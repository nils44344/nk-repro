"""Merge the shard files written by board.py into latest.json, README.md and CHANGES.md.

    python py315-board/merge.py <dir with shard json files>

The shard files come from jobs that installed third-party packages, so they are treated as untrusted data:
every field is checked or cleaned, and nothing from them is executed. Packages missing from this run keep
their previous entry (with its older `tested` date)."""
import glob, json, os, re, sys, time

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from board import norm, read_packages  # noqa: E402

OS_KEYS = {"windows-latest": "windows", "ubuntu-latest": "linux", "macos-latest": "macos"}
OS_NAMES = {"windows": "Windows", "linux": "Linux", "macos": "macOS"}
STATUSES = {"ok", "install-fail", "import-fail", "timeout"}
VERDICT_TEXT = {"ready": "Ready: a wheel installs and the package imports",
                "builds": "Works only by compiling from source on the runner",
                "fails": "Fails on 3.15, works on 3.14",
                "fails-both": "Fails on 3.15 and on 3.14 (not a 3.15 problem)",
                "fails-unknown": "Fails on 3.15 (no 3.14 result)"}
REPO = os.environ.get("GITHUB_REPOSITORY", "nils44344/nk-repro")


def clean(s, n=220):
    s = "".join(ch if 32 <= ord(ch) < 127 else " " for ch in str(s or ""))
    return re.sub(r"[|<>\[\]`]", "'", s).strip()[:n]


def ver(s):
    return s if isinstance(s, str) and re.fullmatch(r"[0-9A-Za-z.+!_-]{1,60}", s) else None


def kind(s):
    return s if isinstance(s, str) and re.fullmatch(r"pure|abi3|source|wheel|(cp|pp|py)\d{1,4}t?", s) else None


def names(xs):
    return [x for x in (xs if isinstance(xs, list) else []) if isinstance(x, str) and re.fullmatch(r"[a-z0-9-]{1,80}", x)][:20]


def module(s):
    return s if isinstance(s, str) and re.fullmatch(r"[A-Za-z0-9_.]{1,120}", s) else None


def verdict(e):
    if e["status"] == "ok":
        return "builds" if e["source_builds"] else "ready"
    c = e.get("control")
    if not c:
        return "fails-unknown"
    return "fails" if c["status"] == "ok" else "fails-both"


def entry(r, meta):
    st = r.get("status") if r.get("status") in STATUSES else "install-fail"
    e = {"status": st, "version": ver(r.get("version")), "kind": kind(r.get("kind")),
         "source_builds": names(r.get("source_builds")), "module": module(r.get("module")),
         "reason": clean(r.get("reason"), 80) or None,
         "error": [clean(x) for x in (r.get("error") if isinstance(r.get("error"), list) else [])[:3] if clean(x)],
         "control": None, "tested": meta["date"], "run": meta["run"], "python": meta["python"]}
    c = r.get("control")
    if isinstance(c, dict):
        e["control"] = {"status": c.get("status") if c.get("status") in STATUSES else "install-fail",
                        "version": ver(c.get("version")), "kind": kind(c.get("kind")),
                        "source_builds": names(c.get("source_builds")), "python": meta["control_python"]}
    e["verdict"] = verdict(e)
    return e


def cell(e):
    if not e:
        return "not tested"
    v = e["verdict"]
    if v == "ready":
        return f"ready ({e['version']})"
    if v == "builds":
        return "compiles from source: " + ", ".join(e["source_builds"][:4])
    tail = {"fails": "; 3.14 works", "fails-both": "; 3.14 fails too", "fails-unknown": ""}[v]
    return f"**fails**: {e['reason'] or e['status']}{tail}"


