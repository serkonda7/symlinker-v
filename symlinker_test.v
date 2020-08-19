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
	assert scope == 'local'

	cmd.flags[0].value = 'true'
	scope = get_scope(cmd)
	assert scope == 'global'
}

fn test_scope_by_dir() {
	dirs := [os.home_dir() + '.local/bin/', '/usr/local/bin/']
	expected := ['local', 'global']
	scopes := dirs.map(get_scope_by_dir(it))
	assert scopes == expected
}

fn test_get_dir() {
	scopes := linux_dirs.keys()
	dirs := scopes.map(get_dir(it))
	expected := [os.home_dir() + '.local/bin/', '/usr/local/bin/',]
	assert dirs == expected
}
