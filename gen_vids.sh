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

VID_IN_FNAME="$1"
TALK_ID=$(($2 + 0))
TRIM_START=$(($3 + 0))
TRIM_END=$(($4 + 0))

PNG_FNAME=$(ls ${PNG_PATH}/${TALK_ID}-*.png)
if [ ! -e "${PNG_FNAME}" ]; then
    echo "No such talk card: ${PNG_FNAME}" >&2
    exit 2
fi

BASENAME=$(basename ${PNG_FNAME/.png})
VID_TITLECARD=${VID_TMP_PATH}/${BASENAME}-title.mxf
VID_OUT_COMBINED=${VID_OUT_PATH}/${BASENAME}-combined.mxf

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
    [0:v]format=pix_fmts=yuva422p10le,fade=t=out:st=${TITLE_SHOW_DURATION_SECS}:d=${FADE_DURATION_SECS}:alpha=1,setpts=PTS-STARTPTS[va0];
    [1:v]format=pix_fmts=yuva422p10le,fade=t=in:st=0:d=${FADE_DURATION_SECS}:alpha=1,setpts=PTS-STARTPTS+${TITLE_SHOW_DURATION_SECS}/TB[va1];
    [va0][va1]overlay[outv]
"

# Show titlecard and fade into source video.
ffmpeg -hwaccel auto \
    -loop 1 \
    -i ${PNG_FNAME} \
    -ss ${TRIM_START} -i ${VID_IN_FNAME} \
    -filter_complex "${FILTER_COMPLEX}" \
    -map '[outv]' \
    -t $((TITLE_SHOW_DURATION_SECS + FADE_DURATION_SECS)) \
    -r 25 \
    -pix_fmt yuv422p10le \
    -c:v dnxhd \
    -b:v 185M \
    -flags +ilme+ildct \
    -f mxf \
    -y ${VID_TITLECARD}

# Combine without re-encoding.
cat > _concat-$$.txt <<EOT
file '${VID_TITLECARD}'

file '${VID_IN_FNAME}'
inpoint $((${FADE_DURATION_SECS} + ${TRIM_START}))
EOT
ffmpeg -f concat -i _concat-$$.txt -map 0 -c copy -y ${VID_OUT_COMBINED}

rm -f concat-$$.txt

echo
echo 'DØNER'
