module main

import os
import v.vmod

const (
	help_text =
'Usage: symlinker [command] [argument] [options]

Commands:
  add <file>     Create a symlink to <file>.
    -n <name>    Use a custom name for the link.
  del <link>     Delete the specified symlink.
  list           List all symlinks.
    -r           Also print the path the links point to.
  version        Print the version text.
  help           Show this message.'

	link_dir = os.home_dir() + '.local/bin/'
)

fn show_help() {
	println(help_text)
}

fn print_version() {
	mod := vmod.decode(@VMOD_FILE) or { panic(err) }
	println('symlinker $mod.version')
}

fn add_link(args []string) {
	if !os.exists(link_dir) {
		os.mkdir_all(link_dir)
	}

	file_path := os.real_path(args[0])
	if !os.exists(file_path) {
		println('Error: $file_path does not exist')
		return
	}

	link_name := get_option_val(args, '-n') or {
		args[0].split('/').last()
	}

	link_path := link_dir + link_name
	if os.exists(link_path) {
		println('Error: link named "$link_name" already exists')
		return
	}

	os.symlink(file_path, link_path) or { panic(err) }
	println('Successfully linked "$link_name".')
}

fn delete_link(link string) {
	link_path := link_dir + link

	if !os.exists(link_path) {
		println('Error: "$link" does not exist.\nRun "symlinker list" to see your links.')
		return
	}

	os.rm(link_path)
	println('Deleted link: $link')
}

fn list_links(args []string) {
	links := os.ls(link_dir) or { panic(err) }

	if links.len == 0 {
		println('No symlinks detected.')
		return
	}

	if has_option(args, '-r') {
		for link in links {
			real_path := os.real_path(link_dir + link)
			println('$link: $real_path')

		}
	}
	else {
		println(links)
	}
}

fn has_option(args []string, option string) bool {
	return option in args
}

fn get_option_val(args []string, option string) ?string {
	if has_option(args, option) {
		ind := args.index(option)
		return args[ind + 1]
	}

	return error('Option $option does not exist.')
}

fn main() {
	args := os.args[1..]

	if args.len == 0 {
		show_help()
		return
	}

	match args[0] {
		'add' { add_link(args[1..]) }
		'del' { delete_link(args[1]) }
		'list' { list_links(args[1..]) }
		'version' { print_version() }
		'help' { show_help() }
		else {
			println('${args[0]}: unknown command\nRun "symlinker help" for usage.')
		}
	}
}
