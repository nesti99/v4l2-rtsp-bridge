import subprocess
import signal
import glob

from flask import Flask, request, render_template_string, redirect, url_for

app = Flask(__name__)

# key -> {proc, dev, url}
PROCS = {}

HTML = """
<!DOCTYPE html>
<html lang="it">
<head>
    <meta charset="utf-8">
    <title>FFmpeg RTSP Restreamer</title>
    <style>
        :root {
            --bg: #0f172a;
            --panel: #111827;
            --card: #1f2933;
            --accent: #38bdf8;
            --accent-hover: #0ea5e9;
            --danger: #ef4444;
            --text: #e5e7eb;
            --muted: #9ca3af;
            --border: #334155;
            --radius: 10px;
        }

        * {
            box-sizing: border-box;
            font-family: system-ui, -apple-system, BlinkMacSystemFont,
                         "Segoe UI", Roboto, Ubuntu, sans-serif;
        }

        body {
            margin: 0;
            background: linear-gradient(135deg, #020617, #0f172a);
            color: var(--text);
            padding: 40px;
        }

        .container {
            display: flex;
            gap: 40px;
            flex-wrap: wrap;
        }

        h2 {
            font-size: 1.6rem;
            margin-top: 0;
        }

        h3 {
            margin-bottom: 10px;
            color: var(--accent);
        }

        .panel {
            background: var(--panel);
            border: 1px solid var(--border);
            border-radius: var(--radius);
            padding: 20px;
            width: 420px;
            box-shadow: 0 10px 30px rgba(0,0,0,.35);
        }

        b {
            display: block;
            margin-bottom: 6px;
            color: var(--muted);
            font-size: 0.8rem;
            text-transform: uppercase;
        }

        input, select {
            width: 100%;
            padding: 10px 12px;
            margin-bottom: 14px;
            background: var(--card);
            border: 1px solid var(--border);
            border-radius: 6px;
            color: var(--text);
            font-size: 0.95rem;
        }

        input:focus, select:focus {
            outline: none;
            border-color: var(--accent);
        }

        button {
            background: var(--accent);
            color: #002;
            border: none;
            border-radius: 6px;
            padding: 10px 14px;
            font-weight: 600;
            cursor: pointer;
            transition: all .2s ease;
        }

        button:hover {
            background: var(--accent-hover);
        }

        button.stop {
            background: var(--danger);
            color: white;
        }

        button.stop:hover {
            opacity: .85;
        }

        ul {
            list-style: none;
            padding: 0;
            margin: 0;
        }

        li.stream {
            background: var(--card);
            border: 1px solid var(--border);
            border-radius: 8px;
            padding: 12px;
            margin-bottom: 10px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        .stream-info {
            font-size: 0.9rem;
        }

        .stream-info b {
            color: var(--accent);
            font-size: 0.85rem;
        }

        pre {
            margin-top: 15px;
            color: var(--danger);
            white-space: pre-wrap;
            font-size: 0.85rem;
        }
    </style>
</head>

<body>
    <h2>🎥 FFmpeg RTSP Restreamer</h2>

    <div class="container">
        <div class="panel">
            <form method="post" action="/start">
                <b>Device</b>
                <select name="dev">
                    {% for d in devs %}
                        <option value="{{ d }}">{{ d }}</option>
                    {% endfor %}
                </select>

                <b>RTSP URL</b>
                <input name="url" value="rtsp://127.0.0.1:8554/cam0">

                <b>Codec</b>
                <select name="codec">
                    <option value="h264_nvenc">h264_nvenc</option>
                    <option value="hevc_nvenc">hevc_nvenc</option>
                    <option value="copy">copy</option>
                </select>

                <b>Bitrate (kbit)</b>
                <input name="br" value="4000">

                <button>START STREAM</button>
            </form>

            {% if msg %}
                <pre>{{ msg }}</pre>
            {% endif %}
        </div>

        <div class="panel">
            <h3>Stream attivi</h3>
            <ul>
                {% for k, v in procs.items() %}
                    <li class="stream">
                        <div class="stream-info">
                            <b>{{ k }}</b><br>
                            {{ v.dev }} → {{ v.url }}
                        </div>
                        <form method="post" action="/stop">
                            <input type="hidden" name="key" value="{{ k }}">
                            <button class="stop">STOP</button>
                        </form>
                    </li>
                {% else %}
                    <li class="stream">Nessuno stream attivo</li>
                {% endfor %}
            </ul>
        </div>
    </div>
</body>
</html>
"""


def list_devs():
    return sorted(glob.glob("/dev/video*"))


@app.route("/")
def index():
    return render_template_string(
        HTML,
        devs=list_devs(),
        procs=PROCS,
        msg=""
    )


@app.route("/start", methods=["POST"])
def start():
    dev = request.form["dev"]
    url = request.form["url"].strip()
    codec = request.form["codec"]
    br = request.form["br"]

    key = url.split("/")[-1]

    # device già in uso
    for s in PROCS.values():
        if s["dev"] == dev:
            return render_template_string(
                HTML,
                devs=list_devs(),
                procs=PROCS,
                msg=f"ERRORE: {dev} già in uso"
            )

    if key in PROCS:
        return render_template_string(
            HTML,
            devs=list_devs(),
            procs=PROCS,
            msg=f"ERRORE: stream {key} già attivo"
        )

    if codec == "copy":
        vopts = ["-c:v", "copy"]
    else:
        vopts = [
            "-c:v", codec,
            "-b:v", f"{br}k",
            "-preset", "p4",
            "-rc", "cbr"
        ]

    cmd = [
        "ffmpeg",
        "-hide_banner",
        "-loglevel", "warning",
        "-f", "v4l2",
        "-i", dev,
        *vopts,
        "-f", "rtsp",
        "-rtsp_transport", "tcp",
        url
    ]

    p = subprocess.Popen(cmd)

    PROCS[key] = {
        "proc": p,
        "dev": dev,
        "url": url
    }

    return redirect(url_for("index"))


@app.route("/stop", methods=["POST"])
def stop():
    key = request.form["key"]

    if key in PROCS:
        PROCS[key]["proc"].send_signal(signal.SIGTERM)
        del PROCS[key]

    return redirect(url_for("index"))


if __name__ == "__main__":
    app.run("0.0.0.0", 5000)
