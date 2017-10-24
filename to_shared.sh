#!/bin/bash

exec rsync -va ./ /shared/conference/bc17/video_processing/  --exclude '*-vids/' --exclude cards/ --exclude .idea/ "$@"
