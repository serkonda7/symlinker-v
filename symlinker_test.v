module main

import os

const (
	troot = os.join_path(os.temp_dir(), 'symlinker/')
	tfiles = (troot + 'tfiles/').replace('/', os.path_separator)
	tlinks = (troot + 'tlinks/').replace('/', os.path_separator)
	sl_test = 'sl_test'
	sl_test2 = 'sl_test2'
	normal_file = 'normal_file'
	inexistent = 'inexistent'
	scope = 'test'
)

fn testsuite_begin() {
	os.rmdir_all(troot)
	os.mkdir_all(troot)
	os.mkdir(tfiles) or {
		panic(err)
	}
	os.mkdir(tlinks) or {
		panic(err)
	}
	os.chdir(tlinks)
	os.write_file(normal_file, 'normal_file') or {
		panic(err)
	}
	os.chdir(tfiles)
	os.write_file(sl_test, 'sl_test') or {
		panic(err)
	}
}

fn testsuite_end() {
	os.chdir(os.wd_at_startup)
	os.rmdir_all(troot)
}

fn test_create_link() {
	// symlinker link ./sl_test
	create_link(scope, sl_test, sl_test)
	assert os.is_link(test_link_dir + sl_test)
	// symlinker link -n sl_test2 ./sl_test
	create_link(scope, sl_test, sl_test2)
	assert os.is_link(test_link_dir + sl_test2)
}

fn test_create_link_errors() {
	mut err_count := 0
	// link ./inexistent
	create_link(scope, inexistent, inexistent) or {
		err_count++
		assert err == 'Cannot link inexistent file "$inexistent"'
	}
	// link ./sl_test
	create_link(scope, sl_test, sl_test) or {
		err_count++
		assert err == '$scope link with name "$sl_test" already exists'
	}
	// link -n normal_file ./sl_test
	create_link(scope, sl_test, normal_file) or {
		err_count++
		assert err == 'File with name "$normal_file" already exists'
	}
	assert err_count == 3
}

fn test_get_links() {
	mut links := get_links(test_link_dir)
	links.sort()
	assert links == [sl_test, sl_test2,]
}

fn test_delete_link() {
	// del sl_test2
	delete_link(scope, test_link_dir, sl_test)
	assert !os.exists(test_link_dir + sl_test)
}

fn test_delete_link_errors() {
	mut err_count := 0
	// del inexistent
	delete_link(scope, test_link_dir, inexistent) or {
		err_count++
		assert err == '$scope link `$inexistent` does not exist'
	}
	// del normal_file
	delete_link(scope, test_link_dir, normal_file) or {
		err_count++
		assert err == '"$normal_file" is no $scope link'
	}
	assert err_count == 2
}

fn test_get_scope_by_dir() {
	scope := get_scope_by_dir(tlinks)
	assert scope == 'test'
}

fn test_get_dir() {
	dir := get_dir('test')
	assert dir == tlinks
}
