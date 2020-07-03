# symlinker
 
![CI](https://github.com/Serkonda/symlinker/workflows/CI/badge.svg?branch=master)

Utility program to manage symlinks.


## Usage

```
Usage: symlinker [flags] [command] [arguments]

Commands:
  add <file>             Create a symlink to <file>.
    -n, --name <name>    Use a custom name for the link.
  del <links>            Delete all specified symlinks.
  list                   List all symlinks.
    -r, --real           Also print the path the links point to.
    -a, --all            List both, local and global links.
  open                   Open symlink folder in the file explorer.
  version                Print the version text.
  help                   Show this message.

Flags:
  -g, --global           Execute the command machine-wide. Use with "sudo".
```


## License

Licensed under the [MIT License][license]


<!-- Links -->
[license]: https://github.com/Serkonda/symlinker/blob/master/LICENSE.md
