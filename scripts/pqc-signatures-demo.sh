#!/usr/bin/env bash
set -euo pipefail

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

printf 'test message for PQC\n' >"$workdir/message.txt"

make_signature() {
	local label="$1"
	local algorithm="$2"
	local stem="$3"

	openssl genpkey -algorithm "$algorithm" -out "$workdir/${stem}.key" >/dev/null 2>&1
	openssl pkey -in "$workdir/${stem}.key" -pubout -out "$workdir/${stem}.pub" >/dev/null 2>&1
	openssl pkeyutl -sign -inkey "$workdir/${stem}.key" -rawin -in "$workdir/message.txt" -out "$workdir/${stem}.sig" >/dev/null 2>&1
	openssl pkeyutl -verify -pubin -inkey "$workdir/${stem}.pub" -rawin -in "$workdir/message.txt" -sigfile "$workdir/${stem}.sig" >/dev/null 2>&1

	local pub_size
	local sig_size
	pub_size="$(wc -c <"$workdir/${stem}.pub" | tr -d ' ')"
	sig_size="$(wc -c <"$workdir/${stem}.sig" | tr -d ' ')"

	printf '%-22s %-24s %10s %12s\n' "$label" "$algorithm" "$pub_size" "$sig_size"
}

echo
echo "Signature comparison"
echo "===================="
printf '%-22s %-24s %10s %12s\n' "Type" "Algorithm" "Public" "Signature"
printf '%-22s %-24s %10s %12s\n' "----" "---------" "------" "---------"

make_signature "Modern classical" "ED25519" "ed25519"
make_signature "PQC lattice" "ML-DSA-65" "mldsa65"
make_signature "PQC hash-based" "SLH-DSA-SHA2-128s" "slhdsa"

echo
echo "Takeaway"
echo "--------"
echo "PQC signatures can take up several kilobytes. That affects certificates, handshakes,"
echo "storage, compatibility and observability."
