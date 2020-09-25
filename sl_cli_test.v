module main

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

// TODO: test command parsing
