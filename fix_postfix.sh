#!/bin/bash

# Skript pro opravu Postfix konfigurace
# Použití: ./fix_postfix.sh [--output-dir OUTPUT_DIR]

# Výchozí hodnoty
OUTPUT_DIR="/tmp"

# Funkce pro zobrazení nápovědy
show_help() {
    echo "Skript pro opravu Postfix konfigurace"
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

OUTPUT_FILE="$OUTPUT_DIR/fix_output.txt"
ERROR_FILE="$OUTPUT_DIR/fix_errors.txt"

echo "=== Oprava Postfix konfigurace ===" > "$OUTPUT_FILE"
echo "=== Chyby ===" > "$ERROR_FILE"

echo "1. Záloha původní konfigurace..." >> "$OUTPUT_FILE"
sudo cp /etc/postfix/main.cf /etc/postfix/main.cf.backup.$(date +%Y%m%d_%H%M%S) 2>> "$ERROR_FILE"
if [ $? -eq 0 ]; then
    echo "   ✓ Záloha vytvořena" >> "$OUTPUT_FILE"
else
    echo "   ✗ Chyba při vytváření zálohy" >> "$OUTPUT_FILE"
fi

echo "" >> "$OUTPUT_FILE"
echo "2. Oprava duplikované konfigurace certifikátu..." >> "$OUTPUT_FILE"

# Oprava řádku 30 - změna smtpd_tls_cert_file na smtpd_tls_key_file
sudo sed -i '30s/smtpd_tls_cert_file=/smtpd_tls_key_file=/' /etc/postfix/main.cf 2>> "$ERROR_FILE"
if [ $? -eq 0 ]; then
    echo "   ✓ Změna cert_file na key_file" >> "$OUTPUT_FILE"
else
    echo "   ✗ Chyba při změně cert_file na key_file" >> "$OUTPUT_FILE"
fi

# Oprava cesty k privátnímu klíči
sudo sed -i '30s/cert\.pem/privkey.pem/' /etc/postfix/main.cf 2>> "$ERROR_FILE"
if [ $? -eq 0 ]; then
    echo "   ✓ Změna cert.pem na privkey.pem" >> "$OUTPUT_FILE"
else
    echo "   ✗ Chyba při změně cert.pem na privkey.pem" >> "$OUTPUT_FILE"
fi

echo "" >> "$OUTPUT_FILE"
echo "3. Ověření změn..." >> "$OUTPUT_FILE"
echo "Řádky 28-32 po úpravě:" >> "$OUTPUT_FILE"
sed -n '28,32p' /etc/postfix/main.cf >> "$OUTPUT_FILE" 2>> "$ERROR_FILE"

echo "" >> "$OUTPUT_FILE"
echo "4. Test konfigurace Postfix..." >> "$OUTPUT_FILE"
sudo postfix check 2>> "$ERROR_FILE"
if [ $? -eq 0 ]; then
    echo "   ✓ Konfigurace je v pořádku" >> "$OUTPUT_FILE"
else
    echo "   ✗ Chyba v konfiguraci" >> "$OUTPUT_FILE"
fi

echo "" >> "$OUTPUT_FILE"
echo "5. Reload Postfix..." >> "$OUTPUT_FILE"
sudo systemctl reload postfix 2>> "$ERROR_FILE"
if [ $? -eq 0 ]; then
    echo "   ✓ Postfix reload úspěšný" >> "$OUTPUT_FILE"
else
    echo "   ✗ Chyba při reload Postfix" >> "$OUTPUT_FILE"
fi

echo "" >> "$OUTPUT_FILE"
echo "=== HOTOVO ===" >> "$OUTPUT_FILE"
echo "Datum: $(date)" >> "$OUTPUT_FILE"

echo "Skript dokončen. Výsledky:"
echo "- Výstup: $OUTPUT_FILE"
echo "- Chyby: $ERROR_FILE"