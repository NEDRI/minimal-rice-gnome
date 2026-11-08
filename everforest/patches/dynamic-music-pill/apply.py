#!/usr/bin/env python3
"""Dynamic Music Pill, two small changes. Run again after the extension updates, then log in again.
- lyric lines scroll at most 35 px/s instead of racing to finish within the line's time;
- a paused player hides the pill, like a stopped one (unless "always show the pill" is on)."""
import os

BASE = os.path.expanduser("~/.local/share/gnome-shell/extensions/dynamic-music-pill@andbal/src/")
PATCHES = [
    ("uiWidgets.js", "lorien: never faster",
     "            const scrollDuration = totalDurationMs - pauseTime - tailTime;\n",
     "            // lorien: never faster than 35 px/s, even if the line ends before the text does\n"
     "            const scrollDuration = Math.max(totalDurationMs - pauseTime - tailTime, (distance / 35) * 1000);\n"),
    ("uiMusicPill.js", "lorien: a paused player",
     "            if (!title || status === 'Stopped') {\n",
     "            // lorien: a paused player hides the pill too, unless 'always show' is on\n"
     "            if (!title || status === 'Stopped' || (status === 'Paused' && !this._settings.get_boolean('always-show-pill'))) {\n"),
]
for name, mark, old, new in PATCHES:
    p = BASE + name
    s = open(p).read()
    if mark in s:
        print(f"{name}: already patched")
    elif old in s:
        open(p, "w").write(s.replace(old, new, 1))
        print(f"{name}: patched")
    else:
        print(f"{name}: this version looks different; not patched")
