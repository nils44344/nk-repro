// Prints this process's V8 heap limit in MB, then starts a child Node process that prints its own.
const v8 = require("v8");
const { execFileSync } = require("child_process");
const mb = () => Math.round(v8.getHeapStatistics().heap_size_limit / 2 ** 20);
if (process.argv[2] === "child") { console.log("child heap limit MB:", mb()); process.exit(0); }
console.log("parent heap limit MB:", mb());
process.stdout.write(execFileSync(process.execPath, [__filename, "child"]).toString());
