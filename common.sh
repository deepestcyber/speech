
# routines that are common among the individual
# crawling scripts, such as reading the good
# and bad words from the respective files.

_basepath=$(dirname ${BASH_SOURCE})

read_words() {
	local path="$1"
	cat $path | while read line; do
		if echo $line | egrep -q '^(#|[ ]*$)'; then
			continue
		fi
		echo $line
	done
}

read_good_words() {
	read_words "$_basepath/good_words.txt"
}

read_bad_words() {
	read_words "$_basepath/bad_words.txt"
}
