#!/bin/sh

LC_MESSAGES=C sh test.sh | sed -e "s,/.*/tenv,./tenv," > test.out

ERR=`diff -Nur test.exp test.out`

if [ -n "$ERR" ] ; then
	echo "$ERR" > test.err
	echo "Tests failed - see test.err"
else
	rm -f test.err
	echo "Tests passed"
fi


