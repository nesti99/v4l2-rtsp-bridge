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
apt update && sudo apt upgrade -y
apt install -y git sudo
sudo git clone https://github.com/nesti99/v4l2-rtsp-bridge.git
cd v4l2-rtsp-bridge
chmod +x install.sh
./install.sh
```
**Usage**
Once the service is active, the RTSP streams are available at the following addresses:

rtsp://<HOST_IP>:8554/ch0

rtsp://<HOST_IP>:8554/ch1

rtsp://<HOST_IP>:8554/ch2

rtsp://<HOST_IP>:8554/ch3

Each channel corresponds to a physical HDMI input on the ProCapture card.

**Testing with VLC**
You can quickly test the stream by running:

vlc rtsp://<HOST_IP>:8554/ch0

**Video Encoding Configuration**

The system currently uses the following streaming parameters:

Video Codec: H.264

Encoder: CPU (libx264)

Input Source: V4L2

Output Protocol: RTSP

Service Management (systemd)
The service is registered as rtsp-streamer.service. Use the following commands to manage it:



```Bash
Check service status:
systemctl status rtsp-streamer


Restart the service:
systemctl restart rtsp-streamer

View real-time logs:
journalctl -u rtsp-streamer -f
```
Roadmap / Future Work

🌐 Web Interface: Add a live dashboard for input previews and stream management.

⚙️ Dynamic Configuration: Support for YAML/JSON files to adjust bitrate and resolution.

🔐 Security: Add RTSP authentication support.
