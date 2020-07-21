module main

import cli
import os

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
	assert scope == 't_local'

	cmd.flags[0].value = 'true'
	scope = get_scope(cmd)
	assert scope == 't_global'
}

fn test_scope_by_dir() {
	dirs := [os.home_dir() + '.local/bin/', '/usr/local/bin/']
	expexted := ['t_local', 't_global']
	scopes := dirs.map(get_scope_by_dir(it))
	assert scopes == expexted
}
