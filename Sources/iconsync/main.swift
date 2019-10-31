import Foundation
import Commander

/// The version of the program.
let version = "1.1.0"

/// The suite name of the application
let suiteName = "nl.fabianishere.iconsync"

/// Obtain the default theme location
let defaultThemeLocation = UserDefaults(suiteName: suiteName)?.url(forKey: "theme") 
        ?? URL(fileURLWithPath: ("~/.theme" as NSString).expandingTildeInPath)

extension URL : ArgumentConvertible {
    public init(parser: ArgumentParser) throws {
        if let value = parser.shift() {
            self.init(fileURLWithPath: (value as NSString).expandingTildeInPath)
        } else {
            throw ArgumentError.missingValue(argument: nil)
        }
    }
}

command(
        Flag("version", flag: "v", description: "Show the version of this program"),
        Flag("recursive", flag: "r", description: "Recursively iterate the targets"),
        Option<URL>("theme", default: defaultThemeLocation, flag: "t", description: "The icon theme to apply"),
        Argument<[URL]>("target", description: "The file(s) to sync the icon theme for")
) { version, recursive, themeUrl, targets in
    if (version) {
        print("iconsync version \(version)")
        exit(0)
    }
    let fileManager = FileManager.default

    guard let theme = DirectoryIconTheme(path: themeUrl) else {
        print("error: failed to initialize theme \(themeUrl)")
        exit(-1)
    }

    // Expand the initial
    var queue: [URL] = targets.flatMap { (target: URL) -> [URL] in
        if target.hasDirectoryPath && target.pathExtension != "app" {
            return try! fileManager.contentsOfDirectory(at: target, includingPropertiesForKeys: nil)
        } else {
            return [target]
        }
    }

    while !queue.isEmpty {
        let target = queue.removeLast()
        if target.pathExtension == "app" {
            let changed = theme.sync(for: target)
            print("Patching: \(target) [\(changed)]")
        } else if target.hasDirectoryPath && recursive {
            queue.append(contentsOf: try! fileManager.contentsOfDirectory(at: target, includingPropertiesForKeys: nil))
        }
    }

}.run()

