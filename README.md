# symlinker
 
![CI](https://github.com/Serkonda/symlinker/workflows/CI/badge.svg?branch=master)

Utility program to manage symlinks.


## Installation

Download the latest stable version from the [Releases page][releases].

Place the executable in a directory of your choice and run 
`sudo ./symlinker add -g ./symlinker`

> At the moment only Linux is supported.


## Usage

```
Usage: symlinker [command] [flags] [arguments]

Flags:
  -m, --machine          Execute the command machine-wide.

Commands:
  link <file>            Create a new symlink to <file>.
    -n, --name <name>      Use a custom name for the link.
  del <link1> <...>      Delete all specified symlinks.
  list                   List all symlinks.
    -r, --real             Also print the path the links point to.
  update <link>          Rename a symlink or update it's real path. Use at least one of the flags.
    -n, --name <name>      The new name.
    -p, --path <path>      The new path.
  open [link]            Open a specific symlink or the general root dir in the file explorer.
  version                Print the version text.
  help                   Show this message.
```


## License

Licensed under the [MIT License](LICENSE.md)


<!-- Links -->
[releases]: https://github.com/Serkonda/symlinker/releases
