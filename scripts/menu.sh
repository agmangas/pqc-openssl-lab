#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" != "" ]]; then
	exec "$@"
fi

while true; do
	cat <<'MENU'

PQC OpenSSL Lab
================
1. View OpenSSL PQC capabilities
2. Compare classical vs hybrid PQC TLS
3. Compare signature sizes
4. Exit

MENU
	read -r -p "Choose an option [1-4]: " choice

	case "$choice" in
	1) pqc-capabilities.sh ;;
	2) pqc-tls-demo.sh ;;
	3) pqc-signatures-demo.sh ;;
	4) exit 0 ;;
	*) echo "Invalid option." ;;
	esac
done
