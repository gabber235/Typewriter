#!/usr/bin/env python3
"""Tables for P11 (perceive without drawing) from one frames.jsonl per job: nodraw_report.py job0/frames.jsonl job1/frames.jsonl ..."""
import collections, json, statistics, sys


def load(path):
    return [json.loads(l) for l in open(path) if l.strip()]


def med(v):
    v = [x for x in v if x is not None]
    return statistics.median(v) if v else None


def fmt(x, nd=1):
    return "-" if x is None else f"{x:.{nd}f}"


def rng(v, nd=1, unit=""):
    v = [x for x in v if x is not None]
    if not v:
        return "-"
    return f"{fmt(med(v), nd)}{unit} ({fmt(min(v), nd)} to {fmt(max(v), nd)})"


def main(paths):
    jobs = [load(p) for p in paths]
    summary = collections.defaultdict(list)
    print("## Per job\n")
    print("| job | cpu | inst | variant | groups | wall s | vs base | wrong/broken | err | a4 asked | tick p50 | client CPU ms per step | perceive per step | draw per step | perceive ms | draw ms | extract ms | nodraw submit/compile/occl ms | busy vCPU | echo p50/p95 | late p50/p95 |")
    print("|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|")
    for j, rows in enumerate(jobs):
        runs = [r for r in rows if r["kind"] == "run"]
        base = collections.defaultdict(list)
        for r in runs:
            if r["variant"] == "base":
                base[(r["inst"], r["mix"])].append(r["wall_s"])
        for r in runs:
            b = med(base[(r["inst"], r["mix"])])
            slow = (r["wall_s"] / b - 1) * 100 if b else None
            fr = r.get("frames") or {}
            nd = fr.get("nodraw_ms") or {}
            tg = r.get("tick_gap_ms") or {}
            e = r.get("echo_ms") or {}
            ls = r.get("late_srv_ms") or {}
            summary[(r["inst"], r["variant"], r["mix"])].append(dict(
                wall=r["wall_s"], slow=slow, wrong=r["wrong"], errors=r["errors"], broken=r["broken"], n=r["n"], tick=tg.get("p50"),
                cpu=r.get("client_cpu_ms_per_step"), pps=(fr.get("perceive") or {}).get("per_step"), dps=(fr.get("draw") or {}).get("per_step"),
                pms=(fr.get("perceive") or {}).get("ms"), dms=(fr.get("draw") or {}).get("ms"), ems=(fr.get("extract") or {}).get("ms"),
                vcpu=r.get("busy_vcpu"), echo50=e.get("p50"), echo95=e.get("p95"), late50=ls.get("p50"), late95=ls.get("p95"),
                a4=r.get("a4_asked"), a4px=(r.get("a4_px") or {}).get("p50"), paper=r["cores"].get("paper")))
            print(f"| {j} | {(r.get('cpu') or '')[:14]} | {r['inst']} | {r['variant']} | {r['mix']} | {r['wall_s']} | {fmt(slow)} % | {r['wrong']}/{r['broken']} | {r['errors']} | {r.get('a4_asked', '-')} | "
                  f"{fmt(tg.get('p50'), 2)} | {fmt(r.get('client_cpu_ms_per_step'), 2)} | {(fr.get('perceive') or {}).get('per_step', '-')} | {(fr.get('draw') or {}).get('per_step', '-')} | "
                  f"{(fr.get('perceive') or {}).get('ms', '-')} | {(fr.get('draw') or {}).get('ms', '-')} | {(fr.get('extract') or {}).get('ms', '-')} | "
                  f"{nd.get('submitNanos', '-')}/{nd.get('compileNanos', '-')}/{nd.get('occlusionNanos', '-')} | {r.get('busy_vcpu')} | "
                  f"{fmt(e.get('p50'))}/{fmt(e.get('p95'))} | {fmt(ls.get('p50'))}/{fmt(ls.get('p95'))} |")
    print("\n## Median over jobs\n")
    print("| inst | variant | groups | jobs | s per 1,000 | vs base | wrong | errors | tick p50 ms | client CPU ms per step | perceive per step | draw per step | perceive ms | draw ms | Paper cores | busy vCPU | echo p50/p95 ms | late p50/p95 ms | a4 asked | a4 px p50 |")
    print("|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|")
    for (inst, v, mix), xs in sorted(summary.items(), key=lambda kv: (kv[0][0], kv[0][2], kv[0][1])):
        g = lambda k: [x[k] for x in xs]
        print(f"| {inst} | {v} | {mix} | {len(xs)} | {rng([w * 1000 / max(1, x['n']) for w, x in zip(g('wall'), xs)])} | {rng(g('slow'), 0, ' %')} | {sum(g('wrong'))} | {sum(g('errors'))} | "
              f"{fmt(med(g('tick')), 2)} | {fmt(med(g('cpu')), 2)} | {fmt(med(g('pps')), 2)} | {fmt(med(g('dps')), 3)} | {fmt(med(g('pms')), 2)} | {fmt(med(g('dms')), 2)} | "
              f"{fmt(med(g('paper')), 2)} | {fmt(med(g('vcpu')), 2)} | {fmt(med(g('echo50')))}/{fmt(med(g('echo95')))} | {fmt(med(g('late50')))}/{fmt(med(g('late95')))} | "
              f"{med(g('a4'))} | {fmt(med(g('a4px')), 0)} |")
    print("\n## Determinism (records until the verdict, per requirement)\n")
    groups = collections.defaultdict(list)
    for j, rows in enumerate(jobs):
        for r in rows:
            if r["kind"] == "run" and r.get("rows") and r["variant"] != "base":
                groups[(r["inst"], r["variant"], r["mix"])].append((j, {row[0]: (row[4], row[1]) for row in r["rows"]}))
    print("| inst | variant | groups | runs | requirements | same counts | same verdict |")
    print("|---|---|---|---|---|---|---|")
    for key, rs in sorted(groups.items()):
        ids = set.intersection(*(set(m) for _, m in rs))
        same = sum(1 for i in ids if len({json.dumps(m[i][0]) for _, m in rs}) == 1)
        samev = sum(1 for i in ids if len({m[i][1] for _, m in rs}) == 1)
        print(f"| {key[0]} | {key[1]} | {key[2]} | {len(rs)} | {len(ids)} | {same} | {samev} |")
    print("\n## Perceive against drawn: the same requirement, the same verdict and records\n")
    for j, rows in enumerate(jobs):
        runs = {}
        for r in rows:
            if r["kind"] == "run" and r.get("rows"):
                runs.setdefault((r["inst"], r["variant"], r["mix"]), r)
        for (inst, v, mix), r in runs.items():
            ref = {"p": "f", "p+a4": "f+a4"}.get(v)
            d = runs.get((inst, ref, mix))
            if not d:
                continue
            a = {row[0]: row for row in d["rows"]}
            b = {row[0]: row for row in r["rows"]}
            ids = set(a) & set(b)
            print(f"- job {j} {inst} {v} against {ref} at {mix}: {len(ids)} requirements, same verdict {sum(1 for i in ids if a[i][1] == b[i][1])}, "
                  f"same records until the verdict {sum(1 for i in ids if a[i][4] == b[i][4])}, same token text "
                  f"{sum(1 for i in ids if [t is not None and t.split('x')[0] for t in a[i][6] or []] == [t is not None and t.split('x')[0] for t in b[i][6] or []])}")


if __name__ == "__main__":
    main(sys.argv[1:])
