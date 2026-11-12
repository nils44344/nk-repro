# openai / @anthropic-ai/sdk (Node): "Connection error."

```
APIConnectionError: Connection error.
```

The message says nothing about the cause. The real reason is on the error's `cause`, so print it first:

```js
catch (e) { console.log(e.cause?.code, e.cause?.message) }
```

## What `run.sh` does, and what happened

It calls both SDKs with fake keys against a local or broken endpoint and prints each error's cause. Run on GitHub Actions `ubuntu-latest`, Node 24.22.2, openai 7.55.0, @anthropic-ai/sdk 1.8.0, on 11 November 2026: https://github.com/nils44344/nk-repro/actions/runs/43056332195 (workflow [`api-connection-error.yml`](../.github/workflows/api-connection-error.yml)).

| Case | `cause` (same for both SDKs) |
|---|---|
| Nothing listening on the port | `ECONNREFUSED` |
| Typo in the host (`api.openai.co`, `api.anthropic.co`) | `ENOTFOUND` |
| HTTPS server with a self-signed certificate | `DEPTH_ZERO_SELF_SIGNED_CERT` |

Certificate fixes, against that self-signed server:

| Fix | Result |
|---|---|
| none | Connection error |
| `NODE_EXTRA_CA_CERTS=cert.pem` | reached the server (401) |
| certificate added to the system store, plain `node` | still Connection error |
| `node --use-system-ca` | reached the server (401) |
| `NODE_USE_SYSTEM_CA=1` | reached the server (401) |
| `NODE_TLS_REJECT_UNAUTHORIZED=0` | reached the server (401); turns certificate checks off, so use it only to test |

Proxy: with `HTTPS_PROXY` set, plain `node` ignored it (the proxy saw nothing). With `NODE_USE_ENV_PROXY=1` as well, the proxy saw `CONNECT api.openai.com:443` and `CONNECT api.anthropic.com:443`.

## Full write-up

https://nilaykabariya.blog/ai/openai-apiconnectionerror-connection-error

## Run it yourself

```bash
git clone https://github.com/nils44344/nk-repro
bash nk-repro/api-connection-error/run.sh
```
