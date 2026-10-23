#!/usr/bin/env bash
# Sends Chat Completions-style arguments to the Responses API. Needs OPENAI_API_KEY; a key with no credits is enough:
# the API checks parameters before credits, so wrong ones return 400 and valid ones return credit_balance_exhausted.
t(){ echo "== $1"; curl -s https://api.openai.com/v1/responses -H "Authorization: Bearer $OPENAI_API_KEY" -H "content-type: application/json" -d "$2"; echo; }
for p in '"messages":[{"role":"user","content":"hi"}]' '"input":"hi","max_tokens":50' '"input":"hi","max_completion_tokens":50' \
  '"input":"hi","response_format":{"type":"json_object"}' '"input":"hi","verbosity":"low"' '"input":"hi","reasoning_effort":"low"' \
  '"input":"hi","seed":1' '"input":"hi","n":2' '"input":"hi","stop":["x"]' '"input":"hi","logprobs":true' \
  '"input":"hi","frequency_penalty":0.5' '"input":"hi","presence_penalty":0.5' '"input":"hi","max_output_tokens":5' \
  '"input":"hi","text":{"format":{"type":"json_object"}}'; do t "$p" "{\"model\":\"gpt-5.5\",$p}"; done
t "4.1 frequency_penalty" '{"model":"gpt-4.1-mini","input":"hi","frequency_penalty":0.5}'
