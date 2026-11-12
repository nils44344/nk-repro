# Windows: "Python was not found; run without arguments to install from the Microsoft Store"

```
Python was not found; run without arguments to install from the Microsoft Store, or disable this shortcut from Settings > Apps > Advanced app settings > App execution aliases.
```

```
'pip' is not recognized as an internal or external command,
operable program or batch file.
```

## Why

The first message does not come from Python. Windows ships placeholder `python.exe` and `python3.exe` files in `%LOCALAPPDATA%\Microsoft\WindowsApps` (app execution aliases) that only point you to the Microsoft Store. If one of them is the first `python.exe` on PATH, you get the message and exit code 9009, even on a machine where Python is installed. The second message means pip is installed but the folder that holds the `pip` command is not on PATH.

## What `run.ps1` does, and what happened

Run on GitHub Actions `windows-latest` on 11 November 2026, pip 26.3, with the runner's Python 3.12.10: https://github.com/nils44344/nk-repro/actions/runs/43003878042 (workflow [`pystub.yml`](../.github/workflows/pystub.yml)).

| Case | Result |
|---|---|
| `python.exe` and `python3.exe` from `WindowsApps`, run directly | the Store message, exit 9009 |
| `python --version` with only `WindowsApps` and system folders on PATH | the Store message, exit 9009 |
| real Python's folder before `WindowsApps` on PATH | `Python 3.12.10` |
| real Python's folder after `WindowsApps` on PATH | the Store message |
| Python's folder on PATH but not its `Scripts` folder, `pip --version` in Command Prompt | `'pip' is not recognized` |
| `python -m pip --version` and `py -m pip --version`, same PATH | `pip 26.3` |

## The fix

Put the real Python's folder above `WindowsApps` in PATH, and run pip through Python:

```powershell
where.exe python
py -m pip --version
```

## Full write-up

https://nilaykabariya.blog/fixes/python-was-not-found-microsoft-store-windows

## Run it yourself

```powershell
git clone https://github.com/nils44344/nk-repro
powershell -File nk-repro\pystub\run.ps1
```
