#!/bin/bash

echo "=== Úklid výstupních souborů ==="

# Vytvoření složky pro archivaci
ARCHIVE_DIR="archive_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$ARCHIVE_DIR"

# Přesun všech výstupních souborů do archivu
echo "Přesunuji výstupní soubory do $ARCHIVE_DIR/..."
mv *_output.txt "$ARCHIVE_DIR/" 2>/dev/null
mv fix_errors.txt "$ARCHIVE_DIR/" 2>/dev/null

# Počet přesunutých souborů
COUNT=$(ls -1 "$ARCHIVE_DIR" | wc -l)
echo "Přesunuto $COUNT souborů"

# Zobrazení zbývajících souborů
echo ""
echo "Zbývající soubory (skripty a dokumentace):"
ls -1 *.sh *.md 2>/dev/null | nl

echo ""
echo "Úklid dokončen!"