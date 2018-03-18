#!/bin/bash

mkdir download
words=$(cat ../words.txt)
for word in $words; do
	i=1
	./forvo -word "$word" | while read label_url; do
		label=$(echo $label_url | cut -d ":" -f 1)
		url=$(echo $label_url | cut -d ":" -f 2-)
		echo $label , $url
		wget $url -O download/"$label"_${i}.mp3
		i=$(expr $i + 1)
	done
done
