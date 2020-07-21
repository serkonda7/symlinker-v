module main

import cli
import os
import etienne_napoleone.chalk

const (
	linux_dirs = {
		'local': os.home_dir() + '.local/bin/'
		'global': '/usr/local/bin/'
		'test_local': os.home_dir() + '.cache/symlinker_local/'
		'test_global': os.home_dir() + '.cache/symlinker_global/'
	}
)

fn add_link(cmd cli.Command) {
	if cmd.args.len == 0 {
		err_and_exit('`add` needs one argument', '')
	}
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

fn delete_link(cmd cli.Command) {
	if cmd.args.len == 0 {
		err_and_exit('`del` needs at least one argument', '')
	}
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

fn list_links(cmd cli.Command) {
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

fn open_link_folder(cmd cli.Command) {
	if os.getenv('SUDO_USER') != '' {
		err_and_exit('Please run without `sudo`.', '')
	}
	scope := get_scope(cmd)
	link_dir := get_dir(scope)
	println('Opening the $scope symlink folder...')
	command := 'xdg-open $link_dir'
	os.exec(command) or { panic(err) }
}

fn get_scope(cmd cli.Command) string {
	mut t := ''
	$if test { t = 't_' }
	is_global := cmd.flags.get_bool('global') or { panic(err) }
	return if is_global { '${t}global' } else { '${t}local' }
}

fn get_scope_by_dir(dir string) string {
	mut t := ''
	$if test { t = 't_' }
	$if linux {
		return if dir == linux_dirs['local'] { '${t}local' } else { '${t}global' }
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
	mut cmd := cli.Command{
		name: 'symlinker'
		version: '0.8.0'
		disable_flags: true
		sort_commands: false
	}
	cmd.add_flag(cli.Flag{
		flag: .bool
		name: 'global'
		abbrev: 'g'
		description: 'Execute the command in global scope.'
		global: true
	})

	mut add_cmd := cli.Command{
		name: 'add'
		description: 'Create a symlink to <file>.'
		execute: add_link
	}
	add_cmd.add_flag(cli.Flag{
		flag: .string
		name: 'name'
		abbrev: 'n'
		description: 'Use a custom name for the link.'
	})

	mut del_cmd := cli.Command{
		name: 'del'
		description: 'Delete all specified symlinks.'
		execute: delete_link
	}

	mut list_cmd := cli.Command{
		name: 'list'
		description: 'List all symlinks.'
		execute: list_links
	}
	list_cmd.add_flag(
		cli.Flag {
			flag: .bool
			name: 'real'
			abbrev: 'r'
			description: 'Also print the path the links point to.'
		}
	)

	mut open_cmd := cli.Command{
		name: 'open'
		description: 'Open symlink folder in the file explorer.'
		execute: open_link_folder
	}

	cmd.add_commands([add_cmd, del_cmd, list_cmd, open_cmd])
	cmd.parse(os.args)
}
