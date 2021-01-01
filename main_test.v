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
	os.rmdir_all(troot)
	os.mkdir_all(tsource)
	os.chdir(tsource)
	os.write_file(link1, '') or { panic(err) }
	os.write_file(link2, '') or { panic(err) }
	os.write_file(link3, '') or { panic(err) }
}

fn testsuite_end() {
	os.chdir(os.wd_at_startup)
	os.rmdir_all(troot)
}

fn test_name_flag_validation() {
	valid_tname := 'mylink'
	mut tname, mut msg := validate_name_flag(valid_tname, '')
	assert tname == valid_tname
	assert msg == ''
	tname, msg = validate_name_flag(' mylink  ', '')
	assert tname == valid_tname
	assert msg == ''
	tname, msg = validate_name_flag('   ', valid_tname)
	assert tname == valid_tname
	assert msg == 'Value of `--name` is empty, "$valid_tname" will be used instead.'
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

fn test_link_cmd() {
	mut cmd := create_cmd()
	cmd.parse(['', 'link', 'link1'])
	cmd = create_cmd()
	cmd.parse(['', 'link', '--name', 'alt_link', 'link2'])
	cmd = create_cmd()
	cmd.parse(['', 'link', 'link3'])
	cmd = create_cmd()
	cmd.parse(['', 'link', '--machine', 'link3'])
}

fn test_list_cmd() {
	mut cmd := create_cmd()
	cmd.parse(['', 'list'])
	cmd = create_cmd()
	cmd.parse(['', 'list', '--real'])
}

fn test_update_cmd() {
	mut cmd := create_cmd()
	cmd.parse(['', 'update', '--name', 'alt2', 'alt_link'])
	cmd = create_cmd()
	cmd.parse(['', 'update', '--path', 'link1', 'alt2'])
	cmd = create_cmd()
	cmd.parse(['', 'update', '--name', 'alt_link', '--path', 'link2', 'alt2'])
}

fn test_del_cmd() {
	mut cmd := create_cmd()
	cmd.parse(['', 'del', 'link1'])
	cmd = create_cmd()
	cmd.parse(['', 'del', 'alt_link', 'link3'])
}

// TODO: open
