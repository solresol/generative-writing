#!/usr/bin/env python3

import bs4
import sys

html = sys.stdin.read()
soup = bs4.BeautifulSoup(html, 'lxml')
spans = soup.find_all('span')
most_confidence = 0
most_confident_word = None

for span in spans:
    if 'ocrx_word' in span['class']:
        title = span['title'].split()
        confidence = None
        for i in range(len(title)-1):
            if title[i].endswith('conf'):
                confidence = title[i+1]
                break
        if confidence is None:
            continue
        confidence = int(confidence)
        if span.find('strong'):
            span = span.find('strong')
        if span.find('em'):
            span = span.find('em')
        character = list(span.children)[0]
        if "{" in character or "}" in character:
            # pretend it isn't there -- too hard, and not interesting anyway
            continue
        if character.strip() == '':
            # successfully doing whitespace isn't a great achievement
            continue
        if confidence > most_confidence:
            most_confidence = confidence
            most_confident_word = character
if most_confident_word is not None:
    print("{confidence %d word {%s}}" % (most_confidence, most_confident_word))
else:
    print("{}")
