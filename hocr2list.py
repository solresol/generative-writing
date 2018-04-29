#!/usr/bin/env python3

import bs4
import sys

soup = bs4.BeautifulSoup(sys.stdin, 'lxml')
print (soup.findall('span'))
