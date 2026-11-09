#!/bin/bash
# jsdom 31: does a `load` listener on document still fire, or only on window? (9 Nov 2026)
set +e
W=${W:-$(pwd)/work-load}; rm -rf "$W"; mkdir -p "$W"; cd "$W" || exit 1
cat > l.cjs <<'JS'
const { JSDOM } = require('jsdom');
const dom = new JSDOM('<!doctype html><p>x</p><script>window.__log=[];document.addEventListener("load",()=>__log.push("document load"));window.addEventListener("load",()=>__log.push("window load"));document.addEventListener("DOMContentLoaded",()=>__log.push("DOMContentLoaded"));</script>', { runScripts: 'dangerously' });
setTimeout(() => console.log(`jsdom ${require('jsdom/package.json').version}: ${dom.window.__log.join(', ') || '(nothing fired)'}`), 300);
JS
for J in 30 31; do mkdir -p j$J && cd j$J && npm init -y >/dev/null && npm i jsdom@$J --no-audit --no-fund --loglevel=error >/dev/null 2>&1 && cp ../l.cjs . && node l.cjs; cd ..; done
