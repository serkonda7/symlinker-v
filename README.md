# symlinker
![CI](https://github.com/Serkonda/symlinker/workflows/CI/badge.svg?branch=master)

CLI utility tool to create and manage symlinks in the PATH.


## Installation
You can download the latest stable release [here][release-latest].

**OR** build symlinker from source. In this case you need to install [V][v_repo] first.
```sh
git clone https://github.com/serkonda7/symlinker.git
cd symlinker
v .
```

Now run `sudo ./symlinker link -m ./symlinker` and you are finished.

> Note: At the moment only Linux is supported.


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
    -r, --real             Also print the real path each symlink points to.
  update <link>          Rename a symlink or update it's real path. Use at least one of the flags.
    -n, --name <name>      The new name for the link.
    -p, --path <path>      The new path that will be linked.
  open [link]            Open a specific symlink or the general root dir in the file explorer.
  help [command]         Prints help information.
  version                Prints version information.
```


## License
Licensed under the [MIT License](LICENSE.md)


<!-- Links -->
[release-latest]: https://github.com/serkonda7/symlinker/releases/download/latest/symlinker
[v_repo]: https://github.com/vlang/v#installing-v-from-source
