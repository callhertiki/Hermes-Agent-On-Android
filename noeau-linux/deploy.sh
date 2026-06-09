#!/bin/bash
# deploy.sh — Copy the Noeau system files into /home/Cipher/Noeau
# Run this once from inside Kali WSL.
#
# Usage (from the repo root):
#   bash noeau-linux/deploy.sh

set -euo pipefail

NOEAU_ROOT="/home/Cipher/Noeau"
SRC="$(cd "$(dirname "$0")" && pwd)"

echo ""
echo "Deploying Noeau Knowledge System to $NOEAU_ROOT ..."
echo ""

# Ensure the target exists
if [ ! -d "$NOEAU_ROOT" ]; then
    echo "ERROR: $NOEAU_ROOT does not exist."
    echo "  Create it first:  mkdir -p $NOEAU_ROOT"
    exit 1
fi

# Copy files (rsync preferred; cp fallback)
if command -v rsync &>/dev/null; then
    rsync -av --exclude="deploy.sh" "$SRC/" "$NOEAU_ROOT/"
else
    cp -rv "$SRC"/config    "$NOEAU_ROOT/"
    cp -rv "$SRC"/dashboard "$NOEAU_ROOT/"
    cp -rv "$SRC"/scripts   "$NOEAU_ROOT/"
    cp -rv "$SRC"/knowledge "$NOEAU_ROOT/"
    cp -rv "$SRC"/reports   "$NOEAU_ROOT/"
    cp -rv "$SRC"/research  "$NOEAU_ROOT/"
    cp -rv "$SRC"/inbox     "$NOEAU_ROOT/"
fi

# Make scripts executable
chmod +x "$NOEAU_ROOT/scripts/"*.py

echo ""
echo "Done!"
echo ""
echo "Quick test:"
echo "  python3 $NOEAU_ROOT/scripts/noeau_search.py test"
echo "  python3 $NOEAU_ROOT/scripts/noeau_report.py"
echo "  python3 $NOEAU_ROOT/scripts/noeau_pdf_collector.py --list"
echo ""
echo "Optional: install pdfplumber for real PDF text extraction:"
echo "  pip install pdfplumber"
echo ""
