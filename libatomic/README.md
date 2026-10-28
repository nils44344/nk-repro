# node: error while loading shared libraries: libatomic.so.1

Since Node 25, the official Linux binaries link against libatomic. Clean minimal images don't have it.

- `run.sh` (workflow `libatomic.yml`): official Node 26.12.1 and 24.22.1 tarballs in 9 clean distro images + official node images, before and after installing each distro's libatomic package. Output: `out-images-x64.txt`.
- `run2.sh` (workflow `libatomic2.yml`, x64 + arm64): nvm install 26, multi-stage `COPY --from=node:26`, distroless/cc, and the fixes. Output: `out-docker-nvm-*.txt`.

Run on GitHub Actions, October 28, 2026.

Post: https://nilaykabariya.blog/fixes/node-26-libatomic-so-1-cannot-open-shared-object-file
