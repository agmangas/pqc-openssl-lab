#!/usr/bin/env bash
set -euo pipefail

workdir="$(mktemp -d)"
server_pid=""

cleanup() {
	if [[ -n "$server_pid" ]]; then
		kill "$server_pid" >/dev/null 2>&1 || true
		wait "$server_pid" >/dev/null 2>&1 || true
	fi
	rm -rf "$workdir"
}
trap cleanup EXIT

openssl req \
	-x509 \
	-newkey rsa:2048 \
	-keyout "$workdir/key.pem" \
	-out "$workdir/cert.pem" \
	-sha256 \
	-days 1 \
	-nodes \
	-subj /CN=localhost \
	>/dev/null 2>&1

run_case() {
	local label="$1"
	local group="$2"
	local port="$3"
	local output="$workdir/client-${group}.log"

	openssl s_server \
		-quiet \
		-tls1_3 \
		-accept "$port" \
		-cert "$workdir/cert.pem" \
		-key "$workdir/key.pem" \
		-groups "$group" \
		>"$workdir/server-${group}.log" 2>&1 &
	server_pid="$!"

	sleep 1

	openssl s_client \
		-connect "127.0.0.1:${port}" \
		-tls1_3 \
		-groups "$group" \
		-msg \
		</dev/null \
		>"$output" 2>&1 || true

	kill "$server_pid" >/dev/null 2>&1 || true
	wait "$server_pid" >/dev/null 2>&1 || true
	server_pid=""

	local tls_summary
	local negotiated
	local client_hello

	tls_summary="$(grep -m1 'New, TLS' "$output" | sed 's/^ *//' || true)"
	negotiated="$(grep -m1 'Negotiated TLS1.3 group' "$output" | sed 's/^ *//' || true)"
	client_hello="$(awk '/Handshake \[length .*ClientHello/ { sub(/^ */, ""); print; exit }' "$output" || true)"

	printf '\n%s\n' "$label"
	printf '%s\n' "$(printf '%*s' "${#label}" '' | tr ' ' '-')"
	printf 'Group requested:           %s\n' "$group"
	printf 'TLS/cipher suite:          %s\n' "${tls_summary:-not found}"
	printf 'Negotiated TLS group:      %s\n' "${negotiated:-not shown for this group}"
	printf 'ClientHello size:          %s\n' "${client_hello:-not found}"
}

echo
echo "TLS 1.3 comparison"
echo "=================="
echo "The certificate is the same in both cases. We change only the key exchange group."

run_case "Case A: classical" "X25519" "9443"
run_case "Case B: hybrid PQC" "X25519MLKEM768" "9444"

echo
echo "Takeaway"
echo "--------"
echo "In the hybrid case, X25519MLKEM768 should appear as the negotiated TLS group."
echo "The data cipher suite can stay the same: here PQC affects the handshake, not the HTTP content."
