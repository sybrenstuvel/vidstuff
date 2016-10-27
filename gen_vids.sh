#!/usr/bin/env bash
# Converts PNG cards to fading videos.
# Assumes NONE of the filenames have spaces in them.

if [ -z "$3" ]; then
    echo "Usage: $0 <source.mxf> <talk ID> <seconds trim from start> <seconds trim from end>" >&2
    exit 1
fi

set -e

PNG_PATH='cards/png'
VID_TMP_PATH='tmp-vids'
VID_OUT_PATH='upload-ready-vids'
mkdir -p ${VID_TMP_PATH} ${VID_OUT_PATH}

TITLE_SHOW_DURATION_SECS=2
FADE_DURATION_SECS=1

AUDIO_FADE_DURATION_SECS=1
TITLE_SHOW_DURATION_MSECS=$((TITLE_SHOW_DURATION_SECS * 1000))

VID_IN_FNAME="$1"
TALK_ID="$2"
TRIM_START="$3"
TRIM_END="$4"

PNG_FNAME=$(ls ${PNG_PATH}/${TALK_ID}-*.png)
if [ ! -e "${PNG_FNAME}" ]; then
    echo "No such talk card: ${PNG_FNAME}" >&2
    exit 2
fi

BASENAME=$(basename ${PNG_FNAME/.png})
VID_TITLECARD=${VID_TMP_PATH}/${BASENAME}-title.mxf
VID_OUT_COMBINED=${VID_OUT_PATH}/${BASENAME}-combined.mkv

if [ ! -e ${VID_IN_FNAME} ]; then
    echo "Source video ${VID_IN_FNAME} does not exist, aborting." >&2
    exit 3
fi

if [ -e ${VID_OUT_COMBINED} ]; then
    echo "Destination video ${VID_OUT_COMBINED} already exists."
    echo "Press [ENTER] to overwrite, [CTRL]+[C] to abort."
    read dummy
fi

FILTER_COMPLEX="
    [0:v]format=pix_fmts=yuva422p10le,fade=t=out:st=${TITLE_SHOW_DURATION_SECS}:d=${FADE_DURATION_SECS}:alpha=1,setpts=PTS-STARTPTS[vid_title];
    [1:v]format=pix_fmts=yuva422p10le,fade=t=in:st=0:d=${FADE_DURATION_SECS}:alpha=1,setpts=PTS-STARTPTS+${TITLE_SHOW_DURATION_SECS}/TB[vid_main];
    [vid_title][vid_main] overlay [vid];
    [2:a] afade=t=out:st=${TITLE_SHOW_DURATION_SECS}:d=${AUDIO_FADE_DURATION_SECS} [aud_title];
    [3:a][4:a] amerge [aud_main_in];
    [aud_main_in] afade=t=in:st=0:d=${FADE_DURATION_SECS} [aud_main_faded];
    [aud_main_faded] adelay=${TITLE_SHOW_DURATION_MSECS}|${TITLE_SHOW_DURATION_MSECS} [aud_main];
    [aud_title][aud_main] amix=duration=longest [audio]
"

ffmpeg \
    -v info \
    -hwaccel auto \
    -loop 1 \
    -i ${PNG_FNAME} \
    -ss ${TRIM_START} \
    -i ${VID_IN_FNAME} \
    -i source-vids/silence.wav \
    -i source-vids/links234-L.wav \
    -i source-vids/witcher-R.wav \
    -filter_complex "${FILTER_COMPLEX}" \
    -map '[vid]' \
    -map '[audio]' \
    -pix_fmt yuv422p \
    -c:v h264 \
    -c:a mp3 \
    -crf 23 \
    -y ${VID_OUT_COMBINED}

echo
echo 'DØNER'
