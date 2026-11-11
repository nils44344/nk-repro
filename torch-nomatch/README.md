# pip: "No matching distribution found for torch" on Windows

```
ERROR: Could not find a version that satisfies the requirement torch (from versions: none)
ERROR: No matching distribution found for torch
```

## Why

pip found no PyTorch wheel for this exact Python. Three things decide it: the Python version (3.15 has only torch 2.15.0), the build (32-bit Python and any CUDA index too old for your Python give `from versions: none`), and a pinned torch version that is older than the wheels published for your Python.

## What `run.sh` does, and what happened

`run.sh` asks pip which torch versions exist for the Python it runs on (`pip index versions`, `pip install --dry-run`), so no multi-GB wheel is downloaded. Run on GitHub Actions `windows-latest` on 11 November 2026, pip 26.3: https://github.com/nils44344/nk-repro/actions/runs/43057169516 (workflow [`torch-nomatch.yml`](../.github/workflows/torch-nomatch.yml)).

| Python | PyPI result |
|---|---|
| 3.14.10, 64-bit | torch 2.9.0 to 2.15.0 |
| 3.14.10, free-threaded | torch 2.9.0 to 2.15.0 |
| 3.15.2, 64-bit | only torch 2.15.0 |
| 3.14.10, 32-bit | `from versions: none` |

Newest torch per PyTorch index, on 64-bit Python 3.14: cu118, cu121, cu124 none; cu126 2.14.1; cu128 2.11.0; cu129 2.9.0; cu130 2.14.1; cu132 2.15.0; cpu 2.15.0. `torch==2.1.2` fails with the list of versions that do exist (2.9.0 to 2.15.0).

## The fix

Use 64-bit Python 3.14 or 3.15 and a current index, and pin a version that exists for your Python:

```powershell
pip install --upgrade pip
pip install torch
```

## Run it yourself

```bash
git clone https://github.com/nils44344/nk-repro
bash nk-repro/torch-nomatch/run.sh            # your Python, PyPI only
INDEXES=1 bash nk-repro/torch-nomatch/run.sh  # also every PyTorch index
```

## More

Every cause with the exact commands, including the wrong package name `pytorch`: https://nilaykabariya.blog/fixes/no-matching-distribution-found-for-torch
