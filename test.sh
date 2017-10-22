#! /bin/bash

pids=($(ps -ef | awk '/[w]atch.sh/{print $2}'))
for id in $pids
do
	echo $id
done