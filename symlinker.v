module main

import os
import v.vmod

const (
	help_text =
'Usage: symlinker [command] [argument]

Commands:
  add <file>   Create a symlink to <file>.
  list         List all symlinks.
  version      Print the version text.
  help         Show this message.'

	link_dir = os.home_dir() + '.local/bin/'
)

fn show_help() {
	println(help_text)
}

fn print_version() {
	mod := vmod.decode(@VMOD_FILE) or { panic(err) }
	println('symlinker $mod.version')
}

fn add_link(binary string) {
	if !os.exists(link_dir) {
		os.mkdir_all(link_dir)
	}

	link_name := binary.split('/').last()

	link_path := link_dir + link_name
	if os.exists(link_path) {
		println('Error: link named "$link_name" already exists')
		return
	}

	abs_origin := os.real_path(binary)

	os.symlink(abs_origin, link_path) or { panic(err) }
	println('Successfully linked "$link_name".')
}

fn list_links() {
	links := os.ls(link_dir) or { panic(err) }

	if links.len == 0 {
		println('No symlinks detected.')
	}
	else {
		println(links)
	}
}

fn main() {
	args := os.args[1..]

	if args.len == 0 {
		show_help()
		return
	}

	match args[0] {
		'add' { add_link(args[1]) }
		'list' { list_links() }
		'version' { print_version() }
		'help' { show_help() }
		else {
			println('${args[0]}: unknown command\nRun "symlinker help" for usage.')
		}
	}
}
