apt update && apt upgrade && apt install ffmpeg python3 python3-pip v4l-utils intel-media-va-driver
wget https://www.magewell.com/files/drivers/ProCaptureForLinux_1.3.4418.tar.gz
tar xzvf ProCaptureForLinux_1.3.4418.tar.gz
cd ProCaptureForLinux_1.3.4418
./install.sh
cd /
gh repo clone nesti99/v4l2-rtsp-bridge
cd v4l2-rtsp-bridge
tar zxvf rtsp.tgz -C /
systemctl daemon-reload
systemctl enable rtsp-streamer
systemctl start rtsp-streamer
