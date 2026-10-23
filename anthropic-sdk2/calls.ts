import Anthropic from "@anthropic-ai/sdk";
import http from "node:http";
const seen: any[] = [];
const srv = http.createServer((req, res) => {
  let b = ""; req.on("data", (c) => (b += c)); req.on("end", () => {
    seen.push({ ...req.headers, _body: b });
    res.setHeader("content-type", "application/json");
    res.end(JSON.stringify({ id: "msg_1", type: "message", role: "assistant", model: "claude-opus-5-5", content: [{ type: "text", text: "hi" }], stop_reason: "end_turn", stop_sequence: null, usage: { input_tokens: 1, output_tokens: 1 } }));
  });
});
await new Promise<void>((r) => srv.listen(0, "127.0.0.1", () => r()));
const baseURL = `http://127.0.0.1:${(srv.address() as any).port}`;
const run = async (name: string, fn: () => any) => {
  console.log(`\n## ${name}`);
  try { const r = await fn(); console.log("OK", r ?? ""); } catch (e: any) { console.log(`${e.constructor.name}: ${e.message}`); }
};
const c = new Anthropic({ apiKey: "sk-ant-fake", baseURL, maxRetries: 0 });
const messages = [{ role: "user" as const, content: "hi" }];
const model = "claude-opus-5-5";
await run("plain create, headers", async () => { await c.messages.create({ model, max_tokens: 10, messages }); const h = seen.at(-1); return { "x-api-key": h["x-api-key"], authorization: h["authorization"], "anthropic-version": h["anthropic-version"] }; });
await run("temperature: 0.2", async () => { await c.messages.create({ model, max_tokens: 10, messages, temperature: 0.2 }); return "sent temperature=" + JSON.parse(seen.at(-1)._body).temperature; });
await run("apiKey + authToken", async () => { const d = new Anthropic({ apiKey: "sk-ant-fake", authToken: "tok", baseURL, maxRetries: 0 }); await d.messages.create({ model, max_tokens: 10, messages }); const h = seen.at(-1); return { "x-api-key": h["x-api-key"], authorization: h["authorization"] }; });
await run("client.completions.create", async () => { await (c as any).completions.create({ model, max_tokens_to_sample: 10, prompt: "\n\nHuman: hi\n\nAssistant:" }); return "sent"; });
srv.close();
