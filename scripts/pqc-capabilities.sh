#!/usr/bin/env bash
set -euo pipefail

echo
echo "OpenSSL"
echo "-------"
openssl version -a | sed -n '1,5p'

echo
echo "KEM disponibles relacionados con ML-KEM"
echo "---------------------------------------"
openssl list -kem-algorithms | grep -E 'ML-KEM|MLKEM|X25519MLKEM|SecP.*MLKEM' || true

echo
echo "Firmas disponibles relacionadas con ML-DSA y SLH-DSA"
echo "----------------------------------------------------"
openssl list -signature-algorithms | grep -E 'ML-DSA|MLDSA|SLH-DSA' || true

echo
echo "Lectura"
echo "-------"
echo "ML-KEM se usa para acordar claves. ML-DSA y SLH-DSA se usan para firmas."
echo "Que aparezcan aquí significa que el runtime criptográfico ya conoce estos algoritmos."
