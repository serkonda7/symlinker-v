module main

import cli { Command, Flag }
import os
import etienne_napoleone.chalk

const (
	linux_dirs = {
		'local': os.home_dir() + '.local/bin/'
		'global': '/usr/local/bin/'
	}
)

fn add_link(cmd Command) {
	scope := get_scope(cmd)
	link_dir := get_dir(scope)
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
			err_and_exit('$scope link with name "$link_name" already exists', '')
		}
		err_and_exit('File named "$link_name" already exists', '')
	}

	os.symlink(file_path, link_path) or {
		err_and_exit('Permission denied', 'Run with "sudo" instead.')
	}
	println('Created $scope link: "$link_name"')
}

fn delete_link(cmd Command) {
	scope := get_scope(cmd)
	link_dir := get_dir(scope)
	mut err := 0
	for arg in cmd.args {
		link_path := link_dir + arg

		if !os.is_link(link_path) {
			if !os.exists(link_path) {
				print_err('$scope link `$arg` does not exist', 'Run `symlinker list` to see your links.')
				err++
				continue
			}
			print_err('"$arg" is no $scope link', '')
			err++
			continue
		}
		os.rm(link_path) or {
			err_and_exit('Permission denied', 'Run with "sudo" instead.')
		}
		println('Deleted $scope link: "$arg"')
	}
	if err > 0 {
		exit(1)
	}
}

fn list_links(cmd Command) {
	dirs := [get_dir('local'), get_dir('global')]
	for dir in dirs {
		scope := get_scope_by_dir(dir)
		files := os.ls(dir) or { panic(err) }
		links := files.filter(os.is_link(dir + it))
		if links.len == 0 {
			println('No $scope symlinks detected.')
			continue
		}
		println(chalk.style('$scope links:', 'bold'))
		f_real := cmd.flags.get_bool('real') or { panic(err) }
		if f_real {
			mut invalid_links := []string{}
			for link in links {
				link_path := dir + link
				real_path := os.real_path(link_path)
				if link_path == real_path {
					invalid_links << link
					continue
				}
				println('  $link: $real_path')
			}
			for inv_link in invalid_links {
				println(chalk.fg('  INVALID', 'light_magenta') + ' $inv_link')
			}
		}
		else {
			mut rows := []string{}
			mut row_idx := 0
			for i, link in links {
				if i % 5 == 0 {
					rows << ''
					row_idx = i / 5
				}
				rows[row_idx] += '$link, '
			}
			rows[rows.len - 1] = rows.last().all_before_last(', ')
			for row in rows {
				println('  $row')
			}
		}
	}
}

fn update_link(cmd Command) {
	if cmd.args.len == 0 {
		err_and_exit('`update` needs the link to update as argument', '')
	}
	new_name := cmd.flags.get_string_or('name', '')
	new_path := cmd.flags.get_string_or('path', '')
	if new_name == '' && new_path == '' {
		err_and_exit('At least one of the flags is required for `update`', '')
	}
	scope := get_scope(cmd)
	mut link_name := cmd.args[0]
	dir := get_dir(scope)
	mut link_path := dir + link_name
	if !os.exists(link_path) {
		err_and_exit('Cannot update inexistent link "$link_path"', '')
	}
	if new_name != '' {
		os.mv_by_cp(link_path, dir + new_name) or { panic(err) }
		link_path = dir + new_name
		link_name = new_name
		println('Renamed $scope link "$link_name" to ${new_name}.')
	}
	if new_path != '' {
		os.rm(link_path) or { panic(err) }
		os.symlink(new_path, link_path) or {
			err_and_exit('Permission denied', 'Run with "sudo" instead.')
		}
		println('Updated path of ${link_name}.')
	}
}

fn open_link_folder(cmd Command) {
	if os.getenv('SUDO_USER') != '' {
		err_and_exit('Please run without `sudo`.', '')
	}
	scope := get_scope(cmd)
	mut dir := get_dir(scope)
	if cmd.args.len >= 1 {
		target_link := cmd.args[0]
		links := os.ls(dir) or { panic(err) }
		if target_link in links {
			dir = os.real_path(dir + target_link).all_before_last('/')
			println('Opening the directory of "$target_link"...')
		} else {
			err_and_exit('Cannot open directory: "$target_link" is no $scope link', '')
		}
	} else {
		println('Opening the $scope symlink folder...')
	}
	command := 'xdg-open $dir'
	os.exec(command) or { panic(err) }
}

fn get_scope(cmd Command) string {
	is_global := cmd.flags.get_bool('global') or { panic(err) }
	return if is_global { 'global' } else { 'local' }
}

fn get_scope_by_dir(dir string) string {
	$if linux {
		return if dir == linux_dirs['local'] { 'local' } else { 'global' }
	} $else {
		panic('Invalid os')
	}
}

fn get_dir(scope string) string {
	$if linux {
		return linux_dirs[scope]
	} $else {
		panic('Invalid os')
	}
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
	mut cmd := Command{
		name: 'symlinker'
		version: '0.8.0'
		disable_flags: true
		sort_commands: false
	}
	cmd.add_flag(Flag{
		flag: .bool
		name: 'global'
		abbrev: 'g'
		description: 'Execute the command in global scope.'
		global: true
	})

	mut add_cmd := Command{
		name: 'add'
		description: 'Create a symlink to <file>.'
		required_args: 1
		execute: add_link
	}
	add_cmd.add_flag(Flag{
		flag: .string
		name: 'name'
		abbrev: 'n'
		description: 'Use a custom name for the link.'
	})

	mut del_cmd := Command{
		name: 'del'
		description: 'Delete all specified symlinks.'
		required_args: 1
		execute: delete_link
	}

	mut list_cmd := Command{
		name: 'list'
		description: 'List all symlinks.'
		execute: list_links
	}
	list_cmd.add_flag(
		Flag {
			flag: .bool
			name: 'real'
			abbrev: 'r'
			description: 'Also print the path the links point to.'
		}
	)

	mut update_cmd := Command{
		name: 'update'
		description: 'Rename symlinks or update their real path.'
		execute: update_link
	}
	update_cmd.add_flags([
		Flag{
			flag: .string
			name: 'name'
			abbrev: 'n'
			description: 'The new name.'
		},
		Flag{
			flag: .string
			name: 'path'
			abbrev: 'p'
			description: 'The new path.'
		}
	])

	mut open_cmd := Command{
		name: 'open'
		description: 'Open symlink folder in the file explorer.'
		execute: open_link_folder
	}

	cmd.add_commands([add_cmd, del_cmd, list_cmd, /* update_cmd, */ open_cmd])
	cmd.parse(os.args)
}