def main():
    src = sys.argv[1]
    pkgs = read_packages()
    known = {norm(p["name"]): p for p in pkgs}
    latest_path = os.path.join(HERE, "latest.json")
    try:
        old = {p["name"]: p for p in json.load(open(latest_path, encoding="utf-8"))["packages"]}
    except Exception:
        old = {}
    first_run = not old

    new, latest, runs = {}, {}, {}
    for f in sorted(glob.glob(os.path.join(src, "**", "*.json"), recursive=True)):
        if f.endswith("-only.json"):
            continue
        try:
            d = json.load(open(f, encoding="utf-8"))
            m = d["meta"]
            osk = OS_KEYS[m["os"]]
            meta = {"date": m["date"] if re.fullmatch(r"\d{4}-\d\d-\d\d", str(m.get("date"))) else None,
                    "run": m["run"] if re.fullmatch(r"\d{1,20}", str(m.get("run"))) else None,
                    "python": ver(m.get("python")), "control_python": ver(m.get("control_python"))}
        except Exception as ex:
            print(f"skip {f}: {type(ex).__name__}")
            continue
        runs[osk] = meta
        for r in d.get("results", []):
            p = known.get(norm(str(r.get("name", ""))))
            if not p:
                continue
            new.setdefault(p["name"], {})[osk] = entry(r, meta)
            if ver(r.get("latest")):
                latest[p["name"]] = r["latest"]

    out, changes = [], []
    for p in pkgs:
        prev = old.get(p["name"], {})
        oses = {}
        for osk in OS_NAMES:
            e = new.get(p["name"], {}).get(osk) or (prev.get("os") or {}).get(osk)
            if not e:
                continue
            oses[osk] = e
            was = (prev.get("os") or {}).get(osk)
            if was and osk in new.get(p["name"], {}) and was.get("verdict") != e["verdict"]:
                changes.append(f"- {e['tested']} {OS_NAMES[osk]}: **{p['name']}** {was.get('verdict')} -> {e['verdict']}"
                               f" ({e['version'] or 'no version'})")
        out.append({"name": p["name"], "rank": p["rank"], "latest": latest.get(p["name"]) or prev.get("latest"), "os": oses})

    today = time.strftime("%Y-%m-%d", time.gmtime())
    run_id = os.environ.get("GITHUB_RUN_ID")
    run_url = f"https://github.com/{REPO}/actions/runs/{run_id}" if run_id else None
    json.dump({"generated": today, "run": run_url, "runners": runs, "verdicts": VERDICT_TEXT, "packages": out},
              open(latest_path, "w", encoding="utf-8", newline="\n"), indent=1)

    ch_path = os.path.join(HERE, "CHANGES.md")
    head = "# Changes on the Python 3.15 readiness board\n\nOne line each time a package changes state on an operating system.\n"
    body = open(ch_path, encoding="utf-8").read().split("\n", 3)[-1] if os.path.exists(ch_path) else ""
    if first_run:
        changes = [f"- {today}: first full run."]
    if changes:
        body = f"\n## {today}\n\n" + "\n".join(changes) + "\n" + body
    open(ch_path, "w", encoding="utf-8", newline="\n").write(head + body)

    counts = {o: {} for o in OS_NAMES}
    for p in out:
        for o in OS_NAMES:
            v = p["os"].get(o, {}).get("verdict", "not tested")
            counts[o][v] = counts[o].get(v, 0) + 1
    L = ["# Python 3.15 readiness board", "",
         f"Plain `pip install <package>` in a fresh venv, then `import`, for {len(out)} PyPI packages on clean GitHub "
         "runners. Anything that is not a clean wheel install is repeated on Python 3.14 to show whether the problem "
         "is specific to 3.15. Re-run daily by [the workflow](../.github/workflows/py315-board.yml).", "",
         f"Last run: {today}" + (f", [run log]({run_url})" if run_url else "") + ". Interpreters: "
         + "; ".join(f"{OS_NAMES[o]} {m['python']} (control {m['control_python']})" for o, m in runs.items()) + ".", "",
         "| | " + " | ".join(OS_NAMES.values()) + " |", "|---|" + "---:|" * len(OS_NAMES)]
    for v, text in list(VERDICT_TEXT.items()) + [("not tested", "Not tested yet")]:
        if any(counts[o].get(v) for o in OS_NAMES):
            L.append(f"| {text} | " + " | ".join(str(counts[o].get(v, 0)) for o in OS_NAMES) + " |")
    L += ["", "## Not ready", "", "Packages where at least one operating system is not a clean wheel install.", "",
          "| Rank | Package | " + " | ".join(OS_NAMES.values()) + " |", "|---:|---|" + "---|" * len(OS_NAMES)]
    rows = [p for p in out if any(e["verdict"] != "ready" for e in p["os"].values())]
    for p in rows:
        L.append(f"| {p['rank'] or ''} | `{p['name']}` | " + " | ".join(cell(p["os"].get(o)) for o in OS_NAMES) + " |")
    if not rows:
        L.append("| | none | | | |")
    L += ["", "## Data and history", "",
          "- Every package, with versions, wheel type, error lines and run ids: [latest.json](latest.json).",
          "- What changed and when: [CHANGES.md](CHANGES.md).",
          "- The package list: [packages.txt](packages.txt), the top 500 PyPI projects by downloads plus a few extras.", "",
          "## Check one package yourself", "", "```", "python py315-board/board.py --only pyyaml,torch", "```", "",
          "Rank is the download rank in packages.txt. \"Compiles from source\" means pip found no wheel for 3.15 and built "
          "the listed packages on the runner, which has a C compiler; on a machine without one the install fails.", ""]
    open(os.path.join(HERE, "README.md"), "w", encoding="utf-8", newline="\n").write("\n".join(L))
    print(f"{len(out)} packages; counts {counts}; {len(changes)} change lines")


if __name__ == "__main__":
    main()
