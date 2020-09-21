import os
import term
import linker

const (
	scope           = 'test'
	ttarget = linker.link_dirs['test']
	troot           = os.temp_dir() + '/symlinker'
	tsource = troot + '/tfiles/'
	sl_test         = 'test'
	sl_test2        = 'test2'
	normal_file     = 'normal_file'
	inexistent      = 'inexistent'
)

fn testsuite_begin() {
	os.rmdir_all(troot)
	os.mkdir_all(tsource)
	os.mkdir_all(ttarget)
	os.chdir(ttarget)
	os.write_file(normal_file, '') or {
		panic(err)
	}
	os.chdir(tsource)
	os.write_file(sl_test, '') or {
		panic(err)
	}
	os.write_file(sl_test2, '') or {
		panic(err)
	}
}

fn testsuite_end() {
	os.chdir(os.wd_at_startup)
	os.rmdir_all(troot)
}

fn test_create_link() {
	mut msg := linker.create_link(sl_test, sl_test, scope) or { '' }
	assert link_exists(sl_test)
	assert msg == 'Created $scope link `${term.bold(sl_test)}` to "$tsource$sl_test".'
	msg = linker.create_link(sl_test, sl_test2, scope) or { '' }
	assert link_exists(sl_test)
	assert msg == 'Created $scope link `${term.bold(sl_test2)}` to "$tsource$sl_test".'
	msg = linker.create_link(sl_test, sl_test, scope) or { '' }
	assert link_exists(sl_test)
	assert msg == '`${term.bold(sl_test)}` already links to "$tsource$sl_test".'
}

fn test_create_link_errors() {
	mut err_count := 0
	linker.create_link(inexistent, inexistent, scope) or {
		err_count++
		assert err == 'Source file "$inexistent" does not exist.'
	}
	linker.create_link(sl_test2, sl_test2, scope) or {
		err_count++
		assert err == 'Another $scope link with name `$sl_test2` does already exist.'
	}
	linker.create_link(sl_test, normal_file, scope) or {
		err_count++
		assert err == 'File with name "$normal_file" does already exist.'
	}
	assert err_count == 3
}

// Helper functions
fn link_exists(name string) bool {
	path := ttarget + name
	return os.is_link(path)
}

/*
fn test_get_links() {
	mut links := get_links(test_link_dir)
	links.sort()
	assert links == [sl_test, sl_test2]
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
*/
