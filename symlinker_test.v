module main

import os

const (
	tfolder = os.join_path( os.temp_dir(), 'symlinker', 'test')
)

fn testsuite_begin() {
	os.rmdir_all(tfolder)
	os.mkdir_all(tfolder)
	os.chdir(tfolder)
}

fn testsuite_end() {
	os.chdir(os.wd_at_startup)
	os.rmdir_all(tfolder)
}

fn test_create_link() {
	scope := 'user'
	source_name := '_symlinker_test_file'
	os.write_file(source_name, '') or {
		panic(err)
	}
	mut test_links := []string{}
	// symlinker link ./_symlinker_test_file
	create_link(scope, source_name, source_name)
	assert os.exists(link_dirs['user'] + source_name)
	os.rm(link_dirs['user'] + source_name) or {
		panic(err)
	}
}
