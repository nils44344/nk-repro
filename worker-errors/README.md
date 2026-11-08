# Error 1101 causes and Error 1102 (CPU limit), 8 Nov 2026

`worker.js` + `wrangler.toml` (limits.cpu_ms = 10 on Workers Paid, to match the Free plan), deployed with wrangler 4.158.0.

- `curl.txt`, `tail-1101.txt`: the six 1101 routes and three Date.now() busy-wait routes (outcome, CPU time, exception from `wrangler tail --format json`).
- `curl-loop.txt`, `tail-loop.txt`: a counted loop at growing sizes, one request every ~2 s, and `/now` (Date.now() before/after a long loop).
- `wait.txt`: scheduler.wait and setTimeout.

Raw tail JSON is not published (it contains request headers).
