module main

import cli
import os
import etienne_napoleone.chalk

const (
	local_link_dir = os.home_dir() + '.local/bin/'
	global_link_dir = '/usr/local/bin/'
)

fn add_link(cmd cli.Command) {
	link_dir := actual_link_dir(cmd)
	if !os.exists(link_dir) {
		os.mkdir_all(link_dir)
	}

	file_path := os.real_path(cmd.args[0])
	if !os.exists(file_path) {
		err_and_exit('Cannot link inexistent file "$file_path"', '')
	}

	mut link_name := cmd.flags.get_string('name') or { panic(err) }
	if link_name == '' {
		link_name = cmd.args[0].split('/').last()
	}

	link_path := link_dir + link_name
	if os.exists(link_path) {
		if os.is_link(link_path) {
			err_and_exit('Error: a ${scope(cmd)} link named "$link_name" already exists', '')
		}
		err_and_exit('Error: a file named "$link_name" already exists', '')
	}

	os.symlink(file_path, link_path) or {
		err_and_exit('Permission denied', 'Run with "sudo" instead.')
	}
	println('Created ${scope(cmd)} link: "$link_name"')
}

fn delete_link(cmd cli.Command) {
	for arg in cmd.args {
		link_path := actual_link_dir(cmd) + arg

		if !os.is_link(link_path) {
			if !os.exists(link_path) {
				print_err('Error: ${scope(cmd)} link "$arg" does not exist', '')
			}
			print_err('Error: "$arg" is no ${scope(cmd)} link', '')
		}

		os.rm(link_path) or {
			err_and_exit('Permission denied', 'Run with "sudo" instead.')
		}
		println('Deleted ${scope(cmd)} link: "$arg"')
	}
}

fn list_links(cmd cli.Command) {
	f_all := cmd.flags.get_bool('all') or { panic(err) }

	dirs := if f_all {
		[local_link_dir, global_link_dir]
	} else {
		[actual_link_dir(cmd)]
	}

	for i, dir in dirs {
		files := os.ls(dir) or { panic(err) }
		links := files.filter(os.is_link(dir + it))

		if links.len == 0 {
			println('No ${scope(cmd)} symlinks detected.')
			return
		}

		println(chalk.style('${scope_by_dir(dir)} links:', 'bold'))
		f_real := cmd.flags.get_bool('real') or { panic(err) }
		if f_real {
			for link in links {
				real_path := os.real_path(dir + link)
				println('$link: $real_path')

			}
		}
		else {
			println(links)
		}

		if i < dirs.len-1 { println('') }
	}
}

fn open_link_folder(cmd cli.Command) {
	link_dir := actual_link_dir(cmd)
	command := 'xdg-open $link_dir'
	os.exec(command) or { panic(err) }
}

fn actual_link_dir(cmd cli.Command) string {
	is_global := cmd.flags.get_bool('global') or { panic(err) }
	return if is_global { global_link_dir } else { local_link_dir }
}

fn scope(cmd cli.Command) string {
	is_global := cmd.flags.get_bool('global') or { panic(err) }
	return if is_global { 'global' } else { 'local' }
}

fn scope_by_dir(dir string) string {
	return if dir == local_link_dir { 'local' } else { 'global' }
}

fn print_err(msg, tip_msg string) {
	println(chalk.fg(msg, 'light_red'))
	if tip_msg.len > 0 {
		println(tip_msg)
	}
}

fn err_and_exit(msg, tip_msg string) {
	print_err(msg, tip_msg)
	exit(1)
}

fn main() {
	mut cmd := cli.Command{
		name: 'symlinker',
		version: '0.6.0',
		disable_flags: true
		sort_commands: false
	}
	cmd.add_flag(cli.Flag{
		flag: .bool,
		name: 'global',
		abbrev: 'g',
		description: 'Execute the command machine-wide.'
		global: true
	})

	mut add_cmd := cli.Command{
		name: 'add',
		description: 'Create a symlink to <file>.',
		execute: add_link
	}
	add_cmd.add_flag(cli.Flag{
		flag: .string,
		name: 'name',
		abbrev: 'n',
		description: 'Use a custom name for the link.'
	})

	mut del_cmd := cli.Command{
		name: 'del',
		description: 'Delete all specified symlinks.',
		execute: delete_link
	}

	mut list_cmd := cli.Command{
		name: 'list',
		description: 'List all symlinks.',
		execute: list_links
	}
	})
	list_cmd.add_flag(cli.Flag{
		flag: .bool,
		name: 'all',
		abbrev: 'a',
		description: 'List both, local and global links.'
	})

	mut open_cmd := cli.Command{
		name: 'open',
		description: 'Open symlink folder in the file explorer.',
		execute: open_link_folder
	}

	cmd.add_command(add_cmd)
	cmd.add_command(del_cmd)
	cmd.add_command(list_cmd)
	cmd.add_command(open_cmd)
	cmd.parse(os.args)
}
