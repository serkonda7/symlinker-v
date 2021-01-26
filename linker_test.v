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
	u_target := get_dir(uscope)
	m_target := get_dir(mscope)
	os.rmdir_all(troot)
	// Setup the source folder
	os.mkdir_all(tsource)
	os.chdir(tsource)
	os.write_file(sl_test, '') ?
	os.write_file(sl_test2, '') ?
	os.write_file(link3, '') ?
	os.write_file(m_link, '') ?
	os.write_file(inv, '') ?
	// Run tests that need the target folders to not exist
	linkmap, msg1 := get_real_links(uscope)
	assert linkmap.len == 0
	assert msg1 == 'No $uscope symlinks detected.'
	command, msg2 := open_link_dir('', uscope) or { panic(err) }
	assert command == 'xdg-open ${get_dir(uscope)} &>/dev/null'
	assert msg2 == 'Opening the $uscope symlink folder...'
	// Create the target folders
	os.mkdir_all(u_target)
	os.mkdir_all(m_target)
	os.chdir(u_target)
	os.write_file(normal_file, '') ?
	os.chdir(tsource)
}

fn testsuite_end() {
	os.chdir(os.wd_at_startup)
	os.rmdir_all(troot)
}

fn test_create_link() {
	// Create a normal link
	mut msg := create_link(sl_test, sl_test, uscope) or { panic(err) }
	assert link_exists(sl_test, uscope)
	assert msg == 'Created $uscope link `${term.bold(sl_test)}` to "$tsource/$sl_test".'
	// Link with different name
	msg = create_link(sl_test, sl_test2, uscope) or { panic(err) }
	assert link_exists(sl_test2, uscope)
	assert msg == 'Created $uscope link `${term.bold(sl_test2)}` to "$tsource/$sl_test".'
	// Link already links this file
	msg = create_link(sl_test, sl_test, uscope) or { panic(err) }
	assert link_exists(sl_test, uscope)
	assert msg == '`${term.bold(sl_test)}` already links to "$tsource/$sl_test".'
	// Create a link and make it invalid
	create_link(inv, inv, uscope)
	os.rm(inv) or { panic(err) }
	assert !os.exists(inv)
	// Create tmachine link
	msg = create_link(m_link, m_link, mscope) or { panic(err) }
	assert link_exists(m_link, mscope)
	assert msg == 'Created $mscope link `${term.bold(m_link)}` to "$tsource/$m_link".'
	// Path traversal attacks should not work
	msg = create_link(sl_test, '../$sl_test3', uscope) or { panic(err) }
	assert link_exists(sl_test3, uscope)
	assert !link_exists('../$sl_test3', uscope)
}

fn test_create_link_errors() {
	mut err_count := 0
	create_link(inexistent, inexistent, uscope) or {
		err_count++
		assert err == 'Source file "$inexistent" does not exist.'
	}
	create_link(sl_test2, sl_test2, uscope) or {
		err_count++
		assert err == 'Another $uscope link with name `$sl_test2` does already exist.'
	}
	create_link(sl_test, normal_file, uscope) or {
		err_count++
		assert err == 'File with name "$normal_file" does already exist.'
	}
	assert err_count == 3
}

fn test_update_link() {
	// Update name
	mut messages := update_link(sl_test, uscope, link3, '') or { panic(err) }
	assert link_exists(link3, uscope)
	assert messages == ['Renamed $uscope link `$sl_test` to `${term.bold(link3)}`.']
	// Update source
	messages = update_link(link3, uscope, '', link3) or { panic(err) }
	assert link_exists(link3, uscope)
	assert messages == ['Changed path of `${term.bold(link3)}` from "$tsource/$sl_test" to "$tsource/$link3".']
	// Update name and source
	messages = update_link(link3, uscope, sl_test, sl_test) or { panic(err) }
	assert link_exists(sl_test, uscope)
	assert messages == ['Renamed $uscope link `$link3` to `${term.bold(sl_test)}`.', 'Changed path of `${term.bold(sl_test)}` from "$tsource/$link3" to "$tsource/$sl_test".']
}

