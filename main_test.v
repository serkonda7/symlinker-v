module main

fn test_new_app() {
	app := new_app()
	assert app.commands.len == 5
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
