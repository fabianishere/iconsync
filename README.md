iconsync
========
A tool to sync your icon theme on macOS.

## Usage
```
iconsync [-vrh] target...

Arguments:

    target - The file(s) to sync the icon theme for

Options:
    -v, --version [default: false] - Show the version of this program
    -r, --recursive [default: false] - Recursively iterate the targets
    -t, --theme [default: ~/.theme] - The icon theme to apply
    --help - Show a help message
```

`iconsync` will identify each icon (in `.icns` or `.png`) in your theme directory and will apply
this icon to all macOS applications in the specified target directories.

## Building
The module is built using [Swift Package Manager](https://swift.org/package-manager/). 
Enter the following commands into your command prompt in the directory in which you intend to build the module:

```shell
$ swift build -c release 
```

## License
The code is released under the MIT license. See [LICENSE.txt](/LICENSE.txt).