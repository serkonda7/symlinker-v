module linker

import os
import term

const (
	link_dirs = {
		'per-user': os.home_dir() + '.local/bin/'
		'machine-wide': '/usr/local/bin/'
		'test': os.temp_dir() + '/symlinker/tlinks/'
	}
)

pub fn create_link(source_name, target_name, scope string) ?string {
	target_dir := get_dir(scope)
	if !os.exists(target_dir) {
		os.mkdir_all(target_dir)
	}
	source_path := os.real_path(source_name)
	if !os.exists(source_path) {
		return error('Source file "$source_path" does not exist.')
	}
	target_path := target_dir + target_name
	if os.exists(target_path) {
		if os.is_link(target_path) {
			if os.real_path(target_path) == source_path {
				return '`${term.bold(target_name)}` already links to "$source_path".'
			}
			// TODO: show tip to use `update`
			return error('Another $scope link with name `$target_name` does already exist.')
		}
		return error('File with name "$target_name" does already exist.')
	}
	os.symlink(source_path, target_path) or {
		return error('Permission denied.')
	}
	return 'Created $scope link `${term.bold(target_name)}` to "$source_path".'
}

pub fn delete_link(name, scope string) ?string {
	dir := get_dir(scope)
	link_path := dir + name
	if !os.is_link(link_path) {
		if !os.exists(link_path) {
			oscope := other_scope(scope)
			other_link_path := get_dir(oscope) + name
			sudo, flag := if oscope == 'machine-wide' { 'sudo ', '-m ' } else {'', ''}
			other_cmd := '${sudo}symlinker del $flag$name'
			if os.is_link(other_link_path) {
				// TODO: allow for testing this error
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
	return 'Deleted $scope link `$name` to "$source_path".'
}

// TODO: remove this
pub fn get_links(scope string) ([]string, string) {
	mut msg := ''
	dir := get_dir(scope)
	files := os.ls(dir) or {
		panic(err)
	}
	links := files.filter(os.is_link(dir + it))
	if links.len == 0 {
		msg = 'No $scope symlinks detected.'
	}
	return links, msg
}

pub fn get_real_links(scope string) (map[string]string, string) {
	mut linkmap := map[string]string
	links, msg := get_links(scope)
	dir := get_dir(scope)
	for l in links {
		linkmap[l] = os.real_path(dir + l)
	}
	return linkmap, msg
}

fn get_dir(scope string) string {
	return link_dirs[scope]
}

fn other_scope(scope string) string {
	$if test {
		return 'test'
	}
	return if scope == 'per-user' {
		'machine-wide'
	} else {
		'per-user'
	}
}
