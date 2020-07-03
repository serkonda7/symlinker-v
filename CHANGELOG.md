# Changelog


## 0.6.0
_3 July 2020_

- Migrate to V cli
- Delete multiple links at once by specifying each as arguments
- New flag `list --all` to list global and local links

## 0.5.0
_25 June 2020_

- Prevent deleting non-link files
- Allow deleting links that point to deleted or moved files
- Do not list non-link files anymore
- Distinguish between non-link files and links in error messages
- Print errors in red color


## 0.4.0
_24 June 2020_

- Print scope in success and error messages
- Don't show false success message for `del -g ...` without sudo
- Replace V panic on denied permission with more helpful error message
- Change exit codes to indicate a program error


## 0.3.0
_23 June 2020_

- New `open` command
- New option `-g` for machine-wide operations
- Options can be specified before and after the main argument
- Show an error for options that miss an argument
- Add exit codes for program errors


## 0.2.0
_22 june 2020_

- New option `add -n <name>` for custom symlink names
- New option `list -r` to show the path pointed to
- Prevent linking inexistent files


## 0.1.0
_20 June 2020_

- New `add <file>` command
- New `del <link>` command
- New `list` command
