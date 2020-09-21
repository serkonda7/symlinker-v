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

// TODO: test command parsing
