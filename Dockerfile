# Stage 1: Build s5cmd from source
FROM golang:1.22-alpine AS s5cmd-builder
RUN apk add --no-cache git make && \
    git clone --depth 1 --branch v2.3.0 https://github.com/peak/s5cmd.git /s5cmd && \
    cd /s5cmd && \
    CGO_ENABLED=0 make build


# Stage 2: Main image
FROM jrottenberg/ffmpeg:8.0-alpine

# Copy s5cmd from build stage
COPY --from=s5cmd-builder /s5cmd/s5cmd /usr/local/bin/s5cmd

# Add the encoding shell script
COPY bin/encode.sh /usr/local/bin/encode.sh
RUN chmod +x /usr/local/bin/encode.sh

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/encode.sh"]
