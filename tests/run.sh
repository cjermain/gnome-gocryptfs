#!/bin/bash

LC_MESSAGES=C bash test.sh | sed -e "s,/.*/tenv,./tenv," > test.out

ERR=`diff -u test.exp test.out`

if [ -n "$ERR" ] ; then
	echo "$ERR" > test.err
	echo "Tests failed - see test.err"
    exit 1
else
	rm -f test.err
	echo "Tests passed"
    exit 0
fi
