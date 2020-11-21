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

/// A target to which a (custom) icon can be applied.
@objc public protocol Target {
    /// The name of the target.
    var name: String { get }

    /// Set the icon for this target.
    ///
    /// - Parameters:
    ///  - image: The image representing the icon to apply.
    /// - Returns: `true` if the icon of the application was updated, `false`
    /// otherwise.
    func set(icon: NSImage) -> Bool

    /// Reset the icon for this target.
    ///
    /// - Returns: `true` if the icon of the application was reset, `false`
    /// otherwise.
    func reset() -> Bool
}

/// An application target.
public class ApplicationTarget: Target {
    /// The `URL` pointing to the application.
    public let url: URL

    /// The name of the target.
    public let name: String

    /// Construct an `ApplicationTarget`.
    ///
    /// - Parameters:
    ///  - url: The `URL` pointing to the application.
    public init(url: URL) {
        self.url = url
        name = url.deletingPathExtension().lastPathComponent
    }

    public func set(icon: NSImage) -> Bool {
        return NSWorkspace.shared.setIcon(icon, forFile: url.path)
    }

    public func reset() -> Bool {
        return NSWorkspace.shared.setIcon(nil, forFile: url.path)
    }
}
