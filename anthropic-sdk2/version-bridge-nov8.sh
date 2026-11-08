#!/bin/bash
# Does sending anthropic-version 2023-06-01 keep `temperature` working? Real API, max_tokens 1 (8 Nov 2026).
# Needs ANTHROPIC_API_KEY; never prints it.
for v in 2023-06-01 2026-10-21; do for m in claude-haiku-4-5 claude-haiku-5-5; do
  r=$(curl -s -m 60 https://api.anthropic.com/v1/messages -H "x-api-key: $ANTHROPIC_API_KEY" -H "anthropic-version: $v" \
    -H "content-type: application/json" -w " HTTP%{http_code}" \
    -d "{\"model\":\"$m\",\"max_tokens\":1,\"temperature\":0.2,\"messages\":[{\"role\":\"user\",\"content\":\"hi\"}]}")
  echo "$v | $m | ${r##* } | $(echo "${r% HTTP*}" | python3 -c "import sys,json;j=json.load(sys.stdin);print(j.get('error',{}).get('message') or 'ok, model='+j.get('model',''))")"
done; done
