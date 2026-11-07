#!/usr/bin/env python3
"""Kiwi Menu: add a white EndeavourOS logo drawn on the 16 px grid (sharp in the top bar) and drop the blurred
shadow under the menu icon. Idempotent; prints the index of the logo, to put in the extension's 'icon' key.
Kiwi Menu updates overwrite it: run again after one. St caches icons by path, so the file name must stay new
(eos-white-16px.svg) whenever the picture changes."""
import json
import os
import shutil
import sys

ext = os.path.expanduser("~/.local/share/gnome-shell/extensions/kiwimenu@kemma")
here = os.path.dirname(os.path.abspath(__file__))
if not os.path.isdir(ext):
    sys.exit("Kiwi Menu is not installed")

shutil.copy(os.path.join(here, "eos-white-16px.svg"), os.path.join(ext, "icons", "eos-white-16px.svg"))

icons_json = os.path.join(ext, "src", "icons.json")
icons = json.load(open(icons_json))
entry = next((i for i in icons if i.get("title") == "EndeavourOS"), None)
if entry is None:
    entry = {"idx": max(i["idx"] for i in icons) + 1, "title": "EndeavourOS", "path": "/icons/eos-white-16px.svg"}
    icons.append(entry)
entry["path"] = "/icons/eos-white-16px.svg"
json.dump(icons, open(icons_json, "w"), indent=2)

css = os.path.join(ext, "stylesheet.css")
text = open(css).read()
open(css, "w").write(text.replace("icon-shadow: 0 1px 3px 3px rgba(0, 0, 0, 0.15);", "icon-shadow: none;"))

print(entry["idx"])
