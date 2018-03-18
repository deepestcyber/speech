#!/bin/bash

mkdir download
words=$(cat ../words.txt)
for word in $words; do
	first_letter=$(echo $word | sed -e 's/\(.\).*/\1/')
	for i in {01..10}; do
		wget http://media.merriam-webster.com/audio/prons/en/us/wav/${first_letter}/${word}00${i}.wav \
			-O download/${word}00${i}.wav
		if ! [ $? -eq 0 ]; then
			rm download/${word}00${i}.wav
			break
		fi
	done
done
