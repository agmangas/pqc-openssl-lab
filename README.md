# PQC OpenSSL Lab

A small Docker image to explore post-quantum cryptography (**PQC**) running inside OpenSSL 3.5 LTS.

It is meant for teaching that PQC is no longer theoretical—it is available in production-grade stacks. The image supports the `Casos de uso` session lab in a quantum computing micro-credential. The goal is not to master OpenSSL, but to build familiarity with how PQC shows up in real tooling.

The full classroom guide (questions and discussion) is in [LAB.md](LAB.md).

## What is inside

The image is built in two stages (see [Dockerfile](Dockerfile)): the first compiles OpenSSL from source; the second keeps only the binaries so the final image does not ship a compiler.

The build pins OpenSSL `3.5.6`, the first LTS line with built-in post-quantum algorithms (**ML-KEM**, **ML-DSA**, **SLH-DSA**).

| Algorithm   | Role                        | Notes                                                                                                                                                                                                 |
| :---------- | :-------------------------- | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **ML-KEM**  | Key encapsulation mechanism | Lattice KEM used to establish shared symmetric keys over public networks; in TLS 1.3 it contributes to the handshake key schedule (alongside classical groups such as ECDH), not to application data. |
| **ML-DSA**  | Digital signatures          | Lattice-based signatures; NIST’s primary PQC signature recommendation for authenticating identities and documents.                                                                                    |
| **SLH-DSA** | Digital signatures          | Hash-based conservative backup signatures if lattice schemes are ever weakened.                                                                                                                       |

## Usage

The usual entry point is an interactive container run, which opens a menu:

```
docker run --rm -it ghcr.io/agmangas/pqc-openssl-lab:main
```

```
PQC OpenSSL Lab
================
1. View OpenSSL PQC capabilities
2. Compare classical vs hybrid PQC TLS
3. Compare signature sizes
4. Exit

Choose an option [1-4]:
```

Each menu item runs a script. You can skip the menu and pass a script name as the container argument:

```
docker run --rm ghcr.io/agmangas/pqc-openssl-lab:2026-06 pqc-capabilities.sh
docker run --rm ghcr.io/agmangas/pqc-openssl-lab:2026-06 pqc-tls-demo.sh
docker run --rm ghcr.io/agmangas/pqc-openssl-lab:2026-06 pqc-signatures-demo.sh
```

## The three demos

Each demo answers one concrete question.

| Script                   | Question it answers                                                      |
| ------------------------ | ------------------------------------------------------------------------ |
| `pqc-capabilities.sh`    | Does this OpenSSL build expose post-quantum algorithms?                  |
| `pqc-tls-demo.sh`        | What changes in a TLS 1.3 handshake between classical and hybrid groups? |
| `pqc-signatures-demo.sh` | How much larger are post-quantum signatures?                             |

### Capabilities

`pqc-capabilities.sh` lists what OpenSSL knows about: KEMs related to ML-KEM and signature algorithms related to ML-DSA and SLH-DSA. Presence in the list only means the crypto provider implements them—it does not mean your traffic is already post-quantum.

### Classical TLS vs hybrid TLS

`pqc-tls-demo.sh` runs two local TLS 1.3 handshakes against `openssl s_server`. The server certificate and the negotiated **TLS 1.3 cipher suite** for record protection stay the same. Only the **key exchange group** changes:

| Key exchange group | What it represents                              |
| ------------------ | ----------------------------------------------- |
| `X25519`           | Classical elliptic-curve Diffie–Hellman (ECDHE) |
| `X25519MLKEM768`   | Hybrid group: X25519 combined with ML-KEM-768   |

In the hybrid run, client output should include `Negotiated TLS1.3 group: X25519MLKEM768`. The takeaway: PQC affects **key establishment in the handshake** (the shared secret fed into the TLS 1.3 key schedule), not the plaintext application protocol on the wire.

### Signature sizes

`pqc-signatures-demo.sh` signs the same message with three algorithms and compares public key and signature sizes:

| Category         | Algorithm           |
| ---------------- | ------------------- |
| Classical        | `Ed25519`           |
| PQC (lattice)    | `ML-DSA-65`         |
| PQC (hash-based) | `SLH-DSA-SHA2-128s` |

> Exact byte counts can vary by machine, but the pattern holds: post-quantum signatures jump from tens of bytes to kilobytes. That shows up in certificates, handshake messages, storage, and observability pipelines.

## Local build

To build the image yourself instead of pulling from the registry:

```
docker build -t pqc-openssl-lab:local .
docker run --rm -it pqc-openssl-lab:local
```

Override the OpenSSL version at build time with `--build-arg OPENSSL_VERSION=3.5.6`.

## Publishing

The workflow `.github/workflows/publish.yml` publishes to GitHub Container Registry:

```
ghcr.io/agmangas/pqc-openssl-lab
```

Expected teaching tags:

| Tag           | Purpose                        |
| ------------- | ------------------------------ |
| `openssl-3.5` | Tracks the LTS line            |
| `2026-06`     | Pins a specific course edition |
