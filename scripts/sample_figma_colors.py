"""Sample dominant colours from Figma raw frames so we can align the app's
hardcoded palette with the real Figma values instead of approximations."""

from PIL import Image
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RAW = ROOT / "assets" / "branding" / "source" / "raw"


def quantize(rgb, step=8):
    return tuple((c // step) * step for c in rgb)


def top_colors(path: Path, n=8, alpha_threshold=128):
    img = Image.open(path).convert("RGBA")
    cnt: Counter = Counter()
    for px in img.getdata():
        r, g, b, a = px
        if a < alpha_threshold:
            continue
        cnt[quantize((r, g, b))] += 1
    return cnt.most_common(n)


def hex_(rgb):
    return "#{:02X}{:02X}{:02X}".format(*rgb)


def main():
    targets = [
        ("splash burgundy gradient", "8133_585_splash_burgundy.png"),
        ("welcome (entry, burgundy + buttons)", None),  # no raw — only thumb
        ("feed card (burgundy CTA)", "screen_feed.png"),
        ("travel card (burgundy gradient)", "screen_travel.png"),
        ("profile header (burgundy band)", "screen_profile.png"),
        ("chat (burgundy bubble)", "screen_chat.png"),
        ("icon master (red heart)", "8133_611_icon_white.png"),
    ]
    for label, fname in targets:
        if fname is None:
            continue
        path = RAW / fname
        if not path.exists():
            print(f"  [skip] {label}: {fname} not found")
            continue
        print(f"\n{label}  ({fname})")
        for rgb, count in top_colors(path):
            print(f"  {hex_(rgb)}  count={count}")


if __name__ == "__main__":
    main()
