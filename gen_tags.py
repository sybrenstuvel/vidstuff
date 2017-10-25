#!/usr/bin/env python3

import json
import sys
import xml.etree.cElementTree as ET

import gen_cards
presentations = gen_cards.load_json()

talk_id = sys.argv[1]
talk = presentations[talk_id]

root = ET.Element("Tags")
tag = ET.SubElement(root, "Tag")

def add_tag(key: str, value: str):
    simple = ET.SubElement(tag, "Simple")
    ET.SubElement(simple, "Name").text = key.upper()
    ET.SubElement(simple, "String").text = value

for key, value in talk.items():
    add_tag(key, value)
add_tag('year', '2017')
add_tag('event', 'Blender Conference')

tree = ET.ElementTree(root)
tree.write(sys.stdout.buffer, encoding='utf-8', xml_declaration=True)
