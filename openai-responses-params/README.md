# openai Python SDK: "Responses.create() got an unexpected keyword argument 'max_tokens'"

```
TypeError: Responses.create() got an unexpected keyword argument 'max_tokens'
```

## Why

`client.responses.create()` is not `client.chat.completions.create()`. The Responses API renamed some arguments, moved others into nested objects and dropped a few, and the Python SDK checks the names before it sends anything. So the `TypeError` is raised by Python, not by the API.

## What `sdk_args.py` does, and what happened

It calls `client.responses.create()` against a local server, so no API key is needed, once per Chat Completions argument. Run on GitHub Actions `ubuntu-latest`, Python 3.14.10, openai 3.37.0 and 3.49.0, on 11 November 2026 (same result on both): https://github.com/nils44344/nk-repro/actions/runs/43056346678 (workflow [`openai-responses-params.yml`](../.github/workflows/openai-responses-params.yml)).

Twelve arguments raised `TypeError ... unexpected keyword argument`: `messages`, `max_tokens`, `max_completion_tokens`, `seed`, `frequency_penalty`, `presence_penalty`, `response_format`, `verbosity`, `reasoning_effort`, `stop` (with "Did you mean 'store'?"), `n` and `logprobs`.

These forms were sent as written:

| Chat Completions | Responses form that was sent |
|---|---|
| `max_tokens` | `max_output_tokens=50` |
| `response_format={"type": "json_object"}` | `text={"format": {"type": "json_object"}}` |
| `verbosity="low"` | `text={"verbosity": "low"}` |
| `reasoning_effort="low"` | `reasoning={"effort": "low"}` |
| `logprobs` | `top_logprobs=2` with `include=["message.output_text.logprobs"]` |
| `messages=[...]` | `input=[{"role": "user", "content": "hi"}]` |

## The fix

```python
client.responses.create(model="gpt-5.5", input="hi", max_output_tokens=500)
```

## Full write-up

The same tests against the live API (the 400 errors the API itself returns), and the `proxies` TypeError from httpx 0.28: https://nilaykabariya.blog/ai/openai-responses-create-unexpected-keyword-argument

## Run it yourself

```bash
git clone https://github.com/nils44344/nk-repro
pip install openai
python nk-repro/openai-responses-params/sdk_args.py
```
