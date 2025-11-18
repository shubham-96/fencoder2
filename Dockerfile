# Stage 1: s5cmd source
FROM peakcom/s5cmd:v2.3.0 AS s5cmd-source

# Stage 2: ffmpeg source
FROM mwader/static-ffmpeg:8.0 AS ffmpeg-source

# Stage 3: Final image
FROM alpine:latest

RUN apk add --no-cache ca-certificates

COPY --from=s5cmd-source /s5cmd /usr/local/bin/s5cmd
COPY --from=ffmpeg-source /ffmpeg /usr/local/bin/ffmpeg
COPY --from=ffmpeg-source /ffprobe /usr/local/bin/ffprobe

COPY bin/encode.sh /usr/local/bin/encode.sh
RUN chmod +x /usr/local/bin/encode.sh

ENTRYPOINT ["/usr/local/bin/encode.sh"]