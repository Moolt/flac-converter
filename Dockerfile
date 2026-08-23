# Automatically uses your host CPU architecture during build
ARG TARGETPLATFORM
FROM --platform=$TARGETPLATFORM alpine:3.19

RUN apk add --no-cache ffmpeg bash findutils dos2unix

WORKDIR /app
COPY convert.sh /app/convert.sh
RUN dos2unix /app/convert.sh && chmod +x /app/convert.sh

ENTRYPOINT ["/bin/sh", "/app/convert.sh"]