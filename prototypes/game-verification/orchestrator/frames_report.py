#!/usr/bin/env python3
"""Tables for the frames spike from one frames.jsonl per job: frames_report.py job0/frames.jsonl job1/frames.jsonl ..."""
import collections, json, statistics, sys


def load(path):
    return [json.loads(l) for l in open(path) if l.strip()]


def med(v):
    v = [x for x in v if x is not None]
    return statistics.median(v) if v else None


def fmt(x, nd=1):
    return "-" if x is None else f"{x:.{nd}f}"


def main(paths):
    jobs = [load(p) for p in paths]
    print("## Per job\n")
    print("| job | cpu | inst | variant | groups | wall s | vs base | wrong/broken | errors | ms per step | tick p50/p95 | Paper cores | client cores (each) | echo p50/p95 ms | late srv p50/p95 ms | records | KB |")
    print("|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|")
    summary = collections.defaultdict(list)
    for j, rows in enumerate(jobs):
        runs = [r for r in rows if r["kind"] == "run"]
        base = collections.defaultdict(list)
        for r in runs:
            if r["variant"] == "base":
                base[(r["inst"], r["mix"])].append(r["wall_s"])
        for r in runs:
            b = med(base[(r["inst"], r["mix"])])
            slow = (r["wall_s"] / b - 1) * 100 if b else None
            summary[(r["inst"], r["variant"], r["mix"])].append((r["wall_s"], slow, r["wrong"], r["errors"]))
            cl = [v for k, v in r["cores"].items() if k != "paper"]
            tg = r.get("tick_gap_ms") or {}
            e = r.get("echo_ms") or {}
            ls = r.get("late_srv_ms") or {}
            print(f"| {j} | {(r.get('cpu') or '')[:14]} | {r['inst']} | {r['variant']} | {r['mix']} | {r['wall_s']} | {fmt(slow)} % | {r['wrong']}/{r['broken']} | {r['errors']} | "
                  f"{r['ms_per_step']} | {fmt(tg.get('p50'), 2)}/{fmt(tg.get('p95'), 2)} | {r['cores'].get('paper')} | {', '.join(fmt(c, 2) for c in cl)} | "
                  f"{fmt(e.get('p50'))}/{fmt(e.get('p95'))} | {fmt(ls.get('p50'))}/{fmt(ls.get('p95'))} | {r['records']} | {r['stream_kb']} |")
    print("\n## Median over jobs\n")
    print("| inst | variant | groups | jobs | wall s median (range) | vs base median (range) | wrong | errors |")
    print("|---|---|---|---|---|---|---|---|")
    for (inst, v, mix), xs in summary.items():
        walls = [x[0] for x in xs]
        slows = [x[1] for x in xs if x[1] is not None]
        print(f"| {inst} | {v} | {mix} | {len(xs)} | {fmt(med(walls))} ({fmt(min(walls))} to {fmt(max(walls))}) | "
              f"{fmt(med(slows))} % ({fmt(min(slows) if slows else None)} to {fmt(max(slows) if slows else None)}) | {sum(x[2] for x in xs)} | {sum(x[3] for x in xs)} |")
    # Determinism: records until the verdict per requirement and member, for the same seed, instance and variant.
    print("\n## Determinism (records until the verdict, per requirement)\n")
    groups = collections.defaultdict(list)
    for j, rows in enumerate(jobs):
        for r in rows:
            if r["kind"] == "run" and r.get("rows") and r["variant"] not in ("base", "fack"):
                groups[(r["inst"], r["variant"], r["mix"])].append((j, {row[0]: (row[4], row[1]) for row in r["rows"]}))
    print("| inst | variant | groups | runs | requirements compared | same counts | same verdict | count histogram |")
    print("|---|---|---|---|---|---|---|---|")
    for key, rs in groups.items():
        ids = set.intersection(*(set(m) for _, m in rs))
        same = sum(1 for i in ids if len({json.dumps(m[i][0]) for _, m in rs}) == 1)
        samev = sum(1 for i in ids if len({m[i][1] for _, m in rs}) == 1)
        hist = collections.Counter(c for i in ids for c in (rs[0][1][i][0] or []))
        print(f"| {key[0]} | {key[1]} | {key[2]} | {len(rs)} | {len(ids)} | {same} | {samev} | {dict(sorted(hist.items()))} |")
    # Smaller window against default: the same text and seen tick for the token.
    print("\n## Window size: what a check reads\n")
    for j, rows in enumerate(jobs):
        runs = {(r["inst"], r["variant"], r["mix"]): r for r in rows if r["kind"] == "run" and r.get("rows")}
        for (inst, v, mix), r in runs.items():
            if not inst.startswith("w="):
                continue
            d = runs.get(("default", v, mix))
            if not d:
                continue
            a = {row[0]: row for row in d["rows"]}
            b = {row[0]: row for row in r["rows"]}
            ids = set(a) & set(b)
            print(f"job {j} {inst} {v} {mix}: {len(ids)} requirements, same verdict {sum(1 for i in ids if a[i][1] == b[i][1])}, "
                  f"same seen ticks {sum(1 for i in ids if a[i][5] == b[i][5])}, same records {sum(1 for i in ids if a[i][4] == b[i][4])}, "
                  f"same token text {sum(1 for i in ids if [t is not None and t.split('x')[0] for t in a[i][6] or []] == [t is not None and t.split('x')[0] for t in b[i][6] or []])}")


if __name__ == "__main__":
    main(sys.argv[1:])
