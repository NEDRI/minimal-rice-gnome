#!/usr/bin/env python3
"""Dynamic Music Pill: lyric lines scroll at most 35 px/s instead of racing to finish within the line's
time. Run again after the extension updates, then log in again."""
import os
p = os.path.expanduser("~/.local/share/gnome-shell/extensions/dynamic-music-pill@andbal/src/uiWidgets.js")
s = open(p).read()
old = "            const scrollDuration = totalDurationMs - pauseTime - tailTime;\n"
new = ("            // lorien: never faster than 35 px/s, even if the line ends before the text does\n"
       "            const scrollDuration = Math.max(totalDurationMs - pauseTime - tailTime, (distance / 35) * 1000);\n")
if "lorien: never faster" in s:
    print("already patched")
elif old in s:
    open(p, "w").write(s.replace(old, new, 1))
    print("patched")
else:
    print("this version of Dynamic Music Pill looks different; not patched")
