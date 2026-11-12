#!/usr/bin/env python3
"""Video prototype: a demo rerun records a smooth clip while the runner steps Paper's ticks.

  demo.py run [--label mac] [--fps 30,60] [--cases camera,walk,title,particles,boss,typing] [--reruns 2] [--rt 30,60]
  demo.py report runs/demo-<label>-<t>
  demo.py compare runs/demo-a runs/demo-b      frames of two runs (fresh clients) against each other

One rig: Paper with spike N's step agent, one gated client in lockstep streaming records to a listener. Passes, in
order: gated (one frame per tick, no video, the gated suite), demo at each fps (fps / 20 frames per tick at even
partial ticks, every frame read back to ffmpeg), the first fps again (rerun), then a real time unstepped recording
of the same cases as the smoothness reference. Every case runs good and deliberately broken.
"""
import argparse, collections, hashlib, json, os, pathlib, statistics, subprocess, sys, time

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import n as N
from run import RUNS, leak_check
from stream import Listener

hooks = {"record": None}
RESULTS = RUNS / "demo.jsonl"
TICKS = {"camera": 120, "walk": 64, "title": 80, "particles": 60, "boss": 106, "typing": 50}
TYPED = {False: "/give @s minecraft:diamond_sword 1", True: "/give @s minecraft:diamond_swrod 1"}
MOVING = {"camera", "walk", "particles", "boss"}


def load():
    return round(os.getloadavg()[0], 1)


def record(kind, **row):
    row = {"kind": kind, "at": time.strftime("%Y-%m-%dT%H:%M:%S"), "load": load(), **row}
    RUNS.mkdir(exist_ok=True)
    with RESULTS.open("a") as f:
        f.write(json.dumps(row) + "\n")
    if hooks["record"]:
        hooks["record"]("demo-" + kind, **{k: v for k, v in row.items() if k != "kind"})
    print(json.dumps(row)[:4000], flush=True)


def stat(v, nd=3):
    v = sorted(x for x in v if x is not None)
    if not v:
        return None
    q = lambda p: v[min(len(v) - 1, int(len(v) * p))]
    return {"n": len(v), "mean": round(statistics.mean(v), nd), "med": round(statistics.median(v), nd), "std": round(statistics.pstdev(v), nd),
            "p95": round(q(0.95), nd), "min": round(v[0], nd), "max": round(v[-1], nd)}


# ---------- run ----------

