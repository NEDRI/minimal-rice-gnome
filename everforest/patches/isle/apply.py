#!/usr/bin/env python3
"""Isle, one change. Run again after the extension updates, then log in again.
- the copy of the island on another monitor takes the bar's sizes (15 px clock, smaller icons) when that
  monitor has a Multi Monitor Bar panel. Isle counts only GNOME's own panel as a top bar, so there the copy
  kept its 'hanging below the bar' sizes and its clock stood out from the rest of the bar."""
import os

BASE = os.path.expanduser("~/.local/share/gnome-shell/extensions/isle@zickrian.github.io/src/")
PATCHES = [
    ("controller.js", "lorien: Multi Monitor Bar",
     "        mirror.compact.inBar = this._compactInBar(onBar);\n",
     "        // lorien: Multi Monitor Bar's panel on that display is a top bar too: the copy takes the bar's sizes\n"
     "        const onMMBar = Main.extensionManager.lookup('multi-monitors-bar@frederykabryan')?.state === 1 &&\n"
     "            mirror.monitor.index !== Main.layoutManager.primaryIndex;\n"
     "        mirror.compact.inBar = this._compactInBar(onBar || onMMBar);\n"),
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
