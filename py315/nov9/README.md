# langchain on Python 3.15.2, Windows 11, no C++ compiler or Rust (9 Nov 2026)

`py -V:3.15 -m venv lc315`, pip 26.2.2, `pip install --no-cache-dir langchain`. uuid-utils and ormsgpack come from 3.15 wheels now; it stops at zstandard 0.25.0 (no 3.15 wheel): Microsoft Visual C++ 14.0 or greater is required.
