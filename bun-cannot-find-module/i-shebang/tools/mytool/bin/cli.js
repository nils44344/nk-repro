#!/usr/bin/env node
const { Database } = require("bun:sqlite");
console.log("runtime:", typeof Bun !== "undefined" ? "bun " + Bun.version : "node " + process.version, new Database(":memory:").query("select 1 as x").get());
