module main

import cli

fn test_get_scope() {
	mut cmd := cli.Command{
		flags: [cli.Flag{
			flag: .bool
			name: 'global'
			value: ''
		}]
	}
	mut scope := ''

	cmd.flags[0].value = 'false'
	scope = get_scope(cmd)
	assert scope == 'test_local'

	cmd.flags[0].value = 'true'
	scope = get_scope(cmd)
	assert scope == 'test_global'
}
