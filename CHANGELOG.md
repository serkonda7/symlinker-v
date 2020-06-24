# Changelog


## 0.4.0
_24 June 2020_

- Print scope in success and error messages
- Fix invalid success message for `del -g ...` without sudo
- Replace V panic on denied permission with custom error message
- Fix error exit codes


## 0.3.0
_23 June 2020_

- New command to open the symlink folder
- New `-g` flag for machine-wide operations
- Options can now be specified before and after the main argument
- Throw an error for options that miss an argument
- Return code is now `0` on program error


## 0.2.0
_22 june 2020_

- Add option to use a custom name for the created symlink
- Add option to list all symlinks with their full path
- Fix bug that inexistant files could be linked


## 0.1.0
_20 June 2020_

- Create and delete symlinks
- List all symlinks
