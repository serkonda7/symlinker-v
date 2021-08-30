module main

import os
import term

const (
	link_dirs = {
		Scope.user:         os.home_dir() + '/.local/bin'
		Scope.machine_wide: '/usr/local/bin'
		Scope.t_user:       os.temp_dir() + '/symlinker/tu_links'
		Scope.t_machine:    os.temp_dir() + '/symlinker/tm_links'
	}
)

enum Scope {
	user
	machine_wide
	t_user
	t_machine
}

fn create_link(source_name string, linkname string, scope Scope) ?string {
	link_dir := get_dir(scope)
	if !os.exists(link_dir) {
		os.mkdir_all(link_dir) ?
	}
	source_path := os.real_path(source_name)
	if !os.exists(source_path) {
		return error('Source file "$source_path" does not exist.')
	}
	link_name := os.file_name(linkname)
	link_path := '$link_dir/$link_name'
	if os.exists(link_path) {
		if os.is_link(link_path) {
			if os.real_path(link_path) == source_path {
				return '`${term.bold(link_name)}` already links to "$source_path".'
			}
			return error('Another $scope link with name `$link_name` does already exist.')
		}
		return error('File with name "$link_name" does already exist.')
	}
	os.symlink(source_path, link_path) or { return error('Permission denied.') }
	return 'Created $scope link `${term.bold(link_name)}` to "$source_path".'
}

fn delete_link(link_name string, scope Scope) ?string {
	dir := get_dir(scope)
	name := os.file_name(link_name)
	link_path := '$dir/$name'
	if !os.is_link(link_path) {
		if !os.exists(link_path) {
			oscope := other_scope(scope)
			other_link_path := get_dir(oscope) + '/$name'
			sudo, f := if oscope in [Scope.t_machine, Scope.machine_wide] {
				'sudo ', '-m '
			} else {
				'', ''
			}
			other_cmd := '${sudo}symlinker del $f$name'
			if os.is_link(other_link_path) {
				return error('`$name` is a $oscope link. Run `$other_cmd` to delete it.')
			}
			return error('$scope link `$name` does not exist.')
		}
		return error('Only symlinks can be deleted but "$name" is no $scope link.')
	}
	source_path := os.real_path(link_path)
	os.rm(link_path) or { return error('Permission denied.') }
	if source_path == link_path {
		return 'Deleted invalid link `$name`.'
	}
	return 'Deleted $scope link `${term.bold(name)}` to "$source_path".'
}

fn get_real_links(scope Scope) (map[string]string, string) {
	mut msg := ''
	mut linkmap := map[string]string{}
	dir := get_dir(scope)
	files := os.ls(dir) or { []string{} }
	mut links := files.filter(os.is_link('$dir/$it'))
	links.sort()
	if links.len == 0 {
		msg = 'No $scope symlinks detected.'
	}
	for l in links {
		linkmap[l] = os.real_path('$dir/$l')
	}
	return linkmap, msg
}

fn update_link(oldname string, scope Scope, newname string, new_source string) ?[]string {
	new_name := os.file_name(newname)
	old_name := os.file_name(oldname)
	old_path := get_dir(scope) + '/$old_name'
	if !os.is_link(old_path) {
		return error('Cannot update inexistent $scope link `$old_name`.')
	}
	if new_name == old_name {
		return error('New name (`$new_name`) cannot be the same as current name.')
	}
	old_rsource := os.real_path(old_path)
	new_rsource := os.real_path(new_source)
	if new_rsource == old_rsource {
		return error('New source path ("$new_rsource") cannot be the same as old source path.')
	}
	update_name := new_name != ''
	update_source := new_source != ''
	if !update_name && !update_source {
		return error('`update` requires at least one of flag of `--name` and `--path`.')
	}
	name_to_set := if update_name { new_name } else { old_name }
	source_to_set := if update_source { new_source } else { old_rsource }
	old_copy_path := '$os.temp_dir()/$old_name'
	os.cp(old_path, old_copy_path) or {} // Backup copy should not cause the program to fail
	os.rm(old_path) or { panic(err) }
	create_link(source_to_set, name_to_set, scope) or {
		// Restore the backup on fail
		if os.exists(old_copy_path) {
			os.cp(old_copy_path, old_path) or { panic(err) }
		}
		return err
	}
	mut messages := []string{}
	if update_name {
		messages << 'Renamed $scope link `$old_name` to `${term.bold(new_name)}`.'
	}
	if update_source {
		messages << if old_path == old_rsource {
			'Set path of `${term.bold(name_to_set)}` to "$new_rsource".'
		} else {
			'Changed path of `${term.bold(name_to_set)}` from "$old_rsource" to "$new_rsource".'
		}
	}
	return messages
}

fn open_link_dir(name string, scope Scope) ?(string, string) {
	link_name := os.file_name(name)
	mut dir := get_dir(scope)
	mut msg := ''
	if link_name == '' {
		if !os.exists(dir) {
			os.mkdir_all(dir) ?
		}
		msg = 'Opening the $scope symlink folder...'
	} else {
		links := os.ls(dir) or { []string{} }
		if link_name in links && os.is_link('$dir/$link_name') {
			dir = os.real_path('$dir/$link_name').all_before_last('/')
			msg = 'Opening the source directory of `$link_name`...'
		} else {
			oscope := other_scope(scope)
			other_link_path := get_dir(oscope) + '/$link_name'
			if os.is_link(other_link_path) {
				flag := if oscope == .t_machine || oscope == .machine_wide { '-m ' } else { '' }
				other_cmd := 'symlinker open $flag$link_name'
				return error("`$link_name` is a $oscope link. Run `$other_cmd` to open it's source directory.")
			}
			return error('Cannot open source directory of inexistent $scope link `$link_name`.')
		}
	}
	return 'xdg-open $dir &>/dev/null', msg
}

fn split_valid_invalid_links(linkmap map[string]string, scope Scope) ([]string, []string) {
	mut valid := []string{}
	mut invalid := []string{}
	dir := get_dir(scope)
	for lnk, real_path in linkmap {
		link_path := '$dir/$lnk'
		if link_path == real_path {
			invalid << lnk
		} else {
			valid << lnk
		}
	}
	return valid, invalid
}

fn get_dir(scope Scope) string {
	return link_dirs[scope]
}

fn other_scope(scope Scope) Scope {
	$if test {
		return if scope == .t_user { Scope.t_machine } else { Scope.t_user }
	} $else {
		return if scope == .user { Scope.machine_wide } else { Scope.user }
	}
}