class Driver:
    def __init__(self, rig, out):
        self.rig, self.S, self.C, self.p, self.out = rig, rig.S, rig.C, rig.p, out
        self.rows = []
        self.clear_particles = True

    def steps(self, k):
        return self.rig.steps_run(k, stop_on_seen=False)

    def tidy(self):
        self.S("vd.clear", _dispatch="direct", player=self.p)
        self.C("st.close")
        self.C("clearChat")
        self.C("demo.watch", ids="")
        if self.clear_particles:
            self.C("demo.clearParticles")
        self.steps(12)

    def case(self, pas, name, broken, fps=None):
        """One requirement. pas: gated | demo30 | demo30b | demo60 ..."""
        self.tidy()
        label = f"{pas}:{name}:{int(broken)}"
        t0 = time.perf_counter()
        self.C("st.reset", name=label)
        rec = None
        if fps:
            path = self.out / "videos" / f"{pas}-{name}-{int(broken)}.mp4"
            rec = self.C("rec", path=str(path), fps=fps, mode="all", block=1, demo=1, enc="x264", preset="veryfast", crf=20)
            assert rec.get("ok"), rec
            d = self.C("n.demo", on=1, fps=fps)
            assert d.get("demo"), d
        r = self.S("vd.go", _dispatch="direct", player=self.p, name=name, broken=int(broken))
        if "id" in r:
            self.C("demo.watch", ids=str(r["id"]))
        if name == "typing":
            self.C("st.chat", text=TYPED[broken], enter=1)
        t1 = time.perf_counter()
        st = self.steps(TICKS[name])
        t2 = time.perf_counter()
        stop = None
        demo = None
        if fps:
            demo = self.C("n.demo", on=0)
            stop = self.C("recStop")
        t3 = time.perf_counter()
        row = {"pass": pas, "case": name, "broken": bool(broken), "fps": fps, "go_tick": r["tick"], "ticks": st["steps"], "steps_ms": round(st["wallMicros"] / 1000, 2),
               "ms_per_tick": round(st["wallMicros"] / 1000 / max(1, st["steps"]), 3), "setup_ms": round((t1 - t0) * 1000, 1),
               "stop_ms": round((t3 - t2) * 1000, 1), "req_ms": round((t3 - t0) * 1000, 1), "demo": demo, "rec": stop}
        self.rows.append(row)
        print(json.dumps({k: row[k] for k in ("pass", "case", "broken", "ticks", "ms_per_tick", "req_ms")}), flush=True)
        return row

    def rt_case(self, name, fps):
        """Real time reference: stepping off, Paper at 20 TPS, client drawing freely, video slots on the wall clock."""
        self.S("vd.clear", _dispatch="direct", player=self.p)
        self.C("st.close")
        self.C("demo.watch", ids="")
        self.C("demo.clearParticles")
        time.sleep(0.6)
        path = self.out / "videos" / f"rt{fps}-{name}-0.mp4"
        self.C("rec", path=str(path), fps=fps, mode="rt", enc="x264", preset="veryfast", crf=20)
        t0 = time.perf_counter()
        r = self.S("vd.go", _dispatch="direct", player=self.p, name=name, broken=0)
        if "id" in r:
            self.C("demo.watch", ids=str(r["id"]))
        if name == "typing":
            self.C("st.chat", text=TYPED[False], enter=1)
        time.sleep(TICKS[name] / 20 + 0.2)
        stop = self.C("recStop")
        row = {"pass": f"rt{fps}", "case": name, "broken": False, "fps": fps, "req_ms": round((time.perf_counter() - t0) * 1000, 1), "rec": stop,
               "client_fps": self.C("stats").get("fps")}
        self.rows.append(row)
        print(json.dumps({k: row[k] for k in ("pass", "case", "req_ms", "client_fps")}), flush=True)


def cmd_run(a):
    out = RUNS / f"demo-{a.label}-{int(time.time())}"
    (out / "videos").mkdir(parents=True, exist_ok=True)
    lis = Listener(out)
    cases = [c for c in a.cases.split(",") if c]
    fpss = [int(x) for x in a.fps.split(",") if x]
    meta = {"label": a.label, "machine": a.machine, "load_start": load(), "cases": cases, "fps": fpss, "reruns": a.reruns, "rt": a.rt}
    try:
        with N.Rig(f"demo-{a.label}") as rig:
            d = Driver(rig, out)
            rig.C("in.setup", focus="fake", grab="fake")
            rig.C("gate", mode=2, parkMicros=a.park)
            meta["particles"] = rig.C("demo.particles", level=0)  # the gated client's minimal particles hide every server particle
            rig.step_on()
            rig.steps_run(60, stop_on_seen=False)
            rig.S("vd.set", _dispatch="direct", player=rig.p)
            rig.steps_run(80, stop_on_seen=False)  # chunks resent and meshed
            rig.C("st.on", port=lis.port, a4=0)
            passes = [("gated", None)] + [(f"demo{f}", f) for f in fpss] + [(f"demo{fpss[0]}r{i}", fpss[0]) for i in range(1, a.reruns)]
            for pas, fps in passes:
                for name in cases:
                    for broken in (False, True):
                        d.case(pas, name, broken, fps)
            d.tidy()
            meta["stream_stats"] = rig.C("st.off")
            if a.rt:
                rig.step_off()
                rig.C("gate", mode=0)
                rig.C("fps", limit=260)
                time.sleep(1.0)
                for f in [int(x) for x in a.rt.split(",") if x]:
                    for name in cases:
                        d.rt_case(name, f)
                rig.C("gate", mode=2)
            meta["load_end"] = load()
            (out / "rows.json").write_text(json.dumps(d.rows, indent=1))
            (out / "meta.json").write_text(json.dumps(meta, indent=1))
    finally:
        time.sleep(0.5)
        lis.stop()
    leak_check()
    rep = report(out)
    record("run", label=a.label, dir=str(out), meta=meta, report=rep)


# ---------- analysis ----------

