from __future__ import annotations

from pathlib import Path
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
    output = scrolledtext.ScrolledText(window, width=110, height=34)

    def browse() -> None:
        selected = filedialog.askdirectory(initialdir=path_var.get())
        if selected:
            path_var.set(selected)

    def execute() -> None:
        result = run(mode_var.get(), Path(path_var.get()))
        output.delete("1.0", tk.END)
        output.insert(tk.END, result.text)
        copy(result.text)
        messagebox.showinfo("awful-audit", "Report copied when clipboard is available.")

    top = tk.Frame(window)
    top.pack(fill=tk.X, padx=8, pady=8)
    tk.Entry(top, textvariable=path_var).pack(side=tk.LEFT, fill=tk.X, expand=True)
    tk.Button(top, text="Browse", command=browse).pack(side=tk.LEFT, padx=4)
    tk.OptionMenu(top, mode_var, "all", *MODES.keys()).pack(side=tk.LEFT)
    tk.Button(top, text="Run", command=execute).pack(side=tk.LEFT, padx=4)
    output.pack(fill=tk.BOTH, expand=True, padx=8, pady=(0, 8))
    window.mainloop()
