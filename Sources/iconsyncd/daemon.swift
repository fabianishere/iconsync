/*
 * Copyright (c) 2020 Fabian Mastenbroek
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import EonilFSEvents
import Foundation

/// A daemon that resyncs icons when they are changed (e.g. due to updates).
class IconSyncDaemon {
    /// The `RunLoop` on which the daemon runs.
    private let runLoop = RunLoop.main

    /// The `FileManager` to use.
    private let fileManager = FileManager.default

    /// The `NSKeyValueObservation` for tracking the path configuration property.
    private var pathObserver: NSKeyValueObservation?

    /// The currently selected paths to watch.
    private var paths: Set<URL> = []

    /// The `EonilFSEventStream` that is currently active.
    private var fsStream: EonilFSEventStream?

    /// The currently selected `IconTheme`.
    private var theme: IconTheme?

    /// The `NSKeyValueObservation` for tracking the theme configuration property.
    private var themeObserver: NSKeyValueObservation?

    /// Construct an `IconSyncDaemon` instance.
    ///
    /// Params:
    ///  - defaults: The `UserDefaults` object to track.
    init(defaults: UserDefaults) {
        // Watch for changed theme
        themeObserver = defaults.observe(\.theme, options: [.initial, .new], changeHandler: { _, change in
            let newTheme: String? = (change.newValue as? NSString)?.expandingTildeInPath
            logger.info("Theme set to \(newTheme)")

            if let newTheme = newTheme,
               let theme = DirectoryIconTheme(path: URL(fileURLWithPath: newTheme))
            {
                self.theme = theme
                self.flushAll(theme: theme, paths: self.paths)
            } else {
                self.flushAll(theme: nil, paths: self.paths)
            }
        })

        // Watch for changed paths
        pathObserver = defaults.observe(\.paths, options: [.initial, .new], changeHandler: { _, change in
            let oldPaths = self.paths
            let paths = Set(change.newValue?.map { URL(fileURLWithPath: ($0 as NSString).expandingTildeInPath) } ?? [])

            let removedPaths = oldPaths.subtracting(paths)
            let addedPaths = paths.subtracting(oldPaths)

            logger.info("Watched paths have changed from \(oldPaths) to \(paths)")

            // Flush the icons for the new paths
            self.flushAll(theme: nil, paths: removedPaths)
            self.flushAll(theme: self.theme, paths: addedPaths)

            // Update the paths
            self.paths = paths

            // Invalidate previous stream
            self.fsStream?.stop()
            self.fsStream?.invalidate()

            // Create new stream
            self.fsStream = self.createFSEventStream(paths: paths)
            try! self.fsStream?.start()
        })
    }

    /// Deinitializes the `IconSyncDaemon` instance.
    deinit {
        self.themeObserver?.invalidate()
        self.pathObserver?.invalidate()
        self.fsStream?.stop()
        self.fsStream?.invalidate()
    }

    /// Flush all icons.
    private func flushAll(theme: IconTheme?, paths: Set<URL>) {
        // Skip flushing if no paths are given
        if paths.isEmpty {
            return
        }

        logger.info("Flushing all icons")

        // Expand the initial paths
        var queue: [URL] = paths.flatMap { (target: URL) -> [URL] in
            if target.hasDirectoryPath, target.pathExtension != "app" {
                return try! fileManager.contentsOfDirectory(at: target, includingPropertiesForKeys: nil)
            } else {
                return [target]
            }
        }

        while !queue.isEmpty {
            let target = queue.removeLast()
            if target.pathExtension == "app" {
                flushSingle(theme: theme, url: target)
            } else if target.hasDirectoryPath {
                queue.append(contentsOf: try! fileManager.contentsOfDirectory(at: target, includingPropertiesForKeys: nil))
            }
        }
    }

    /// Flush a single icon.
    private func flushSingle(theme: IconTheme?, url: URL) {
        let app = ApplicationTarget(url: url)
        var res: Bool = false
        if let theme = self.theme,
           let icon = theme[app.name].first
        {
            res = icon.apply(for: app)
        } else {
            res = app.reset()
        }

        logger.info("Updating: \(url.path) [\(res)]")
    }

    /// Create an `FSEventStream` based on the defaults.
    private func createFSEventStream(paths: Set<URL>) -> EonilFSEventStream? {
        // We need at least one directory to start the stream
        if paths.isEmpty {
            return nil
        }

        return try? createFSEventStream(paths: paths.map { $0.path })
    }

    /// Create an `FSEventStream` for the specified paths.
    private func createFSEventStream(paths: [String]) throws -> EonilFSEventStream {
        logger.info("Creating FSEventStream for paths \(paths, privacy: .public)")

        let s = try EonilFSEventStream(
            pathsToWatch: paths,
            sinceWhen: .now, // We always flush the icons at the start of the daemon
            latency: 5, // We do not about collapsed events
            flags: [.ignoreSelf, .fileEvents],
            handler: handleFSEvent
        )
        s.scheduleWithRunloop(runLoop: runLoop, runLoopMode: .common)
        return s
    }

    /// Handle an event from the FSStream.
    private func handleFSEvent(event: EonilFSEventsEvent) {
        let url = URL(fileURLWithPath: event.path)

        // Only consider app extensions for now
        if url.pathExtension != "app" {
            return
        }

        flushSingle(theme: theme, url: url)
    }

    /// Run the daemon and block the current thread until the process is interrupted.
    func run() {
        runLoop.run()
    }
}

extension UserDefaults {
    /// The paths to watch for icon changes.
    @objc dynamic var paths: [String] {
        return stringArray(forKey: "paths") ?? []
    }

    /// The path to the theme or `nil` if the native theme is selected.
    @objc dynamic var theme: String? {
        return string(forKey: "theme")
    }
}
