module linker

import os

const (
	link_dirs     = {
		'per-user': os.home_dir() + '.local/bin/'
		'machine-wide': '/usr/local/bin/'
	}
)

pub fn create_link(source_name, target_name, scope string) ? {
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
			// TODO: check if real link path is same as source
			return error('$scope link with name "$target_name" does already exist.')
		}
		return error('File with name "$target_name" does already exist.')
	}
	os.symlink(source_path, target_path) or {
		return error('Permission denied.')
	}
	println('Created $scope link "$target_name".')
}

fn get_dir(scope string) string {
	return link_dirs[scope]
}
