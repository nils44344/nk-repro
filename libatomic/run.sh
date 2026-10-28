#!/usr/bin/env bash
# Runs the official Node.js Linux binaries (latest 26 and 24, unpacked on the host) inside clean images,
# with nothing installed first, then installs each distro's libatomic package and runs them again.
set -u
N26=$(cat n26.txt); N24=$(cat n24.txt)
images=(
  "debian:bookworm-slim|apt-get update -qq >/dev/null && apt-get install -y -qq libatomic1 >/dev/null"
  "debian:trixie-slim|apt-get update -qq >/dev/null && apt-get install -y -qq libatomic1 >/dev/null"
  "ubuntu:24.04|apt-get update -qq >/dev/null && apt-get install -y -qq libatomic1 >/dev/null"
  "ubuntu:22.04|apt-get update -qq >/dev/null && apt-get install -y -qq libatomic1 >/dev/null"
  "amazonlinux:2023|dnf install -y -q libatomic >/dev/null"
  "fedora:42|dnf install -y -q libatomic >/dev/null"
  "rockylinux:9-minimal|microdnf install -y libatomic >/dev/null"
  "redhat/ubi9-minimal|microdnf install -y libatomic >/dev/null"
  "opensuse/leap:15.6|zypper -q -n install libatomic1 >/dev/null"
  "node:26-bookworm-slim|true"
  "node:26-alpine|true"
)
for row in "${images[@]}"; do
  img=${row%%|*}; fix=${row#*|}
  echo "=================== $img"
  docker run --rm -v "$PWD:/w" -e N26="$N26" -e N24="$N24" "$img" sh -c '
    echo "--- libatomic present before:"; (ls /usr/lib*/libatomic.so.1 /usr/lib/*/libatomic.so.1 /lib*/libatomic.so.1 /lib/*/libatomic.so.1 2>/dev/null || echo none) | head -3
    echo "--- node 26 ($N26):"; /w/$N26/bin/node -v; echo "exit=$?"
    echo "--- npm 26 via PATH:"; PATH=/w/$N26/bin:$PATH npm -v; echo "exit=$?"
    echo "--- node 24 ($N24):"; /w/$N24/bin/node -v; echo "exit=$?"
    if command -v node >/dev/null; then echo "--- image node: $(node -v) at $(command -v node)"; fi
    echo "--- fix: '"$fix"'"; '"$fix"'; echo "fix exit=$?"
    echo "--- node 26 after fix:"; /w/$N26/bin/node -v; echo "exit=$?"
    echo "--- npm 26 after fix:"; PATH=/w/$N26/bin:$PATH npm -v; echo "exit=$?"
  ' 2>&1
done
echo "=================== NEEDED entries"
for n in "$N26" "$N24"; do echo "$n:"; readelf -d "$n/bin/node" | grep NEEDED; done
echo "=================== runner (ubuntu-latest, setup-node not used)"
ldconfig -p | grep libatomic || echo "no libatomic on runner"
echo "=================== nvm in debian:bookworm-slim (curl installed, libatomic not)"
docker run --rm debian:bookworm-slim bash -c '
  apt-get update -qq >/dev/null && apt-get install -y -qq curl ca-certificates >/dev/null
  echo "libatomic after curl install:"; ls /usr/lib/x86_64-linux-gnu/libatomic.so.1 2>/dev/null || echo none
  curl -s -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash >/dev/null 2>&1
  . ~/.nvm/nvm.sh; nvm install 26 2>&1 | tail -4; echo "nvm install exit=$?"; node -v; echo "node exit=$?"
' 2>&1