def segments(frames):
    segs, cur, name = {}, [], None
    for f in frames:
        if f["type"] == 3:
            if name:
                segs[name] = cur
            cur, name = [], f["name"]
        elif f["type"] == 1:
            cur.append(f)
    if name:
        segs[name] = cur
    return segs


def title_legible(rec):
    return any(t == "title" and "The Journey Begins" in x for t, x in rec["runs"])


# Requirement per case: (condition on the record of a frame, earliest relative tick, latest relative tick).
REQS = {
    "camera": (lambda r, vx: vx["cam"][3] >= 89.0, 1, 70),
    "walk": (lambda r, vx: any(p[0] >= 3.5 for p in vx.get("ents", {}).values()), 1, 62),
    "title": (lambda r, vx: title_legible(r), 45, 80),
    "particles": (lambda r, vx: vx.get("particles", 0) >= 20, 1, 10),
    "boss": (lambda r, vx: any(b >= 0.99 for b in vx.get("boss", [])), 1, 105),
    "typing": (lambda r, vx: "diamond_sword" in vx.get("slot0", ""), 1, 50),
}


def verdict(case, recs, go):
    """(passed, first relative tick the condition held, records, partial tick of the first record). Tick 1 is the
    first stepped tick after the stimulus (go is the server's tick count when the stimulus ran, between ticks). A
    record holds until the next one: the gated stream sends a record only when the content changed."""
    recs = [r for r in recs if go < r["tick"] <= go + TICKS[case]]
    if not recs:
        return False, None, 0, None
    cond, lo, hi = REQS[case]
    first = None
    for k, r in enumerate(recs):
        t = r["tick"] - go
        until = recs[k + 1]["tick"] - go if k + 1 < len(recs) else TICKS[case] + 1
        if cond(r, r["facts"].get("vx", {})) and max(t, lo) < max(until, t + 1):
            first = max(t, lo)
            break
    passed = first is not None and first <= hi
    return passed, first, len(recs), recs[0]["facts"].get("vx", {}).get("pt")


def load_side(path):
    p = pathlib.Path(str(path) + ".frames.jsonl")
    return [json.loads(l) for l in p.read_text().splitlines() if l.strip()] if p.exists() else []


