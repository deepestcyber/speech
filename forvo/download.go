package main

import (
	"log"
	"github.com/PuerkitoBio/goquery"
	"strings"
	"regexp"
	"encoding/base64"
	"os"
	"fmt"
	"flag"
)

var flag_word = flag.String("word", "fuck", "Forvo word URL")

func main() {
	flag.Parse()

	url := fmt.Sprintf("https://forvo.com/word/%s/", *flag_word)

	doc, err := goquery.NewDocument(url)

	log.SetOutput(os.Stderr)

	if err != nil {
		log.Fatal(err)
	}

	enArticle := doc.Find("article.pronunciations header em[id=en]").Parent().Parent()
	links := enArticle.Find("ul").Eq(0).Find("li span.play")

	// onclick="Play(1433706,'OTE4OTQ3OS8zOS85MTg5NDc5XzM5XzEzMTBfMTQyNzI0My5tcDM=','OTE4OTQ3OS8zOS85MTg5NDc5XzM5XzEzMTBfMTQyNzI0My5vZ2c=',false,'by9lL29lXzkxODk0NzlfMzlfMTMxMF8xNDI3MjQzLm1wMw==' (TIHS ONE) ,'by9lL29lXzkxODk0NzlfMzlfMTMxMF8xNDI3MjQzLm9nZw==','h');

	playPattern := regexp.MustCompile(`Play\([^,]*,[^,]*,[^,]*,[^,]*,'([^,]*)',[^,]*,'h'\)`)

	links.Each(func(i int, s *goquery.Selection) {
		protoLabel := strings.Split(s.Text(), " ")
		label := strings.Join(protoLabel[:len(protoLabel) - 1], " ")

		onclick, _ := s.Attr("onclick")

		match := playPattern.FindStringSubmatch(onclick)

		if len(match) < 2 {
			log.Println("No match for", onclick)
			return
		}

		suffix := match[1]
		b, err := base64.StdEncoding.DecodeString(suffix)
		if err != nil {
			log.Println(err)
			return
		}
		suffix = string(b)

		fmt.Print(label, ":")
		fmt.Printf("https://audio00.forvo.com/audios/mp3/%s\n", suffix)
	})

}
