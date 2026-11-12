#!/usr/bin/env python3
"""Multi Monitor Bar, three changes. Run again after the extension updates, then log in again.
- the bar on other monitors keeps GNOME's Activities button (the workspace dots) even with ArcMenu on.
  The extension assumes ArcMenu replaces Activities, but here ArcMenu's own button is hidden
  (menu-button-appearance='None') and ArcMenu shows Activities itself (show-activities-button=true),
  so the main bar has the dots and the other bars would not.
- the copied System Monitor keeps its natural width instead of the main bar's width from when the copy
  was built, so growing values ('845 kB') do not run into the next icon;
- copied labels keep the source's ellipsize mode: System Monitor never cuts its values, the copies
  did ('↑0.7 …')."""
import os

BASE = os.path.expanduser("~/.local/share/gnome-shell/extensions/multi-monitors-bar@frederykabryan/")
PATCHES = [
    ("mmpanel.js", "lorien: keep Activities",
     "        _shouldSuppressActivitiesForArcMenu() {\n"
     "            return this._isArcMenuRole('ArcMenu');\n",
     "        _shouldSuppressActivitiesForArcMenu() {\n"
     "            // lorien: keep Activities (workspace dots) next to ArcMenu, as on the main bar\n"
     "            return false;\n"),
    ("mmpanel.js", "lorien: dots stay",
     "            if (this._hasArcMenuRole([...leftIndicators, ...centerIndicators, ...rightIndicators])) {\n",
     "            // lorien: dots stay; ArcMenu does not replace Activities here\n"
     "            if (this._shouldSuppressActivitiesForArcMenu()) {\n"),
    ("mirroredIndicatorButton.js", "lorien: live text",
     "                const [width, height] = this._getActorAllocationSize(source);\n"
     "                if (width > 0 && height > 0)\n"
     "                    container.set_size(width, height);\n",
     "                const [width, height] = this._getActorAllocationSize(source);\n"
     "                // lorien: live text (System Monitor) keeps its natural width; the source's width from\n"
     "                // when the copy was built cut '845 kB' to '845 …' or ran it into the next icon\n"
     "                if (height > 0 && this._role?.toLowerCase().includes('system-monitor')) {\n"
     "                    container.set_size(-1, height);\n"
     "                    return;\n"
     "                }\n"
     "                if (width > 0 && height > 0)\n"
     "                    container.set_size(width, height);\n"),
    ("mirroredIndicatorButton.js", "lorien: never cut",
     "            const binding = sourceLabel.bind_property(\n"
     "                'text', labelCopy, 'text', GObject.BindingFlags.SYNC_CREATE);\n",
     "            // lorien: never cut the copy where the source is not (System Monitor: ellipsize NONE)\n"
     "            labelCopy.clutter_text.ellipsize = sourceLabel.clutter_text.ellipsize;\n"
     "            const binding = sourceLabel.bind_property(\n"
     "                'text', labelCopy, 'text', GObject.BindingFlags.SYNC_CREATE);\n"),
]
for name, mark, old, new in PATCHES:
    p = BASE + name
    s = open(p).read()
    if mark in s:
        print(f"{name}: already patched ({mark})")
    elif old in s:
        open(p, "w").write(s.replace(old, new, 1))
        print(f"{name}: patched ({mark})")
    else:
        print(f"{name}: this version looks different; not patched ({mark})")
