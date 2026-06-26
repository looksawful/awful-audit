from __future__ import annotations

import os
import platform
import subprocess


def copy(text: str) -> bool:
    system = platform.system().lower()
    try:
        if system == "windows":
            subprocess.run(["clip"], input=text, text=True, check=True)
            return True
        if system == "darwin":
            subprocess.run(["pbcopy"], input=text, text=True, check=True)
            return True
        if os.environ.get("WAYLAND_DISPLAY"):
            subprocess.run(["wl-copy"], input=text, text=True, check=True)
            return True
        subprocess.run(["xclip", "-selection", "clipboard"], input=text, text=True, check=True)
        return True
    except Exception:
        return False
