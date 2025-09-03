#!/bin/sh
set -e

# Check dependencies
command -v s5cmd >/dev/null 2>&1 || { echo >&2 "s5cmd is not installed. Aborting."; exit 1; }
command -v ffmpeg >/dev/null 2>&1 || { echo >&2 "ffmpeg is not installed. Aborting."; exit 1; }
ffmpeg -codecs | grep -q libx265 || { echo >&2 "ffmpeg is missing libx265 support. Aborting."; exit 1; }

# Read environment variables
S3_BUCKET="${S3_BUCKET}"
S3_KEY="${S3_KEY}"

if [ -z "$S3_BUCKET" ] || [ -z "$S3_KEY" ]; then
	echo "S3_BUCKET and S3_KEY environment variables must be set. Aborting."
	exit 1
fi

# Local file paths
INPUT_FILE="/tmp/input.mp4"
OUTPUT_FILE="/tmp/output.mp4"

# Download input file from S3
echo "Downloading s3://$S3_BUCKET/$S3_KEY to $INPUT_FILE..."
s5cmd cp "s3://$S3_BUCKET/$S3_KEY" "$INPUT_FILE"

# Determine encoding parameters based on S3_KEY prefix
CRF=23
SCALE=""
if echo "$S3_KEY" | grep -q '^input/preserve/'; then
	# Preserve original resolution
	SCALE="-vsync vfr"
elif echo "$S3_KEY" | grep -q '^input/downscale/'; then
	# Downscale 4K to 1440p
	SCALE="-vf scale=-1:1440 -vsync vfr"
elif echo "$S3_KEY" | grep -q '^input/flip/'; then
	# Flip video horizontally
	SCALE="-vf hflip -vsync vfr"
elif echo "$S3_KEY" | grep -q '^input/downflip/'; then
	# Downscale to 1440p and flip horizontally
	SCALE="-vf scale=-1:1440,hflip -vsync vfr"
fi

# Run ffmpeg encoding
echo "Encoding video with ffmpeg..."
if [ -n "$SCALE" ]; then
	ffmpeg -hide_banner -y -i "$INPUT_FILE" $SCALE -c:v libx265 -x265-params log-level=warning -crf $CRF -c:a copy "$OUTPUT_FILE"
else
	ffmpeg -hide_banner -y -i "$INPUT_FILE" -c:v libx265 -x265-params log-level=warning -crf $CRF -c:a copy "$OUTPUT_FILE"
fi

# Upload output file to S3 (same key, but under output/ prefix)
OUTPUT_KEY="output/${S3_KEY#input/}"
echo "Uploading encoded video to s3://$S3_BUCKET/$OUTPUT_KEY..."
s5cmd cp "$OUTPUT_FILE" "s3://$S3_BUCKET/$OUTPUT_KEY" --storage-class GLACIER_IR

echo "Encoding and upload complete."