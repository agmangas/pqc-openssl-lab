#!/usr/bin/env bash
set -euo pipefail

echo
echo "OpenSSL"
echo "-------"
openssl version -a | sed -n '1,5p'

echo
echo "KEMs available related to ML-KEM"
echo "--------------------------------"
openssl list -kem-algorithms | grep -E 'ML-KEM|MLKEM|X25519MLKEM|SecP.*MLKEM' || true

echo
echo "Signatures available related to ML-DSA and SLH-DSA"
echo "--------------------------------------------------"
openssl list -signature-algorithms | grep -E 'ML-DSA|MLDSA|SLH-DSA' || true

echo
echo "Takeaway"
echo "--------"
echo "ML-KEM is used to agree keys. ML-DSA and SLH-DSA are used for signatures."
echo "Their presence here means the crypto runtime already knows these algorithms."
