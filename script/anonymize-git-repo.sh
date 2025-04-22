#!/bin/bash
# Git-Repository Anonymisierung
# Dieses Skript checkt ein Repository mit allen Submodulen aus,
# anonymisiert es und erstellt ein tar.gz-Archiv ohne Verlauf

set -e  # Script beenden bei Fehlern

# Funktion zur Fehlerausgabe
error_exit() {
    echo "FEHLER: $1" >&2
    exit 1
}

# Funktion zum Überprüfen von erforderlichen Programmen
check_requirements() {
    local required_tools=("git" "tar" "find" "sed")
    for tool in "${required_tools[@]}"; do
        if ! command -v $tool &> /dev/null; then
            error_exit "$tool wird benötigt, ist aber nicht installiert."
        fi
    done
}

# Parameter überprüfen
if [ "$#" -lt 2 ]; then
    echo "Verwendung: $0 <Git-Repository-URL> <Output-Archiv-Name> [Temporäres Verzeichnis]"
    echo "Beispiel: $0 https://github.com/example/repo.git anonymized-repo /tmp/work"
    exit 1
fi

REPO_URL="$1"
OUTPUT_ARCHIVE="$2"
TEMP_DIR="${3:-/tmp/git-anonymize-$(date +%s)}"
REPO_DIR="$TEMP_DIR/repo"
ANON_DIR="$TEMP_DIR/anonymized"

# Erforderliche Tools überprüfen
check_requirements

echo "=== Git-Repository-Anonymisierung ==="
echo "Repository: $REPO_URL"
echo "Ausgabe-Archiv: $OUTPUT_ARCHIVE"
echo "Temporäres Verzeichnis: $TEMP_DIR"

# Temporäre Verzeichnisse erstellen
mkdir -p "$REPO_DIR" "$ANON_DIR"

# Repository auschecken mit allen Branches und Submodulen
echo "Klone das Repository mit allen Branches..."
git clone --mirror "$REPO_URL" "$REPO_DIR/.git"
cd "$REPO_DIR"
git config --local --bool core.bare false
git checkout

# Liste aller Branches holen
branches=$(git branch -r | grep -v HEAD | sed 's/origin\///')
echo "Gefundene Branches: $branches"

# Submodule initialisieren und aktualisieren
echo "Initialisiere und aktualisiere alle Submodule rekursiv..."
git submodule update --init --recursive

# Anonymisiertes Repository vorbereiten
echo "Bereite anonymisiertes Repository vor..."
mkdir -p "$ANON_DIR"

# Alle Dateien kopieren (ohne .git Verzeichnisse)
echo "Kopiere Dateien (ohne .git Verzeichnisse)..."
find "$REPO_DIR" -type f -not -path "*/\.git/*" -not -path "*/\.git" | while read file; do
    rel_path="${file#$REPO_DIR/}"
    target_file="$ANON_DIR/$rel_path"
    mkdir -p "$(dirname "$target_file")"
    cp "$file" "$target_file"
done

# Für jeden Branch ein Verzeichnis anlegen
echo "Erstelle Verzeichnisse für alle Branches..."
for branch in $branches; do
    # Branch wechseln und Verzeichnis erstellen
    cd "$REPO_DIR"
    git checkout "$branch"
    branch_dir="$ANON_DIR/branches/$branch"
    mkdir -p "$branch_dir"
    
    # Dateien für diesen Branch kopieren (ohne .git)
    find "$REPO_DIR" -type f -not -path "*/\.git/*" -not -path "*/\.git" | while read file; do
        rel_path="${file#$REPO_DIR/}"
        target_file="$branch_dir/$rel_path"
        mkdir -p "$(dirname "$target_file")"
        cp "$file" "$target_file"
    done
    
    echo "Branch $branch wurde kopiert."
done

# README zum anonymisierten Repository hinzufügen
cat > "$ANON_DIR/README_ANONYMOUS_REPO.md" << EOF
# Anonymisiertes Repository

Dieses Repository wurde anonymisiert und enthält keine Git-Historie oder persönlichen Daten.

## Verfügbare Branches

Alle Branches befinden sich im Verzeichnis \`branches/\`:

$(for branch in $branches; do echo "- $branch"; done)

## Verwendung

Jeder Branch enthält den kompletten Code-Stand ohne Git-Verlauf.
EOF

# Archiv erstellen
echo "Erstelle Archiv $OUTPUT_ARCHIVE..."
cd "$TEMP_DIR"
tar -czf "$OUTPUT_ARCHIVE" -C "$TEMP_DIR" "anonymized"

# Aufräumen
echo "Räume temporäre Dateien auf..."
rm -rf "$TEMP_DIR"

echo "=== Anonymisierung abgeschlossen ==="
echo "Anonymisiertes Repository wurde erstellt: $OUTPUT_ARCHIVE"
