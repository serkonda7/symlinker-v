module linker

import os
import term

const (
	link_dirs = {
		'per-user': os.home_dir() + '.local/bin/'
		'machine-wide': '/usr/local/bin/'
	}
	test_link_dirs = {
		'tuser': os.temp_dir() + '/symlinker/tu_links/'
		'tmachine': os.temp_dir() + '/symlinker/tm_links/'
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
			mut sudo, mut flag := '', ''
			$if test {
				sudo, flag = if oscope == 'tmachine' { 'sudo ', '-m ' } else {'', ''}
			} $else {
				sudo, flag = if oscope == 'machine-wide' { 'sudo ', '-m ' } else {'', ''}
			}
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
	return 'Deleted $scope link `$name` to "$source_path".'
}

pub fn get_real_links(scope string) (map[string]string, string) {
	mut msg := ''
	mut linkmap := map[string]string
	dir := get_dir(scope)
	files := os.ls(dir) or {
		panic(err)
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

// TODO: add tests
pub fn split_valid_invalid_links(linkmap map[string]string, scope string) ([]string, []string) {
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
