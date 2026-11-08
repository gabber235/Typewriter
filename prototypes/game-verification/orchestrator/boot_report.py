#!/usr/bin/env python3
"""Tables from boot.jsonl files: per variant and parallelism, the median over jobs of each job's median, with the
range over jobs, and the change against the baseline measured in the same job (same runner, same CPU).

  boot_report.py runs/boot.jsonl [more.jsonl ...] [--since 2026-11-08T09:00]
"""
import json, statistics, sys
from collections import defaultdict

args = [a for i, a in enumerate(sys.argv[1:], 1) if not a.startswith("--") and sys.argv[i - 1] != "--since"]
since = next((sys.argv[i + 1] for i, a in enumerate(sys.argv) if a == "--since"), "")
rows = []
for path in args:
    for line in open(path):
        r = json.loads(line)
        if r.get("at", "") >= since:
            r["_file"] = path
            rows.append(r)

trials = [r for r in rows if r["kind"] == "trial"]
jobs = defaultdict(list)  # (file, label, variant, par) -> trials
for r in trials:
    jobs[(r["_file"], r["label"], r["variant"], r["par"])].append(r)


def med(v):
    v = [x for x in v if x is not None]
    return statistics.median(v) if v else None


def fmt(v, d=2):
    return "" if v is None else f"{v:.{d}f}"


keys = ["done_s", "ready_s", "state_s", "kill_to_state_s", "paper_cpu_s", "client_cpu_s", "paper_rss_mb", "after_med_ms", "platform_med_ms"]
per_job = {}
for k, rs in jobs.items():
    per_job[k] = {x: med([r.get(x) for r in rs]) for x in keys}
    per_job[k]["n"] = len(rs)
    per_job[k]["wrong"] = sum(r["wrong"] for r in rs)
    per_job[k]["after_wrong"] = sum(r.get("after_wrong", 0) for r in rs)
    per_job[k]["cpu"] = rs[0].get("cpu_model", "")

by_variant = defaultdict(list)
for (f, label, variant, par), m in per_job.items():
    base = per_job.get((f, label, "base", par))
    m = dict(m)
    if base and base["state_s"] and m["state_s"]:
        m["vs_base_state"] = m["state_s"] / base["state_s"] - 1
        m["vs_base_cpu"] = m["paper_cpu_s"] / base["paper_cpu_s"] - 1 if base["paper_cpu_s"] and m["paper_cpu_s"] else None
    by_variant[(variant, par)].append(m)

print("| Variant | Par | Jobs | Trials | Done s | Ready s | State s | Against base | Paper CPU s | CPU against base | Client CPU s | RSS MB | Chat at 200 ms | Platform ms | Wrong |")
print("|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|")
order = ["base", "nocache", "xshareoff", "cdsjoin", "aot", "aotfull", "aotnolink", "aotnojoin", "slim", "c1", "serial", "parallel", "fastjvm", "jar", "cold", "best", "bestcds", "baseq", "bestq"]
for (variant, par) in sorted(by_variant, key=lambda k: (k[1], order.index(k[0]) if k[0] in order else 99)):
    ms = by_variant[(variant, par)]

    def cell(x, d=2, pct=False):
        v = [m.get(x) for m in ms if m.get(x) is not None]
        if not v:
            return ""
        if pct:
            return f"{med(v) * 100:+.0f} % ({min(v) * 100:+.0f} to {max(v) * 100:+.0f})"
        return f"{fmt(med(v), d)} ({fmt(min(v), d)} to {fmt(max(v), d)})" if len(v) > 1 else fmt(v[0], d)
    print(f"| {variant} | {par} | {len(ms)} | {sum(m['n'] for m in ms)} | {cell('done_s')} | {cell('ready_s')} | {cell('state_s')} | {cell('vs_base_state', pct=True)} | "
          f"{cell('paper_cpu_s', 1)} | {cell('vs_base_cpu', pct=True)} | {cell('client_cpu_s', 1)} | {cell('paper_rss_mb', 0)} | {cell('after_med_ms', 0)} | {cell('platform_med_ms', 1)} | "
          f"{sum(m['wrong'] for m in ms)} of {sum(m['n'] for m in ms)}, after {sum(m['after_wrong'] for m in ms)} |")

print()
for r in rows:
    if r["kind"] in ("error", "skipped"):
        print("-", r["kind"], r.get("label"), r.get("variant"), r.get("par"), (r.get("error") or r.get("why") or "")[:300].replace("\n", " "))
    if r["kind"] == "train":
        print("- train", r["variant"], f"{r.get('train_s')} s", f"cache {r.get('cache_mb')} MB", f"create rc {r.get('create_rc')}" if "create_rc" in r else "")
for r in rows:
    if r["kind"] == "summary" and r["par"] > 1:
        print("- par", r["label"], r["variant"], "round wall", r.get("round_wall_s"), "peak used MB", r.get("peak_used_mb"), "peak rss MB", r.get("peak_rss_mb"))
print("CPUs:", sorted({m['cpu'] for m in per_job.values()}))
