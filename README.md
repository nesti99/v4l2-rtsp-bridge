# v4l2-rtsp-bridge

**v4l2-rtsp-bridge** is a Linux service that leverages FFmpeg to expose the four HDMI inputs of a **Magewell ProCapture** card as independent RTSP streams. Each channel (from `ch0` to `ch3`) is directly accessible via the host machine's IP address.

The project is optimized for **headless servers** and runs as a system service managed by `systemd`.

---

## Features

* **4-Channel Support:** Specifically designed for Magewell ProCapture Quad cards.
* **Independent RTSP Streams:** A dedicated stream for each physical HDMI input.
* **FFmpeg-based:** Reliable, versatile, and widely compatible.
* **CPU Video Encoding:** Software-based stream processing (libx264).
* **Automatic Startup:** Fully integrated as a `systemd` service.
* **Headless Design:** Operates without a graphical interface or local monitor.

---

## System Requirements

* **Operating System:** Debian / Ubuntu
* **Kernel:** Linux 5.10
* **Hardware:** Magewell ProCapture acquisition card
* **Privileges:** Root or `sudo` access
* **Internet:** Required for initial package installation

---

## Installation

### 1. Install System Dependencies
Update your system and install the required packages:

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y \
  ffmpeg \
  python3 \
  python3-pip \
  v4l-utils \
  intel-media-va-driver \
  linux-headers-5.10.0-37-amd64 \
  sudo \
  git

# 2. Install Magewell ProCapture Drivers
# Download and install the official Magewell Linux drivers:

wget [https://www.magewell.com/files/drivers/ProCaptureForLinux_1.3.4418.tar.gz](https://www.magewell.com/files/drivers/ProCaptureForLinux_1.3.4418.tar.gz)
tar xzvf ProCaptureForLinux_1.3.4418.tar.gz
cd ProCaptureForLinux_1.3.4418
sudo ./install.sh
# [!IMPORTANT] A system reboot is strongly recommended after the driver installation is complete.

# 3. Install v4l2-rtsp-bridge
# Clone the repository and install the RTSP service files:

cd /
sudo git clone https://github.com/nesti99/v4l2-rtsp-bridge.git
cd v4l2-rtsp-bridge
sudo tar zxvf rtsp.tgz -C /
# Reload systemd and enable the service:

sudo systemctl daemon-reload
sudo systemctl enable rtsp-streamer
sudo systemctl start rtsp-streamer
```
Usage
Once the service is active, the RTSP streams are available at the following addresses:

rtsp://<HOST_IP>:8554/ch0

rtsp://<HOST_IP>:8554/ch1

rtsp://<HOST_IP>:8554/ch2

rtsp://<HOST_IP>:8554/ch3

Each channel corresponds to a physical HDMI input on the ProCapture card.

Testing with VLC
You can quickly test the stream by running:

vlc rtsp://<HOST_IP>:8554/ch0
Video Encoding Configuration
The system currently uses the following streaming parameters:

Video Codec: H.264

Encoder: CPU (libx264)

Input Source: V4L2

Output Protocol: RTSP

Service Management (systemd)
The service is registered as rtsp-streamer.service. Use the following commands to manage it:

Check service status:

```Bash

systemctl status rtsp-streamer
Restart the service:

systemctl restart rtsp-streamer
View real-time logs:

journalctl -u rtsp-streamer -f
```
Roadmap / Future Work

🚀 Hardware Acceleration: Implement support for Intel VAAPI and NVIDIA NVENC/CUDA.

🌐 Web Interface: Add a live dashboard for input previews and stream management.

⚙️ Dynamic Configuration: Support for YAML/JSON files to adjust bitrate and resolution.

🔐 Security: Add RTSP authentication support.
