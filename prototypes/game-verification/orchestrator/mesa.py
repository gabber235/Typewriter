#!/usr/bin/env python3
"""proto/gv-goldens: determinism of golden frames per Mesa source, over saved f-goldens session dirs.

  mesa.py DIR [DIR ...] [--out runs/mesa-analysis.json]

A dir is one client session from goldens.py (meta.json plus PNGs). The label's first part names the
Mesa source: x86_64nix (devenv, Mesa 26.2.5), x86_64apt (Ubuntu apt, this branch's code) or
x86_64 (spike F's run 42118497980, Ubuntu Mesa 25.2.8).
"""
import argparse, hashlib, itertools, json, pathlib, statistics, sys
from collections import defaultdict

import numpy as np
from PIL import Image

SOURCES = {"x86_64nix": "nix 26.2.5", "x86_64apt": "apt (this run)", "x86_64": "apt 25.2.8 (spike F)", "aarch64": "arm 25.2.8 (spike F)"}


def scene_of(kind, name):
    if kind == "session":
        if name.startswith("all-") or name == "regions-ref":
            return "void"
        if name.startswith("break-"):
            return "break-" + name.split("-")[1]
        return None
    if name.startswith("terrain-all-"):
        return "terrain"
    return None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("dirs", nargs="+")
    ap.add_argument("--out", default="runs/mesa-analysis.json")
    a = ap.parse_args()
    frames = []  # (source, backend, cpu, job, client, scene, name, path)
    renderers = defaultdict(set)
    timing = defaultdict(list)
    for d in map(pathlib.Path, a.dirs):
        mf = d / "meta.json"
        if not mf.exists():
            continue
        meta = json.loads(mf.read_text())
        arch, backend, cpu, job, client = meta["label"].split("-")
        src = SOURCES.get(arch, arch)
        r = meta.get("renderer") or {}
        renderers[(src, backend)].add(f"{r.get('gpu')} | {r.get('driver')}")
        for run in meta["runs"]:
            sc = scene_of(meta["kind"], run["name"])
            if sc is None:
                continue
            frames.append((src, backend, cpu, job, f"{job}-{client}", sc, run["name"], d / f"{run['name']}.png"))
            if sc in ("void", "terrain"):
                timing[(src, backend, sc)].append((run["settle_s"] + run["grab_ms"] / 1000, run["grabs"], run["stable"]))

    cache = {}

    def img(p):
        if p not in cache:
            cache[p] = np.asarray(Image.open(p).convert("RGB"), dtype=np.int16)
        return cache[p]

    def h(p):
        return hashlib.sha256(img(p).tobytes()).hexdigest()[:12]

    def diff(p, q):
        d = np.abs(img(p) - img(q)).max(axis=2)
        return int((d > 0).sum()), int(d.max()), int((d > 8).sum())

    out = {"renderers": {f"{k[0]} / {k[1]}": sorted(v) for k, v in renderers.items()}}

    # Distinct hashes per golden scene, and identical pairs by class
    groups = defaultdict(list)
    for f in frames:
        groups[(f[0], f[1], f[5])].append(f)
    det = []
    for (src, backend, sc), fs in sorted(groups.items()):
        hashes = defaultdict(list)
        for f in fs:
            hashes[h(f[7])].append(f)
        classes = defaultdict(lambda: [0, 0, 0])  # pairs, fired, max pixels
        for x, y in itertools.combinations(fs, 2):
            c = "same client" if x[4] == y[4] else "fresh client, same job" if x[3] == y[3] else "same CPU model, other job" if x[2] == y[2] else "other CPU model"
            px = 0 if h(x[7]) == h(y[7]) else diff(x[7], y[7])[0]
            classes[c][0] += 1
            classes[c][1] += px > 0
            classes[c][2] = max(classes[c][2], px)
        det.append({"source": src, "backend": backend, "scene": sc, "frames": len(fs), "jobs": len({f[3] for f in fs}), "clients": len({f[4] for f in fs}),
                    "cpus": sorted({f[2] for f in fs}), "hashes": {k: len(v) for k, v in hashes.items()},
                    "hash_by_cpu": {cpu: sorted({h(f[7]) for f in fs if f[2] == cpu}) for cpu in sorted({f[2] for f in fs})},
                    "pairs": {k: {"pairs": v[0], "fired": v[1], "max_px": v[2]} for k, v in classes.items()}})
    out["determinism"] = det

    # Breaks: every break frame against every void golden of its own source and backend
    brk = []
    for (src, backend, sc), fs in sorted(groups.items()):
        if not sc.startswith("break-"):
            continue
        goldens = groups.get((src, backend, "void"), [])
        px = [diff(g[7], f[7])[0] for f in fs for g in goldens]
        if px:
            brk.append({"source": src, "backend": backend, "break": sc[6:], "comparisons": len(px), "caught": sum(p > 0 for p in px), "px_min": min(px), "px_max": max(px)})
    out["breaks"] = brk

    # Across sources and backends: one representative frame per group
    rep = {k: v[0][7] for k, v in groups.items()}
    cross = []
    keys = sorted(rep)
    for x, y in itertools.combinations(keys, 2):
        if x[2] != y[2] or x[2].startswith("break-"):
            continue
        px, mx, o8 = diff(rep[x], rep[y])
        cross.append({"a": f"{x[0]} {x[1]}", "b": f"{y[0]} {y[1]}", "scene": x[2], "px": px, "max": mx, "over8": o8})
    out["cross"] = cross

    out["capture"] = []
    for (src, backend, sc), v in sorted(timing.items()):
        t = sorted(x[0] for x in v)
        out["capture"].append({"source": src, "backend": backend, "scene": sc, "n": len(t), "median_s": round(statistics.median(t), 3), "p90_s": round(t[int(len(t) * 0.9) - 1], 3), "max_s": round(t[-1], 3),
                               "grabs_median": statistics.median(x[1] for x in v), "unstable": sum(not x[2] for x in v)})
    pathlib.Path(a.out).write_text(json.dumps(out, indent=1))
    for k in ("renderers",):
        print(json.dumps(out[k], indent=1))
    for r in det:
        print(f"{r['source']:22} {r['backend']:7} {r['scene']:14} frames {r['frames']:3} jobs {r['jobs']} clients {r['clients']:2} cpus {len(r['cpus'])} hashes {len(r['hashes'])} pairs {r['pairs']}")
    for r in brk:
        print(f"break {r['source']:22} {r['backend']:7} {r['break']:8} caught {r['caught']}/{r['comparisons']} px {r['px_min']}..{r['px_max']}")
    for r in cross:
        print(f"cross {r['scene']:8} {r['a']:30} vs {r['b']:30} px {r['px']} max {r['max']} over8 {r['over8']}")
    for r in out["capture"]:
        print(f"capture {r}")


if __name__ == "__main__":
    main()
