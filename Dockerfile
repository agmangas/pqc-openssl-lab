# ─────────────────────────────────────────────────────────────────────────────
# STAGE 1: "build" — compile OpenSSL from source
#
# This is a multi-stage build. This first stage installs a full compiler
# toolchain and builds OpenSSL, producing binaries in /opt/openssl. None of the
# heavy build tools end up in the final image — only the compiled output is
# copied forward (see the COPY --from=build line below). This keeps the runtime
# image small.
# ─────────────────────────────────────────────────────────────────────────────
FROM debian:bookworm-slim AS build

# The OpenSSL version to build. We target 3.5.x because it is the first LTS
# release to ship post-quantum algorithms (ML-KEM, ML-DSA) built in — no
# external provider needed. ARG lets you override it at build time:
#   docker build --build-arg OPENSSL_VERSION=3.5.6 .
ARG OPENSSL_VERSION=3.5.6

# Install the tools needed to download and compile OpenSSL.
# --no-install-recommends keeps the install lean, and we delete the apt cache
# afterwards so it doesn't bloat this layer.
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
  ca-certificates \
  build-essential \
  perl \
  wget \
  && rm -rf /var/lib/apt/lists/*

# A scratch directory to download and unpack the source into.
WORKDIR /tmp/build

# Download, configure, compile, and install OpenSSL — all in one RUN so the
# intermediate files share a single layer (which is then discarded with the
# whole build stage anyway).
#
# Configure flags worth knowing:
#   --prefix         where the final files are installed
#   --openssldir     where OpenSSL looks for its config and certs at runtime
#   no-shared        build static binaries (no .so files) so the runtime image
#                    needs no extra shared libraries to copy or resolve
#   no-tests         skip building the test suite to speed up the build
#
# make -j"$(nproc)" compiles in parallel using all available CPU cores.
# make install_sw installs just the software (binaries + libs), skipping docs.
RUN wget -O openssl.tar.gz "https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz" \
  && tar -xzf openssl.tar.gz \
  && cd "openssl-${OPENSSL_VERSION}" \
  && ./config \
  --prefix=/opt/openssl \
  --openssldir=/opt/openssl/ssl \
  no-shared \
  no-tests \
  && make -j"$(nproc)" \
  && make install_sw

# ─────────────────────────────────────────────────────────────────────────────
# STAGE 2: final runtime image
#
# Starts fresh from a clean Debian base — none of the build tools above are
# present here. We copy in the compiled OpenSSL plus our lab scripts.
# ─────────────────────────────────────────────────────────────────────────────
FROM debian:bookworm-slim

# Re-declared because each build stage gets its own set of ARGs. We use it below
# to stamp the version into an image label and an environment variable.
ARG OPENSSL_VERSION=3.5.6

# OCI image labels — standardized metadata shown by `docker inspect` and
# registries. Purely informational; they don't affect how the image runs.
LABEL org.opencontainers.image.title="PQC OpenSSL Lab"
LABEL org.opencontainers.image.description="Small teaching image for TLS 1.3 hybrid PQC demos with OpenSSL 3.5 LTS."
LABEL org.opencontainers.image.source="https://github.com/agmangas/pqc-openssl-lab"
LABEL org.opencontainers.image.version="${OPENSSL_VERSION}"

# Runtime dependencies for the lab scripts (NOT for building OpenSSL).
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
  ca-certificates \
  coreutils \
  grep \
  procps \
  && rm -rf /var/lib/apt/lists/*

# Pull the compiled OpenSSL from the build stage, then add the lab's scripts and
# the custom OpenSSL config that enables the PQC demos.
COPY --from=build /opt/openssl /opt/openssl
COPY scripts/ /usr/local/bin/
COPY config/openssl.cnf /opt/openssl/ssl/openssl.cnf

# Environment setup so our freshly built OpenSSL is the one that gets used:
#   PATH             puts /opt/openssl/bin first, so `openssl` = our 3.5 build,
#                    not any system version
#   OPENSSL_MODULES  where OpenSSL loads provider modules from
#   OPENSSL_VERSION  exposed to the scripts so they can display/branch on it
ENV PATH="/opt/openssl/bin:${PATH}"
ENV OPENSSL_MODULES="/opt/openssl/lib/ossl-modules"
ENV OPENSSL_VERSION="${OPENSSL_VERSION}"

# Make the lab scripts executable, and run `openssl version` as a build-time
# smoke test — if the binary is broken or missing, the build fails right here
# instead of at container startup.
RUN chmod +x /usr/local/bin/*.sh && openssl version

# When the container starts, drop the user straight into the lab's interactive
# menu rather than a bare shell.
ENTRYPOINT ["/usr/local/bin/menu.sh"]
