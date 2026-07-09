from __future__ import annotations

import os
import platform
import shutil
import subprocess


def copy(text: str) -> bool:
    system = platform.system().lower()
    try:
        if system == "windows":
            subprocess.run(["clip"], input=text, text=True, check=True, timeout=10)
            return True
        if system == "darwin":
            subprocess.run(["pbcopy"], input=text, text=True, check=True, timeout=10)
            return True
        if os.environ.get("WAYLAND_DISPLAY") and shutil.which("wl-copy"):
            subprocess.run(["wl-copy"], input=text, text=True, check=True, timeout=10)
            return True
        if shutil.which("xclip"):
            subprocess.run(["xclip", "-selection", "clipboard"], input=text, text=True, check=True, timeout=10)
            return True
    except Exception:
        return False
    return False
