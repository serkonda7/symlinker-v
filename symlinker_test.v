module main

import os

const (
	tfolder = os.join_path(os.temp_dir(), 'symlinker', 'tfiles')
	source_name = '__sl_test'
)

fn testsuite_begin() {
	os.rmdir_all(tfolder)
	os.mkdir_all(tfolder)
	os.chdir(tfolder)
	os.write_file(source_name, '') or {
		panic(err)
	}
}

fn testsuite_end() {
	os.chdir(os.wd_at_startup)
	os.rmdir_all(tfolder)
}

fn test_create_link() {
	scope := 'user'
	link_dir := link_dirs[scope]
	// symlinker link ./__sl_test
	create_link(scope, source_name, source_name)
	assert os.exists(link_dir + source_name)
	// symlinker link -n __sl_test2 ./__sl_test
	dest_name := '__sl_test2'
	create_link(scope, source_name, dest_name)
	assert os.exists(link_dir + dest_name)
}
