#!/usr/bin/env python3

import bs4
import sys
import string

html = sys.stdin.read()
sys.stderr.write("===========================================\n")
sys.stderr.write(html)
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
        try:
            character = list(span.children)[0]
        except IndexError:
            continue
        if "{" in character or "}" in character:
            # pretend it isn't there -- too hard, and not interesting anyway
            continue
        if character.strip() == '':
            # successfully doing whitespace isn't a great achievement
            continue
        good = True
        for c in character:
            if c not in string.ascii_letters:
                good = False
        if not(good):
            continue
        if '\\' in character:
            character = character.replace('\\', '\\\\')
        if confidence > most_confidence:
            most_confidence = confidence
            most_confident_word = character
if most_confident_word is not None:
    print("{confidence %d word {%s}}" % (most_confidence, most_confident_word))
else:
    print("{}")
