#!/usr/bin/env python3
"""List every wallpaper on this computer in GNOME Settings → Appearance: the images of at least 1280x720 in
~/Pictures/Wallpapers, ~/.local/share/wallpapers, ~/.local/share/backgrounds and /usr/share/backgrounds that
GNOME's own lists don't already show. Writes ~/.local/share/gnome-background-properties/lorien-wallpapers.xml;
run it again after adding wallpapers."""
import glob
import html
import os
import re
import struct

HOME = os.path.expanduser("~")
ROOTS = [HOME + "/Pictures/Wallpapers", HOME + "/.local/share/wallpapers", HOME + "/.local/share/backgrounds",
         "/usr/share/backgrounds"]
EXTS = (".jpg", ".jpeg", ".png", ".webp")


def size(path):
    """(width, height) from the file header, without Pillow; None if unknown."""
    with open(path, "rb") as f:
        head = f.read(32)
        if head.startswith(b"\x89PNG"):
            return struct.unpack(">II", head[16:24])
        if head[:4] == b"RIFF" and head[8:12] == b"WEBP":
            return None
        if head[:2] == b"\xff\xd8":
            f.seek(2)
            while True:
                marker = f.read(2)
                if len(marker) < 2 or marker[0] != 0xFF:
                    return None
                if marker[1] in (0xC0, 0xC1, 0xC2):
                    f.read(3)
                    h, w = struct.unpack(">HH", f.read(4))
                    return w, h
                f.seek(struct.unpack(">H", f.read(2))[0] - 2, 1)
    return None


known = set()
for x in glob.glob("/usr/share/gnome-background-properties/*.xml"):
    known |= set(re.findall(r"<filename>([^<]+)</filename>", open(x, errors="ignore").read()))

items = []
for root in ROOTS:
    for dp, _dn, fn in os.walk(root):
        for f in sorted(fn):
            p = os.path.join(dp, f)
            if not f.lower().endswith(EXTS) or p in known:
                continue
            s = size(p)
            if s and (s[0] < 1280 or s[1] < 720):
                continue
            items.append(p)


def name(p):
    if "/contents/images/" in p:   # KDE wallpaper packages: the folder is the name
        return p.split("/contents/images/")[0].rsplit("/", 1)[-1].replace("-", " ")
    return os.path.splitext(os.path.basename(p))[0].replace("_", " ")


out = ['<?xml version="1.0" encoding="UTF-8"?>', '<!DOCTYPE wallpapers SYSTEM "gnome-wp-list.dtd">', "<wallpapers>"]
for p in items:
    out.append(f'  <wallpaper deleted="false">\n    <name>{html.escape(name(p))}</name>\n'
               f"    <filename>{html.escape(p)}</filename>\n    <options>zoom</options>\n"
               "    <shade_type>solid</shade_type>\n  </wallpaper>")
out.append("</wallpapers>")
dest = HOME + "/.local/share/gnome-background-properties"
os.makedirs(dest, exist_ok=True)
open(dest + "/lorien-wallpapers.xml", "w").write("\n".join(out) + "\n")
print(f"{len(items)} wallpapers listed in Settings → Appearance")
