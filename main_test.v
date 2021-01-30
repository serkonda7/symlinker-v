module main

import os

const (
	troot   = os.temp_dir() + '/symlinker'
	tsource = troot + '/tfiles/'
	link1   = 'link1'
	link2   = 'link2'
	link3   = 'link3'
)

fn testsuite_begin() {
	os.rmdir_all(troot) or { }
	os.mkdir_all(tsource) or { panic(err) }
	os.chdir(tsource)
	os.write_file(link1, '') or { panic(err) }
	os.write_file(link2, '') or { panic(err) }
	os.write_file(link3, '') or { panic(err) }
}

fn testsuite_end() {
	os.chdir(os.wd_at_startup)
	os.rmdir_all(troot) or { }
}

fn test_name_from_source_or_flag() {
	// simple value for name flag
	mut res := name_from_source_or_flag('l1', '')
	assert res.name == 'l1'
	assert res.msg == ''
	// name flag was not set
	res = name_from_source_or_flag('', 'l2')
	assert res.name == 'l2'
	assert res.msg == ''
	// with bad spaces
	res = name_from_source_or_flag(' l 3  ', '')
	assert res.name == 'l 3'
	assert res.msg == ''
	// only spaces
	res = name_from_source_or_flag('   ', 'l4')
	assert res.name == 'l4'
	assert res.msg == 'Value of `--name` is empty, "l4" will be used instead.'
}

fn test_array_to_rows() {
	arr := ['Lorem', 'ipsum', 'dolor', 'sit', 'amet']
	single_row := array_to_rows(arr, 5)
	assert single_row == ['Lorem, ipsum, dolor, sit, amet']
	rows := array_to_rows(arr, 3)
	assert rows == ['Lorem, ipsum, dolor, ', 'sit, amet']
}

fn test_name_max() {
	names := ['Lorem', 'sit', 'amet']
	expected := 5
	assert name_max(names) == expected
}

/*
fn test_link_cmd() {
	mut app := new_app()
	app.parse(['', 'link', 'link1'])
	app = new_app()
	app.parse(['', 'link', '--name', 'alt_link', 'link2'])
	app = new_app()
	app.parse(['', 'link', 'link3'])
	app = new_app()
	app.parse(['', 'link', '--machine', 'link3'])
}

fn test_list_cmd() {
	mut app := new_app()
	app.parse(['', 'list'])
	app = new_app()
	app.parse(['', 'list', '--real'])
}

fn test_update_cmd() {
	mut app := new_app()
	app.parse(['', 'update', '--name', 'alt2', 'alt_link'])
	app = new_app()
	app.parse(['', 'update', '--path', 'link1', 'alt2'])
	app = new_app()
	app.parse(['', 'update', '--name', 'alt_link', '--path', 'link2', 'alt2'])
}

fn test_del_cmd() {
	mut app := new_app()
	app.parse(['', 'del', 'link1'])
	app = new_app()
	app.parse(['', 'del', 'alt_link', 'link3'])
}
*/
// TODO: open
