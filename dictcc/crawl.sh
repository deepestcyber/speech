#!/bin/bash

. ../common.sh

# OK so for dictcc we need to reverse engineer the JS a bit.
#
# 1. In the HTML source code for en-de.dict.cc/?s=gentleman we get
#
#    var idArr = new Array(0,59994,68527,31219,820997,663354,1171905,663353,858319,1174346,890270,200619,200971,809875,992156,1349687,157010, ...);
#    var c1Arr = new Array("","gentleman","gentleman","gentleman","gentleman","gentleman","gentleman","gentleman","country gentleman","country gentleman","country-gentleman", ...);
#
# 2. These ids can be used to request the recordings from the recordings
#    server (originally done by AJAX), JS code:
#
#    req.open('POST', '/dict/ajax_get_audiorecordings.php?id_str='+idArr.join(" "), true);
#
# 3. From this we will get a response similar to this:
#
# 	0 2206_katiebeb_gb_lid1_v|75942_StrawberryCupcake_gbatr_lid2_v|127140_Halmafelix_de_lid2_v|251841_Mannlicher_atr_lid2_v|277834_Immanuel_der_lid2_v|289322_Connum_der_lid2_v|39650_patu_de_lid2_v|538656_Artists_usr_lid1_v|845396_patu_de_lid2_v 2206_katiebeb_gb_lid1_v|56837_patu_de_lid2_v|468158_BHM_de_lid2_v|538656_Artists_usr_lid1_v
#
# 4. The response is delimited by | and we need to filter those fields with
#    _lid1_ as this corresponds to the english utterances
#
# 5. Finally we can take the leading numbers (the utterance id) and insert
#    it into the following URL to download the audio
#
#    https://audio.dict.cc/speak.audio.php?type=mp3&id=<id>&lang=rec&lp=DEEN

agent="User-Agent: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:63.0) Gecko/20100101 Firefox/63.0"
dictcc="https://en-de.dict.cc"

words=$(read_good_words; read_bad_words)

mkdir download
for word in $words; do
	url="${dictcc}/?s=${word}"

	wget -q --user-agent "$agent" "$url" -O tmp_index.html

	# get values out of idArr = Array(0,1,...) call in HTML;
	# store them as array.
	ids=$(grep idArr tmp_index.html | cut -d "(" -f 2- | cut -d ")" -f 1)
	ids=($(echo $ids | sed -e 's/,/ /g'))

	# now we need to know which indices in the array actually correspond
	# exactly to our word (e.g., "gentleman") instead of being part of a
	# larger utterance (e.g., "the gentleman sits").
	#
	# for this we fetch the c1Arr (which is aligned with idArr) but
	# contains the individual words instead of ids. From there we can find
	# the indices of our word (line counts of grep) and use those to filter
	# the relevant ids.
	indices=$(grep c1Arr tmp_index.html \
		| egrep -o '\(.*\)' \
		| sed -e 's/",/"\n/g' \
		| grep -n "\"$word\"" \
		| cut -d ":" -f 1)

	# last step: take only those ids from idArray where the c1Arr index
	# matches our word.
	ids=$(for idx in $indices; do
		idx=$(($idx - 1))
		echo ${ids[$idx]}
	done)

	# replace " " with url encoded whitespace
	ids=$(echo $ids | sed -e 's/ /%20/g')

	wget -q --user-agent "$agent" -O tmp_recordings.txt \
		"${dictcc}/dict/ajax_get_audiorecordings.php?id_str=${ids}"

	# 1. separate each file by lines, not by | or whitespace
	# 2. just filter the english samples
	# 2. remove duplicates
	# 3. retrieve the id
	# 4. download audio sample for each id
	i=0
	cat tmp_recordings.txt \
	 | sed -e 's/|/\n/g' -e 's/ /\n/g' \
	 | egrep '_lid1_v$' \
	 | sort -u \
	 | cut -d "_" -f 1 \
	 | while read id; do
		path="download/${word}_${i}.mp3"
		url="https://audio.dict.cc/speak.audio.php?type=mp3&id=${id}&lang=rec&lp=DEEN"
		wget -q --user-agent "$agent" -O "$path" "$url"
		if [ $? -eq 0 ]; then
			echo "download $path ($id): OK"
		else
			echo "download $path ($id): failed"
		fi
		i=$(($i + 1))
	done
done
