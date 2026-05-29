"""
Tend Pets — Derive 7 iOS icon sizes from the 1024×1024 source icon.

Final icon (1024×1024 RGB no-alpha PNG) is generated via ChatGPT (gpt-image-2)
using one of the 4 prompts in `ios-app/AppStore/app-icon-prompts.md`.
This script derives all 7 auxiliary sizes Apple iOS asset catalog requires
so they stay visually consistent (single source of truth).

Mirrorbite pattern: `apps/mirrorbite/store/derive-assets-from-icon.py`.
Adapted for SwiftUI native iOS (no Android / no Expo splash needed).

Run:
    cd REDACTED-PATH/generated/pet-med-care-tracker/store
    python derive-assets-from-icon.py

Output (overwrites existing):
    ../ios-app/TendPets/Resources/Assets.xcassets/AppIcon.appiconset/
        AppIcon-40.png   (20pt @2x)
        AppIcon-58.png   (29pt @2x)
        AppIcon-60.png   (20pt @3x)
        AppIcon-80.png   (40pt @2x)
        AppIcon-87.png   (29pt @3x)
        AppIcon-120.png  (40pt @3x, 60pt @2x)
        AppIcon-180.png  (60pt @3x)
        (AppIcon-1024.png is the source, not regenerated)

Requirements:
- Source AppIcon-1024.png must exist
- Pillow (PIL): `pip install Pillow`

Apple requirements honored:
- RGB color mode (no alpha channel) — flatten if needed
- LANCZOS resampling for best downscale quality
- PNG format with optimize=True for smaller bundle
"""

from PIL import Image
import os
import sys

THIS_DIR = os.path.dirname(os.path.abspath(__file__))
ICON_DIR = os.path.normpath(os.path.join(
    THIS_DIR,
    '..',
    'ios-app',
    'TendPets',
    'Resources',
    'Assets.xcassets',
    'AppIcon.appiconset',
))
SOURCE_ICON = os.path.join(ICON_DIR, 'AppIcon-1024.png')

# Apple App Store / iOS asset catalog requirements for iPhone
# (taken from project.yml Contents.json)
SIZES = [
    (40, 'AppIcon-40.png'),    # 20pt @2x (Notification)
    (58, 'AppIcon-58.png'),    # 29pt @2x (Settings)
    (60, 'AppIcon-60.png'),    # 20pt @3x (Notification)
    (80, 'AppIcon-80.png'),    # 40pt @2x (Spotlight)
    (87, 'AppIcon-87.png'),    # 29pt @3x (Settings)
    (120, 'AppIcon-120.png'),  # 40pt @3x (Spotlight) + 60pt @2x (App)
    (180, 'AppIcon-180.png'),  # 60pt @3x (App)
]


def flatten_alpha(img):
    """Apple requires icons WITHOUT alpha channel. Flatten transparent pixels
    against pure white to be safe.
    """
    if img.mode == 'RGBA':
        background = Image.new('RGB', img.size, (255, 255, 255))
        background.paste(img, mask=img.split()[3])
        return background
    return img.convert('RGB')


def main():
    if not os.path.exists(SOURCE_ICON):
        sys.stderr.write(
            f"ERROR: source icon not found: {SOURCE_ICON}\n"
            "  Generate AppIcon-1024.png with ChatGPT (gpt-image-2) using one of\n"
            "  the 4 prompts in ios-app/AppStore/app-icon-prompts.md, then re-run.\n"
        )
        sys.exit(1)

    source = Image.open(SOURCE_ICON)
    print(f"Source: {SOURCE_ICON}")
    print(f"        size={source.size}, mode={source.mode}")

    # Ensure source itself is RGB no-alpha (Apple requirement)
    flat_source = flatten_alpha(source)
    if flat_source.mode != source.mode or flat_source.size != source.size:
        flat_source.save(SOURCE_ICON, 'PNG', optimize=True)
        print(f"  -> source re-saved as RGB no-alpha PNG")

    # Generate derived sizes
    print()
    print("Generating 7 derived sizes:")
    for size_px, filename in SIZES:
        out_path = os.path.join(ICON_DIR, filename)
        resized = flat_source.resize((size_px, size_px), Image.LANCZOS)
        resized.save(out_path, 'PNG', optimize=True)
        bytes_out = os.path.getsize(out_path)
        print(f"  {filename:24s}  {size_px:>4d}x{size_px:<4d}  {bytes_out:>6d} B")

    print()
    print("All 7 derived icon sizes regenerated from AppIcon-1024.png source.")
    print("Next step: open Xcode (or Codemagic build) and verify icon renders on")
    print("iPhone home screen, Spotlight, Settings, and App Store preview.")


if __name__ == '__main__':
    main()
