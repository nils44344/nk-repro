// The three CPU tasks, timed inside the process; prints "name ms checksum" so both runtimes can be compared.
const t = (name, f) => { const s = performance.now(); const c = f(); console.log(name, (performance.now() - s).toFixed(1), c); };
let seed = 42; const rnd = () => (seed = (seed * 1103515245 + 12345) % 2147483648) / 2147483648;
t("sort", () => { const a = Array.from({ length: 2_000_000 }, rnd); a.sort((x, y) => x - y); return Math.round(a[1000] * 1e6); });
t("json", () => { const o = Array.from({ length: 200_000 }, (_, i) => ({ id: i, name: "item" + i, tags: ["a", "b"], v: i * 1.5 })); return JSON.parse(JSON.stringify(o)).length; });
t("sieve", () => { const n = 10_000_000, s = new Uint8Array(n + 1); let c = 0; for (let i = 2; i <= n; i++) { if (!s[i]) { c++; for (let j = i * i; j <= n; j += i) s[j] = 1; } } return c; });
