#!/usr/bin/env python3
"""Tables from restore rows: restore_report.py <h.jsonl or restore.jsonl> [...]."""
import json, sys


def rows(paths):
    for p in paths:
        for line in open(p):
            r = json.loads(line)
            k = r.get("kind", "")
            if k.startswith("r-"):
                r["kind"] = k[2:]
            yield r


def m(s, key="med"):
    return "" if not s else f"{s[key]}"


def main():
    rs = list(rows(sys.argv[1:]))
    cpu = next((r["machine"]["cpu"] for r in rs if "machine" in r), "?")
    print("CPU:", cpu)
    print("\n## Images\n")
    print("| name | ok | to point s | write s | wall s | cpu s | image MB | refused / failed |")
    print("|---|---|---|---|---|---|---|---|")
    for r in rs:
        if r["kind"] == "image":
            why = r.get("failed") or ""
            ref = "; ".join(r.get("refused", []))[:400]
            print(f"| {r['name']} | {r.get('ok')} | {r.get('to_point_s')} | {r.get('write_s')} | {r.get('wall_s')} | {r.get('cpu_s')} | {r.get('image_mb')} | {why} {ref} {r.get('error', '')} |")
    print("\n## Boot against restore (restart into the same folder, to Done)\n")
    print("| image | kind | n | wall med (p95) | cpu s med | RSS MB | PSS MB |")
    print("|---|---|---|---|---|---|---|")
    for r in rs:
        if r["kind"] == "compare":
            for kind in ("boot", "restore"):
                s = r[kind]
                w = s["wall_s"]
                print(f"| {r['image']} | {kind} | {w['n'] if w else 0} | {m(w)} ({m(w, 'p95')}) | {m(s['cpu_s'])} | {m(s['rss'])} | {m(s['pss'])} |")
    print("\n## Parallel\n")
    print("| image | what | k | all Done s | each s | cpu s | RSS | PSS | memory used MB |")
    print("|---|---|---|---|---|---|---|---|---|")
    for r in rs:
        if r["kind"] == "parallel":
            print(f"| {r['image']} | {r['what']} | {r['k']} | {r['all_done_s']} | {r['each_done_s']} | {r['cpu_s']} | {r['rss']} | {r['pss']} | {r['mem_used_mb']} |")
    print("\n## Restart scenes\n")
    print("| image | point | trials | wrong | wrong by cell | Done med (p95) | ready med (p95) | cpu s | after wrong |")
    print("|---|---|---|---|---|---|---|---|---|")
    for r in rs:
        if r["kind"] == "scenes":
            print(f"| {r['image']} | {r['point']} | {r['trials']} | {r['wrong']} | {r['wrong_by']} | {m(r['done_s'])} ({m(r['done_s'], 'p95')}) | {m(r['ready_s'])} ({m(r['ready_s'], 'p95')}) | {m(r['cpu_s'])} | {r['after_wrong']} |")
    for r in rs:
        if r["kind"] in ("step_failed", "skipped"):
            print("STEP", r["kind"], r.get("step"), (r.get("error") or r.get("why") or "")[:300])


if __name__ == "__main__":
    main()
