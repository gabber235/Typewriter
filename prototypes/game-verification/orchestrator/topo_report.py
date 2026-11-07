#!/usr/bin/env python3
"""Aggregates topo run rows (one or more topo.jsonl or h.jsonl files) into the tables for RESULTS.md."""
import collections, json, statistics, sys


def rows(paths):
    for p in paths:
        for line in open(p):
            r = json.loads(line)
            k = r.get("kind", "")
            if k in ("run", "topo-run") or (k == "topo-run"):
                yield r
            elif k in ("setup", "topo-setup"):
                yield r


def med(v):
    v = [x for x in v if x is not None]
    return round(statistics.median(v), 3) if v else None


def main(paths):
    runs, setups = [], []
    for r in rows(paths):
        (runs if r["kind"].endswith("run") else setups).append(r)
    by = collections.defaultdict(list)
    for r in runs:
        by[(r["restart_share"], r["mix"], r["topo"])].append(r)
    print("| restarts | group mix | topo | runs | wall s (each) | p50 ms | p95 ms | normal done s | wrong | peak used GB | busy vCPU | cpu |")
    print("|---|---|---|---|---|---|---|---|---|---|---|---|")
    for key in sorted(by):
        rs = by[key]
        print(f"| {key[0]} | {key[1]} | {key[2]} | {len(rs)} | {med([r['wall_s'] for r in rs])} ({', '.join(str(r['wall_s']) for r in rs)}) | "
              f"{med([r['req_s']['p50'] * 1000 for r in rs])} | {med([r['req_s']['p95'] * 1000 for r in rs])} | {med([r['normal_end_s'] for r in rs])} | "
              f"{sum(r['wrong'] for r in rs)} of {sum(r['n'] for r in rs)} | {med([(r['peak_used_mb'] or 0) / 1024 for r in rs])} | "
              f"{med([r['busy_vcpu'] for r in rs])} | {sorted({r.get('cpu') for r in rs})} |")
    print()
    print("Overhead of B against A, paired per job (same runner, same seed):")
    pairs = collections.defaultdict(list)
    for r in runs:
        pairs[(r.get("label"), r["restart_share"], r["mix"])].append(r)
    agg = collections.defaultdict(list)
    for (label, share, mix), rs in sorted(pairs.items(), key=str):
        t = {r["topo"]: r for r in rs}
        if "A" in t and "B" in t:
            o = (t["B"]["wall_s"] / t["A"]["wall_s"] - 1) * 100
            on = (t["B"]["normal_end_s"] / t["A"]["normal_end_s"] - 1) * 100 if t["A"]["normal_end_s"] else None
            agg[(share, mix)].append((o, on))
            print(f"  {label} restarts {share} mix {mix}: wall A {t['A']['wall_s']} B {t['B']['wall_s']} -> {o:+.1f} %; normal done {on:+.1f} %")
    print()
    for k, v in sorted(agg.items()):
        print(f"  restarts {k[0]} mix {k[1]}: median {med([x[0] for x in v])} % (range {min(x[0] for x in v):.1f} to {max(x[0] for x in v):.1f}); normal done median {med([x[1] for x in v])} %")
    print()
    for r in runs:
        print(r.get("label"), r["topo"], r["restart_share"], r["mix"], "lostQ", r["lost_quiet_ms_total"], "lostAck", r["lost_ack_ms_total"],
              "ownQ", r["own_quiet_ms_total"], "moves", r.get("move_each_s"), "restart", r.get("restart_s"), "boot", r.get("restart_boot_s"),
              "async", r.get("async_s"), "group", r.get("group_s"), "single", r.get("single_s"), "errors", r["errors"], "rss", r["peak_rss_mb"])
    for s in setups:
        print("setup", s.get("label"), s.get("topo"), json.dumps(s.get("boot")), s.get("cpu"))


if __name__ == "__main__":
    main(sys.argv[1:])
