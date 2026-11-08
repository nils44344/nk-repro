// Worker whose top level runs N iterations of a fixed loop.
const n = Number(process.argv[2]);
console.log(`let x = 0; for (let i = 0; i < ${n}; i++) { x = (x * 31 + i) % 1000003; }
export default { fetch() { return new Response(String(x)); } };`);
