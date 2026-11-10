# PyYAML on Python 3.15: "Failed building wheel for pyyaml"

`pip install pyyaml` on Python 3.15 for Windows, on a PC without the C++ Build Tools:

```
error: Microsoft Visual C++ 14.0 or greater is required. Get it with "Microsoft C++ Build Tools": https://visualstudio.microsoft.com/visual-cpp-build-tools/
ERROR: Failed building wheel for pyyaml
```

`pip install transformers`, `jupyterlab` and `langchain` stop with the same lines, because they all install PyYAML.

## Why

PyYAML 6.0.3 (September 2025) is still the newest release. On PyPI today (10 November 2026) it has wheels up to
`cp314` and none for `cp315`. With no wheel, pip downloads the source and compiles PyYAML's C extension, and that
needs a C compiler.

## What `check.py` does, and what happened

`check.py` makes a fresh virtual environment for each package, runs `pip install --no-cache-dir <package>`, and prints
the installed version or the error lines. It also prints whether a C compiler and Rust are present.

Run on GitHub Actions on November 5, 2026: https://github.com/nils44344/nk-repro/actions/runs/41991589424
(workflow [`py315.yml`](../.github/workflows/py315.yml)).

| Package | Windows, 3.15.2 | Windows, 3.14.10 | Ubuntu, 3.15.2 | Ubuntu, 3.14.9 |
|---|---|---|---|---|
| pyyaml | 6.0.3, built from source | 6.0.3, wheel | 6.0.3, built from source | 6.0.3, wheel |
| transformers | 5.22.1, built pyyaml | 5.22.1 | 5.22.1, built pyyaml | 5.22.1 |
| jupyterlab | 4.6.5, built pyyaml | 4.6.5 | 4.6.5, built pyyaml | 4.6.5 |
| langchain | 1.4.9, built pyyaml and zstandard | 1.4.9 | 1.4.9, built pyyaml and zstandard | 1.4.9 |
| sentencepiece | 0.2.3, wheel | 0.2.3 | 0.2.3 | 0.2.3 |
| torch | 2.15.0 | 2.15.0 | 2.15.0 | 2.15.0 |
| tensorflow | `No matching distribution found` | 2.22.0rc0 | `No matching distribution found` | 2.22.0rc0 |

The GitHub runners come with a C++ compiler and Rust installed, so on 3.15 pip compiled PyYAML there and the install
worked. That is what separates the two kinds of failure: PyYAML (and everything that needs it) fails only where there
is no compiler, which is most Windows PCs; tensorflow fails everywhere, because there is nothing to compile, it is not
published for 3.15 at all.

The failure without a compiler was run on Windows 11. [`nov8/`](nov8) has the full output for PyYAML on a machine
without Build Tools, and [`nov9/`](nov9) the same for langchain on 3.15.2.

## The fix

Either keep the project on Python 3.14, where PyYAML has a wheel:

```powershell
py -V:3.14 -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
```

Or stay on 3.15 and let PyYAML install without its C speedups:

```powershell
$env:PYYAML_FORCE_LIBYAML = "0"
pip install pyyaml
```

In the test for the post, PyYAML 6.0.3 installed on 3.15 this way with no compiler and loaded YAML correctly, and
`pip install transformers` then worked. That build is pure Python, so large YAML files load more slowly.

Installing the C++ Build Tools works too (it is what the runners have), at the cost of a large download.

## Run it yourself

```bash
git clone https://github.com/nils44344/nk-repro
python nk-repro/py315/check.py            # all the packages
python nk-repro/py315/check.py pyyaml     # just one
```

Run it with the Python you want to test. Each package goes into its own temporary virtual environment, which is
deleted afterwards.

## More

All 45 packages tested on 3.15 for Windows, and how torch, sentencepiece and langchain got working:
https://nilaykabariya.blog/tested/python-3-15-windows-packages-tested
