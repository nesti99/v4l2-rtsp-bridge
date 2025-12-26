#!/usr/bin/env bash

set -e

echo "======================================"
echo " RTSP Streaming Server Installer"
echo "======================================"
echo

# --------------------------------------
# 1. System update & dependencies
# --------------------------------------
echo "➡️  Aggiornamento sistema e installazione dipendenze..."

apt update && apt upgrade -y

apt install -y \
  ffmpeg \
  python3 \
  python3-pip \
  v4l-utils \
  intel-media-va-driver \
  linux-headers-$(uname -r) \
  sudo \
  alsa-utils \
  wget

# --------------------------------------
# 2. Magewell ProCapture Drivers
# --------------------------------------
echo
echo "➡️  Installazione driver Magewell ProCapture..."


wget -q https://www.magewell.com/files/drivers/ProCaptureForLinux_1.3.4418.tar.gz
tar xzf ProCaptureForLinux_1.3.4418.tar.gz
cd ProCaptureForLinux_1.3.4418
sudo ./install.sh

echo
echo "⚠️  È fortemente consigliato riavviare il sistema dopo l'installazione dei driver Magewell."

# --------------------------------------
# 3. Install v4l2-rtsp-bridge
# --------------------------------------
echo
echo "➡️  Installazione v4l2-rtsp-bridge..."

cd /
if [ ! -d /v4l2-rtsp-bridge ]; then
  sudo git clone https://github.com/nesti99/v4l2-rtsp-bridge.git
fi

cd /v4l2-rtsp-bridge
sudo tar zxvf rtsp.tgz -C /

# --------------------------------------
# 4. Encoder selection
# --------------------------------------
echo
echo "======================================"
echo " choose encoder video"
echo "======================================"
echo
echo "1) CPU (libx264)"
echo "2) NVIDIA GPU (NVENC)"
echo "3) Intel GPU (VAAPI)"
echo

read -rp "choose encoder video [1-3]: " CHOICE

TARGET="/usr/local/bin/rtsp_streamer.sh"

case "$CHOICE" in
  1)
    SRC="rtsp_streamer_cpu.sh"
    ENCODER="CPU"
    ;;
  2)
    SRC="rtsp_streamer_nvidia.sh"
    ENCODER="NVIDIA"
    ;;
  3)
    SRC="rtsp_streamer_vaapi.sh"
    ENCODER="VAAPI"
    ;;
  *)
    echo "❌ Scelta non valida"
    exit 1
    ;;
esac

if [ ! -f "$SRC" ]; then
  echo "❌ File $SRC non trovato in $(pwd)"
  exit 1
fi

echo
echo "➡️  Installazione encoder: $ENCODER"
sudo cp "$SRC" "$TARGET"
sudo chmod +x "$TARGET"

# --------------------------------------
# 5. Enable & start service
# --------------------------------------
echo
echo "➡️  Abilitazione servizio systemd..."

sudo systemctl daemon-reload
sudo systemctl enable rtsp-streamer
sudo systemctl restart rtsp-streamer

# --------------------------------------
# Done
# --------------------------------------
echo
echo "✅ Installazione completata con successo"
echo "🎥 Encoder attivo: $ENCODER"
echo "📄 Script runtime: $TARGET"
echo
echo "🔁 Riavvia il sistema per completare l'installazione dei driver Magewell."
