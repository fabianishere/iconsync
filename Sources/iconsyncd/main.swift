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

import Commander
import EonilFSEvents
import Foundation

import os

/// The version of the program.
let version = "2.0.0"

/// The suite name of the application
let suiteName = "nl.fabianishere.iconsync"

/// The logger of the program.
let logger = Logger(subsystem: suiteName, category: "daemon")

command(
    Flag("version", flag: "v", description: "Show the version of this program")
) { version in
    if version {
        print("iconsyncd version \(version)")
        exit(0)
    }

    // Test whether the user defaults are available
    guard let defaults = UserDefaults(suiteName: suiteName) else {
        logger.critical("User defaults not available")
        exit(1)
    }

    let daemon = IconSyncDaemon(defaults: defaults)

    // Run the daemon and block execution until the process is interrupted
    daemon.run()
}.run()
