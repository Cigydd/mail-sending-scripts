#!/bin/bash

# Skript pro opravu cesty k privátnímu klíči
# Použití: ./fix_key_path.sh [--output-dir OUTPUT_DIR]

# Výchozí hodnoty
OUTPUT_DIR="/tmp"

# Funkce pro zobrazení nápovědy
show_help() {
    echo "Skript pro opravu cesty k privátnímu klíči v Postfix konfiguraci"
    echo ""
    echo "Použití: $0 [PARAMETRY]"
    echo ""
    echo "Parametry:"
    echo "  -o, --output-dir DIR     Adresář pro výstupní soubory (výchozí: /tmp)"
    echo "  -h, --help              Zobrazí tuto nápovědu"
    echo ""
    echo "Příklady:"
    echo "  $0"
    echo "  $0 --output-dir /var/log/mail-fixes"
}

# Zpracování parametrů
while [[ $# -gt 0 ]]; do
    case $1 in
        -o|--output-dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Neznámý parametr: $1" >&2
            echo "Použijte --help pro nápovědu." >&2
            exit 1
            ;;
    esac
done

# Validace parametrů
if [[ ! -d "$OUTPUT_DIR" ]]; then
    echo "Chyba: Adresář '$OUTPUT_DIR' neexistuje" >&2
    exit 1
fi

OUTPUT_FILE="$OUTPUT_DIR/fix_key_output.txt"

echo "=== Oprava cesty k privátnímu klíči ===" > "$OUTPUT_FILE"

echo "Před úpravou:" >> "$OUTPUT_FILE"
grep "smtpd_tls_key_file" /etc/postfix/main.cf >> "$OUTPUT_FILE"

sudo sed -i 's|key\.pem|privkey.pem|' /etc/postfix/main.cf

echo "Po úpravě:" >> "$OUTPUT_FILE"
grep "smtpd_tls_key_file" /etc/postfix/main.cf >> "$OUTPUT_FILE"

sudo postfix check && sudo systemctl reload postfix
echo "Status: $?" >> "$OUTPUT_FILE"

echo "Hotovo: $(date)" >> "$OUTPUT_FILE"

echo "Skript dokončen. Výsledky v: $OUTPUT_FILE"