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
mkdir -p ${VID_OUT_PATH} ${VID_TMP_PATH}

TITLE_SHOW_DURATION_SECS=2

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
VID_OUT_COMBINED=${VID_OUT_PATH}/${BASENAME}-combined.mkv
VID_TMP_CARD=${VID_TMP_PATH}/${BASENAME}-card.mkv
VID_TMP_TALK=${VID_TMP_PATH}/${BASENAME}-talk.mkv

if [ ! -e ${VID_IN_FNAME} ]; then
    echo "Source video ${VID_IN_FNAME} does not exist, aborting." >&2
    exit 3
fi

if [ -e ${VID_OUT_COMBINED} ]; then
    echo "Destination video ${VID_OUT_COMBINED} already exists."
    echo "Press [ENTER] to overwrite, [CTRL]+[C] to abort."
    read dummy
fi

FFMPEG="ffmpeg -v warning -hwaccel auto"

FILTER_COMPLEX="
    [0:v] yadif [vid];
    [1:a] channelmap=map=0-0|1-1 [aud_stereo];
    [aud_stereo] dynaudnorm=p=0.9:r=1.0:b=1 [audio]
"

# Durations of the talk itself, after trimming the start & end.
DURATION=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 ${VID_IN_FNAME})
FINAL_DURATION=$(echo $DURATION - $TRIM_END - $TRIM_START | bc)

VID_ENCODING_OPTS="
    -c:v h264
    -pix_fmt yuv422p
    -crf 23
    -g 15
    -preset:v veryfast
    -c:a aac
    -b:a 192k
    -map_metadata -1
    -aspect 16:9
"

# Input file is loaded twice, so that we can apply itsoffset to the audio only.
echo " [*] Encoding TALK"
$FFMPEG \
    -ss ${TRIM_START} \
    -i ${VID_IN_FNAME} \
    -ss ${TRIM_START} \
    -itsoffset 0.2 \
    -i ${VID_IN_FNAME} \
    -filter_complex "${FILTER_COMPLEX}" \
    -map '[vid]' \
    -map '[audio]' \
    ${VID_ENCODING_OPTS} \
    -t ${FINAL_DURATION} \
    -y ${VID_TMP_TALK}

echo
echo " [*] Encoding CARD"
$FFMPEG \
    -loop 1 \
    -i ${PNG_FNAME} \
    -i silence-24.wav \
    ${VID_ENCODING_OPTS} \
    -t ${TITLE_SHOW_DURATION_SECS} \
    -y ${VID_TMP_CARD}

echo
echo " [*] Merging CARD + TALK → ${VID_OUT_COMBINED}"
mkvmerge --quiet -o ${VID_OUT_COMBINED} ${VID_TMP_CARD} + ${VID_TMP_TALK}

echo ' [*] DØNER'
