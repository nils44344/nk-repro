# TypeError: unexpected keyword argument 'proxies'

`px.py` builds OpenAI / Anthropic clients and plain httpx clients with `proxies=`, `proxy=` and `mounts=`,
against a local HTTP server that acts as the proxy and records what reaches it. No real API calls.

Run it in one venv per combination (Python 3.14.5, Windows 11, October 23, 2026):

| venv | packages |
|---|---|
| px1.40.0 | openai 1.40.0, httpx 0.28.1 |
| px1.55.2 | openai 1.55.2, httpx 0.28.1 |
| phx27 | openai 1.55.2, httpx 0.27.2 |
| px1.55.3 | openai 1.55.3, httpx 0.28.1 |
| pa0.39.0 / pa0.40.0 | anthropic 0.39.0 / 0.40.0, httpx 0.28.1 |
| voai | openai 3.37.0 (httpx2 2.16.0) |
| pxnew | openai 3.37.0, httpx 0.28.1 |

    python -I px.py
