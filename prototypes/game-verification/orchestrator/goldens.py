#!/usr/bin/env python3
"""Spike F: can golden frames be stable enough to catch small real changes without false alarms.

  goldens.py session [--label mac-a] [--runs 3] [--backend opengl]   one fresh client: knob sets, breaks, regions
  goldens.py terrain [--label mac-t] [--runs 3]                      one fresh client in the default world
  goldens.py analyse DIR [DIR ...] [--out runs/f-analysis.json]      every comparison over saved frames

A run is one requirement's golden: reset, some time passes, knobs, arrange the scene, render barrier,
grab. Frames are saved as RGB PNG (lossless), so any later comparison sees exactly what the client drew.
The client launches through speed.Session (direct java, silent options, zero volume asserted).
"""
import argparse, itertools, json, math, os, pathlib, random, shutil, sys, time

import numpy as np
from PIL import Image

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import speed
from run import RUNS, leak_check

OUT = RUNS / "f-goldens"
RESULTS = RUNS / "f-goldens.jsonl"
W, H = 854, 480
HOTBAR = "244,436,608,480"  # hotbar in framebuffer pixels at 854x480, GUI scale 2

# The scene a golden requirement would name. Breaks change exactly one thing.
SCENE = dict(title="Quest Complete", color="FFAA00", chat="Golden chat line", zx=-1.5, block="STONE", dy=0.0,
             items=",DIAMOND,IRON_INGOT,BREAD,OAK_LOG,REDSTONE,EXPERIENCE_BOTTLE,,")
BREAKS = {
    "text": dict(title="Quest Completa"),
    "color10": dict(color="FFA000"),
    "color3": dict(color="FFA700"),
    "dy1px": dict(dy=0.5),
    "block": dict(block="ANDESITE"),
    "entity": dict(zx=-1.25),
    "item": dict(items=",DIAMOND,IRON_INGOT,,OAK_LOG,REDSTONE,EXPERIENCE_BOTTLE,,"),
}
REGION_OF = {"text": "title", "color10": "title", "color3": "title", "dy1px": "title", "block": "block", "entity": "entity", "item": "item"}

KNOBS = ["gate", "freeze", "anim0", "flicker", "pin", "early", "vignette", "bob", "glint", "hud"]
SETS = {"all": set(KNOBS), **{f"no-{k}": set(KNOBS) - {k} for k in KNOBS}, "none": set()}


def record(row):
    RUNS.mkdir(exist_ok=True)
    row = {"at": time.strftime("%Y-%m-%dT%H:%M:%S"), "load": os.getloadavg()[0], **row}
    with RESULTS.open("a") as f:
        f.write(json.dumps(row) + "\n")
    print(json.dumps(row)[:400], flush=True)


# ---------- sessions ----------

class GPaper(speed.TunedPaper):
    def setup(self):
        super().setup()
        props = self.dir / "server.properties"
        props.write_text(props.read_text() + "level-seed=20261105\n")


def mac_session(label, world, rd):
    s = speed.Session(label, dispatch="tick", rd=rd)
    old = s.server
    s.server = GPaper(old.dir, tuned=True, view=max(3, rd), world=world, xmx=old.xmx, extra_jvm=old.extra_jvm)
    s.client.window_clear = "0x2000"  # true 854x480 framebuffer on a high density screen
    return s


SESSION = mac_session  # ci.py replaces this with one that runs under Xvfb on the runner's renderer


