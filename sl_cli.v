module main

import cli { Command }
import os
import term
import linker

const (
	link_dirs     = {
		'per-user': os.home_dir() + '.local/bin/'
		'machine-wide': '/usr/local/bin/'
	}
	test_link_dir = os.join_path(os.temp_dir(), 'symlinker', 'tlinks/')
)

fn main() {
	mut cmd := create_cmd()
	cmd.parse(os.args)
}

fn create_cmd() Command {
	mut cmd := Command{
		name: 'symlinker'
		version: '1.0.1'
		disable_flags: true
		sort_commands: false
	}
	cmd.add_flag({
		flag: .bool
		name: 'machine'
		abbrev: 'm'
		description: 'Execute the command machine-wide.'
		global: true
	})
	mut link_cmd := Command{
		name: 'link'
		description: 'Create a new symlink to <file>.'
		required_args: 1
		execute: link_func
	}
	link_cmd.add_flag({
		flag: .string
		name: 'name'
		abbrev: 'n'
		description: 'Use a custom name for the link.'
	})
	mut del_cmd := Command{
		name: 'del'
		description: 'Delete all specified symlinks.'
		required_args: 1
		execute: del_func
	}
	mut list_cmd := Command{
		name: 'list'
		description: 'List all symlinks.'
		execute: list_func
	}
	list_cmd.add_flag({
		flag: .bool
		name: 'real'
		abbrev: 'r'
		description: 'Also print the path the links point to.'
	})
	mut update_cmd := Command{
		name: 'update'
		description: "Rename a symlink or update it's real path."
		required_args: 1
		execute: update_func
	}
	update_cmd.add_flag({
		flag: .string
		name: 'name'
		abbrev: 'n'
		description: 'The new name.'
	})
	update_cmd.add_flag({
		flag: .string
		name: 'path'
		abbrev: 'p'
		description: 'The new path.'
	})
	mut open_cmd := Command{
		name: 'open'
		description: 'Open a specific symlink or the general root dir in the file explorer.'
		execute: open_func
	}
	cmd.add_commands([link_cmd, del_cmd, list_cmd, update_cmd, open_cmd])
	return cmd
}

fn link_func(cmd Command) {
	scope := get_scope(cmd)
	source_name := cmd.args[0]
	name_flag_val := cmd.flags.get_string_or('name', '')
	target_name, validation_msg := validate_name_flag(name_flag_val, source_name)
	if validation_msg != '' {
		println(validation_msg)
	}
	msg := linker.create_link(source_name, target_name, scope) or {
		println(term.bright_red(err))
		exit(1)
	}
	println(msg)
}

fn del_func(cmd Command) {
	scope := get_scope(cmd)
	mut err_count := 0
	for arg in cmd.args {
		msg := linker.delete_link(arg, scope) or {
			err_count++
			println(term.bright_red(err))
			continue
		}
		println(msg)
	}
	if err_count > 0 {
		exit(1)
	}
}

fn list_func(cmd Command) {
	for scope, dir in link_dirs {
		$if test {
			if scope != 'test' {
				continue
			}
		} $else {
			if scope == 'test' {
				continue
			}
		}
		linkmap, msg := linker.get_real_links(scope)
		if msg != '' {
			println(msg)
			continue
		}
		println(term.bold('$scope links:'))
		f_real := cmd.flags.get_bool_or('real', false)
		if f_real {
			// TODO: function to get invalid links
			mut invalid_links := []string{}
			for link, real_path in linkmap {
				link_path := dir + link
				if link_path == real_path {
					invalid_links << link
					continue
				}
				println('  $link: $real_path')
			}
			for inv_link in invalid_links {
				println(term.bright_magenta('  INVALID') + ' $inv_link')
			}
		} else {
			mut links := []string{}
			for link, real_path in linkmap {
				link_path := dir + link
				if link_path == real_path {
					links << term.bright_magenta(link)
					continue
				}
				links << link
			}
			// TODO: move pretty print into extra function
			mut rows := []string{}
			mut row_idx := 0
			for i, l in links {
				if i % 5 == 0 {
					rows << ''
					row_idx = i / 5
				}
				rows[row_idx] += '$l, '
			}
			rows[rows.len - 1] = rows.last().all_before_last(', ')
			for row in rows {
				println('  $row')
			}
		}
	}
}

fn update_func(cmd Command) {
	// TODO: move parts to linker
	name_flag_val := cmd.flags.get_string_or('name', '')
	path_flag_val := cmd.flags.get_string_or('path', '')
	update_name := name_flag_val != ''
	update_path := path_flag_val != ''
	if !update_name && !update_path {
		term.fail_message('`update` should be used with at least one flag')
		exit(1)
	}
	scope := get_scope(cmd)
	link_parent_dir := get_dir(scope)
	mut curr_name := cmd.args[0]
	curr_path := link_parent_dir + curr_name
	if !os.exists(curr_path) {
		term.fail_message('Cannot update inexistent link "$curr_path"')
		exit(1)
	}
	new_link_source := if update_path { path_flag_val } else { curr_name }
	new_link_dest := if update_name { name_flag_val } else { curr_name }
	linker.create_link(new_link_source, new_link_dest, scope) or {
		term.fail_message(err)
		exit(1)
	}
	os.rm(curr_path) or {
		panic(err)
	}
	if update_name {
		println('Renamed $scope link "$curr_name" to "$new_link_dest".')
	}
	if update_path {
		curr_name = new_link_dest
		real_source := os.real_path(new_link_source)
		println('Changed path of "$curr_name" to "$real_source".')
	}
}

fn open_func(cmd Command) {
	// TODO: move parts to linker
	if os.getenv('SUDO_USER') != '' {
		term.fail_message('Please run without `sudo`.')
		exit(1)
	}
	scope := get_scope(cmd)
	mut dir := get_dir(scope)
	if cmd.args.len >= 1 {
		target_link := cmd.args[0]
		links := os.ls(dir) or {
			panic(err)
		}
		if target_link in links {
			dir = os.real_path(dir + target_link).all_before_last('/')
			println('Opening the directory of "$target_link"...')
		} else {
			term.fail_message('Cannot open directory: "$target_link" is no $scope link')
			exit(1)
		}
	} else {
		println('Opening the $scope symlink folder...')
	}
	command := 'xdg-open $dir'
	os.exec(command) or {
		panic(err)
	}
}

fn validate_name_flag(name, alt_name string) (string, string) {
	mut msg := ''
	mut tname := name
	if tname.ends_with(' ') {
		tname = tname.trim_space()
		if tname.len == 0 {
			msg = 'Value of `--name` is empty, "$alt_name" will be used instead.'
		}
	}
	if tname == '' {
		tname = os.file_name(alt_name)
	}
	return tname, msg
}

fn get_scope(cmd Command) string {
	$if test {
		return 'test'
	}
	machine_wide := cmd.flags.get_bool_or('machine', false)
	return if machine_wide {
		'machine-wide'
	} else {
		'per-user'
	}
}

fn get_dir(scope string) string {
	$if test {
		return test_link_dir
	}
	return link_dirs[scope]
}
