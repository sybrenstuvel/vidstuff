#!/bin/bash

exec rsync -va ./ /shared/conference/bc16/video_processing/  --exclude '*-vids/' --exclude cards/ --exclude .idea/ "$@"
