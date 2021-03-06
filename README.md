# Blender Conference Video Processing Stuff


## Preparing a video for upload to YouTube

1. Get the talk ID from the spreadsheet you got from Francesco, the [conference
   site](https://www.blender.org/conference/2017/presentations), or or look it up in
   `presentations.json`. In the next steps, we assume this is **813**.
2. Get the filename containing the talk video, say `/media/disk1/Capture00412.mov`.
3. Watch the talk video, and write down how many seconds to trim from the start and the end.
   In the next steps, we assume these are respectively **32** and **47** seconds.
4. Run `./gen_vids.sh 813 /media/disk1/Capture00412.mov 32 47`


## Uploading a video to YouTube

1. Prepare the video for upload (see above)
2. Run `./upload_vid.py 813`


## One time only Stuff

### Setup

1. Run `git submodule init` and `git submodule update` if you haven't done this yet. Doing it twice
   is fine too.
2. Create a Python 3 virtualenv and `pip install -U -r requirements.txt`.
3. Install ffmpeg, mkvtoolnix, curl, and inkscape.


### Updating from last year to this year

1. Set the right year everywhere, replacing notation like '2017' and 'bc17'
2. Update `slide_template.svg` to the style of the year.
3. Install the fonts from the 'fonts' directory.
4. Remove `presentations.json` and the `cards` directory to clean up from last year.
5. Run `./gen_cards.py`, which downloads [the schedule as
   JSON](https://www.blender.org/conference/2017/presentations?format=json) from the conference
   website and generates the individual cards in `cards/png` and `cards/svg`.
