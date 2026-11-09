"""Python 3.15 readiness board: plain `pip install <package>` in a fresh venv, then import it, for every package
in packages.txt, on a clean GitHub runner. Anything that is not a clean wheel install is repeated on the control
interpreter (CONTROL_PY, Python 3.14) to show whether the problem is specific to 3.15.

Run with the interpreter under test:
    python py315-board/board.py --shard 0/6 --os windows-latest --out board-out
    python py315-board/board.py --only pyyaml,torch --os windows-latest --out board-out

Package failures are data, not errors: the script exits 0 and writes one JSON file."""
import argparse, json, os, platform, re, subprocess, sys, tempfile, time, urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
INSTALL_TIMEOUT = 900
IMPORT_TIMEOUT = 180


def norm(n):
    return re.sub(r"[-_.]+", "-", n).lower()


def read_packages():
    out, rank, extra = [], 0, False
    for line in open(os.path.join(HERE, "packages.txt"), encoding="utf-8"):
        line = line.strip()
        if line.lower().startswith("# extra"):
            extra = True
        if not line or line.startswith("#"):
            continue
        rank += 1
        out.append({"name": line, "rank": None if extra else rank})
    return out


# Runs inside the venv: find the module this distribution ships and import it.
PROBE = r'''
import importlib, importlib.metadata as m, json, re, sys, traceback
name = sys.argv[1]
def norm(n): return re.sub(r"[-_.]+", "-", n).lower()
res = {"module": None, "import": "none", "error": None, "missing": None, "version": None}
try:
    res["version"] = m.version(name)
except Exception:
    pass
try:
    files = [str(f).replace("\\", "/") for f in (m.distribution(name).files or [])]
except Exception:
    files = []
pkgs, mods = set(), set()
for f in files:
    parts = f.split("/")
    if ".." in parts or parts[0] == "__pycache__" or parts[0].endswith((".dist-info", ".egg-info", ".data")):
        continue
    if len(parts) == 1:
        if parts[0].endswith(".py"):
            mods.add(parts[0][:-3])
        elif re.search(r"\.(pyd|so)$", parts[0]):
            mods.add(parts[0].split(".")[0])
    elif parts[-1] == "__init__.py":
        pkgs.add("/".join(parts[:-1]))
roots = [p for p in pkgs if "/".join(p.split("/")[:-1]) not in pkgs]
cands = [p.replace("/", ".") for p in roots] + list(mods)
cands = [c for c in cands if all(x.isidentifier() for x in c.split("."))
         and c.split(".")[0] not in ("tests", "test", "docs", "examples", "benchmarks")]
want = norm(name)
def score(c):
    n = norm(c)
    return (0 if n == want else 1 if n.split("-")[-1] == want or want.endswith(n) or n.endswith(want) else 2,
            c.startswith("_"), c.count("."), len(c), c)
cands.sort(key=score)
if cands:
    res["module"] = cands[0]
    try:
        importlib.import_module(cands[0])
        res["import"] = "ok"
    except BaseException as e:
        res["import"] = "fail"
        if isinstance(e, ModuleNotFoundError) and e.name:
            res["missing"] = e.name.split(".")[0]
        res["error"] = (type(e).__name__ + ": " + str(e)).splitlines()[0][:300] if str(e) else type(e).__name__
print("PROBE " + json.dumps(res))
'''


def wheel_kind(url):
    """pure | abi3 | cpXY (version-specific wheel) | source"""
    fn = url.split("?")[0].split("#")[0].rsplit("/", 1)[-1]
    if not fn.endswith(".whl"):
        return "source"
    parts = fn[:-4].split("-")
    if len(parts) < 5:
        return "wheel"
    py, abi, plat = parts[-3], parts[-2], parts[-1]
    if plat == "any":
        return "pure"
    if abi == "abi3":
        return "abi3"
    return py.split(".")[-1][:12]


def classify(out):
    if "Microsoft Visual C++ 14.0 or greater is required" in out:
        return "needs a C compiler (MSVC)"
    if "newer than PyO3's maximum supported version" in out:
        return "Rust extension: its PyO3 does not support this Python yet"
    if re.search(r"can't find Rust compiler|cargo.*not found|Rust (toolchain|compiler)|maturin failed|PyO3", out, re.I):
        return "Rust build failed"
    if "No matching distribution found" in out:
        return "no matching version"
    if re.search(r"requires a different Python|Requires-Python", out):
        return "Requires-Python excludes this version"
    if re.search(r"Failed building wheel|failed to build|metadata-generation-failed|subprocess-exited-with-error", out, re.I):
        return "build from source failed"
    return "install failed"


def failed_builds(out):
    """Names of the projects pip could not build."""
    found = set(re.findall(r"Failed to build '([^']+)'", out)) | set(re.findall(r"Failed building wheel for ([A-Za-z0-9_.-]+)", out))
    for group in re.findall(r"based projects \(([^)]*)\)", out):
        found |= {x.strip() for x in group.split(",") if x.strip()}
    return sorted({norm(x) for x in found})[:6]


def error_lines(out):
    lines = [l.strip() for l in out.splitlines()
             if re.search(r"error|Error|ERROR|required|not found|No matching|Rust|cargo|link\.exe", l)]
    generic = r"This error originates from a subprocess|failed-wheel-build-for-install|subprocess-exited-with-error|metadata-generation-failed"
    specific = [l for l in lines if not re.search(generic, l)]
    return [l[:220] for l in (specific or lines)[-3:]]


def latest_version(pkg):
    try:
        req = urllib.request.Request(f"https://pypi.org/pypi/{pkg}/json", headers={"User-Agent": "nk-repro py315-board"})
        with urllib.request.urlopen(req, timeout=20) as r:
            return json.load(r)["info"]["version"]
    except Exception:
        return None


