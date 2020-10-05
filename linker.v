module main

import os
import term

const (
	link_dirs      = {
		'per-user': os.home_dir() + '/.local/bin/'
		'machine-wide': '/usr/local/bin/'
	}
	test_link_dirs = {
		'tuser': os.temp_dir() + '/symlinker/tu_links/'
		'tmachine': os.temp_dir() + '/symlinker/tm_links/'
	}
)

fn create_link(source_name, linkname, scope string) ?string {
	link_dir := get_dir(scope)
	if !os.exists(link_dir) {
		os.mkdir_all(link_dir)
	}
	source_path := os.real_path(source_name)
	if !os.exists(source_path) {
		return error('Source file "$source_path" does not exist.')
	}
	link_name := os.file_name(linkname)
	link_path := link_dir + link_name
	if os.exists(link_path) {
		if os.is_link(link_path) {
			if os.real_path(link_path) == source_path {
				return '`${term.bold(link_name)}` already links to "$source_path".'
			}
			return error('Another $scope link with name `$link_name` does already exist.')
		}
		return error('File with name "$link_name" does already exist.')
	}
	os.symlink(source_path, link_path) or {
		return error('Permission denied.')
	}
	return 'Created $scope link `${term.bold(link_name)}` to "$source_path".'
}

fn delete_link(link_name, scope string) ?string {
	dir := get_dir(scope)
	name := os.file_name(link_name)
	link_path := dir + name
	if !os.is_link(link_path) {
		if !os.exists(link_path) {
			oscope := other_scope(scope)
			other_link_path := get_dir(oscope) + name
			sudo, flag := if oscope == 'tmachine' || oscope == 'machine-wide' { 'sudo ', '-m ' } else { '', '' }
			other_cmd := '${sudo}symlinker del $flag$name'
			if os.is_link(other_link_path) {
				return error('`$name` is a $oscope link. Run `$other_cmd` to delete it.')
			}
			return error('$scope link `$name` does not exist.')
		}
		return error('Only symlinks can be deleted but "$name" is no $scope link.')
	}
	source_path := os.real_path(link_path)
	os.rm(link_path) or {
		return error('Permission denied.')
	}
	if source_path == link_path {
		return 'Deleted invalid link `$name`.'
	}
	return 'Deleted $scope link `${term.bold(name)}` to "$source_path".'
}

fn get_real_links(scope string) (map[string]string, string) {
	mut msg := ''
	mut linkmap := map[string]string{}
	dir := get_dir(scope)
	files := os.ls(dir) or {
		[]string{}
	}
	links := files.filter(os.is_link(dir + it))
	if links.len == 0 {
		msg = 'No $scope symlinks detected.'
	}
	for l in links {
		linkmap[l] = os.real_path(dir + l)
	}
	return linkmap, msg
}

fn update_link(oldname, scope, newname, new_source string) ?[]string {
	new_name := os.file_name(newname)
	old_name := os.file_name(oldname)
	old_path := get_dir(scope) + old_name
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
		return error('`update` requires at least one of flag of `--name` and `--source`.')
	}
	name_to_set := if update_name { new_name } else { old_name }
	source_to_set := if update_source { new_source } else { old_rsource }
	os.rm(old_path) or {
		panic(err)
	}
	create_link(source_to_set, name_to_set, scope) or {
		return error(err)
	}
	mut messages := []string{}
	if update_name {
		messages << 'Renamed $scope link `$old_name` to `${term.bold(new_name)}`.'
	}
	if update_source {
		messages <<
			'Changed path of `${term.bold(name_to_set)}` from "$old_rsource" to "$new_rsource".'
	}
	return messages
}

fn open_link_dir(name, scope string) ?(string, string) {
	link_name := os.file_name(name)
	mut dir := get_dir(scope)
	mut msg := ''
	if link_name == '' {
		if !os.exists(dir) {
			os.mkdir_all(dir)
		}
		msg = 'Opening the $scope symlink folder...'
	} else {
		links := os.ls(dir) or {
			[]string{}
		}
		if link_name in links && os.is_link(dir + link_name) {
			dir = os.real_path(dir + link_name).all_before_last('/') + '/'
			msg = 'Opening the source directory of `$link_name`...'
		} else {
			oscope := other_scope(scope)
			other_link_path := get_dir(oscope) + link_name
			if os.is_link(other_link_path) {
				flag := if oscope == 'tmachine' || oscope == 'machine-wide' { '-m ' } else { '' }
				other_cmd := 'symlinker open $flag$link_name'
				return error("`$link_name` is a $oscope link. Run `$other_cmd` to open it's source directory.")
			}
			return error('Cannot open source directory of inexistent $scope link `$link_name`.')
		}
	}
	return 'xdg-open $dir &', msg
}

fn split_valid_invalid_links(linkmap map[string]string, scope string) ([]string, []string) {
	mut valid := []string{}
	mut invalid := []string{}
	dir := get_dir(scope)
	for lnk, real_path in linkmap {
		link_path := dir + lnk
		if link_path == real_path {
			invalid << lnk
		} else {
			valid << lnk
		}
	}
	return valid, invalid
}

fn get_dir(scope string) string {
	$if test {
		return test_link_dirs[scope]
	} $else {
		return link_dirs[scope]
	}
}

fn other_scope(scope string) string {
	$if test {
		return if scope == 'tuser' {
			'tmachine'
		} else {
			'tuser'
		}
	} $else {
		return if scope == 'per-user' {
			'machine-wide'
		} else {
			'per-user'
		}
	}
}
