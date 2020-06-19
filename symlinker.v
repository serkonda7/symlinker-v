module main

import os

const (
	help_text =
'symlinker

Usage: symlinker [command]

Commands:
  help    Show this message.'
)

fn show_help() {
	println(help_text)
}

fn main() {
	args := os.args[1..]

	if args.len == 0 {
		show_help()
		return
	}

	match args[0] {
		'help' { show_help() }
		else {
			println('${args[0]}: unknown command\nRun "symlinker help" for usage.')
		}
	}
}
