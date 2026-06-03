#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" != "" ]]; then
	exec "$@"
fi

while true; do
	cat <<'MENU'

PQC OpenSSL Lab
================
1. Ver capacidades PQC de OpenSSL
2. Comparar TLS clásico vs TLS híbrido PQC
3. Comparar tamaños de firmas
4. Salir

MENU
	read -r -p "Elige una opción [1-4]: " choice

	case "$choice" in
	1) pqc-capabilities.sh ;;
	2) pqc-tls-demo.sh ;;
	3) pqc-signatures-demo.sh ;;
	4) exit 0 ;;
	*) echo "Opción no válida." ;;
	esac
done