fn test_update_link_errors() {
	mut err_count := 0
	update_link(inexistent, uscope, '', '') or {
		err_count++
		assert err == 'Cannot update inexistent $uscope link `$inexistent`.'
	}
	update_link(sl_test, uscope, sl_test, '') or {
		err_count++
		assert err == 'New name (`$sl_test`) cannot be the same as current name.'
	}
	update_link(sl_test, uscope, '', sl_test) or {
		err_count++
		assert err == 'New source path ("$tsource/$sl_test") cannot be the same as old source path.'
	}
	update_link(sl_test, uscope, '', '') or {
		err_count++
		assert err == '`update` requires at least one of flag of `--name` and `--path`.'
	}
	assert err_count == 4
}

fn test_get_real_links() {
	linkmap, msg := get_real_links(uscope)
	mut expected := map[string]string{}
	expected[inv] = get_dir(uscope) + '/$inv'
	expected[sl_test] = '$tsource/$sl_test'
	expected[sl_test2] = '$tsource/$sl_test'
	expected[sl_test3] = '$tsource/$sl_test'
	assert linkmap == expected
	assert msg == ''
}

fn test_split_valid_invalid_links() {
	linkmap, _ := get_real_links(uscope)
	mut valid_links, invalid_links := split_valid_invalid_links(linkmap, uscope)
	valid_links.sort()
	assert valid_links == [sl_test, sl_test2, sl_test3]
	assert invalid_links == [inv]
}

fn test_open_link_dir() {
	// Open symlink folder
	mut command, mut msg := open_link_dir('', uscope) or { panic(err) }
	assert command == 'xdg-open ${get_dir(uscope)} &>/dev/null'
	assert msg == 'Opening the $uscope symlink folder...'
	// Open a specific link
	command, msg = open_link_dir(sl_test, uscope) or { panic(err) }
	assert command == 'xdg-open $tsource &>/dev/null'
	assert msg == 'Opening the source directory of `$sl_test`...'
}

fn test_open_link_dir_errors() {
	mut err_count := 0
	open_link_dir(inexistent, uscope) or {
		err_count++
		assert err == 'Cannot open source directory of inexistent $uscope link `$inexistent`.'
	}
	// Scope suggestion user --> machine
	open_link_dir(m_link, uscope) or {
		err_count++
		assert err == "`$m_link` is a $mscope link. Run `symlinker open -m $m_link` to open it's source directory."
	}
	// Scope suggestion machine --> user
	open_link_dir(sl_test, mscope) or {
		err_count++
		assert err == "`$sl_test` is a $uscope link. Run `symlinker open $sl_test` to open it's source directory."
	}
	assert err_count == 3
}

fn test_delete_link_errors() {
	mut err_count := 0
	delete_link(inexistent, uscope) or {
		err_count++
		assert err == '$uscope link `$inexistent` does not exist.'
	}
	delete_link(normal_file, uscope) or {
		err_count++
		assert err == 'Only symlinks can be deleted but "$normal_file" is no $uscope link.'
	}
	// Scope suggestion user --> machine
	delete_link(m_link, uscope) or {
		err_count++
		assert err == '`$m_link` is a $mscope link. Run `sudo symlinker del -m $m_link` to delete it.'
	}
	// Scope suggestion machine --> user
	delete_link(sl_test, mscope) or {
		err_count++
		assert err == '`$sl_test` is a $uscope link. Run `symlinker del $sl_test` to delete it.'
	}
	assert err_count == 4
}

fn test_delete_link() {
	mut msg := delete_link(sl_test, uscope) or { panic(err) }
	assert !link_exists(sl_test, uscope)
	assert msg == 'Deleted $uscope link `${term.bold(sl_test)}` to "$tsource/$sl_test".'
	msg = delete_link(sl_test2, uscope) or { panic(err) }
	assert !link_exists(sl_test2, uscope)
	assert msg == 'Deleted $uscope link `${term.bold(sl_test2)}` to "$tsource/$sl_test".'
	delete_link(sl_test3, uscope) or { panic(err) }
	assert !link_exists(sl_test3, uscope)
	msg = delete_link(inv, uscope) or { panic(err) }
	assert !link_exists(inv, uscope)
	assert msg == 'Deleted invalid link `$inv`.'
}

fn test_get_real_links_in_empty_scope() {
	linkmap, msg := get_real_links(uscope)
	assert linkmap.len == 0
	assert msg == 'No $uscope symlinks detected.'
}

// Helper functions
fn link_exists(name string, scope string) bool {
	dir := get_dir(scope)
	return os.is_link('$dir/$name')
}

// TODO: link exists with source
