# Anthropic SDK 1.x vs 2.x (Python) and 0.x vs 1.x (TypeScript)

Each script starts a local HTTP server, points the SDK at it with `base_url` / `baseURL` and a fake key, and prints what the SDK raised or sent. No real API calls.

```
pip install "anthropic==1.17.0"   # then "anthropic==2.1.0"
python calls.py; python headers.py; python betas.py

npm i @anthropic-ai/sdk@0.137.0 typescript@5 tsx   # then @1.1.0
npx tsc -p . ; npx tsx calls.ts
```

Write-up: https://nilaykabariya.blog/ai/anthropic-messages-create-unexpected-keyword-argument
