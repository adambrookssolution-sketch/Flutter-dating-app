"""Process Figma raw exports into final branding assets.

Inputs (in assets/branding/source/raw/):
  - 8133_611_icon_white.png   1656x3248  Affinity heart+text on white
  - 8133_585_splash_burgundy.png  1656x3248  burgundy gradient splash
  - screen_feed.png    1656x3548
  - screen_travel.png  1656x3680
  - screen_chat.png    1560x3376
  - screen_profile.png 1560x3264
  - screen_inbox.png   1560x3376

Outputs (in assets/branding/):
  - icon.png             1024x1024  burgundy bg + heart+text  (iOS+general)
  - icon_foreground.png  1024x1024  heart only on transparent (Android adaptive fg)
  - splash.png           1242x2688  full splash frame, original aspect
  - feature_graphic.png  1024x500   Google Play feature graphic
  - screenshots/{es,en}/01_feed.png ... 05_security.png  1290x2796  App Store / Play

The same English-language Figma frames are reused for both es/ and en/ for now,
since Figma only contains English copy. Spanish overlays (if needed) come later.
"""

from PIL import Image, ImageOps
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RAW = ROOT / "assets" / "branding" / "source" / "raw"
OUT = ROOT / "assets" / "branding"
SCREENS = OUT / "screenshots"

BURGUNDY = (0xB0, 0x10, 0x30, 255)  # Affinity primary, sampled exact from Figma file


