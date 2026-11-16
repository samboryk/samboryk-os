#!/usr/bin/env python3
"""Генерує кольорові схеми KDE SamborykSilver і SamborykGraphite."""
import os
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "packages/samboryk-theme/root/usr/share/color-schemes")
ACCENT = "224,38,60"

SCHEMES = {
    "SamborykSilver": dict(
        name="Samboryk Silver",
        window=("246,247,249", "21,23,26"), view=("255,255,255", "21,23,26"), view_alt="244,245,247",
        button=("236,238,241", "21,23,26"), header=("236,238,241", "21,23,26"),
        tooltip=("30,32,36", "242,244,247"), compl=("21,23,26", "242,244,247"),
        inactive="80,85,94", link="37,99,235", visited="109,63,224",
        negative="200,30,51", neutral="180,110,0", positive="21,128,61",
        wm_active=("236,238,241", "21,23,26"), wm_inactive=("242,243,245", "120,125,133")),
    "SamborykGraphite": dict(
        name="Samboryk Graphite",
        window=("28,29,33", "242,244,247"), view=("21,22,25", "242,244,247"), view_alt="32,33,37",
        button=("44,46,51", "242,244,247"), header=("24,25,29", "242,244,247"),
        tooltip=("44,46,51", "242,244,247"), compl=("12,13,16", "242,244,247"),
        inactive="167,173,183", link="96,165,250", visited="167,139,250",
        negative="248,113,113", neutral="251,191,36", positive="74,222,128",
        wm_active=("24,25,29", "242,244,247"), wm_inactive=("28,29,33", "140,145,153")),
}

def group(title, bg, fg, s, alt=None, sel=False):
    if sel:
        bg, fg = ACCENT, "255,255,255"
    return f"""[{title}]
BackgroundAlternate={alt or bg}
BackgroundNormal={bg}
DecorationFocus={ACCENT}
DecorationHover={ACCENT}
ForegroundActive={ACCENT if not sel else fg}
ForegroundInactive={s['inactive'] if not sel else fg}
ForegroundLink={s['link'] if not sel else fg}
ForegroundNegative={s['negative']}
ForegroundNeutral={s['neutral']}
ForegroundNormal={fg}
ForegroundPositive={s['positive']}
ForegroundVisited={s['visited'] if not sel else fg}

"""

for key, s in SCHEMES.items():
    t = """[ColorEffects:Disabled]
Color=56,56,56
ColorAmount=0
ColorEffect=0
ContrastAmount=0.65
ContrastEffect=1
IntensityAmount=0.1
IntensityEffect=2

[ColorEffects:Inactive]
ChangeSelectionColor=true
Color=112,111,110
ColorAmount=0.025
ColorEffect=2
ContrastAmount=0.1
ContrastEffect=2
Enable=false
IntensityAmount=0
IntensityEffect=0

"""
    t += group("Colors:Button", *s["button"], s)
    t += group("Colors:Complementary", *s["compl"], s)
    t += group("Colors:Header", *s["header"], s)
    t += group("Colors:Header][Inactive", *s["window"], s)
    t += group("Colors:Selection", "", "", s, sel=True)
    t += group("Colors:Tooltip", *s["tooltip"], s)
    t += group("Colors:View", *s["view"], s, alt=s["view_alt"])
    t += group("Colors:Window", *s["window"], s)
    t += f"""[General]
ColorScheme={key}
Name={s['name']}
shadeSortColumn=true

[KDE]
contrast=4

[WM]
activeBackground={s['wm_active'][0]}
activeBlend={s['wm_active'][1]}
activeForeground={s['wm_active'][1]}
inactiveBackground={s['wm_inactive'][0]}
inactiveBlend={s['wm_inactive'][1]}
inactiveForeground={s['wm_inactive'][1]}
"""
    os.makedirs(OUT, exist_ok=True)
    with open(os.path.join(OUT, key + ".colors"), "w", encoding="utf-8") as f:
        f.write(t)
print("colors ok")
