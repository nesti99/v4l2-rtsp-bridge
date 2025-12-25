v4l2-rtsp-bridge

v4l2-rtsp-bridge is a Linux service that uses FFmpeg to expose four HDMI inputs of a Magewell ProCapture card as RTSP streams, one per channel (ch0 → ch3), accessible directly from the host machine IP address.

The project is designed for headless servers and runs as a systemd service.

Features

Support for 4 HDMI inputs (ProCapture Quad)

Independent RTSP stream per channel

Based on FFmpeg

CPU-based video encoding

Automatic startup via systemd

No graphical interface required

System Requirements

Debian / Ubuntu

Linux kernel 5.10

Magewell ProCapture capture card

Root or sudo privileges

Internet connection

Installation
1. Install system dependencies

Update the system and install required packages:

'apt update && apt upgrade -y && apt install \
ffmpeg \
python3 \
python3-pip \
v4l-utils \
intel-media-va-driver \
linux-headers-5.10.0-37-amd64 \
git -y'

2. Install Magewell ProCapture drivers

Download and install the official Magewell Linux drivers:

wget https://www.magewell.com/files/drivers/ProCaptureForLinux_1.3.4418.tar.gz
tar xzvf ProCaptureForLinux_1.3.4418.tar.gz
cd ProCaptureForLinux_1.3.4418
./install.sh


⚠️ A system reboot is strongly recommended after driver installation.

3. Install v4l2-rtsp-bridge

Clone the repository and install the RTSP service files:

cd /
git clone https://github.com/nesti99/v4l2-rtsp-bridge.git
cd v4l2-rtsp-bridge
tar zxvf rtsp.tgz -C /


Reload systemd and enable the service:

systemctl daemon-reload
systemctl enable rtsp-streamer
systemctl start rtsp-streamer

Usage

Once the service is running, the RTSP streams are available at:

rtsp://<HOST_IP>:8554/ch0
rtsp://<HOST_IP>:8554/ch1
rtsp://<HOST_IP>:8554/ch2
rtsp://<HOST_IP>:8554/ch3


Each channel corresponds to one HDMI input on the ProCapture card.

Testing with VLC
vlc rtsp://<HOST_IP>:8554/ch0

Video Encoding

Current streaming configuration:

Video codec: H.264

Encoder: CPU (libx264)

Input: V4L2

Output: RTSP

systemd Service

The service is installed as:

rtsp-streamer.service


Useful commands:

systemctl status rtsp-streamer
systemctl restart rtsp-streamer
journalctl -u rtsp-streamer -f

Roadmap / Future Work

Planned features and improvements:

🚀 Hardware-accelerated encoding

Intel VAAPI

NVIDIA NVENC / CUDA

🌐 Web interface

Live preview of all inputs

Start / stop individual streams

Configure bitrate, resolution and codec

⚙️ Dynamic configuration via YAML / JSON

🔐 RTSP authentication support

Notes

Designed for broadcast and industrial environments

FFmpeg must be built with required codec support

Performance depends on CPU when using software encoding
