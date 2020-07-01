module main

import cli
import os

const (
	local_link_dir = os.home_dir() + '.local/bin/'
	global_link_dir = '/usr/local/bin/'
)

fn list_links(cmd cli.Command) {
	files := os.ls(global_link_dir) or { panic(err) }
	links := files.filter(os.is_link(global_link_dir + it))

	if links.len == 0 {
		println('No symlinks detected.')
		return
	}

	f_real := cmd.flags.get_bool('real') or { panic(err) }
	if f_real {
		for link in links {
			real_path := os.real_path(global_link_dir + link)
			println('$link: $real_path')

		}
	}
	else {
		println(links)
	}
}

fn main() {
	mut cmd := cli.Command{
		name: 'symlinker',
		version: '0.5.0',
		disable_flags: true
	}

	mut list_cmd := cli.Command{
		name: 'list',
		description: 'List all symlinks.',
		execute: list_links
	}
	list_cmd.add_flag(cli.Flag{
		flag: .bool,
		name: 'real',
		abbrev: 'r',
		description: 'Also print the path the links point to.'
	})

	cmd.add_command(list_cmd)
	cmd.parse(os.args)
}
