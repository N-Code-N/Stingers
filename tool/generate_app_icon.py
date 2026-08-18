#!/usr/bin/env python3
"""Draws the app icon and writes every size iOS and Android ask for.

The mark: a strip of film seen head-on, its sprocket holes down both edges, with rolling
credits in the frames — line after line of type marching upward and thinning out — and one
last frame below them that is not text at all. That frame is the stinger.

Palette is the app's own (core/theme/app_theme.dart): near-black ground, warm off-white
for the credit lines, amber for the scene. No blue anywhere, for the same reason the app
has no light theme.

Everything is drawn at 4x and box-filtered down, which is how the diagonal sprocket
corners and thin credit lines stay clean at 40px.

    python3 tool/generate_app_icon.py

Requires Pillow. Regenerate after changing the palette; the output is committed.
"""

from __future__ import annotations

import os
from PIL import Image, ImageDraw

SS = 4  # supersampling factor

BACKGROUND = (10, 10, 11)
STRIP = (36, 33, 29)
STRIP_EDGE = (46, 42, 38)
SPROCKET = (10, 10, 11)
CREDIT = (242, 235, 224)
ACCENT = (255, 176, 32)

# iOS wants a full-bleed square; Android's adaptive foreground is cropped to a circle of
# ~66% and may be masked further, so the mark itself stays well inside a safe radius.
IOS_SIZES = {
    'Icon-App-20x20@1x.png': 20, 'Icon-App-20x20@2x.png': 40, 'Icon-App-20x20@3x.png': 60,
    'Icon-App-29x29@1x.png': 29, 'Icon-App-29x29@2x.png': 58, 'Icon-App-29x29@3x.png': 87,
    'Icon-App-40x40@1x.png': 40, 'Icon-App-40x40@2x.png': 80, 'Icon-App-40x40@3x.png': 120,
    'Icon-App-60x60@2x.png': 120, 'Icon-App-60x60@3x.png': 180,
    'Icon-App-76x76@1x.png': 76, 'Icon-App-76x76@2x.png': 152,
    'Icon-App-83.5x83.5@2x.png': 167,
    'Icon-App-1024x1024@1x.png': 1024,
}

ANDROID_SIZES = {
    'mipmap-mdpi': 48, 'mipmap-hdpi': 72, 'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144, 'mipmap-xxxhdpi': 192,
}


def draw_icon(size: int, *, background: bool, inset: float = 0.0) -> Image.Image:
    """Renders the mark at `size` px.

    `background` off gives a transparent foreground for Android's adaptive icon; `inset`
    shrinks the mark toward the centre so the adaptive mask cannot clip it.
    """
    px = size * SS
    image = Image.new('RGBA', (px, px), (*BACKGROUND, 255) if background else (0, 0, 0, 0))
    d = ImageDraw.Draw(image)

    scale = (1.0 - inset)
    cx = px / 2

    # --- the strip ---------------------------------------------------------
    strip_w = px * 0.62 * scale
    strip_h = px * 0.86 * scale
    left = cx - strip_w / 2
    right = cx + strip_w / 2
    top = px / 2 - strip_h / 2
    bottom = px / 2 + strip_h / 2

    radius = strip_w * 0.10
    d.rounded_rectangle([left, top, right, bottom], radius=radius, fill=STRIP)

    # --- sprocket holes, both edges ----------------------------------------
    # Punched out to the background rather than drawn dark, so the strip reads as
    # perforated film rather than as a panel with dots on it.
    margin = strip_w * 0.085
    hole_w = strip_w * 0.10
    hole_h = strip_h * 0.052
    hole_r = hole_w * 0.34
    rows = 7
    span = strip_h - hole_h * 2.4
    for i in range(rows):
        y = top + hole_h * 1.2 + span * (i / (rows - 1))
        for x in (left + margin, right - margin - hole_w):
            d.rounded_rectangle(
                [x, y - hole_h / 2, x + hole_w, y + hole_h / 2],
                radius=hole_r,
                fill=SPROCKET if background else (0, 0, 0, 0),
            )

    # --- the credits -------------------------------------------------------
    # Centred lines that shorten and dim as they go up: type receding into the distance
    # is what "rolling credits" looks like in one static frame.
    frame_l = left + margin * 2 + hole_w
    frame_r = right - margin * 2 - hole_w
    frame_w = frame_r - frame_l
    frame_cx = (frame_l + frame_r) / 2

    lines = [
        # (width fraction, y fraction of strip height, opacity)
        (0.34, 0.130, 0.30),
        (0.52, 0.215, 0.48),
        (0.42, 0.300, 0.62),
        (0.68, 0.385, 0.80),
        (0.50, 0.470, 0.92),
        (0.76, 0.555, 1.00),
    ]
    line_h = strip_h * 0.036
    for width_f, y_f, alpha in lines:
        w = frame_w * width_f
        y = top + strip_h * y_f
        d.rounded_rectangle(
            [frame_cx - w / 2, y - line_h / 2, frame_cx + w / 2, y + line_h / 2],
            radius=line_h / 2,
            fill=(*CREDIT, int(255 * alpha)),
        )

    # --- the stinger -------------------------------------------------------
    # After the credits stop: one frame with something still in it. The only amber in
    # the mark, and the only shape that is not a line of type.
    gap_y = top + strip_h * 0.655
    d.rounded_rectangle(
        [frame_l, gap_y, frame_r, gap_y + strip_h * 0.008],
        radius=strip_h * 0.004,
        fill=(*STRIP_EDGE, 255),
    )

    # A bare triangle, not a triangle inside a circle: at 40px the ring around a play
    # mark closes up into a blob and the whole thing reads as a dot.
    tri_h = strip_h * 0.170
    tri_w = tri_h * 0.92
    tri_cy = top + strip_h * 0.800
    d.polygon(
        [
            (frame_cx - tri_w * 0.42, tri_cy - tri_h / 2),
            (frame_cx - tri_w * 0.42, tri_cy + tri_h / 2),
            (frame_cx + tri_w * 0.58, tri_cy),
        ],
        fill=(*ACCENT, 255),
    )

    return image.resize((size, size), Image.LANCZOS)


def main() -> None:
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

    ios_dir = os.path.join(root, 'ios/Runner/Assets.xcassets/AppIcon.appiconset')
    for name, size in IOS_SIZES.items():
        # iOS icons are opaque and un-inset: the system rounds the corners itself, and a
        # transparent pixel in an app icon is a store rejection.
        draw_icon(size, background=True).convert('RGB').save(os.path.join(ios_dir, name))
    print(f'wrote {len(IOS_SIZES)} iOS icons')

    res = os.path.join(root, 'android/app/src/main/res')
    for folder, size in ANDROID_SIZES.items():
        path = os.path.join(res, folder)
        os.makedirs(path, exist_ok=True)
        draw_icon(size, background=True).save(os.path.join(path, 'ic_launcher.png'))
        # The adaptive foreground is drawn at 108dp for a 72dp safe zone: two thirds.
        draw_icon(round(size * 108 / 48), background=False, inset=0.34).save(
            os.path.join(path, 'ic_launcher_foreground.png')
        )
    print(f'wrote {len(ANDROID_SIZES) * 2} Android icons')

    preview = os.path.join(root, 'build', 'app_icon_preview.png')
    os.makedirs(os.path.dirname(preview), exist_ok=True)
    draw_icon(512, background=True).save(preview)
    print(f'preview: {preview}')


if __name__ == '__main__':
    main()
