# Changelog


## 2.2.2
_3 May 2021_

**Changes**
- updating the path of an invalid link now gives a different message
- more tests and CI checks

## 2.2.1
_18 January 2021_

**Additions**
- `help`: also print a description

**Changes**
- `open`: errors and warnings caused by the file explorer are hidden

**Fixes**
- Invalid paths can now be updated
- fix `open` blocking the console


## 2.2.0
_29 December 2020_

**Changes**
- `list --real`: the real paths are now aligned

**Fixes**
- Show the correct flag name (`--path`) in an `update` error message


## 2.1.1
_9 December 2020_

**Changes**
- Restore the old symlink if updating it fails
- Some CI updates

## 2.1.0
_5 October 2020_

**Critical**
- Prevent possible access to unwanted files using `add -n`, `del`, `open` and `update` with relative paths.

**Changes**
- `open`: run the file explorer as background process
- Move linker back to main module but as separate file

**Fixes**
- `list`: don't panic if a linkdir does not exist
- `open`: prevent runtime error if the linkdir to be opened does not exist
- `open`: give other scope suggestion also if the current scope linkdir does not exist


## 2.0.0
_26 September 2020_

**Additions**
- `link`: new message if the exact same link already exists.
- `link --name`: show a hint if whitespace was stripped from the provided name.
- `del`: give a different message if the deleted link was invalid.
- `del`, `open`: add a suggestion if the specified link only exists in the other scope.
- `update`: throw an error when the provided values are the same as the old ones.
- Create a huge amount of (new) tests to ensure great stability.

**Changes**
- Split the code into two files, the command-line-interface and the actual logic.
- Error and success messages are much more helpful and informative.
- `list`: invalid links are now always marked, not only with `--real`.
- `help`: some updates to the help message and the command usages.
- CI: remove windows/mac build job

**Fixes**
- `update`: prevent possible deletation of the link that should be updated.
- `update`: fix corrupted links if `--path` was left empty.
- `update`: fix possible fail in link creation step if the name was not changed.
- Fix regression that error messages were not printed.


## 1.0.1
_15 September 2020_

**Changes**
- Replace `etienne_napoleone.chalk` with `vlib.term` module
- CI: Verify code formatting with `vfmt`

**Fixes**
- Fix inconsitent result in `test_get_links()`


## 1.0.0
_22 August 2020_

**Breaking**
- Rename `--global` flag to `--machine`
- Rename `add` command to `link`

**Additions**
- New `update` command to change the name or real path of existing links
- `open <link>` will open the real directory of a specific link
- CI: test building also on Windows and macOS

**Changes**
- Show an error if a required argument is missing
- `link --name`: strip spaces from the name alias end
- Prevent possible panics by providing default values
- Improve scope names
- `list`: minor optimization
- Huge improvements and simplifications under the hood
- Reduce scheduled CI frequency to one run per day

**Fixes**
- `link --name`: ignore the flag if the name alias consists only of whitespace


## 0.8.0
_19 July 2020_

**Changes:**
- `list --real`: label invalid links
- `open`: print what folder was opened
- `list`: print many symlinks more pretty by splitting into shorter rows

**Fixes:**
- `open`: disallow running with sudo
- `del`: only show the correct error message
- `del`: use exit code `1` if any error occurs


## 0.7.0
_18 July 2020_

**Breaking:**
- `list`: remove `--all` flag and make it the default behaviour

**Changes:**
- `list --real`: print links with some indentation
- shorter error messages

**Fixes:**
- `list --all`: list global links if local ones are empty
- `list --all`: print correct scope for no detected links


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
