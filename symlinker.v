module main

import os
import v.vmod

const (
	help_text =
'symlinker

Usage: symlinker [command] [argument]

Commands:
  add <bin>    Create a new symlink to <binary>.
  version      Print the version text.
  help         Show this message.'

	link_folder = os.home_dir() + '.local/bin/'
)

fn show_help() {
	println(help_text)
}

fn print_version() {
	mod := vmod.decode(@VMOD_FILE) or { panic(err) }
	println('symlinker $mod.version')
}

fn add_link(binary string) {
	if !os.exists(link_folder) {
		os.mkdir_all(link_folder)
	}

	abs_origin := os.real_path(binary)
	link_path := link_folder + abs_origin.split('/').last()

	os.symlink(abs_origin, link_path) or { panic(err) }
}

fn main() {
	args := os.args[1..]

	if args.len == 0 {
		show_help()
		return
	}

	match args[0] {
		'add' { add_link(args[1]) }
		'version' { print_version() }
		'help' { show_help() }
		else {
			println('${args[0]}: unknown command\nRun "symlinker help" for usage.')
		}
	}
}
