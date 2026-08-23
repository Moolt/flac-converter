#!/bin/bash

MUSIC_DIR="${MUSIC_DIR:-/music}"
TARGET_FORMAT="${TARGET_FORMAT:-opus}"
BITRATE="${BITRATE:-128k}"
SCAN_INTERVAL="${SCAN_INTERVAL:-60}"
DELETE_ORIGINAL="${DELETE_ORIGINAL:-true}"

FORMAT_LOWER=$(echo "$TARGET_FORMAT" | tr '[:upper:]' '[:lower:]')

case "$FORMAT_LOWER" in
  opus)
    CODEC="${CODEC:-libopus}"
    EXTENSION="${EXTENSION:-opus}"
    FFMPEG_EXTRA="${FFMPEG_EXTRA:--vbr on}"
    ;;
  mp3)
    CODEC="${CODEC:-libmp3lame}"
    EXTENSION="${EXTENSION:-mp3}"
    FFMPEG_EXTRA="${FFMPEG_EXTRA:-}"
    ;;
  aac|m4a)
    CODEC="${CODEC:-aac}"
    EXTENSION="${EXTENSION:-m4a}"
    FFMPEG_EXTRA="${FFMPEG_EXTRA:-}"
    ;;
  ogg|vorbis)
    CODEC="${CODEC:-libvorbis}"
    EXTENSION="${EXTENSION:-ogg}"
    FFMPEG_EXTRA="${FFMPEG_EXTRA:-}"
    ;;
  *)
    CODEC="${CODEC:-$FORMAT_LOWER}"
    EXTENSION="${EXTENSION:-$FORMAT_LOWER}"
    FFMPEG_EXTRA="${FFMPEG_EXTRA:-}"
    ;;
esac

echo "=== FLAC Audio Auto-Converter Started ==="
echo "Target Directory: $MUSIC_DIR"
echo "Target Format:    $TARGET_FORMAT (Codec: $CODEC, Ext: .$EXTENSION)"
echo "Target Bitrate:   $BITRATE"
echo "Scan Interval:    ${SCAN_INTERVAL}s"
echo "Delete Original:  $DELETE_ORIGINAL"

while true; do
  # Use null-delimited processing (-print0 / -d '') for space & dot safety
  find "$MUSIC_DIR" -type f -iname "*.flac" -print0 | while IFS= read -r -d '' flac_file; do
    target_file="${flac_file%.*}.${EXTENSION}"

    if [ -f "$target_file" ]; then
      continue
    fi

    echo "[$(date +'%Y-%m-%d %H:%M:%S')] Converting: $flac_file -> $target_file"

    # -nostdin and < /dev/null prevent FFmpeg from stealing stdin from the read loop
    ffmpeg -nostdin -hide_banner -loglevel error -y \
      -i "$flac_file" \
      -c:a "$CODEC" \
      -b:a "$BITRATE" \
      $FFMPEG_EXTRA \
      -map_metadata 0 \
      "$target_file" < /dev/null

    if [ $? -eq 0 ]; then
      echo "[$(date +'%Y-%m-%d %H:%M:%S')] Successfully created: $target_file"
      if [ "$DELETE_ORIGINAL" = "true" ]; then
        rm "$flac_file"
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] Deleted original: $flac_file"
      fi
    else
      echo "[ERROR] Conversion failed for: $flac_file"
      rm -f "$target_file"
    fi
  done

  sleep "$SCAN_INTERVAL"
done