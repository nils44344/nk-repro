# OpenAI October 23, 2026 model shutdown

Tested with `openai` 7.32.0 (npm), Node 24.14.0, Windows 11 Pro, on a new API project with a $0 credit balance (no credits spent).

- `poll.mjs`: calls each shut-down model every 15 minutes and logs every status change with its UTC time. `poll.log` is the real log: all models flipped from `429 credit_balance_exhausted` to `404 ... has been deprecated` between 17:10 and 17:25 UTC on Oct 23.
- `after.mjs`: after the shutdown, `models.retrieve` still returns most removed models while a call 404s.
- `check.mjs`: the check from the post. A real call tells a live model (429 on a $0 key) from a shut-down one (404).

Put `OPENAI_API_KEY` in `../.env`, `npm i openai dotenv`, then `node check.mjs`.

Post: https://nilaykabariya.blog/ai/openai-model-shutdown-october-23-2026
