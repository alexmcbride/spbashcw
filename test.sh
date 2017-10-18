#!/bin/bash

test()
{
	for hmm in $@
	do
		echo "$hmm"
	done
}

test "hello" "fart"
