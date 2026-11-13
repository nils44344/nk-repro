# puppeteer-libs

Puppeteer 25.17.0 (Chrome 157.0.8103.50) on bare `node:24-bookworm-slim` (Debian 12) and `node:24-trixie-slim` (Debian 13).
Result of run 43463966292 (13 Nov 2026): launch fails with `Code: 127` and an empty stderr; running Chrome by hand prints
`error while loading shared libraries: libglib-2.0.so.0`; `ldd` lists 25 missing libraries; the packages `apt-file` names
(Debian 13 uses `t64` names) fix it and the second launch prints `launched Chrome/157.0.8103.50`.
Also: without `unzip` and `ca-certificates` the install left empty cache folders (`Could not find Chrome`).
Write-up: https://nilaykabariya.blog/fixes/puppeteer-failed-to-launch-browser-process-code-127 (live from its publish date).
