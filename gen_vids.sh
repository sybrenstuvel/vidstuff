#!/usr/bin/env bash
# Converts PNG cards to fading videos.
# Assumes NONE of the filenames have spaces in them.

set -e

PNG_PATH='cards/png'
VID_IN_PATH='source-vids'
VID_TMP_PATH='tmp-vids'
VID_OUT_PATH='upload-ready-vids'

TITLE_SHOW_DURATION_SECS=2
FADE_DURATION_SECS=1

FILTER_COMPLEX="
    [0:v]format=pix_fmts=yuva422p10le,fade=t=out:st=${TITLE_SHOW_DURATION_SECS}:d=${FADE_DURATION_SECS}:alpha=1,setpts=PTS-STARTPTS[va0];
    [1:v]format=pix_fmts=yuva422p10le,fade=t=in:st=0:d=${FADE_DURATION_SECS}:alpha=1,setpts=PTS-STARTPTS+${TITLE_SHOW_DURATION_SECS}/TB[va1];
    [va0][va1]overlay[outv]
"


mkdir -p ${VID_IN_PATH} ${VID_TMP_PATH} ${VID_OUT_PATH}

for png_fname in ${PNG_PATH}/*.png; do
    BASENAME=$(basename ${png_fname/.png})
    VID_IN_FNAME=${VID_IN_PATH}/my-source.mxf
    VID_TITLECARD=${VID_TMP_PATH}/${BASENAME}-title.mxf
    VID_OUT_COMBINED=${VID_OUT_PATH}/${BASENAME}-combined.mxf

    # if [ -e ${VID_OUT_COMBINED} ]; then
    #     echo "Destination video ${VID_OUT_COMBINED} already exists, skipping"
    #     continue
    # fi

    if [ ! -e ${VID_IN_FNAME} ]; then
        echo "Source video ${VID_IN_FNAME} does not exist, skipping"
        continue
    fi

    # Show titlecard and fade into source video.
    ffmpeg -hwaccel auto \
        -loop 1 \
        -i ${png_fname} \
        -i ${VID_IN_FNAME} \
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
inpoint ${FADE_DURATION_SECS}
EOT
    ffmpeg -f concat -i _concat-$$.txt -map 0 -c copy -y ${VID_OUT_COMBINED}

    rm -f concat-$$.txt

    break
done

echo 'DØNER'
