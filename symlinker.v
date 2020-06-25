module main

import os
import v.vmod
import chalk

const (
	help_text =
'Usage: symlinker [command] [options] [argument]

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
  -g             Execute the command machine-wide.'

	local_link_dir = os.home_dir() + '.local/bin/'
	global_link_dir = '/usr/local/bin/'

	options_with_val = ['-n']
)

struct SortedArgs{
mut:
	main_arg string
	options  map[string]string
	scope    string = 'local'
}

fn show_help() {
	println(help_text)
}

fn print_version() {
	mod := vmod.decode(@VMOD_FILE) or { panic(err) }
	println('symlinker $mod.version')
}

fn add_link(args SortedArgs) {
	link_dir := actual_link_dir(args)
	if !os.exists(link_dir) {
		os.mkdir_all(link_dir)
	}

	file_path := os.real_path(args.main_arg)
	if !os.exists(file_path) {
		print_err('Error: path "$file_path" does not exist', '')
	}

	link_name := if '-n' in args.options {
		args.options['-n']
	} else {
		args.main_arg.split('/').last()
	}

	link_path := link_dir + link_name
	if os.exists(link_path) {
		print_err('Error: a $args.scope link named "$link_name" already exists', '')
	}

	os.symlink(file_path, link_path) or {
		print_err('Permission denied', 'Run with "sudo" instead.')
	}
	println('Created $args.scope link: "$link_name"')
}

fn delete_link(args SortedArgs) {
	link_path := actual_link_dir(args) + args.main_arg

	if !os.exists(link_path) {
		print_err('Error: $args.scope link "$args.main_arg" does not exist', '')
	}

	os.rm(link_path) or {
		print_err('Permission denied', 'Run with "sudo" instead.')
	}
	println('Deleted $args.scope link: "$args.main_arg"')
}

fn list_links(args SortedArgs) {
	links := os.ls(actual_link_dir(args)) or { panic(err) }

	if links.len == 0 {
		println('No $args.scope symlinks detected.')
		return
	}

	if '-r' in args.options {
		for link in links {
			real_path := os.real_path(actual_link_dir(args) + link)
			println('$link: $real_path')

		}
	}
	else {
		println(links)
	}
}

fn open_link_folder(args SortedArgs) {
	link_dir := actual_link_dir(args)
	command := 'xdg-open $link_dir'
	os.exec(command) or { panic(err) }
}

fn actual_link_dir(args SortedArgs) string {
	return if args.scope == 'global' { global_link_dir } else { local_link_dir }
}

fn print_err(msg, help_msg string) {
	println(chalk.fg(msg, 'light_red'))
	if help_msg.len > 0 {
		println(help_msg)
	}
	exit(1)
}

fn sort_args(args []string) SortedArgs {
	mut sorted_args := SortedArgs{}
	mut main_arg_set := false

	for i := 0; i < args.len; i++ {
		arg := args[i]
		if arg.starts_with('-') {
			if arg in options_with_val {
				if i + 1 >= args.len {
					print_err('Error: missing agument for option "$arg"', '')
				}
				sorted_args.options[arg] = args[i + 1]
				i++
				continue
			}

			if arg == '-g' {
				sorted_args.scope = 'global'
				continue
			}

			sorted_args.options[arg] = ''
			continue
		}

		if !main_arg_set {
			sorted_args.main_arg = arg
			main_arg_set = true
		}
	}

	return sorted_args
}

fn main() {
	args := os.args[1..]

	if args.len == 0 {
		show_help()
		return
	}

	sorted_args := sort_args(args[1..])

	match args[0] {
		'add' { add_link(sorted_args) }
		'del' { delete_link(sorted_args) }
		'list' { list_links(sorted_args) }
		'open' { open_link_folder(sorted_args) }
		'version' { print_version() }
		'help' { show_help() }
		else {
			println('${args[0]}: unknown command\nRun "symlinker help" for usage.')
		}
	}
}