class Golden:
    def __init__(self, s, out):
        self.s, self.S, self.C, self.p = s, s.S, s.C, s.p
        self.out = out
        self.ping = 900000 + random.randrange(1000) * 1000

    def barrier(self):
        self.ping += 1
        self.S("noop", player=self.p, ping=self.ping)
        self.C("state", ping=self.ping, timeoutMs=5000)

    def off(self):
        self.C("g.knobs", freeze=0, pin="NaN", flicker=0, vignette=1, bob=1, glint=0.5, titleDy=0)
        self.C("gate", mode=2)

    def knobs(self, ks, scene):
        if "freeze" in ks and "early" in ks:
            self.freeze(ks)
        self.C("g.knobs", flicker=int("flicker" in ks), pin="1.0" if "pin" in ks else "NaN",
               vignette=int("vignette" not in ks), bob=int("bob" not in ks), glint=0 if "glint" in ks else 0.5, hud=int("hud" in ks), titleDy=scene["dy"])
        self.C("gate", mode=2 if "gate" in ks else 0)

    def freeze(self, ks):
        self.C("g.knobs", freeze=1)
        time.sleep(0.15)  # the client applies a freeze at its next tick; one more texture tick can run before it
        if "anim0" in ks:
            self.C("g.knobs", anim0=1)

    def arrange(self, sc):
        S, p = self.S, self.p
        S("ttl", player=p, text=sc["title"], color=sc["color"], stay=4000)
        S("say", player=p, text=sc["chat"])
        S("ghotbar", player=p, items=sc["items"], held=0)
        self.zombie = S("pzombie", player=p, x=sc["zx"], y=65, z=6.5, yaw=180)["id"]
        S("block", player=p, x=1, y=66, z=9, material=sc["block"], fake=1)
        self.barrier()

    def settle(self, max_s):
        """Render barrier: grab until two frames in a row are identical, or give up at max_s."""
        t0 = time.time()
        self.C("g.grab", frames=4, slot="ga")
        n = 1
        while True:
            self.C("g.grab", frames=2, slot="gb")
            n += 1
            same = self.C("g.same", a="ga", b="gb", thr=0)["count"] == 0
            if same or time.time() - t0 > max_s:
                return {"stable": same, "grabs": n, "settle_s": round(time.time() - t0, 3)}
            self.C("g.grab", frames=2, slot="ga")
            n += 1
            same = self.C("g.same", a="ga", b="gb", thr=0)["count"] == 0
            if same or time.time() - t0 > max_s:
                return {"stable": same, "grabs": n, "settle_s": round(time.time() - t0, 3)}

    def run(self, name, ks, scene, world="void"):
        t0 = time.time()
        self.off()
        self.S("arena", player=self.p)
        self.S("gscene" if world == "void" else "gterrain", player=self.p)
        jitter = random.uniform(0.2, 1.0)
        time.sleep(jitter)  # stands for whatever ran before this requirement
        self.knobs(ks, scene)
        if world == "void":
            self.arrange(scene)
        else:
            self.barrier()
        if "freeze" in ks and "early" not in ks:
            time.sleep(random.uniform(0.2, 1.0))
            self.freeze(ks)
        st = self.settle(2.5 if "freeze" in ks else 1.0)
        raw = self.out / f"{name}.rgba"
        g = self.C("g.grab", frames=1, path=str(raw))
        png = save_png(raw)
        row = {"name": name, "knobs": sorted(ks), "jitter_s": round(jitter, 2), **st, "grab_ms": g["grabMs"], "write_ms": g.get("writeMs"),
               "png_bytes": png.stat().st_size, "run_s": round(time.time() - t0, 2)}
        return row

    def regions(self):
        """Boxes the requirement names, from A4 on the golden scene itself. vis resets the pin, so knobs are reapplied after."""
        S, p = self.S, self.p
        out = {}
        out["title"] = self.C("vis", kind="text", needle="Quest", settle=1)
        out["entity"] = self.C("vis", kind="entity", id=self.zombie, settle=1)
        out["item"] = self.C("vis", kind="item", id="minecraft:bread", rect=HOTBAR, settle=1)
        out["block"] = self.C("vis", kind="block", x=1, y=66, z=9, settle=1)
        return {k: {"bbox": v["bbox"], "count": v["count"], "hits": v["hits"]} for k, v in out.items()}


def save_png(raw):
    a = np.fromfile(raw, dtype=np.uint8).reshape(H, W, 4)[::-1, :, :3]
    path = raw.with_suffix(".png")
    Image.fromarray(np.ascontiguousarray(a)).save(path, optimize=True)
    raw.unlink()
    return path


def wait_join_settle(g, seconds=10, prep_scene=True):
    """Frames change for about 9 s after join (spike A); wait it out before the first golden."""
    g.S("gprep", player=g.p)
    if prep_scene:
        # A new floor gets its light a few ticks after the frame barrier passes (151 pixels, 1 level, first run only).
        g.S("gscene", player=g.p)
    time.sleep(3)
    g.C("g.knobs", hud=1)
    ev = g.s.client.events()["first_world_frame"]
    left = seconds - (time.time() - ev["at"] / 1e6)
    if left > 0:
        time.sleep(left)


