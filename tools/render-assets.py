#!/usr/bin/env python3
"""Генерує логотипи, шпалери й прев'ю Samboryk OS.

Запуск: python3 tools/render-assets.py
Потрібні: rsvg-convert (librsvg2-bin) і Pillow.
Результат лягає в assets/ і в каталоги пакетів.
"""
import os
import random
import subprocess
import tempfile

from PIL import Image, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
A = os.path.join(ROOT, "assets")
os.makedirs(A, exist_ok=True)

S_PATH = ("M16.2 7.6c-.9-1.1-2.3-1.7-4-1.7-2.3 0-4 1.2-4 3 0 4 8.2 2.4 8.2 6.3 "
          "0 1.9-1.8 3.2-4.3 3.2-1.8 0-3.3-.6-4.4-1.8")


def logo_svg():
    # Графітова скляна плитка зі знаком «S».
    return f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" width="256" height="256">
  <defs>
    <linearGradient id="tile" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#4c5059"/>
      <stop offset="1" stop-color="#0d0e11"/>
    </linearGradient>
    <linearGradient id="gloss" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#ffffff" stop-opacity="0.38"/>
      <stop offset="1" stop-color="#ffffff" stop-opacity="0.02"/>
    </linearGradient>
    <linearGradient id="rim" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#ffffff" stop-opacity="0.55"/>
      <stop offset="1" stop-color="#ffffff" stop-opacity="0.08"/>
    </linearGradient>
    <clipPath id="c"><rect x="16" y="16" width="224" height="224" rx="58"/></clipPath>
  </defs>
  <rect x="16" y="16" width="224" height="224" rx="58" fill="url(#tile)"/>
  <g clip-path="url(#c)"><ellipse cx="128" cy="40" rx="170" ry="104" fill="url(#gloss)"/></g>
  <rect x="17" y="17" width="222" height="222" rx="57" fill="none" stroke="url(#rim)" stroke-width="2"/>
  <g transform="translate(128 128) scale(7.2) translate(-12 -12.4)">
    <path d="{S_PATH}" fill="none" stroke="#f4f6f9" stroke-width="2" stroke-linecap="round"/>
  </g>
</svg>
"""


def mark_svg(color="#ffffff"):
    # Кругла монохромна версія для меню й панелі.
    return f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
  <circle cx="12" cy="12" r="10.5" fill="none" stroke="{color}" stroke-width="1.6"/>
  <path d="M15.5 8.2c-.8-.9-2-1.4-3.4-1.4-1.9 0-3.3 1-3.3 2.5 0 3.3 7 2 7 5.3 0 1.6-1.5 2.7-3.6 2.7-1.5 0-2.8-.5-3.7-1.5" fill="none" stroke="{color}" stroke-width="1.8" stroke-linecap="round"/>
</svg>
"""


def wallpaper_svg(dark):
    if dark:
        stops = [("0", "#0b0c0f"), ("0.4", "#202227"), ("0.72", "#434750"), ("1", "#111215")]
        hi, sh = 0.20, 0.55
    else:
        stops = [("0", "#3a3d44"), ("0.38", "#6f747e"), ("0.68", "#c6cbd3"), ("1", "#575c66")]
        hi, sh = 0.60, 0.35
    st = "".join(f'<stop offset="{o}" stop-color="{c}"/>' for o, c in stops)
    return f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 3840 2160" width="3840" height="2160">
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">{st}</linearGradient>
    <linearGradient id="rib" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0" stop-color="#ffffff" stop-opacity="0"/>
      <stop offset="0.45" stop-color="#ffffff" stop-opacity="{hi}"/>
      <stop offset="1" stop-color="#ffffff" stop-opacity="0.05"/>
    </linearGradient>
    <radialGradient id="shade" cx="0.5" cy="0.5" r="0.5">
      <stop offset="0" stop-color="#0b0c0f" stop-opacity="{sh}"/>
      <stop offset="1" stop-color="#0b0c0f" stop-opacity="0"/>
    </radialGradient>
    <filter id="soft" x="-20%" y="-20%" width="140%" height="140%"><feGaussianBlur stdDeviation="18"/></filter>
    <filter id="wide" x="-20%" y="-20%" width="140%" height="140%"><feGaussianBlur stdDeviation="90"/></filter>
  </defs>
  <rect width="3840" height="2160" fill="url(#bg)"/>
  <ellipse cx="2500" cy="2050" rx="2100" ry="1000" fill="url(#shade)"/>
  <path d="M-200 1700 C 700 900, 1500 -150, 2700 -250" fill="none" stroke="url(#rib)" stroke-width="210" filter="url(#wide)"/>
  <path d="M-200 1700 C 700 900, 1500 -150, 2700 -250" fill="none" stroke="url(#rib)" stroke-width="14" filter="url(#soft)"/>
  <path d="M700 2300 C 1600 1300, 2700 800, 4100 900" fill="none" stroke="url(#rib)" stroke-width="320" filter="url(#wide)" opacity="0.8"/>
  <path d="M700 2300 C 1600 1300, 2700 800, 4100 900" fill="none" stroke="url(#rib)" stroke-width="10" filter="url(#soft)"/>
  <path d="M2200 -200 C 2900 500, 3300 1100, 4000 1500" fill="none" stroke="url(#rib)" stroke-width="160" filter="url(#wide)" opacity="0.7"/>
  <path d="M2200 -200 C 2900 500, 3300 1100, 4000 1500" fill="none" stroke="url(#rib)" stroke-width="8" filter="url(#soft)" opacity="0.9"/>
