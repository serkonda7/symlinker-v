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
	expected := ['t_local', 't_global']
	scopes := dirs.map(get_scope_by_dir(it))
	assert scopes == expected
}

fn test_get_dir() {
	scopes := linux_dirs.keys()
	dirs := scopes.map(get_dir(it))
	expected := [os.home_dir() + '.local/bin/', '/usr/local/bin/',
		os.home_dir() + '.cache/symlinker_local/', os.home_dir() + '.cache/symlinker_global/',]
	assert dirs == expected
}