def test(interp, pkg):
    """One fresh venv: install, then import. Returns a dict with status ok | install-fail | import-fail | timeout."""
    t0 = time.time()
    res = {"status": "install-fail", "version": None, "kind": None, "source_builds": [], "module": None,
           "reason": None, "error": [], "failed_builds": []}
    with tempfile.TemporaryDirectory(ignore_cleanup_errors=True) as d:
        v = os.path.join(d, "v")
        mk = subprocess.run([interp, "-m", "venv", v], capture_output=True, text=True)
        if mk.returncode:
            res["reason"], res["error"] = "venv failed", error_lines(mk.stdout + mk.stderr)
            return res
        py = os.path.join(v, "Scripts" if os.name == "nt" else "bin", "python")
        rep = os.path.join(d, "report.json")
        try:
            r = subprocess.run([py, "-m", "pip", "install", "--no-cache-dir", "--disable-pip-version-check",
                                "--no-input", "--report", rep, pkg],
                               capture_output=True, text=True, errors="replace", timeout=INSTALL_TIMEOUT)
        except subprocess.TimeoutExpired:
            res["status"], res["reason"] = "timeout", f"install took over {INSTALL_TIMEOUT}s"
            res["seconds"] = round(time.time() - t0)
            return res
        out = r.stdout + r.stderr
        try:
            items = json.load(open(rep, encoding="utf-8")).get("install", [])
        except Exception:
            items = []
        for it in items:
            name = it.get("metadata", {}).get("name", "")
            kind = wheel_kind(it.get("download_info", {}).get("url", ""))
            if kind == "source":
                res["source_builds"].append(norm(name))
            if norm(name) == norm(pkg):
                res["version"], res["kind"] = it.get("metadata", {}).get("version"), kind
        res["source_builds"].sort()
        if r.returncode:
            res["reason"], res["error"] = classify(out), error_lines(out)
            res["failed_builds"] = failed_builds(out)
        else:
            try:
                p = subprocess.run([py, "-c", PROBE, pkg], capture_output=True, text=True, errors="replace",
                                   timeout=IMPORT_TIMEOUT, cwd=d)
                m = re.search(r"^PROBE (\{.*\})\s*$", p.stdout, re.M)
                probe = json.loads(m.group(1)) if m else {"module": None, "import": "fail",
                                                          "error": (p.stderr.strip().splitlines() or ["probe crashed"])[-1][:300]}
            except subprocess.TimeoutExpired:
                probe = {"module": None, "import": "fail", "error": f"import took over {IMPORT_TIMEOUT}s"}
            res["module"] = probe.get("module")
            res["version"] = res["version"] or probe.get("version")
            if probe.get("import") == "fail":
                res["status"], res["reason"], res["error"] = "import-fail", "import failed", [probe.get("error") or ""]
                miss = probe.get("missing")
                if miss and miss != (res["module"] or "").split(".")[0]:
                    res["reason"] = f"import needs the module {miss}, which this package does not install"
            else:
                res["status"] = "ok"
    res["seconds"] = round(time.time() - t0)
    return res


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--shard", default="0/1")
    ap.add_argument("--only", default="")
    ap.add_argument("--os", default=platform.system().lower())
    ap.add_argument("--out", default="board-out")
    a = ap.parse_args()

    pkgs = read_packages()
    if a.only.strip():
        want = {norm(x) for x in a.only.split(",") if x.strip()}
        known = {norm(p["name"]): p for p in pkgs}
        pkgs = [known.get(w, {"name": w, "rank": None}) for w in sorted(want)]
        tag = "only"
    else:
        i, n = (int(x) for x in a.shard.split("/"))
        pkgs = pkgs[i::n]
        tag = str(i)

    control = os.environ.get("CONTROL_PY") or None
    control_ver = None
    if control:
        control_ver = subprocess.run([control, "-c", "import sys; print(sys.version.split()[0])"],
                                     capture_output=True, text=True).stdout.strip() or None
    meta = {"os": a.os, "platform": platform.platform(), "machine": platform.machine(),
            "python": sys.version.split()[0], "control_python": control_ver,
            "date": time.strftime("%Y-%m-%d", time.gmtime()), "run": os.environ.get("GITHUB_RUN_ID")}
    print(f"Python {meta['python']} on {meta['platform']}; control {control_ver}; {len(pkgs)} packages", flush=True)

    results = []
    for p in pkgs:
        r = test(sys.executable, p["name"])
        r.update(name=p["name"], rank=p["rank"], latest=latest_version(p["name"]))
        if control and (r["status"] != "ok" or r["source_builds"]):
            c = test(control, p["name"])
            r["control"] = {k: c[k] for k in ("status", "version", "kind", "source_builds", "reason", "failed_builds")}
        results.append(r)
        line = f"{r['status']:<13} {p['name']} {r['version'] or ''} [{r['kind'] or '-'}]"
        if r["source_builds"]:
            line += "  built from source: " + ", ".join(r["source_builds"])
        if r["status"] != "ok":
            line += f"  ({r['reason']})"
        if "control" in r:
            line += f"  | on {control_ver}: {r['control']['status']} [{r['control']['kind'] or '-'}]"
        print(line, flush=True)
        for e in r["error"]:
            print(f"        {e}", flush=True)

    os.makedirs(a.out, exist_ok=True)
    path = os.path.join(a.out, f"{a.os}-{tag}.json")
    json.dump({"meta": meta, "results": results}, open(path, "w", encoding="utf-8"), indent=1)
    bad = sum(r["status"] != "ok" for r in results)
    print(f"wrote {path}: {len(results) - bad} ok, {bad} not ok")


if __name__ == "__main__":
    main()
