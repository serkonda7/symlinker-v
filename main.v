module main

import cli { Command, Flag }
import os
import term
import v.vmod

fn main() {
	mut app := new_app()
	app.parse(os.args)
}

fn new_app() Command {
	mod := vmod.decode(@VMOD_FILE) or { panic(err) }
	mut app := Command{
		name: 'symlinker'
		description: mod.description
		version: mod.version
		disable_flags: true
		sort_commands: false
		flags: [
			Flag{
				flag: .bool
				name: 'machine'
				abbrev: 'm'
				description: 'Execute the command machine-wide.'
				global: true
			},
		]
	}
	link_cmd := Command{
		name: 'link'
		description: 'Create a new symlink to <file>.'
		usage: '<file>'
		required_args: 1
		execute: link_func
		flags: [
			Flag{
				flag: .string
				name: 'name'
				abbrev: 'n'
				description: 'Use a custom name for the link.'
			},
		]
	}
	del_cmd := Command{
		name: 'del'
		description: 'Delete all specified symlinks.'
		usage: '<link1> <...>'
		required_args: 1
		execute: del_func
	}
	list_cmd := Command{
		name: 'list'
		description: 'List all symlinks.'
		execute: list_func
		flags: [
			Flag{
				flag: .bool
				name: 'real'
				abbrev: 'r'
				description: 'Also print the path the links point to.'
			},
		]
	}
	update_cmd := Command{
		name: 'update'
		description: "Rename a symlink or update it's real path. Use at least on of the flags."
		usage: '<link>'
		required_args: 1
		execute: update_func
		flags: [
			Flag{
				flag: .string
				name: 'name'
				abbrev: 'n'
				description: 'The new name for the link.'
			},
			Flag{
				flag: .string
				name: 'path'
				abbrev: 'p'
				description: 'The new path that will be linked'
			},
		]
	}
	open_cmd := Command{
		name: 'open'
		description: 'Open a specific symlink or the general root dir in the file explorer.'
		usage: '[link]'
		execute: open_func
	}
	app.add_commands([link_cmd, del_cmd, list_cmd, update_cmd, open_cmd])
	app.setup()
	return app
}

fn link_func(cmd Command) {
	scope := get_scope(cmd)
	source_name := cmd.args[0]
	name_flag_val := cmd.flags.get_string('name') or { '' }
	name_res := name_from_source_or_flag(name_flag_val, source_name)
	if name_res.msg != '' {
		println(name_res.msg)
	}
	msg := create_link(source_name, name_res.name, scope) or {
		println(term.bright_red(err))
		exit(1)
	}
	println(msg)
}

fn del_func(cmd Command) {
	scope := get_scope(cmd)
	mut err_count := 0
	for arg in cmd.args {
		msg := delete_link(arg, scope) or {
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
	scopes := $if test { test_link_dirs.keys() } $else { link_dirs.keys() }
	for i, scope in scopes {
		linkmap, msg := get_real_links(scope)
		if msg != '' {
			println('$msg\n')
			continue
		}
		println(term.bold('$scope links:'))
		valid, invalid := split_valid_invalid_links(linkmap, scope)
		f_real := cmd.flags.get_bool('real') or { false }
		if f_real {
			max_len := name_max(valid)
			for v in valid {
				s := ' '.repeat(max_len - v.len + 1)
				println('  $v:$s${linkmap[v]}')
			}
			for inv in invalid {
				println(term.bright_magenta('  INVALID: $inv'))
			}
		} else {
			mut links := valid.clone()
			for inv in invalid {
				links << term.bright_magenta(inv)
			}
			rows := array_to_rows(links, 5)
			for row in rows {
				println('  $row')
			}
		}
		if i < scopes.len - 1 {
			println('')
		}
	}
}

fn update_func(cmd Command) {
	name_flag_val := cmd.flags.get_string('name') or { '' }
	path_flag_val := cmd.flags.get_string('path') or { '' }
	scope := get_scope(cmd)
	link_name := cmd.args[0]
	messages := update_link(link_name, scope, name_flag_val, path_flag_val) or {
		println(term.bright_red(err))
		exit(1)
	}
	for msg in messages {
		println(msg)
	}
}

fn open_func(cmd Command) {
	if os.getenv('SUDO_USER') != '' {
		println(term.bright_red('Please run without `sudo`.'))
		exit(1)
	}
	scope := get_scope(cmd)
	link_name := if cmd.args.len >= 1 { cmd.args[0] } else { '' }
	command, msg := open_link_dir(link_name, scope) or {
		println(term.bright_red(err))
		exit(1)
	}
	println(msg)
	os.execute(command)
}

struct NameResult {
	name string
	msg  string
}

fn name_from_source_or_flag(flag_val string, source_val string) NameResult {
	if flag_val.len > 0 {
		name := flag_val.trim_space()
		if name.len > 0 {
			return {
				name: name
			}
		}
		return {
			name: source_val
			msg: 'Value of `--name` is empty, "$source_val" will be used instead.'
		}
	}
	return {
		name: source_val
	}
}

fn array_to_rows(arr []string, max_row_entries int) []string {
	mut rows := []string{}
	mut row_idx := 0
	for i, a in arr {
		if i % max_row_entries == 0 {
			rows << ''
			row_idx = i / max_row_entries
		}
		rows[row_idx] += '$a, '
	}
	rows[rows.len - 1] = rows.last().all_before_last(', ')
	return rows
}

fn name_max(names []string) int {
	mut max := 0
	for n in names {
		if n.len > max {
			max = n.len
		}
	}
	return max
}

fn get_scope(cmd Command) string {
	machine_wide := cmd.flags.get_bool('machine') or { false }
	$if test {
		return if machine_wide { 'tmachine' } else { 'tuser' }
	} $else {
		return if machine_wide { 'machine-wide' } else { 'per-user' }
	}
}