def fit_letterbox(img: Image.Image, target_w: int, target_h: int, bg=(255, 255, 255, 0)) -> Image.Image:
    """Resize img preserving aspect ratio, pad with bg to exact target."""
    img = img.convert("RGBA")
    src_ratio = img.width / img.height
    tgt_ratio = target_w / target_h
    if src_ratio > tgt_ratio:
        new_w = target_w
        new_h = round(target_w / src_ratio)
    else:
        new_h = target_h
        new_w = round(target_h * src_ratio)
    resized = img.resize((new_w, new_h), Image.LANCZOS)
    canvas = Image.new("RGBA", (target_w, target_h), bg)
    canvas.paste(resized, ((target_w - new_w) // 2, (target_h - new_h) // 2), resized)
    return canvas


def cover_crop(img: Image.Image, target_w: int, target_h: int) -> Image.Image:
    """Resize+crop so img fully covers target area (no padding)."""
    img = img.convert("RGBA")
    src_ratio = img.width / img.height
    tgt_ratio = target_w / target_h
    if src_ratio > tgt_ratio:
        new_h = target_h
        new_w = round(target_h * src_ratio)
    else:
        new_w = target_w
        new_h = round(target_w / src_ratio)
    resized = img.resize((new_w, new_h), Image.LANCZOS)
    left = (new_w - target_w) // 2
    top = (new_h - target_h) // 2
    return resized.crop((left, top, left + target_w, top + target_h))


def _extract_heart(src: Image.Image) -> Image.Image:
    """Find the red heart on a white-bg frame and return a tight square crop with
    only the heart preserved (white background and black 'Affinity' text both made
    transparent)."""
    img = src.convert("RGBA")
    px = img.load()
    w, h = img.size
    # Pass 1: keep only red-ish pixels. Anything that's not clearly red becomes transparent.
    # Heart in source is roughly RGB(180,30,50) — saturated red.
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            is_red = r > 120 and r > g + 40 and r > b + 40
            if not is_red:
                px[x, y] = (0, 0, 0, 0)
    bbox = img.getbbox()
    if bbox is None:
        raise RuntimeError("no red pixels found in frame")
    left, top, right, bot = bbox
    bw, bh = right - left, bot - top
    side = max(bw, bh)
    pad = int(side * 0.08)
    side += pad * 2
    cx, cy = (left + right) // 2, (top + bot) // 2
    sq_left = cx - side // 2
    sq_top = cy - side // 2
    return img.crop((sq_left, sq_top, sq_left + side, sq_top + side))


def _recolor(heart: Image.Image, fill=(255, 255, 255, 255)) -> Image.Image:
    """Take the extracted heart (red on transparent) and recolour every visible
    pixel to `fill`, preserving the alpha shape."""
    out = heart.copy()
    px = out.load()
    w, h = out.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a > 0:
                px[x, y] = (fill[0], fill[1], fill[2], a)
    return out


def make_icon_master():
    """1024x1024 icon: burgundy background + WHITE heart centered. Matches the
    Figma splash design (heart looks white-on-burgundy in the gradient frame).
    Plain red-on-burgundy didn't have enough contrast — Figma never uses that
    combination either."""
    src = Image.open(RAW / "8133_611_icon_white.png").convert("RGBA")
    heart = _recolor(_extract_heart(src), fill=(255, 255, 255))
    canvas = Image.new("RGBA", (1024, 1024), BURGUNDY)
    side = round(1024 * 0.70)
    h = heart.resize((side, side), Image.LANCZOS)
    canvas.paste(h, ((1024 - side) // 2, (1024 - side) // 2), h)
    canvas.save(OUT / "icon.png", "PNG", optimize=True)
    print(f"  icon.png  1024x1024  ({(OUT / 'icon.png').stat().st_size // 1024} KB)")


def make_icon_foreground():
    """1024x1024 transparent PNG with the heart only, sized for Android adaptive
    safe zone (inner 66%, but the heart itself fills ~75% of canvas because the
    Android launcher will mask/crop)."""
    src = Image.open(RAW / "8133_611_icon_white.png").convert("RGBA")
    heart = _extract_heart(src)
    fg = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
    side = round(1024 * 0.66)  # safe-zone diameter
    h = heart.resize((side, side), Image.LANCZOS)
    fg.paste(h, ((1024 - side) // 2, (1024 - side) // 2), h)
    fg.save(OUT / "icon_foreground.png", "PNG", optimize=True)
    print(f"  icon_foreground.png  1024x1024  ({(OUT / 'icon_foreground.png').stat().st_size // 1024} KB)")


def make_splash():
    """Splash 1242x2688 (iPhone XS Max-ish), preserving the original burgundy frame."""
    src = Image.open(RAW / "8133_585_splash_burgundy.png").convert("RGBA")
    # Source is 1656x3248 (414x812 @ 4x). cover_crop into 1242x2688.
    out = cover_crop(src, 1242, 2688)
    out.save(OUT / "splash.png", "PNG", optimize=True)
    print(f"  splash.png  1242x2688  ({(OUT / 'splash.png').stat().st_size // 1024} KB)")


def make_feature_graphic():
    """Google Play feature graphic 1024x500: burgundy bg + heart on the left,
    'Affinity' wordmark in white on the right."""
    from PIL import ImageDraw, ImageFont
    src = Image.open(RAW / "8133_611_icon_white.png").convert("RGBA")
    heart = _recolor(_extract_heart(src), fill=(255, 255, 255))
    canvas = Image.new("RGBA", (1024, 500), BURGUNDY)
    # Heart at ~80% of height, left-padded
    side = 380
    h = heart.resize((side, side), Image.LANCZOS)
    canvas.paste(h, (90, (500 - side) // 2), h)
    # White "Affinity" wordmark to the right of the heart
    draw = ImageDraw.Draw(canvas)
    text = "Affinity"
    font = None
    for cand in [
        "C:/Windows/Fonts/segoeui.ttf",
        "C:/Windows/Fonts/calibri.ttf",
        "C:/Windows/Fonts/arial.ttf",
    ]:
        try:
            font = ImageFont.truetype(cand, 130)
            break
        except OSError:
            continue
    if font is None:
        font = ImageFont.load_default()
    bbox = draw.textbbox((0, 0), text, font=font)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    tx = 90 + side + 50
    ty = (500 - th) // 2 - bbox[1]
    draw.text((tx, ty), text, fill=(255, 255, 255, 255), font=font)
    canvas.save(OUT / "feature_graphic.png", "PNG", optimize=True)
    print(f"  feature_graphic.png  1024x500  ({(OUT / 'feature_graphic.png').stat().st_size // 1024} KB)")


def make_screenshot(raw_name: str, out_name: str):
    """Resize a screen frame to App Store 1290x2796."""
    src = Image.open(RAW / raw_name).convert("RGBA")
    # cover_crop preserves edge pixels; safer to letterbox if aspect mismatches significantly.
    out = cover_crop(src, 1290, 2796)
    for lang in ("es", "en"):
        target_dir = SCREENS / lang
        target_dir.mkdir(parents=True, exist_ok=True)
        out.save(target_dir / out_name, "PNG", optimize=True)
    print(f"  screenshots/{{es,en}}/{out_name}  1290x2796  ({(SCREENS / 'es' / out_name).stat().st_size // 1024} KB)")


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    SCREENS.mkdir(parents=True, exist_ok=True)
    print("Generating Affinity branding assets from Figma raws…")
    make_icon_master()
    make_icon_foreground()
    make_splash()
    make_feature_graphic()
    print("Generating App Store / Play screenshots…")
    make_screenshot("screen_feed.png",    "01_feed.png")
    make_screenshot("screen_inbox.png",   "02_filters.png")  # used as filters slot (no Figma filter mock)
    make_screenshot("screen_travel.png",  "03_travel.png")
    make_screenshot("screen_chat.png",    "04_chat.png")
    make_screenshot("screen_profile.png", "05_security.png")
    print("Done.")


if __name__ == "__main__":
    main()