def cmd_session(a):
    out = OUT / f"{a.label}-{int(time.time())}"
    out.mkdir(parents=True, exist_ok=True)
    with SESSION(f"f-{a.label}", "void", 2) as s:
        g = Golden(s, out)
        wait_join_settle(g)
        meta = {"label": a.label, "dir": str(out), "renderer": s.client.events().get("renderer"), "kind": "session"}
        rows = []
        sets = list(SETS) if not a.sets else a.sets.split(",")
        for i in range(a.runs):
            for name in sets:
                rows.append(g.run(f"{name}-{i}", SETS[name], SCENE))
        for i in range(a.break_runs):
            for b, change in BREAKS.items():
                rows.append(g.run(f"break-{b}-{i}", SETS["all"], {**SCENE, **change}))
        rows.append(g.run("regions-ref", SETS["all"], SCENE))
        regions = g.regions()
        g.off()
    (out / "meta.json").write_text(json.dumps({**meta, "regions": regions, "runs": rows}, indent=1))
    record({**meta, "regions": regions, "runs": len(rows), "settle": summary([r["settle_s"] for r in rows]), "unstable": [r["name"] for r in rows if not r["stable"]]})
    return out


def cmd_terrain(a):
    out = OUT / f"{a.label}-{int(time.time())}"
    out.mkdir(parents=True, exist_ok=True)
    with SESSION(f"f-{a.label}", "default", 5) as s:
        g = Golden(s, out)
        wait_join_settle(g, 12, prep_scene=False)
        meta = {"label": a.label, "dir": str(out), "renderer": s.client.events().get("renderer"), "kind": "terrain"}
        rows = []
        for i in range(a.runs):
            for name in ("all", "none"):
                rows.append(g.run(f"terrain-{name}-{i}", SETS[name], SCENE, world="default"))
        g.off()
    (out / "meta.json").write_text(json.dumps({**meta, "runs": rows}, indent=1))
    record({**meta, "runs": len(rows), "unstable": [r["name"] for r in rows if not r["stable"]]})
    return out


