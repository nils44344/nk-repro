// Keeps allocating until it reaches TARGET_MB of live data (or the heap runs out).
const target = Number(process.env.TARGET_MB || 600);
const keep = [];
let mb = 0;
while (mb < target) { keep.push(new Array(256 * 1024).fill(mb)); mb += 2; }
console.log("reached", target, "MB without crashing");
