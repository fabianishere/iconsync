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

/// An IconTheme maps an application name to a custom icon.
@objc public protocol IconTheme {
    /// The name of the icon theme.
    var name: String { get }

    /// Construct the `IconTheme` from the specified configuration.
    init?(config: [String: Any])

    /// Resolve the custom icon of an application or an empty array if none exist.
    subscript(_: String) -> [Icon] { get }

    /// Determine if the icon theme contains the specified app.
    func contains(name: String) -> Bool

    /// Refresh the icons in the theme.
    ///
    /// This method might be used to reload the icons from the file system for
    /// example.
    func refresh()
}

/// A (custom) icon for an application.
@objc public protocol Icon {
    /// The name of the icon.
    var name: String { get }

    /// A description describing the icon.
    var description: String? { get }

    /// Apply the icon for the specified target.
    ///
    /// - Parameters:
    ///    - target: The target to apply the icon to.
    /// - Returns: `true` if the icon of the target was updated, `false`
    /// otherwise.
    func apply(for target: Target) -> Bool
}
