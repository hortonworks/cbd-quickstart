#/bin/bash

dd_tempfile=tempfile
dd_awk=awk

function dd_help() {
	echo help text
}

if [ ! -f $1 ] || [ -z $1 ]  ; then
	echo first param should be the test file
	dd_help
	exit 1
fi

if [ ! -f $2 ] || [ -z $2 ] ; then
	echo second param should be the data file
	dd_help
	exit 1
fi

function dd_runall() {
	counter=2
	while [ $counter -le $dd_col_no ] ; do
		let dd_string=$counter
		dd_runint
		let counter=counter+1
	done
}

function dd_runstring() {
	$dd_awk ' NR==1 { for (i=2; i<=NF; i++) { if ($i=="'$dd_string'") { break } } if (i>NF) exit 1 } { print $1 "=" $i } ' $dd_file > $dd_tempfile
	ls -al $dd_tempfile
	cat $dd_tempfile
	dd_run
}

function dd_runint() {
	$dd_awk ' { print $1 "=" $'$dd_string' } ' $dd_file > $dd_tempfile
	dd_run
}

function dd_run() {
	source $dd_tempfile
	source $dd_test
}

dd_file=$2
dd_test=$1
dd_string=$4
dd_col_no=$( $dd_awk '{ print NF ; exit 0 }' $dd_file )
case "$3" in
	"") 
		dd_runall
		;;
	"-s")
		dd_runstring
		;;
	"-i")
		if [[ ! $dd_string =~ ^-?[0-9]+$ ]] ; then
			echo in this case a fourth parameter should be a valid positive integer
			exit 1
		fi
		if [ $dd_string -gt $dd_col_no ] ; then
			echo it is more than the colum number in the data file
			exit 1
		fi
		dd_runint
		;;
	*)
		echo "third parameter could be [ -s stringvalue | -i col_no ] "
		dd_help
		exit 1
		;;
esac

[[ -f $dd_tempfile ]]  && rm $dd_tempfile