def decode(path, w, h, half=True):
    import numpy as np
    ww, hh = (w // 2, h // 2) if half else (w, h)
    vf = ["-vf", "scale=iw/2:ih/2:flags=area"] if half else []
    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", str(path), *vf, "-f", "rawvideo", "-pix_fmt", "rgb24", "-"], capture_output=True, check=True).stdout
    n = len(raw) // (ww * hh * 3)
    return np.frombuffer(raw[: n * ww * hh * 3], dtype=np.uint8).reshape(n, hh, ww, 3).astype(np.int16)


def motion_stats(vals, boundary):
    """Per frame motion: evenness and whether frames that start a new tick move more than frames inside a tick."""
    vals = list(vals)
    mv = [v for v in vals if v is not None]
    if len(mv) < 4:
        return None
    med = statistics.median(mv)
    b = [v for v, bd in zip(vals, boundary) if v is not None and bd]
    i = [v for v, bd in zip(vals, boundary) if v is not None and not bd]
    mean = statistics.mean(mv)
    return {"frames": len(mv), "mean": round(mean, 4), "cv": round(statistics.pstdev(mv) / mean, 3) if mean else None,
            "max_over_med": round(max(mv) / med, 2) if med else None, "still": sum(1 for v in mv if v == 0),
            "boundary_over_inside": round(statistics.mean(b) / statistics.mean(i), 3) if b and i and statistics.mean(i) else None}


def window(vals, eps=1e-6, trim=0.2):
    """Index range of the steady part of the motion: from the first to the last frame that moves, without the
    first and last 20 percent (start and stop ramps of interpolation)."""
    idx = [k for k, v in enumerate(vals) if v is not None and abs(v) > eps]
    if not idx:
        return (0, 0)
    lo, hi = idx[0], idx[-1] + 1
    cut = int((hi - lo) * trim)
    return (lo + cut, hi - cut)


def smoothness(case, side):
    """Fact based smoothness of one clip from its sidecar: game time per frame, still frames, motion at tick edges."""
    if len(side) < 4:
        return None
    g = [s["t"] + s["x"]["pt"] for s in side]
    dg = [round(b - a, 5) for a, b in zip(g, g[1:])]
    boundary = [b["t"] != a["t"] for a, b in zip(side, side[1:])]
    crc_same = sum(1 for a, b in zip(side, side[1:]) if a["crc"] == b["crc"])
    if case == "camera":
        def mv(a, b):
            ca, cb = a["x"]["cam"], b["x"]["cam"]
            return ((cb[0] - ca[0]) ** 2 + (cb[1] - ca[1]) ** 2 + (cb[2] - ca[2]) ** 2) ** 0.5
    elif case == "walk":
        def mv(a, b):
            ea, eb = a["x"].get("ents", {}), b["x"].get("ents", {})
            k = next(iter(ea), None)
            return abs(eb[k][0] - ea[k][0]) if k and k in eb else None
    elif case == "boss":
        def mv(a, b):
            return abs(b["x"]["boss"][0] - a["x"]["boss"][0]) if a["x"]["boss"] and b["x"]["boss"] else None
    elif case == "title":
        def mv(a, b):
            return abs(b["x"]["titleAlpha"] - a["x"]["titleAlpha"])
    else:
        mv = None
    res = {"frames": len(side), "game_ticks_per_frame": stat(dg, 4), "zero_game_step": sum(1 for v in dg if v <= 0),
           "dup_slots": sum(1 for s in side if s.get("dup")), "identical_neighbours": crc_same}
    if mv:
        m = [mv(a, b) for a, b in zip(side, side[1:])]
        lo, hi = window(m)
        res["motion_window"] = [lo, hi]
        res["motion"] = motion_stats(m[lo:hi], boundary[lo:hi])
        res["identical_in_motion"] = sum(1 for k in range(lo, hi) if side[k]["crc"] == side[k + 1]["crc"])
    return res


def phase_shift(a, b):
    import numpy as np
    fa, fb = np.fft.fft2(a), np.fft.fft2(b)
    r = fa * np.conj(fb)
    r /= np.abs(r) + 1e-9
    c = np.abs(np.fft.ifft2(r))
    y, x = np.unravel_index(np.argmax(c), c.shape)
    h, w = c.shape
    if y > h // 2:
        y -= h
    if x > w // 2:
        x -= w
    return float(x), float(y)


def pixel_checks(case, video, side, recs_by_df, w, h, other=None):
    """Facts of each frame against what the frame shows."""
    import numpy as np
    fr = decode(video, w, h)
    n = min(len(fr), len(side))
    out = {"decoded": len(fr), "side": len(side)}
    if n < 4:
        return out
    fr = fr[:n]
    side = side[:n]
    gray = fr.mean(axis=3)
    H, W = gray.shape[1:]
    boundary = [False] + [side[k]["t"] != side[k - 1]["t"] for k in range(1, n)]
    if case == "title":
        ref = gray[-1]
        box = (slice(int(H * 0.30), int(H * 0.62)), slice(int(W * 0.12), int(W * 0.88)))
        seen = [(np.abs(gray[k][box] - ref[box]) > 25).sum() > 30 for k in range(n)]
        fact = [title_legible(recs_by_df[s["x"]["df"]]) if s["x"]["df"] in recs_by_df else None for s in side]
        alpha = [s["x"]["titleAlpha"] for s in side]
        dis = [(k, alpha[k], fact[k], bool(seen[k])) for k in range(n) if fact[k] is not None and fact[k] != seen[k]]
        out.update(agree=sum(1 for k in range(n) if fact[k] == seen[k]), frames=n, disagree=len(dis), disagree_alpha=[d[1] for d in dis][:20],
                   fact_only=sum(1 for d in dis if d[2]), pixels_only=sum(1 for d in dis if not d[2]))
    elif case == "boss":
        rgb = decode(video, w, h, half=False)[:n] // 1
        top = rgb[:, : int(h * 0.12), :, :]
        W = w // 2  # bar maths below in GUI pixels: GUI scale 2 at 854x480, so take every other column
        top = top[:, :, ::2, :]
        red = (top[..., 0] > 120) & (top[..., 0] - top[..., 1] > 60) & (top[..., 0] - top[..., 2] > 60)
        cols = red.any(axis=1)  # (n, W)
        x0 = W // 2 - 91
        filled = [int(cols[k, x0: x0 + 183].sum()) for k in range(n)]
        prog = [s["x"]["boss"][0] if s["x"]["boss"] else 0 for s in side]
        expect = [int(p * 183) for p in prog]
        err = [abs(a - b) for a, b in zip(filled, expect)]
        signed = [a - b for a, b in zip(filled, expect)]
        out.update(frames=n, max_err_px=max(err), over_1px=sum(1 for e in err if e > 1), mean_err_px=round(statistics.mean(err), 2),
                   signed_err=dict(collections.Counter(signed)))
    elif case == "walk":
        gray = gray[:, int(H * 0.25): int(H * 0.68), : int(W * 0.68)]  # the path, without the hand and the hotbar
        bg = np.median(gray, axis=0)
        xs, fx = [], []
        key = None
        for k in range(n):
            ents = side[k]["x"].get("ents", {})
            key = key or next(iter(ents), None)
            m = np.abs(gray[k] - bg) > 30
            if m.sum() > 40 and key in ents:
                xs.append(float(np.nonzero(m)[1].mean()))
                fx.append(ents[key][0])
            else:
                xs.append(None)
                fx.append(None)
        pairs = [(a, b) for a, b in zip(xs, fx) if a is not None]
        if len(pairs) > 5:
            r = float(np.corrcoef([p[0] for p in pairs], [p[1] for p in pairs])[0, 1])
            fit = np.polyfit([p[1] for p in pairs], [p[0] for p in pairs], 1)
            res = [abs(p[0] - (fit[0] * p[1] + fit[1])) for p in pairs]
            dx = [None if a is None or b is None else abs(b - a) for a, b in zip(xs, xs[1:])]
            lo, hi = window(dx, eps=0.05)
            out.update(frames=len(pairs), r=round(r, 4), px_per_block=round(float(fit[0]), 2), residual_px_max=round(max(res), 2),
                       residual_px_med=round(statistics.median(res), 2), pixel_motion=motion_stats(dx[lo:hi], boundary[1:][lo:hi]))
    elif case == "camera":
        mad = [None] + [float(np.abs(gray[k] - gray[k - 1]).mean()) for k in range(1, n)]
        dyaw = [None] + [abs(side[k]["x"]["cam"][3] - side[k - 1]["x"]["cam"][3]) for k in range(1, n)]
        lo, hi = window(dyaw[1:], eps=1e-4)
        pairs = [(a, b) for a, b in zip(mad[1:][lo:hi], dyaw[1:][lo:hi])]
        out.update(frames=n, pixel_motion=motion_stats(mad[1:][lo:hi], boundary[1:][lo:hi]),
                   r_mad_vs_dyaw=round(float(np.corrcoef([p[0] for p in pairs], [p[1] for p in pairs])[0, 1]), 3) if len(pairs) > 5 else None)
    elif case == "particles" and other is not None:
        ofr = decode(other, w, h)
        m = min(n, len(ofr))
        og = ofr[:m].mean(axis=3)
        px = [int((np.abs(gray[k] - og[k]) > 30).sum()) for k in range(m)]
        cnt = [side[k]["x"]["particles"] for k in range(m)]
        out.update(frames=m, fact_only=sum(1 for a, b in zip(px, cnt) if b > 0 and a == 0), pixels_only=sum(1 for a, b in zip(px, cnt) if b == 0 and a > 0),
                   agree=sum(1 for a, b in zip(px, cnt) if (a > 0) == (b > 0)))
    elif case == "typing":
        row = (slice(int(H * 0.88), H), slice(0, W))
        pix = [False] + [(np.abs(gray[k][row] - gray[k - 1][row]) > 40).sum() > 3 for k in range(1, n)]
        def screen(k):
            r = recs_by_df.get(side[k]["x"]["df"])
            return None if r is None else tuple(x for t, x in r["runs"] if t in ("screen", "suggestions"))
        sc = [screen(k) for k in range(n)]
        fact = [False] + [sc[k] != sc[k - 1] for k in range(1, n)]
        open_ = [s_["x"]["input"] is not None for s_ in side]
        keep = [k for k in range(1, n) if open_[k] and open_[k - 1]]
        pix = [pix[k] for k in keep]
        fact = [fact[k] for k in keep]
        out.update(frames=n, agree=sum(1 for a, b in zip(pix, fact) if a == b), fact_only=sum(1 for a, b in zip(pix, fact) if b and not a),
                   pixels_only=sum(1 for a, b in zip(pix, fact) if a and not b))
    return out


def timeline(side, recs, fps, go):
    """The clip against the record timeline: one video frame per demo frame, in order, each with its own record
    whose tick is the tick the schedule says."""
    dfs = [s["x"]["df"] for s in side]
    by = {r["facts"]["vx"]["df"]: r for r in recs if r["facts"].get("vx", {}).get("df", -1) >= 0}
    t0 = go + 1
    gaps = sum(1 for a, b in zip(dfs, dfs[1:]) if b != a + 1)
    missing = sum(1 for d in dfs if d not in by)
    wrong_tick = sum(1 for d in dfs if d in by and by[d]["tick"] - t0 != d * 20 // fps)
    wrong_pt = sum(1 for s in side if abs(s["x"]["pt"] - ((s["x"]["df"] * 20) % fps) / fps) > 1e-4)
    return {"frames": len(dfs), "first_df": dfs[0] if dfs else None, "gaps": gaps, "frames_without_record": missing,
            "record_tick_off_schedule": wrong_tick, "partial_off_schedule": wrong_pt, "records": len(recs)}


def report(out):
    out = pathlib.Path(out)
    rows = json.loads((out / "rows.json").read_text())
    meta = json.loads((out / "meta.json").read_text())
    frames = [json.loads(l) for l in (out / "stream.jsonl").read_text().splitlines() if l.strip()]
    segs = segments(frames)
    w, h = 854, 480
    rep = {"meta": meta, "verdicts": {}, "cost": {}, "timeline": {}, "smooth": {}, "pixels": {}, "identical": {}}
    # Verdicts per pass.
    go_of = {f"{r['pass']}:{r['case']}:{int(r['broken'])}": r.get("go_tick") for r in rows}
    for name, recs in segs.items():
        pas, case, broken = name.split(":")
        if go_of.get(name) is None:
            continue
        p, first, n, pt = verdict(case, recs, go_of[name])
        rep["verdicts"].setdefault(f"{case}:{broken}", {})[pas] = {"pass": p, "first_tick": first, "records": n, "pt": pt}
    # Cost per pass.
    by_pass = collections.defaultdict(list)
    for r in rows:
        by_pass[r["pass"]].append(r)
    for pas, rs in by_pass.items():
        ticks = sum(r.get("ticks", 0) for r in rs)
        c = {"requirements": len(rs), "ticks": ticks, "req_ms": stat([r["req_ms"] for r in rs], 1)}
        if ticks:
            c["ms_per_tick"] = round(sum(r["steps_ms"] for r in rs) / ticks, 3)
            c["per_case_ms_per_tick"] = {f"{r['case']}:{int(r['broken'])}": r["ms_per_tick"] for r in rs}
        recs = [r["rec"] for r in rs if r.get("rec")]
        if recs:
            c["frames"] = sum(x["captured"] for x in recs)
            c["issue_us"] = stat([x["issueUsPerCapture"] for x in recs], 1)
            c["callback_us"] = stat([x["callbackUsPerCapture"] for x in recs], 1)
            c["facts_us"] = stat([x.get("factsUsPerCapture") for x in recs], 1)
            c["block_ms"] = sum(x["blockMs"] for x in recs)
            c["encode_tail_ms"] = stat([x["encodeTailMs"] for x in recs], 1)
            c["ffmpeg_cpu_ms"] = sum(x["ffmpegCpuMs"] or 0 for x in recs)
            c["video_bytes"] = sum((out / "videos" / f"{pas}-{r['case']}-{int(r['broken'])}.mp4").stat().st_size for r in rs if (out / "videos" / f"{pas}-{r['case']}-{int(r['broken'])}.mp4").exists())
        if rs and rs[0].get("client_fps") is not None:
            c["client_fps"] = [r["client_fps"] for r in rs]
        rep["cost"][pas] = c
    # Clips.
    for r in rows:
        if not r.get("fps"):
            continue
        pas, case, b = r["pass"], r["case"], int(r["broken"])
        video = out / "videos" / f"{pas}-{case}-{b}.mp4"
        side = load_side(video)
        key = f"{pas}:{case}:{b}"
        rep["smooth"][key] = smoothness(case, side)
        if pas.startswith("demo"):
            recs = segs.get(f"{pas}:{case}:{b}", [])
            rep["timeline"][key] = timeline(side, recs, r["fps"], r["go_tick"])
            if b == 0:
                by = {x["facts"]["vx"]["df"]: x for x in recs if x["facts"].get("vx", {}).get("df", -1) >= 0}
                other = out / "videos" / f"{pas}-{case}-1.mp4" if case == "particles" else None
                try:
                    rep["pixels"][key] = pixel_checks(case, video, side, by, w, h, other)
                except Exception as e:
                    rep["pixels"][key] = {"error": repr(e)}
        elif pas.startswith("rt"):
            try:
                rep["pixels"][key] = pixel_checks(case, video, side, {}, w, h) if case in ("walk", "camera", "boss") else None
            except Exception as e:
                rep["pixels"][key] = {"error": repr(e)}
    # Reruns: the same frames?
    fpss = meta["fps"]
    for i in range(1, meta.get("reruns", 1)):
        a, b = f"demo{fpss[0]}", f"demo{fpss[0]}r{i}"
        for case in meta["cases"]:
            for br in (0, 1):
                rep["identical"][f"{a}~{b}:{case}:{br}"] = same_frames(out / "videos" / f"{a}-{case}-{br}.mp4", out / "videos" / f"{b}-{case}-{br}.mp4")
    (out / "report.json").write_text(json.dumps(rep, indent=1))
    return rep


def same_frames(va, vb):
    sa, sb = load_side(va), load_side(vb)
    if not sa or not sb:
        return None
    n = min(len(sa), len(sb))
    eq = [sa[k]["crc"] == sb[k]["crc"] for k in range(n)]
    diff = [k for k in range(n) if not eq[k]]
    first = diff[0] if diff else None
    norm = lambda x: {**x, "ents": sorted((x.get("ents") or {}).values())}
    facts_eq = sum(1 for k in range(n) if norm(sa[k]["x"]) == norm(sb[k]["x"]))
    res = {"frames": [len(sa), len(sb)], "identical": sum(eq), "first_diff": first, "facts_identical": facts_eq,
           "mp4_identical": hashlib.sha256(pathlib.Path(va).read_bytes()).hexdigest() == hashlib.sha256(pathlib.Path(vb).read_bytes()).hexdigest()}
    if first is not None:
        xa, xb = norm(sa[first]["x"]), norm(sb[first]["x"])
        res["facts_at_first_diff"] = {k: [xa.get(k), xb.get(k)] for k in set(xa) | set(xb) if xa.get(k) != xb.get(k)}
    return res


def cmd_report(a):
    print(json.dumps(report(a.dir), indent=1))


def cmd_compare(a):
    da, db = pathlib.Path(a.a), pathlib.Path(a.b)
    res = {}
    for v in sorted((da / "videos").glob("demo*.mp4")):
        o = db / "videos" / v.name
        if o.exists():
            res[v.stem] = same_frames(v, o)
    print(json.dumps(res, indent=1))
    record("compare", a=str(da), b=str(db), result=res)


def main(argv=None):
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    r = sub.add_parser("run")
    r.add_argument("--label", default="mac")
    r.add_argument("--machine", default="M1 Max, OpenGL 4.1 on Metal, 854x480, gate 2")
    r.add_argument("--cases", default="camera,walk,title,particles,boss,typing")
    r.add_argument("--fps", default="30,60")
    r.add_argument("--reruns", type=int, default=2)
    r.add_argument("--rt", default="30,60")
    r.add_argument("--park", type=int, default=2000)
    r.set_defaults(f=cmd_run)
    p = sub.add_parser("report")
    p.add_argument("dir")
    p.set_defaults(f=cmd_report)
    c = sub.add_parser("compare")
    c.add_argument("a")
    c.add_argument("b")
    c.set_defaults(f=cmd_compare)
    a = ap.parse_args(argv)
    print("uptime load", load(), flush=True)
    a.f(a)
    print("uptime load", load(), flush=True)


if __name__ == "__main__":
    main()
