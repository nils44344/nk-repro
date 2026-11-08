# Where does "Script startup exceeded CPU time limit" [code: 10021] start? (8 Nov 2026)

`node gen.mjs N > worker.js` writes a Worker whose top level runs a fixed loop N times; `npx wrangler@4.158.0 deploy`
then reports `Worker Startup Time` or rejects the upload with code 10021. 21 deploys of 11 sizes, in the order run, are in
`results.txt` (the first ten were logged without seconds). `npx wrangler check startup` on 100,000,000 measured 949 ms
active locally (Windows 11), against 449 ms on Cloudflare.
