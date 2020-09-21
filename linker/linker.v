module linker

import os
import term

const (
	// TODO: user --> per-user
	link_dirs = {
		'user': os.home_dir() + '.local/bin/'
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

fn get_dir(scope string) string {
	return link_dirs[scope]
}
