"""
Letterbox iPhone Simulator screenshots to ASC 6.5" Display (1242x2688).

Wrapper around REDACTED-PATH/scripts/letterbox-asc-screenshots.py.
Use when the user captures screenshots from iPhone 16 Pro Simulator
(1206x2622) or iPhone 16 (1320x2868) — both larger than 6.5" — and needs
to downscale + pad to the canonical 1242x2688 ASC accepts.

If the user captures from a real iPhone 16 Pro Max (1320x2868), Apple ASC
accepts that natively — no letterbox needed. Use directly with
asc-upload-screenshots.py.

Usage:
  python scripts/letterbox-screenshots.py screenshots/raw/*.png
"""
import sys
from pathlib import Path

# Reuse the workspace-level letterboxer (same logic, already proven by Mirrorbite).
WORKSPACE_SCRIPT = Path(r"REDACTED-PATH\scripts\letterbox-asc-screenshots.py")
if not WORKSPACE_SCRIPT.exists():
    sys.stderr.write(f"ERROR: workspace letterboxer not found at {WORKSPACE_SCRIPT}\n")
    sys.exit(1)

import subprocess
sys.exit(subprocess.call(["python", str(WORKSPACE_SCRIPT), *sys.argv[1:]]))
