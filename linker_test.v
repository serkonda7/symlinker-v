module main

import os
import term

const (
	uscope      = 'tuser'
	mscope      = 'tmachine'
	troot       = os.temp_dir() + '/symlinker'
	tsource     = troot + '/tfiles'
	sl_test     = 'test'
	sl_test2    = 'test2'
	sl_test3    = 'test3'
	link3       = 'link3'
	m_link      = 'm_link'
	inv         = 'invalid'
	normal_file = 'normal_file'
	inexistent  = 'inexistent'
)

fn testsuite_begin() ? {
	u_target := get_dir(main.uscope)
	m_target := get_dir(main.mscope)
	os.rmdir_all(main.troot)
	// Setup the source folder
	os.mkdir_all(main.tsource)
	os.chdir(main.tsource)
	os.write_file(main.sl_test, '') ?
	os.write_file(main.sl_test2, '') ?
	os.write_file(main.link3, '') ?
	os.write_file(main.m_link, '') ?
	os.write_file(main.inv, '') ?
	// Run tests that need the target folders to not exist
	linkmap, msg1 := get_real_links(main.uscope)
	assert linkmap.len == 0
	assert msg1 == 'No $main.uscope symlinks detected.'
	command, msg2 := open_link_dir('', main.uscope) or { panic(err) }
	assert command == 'xdg-open ${get_dir(main.uscope)} &>/dev/null'
	assert msg2 == 'Opening the $main.uscope symlink folder...'
	// Create the target folders
	os.mkdir_all(u_target)
	os.mkdir_all(m_target)
	os.chdir(u_target)
	os.write_file(main.normal_file, '') ?
	os.chdir(main.tsource)
}

fn testsuite_end() {
	os.chdir(os.wd_at_startup)
	os.rmdir_all(main.troot)
}

fn test_create_link() {
	// Create a normal link
	mut msg := create_link(main.sl_test, main.sl_test, main.uscope) or { panic(err) }
	assert link_exists(main.sl_test, main.uscope)
	assert msg == 'Created $main.uscope link `${term.bold(main.sl_test)}` to "$main.tsource/$main.sl_test".'
	// Link with different name
	msg = create_link(main.sl_test, main.sl_test2, main.uscope) or { panic(err) }
	assert link_exists(main.sl_test2, main.uscope)
	assert msg == 'Created $main.uscope link `${term.bold(main.sl_test2)}` to "$main.tsource/$main.sl_test".'
	// Link already links this file
	msg = create_link(main.sl_test, main.sl_test, main.uscope) or { panic(err) }
	assert link_exists(main.sl_test, main.uscope)
	assert msg == '`${term.bold(main.sl_test)}` already links to "$main.tsource/$main.sl_test".'
	// Create a link and make it invalid
	create_link(main.inv, main.inv, main.uscope)
	os.rm(main.inv) or { panic(err) }
	assert !os.exists(main.inv)
	// Create tmachine link
	msg = create_link(main.m_link, main.m_link, main.mscope) or { panic(err) }
	assert link_exists(main.m_link, main.mscope)
	assert msg == 'Created $main.mscope link `${term.bold(main.m_link)}` to "$main.tsource/$main.m_link".'
	// Path traversal attacks should not work
	msg = create_link(main.sl_test, '../$main.sl_test3', main.uscope) or { panic(err) }
	assert link_exists(main.sl_test3, main.uscope)
	assert !link_exists('../$main.sl_test3', main.uscope)
}

fn test_create_link_errors() {
	mut err_count := 0
	create_link(main.inexistent, main.inexistent, main.uscope) or {
		err_count++
		assert err == 'Source file "$main.inexistent" does not exist.'
	}
	create_link(main.sl_test2, main.sl_test2, main.uscope) or {
		err_count++
		assert err == 'Another $main.uscope link with name `$main.sl_test2` does already exist.'
	}
	create_link(main.sl_test, main.normal_file, main.uscope) or {
		err_count++
		assert err == 'File with name "$main.normal_file" does already exist.'
	}
	assert err_count == 3
}

fn test_update_link() {
	// Update name
	mut messages := update_link(main.sl_test, main.uscope, main.link3, '') or { panic(err) }
	assert link_exists(main.link3, main.uscope)
	assert messages == ['Renamed $main.uscope link `$main.sl_test` to `${term.bold(main.link3)}`.']
	// Update source
	messages = update_link(main.link3, main.uscope, '', main.link3) or { panic(err) }
	assert link_exists(main.link3, main.uscope)
	assert messages == ['Changed path of `${term.bold(main.link3)}` from "$main.tsource/$main.sl_test" to "$main.tsource/$main.link3".']
	// Update name and source
	messages = update_link(main.link3, main.uscope, main.sl_test, main.sl_test) or { panic(err) }
	assert link_exists(main.sl_test, main.uscope)
	assert messages == ['Renamed $main.uscope link `$main.link3` to `${term.bold(main.sl_test)}`.', 'Changed path of `${term.bold(main.sl_test)}` from "$main.tsource/$main.link3" to "$main.tsource/$main.sl_test".']
}

