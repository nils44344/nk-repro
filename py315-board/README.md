# Python 3.15 readiness board

Plain `pip install <package>` in a fresh venv, then `import`, for 504 PyPI packages on clean GitHub runners. Anything that is not a clean wheel install is repeated on Python 3.14 to show whether the problem is specific to 3.15. Re-run daily by [the workflow](../.github/workflows/py315-board.yml).

Last run: 2026-11-09, [run log](https://github.com/nils44344/nk-repro/actions/runs/42685150359). Interpreters: macOS 3.15.2 (control 3.14.10); Linux 3.15.2 (control 3.14.10); Windows 3.15.2 (control 3.14.10).

| | Windows | Linux | macOS |
|---|---:|---:|---:|
| Ready: a wheel installs and the package imports | 458 | 459 | 456 |
| Works only by compiling from source on the runner | 24 | 25 | 25 |
| Fails on 3.15, works on 3.14 | 7 | 7 | 7 |
| Fails on 3.15 and on 3.14 (not a 3.15 problem) | 15 | 13 | 16 |

## Not ready

Packages where at least one operating system is not a clean wheel install.

| Rank | Package | Windows | Linux | macOS |
|---:|---|---|---|---|
| 12 | `pyyaml` | compiles from source: pyyaml | compiles from source: pyyaml | compiles from source: pyyaml |
| 105 | `soupsieve` | **fails**: import failed; 3.14 fails too | **fails**: import failed; 3.14 fails too | **fails**: import failed; 3.14 fails too |
| 120 | `uvloop` | **fails**: build from source failed; 3.14 fails too | ready (0.23.0) | ready (0.23.0) |
| 121 | `huggingface-hub` | compiles from source: pyyaml | compiles from source: pyyaml | compiles from source: pyyaml |
| 156 | `tokenizers` | compiles from source: pyyaml | compiles from source: pyyaml | compiles from source: pyyaml |
| 168 | `httpx-sse` | **fails**: import failed; 3.14 fails too | **fails**: import failed; 3.14 fails too | **fails**: import failed; 3.14 fails too |
| 170 | `psycopg` | ready (3.3.8) | ready (3.3.8) | **fails**: import failed; 3.14 fails too |
| 173 | `zstandard` | compiles from source: zstandard | compiles from source: zstandard | compiles from source: zstandard |
| 181 | `psycopg-binary` | **fails**: import failed; 3.14 fails too | **fails**: import failed; 3.14 fails too | **fails**: import failed; 3.14 fails too |
| 198 | `langchain` | compiles from source: pyyaml, zstandard | compiles from source: pyyaml, zstandard | compiles from source: pyyaml, zstandard |
| 207 | `langchain-core` | compiles from source: pyyaml, zstandard | compiles from source: pyyaml, zstandard | compiles from source: pyyaml, zstandard |
| 211 | `pre-commit` | compiles from source: pyyaml | compiles from source: pyyaml | compiles from source: pyyaml |
| 234 | `ptyprocess` | **fails**: import failed; 3.14 fails too | ready (0.7.0) | ready (0.7.0) |
| 246 | `opentelemetry-util-http` | **fails**: import failed; 3.14 fails too | **fails**: import failed; 3.14 fails too | **fails**: import failed; 3.14 fails too |
| 269 | `transformers` | compiles from source: pyyaml | compiles from source: pyyaml | compiles from source: pyyaml |
| 285 | `onnxruntime` | **fails**: no matching version; 3.14 works | **fails**: no matching version; 3.14 works | **fails**: no matching version; 3.14 works |
| 286 | `matplotlib-inline` | **fails**: import failed; 3.14 fails too | **fails**: import failed; 3.14 fails too | **fails**: import failed; 3.14 fails too |
| 295 | `litellm` | **fails**: Rust build failed; 3.14 works | **fails**: Rust build failed; 3.14 works | **fails**: Rust build failed; 3.14 works |
| 308 | `langsmith` | compiles from source: zstandard | compiles from source: zstandard | compiles from source: zstandard |
| 310 | `awscli` | compiles from source: pyyaml | compiles from source: pyyaml | compiles from source: pyyaml |
| 319 | `lz4` | compiles from source: lz4 | compiles from source: lz4 | compiles from source: lz4 |
| 322 | `kubernetes` | compiles from source: pyyaml | compiles from source: pyyaml | compiles from source: pyyaml |
| 332 | `opentelemetry-instrumentation-fastapi` | **fails**: import failed; 3.14 fails too | **fails**: import failed; 3.14 fails too | **fails**: import failed; 3.14 fails too |
| 334 | `fastuuid` | **fails**: Rust build failed; 3.14 works | **fails**: Rust build failed; 3.14 works | **fails**: Rust build failed; 3.14 works |
| 349 | `jsonschema-path` | compiles from source: pyyaml | compiles from source: pyyaml | compiles from source: pyyaml |
| 357 | `opentelemetry-instrumentation-requests` | **fails**: import failed; 3.14 fails too | **fails**: import failed; 3.14 fails too | **fails**: import failed; 3.14 fails too |
| 373 | `datasets` | compiles from source: pyyaml | compiles from source: pyyaml | compiles from source: pyyaml |
| 376 | `ruamel-yaml-clib` | **fails**: import failed; 3.14 fails too | **fails**: import failed; 3.14 fails too | **fails**: import failed; 3.14 fails too |
| 390 | `psycopg2` | ready (2.9.13) | compiles from source: psycopg2 | **fails**: build from source failed; 3.14 fails too |
| 391 | `responses` | compiles from source: pyyaml | compiles from source: pyyaml | compiles from source: pyyaml |
| 408 | `fastmcp` | compiles from source: pyyaml | compiles from source: pyyaml | compiles from source: pyyaml |
| 410 | `deepdiff` | **fails**: Rust build failed; 3.14 works | **fails**: Rust build failed; 3.14 works | **fails**: Rust build failed; 3.14 works |
| 416 | `backports-zstd` | **fails**: no matching version; 3.14 fails too | **fails**: no matching version; 3.14 fails too | **fails**: no matching version; 3.14 fails too |
| 419 | `jupyterlab-pygments` | **fails**: import failed; 3.14 fails too | **fails**: import failed; 3.14 fails too | **fails**: import failed; 3.14 fails too |
| 424 | `psycopg-pool` | **fails**: import failed; 3.14 fails too | **fails**: import failed; 3.14 fails too | **fails**: import failed; 3.14 fails too |
| 426 | `langgraph` | compiles from source: pyyaml, zstandard | compiles from source: pyyaml, zstandard | compiles from source: pyyaml, zstandard |
| 436 | `langgraph-sdk` | compiles from source: pyyaml, zstandard | compiles from source: pyyaml, zstandard | compiles from source: pyyaml, zstandard |
| 441 | `langgraph-checkpoint` | compiles from source: pyyaml, zstandard | compiles from source: pyyaml, zstandard | compiles from source: pyyaml, zstandard |
| 448 | `langgraph-prebuilt` | **fails**: import failed; 3.14 fails too | **fails**: import failed; 3.14 fails too | **fails**: import failed; 3.14 fails too |
| 453 | `pyspark` | compiles from source: pyspark | compiles from source: pyspark | compiles from source: pyspark |
| 467 | `fastapi-cli` | compiles from source: pyyaml | compiles from source: pyyaml | compiles from source: pyyaml |
| 473 | `triton` | **fails**: no matching version; 3.14 fails too | ready (3.9.0) | **fails**: no matching version; 3.14 fails too |
| 480 | `tree-sitter` | compiles from source: tree-sitter | compiles from source: tree-sitter | compiles from source: tree-sitter |
| 482 | `moto` | compiles from source: pyyaml | compiles from source: pyyaml | compiles from source: pyyaml |
| 486 | `ddtrace` | **fails**: build from source failed; 3.14 works | **fails**: build from source failed; 3.14 works | **fails**: build from source failed; 3.14 works |
| 494 | `confluent-kafka` | **fails**: build from source failed; 3.14 works | **fails**: build from source failed; 3.14 works | **fails**: build from source failed; 3.14 works |
| 500 | `poetry` | ready (2.5.1) | ready (2.5.1) | compiles from source: xattr |
|  | `tensorflow` | **fails**: no matching version; 3.14 works | **fails**: no matching version; 3.14 works | **fails**: no matching version; 3.14 works |
|  | `jupyterlab` | compiles from source: pyyaml | compiles from source: pyyaml | compiles from source: pyyaml |
|  | `pywinpty` | ready (3.1.2) | **fails**: Rust build failed; 3.14 fails too | **fails**: Rust build failed; 3.14 fails too |

## Data and history

- Every package, with versions, wheel type, error lines and run ids: [latest.json](latest.json).
- What changed and when: [CHANGES.md](CHANGES.md).
- The package list: [packages.txt](packages.txt), the top 500 PyPI projects by downloads plus a few extras.

## Check one package yourself

```
python py315-board/board.py --only pyyaml,torch
```

Rank is the download rank in packages.txt. "Compiles from source" means pip found no wheel for 3.15 and built the listed packages on the runner, which has a C compiler; on a machine without one the install fails.
