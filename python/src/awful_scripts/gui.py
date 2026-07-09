from __future__ import annotations

from pathlib import Path
import threading
import tkinter as tk
from tkinter import filedialog, messagebox, scrolledtext

from .audits import MODES, run
from .clipboard import copy


def main(root_path: Path | None = None) -> None:
    current = root_path or Path.cwd()
    window = tk.Tk()
    window.title("awful-audit")
    path_var = tk.StringVar(value=str(current))
    mode_var = tk.StringVar(value="all")
    status_var = tk.StringVar(value="ready")
    output = scrolledtext.ScrolledText(window, width=110, height=34)

    def browse() -> None:
        selected = filedialog.askdirectory(initialdir=path_var.get())
        if selected:
            path_var.set(selected)

    def set_busy(is_busy: bool) -> None:
        run_button.configure(state=tk.DISABLED if is_busy else tk.NORMAL)
        browse_button.configure(state=tk.DISABLED if is_busy else tk.NORMAL)
        status_var.set("running" if is_busy else "ready")

    def execute() -> None:
        root = Path(path_var.get())
        mode = mode_var.get()
        set_busy(True)
        output.delete("1.0", tk.END)
        output.insert(tk.END, "running...\n")

        def worker() -> None:
            try:
                result = run(mode, root)
                copied = copy(result.text)

                def done() -> None:
                    output.delete("1.0", tk.END)
                    output.insert(tk.END, result.text)
                    set_busy(False)
                    messagebox.showinfo("awful-audit", "Report copied." if copied else "Report built. Clipboard skipped because the report is large or unavailable.")

                window.after(0, done)
            except Exception as exc:
                def failed() -> None:
                    output.delete("1.0", tk.END)
                    output.insert(tk.END, f"ERROR: {exc}")
                    set_busy(False)

                window.after(0, failed)

        threading.Thread(target=worker, daemon=True).start()

    top = tk.Frame(window)
    top.pack(fill=tk.X, padx=8, pady=8)
    tk.Entry(top, textvariable=path_var).pack(side=tk.LEFT, fill=tk.X, expand=True)
    browse_button = tk.Button(top, text="Browse", command=browse)
    browse_button.pack(side=tk.LEFT, padx=4)
    tk.OptionMenu(top, mode_var, "all", *MODES.keys()).pack(side=tk.LEFT)
    run_button = tk.Button(top, text="Run", command=execute)
    run_button.pack(side=tk.LEFT, padx=4)
    tk.Label(window, textvariable=status_var, anchor="w").pack(fill=tk.X, padx=8)
    output.pack(fill=tk.BOTH, expand=True, padx=8, pady=(0, 8))
    window.mainloop()
