#!/usr/bin/env python3

# Run 'youtube_uploader' on CLI first.

import argparse
import glob

import youtube_upload.main
import gen_cards

parser = argparse.ArgumentParser()
parser.add_argument('talk_id')
args = parser.parse_args()

def find_one(the_glob: str) -> str:
    candidate_files = glob.glob(the_glob)
    if len(candidate_files) > 1:
        raise SystemExit('Multiple matches:\n' + '\n'.join(candidate_files))
    if not candidate_files:
        raise SystemExit('No files match %s' % the_glob)
    return candidate_files[0]

# Figure out which video to upload and with what thumbnail.
video_fname = find_one('upload-ready-vids/%s-*.mkv' % args.talk_id)
png_fname = find_one('cards/png/%s-*.png' % args.talk_id)

# Load the prezzo JSON
presentations = gen_cards.load_json()
pres = presentations[args.talk_id]

description = '''"%(title)s" by %(speakers)s
Blender Conference 2017
%(day)s %(time)s at the %(location)s.
''' % pres

# Mocking CLI options, see youtube_upload.main.main()
argv = [
    '--title', pres['title'],
    '--description', description,
    '--privacy', 'unlisted',
    '--playlist', 'Blender Conference 2017',
    '--client-secrets', 'youtube-upload/client_secrets.json',
    '--thumbnail', png_fname,
    '--open-link',
    video_fname,
]
youtube_upload.main.main(argv)

print('DØNER')
