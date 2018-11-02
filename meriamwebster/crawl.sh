#!/bin/bash

. ../common.sh

mkdir download
words=$(read_good_words; read_bad_words)
for word in $words; do
	first_letter=$(echo $word | sed -e 's/\(.\).*/\1/')
	for i in {01..10}; do
		path="download/${word}_${i}.wav"
		if [ -e "$path" ]; then
			echo "file $path already exists, skipping"
			continue
		fi
		wget -q http://media.merriam-webster.com/audio/prons/en/us/wav/${first_letter}/${word}00${i}.wav \
			-O "$path"
		if ! [ $? -eq 0 ]; then
			rm "$path"
			break
		fi
		echo "download $path: OK"
	done
done
