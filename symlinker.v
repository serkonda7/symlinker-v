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

	link_name := if args[1] == '-n' {
		args[2]
	}
	else {
		args[0].split('/').last()
	}

	link_path := link_dir + link_name
	if os.exists(link_path) {
		println('Error: link named "$link_name" already exists')
		return
	}

	file_path := os.real_path(args[0])

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
		'add' { add_link(args[1..]) }
		'del' { delete_link(args[1]) }
		'list' { list_links() }
		'version' { print_version() }
		'help' { show_help() }
		else {
			println('${args[0]}: unknown command\nRun "symlinker help" for usage.')
		}
	}
}
