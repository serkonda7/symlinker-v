module main

import os

fn main() {
	args := os.args[1..]

	if args.len == 0 {
		return
	}

	match args[0] {
		else {
			println('${args[0]}: unknown command')
		}
	}
}
