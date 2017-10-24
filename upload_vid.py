#!/usr/bin/env python3

# Run 'youtube_uploader' on CLI first.

import argparse
import webbrowser
import glob

import youtube_upload.main
import gen_cards

parser = argparse.ArgumentParser()
parser.add_argument('talk_id')
args = parser.parse_args()

# Figure out which video to upload
the_glob = 'upload-ready-vids/%s-*.mkv' % args.talk_id
candidate_files = glob.glob(the_glob)
if len(candidate_files) > 1:
    raise SystemExit('Multiple matches:\n' + '\n'.join(candidate_files))
if not candidate_files:
    raise SystemExit('No files match %s' % the_glob)
video_fname = candidate_files[0]

# Load the prezzo JSON
presentations = gen_cards.load_json()
pres = presentations[args.talk_id]


# Mocking CLI options, see youtube_upload.main.main()
class Options:
    title = pres['title']
    description = '''"%(title)s" by %(speakers)s
Blender Conference 2017
%(day)s %(time)s at the %(location)s.
'''
    privacy = 'unlisted'  # TODO: change to 'public'
    playlist = 'Blender Conference 2017'
    publish_at = None
    location = None
    recording_date = None
    default_language = None
    default_audio_language = None
    client_secrets = None
    credentials_file = None
    auth_browser = False
    tags = None
    title_template = None
    category = None

options = Options()
options.description %= pres

youtube = youtube_upload.main.get_youtube_handler(options)

video_id = youtube_upload.main.upload_youtube_video(youtube, options, video_fname, 1, 0)
video_url = youtube_upload.main.WATCH_VIDEO_URL.format(id=video_id)
webbrowser.open_new_tab(video_url)
