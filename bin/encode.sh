#!/bin/sh
set -e

cleanup() {
	rm -f /tmp/input.* "$OUTPUT_FILE"
}
trap cleanup EXIT

# Check dependencies
command -v s5cmd >/dev/null 2>&1 || { echo >&2 "s5cmd is not installed. Aborting."; exit 1; }
command -v ffmpeg >/dev/null 2>&1 || { echo >&2 "ffmpeg is not installed. Aborting."; exit 1; }
if ! ffmpeg -codecs 2>/dev/null | grep -q libx265; then
    echo >&2 "ffmpeg is missing libx265 support. Aborting."
    exit 1
fi

if [ -z "$S3_BUCKET" ] || [ -z "$S3_KEY" ]; then
	echo "S3_BUCKET and S3_KEY environment variables must be set. Aborting."
	exit 1
fi

CRF="${CRF:-23}"
S3_STORAGE_CLASS="${S3_STORAGE_CLASS:-INTELLIGENT_TIERING}"
INPUT_EXT="${S3_KEY##*.}"
INPUT_FILE="/tmp/input.${INPUT_EXT}"
OUTPUT_FILE="/tmp/output.mp4"

echo "Downloading s3://$S3_BUCKET/$S3_KEY to $INPUT_FILE..."
s5cmd cp "s3://$S3_BUCKET/$S3_KEY" "$INPUT_FILE"

# Determine encoding parameters based on S3_KEY prefix
SCALE=""
case "$S3_KEY" in
	input/preserve/*)		SCALE="-fps_mode vfr" ;;
	input/downscale/*)	SCALE="-vf scale=-1:1440 -fps_mode vfr" ;;
	input/flip/*)				SCALE="-vf hflip -fps_mode vfr" ;;
	input/downflip/*)		SCALE="-vf scale=-1:1440,hflip -fps_mode vfr" ;;
	*) echo "Unknown S3_KEY prefix. Proceeding without scaling filters." ;;
esac

echo "Encoding video with ffmpeg..."
ffmpeg -hide_banner -y -i "$INPUT_FILE" $SCALE \
	-c:v libx265 -x265-params log-level=warning -crf $CRF \
	-c:a copy "$OUTPUT_FILE"

# Upload output file to S3 (under output/ prefix)
FULL_FILENAME=${S3_KEY##*/}
FILENAME_NO_EXT=${FULL_FILENAME%.*}
OUTPUT_KEY="output/${FILENAME_NO_EXT}.mp4"
echo "Uploading encoded video to s3://$S3_BUCKET/$OUTPUT_KEY..."
s5cmd cp  --storage-class $S3_STORAGE_CLASS "$OUTPUT_FILE" "s3://$S3_BUCKET/$OUTPUT_KEY"

echo "Encoding and upload complete."