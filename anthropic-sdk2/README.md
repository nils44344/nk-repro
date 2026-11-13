# Anthropic Python SDK: "Messages.create() got an unexpected keyword argument 'temperature'"

```
TypeError: Messages.create() got an unexpected keyword argument 'temperature'
```

## What the scripts show, and what happened

Run on GitHub Actions `ubuntu-latest`, Python 3.14.10, anthropic 1.17.0 and 2.1.0, on 11 November 2026: https://github.com/nils44344/nk-repro/actions/runs/43056320851 (workflow [`anthropic-sdk2.yml`](../.github/workflows/anthropic-sdk2.yml)). The SDK is pointed at a local server with a fake key, so no key is needed.

| Call | 1.17.0 | 2.1.0 |
|---|---|---|
| `messages.create(temperature=...)`, `top_p`, `top_k` | `TypeError: unexpected keyword argument` | same |
| `messages.stream(temperature=...)`, `messages.count_tokens(temperature=...)` | same TypeError | same TypeError |
| `messages.create(betas=[...])` | `unexpected keyword argument 'betas'` | same |
| `beta.messages.create(betas=[...])` | sent, `?beta=true` | sent, `?beta=true` |
| `beta.messages.create(temperature=...)` | `unexpected keyword argument` | same |
| `anthropic-version` header sent | `2023-06-01` | `2026-10-21` |
| `client.completions` | no `completions` attribute | no `completions` attribute |
| Both `api_key` and `auth_token` | sent both credentials | refused (`ValueError`) |
| `MessageParam(role="user", content="hi")` | returned a dict | `TypeError: 'typing.Union' object is not callable` |

Full write-up (the real-API tests, the fixes, what did not work): https://nilaykabariya.blog/ai/anthropic-messages-create-unexpected-keyword-argument

## Run it yourself

```
pip install "anthropic==1.17.0"   # then "anthropic==2.1.0"
python calls.py; python headers.py; python betas.py

npm i @anthropic-ai/sdk@0.137.0 typescript@5 tsx   # then @1.1.0
npx tsc -p . ; npx tsx calls.ts
```

Write-up: https://nilaykabariya.blog/ai/anthropic-messages-create-unexpected-keyword-argument
