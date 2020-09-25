module main

import cli { Command }
import os
import term
import linker

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
		description: 'The new name for the link.'
	})
	update_cmd.add_flag({
		flag: .string
		name: 'source'
		abbrev: 's'
		description: 'The new source path it links to.'
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
	scopes := $if test { linker.test_link_dirs.keys() } $else { linker.link_dirs.keys() }
	for s, scope in scopes {
		linkmap, msg := linker.get_real_links(scope)
		if msg != '' {
			println(msg)
			continue
		}
		println(term.bold('$scope links:'))
		valid, invalid := linker.split_valid_invalid_links(linkmap, scope)
		f_real := cmd.flags.get_bool_or('real', false)
		if f_real {
			for v in valid {
				println('  $v: ${linkmap[v]}')
			}
			for inv in invalid {
				println(term.bright_magenta('  INVALID: $inv'))
			}
		} else {
			mut links := valid
			for inv in invalid {
				links << term.bright_magenta(inv)
			}
			// TODO: move pretty print into extra function
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
		if s < scopes.len - 1 {
			println('')
		}
	}
}

fn update_func(cmd Command) {
	name_flag_val := cmd.flags.get_string_or('name', '')
	source_flag_val := cmd.flags.get_string_or('source', '')
	scope := get_scope(cmd)
	link_name := cmd.args[0]
	messages := linker.update_link(link_name, scope, name_flag_val, source_flag_val) or {
		println(term.bright_red(err))
		exit(1)
	}
	for msg in messages {
		println(msg)
	}
}

fn open_func(cmd Command) {
	// TODO: move parts to linker
	if os.getenv('SUDO_USER') != '' {
		term.fail_message('Please run without `sudo`.')
		exit(1)
	}
	scope := get_scope(cmd)
	mut dir := linker.get_dir(scope)
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
