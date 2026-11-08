# PyYAML on Python 3.14.5, Windows 11, no C++ compiler (8 Nov 2026)

Fresh venv (`py -3.14 -m venv v`), pip 26.1.1, Git Bash:

1. `v/Scripts/python -m pip install --no-cache-dir pyyaml==6.0.1`: Microsoft Visual C++ 14.0 or greater is required
2. `v/Scripts/python -m pip download pyyaml==6.0.1 --only-binary :all: --no-deps -d dl`: only 6.0.3 has a wheel
3. `v/Scripts/python -m pip install --no-cache-dir pyyaml==6.0.3`: installed from the cp314 win_amd64 wheel; `yaml.__with_libyaml__` is True

The full output of each step is in the numbered files.
