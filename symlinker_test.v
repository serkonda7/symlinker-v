module main

import os

const (
	tfolder = os.join_path(os.temp_dir(), 'symlinker', 'tfiles')
	source_name = 'sl_test'
	scope = 'test'
)

fn testsuite_begin() {
	os.rmdir_all(tfolder)
	os.mkdir_all(tfolder)
	os.chdir(tfolder)
	os.write_file(source_name, '') or {
		panic(err)
	}
	os.write_file('normal_file', '') or {
		panic(err)
	}
}

fn testsuite_end() {
	os.chdir(os.wd_at_startup)
	os.rmdir_all(tfolder)
}

fn test_create_link() {
	link_dir := link_dirs[scope]
	// symlinker link ./sl_test
	create_link(scope, source_name, source_name)
	assert os.exists(link_dir + source_name)
	// symlinker link -n sl_test2 ./sl_test
	dest_name := 'sl_test2'
	create_link(scope, source_name, dest_name)
	assert os.exists(link_dir + dest_name)
}

fn test_create_link_errors() {
	// symlinker link ./sl_test_inexistent
	invalid_source := 'sl_test_inexistent'
	create_link(scope, invalid_source, invalid_source) or {
		assert err == 'Cannot link inexistent file "$invalid_source"'
	}
	// symlinker link ./sl_test
	create_link(scope, source_name, source_name) or {
		assert err == '$scope link with name "$source_name" already exists'
	}
	// symlinker link -n normal_file ./sl_test
	dest_name := 'normal_file'
	create_link(scope, source_name, dest_name) or {
		assert err == 'File with name "$dest_name" already exists'
	}
}
