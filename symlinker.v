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
		print_err('Cannot link inexistent file "$file_path"', '')
	}

	link_name := cmd.flags.get_string_or('name', cmd.args[0].split('/').last())

	link_path := link_dir + link_name
	if os.exists(link_path) {
		if os.is_link(link_path) {
			print_err('Error: a ${scope(cmd)} link named "$link_name" already exists', '')
		}
		print_err('Error: a file named "$link_name" already exists', '')
	}

	os.symlink(file_path, link_path) or {
		print_err('Permission denied', 'Run with "sudo" instead.')
	}
	println('Created ${scope(cmd)} link: "$link_name"')
}

fn list_links(cmd cli.Command) {
	files := os.ls(actual_link_dir(cmd)) or { panic(err) }
	links := files.filter(os.is_link(actual_link_dir(cmd) + it))

	if links.len == 0 {
		println('No symlinks detected.')
		return
	}

	f_real := cmd.flags.get_bool('real') or { panic(err) }
	if f_real {
		for link in links {
			real_path := os.real_path(actual_link_dir(cmd) + link)
			println('$link: $real_path')

		}
	}
	else {
		println(links)
	}
}

fn actual_link_dir(cmd cli.Command) string {
	is_global := cmd.flags.get_bool('global') or { panic(err) }
	return if is_global { global_link_dir } else { local_link_dir }
}

fn scope(cmd cli.Command) string {
	is_global := cmd.flags.get_bool('global') or { panic(err) }
	return if is_global { 'global' } else { 'local' }
}

fn print_err(msg, tip_msg string) {
	println(chalk.fg(msg, 'light_red'))
	if tip_msg.len > 0 {
		println(tip_msg)
	}
	exit(1)
}

fn main() {
	mut cmd := cli.Command{
		name: 'symlinker',
		version: '0.5.0',
		disable_flags: true
	}

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
	add_cmd.add_flag(cli.Flag{
		flag: .bool,
		name: 'global',
		abbrev: 'g',
		description: 'Execute the command machine-wide.'
	})

	mut list_cmd := cli.Command{
		name: 'list',
		description: 'List all symlinks.',
		execute: list_links
	}
	list_cmd.add_flag(cli.Flag{
		flag: .bool,
		name: 'real',
		abbrev: 'r',
		description: 'Also print the path the links point to.'
	})
	list_cmd.add_flag(cli.Flag{
		flag: .bool,
		name: 'global',
		abbrev: 'g',
		description: 'Execute the command machine-wide.'
	})

	cmd.add_command(add_cmd)
	cmd.add_command(list_cmd)
	cmd.parse(os.args)
}
