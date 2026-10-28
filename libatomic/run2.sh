#!/usr/bin/env bash
# Second pass: nvm install, multi-stage COPY of node from the official image, distroless, and the fix for each.
set -u
echo "=================== arch: $(uname -m)"
echo "=================== nvm in debian:bookworm-slim (curl installed, libatomic not)"
docker run --rm debian:bookworm-slim bash -c '
  apt-get update -qq >/dev/null && apt-get install -y -qq curl ca-certificates >/dev/null 2>&1
  ls /usr/lib/*/libatomic.so.1 2>/dev/null || echo "libatomic: none"
  curl -s -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash >/dev/null 2>&1
  . ~/.nvm/nvm.sh; nvm install 26 >/tmp/nvm.log 2>&1; echo "nvm install exit=$?"; tail -3 /tmp/nvm.log
  node -v; echo "node exit=$?"; npm -v; echo "npm exit=$?"
  apt-get install -y -qq libatomic1 >/dev/null 2>&1; node -v; echo "after fix exit=$?"
' 2>&1
mkdir -p ms && cd ms
build() { echo "=================== $1"; printf '%s\n' "$2" | sed "s/@ARCH@/$(uname -m)/g" > Dockerfile; docker build -q -t t . >/dev/null 2>build.log || { tail -3 build.log; return; }; docker run --rm t; echo "run exit=$?"; }
build "COPY node from node:26 into debian:bookworm-slim" 'FROM node:26-bookworm-slim AS n
FROM debian:bookworm-slim
COPY --from=n /usr/local/bin/node /usr/local/bin/node
CMD ["node","-v"]'
build "same + COPY libatomic.so.1 from the node stage" 'FROM node:26-bookworm-slim AS n
FROM debian:bookworm-slim
COPY --from=n /usr/local/bin/node /usr/local/bin/node
COPY --from=n /usr/lib/@ARCH@-linux-gnu/libatomic.so.1 /usr/lib/@ARCH@-linux-gnu/
CMD ["node","-v"]'
build "same + apt-get install libatomic1" 'FROM node:26-bookworm-slim AS n
FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends libatomic1 && rm -rf /var/lib/apt/lists/*
COPY --from=n /usr/local/bin/node /usr/local/bin/node
CMD ["node","-v"]'
build "COPY node into gcr.io/distroless/cc-debian12" 'FROM node:26-bookworm-slim AS n
FROM gcr.io/distroless/cc-debian12
COPY --from=n /usr/local/bin/node /usr/local/bin/node
CMD ["/usr/local/bin/node","-v"]'
build "distroless/cc + COPY libatomic.so.1" 'FROM node:26-bookworm-slim AS n
FROM gcr.io/distroless/cc-debian12
COPY --from=n /usr/local/bin/node /usr/local/bin/node
COPY --from=n /usr/lib/@ARCH@-linux-gnu/libatomic.so.1 /usr/lib/@ARCH@-linux-gnu/
CMD ["/usr/local/bin/node","-v"]'
build "COPY node from node:24 into debian:bookworm-slim (control)" 'FROM node:24-bookworm-slim AS n
FROM debian:bookworm-slim
COPY --from=n /usr/local/bin/node /usr/local/bin/node
CMD ["node","-v"]'
build "gcr.io/distroless/nodejs26-debian12" 'FROM gcr.io/distroless/nodejs26-debian12
CMD ["-v"]'
