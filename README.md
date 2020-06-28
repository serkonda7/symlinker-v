# symlinker
 
![CI](https://github.com/Serkonda/symlinker/workflows/CI/badge.svg?branch=master)

Utility program to manage symlinks.


## Usage

```
Usage: symlinker [command] [options] [argument]

Commands:
  add <file>     Create a symlink to <file>.
    -n <name>    Use a custom name for the link.
  del <link>     Delete the specified symlink.
  list           List all symlinks.
    -r           Also print the path the links point to.
  open           Open symlink folder in the file explorer.
  version        Print the version text.
  help           Show this message.

Options:
  -g             Execute the command machine-wide. Use with "sudo".
```


## License

Licensed under the [MIT License][license]


<!-- Links -->
[license]: https://github.com/Serkonda/symlinker/blob/master/LICENSE.md