def summary(v):
    v = sorted(v)
    return {"min": v[0], "median": v[len(v) // 2], "max": v[-1]} if v else None


# ---------- comparison ----------

def load(path):
    return np.asarray(Image.open(path).convert("RGB"), dtype=np.int16)


def box(a, r):
    """Mean over an r x r window, same size, edges by the valid part (cumulative sums)."""
    pad = r // 2
    p = np.pad(a, [(pad, pad), (pad, pad)] + [(0, 0)] * (a.ndim - 2), mode="edge").astype(np.float64)
    c = p.cumsum(0).cumsum(1)
    c = np.pad(c, [(1, 0), (1, 0)] + [(0, 0)] * (a.ndim - 2))
    s = c[r:, r:] - c[:-r, r:] - c[r:, :-r] + c[:-r, :-r]
    return s / (r * r)


def ssim_min(a, b, r=7):
    la = (0.299 * a[..., 0] + 0.587 * a[..., 1] + 0.114 * a[..., 2])
    lb = (0.299 * b[..., 0] + 0.587 * b[..., 1] + 0.114 * b[..., 2])
    c1, c2 = (0.01 * 255) ** 2, (0.03 * 255) ** 2
    ma, mb = box(la, r), box(lb, r)
    va, vb, cov = box(la * la, r) - ma * ma, box(lb * lb, r) - mb * mb, box(la * lb, r) - ma * mb
    s = ((2 * ma * mb + c1) * (2 * cov + c2)) / ((ma * ma + mb * mb + c1) * (va + vb + c2))
    return float(s.min()), float(s.mean())


def metrics(a, b, rect=None):
    if rect is not None:
        x0, y0, x1, y1 = rect
        a, b = a[y0:y1, x0:x1], b[y0:y1, x0:x1]
    d = np.abs(a - b).max(axis=2)
    bd = np.abs(box(a, 3) - box(b, 3)).max(axis=2)
    smin, smean = ssim_min(a, b)
    return {"exact": int((d > 0).sum()), "max": int(d.max()), "t2": int((d > 2).sum()), "t8": int((d > 8).sum()), "t16": int((d > 16).sum()),
            "t32": int((d > 32).sum()), "blur8": int((bd > 8).sum()), "blur4": int((bd > 4).sum()), "ssim_min": round(smin, 5), "ssim_mean": round(smean, 6)}


# A method says "different" when its rule fires. Thresholds are fixed up front, not tuned per break.
METHODS = {
    "exact": lambda m: m["exact"] > 0,
    "t8": lambda m: m["t8"] > 0,
    "t8>20": lambda m: m["t8"] > 20,
    "t16>20": lambda m: m["t16"] > 20,
    "blur4": lambda m: m["blur4"] > 0,
    "blur8": lambda m: m["blur8"] > 0,
    "ssim<0.99": lambda m: m["ssim_min"] < 0.99,
}


def machine(lbl):
    """mac-* or the ci.py label arch-backend-cpu-runrepeat-kind."""
    if lbl.startswith("mac"):
        return {"arch": "mac", "backend": "metal-gl", "cpu": "m1max", "job": "mac"}
    arch, backend, cpu, job, _ = lbl.split("-")
    return {"arch": arch, "backend": backend, "cpu": cpu, "job": job}


def pair_class(l1, l2):
    a, b = machine(l1), machine(l2)
    if a["job"] == b["job"]:
        return "fresh client, same machine" if a["backend"] == b["backend"] else "GL vs VK, same runner"
    if "mac" in (a["arch"], b["arch"]):
        return "mac vs linux"
    if a["arch"] != b["arch"]:
        return f"arm vs x86, {a['backend']}" if a["backend"] == b["backend"] else "arm vs x86, other backend"
    if a["backend"] != b["backend"]:
        return "other runner, other backend"
    return f"{a['arch']} {a['backend']}, same CPU model" if a["cpu"] == b["cpu"] else f"{a['arch']} {a['backend']}, other CPU model"


def grow(bbox, margin=4):
    x0, y0, x1, y1 = bbox
    return [max(0, x0 - margin), max(0, y0 - margin), min(W, x1 + 1 + margin), min(H, y1 + 1 + margin)]


def cmd_analyse(a):
    dirs = [pathlib.Path(d) for d in a.dirs]
    metas = {d: json.loads((d / "meta.json").read_text()) for d in dirs if (d / "meta.json").exists()}
    out = {"pairs": [], "cost": {}, "sizes": {}}
    cache = {}

    def img(d, name):
        k = (d, name)
        if k not in cache:
            cache[k] = load(d / f"{name}.png")
        return cache[k]

    def label(d):
        return metas[d]["label"]

    def add(kind, d1, n1, d2, n2, rect=None, region=None, extra=None):
        m = metrics(img(d1, n1), img(d2, n2), rect)
        row = {"kind": kind, "a": f"{label(d1)}/{n1}", "b": f"{label(d2)}/{n2}", "region": region, "class": pair_class(label(d1), label(d2)), **m, **(extra or {})}
        row["alarm"] = {k: f(m) for k, f in METHODS.items()}
        out["pairs"].append(row)

    sess = [d for d in dirs if metas.get(d, {}).get("kind") == "session"]
    terr = [d for d in dirs if metas.get(d, {}).get("kind") == "terrain"]
    for d in sess:
        names = {r["name"] for r in metas[d]["runs"]}
        regions = {k: grow(v["bbox"]) for k, v in metas[d]["regions"].items() if v["count"] > 0}
        # F2: within one client, each knob set against itself
        for s in SETS:
            runs = sorted(n for n in names if n.rsplit("-", 1)[0] == s)
            for x, y in itertools.combinations(runs, 2):
                add("within", d, x, d, y, extra={"set": s})
        refs = sorted(n for n in names if n.startswith("all-")) + ["regions-ref"]
        for x, y in itertools.combinations(refs, 2):
            for reg, rect in regions.items():
                add("within-region", d, x, d, y, rect, reg, extra={"set": "all"})
        # breaks against this client's goldens
        for n in sorted(n for n in names if n.startswith("break-")):
            b = n.split("-")[1]
            for r in refs:
                add("break", d, r, d, n, extra={"break": b})
                if REGION_OF[b] in regions:
                    add("break-region", d, r, d, n, regions[REGION_OF[b]], REGION_OF[b], extra={"break": b})
    # F1 and F4: goldens of one client against another client's (fresh client, other machine, other renderer)
    for d1, d2 in itertools.combinations(sess, 2):
        regions = {k: grow(v["bbox"]) for k, v in metas[d1]["regions"].items() if v["count"] > 0}
        for n in ("all-0", "regions-ref"):
            add("across", d1, n, d2, n, extra={"set": "all"})
            for reg, rect in regions.items():
                add("across-region", d1, n, d2, n, rect, reg, extra={"set": "all"})
        for b in BREAKS:
            add("break-across", d1, "all-0", d2, f"break-{b}-0", extra={"break": b})
            if REGION_OF[b] in regions:
                add("break-across-region", d1, "all-0", d2, f"break-{b}-0", regions[REGION_OF[b]], REGION_OF[b], extra={"break": b})
    for d in terr:
        names = sorted(r["name"] for r in metas[d]["runs"])
        for s in ("all", "none"):
            runs = [n for n in names if n.startswith(f"terrain-{s}-")]
            for x, y in itertools.combinations(runs, 2):
                add("terrain-within", d, x, d, y, extra={"set": s})
    for d1, d2 in itertools.combinations(terr, 2):
        add("terrain-across", d1, "terrain-all-0", d2, "terrain-all-0", extra={"set": "all"})
    # cost and size
    if sess:
        d = sess[0]
        a0, b0 = img(d, "all-0"), img(d, "break-text-0")
        regions = {k: grow(v["bbox"]) for k, v in metas[d]["regions"].items() if v["count"] > 0}
        for name, fn in (("exact", lambda x, y: int((x != y).any(axis=2).sum())), ("t8", lambda x, y: int((np.abs(x - y).max(axis=2) > 8).sum())),
                         ("blur", lambda x, y: int((np.abs(box(x, 3) - box(y, 3)).max(axis=2) > 4).sum())), ("ssim", lambda x, y: ssim_min(x, y)), ("all metrics", metrics)):
            t0 = time.perf_counter()
            for _ in range(10):
                fn(a0, b0)
            full = (time.perf_counter() - t0) / 10 * 1000
            x0, y0, x1, y1 = regions.get("title", [0, 0, W, H])
            t0 = time.perf_counter()
            for _ in range(10):
                fn(a0[y0:y1, x0:x1], b0[y0:y1, x0:x1])
            out["cost"][name] = {"full_ms": round(full, 2), "title_region_ms": round((time.perf_counter() - t0) / 10 * 1000, 3)}
        t0 = time.perf_counter()
        load(d / "all-0.png")
        out["cost"]["png_decode_ms"] = round((time.perf_counter() - t0) * 1000, 2)
        for d in sess:
            regions = {k: grow(v["bbox"]) for k, v in metas[d]["regions"].items() if v["count"] > 0}
            full = (d / "all-0.png").stat().st_size
            crops = {}
            im = Image.open(d / "all-0.png")
            for k, (x0, y0, x1, y1) in regions.items():
                p = d / f"crop-{k}.png"
                im.crop((x0, y0, x1, y1)).save(p, optimize=True)
                crops[k] = {"bytes": p.stat().st_size, "box": [x0, y0, x1, y1]}
            out["sizes"][label(d)] = {"full_png": full, "crops": crops}
        for d in terr:
            out["sizes"][label(d)] = {"full_png": (d / "terrain-all-0.png").stat().st_size}
    pathlib.Path(a.out).write_text(json.dumps(out, indent=1))
    report(out)


def report(out):
    from collections import defaultdict
    groups = defaultdict(list)
    for r in out["pairs"]:
        key = (r["kind"], r.get("set") or r.get("break"), r.get("region"), r["class"] if r["kind"].endswith(("across", "across-region")) else "")
        groups[key].append(r)
    for key in sorted(groups, key=lambda k: tuple(str(x) for x in k)):
        rs = groups[key]
        ex = [r["exact"] for r in rs]
        t8 = [r["t8"] for r in rs]
        mx = [r["max"] for r in rs]
        ss = [r["ssim_min"] for r in rs]
        al = {k: sum(r["alarm"][k] for r in rs) for k in METHODS}
        print(f"{key[0]:20} {str(key[1]):10} {str(key[2]):7} {key[3]:28} n={len(rs):3} exact {min(ex)}..{max(ex)} max {min(mx)}..{max(mx)} t8 {min(t8)}..{max(t8)} ssim {min(ss):.4f}..{max(ss):.4f} fired {al}")
    print(json.dumps(out["cost"]))
    print(json.dumps(out["sizes"]))


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    s = sub.add_parser("session")
    s.add_argument("--label", default="mac")
    s.add_argument("--runs", type=int, default=3)
    s.add_argument("--break-runs", type=int, default=2)
    s.add_argument("--sets", default="")
    t = sub.add_parser("terrain")
    t.add_argument("--label", default="mac-terrain")
    t.add_argument("--runs", type=int, default=3)
    n = sub.add_parser("analyse")
    n.add_argument("dirs", nargs="+")
    n.add_argument("--out", default=str(RUNS / "f-analysis.json"))
    a = ap.parse_args()
    try:
        if a.cmd == "session":
            cmd_session(a)
        elif a.cmd == "terrain":
            cmd_terrain(a)
        else:
            cmd_analyse(a)
    finally:
        if a.cmd != "analyse":
            print("leaks:", leak_check())


if __name__ == "__main__":
    main()