</svg>
"""


def svg_to_png(svg, out, w=None, h=None):
    with tempfile.NamedTemporaryFile("w", suffix=".svg", delete=False) as f:
        f.write(svg)
        p = f.name
    cmd = ["rsvg-convert", p, "-o", out]
    if w:
        cmd += ["-w", str(w)]
    if h:
        cmd += ["-h", str(h)]
    subprocess.run(cmd, check=True)
    os.unlink(p)


def write(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        f.write(text)


def dither_to_jpg(png, jpg):
    # Легкий шум прибирає смуги в градієнтах після стискання.
    im = Image.open(png).convert("RGB")
    rnd = random.Random(7)
    noise = Image.effect_noise(im.size, 6).convert("L")
    noise = noise.filter(ImageFilter.GaussianBlur(0.6))
    im = Image.blend(im, Image.merge("RGB", (noise, noise, noise)), 0.025)
    im.save(jpg, "JPEG", quality=92, optimize=True, progressive=True)
    _ = rnd


def main():
    pk = os.path.join(ROOT, "packages")

    # Логотипи
    write(os.path.join(A, "samboryk-logo.svg"), logo_svg())
    write(os.path.join(A, "samboryk-mark.svg"), mark_svg("#ffffff"))
    write(os.path.join(A, "samboryk-mark-dark.svg"), mark_svg("#15171a"))
    for size in (64, 128, 256, 512):
        svg_to_png(logo_svg(), os.path.join(A, f"samboryk-logo-{size}.png"), size, size)

    br = os.path.join(pk, "samboryk-branding", "root")
    write(os.path.join(br, "usr/share/icons/hicolor/scalable/apps/samboryk-logo.svg"), logo_svg())
    write(os.path.join(br, "usr/share/icons/hicolor/scalable/apps/samboryk-menu.svg"), mark_svg("#ffffff"))
    write(os.path.join(br, "usr/share/samboryk/logo/samboryk-logo.svg"), logo_svg())
    os.makedirs(os.path.join(br, "usr/share/samboryk/logo"), exist_ok=True)
    svg_to_png(logo_svg(), os.path.join(br, "usr/share/samboryk/logo/samboryk-logo-256.png"), 256, 256)
    pl = os.path.join(br, "usr/share/plymouth/themes/samboryk")
    os.makedirs(pl, exist_ok=True)
    svg_to_png(logo_svg(), os.path.join(pl, "logo.png"), 160, 160)
    dot = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" width="16" height="16"><circle cx="8" cy="8" r="5" fill="#f2f4f7"/></svg>'
    svg_to_png(dot, os.path.join(pl, "dot.png"), 16, 16)
    field = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 320 44" width="320" height="44"><rect x="1" y="1" width="318" height="42" rx="21" fill="#ffffff" fill-opacity="0.12" stroke="#ffffff" stroke-opacity="0.35"/></svg>'
    svg_to_png(field, os.path.join(pl, "field.png"), 320, 44)

    th = os.path.join(pk, "samboryk-theme", "root")
    for lnf in ("org.samboryk.silver", "org.samboryk.graphite"):
        sp = os.path.join(th, f"usr/share/plasma/look-and-feel/{lnf}/contents/splash/images")
        os.makedirs(sp, exist_ok=True)
        svg_to_png(logo_svg(), os.path.join(sp, "logo.png"), 160, 160)

    # Шпалери: світла і темна версії в одному пакеті шпалер Plasma
    wp = os.path.join(th, "usr/share/wallpapers/SamborykGlass/contents")
    for dark, sub in ((False, "images"), (True, "images_dark")):
        d = os.path.join(wp, sub)
        os.makedirs(d, exist_ok=True)
        tmp = os.path.join(tempfile.gettempdir(), f"wp-{sub}.png")
        svg_to_png(wallpaper_svg(dark), tmp)
        dither_to_jpg(tmp, os.path.join(d, "3840x2160.jpg"))
        small = Image.open(tmp).convert("RGB").resize((640, 360), Image.LANCZOS)
        small.save(os.path.join(wp, f"screenshot{'_dark' if dark else ''}.png"))
        small.save(os.path.join(A, f"wallpaper{'-dark' if dark else ''}-preview.png"))
        os.unlink(tmp)

    # Прев'ю для вибору глобальної теми
    for lnf, dark in (("org.samboryk.silver", False), ("org.samboryk.graphite", True)):
        pv = os.path.join(th, f"usr/share/plasma/look-and-feel/{lnf}/contents/previews")
        os.makedirs(pv, exist_ok=True)
        src = os.path.join(A, f"wallpaper{'-dark' if dark else ''}-preview.png")
        im = Image.open(src).convert("RGB")
        im.save(os.path.join(pv, "fullscreenpreview.jpg"), "JPEG", quality=90)
        im.resize((320, 180), Image.LANCZOS).save(os.path.join(pv, "preview.png"))
    print("assets ok")


if __name__ == "__main__":
    main()
