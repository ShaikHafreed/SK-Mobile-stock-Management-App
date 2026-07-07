"""
Generates the SR Mobiles app icon: a blue gradient rounded-square with a
white phone glyph, matching the login screen's existing branding
(gradient #1565C0 -> #42A5F5, phone icon motif).

Run once with the backend venv (has Pillow):
    ../../backend/venv/Scripts/python.exe generate_icon.py
Outputs app_icon_master.png (1024x1024) plus every Android mipmap size.
"""
import math
import os

from PIL import Image, ImageDraw, ImageFilter

SIZE = 1024
COLOR_TOP_LEFT = (21, 101, 192)      # 0xFF1565C0
COLOR_BOTTOM_RIGHT = (66, 165, 245)  # 0xFF42A5F5
WHITE = (255, 255, 255, 255)

HERE = os.path.dirname(os.path.abspath(__file__))
MIPMAP_TARGETS = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}
RES_DIR = os.path.join(HERE, "..", "android", "app", "src", "main", "res")


def make_gradient_background(size):
    img = Image.new("RGBA", (size, size))
    for y in range(size):
        for x in range(size):
            t = (x + y) / (2 * size)
            r = int(COLOR_TOP_LEFT[0] + (COLOR_BOTTOM_RIGHT[0] - COLOR_TOP_LEFT[0]) * t)
            g = int(COLOR_TOP_LEFT[1] + (COLOR_BOTTOM_RIGHT[1] - COLOR_TOP_LEFT[1]) * t)
            b = int(COLOR_TOP_LEFT[2] + (COLOR_BOTTOM_RIGHT[2] - COLOR_TOP_LEFT[2]) * t)
            img.putpixel((x, y), (r, g, b, 255))
    return img


def make_gradient_background_fast(size):
    # Row/col-wise interpolation is much faster than per-pixel loops.
    base = Image.new("RGBA", (size, 1))
    for x in range(size):
        t = x / size
        r = int(COLOR_TOP_LEFT[0] + (COLOR_BOTTOM_RIGHT[0] - COLOR_TOP_LEFT[0]) * t * 0.5)
        g = int(COLOR_TOP_LEFT[1] + (COLOR_BOTTOM_RIGHT[1] - COLOR_TOP_LEFT[1]) * t * 0.5)
        b = int(COLOR_TOP_LEFT[2] + (COLOR_BOTTOM_RIGHT[2] - COLOR_TOP_LEFT[2]) * t * 0.5)
        base.putpixel((x, 0), (r, g, b, 255))
    row = base.resize((size, size))
    col = row.transpose(Image.ROTATE_90)
    return Image.blend(row, col, 0.5)


def rounded_square_mask(size, radius):
    mask = Image.new("L", (size, size), 0)
    d = ImageDraw.Draw(mask)
    d.rounded_rectangle([0, 0, size - 1, size - 1], radius=radius, fill=255)
    return mask


def draw_phone_glyph(canvas, size):
    d = ImageDraw.Draw(canvas)
    pw = size * 0.34
    ph = size * 0.52
    cx, cy = size / 2, size / 2 - size * 0.01
    left, top = cx - pw / 2, cy - ph / 2
    right, bottom = cx + pw / 2, cy + ph / 2
    radius = size * 0.07

    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    off = size * 0.012
    sd.rounded_rectangle(
        [left + off, top + off * 2.2, right + off, bottom + off * 2.2],
        radius=radius, fill=(0, 0, 0, 70),
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(size * 0.02))
    canvas.alpha_composite(shadow)

    d.rounded_rectangle([left, top, right, bottom], radius=radius, fill=WHITE)

    screen_pad = size * 0.028
    screen_color = COLOR_TOP_LEFT + (255,)
    d.rounded_rectangle(
        [left + screen_pad, top + screen_pad * 1.8,
         right - screen_pad, bottom - screen_pad * 3.2],
        radius=radius * 0.55, fill=screen_color,
    )

    home_r = size * 0.018
    home_cy = bottom - screen_pad * 1.6
    d.ellipse(
        [cx - home_r, home_cy - home_r, cx + home_r, home_cy + home_r],
        fill=(255, 255, 255, 140),
    )

    speaker_w = size * 0.05
    speaker_y = top + screen_pad * 0.9
    d.rounded_rectangle(
        [cx - speaker_w / 2, speaker_y - 2, cx + speaker_w / 2, speaker_y + 2],
        radius=2, fill=(255, 255, 255, 160),
    )


def build_master():
    bg = make_gradient_background_fast(SIZE)
    mask = rounded_square_mask(SIZE, radius=int(SIZE * 0.22))
    canvas = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    canvas.paste(bg, (0, 0), mask)
    draw_phone_glyph(canvas, SIZE)
    return canvas


def main():
    master = build_master()
    master_path = os.path.join(HERE, "app_icon_master.png")
    master.save(master_path)
    print("Saved", master_path)

    for folder, px in MIPMAP_TARGETS.items():
        out_dir = os.path.join(RES_DIR, folder)
        os.makedirs(out_dir, exist_ok=True)
        resized = master.resize((px, px), Image.LANCZOS)
        out_path = os.path.join(out_dir, "ic_launcher.png")
        resized.save(out_path)
        print("Saved", out_path, f"({px}x{px})")

    play_store_path = os.path.join(HERE, "play_store_icon_512.png")
    master.resize((512, 512), Image.LANCZOS).save(play_store_path)
    print("Saved", play_store_path)


if __name__ == "__main__":
    main()
