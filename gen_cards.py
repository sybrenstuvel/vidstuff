#!/usr/bin/env python3

import json
import multiprocessing
import os
import subprocess
from xml.sax.saxutils import escape

import slugify


def main():
    os.makedirs('cards/svg', exist_ok=True)
    os.makedirs('cards/png', exist_ok=True)

    presentations = load_json()
    with open('slide_template.svg', 'r', encoding='utf8') as infile:
        card_template = infile.read()

    with multiprocessing.Pool(processes=multiprocessing.cpu_count()) as pool:
        for talk_id, talk_info in presentations.items():
            print('Queueing talk %r' % talk_id)
            pool.apply_async(create_card, (card_template, talk_id, talk_info))
        pool.close()
        pool.join()

    # for talk_id, talk_info in presentations.items():
    #     print('Queueing talk %s' % talk_id)
    #     create_card(card_template, talk_id, talk_info)

    print('DØNER')


def create_card(card_template, talk_id, talk_info):
    fname = '%s-%s' % (talk_id, slugify.slugify(talk_info['title']))
    svg_fname = 'cards/svg/%s.svg' % fname
    png_fname = 'cards/png/%s.png' % fname

    for key, value in talk_info.items():
        talk_info[key] = escape(value)
    talk_info['title'] = talk_info['title'].rstrip('.')

    # Create card SVG if it doesn't exist yet.
    if not os.path.exists(svg_fname):
        with open(svg_fname, 'w', encoding='utf8') as outfile:
            outfile.write(card_template.format(**talk_info))

    # Convert to PNG if SVG is newer than PNG.
    if not os.path.exists(png_fname) or os.stat(svg_fname).st_mtime > os.stat(png_fname).st_mtime:
        subprocess.check_call(['inkscape', svg_fname,
                               '--export-background-opacity=1.0',
                               '--export-png=%s' % png_fname,
                               '--export-width=1920',
                               '--export-height=1080'])


def load_json():
    json_fname = 'presentations.json'
    if not os.path.exists(json_fname):
        subprocess.check_call([
            'curl',
            'https://www.blender.org/conference/2017/presentations?format=json',
            '-opresentations.json',
        ])
    with open(json_fname, 'r', encoding='utf-8') as infile:
        presentations = json.load(infile)
        presentations = presentations['presentations']
    return presentations


if __name__ == '__main__':
    main()
