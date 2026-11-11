# Python 3.15 readiness board

Plain `pip install <package>` in a fresh venv, then `import`, for 504 PyPI packages on clean GitHub runners. Anything that is not a clean wheel install is repeated on Python 3.14 to show whether the problem is specific to 3.15. Re-run daily by [the workflow](../.github/workflows/py315-board.yml).

Last run: 2026-11-11, [run log](https://github.com/nils44344/nk-repro/actions/runs/42934173012). Interpreters: macOS 3.15.2 (control 3.14.10); Linux 3.15.2 (control 3.14.10); Windows 3.15.2 (control 3.14.10).

| | Windows | Linux | macOS |
|---|---:|---:|---:|
| Ready: a wheel installs and the package imports | 458 | 459 | 457 |
| Works only by compiling from source on the runner | 25 | 25 | 25 |
| Fails on 3.15, works on 3.14 | 6 | 7 | 6 |
| Same failure on 3.14 (not a 3.15 problem) | 15 | 13 | 16 |

## Fails on 3.15 only

The same command works on Python 3.14 on at least one operating system where it fails on 3.15.

| Rank | Package | Windows | Linux | macOS |
|---:|---|---|---|---|
| 285 | `onnxruntime` | **fails**: no matching version | **fails**: no matching version | **fails**: no matching version |
| 295 | `litellm` | compiles from source: pyyaml | **fails**: Rust extension: its PyO3 does not support this Python yet (fastuuid, pydantic-core, tiktoken) | compiles from source: pyyaml |
| 334 | `fastuuid` | **fails**: Rust extension: its PyO3 does not support this Python yet (fastuuid) | **fails**: Rust extension: its PyO3 does not support this Python yet (fastuuid) | **fails**: Rust extension: its PyO3 does not support this Python yet (fastuuid) |
| 410 | `deepdiff` | **fails**: Rust extension: its PyO3 does not support this Python yet (cachebox) | **fails**: Rust extension: its PyO3 does not support this Python yet (cachebox) | **fails**: Rust extension: its PyO3 does not support this Python yet (cachebox) |
| 486 | `ddtrace` | **fails**: build from source failed (ddtrace) | **fails**: build from source failed (ddtrace) | **fails**: build from source failed (ddtrace) |
| 494 | `confluent-kafka` | **fails**: build from source failed (confluent-kafka) | **fails**: build from source failed (confluent-kafka) | **fails**: build from source failed (confluent-kafka) |
|  | `tensorflow` | **fails**: no matching version | **fails**: no matching version | **fails**: no matching version |

## Installs on 3.15 only by compiling

pip found no 3.15 wheel for the listed packages and built them from source. The runners have a C compiler; on a machine without one this install fails.

| Rank | Package | Windows | Linux | macOS |
|---:|---|---|---|---|
| 12 | `pyyaml` | compiles from source: pyyaml | compiles from source: pyyaml | compiles from source: pyyaml |
| 121 | `huggingface-hub` | compiles from source: pyyaml | compiles from source: pyyaml | compiles from source: pyyaml |
| 156 | `tokenizers` | compiles from source: pyyaml | compiles from source: pyyaml | compiles from source: pyyaml |
| 173 | `zstandard` | compiles from source: zstandard | compiles from source: zstandard | compiles from source: zstandard |
| 198 | `langchain` | compiles from source: pyyaml, zstandard | compiles from source: pyyaml, zstandard | compiles from source: pyyaml, zstandard |
| 207 | `langchain-core` | compiles from source: pyyaml, zstandard | compiles from source: pyyaml, zstandard | compiles from source: pyyaml, zstandard |
| 211 | `pre-commit` | compiles from source: pyyaml | compiles from source: pyyaml | compiles from source: pyyaml |
| 269 | `transformers` | compiles from source: pyyaml | compiles from source: pyyaml | compiles from source: pyyaml |
| 308 | `langsmith` | compiles from source: zstandard | compiles from source: zstandard | compiles from source: zstandard |
| 310 | `awscli` | compiles from source: pyyaml | compiles from source: pyyaml | compiles from source: pyyaml |
| 319 | `lz4` | compiles from source: lz4 | compiles from source: lz4 | compiles from source: lz4 |
| 322 | `kubernetes` | compiles from source: pyyaml | compiles from source: pyyaml | compiles from source: pyyaml |
| 349 | `jsonschema-path` | compiles from source: pyyaml | compiles from source: pyyaml | compiles from source: pyyaml |
| 373 | `datasets` | compiles from source: pyyaml | compiles from source: pyyaml | compiles from source: pyyaml |
| 390 | `psycopg2` | ready (2.9.13) | compiles from source: psycopg2 | build from source failed (psycopg2) |
| 391 | `responses` | compiles from source: pyyaml | compiles from source: pyyaml | compiles from source: pyyaml |
| 408 | `fastmcp` | compiles from source: pyyaml | compiles from source: pyyaml | compiles from source: pyyaml |
| 426 | `langgraph` | compiles from source: pyyaml, zstandard | compiles from source: pyyaml, zstandard | compiles from source: pyyaml, zstandard |
| 436 | `langgraph-sdk` | compiles from source: pyyaml, zstandard | compiles from source: pyyaml, zstandard | compiles from source: pyyaml, zstandard |
| 441 | `langgraph-checkpoint` | compiles from source: pyyaml, zstandard | compiles from source: pyyaml, zstandard | compiles from source: pyyaml, zstandard |
| 453 | `pyspark` | compiles from source: pyspark | compiles from source: pyspark | compiles from source: pyspark |
| 467 | `fastapi-cli` | compiles from source: pyyaml | compiles from source: pyyaml | compiles from source: pyyaml |
| 480 | `tree-sitter` | compiles from source: tree-sitter | compiles from source: tree-sitter | compiles from source: tree-sitter |
| 482 | `moto` | compiles from source: pyyaml | compiles from source: pyyaml | compiles from source: pyyaml |
|  | `jupyterlab` | compiles from source: pyyaml | compiles from source: pyyaml | compiles from source: pyyaml |

## Same result on 3.14

Not a 3.15 problem: the package does not support that operating system, needs a system library to build, or cannot be imported without a companion package.

| Rank | Package | Windows | Linux | macOS |
|---:|---|---|---|---|
| 105 | `soupsieve` | import needs the module bs4, which this package does not install | import needs the module bs4, which this package does not install | import needs the module bs4, which this package does not install |
| 120 | `uvloop` | build from source failed (uvloop) | ready (0.23.0) | ready (0.23.0) |
| 168 | `httpx-sse` | import needs the module httpx, which this package does not install | import needs the module httpx, which this package does not install | import needs the module httpx, which this package does not install |
| 170 | `psycopg` | ready (3.3.8) | ready (3.3.8) | import failed |
| 181 | `psycopg-binary` | import failed | import failed | import failed |
| 234 | `ptyprocess` | import needs the module fcntl, which this package does not install | ready (0.7.0) | ready (0.7.0) |
| 246 | `opentelemetry-util-http` | import failed | import failed | import failed |
| 286 | `matplotlib-inline` | import needs the module matplotlib, which this package does not install | import needs the module matplotlib, which this package does not install | import needs the module matplotlib, which this package does not install |
| 332 | `opentelemetry-instrumentation-fastapi` | import needs the module fastapi, which this package does not install | import needs the module fastapi, which this package does not install | import needs the module fastapi, which this package does not install |
| 357 | `opentelemetry-instrumentation-requests` | import needs the module requests, which this package does not install | import needs the module requests, which this package does not install | import needs the module requests, which this package does not install |
| 376 | `ruamel-yaml-clib` | import needs the module ruamel, which this package does not install | import needs the module ruamel, which this package does not install | import needs the module ruamel, which this package does not install |
| 416 | `backports-zstd` | no matching version | no matching version | no matching version |
| 419 | `jupyterlab-pygments` | import needs the module pygments, which this package does not install | import needs the module pygments, which this package does not install | import needs the module pygments, which this package does not install |
| 424 | `psycopg-pool` | import needs the module psycopg, which this package does not install | import needs the module psycopg, which this package does not install | import needs the module psycopg, which this package does not install |
| 448 | `langgraph-prebuilt` | import failed | import failed | import failed |
| 473 | `triton` | no matching version | ready (3.9.0) | no matching version |
|  | `pywinpty` | ready (3.1.2) | Rust build failed (pywinpty) | Rust build failed (pywinpty) |

## Data and history

- Every package, with versions, wheel type, error lines and run ids: [latest.json](latest.json).
- What changed and when: [CHANGES.md](CHANGES.md).
- The package list: [packages.txt](packages.txt), the top 500 PyPI projects by downloads plus a few extras.

## Check one package yourself

```
python py315-board/board.py --only pyyaml,torch
```

Rank is the download rank in packages.txt.
