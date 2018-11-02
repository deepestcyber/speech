#!/bin/bash

. ../common.sh

mkdir download
words=$(read_good_words; read_bad_words)
for word in $words; do
	i=1
	./forvo -word "$word" | while read label_url; do
		label=$(echo $label_url | cut -d ":" -f 1)
		url=$(echo $label_url | cut -d ":" -f 2-)
		echo $label , $url
		path="download/${label}_${i}.mp3"
		if [ -e "$path" ]; then
			echo "$path already exists, skipping."
			continue
		fi
		wget $url -O $path
		i=$(expr $i + 1)
	done
done