fn test_update_link_errors() {
	mut err_count := 0
	update_link(main.inexistent, main.uscope, '', '') or {
		err_count++
		assert err == 'Cannot update inexistent $main.uscope link `$main.inexistent`.'
	}
	update_link(main.sl_test, main.uscope, main.sl_test, '') or {
		err_count++
		assert err == 'New name (`$main.sl_test`) cannot be the same as current name.'
	}
	update_link(main.sl_test, main.uscope, '', main.sl_test) or {
		err_count++
		assert err == 'New source path ("$main.tsource/$main.sl_test") cannot be the same as old source path.'
	}
	update_link(main.sl_test, main.uscope, '', '') or {
		err_count++
		assert err == '`update` requires at least one of flag of `--name` and `--path`.'
	}
	assert err_count == 4
}

fn test_get_real_links() {
	linkmap, msg := get_real_links(main.uscope)
	mut expected := map[string]string{}
	expected[main.inv] = get_dir(main.uscope) + '/$main.inv'
	expected[main.sl_test] = '$main.tsource/$main.sl_test'
	expected[main.sl_test2] = '$main.tsource/$main.sl_test'
	expected[main.sl_test3] = '$main.tsource/$main.sl_test'
	assert linkmap == expected
	assert msg == ''
}

fn test_split_valid_invalid_links() {
	linkmap, _ := get_real_links(main.uscope)
	mut valid_links, invalid_links := split_valid_invalid_links(linkmap, main.uscope)
	valid_links.sort()
	assert valid_links == [main.sl_test, main.sl_test2, main.sl_test3]
	assert invalid_links == [main.inv]
}

fn test_open_link_dir() {
	// Open symlink folder
	mut command, mut msg := open_link_dir('', main.uscope) or { panic(err) }
	assert command == 'xdg-open ${get_dir(main.uscope)} &>/dev/null'
	assert msg == 'Opening the $main.uscope symlink folder...'
	// Open a specific link
	command, msg = open_link_dir(main.sl_test, main.uscope) or { panic(err) }
	assert command == 'xdg-open $main.tsource &>/dev/null'
	assert msg == 'Opening the source directory of `$main.sl_test`...'
}

fn test_open_link_dir_errors() {
	mut err_count := 0
	open_link_dir(main.inexistent, main.uscope) or {
		err_count++
		assert err == 'Cannot open source directory of inexistent $main.uscope link `$main.inexistent`.'
	}
	// Scope suggestion user --> machine
	open_link_dir(main.m_link, main.uscope) or {
		err_count++
		assert err == "`$main.m_link` is a $main.mscope link. Run `symlinker open -m $main.m_link` to open it's source directory."
	}
	// Scope suggestion machine --> user
	open_link_dir(main.sl_test, main.mscope) or {
		err_count++
		assert err == "`$main.sl_test` is a $main.uscope link. Run `symlinker open $main.sl_test` to open it's source directory."
	}
	assert err_count == 3
}

fn test_delete_link_errors() {
	mut err_count := 0
	delete_link(main.inexistent, main.uscope) or {
		err_count++
		assert err == '$main.uscope link `$main.inexistent` does not exist.'
	}
	delete_link(main.normal_file, main.uscope) or {
		err_count++
		assert err == 'Only symlinks can be deleted but "$main.normal_file" is no $main.uscope link.'
	}
	// Scope suggestion user --> machine
	delete_link(main.m_link, main.uscope) or {
		err_count++
		assert err == '`$main.m_link` is a $main.mscope link. Run `sudo symlinker del -m $main.m_link` to delete it.'
	}
	// Scope suggestion machine --> user
	delete_link(main.sl_test, main.mscope) or {
		err_count++
		assert err == '`$main.sl_test` is a $main.uscope link. Run `symlinker del $main.sl_test` to delete it.'
	}
	assert err_count == 4
}

fn test_delete_link() {
	mut msg := delete_link(main.sl_test, main.uscope) or { panic(err) }
	assert !link_exists(main.sl_test, main.uscope)
	assert msg == 'Deleted $main.uscope link `${term.bold(main.sl_test)}` to "$main.tsource/$main.sl_test".'
	msg = delete_link(main.sl_test2, main.uscope) or { panic(err) }
	assert !link_exists(main.sl_test2, main.uscope)
	assert msg == 'Deleted $main.uscope link `${term.bold(main.sl_test2)}` to "$main.tsource/$main.sl_test".'
	delete_link(main.sl_test3, main.uscope) or { panic(err) }
	assert !link_exists(main.sl_test3, main.uscope)
	msg = delete_link(main.inv, main.uscope) or { panic(err) }
	assert !link_exists(main.inv, main.uscope)
	assert msg == 'Deleted invalid link `$main.inv`.'
}

fn test_get_real_links_in_empty_scope() {
	linkmap, msg := get_real_links(main.uscope)
	assert linkmap.len == 0
	assert msg == 'No $main.uscope symlinks detected.'
}

// Helper functions
fn link_exists(name string, scope string) bool {
	dir := get_dir(scope)
	return os.is_link('$dir/$name')
}

// TODO: link exists with source
