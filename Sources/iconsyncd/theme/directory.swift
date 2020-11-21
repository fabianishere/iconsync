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

import Cocoa
import Foundation

/// An IconTheme that maps icons in a directory to applications with the same name as the icons.
public class DirectoryIconTheme: IconTheme {
    /// The name of the icon theme
    public var name: String { path.path }

    /// The path to the directory which represents the icon theme.
    public let path: URL

    /// The extensions that are accepted.
    public let extensions: Set<String>

    /// The map containing the URLs to the icons and their respective name.
    private var map: [String: DirectoryIcon] = [:]

    /// Construct the `DirectoryIconTheme` from the specified configuration.
    public required convenience init?(config: [String: Any]) {
        guard let path = config["path"] as? String else {
            logger.warning("Invalid configuration for directory theme")
            return nil
        }

        let extensions = config["extensions"] as? [String] ?? ["icns", "png"]

        self.init(path: URL(fileURLWithPath: path), extensions: Set(extensions))
    }

    /// Construct a new `DirectoryIconTheme`.
    ///
    /// - Parameters:
    ///    - path: The path to the directory to represent the icon theme.
    ///    - extensions: The set of extensions that are recognized as icon.
    /// - Returns: `nil` if the given path is not a directory.
    public init?(path: URL, extensions: Set<String> = ["icns", "png"]) {
        if !path.hasDirectoryPath {
            return nil
        }
        self.path = path
        self.extensions = extensions
        refresh()
    }

    /// Refresh map of the icons in this directory.
    public func refresh() {
        let fileManager = FileManager.default
        do {
            let urls = try fileManager.contentsOfDirectory(at: path, includingPropertiesForKeys: nil)
            for url in urls {
                if extensions.contains(url.pathExtension) {
                    let name = url.deletingPathExtension().lastPathComponent
                    map[name] = DirectoryIcon(name: name, url: url)
                }
            }
        } catch {
            logger.error("Failed to list contents of directory: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Resolve the custom icon of an application or `null` if none exist.
    public subscript(name: String) -> [Icon] {
        if let icon = map[name] {
            return [icon]
        }

        return []
    }

    /// Determine if the icon theme contains the specified app.
    public func contains(name: String) -> Bool {
        map.keys.contains(name)
    }

    /// An icon in a directory.
    private class DirectoryIcon: Icon {
        /// The name of the icon.
        let name: String

        /// The URL of the icon.
        let url: URL

        /// An empty description.
        let description: String? = nil

        /// Construct a new `DirectoryIcon`.
        ///
        /// Parameters:
        ///  - name: The name of the icon.
        ///  - url: The url at which the icon is located.
        init(name: String, url: URL) {
            self.name = name
            self.url = url
        }

        /// Apply the icon for the specified target.
        func apply(for target: Target) -> Bool {
            guard let image = NSImage(contentsOf: url) else {
                let name = self.name
                logger.error("Failed to obtain image for icon \(name, privacy: .public)")
                return false
            }

            return target.set(icon: image)
        }
    }
}
