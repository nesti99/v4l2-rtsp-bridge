#!/bin/bash

MEDIAMTX_BIN="/mediamtx/mediamtx"
MEDIAMTX_CONF="/mediamtx/mediamtx.yml"

VIDEO_DEVICES=(0 1 2 3)
AUDIO_DEVICES=("hw:1,0" "hw:2,0" "hw:3,0" "hw:4,0")

FRAMERATE=60
VIDEO_SIZE="1920x1080"

VAAPI_DEVICE="/dev/dri/renderD128"

declare -A PIDS

################################
# MediaMTX
################################

start_mediamtx() {
    echo "▶ Avvio MediaMTX"
    $MEDIAMTX_BIN $MEDIAMTX_CONF >> /var/log/mediamtx.log 2>&1 &
    sleep 3
}

is_mediamtx_alive() {
    ss -ltn | grep -q ":8554"
}

stop_all_ffmpeg() {
    echo "⛔ Stop di tutti gli FFmpeg"
    killall -q ffmpeg
    sleep 2
}

################################
# FFmpeg per canale (Intel VAAPI)
################################

start_ffmpeg() {
    local V=$1
    local A=$2
    local VIDEO_DEV="/dev/video$V"
    local RTSP_PATH="ch$V"

    echo "▶ Avvio FFmpeg ch$V (Intel VAAPI)"

    ffmpeg \
        -fflags +genpts \
        -hide_banner -loglevel warning \
        -init_hw_device vaapi=intel:${VAAPI_DEVICE} \
        -filter_hw_device intel \
        -f v4l2 -thread_queue_size 512 \
        -framerate $FRAMERATE \
        -video_size $VIDEO_SIZE \
        -input_format yuyv422 \
        -i $VIDEO_DEV \
        -f alsa -thread_queue_size 256 \
        -use_wallclock_as_timestamps 1 \
        -i $A \
        -map 0:v:0 -map 1:a:0 \
        -vf "format=nv12,hwupload" \
        -c:v h264_vaapi \
        -profile:v high \
        -level 4.2 \
        -qp 20 \
        -maxrate 18M -bufsize 36M \
        -g 60 \
        -bf 0 \
        -low_power 1 \
        -af "aresample=async=1:first_pts=0" \
        -c:a aac -b:a 192k -ar 44100 \
        -shortest \
        -f rtsp -rtsp_transport tcp \
        rtsp://127.0.0.1:8554/$RTSP_PATH \
        >> /var/log/ffmpeg_ch${V}.log 2>&1 &

    PIDS[$V]=$!
}

################################
# Bootstrap iniziale
################################

pkill -9 mediamtx 2>/dev/null
pkill -9 ffmpeg 2>/dev/null

start_mediamtx

for i in "${!VIDEO_DEVICES[@]}"; do
    start_ffmpeg "${VIDEO_DEVICES[$i]}" "${AUDIO_DEVICES[$i]}"
done

################################
# WATCHDOG PRINCIPALE
################################

while true; do

    # 🔴 MediaMTX morto → restart globale
    if ! is_mediamtx_alive; then
        echo "🚨 MediaMTX non risponde!"

        stop_all_ffmpeg
        pkill -9 mediamtx 2>/dev/null

        start_mediamtx

        for i in "${!VIDEO_DEVICES[@]}"; do
            start_ffmpeg "${VIDEO_DEVICES[$i]}" "${AUDIO_DEVICES[$i]}"
        done
    fi

    # 🟡 FFmpeg singoli
    for V in "${VIDEO_DEVICES[@]}"; do
        PID=${PIDS[$V]}
        if ! kill -0 "$PID" 2>/dev/null; then
            echo "⚠️ FFmpeg ch$V morto → restart"
            start_ffmpeg "$V" "${AUDIO_DEVICES[$V]}"
        fi
    done

    sleep 5
done
