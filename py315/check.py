"""Plain `pip install` of the packages that had no Python 3.15 wheel on Windows, each in a fresh venv, on a clean
GitHub runner. Prints the installed version, or the last error lines. Used by the Python 3.15 post on
nilaykabariya.blog. Run with the interpreter under test: python py315/check.py"""
import os, re, shutil, subprocess, sys, tempfile, venv

PKGS = ["pyyaml", "transformers", "sentencepiece", "torch", "tensorflow", "langchain", "jupyterlab", "uuid-utils", "pywinpty"]
if os.name != "nt":
    PKGS.remove("pywinpty")  # Windows-only package

print(f"Python {sys.version.split()[0]} on {sys.platform}; C compiler: {bool(shutil.which('cl') or shutil.which('gcc'))}; cargo: {bool(shutil.which('cargo'))}")
for pkg in PKGS:
    with tempfile.TemporaryDirectory() as d:
        venv.create(d, with_pip=True)
        py = os.path.join(d, "Scripts" if os.name == "nt" else "bin", "python")
        r = subprocess.run([py, "-m", "pip", "install", "--no-cache-dir", "--disable-pip-version-check", pkg], capture_output=True, text=True)
        out = r.stdout + r.stderr
        if r.returncode == 0:
            m = re.search(r"Successfully installed (.*)", out)
            mine = [x for x in (m.group(1).split() if m else []) if x.lower().replace("_", "-").rsplit("-", 1)[0] == pkg]
            built = re.findall(r"Building wheel for (\S+)", out)
            print(f"OK    {pkg}: {mine[0] if mine else '?'}{'  (built from source: ' + ', '.join(sorted(set(built))) + ')' if built else ''}")
        else:
            lines = [l.strip() for l in out.splitlines() if re.search(r"error|Error|ERROR|required|not found|No matching|Rust|cargo|link\.exe", l)]
            print(f"FAIL  {pkg}:")
            for l in lines[-8:]:
                print(f"        {l[:220]}")
