"""Which situations make `pip install` fall back to compiling, and print
"Microsoft Visual C++ 14.0 or greater is required"? One fresh venv per case.
Run with the interpreter under test; extra args = "pkg[==ver]" specs; env vars pass through (PIP_NO_BINARY etc.)."""
import os, re, subprocess, sys, tempfile, venv, platform, sysconfig

specs = sys.argv[1:]
tag = f"{sys.version.split()[0]} {platform.architecture()[0]}{' free-threaded' if sysconfig.get_config_var('Py_GIL_DISABLED') else ''}"
for spec in specs:
    with tempfile.TemporaryDirectory() as d:
        venv.create(d, with_pip=True)
        py = os.path.join(d, "Scripts", "python.exe")
        pipv = subprocess.run([py, "-m", "pip", "--version"], capture_output=True, text=True).stdout.split()[1]
        r = subprocess.run([py, "-m", "pip", "install", "--no-cache-dir", "--disable-pip-version-check", spec], capture_output=True, text=True)
        out = r.stdout + r.stderr
        built = sorted(set(re.findall(r"Building wheel for (\S+)", out)))
        msvc = "Microsoft Visual C++ 14.0 or greater is required" in out
        key = [l.strip() for l in out.splitlines() if re.search(r"^\s*error:|ERROR:|Microsoft Visual", l)]
        res = "OK" if r.returncode == 0 else ("MSVC" if msvc else "FAIL")
        print(f"[{tag} pip {pipv}] {spec}: {res}{'  built: ' + ','.join(built) if built else ''}")
        if r.returncode:
            for l in key[-4:]:
                print(f"      {l[:200]}")
