/*
 * The MIT License (MIT)
 *
 * Copyright (c) 2019 Fabian Mastenbroek
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

import Foundation
import Cocoa

/// An IconTheme maps an application name to a custom icon.
protocol IconTheme {
    /// The name of the icon theme.
    var name: String { get }

    /// Resolve the custom icon of an application or `null` if none exist.
    subscript(name: String) -> URL? { get }

    /// Determine if the icon theme contains the specified app.
    func contains(name: String) -> Bool

    /// Refresh the icons in the theme.
    ///
    /// This method might be used to reload the icons from the file system for
    /// example.
    func refresh()
}

extension IconTheme {
    /// Sync the icon theme for the application located at the specified `URL`.
    ///
    // - Parameters:
    //    - app: The application to apply the theme to.
    // - Returns: `true` if the icon of the application was updated, `false`
    // otherwise.
    func sync(for app: URL) -> Bool {
        let name = app.deletingPathExtension().lastPathComponent
        guard let icon = self[name] else {
            return false
        }

        guard let image = NSImage(contentsOf: icon) else {
            print("Failed to obtain image")
            return false
        }

        return NSWorkspace.shared.setIcon(image, forFile: app.path)
    }
}

class DirectoryIconTheme : IconTheme {
    /// The name of the icon theme
    var name: String {
        get { path.path }
    }

    /// The path to the directory which represents the icon theme.
    let path: URL

    /// The extensions that are accepted.
    let extensions: Set<String>

    /// The map containing the URLs to the icons and their respective name.
    private var map: [String : URL] = [:]

    /// Construct a new `DirectoryIconTheme`.
    ///
    /// - Parameters:
    ///    - path: The path to the directory to represent the icon theme.
    /// - Throws: If the given path is not a directory.
    init?(path: URL, extensions: Set<String> = ["icns", "png"])  {
        if !path.hasDirectoryPath {
            return nil
        }
        self.path = path
        self.extensions = extensions
        self.refresh()
    }

    /// Refresh map of the icons in this directory.
    func refresh() {
        let fileManager = FileManager.default
        do {
            let urls = try fileManager.contentsOfDirectory(at: self.path, includingPropertiesForKeys: nil)
            for url in urls {
                if extensions.contains(url.pathExtension) {
                    map[url.deletingPathExtension().lastPathComponent] = url
                }
            }
        } catch {
            print("error: failed to list contents of directory")
        }
    }

    /// Resolve the custom icon of an application or `null` if none exist.
    subscript(name: String) -> URL? { map[name] }

    /// Determine if the icon theme contains the specified app.
    func contains(name: String) -> Bool {
        map.keys.contains(name)
    }
}