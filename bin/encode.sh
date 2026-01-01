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
CODEC="libx265"
CODEC_FLAGS="-x265-params log-level=warning -crf $CRF"

if echo "$S3_KEY" | grep -q '^input/av1test'; then
	CODEC="libsvtav1"
	CODEC_FLAGS="-preset 6 -crf 30 -svtav1-params tune=0:scd=1:enable-overlays=1 -pix_fmt yuv420p10le -vf fps=fps=source_fps -fps_mode cfr"
else 
	case "$S3_KEY" in
		input/preserve/*)		SCALE="-vf fps=fps=source_fps -fps_mode cfr" ;;
		input/downscale/*)	SCALE='-vf scale=-1:1440,fps=fps=source_fps -fps_mode cfr' ;;
		input/flip/*)				SCALE='-vf hflip,fps=fps=source_fps -fps_mode cfr' ;;
		input/downflip/*)		SCALE='-vf scale=-1:1440,hflip,fps=fps=source_fps -fps_mode cfr' ;;
		*) echo "Unknown S3_KEY prefix. Proceeding without scaling filters." ;;
	esac
fi

TRIM_FLAGS=""
if [ -n "$START_TIME" ]; then
	TRIM_FLAGS="$TRIM_FLAGS -ss $START_TIME"
fi
if [ -n "$END_TIME" ]; then
	TRIM_FLAGS="$TRIM_FLAGS -to $END_TIME"
fi

echo "Encoding video with ffmpeg..."
ffmpeg -hide_banner -nostdin -y -i "$INPUT_FILE" $TRIM_FLAGS $SCALE \
	-c:v $CODEC $CODEC_FLAGS \
	-c:a copy "$OUTPUT_FILE"

# Upload output file to S3 (under output/ prefix)
FULL_FILENAME=${S3_KEY##*/}
FILENAME_NO_EXT=${FULL_FILENAME%.*}
OUTPUT_KEY="output/${FILENAME_NO_EXT}.mp4"
echo "Uploading encoded video to s3://$S3_BUCKET/$OUTPUT_KEY..."
s5cmd cp  --storage-class $S3_STORAGE_CLASS "$OUTPUT_FILE" "s3://$S3_BUCKET/$OUTPUT_KEY"

echo "Encoding and upload complete."
