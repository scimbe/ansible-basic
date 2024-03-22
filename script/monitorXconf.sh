#!/bin/bash

# Überprüft, ob der erste Parameter gesetzt und nicht leer ist
if [ -n "$1" ]; then
    # Ausführen des xfconf-query-Befehls mit dem übergebenen Parameter
    xfconf-query -c "$1" -m
else
    # Ausgabe einer Fehlermeldung, wenn kein Parameter übergeben wurde
    echo "Benutzung: $0 <Konfigurationskanal>"
    xfconf-query  -m
fi
