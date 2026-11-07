#!/usr/bin/env python3
"""Spike C: how low can seconds per requirement go.

  speed.py c3 --approach R4 --n 200 [--dispatch tick|direct] [--fail barrier|timeout] [--obs-timeout 250]
              [--gate 0|1|2] [--rate 20] [--uncap] [--fps 260] [--fps-off]
  speed.py leak --approach R1 --rounds 6
  speed.py ready --approach R1 --rounds 10
  speed.py c1 cpu|frame|broke
  speed.py c2
  speed.py c4 paper|client

Every command stops what it started; leak_check at the end. Client always launches through Client in
run.py (direct java, silent options) and the volume facts are asserted before anything else happens.
"""
import argparse, json, os, pathlib, re, shutil, socket, statistics, subprocess, sys, time, urllib.parse

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import run as R
from run import Paper, Client, RUNS, free_port, leak_check, stop_all, front_app, rss_mb, now_micros

RESULTS = RUNS / "c-speed.jsonl"
KINDS = ["title", "chat", "block", "entity"]
MATERIALS = ["DIAMOND_BLOCK", "GOLD_BLOCK", "EMERALD_BLOCK", "REDSTONE_BLOCK", "LAPIS_BLOCK", "IRON_BLOCK"]


class Line:
    def __init__(self, port, prefix=""):
        self.port, self.prefix = port, prefix
        deadline = time.time() + 60
        while True:
            try:
                self.s = socket.create_connection(("127.0.0.1", port), timeout=120)
                break
            except OSError:
                if time.time() > deadline:
                    raise
                time.sleep(0.1)
        self.s.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
        self.f = self.s.makefile("rb")

    def __call__(self, name, /, _dispatch=None, **params):
        q = urllib.parse.urlencode(params)
        pre = (_dispatch + "/") if _dispatch else self.prefix
        self.s.sendall(f"{pre}{name}?{q}\n".encode())
        reply = self.f.readline()
        if not reply:
            raise RuntimeError(f"channel closed during {name}")
        out = json.loads(reply)
        if "error" in out:
            raise RuntimeError(f"{name}: {out['error']}")
        return out


class TunedPaper(Paper):
    """Same Paper with the chunk send and load limits off and the small view distance a void test needs."""

    def __init__(self, *a, tuned=True, view=3, **k):
        super().__init__(*a, **k)
        self.tuned, self.view = tuned, view

    def setup(self):
        super().setup()
        if not self.tuned:
            return
        props = self.dir / "server.properties"
        text = props.read_text().replace("view-distance=8", f"view-distance={self.view}").replace("simulation-distance=4", "simulation-distance=3")
        props.write_text(text + "sync-chunk-writes=false\nnetwork-compression-threshold=-1\n")
        cfg = self.dir / "config"
        cfg.mkdir(exist_ok=True)
        shutil.copy(pathlib.Path(__file__).parent / "paper-global-tuned.yml", cfg / "paper-global.yml")


class Session:
    """One long lived Paper and one long lived client, both silent and in the background."""

    def __init__(self, label, dispatch="tick", rd=2, xmx="1g", server_xmx="1g", max_runtime=3000, server_jvm=(), client_jvm=(), keep=False, tuned=True):
        self.run = RUNS / f"{label}-{int(time.time())}"
        self.keep = keep
        self.live, self.line = free_port(), free_port()
        limit = f"-Dprobe.maxRuntimeSec={max_runtime}"
        self.server = TunedPaper(self.run / "server", tuned=tuned, world="void", xmx=server_xmx, extra_jvm=[limit, f"-Dprobe.line.port={self.line}", *server_jvm])
        self.client = Client(self.run / "client", server=None, backend="opengl", xmx=xmx, rd=rd, facts_mode="changes",
                             extra_jvm=[limit, f"-Dprobe.live.port={self.live}", *client_jvm])
        self.dispatch = dispatch
        self.p = self.client.name
        self.load_start = os.getloadavg()

    def __enter__(self):
        self.server.start()
        self.server_done = self.server.wait_done()
        self.client.server = f"127.0.0.1:{self.server.port}"
        self.client.start()
        self.client.wait_event("first_world_frame", 120)
        self.client.wait_event("load_finished", 60)
        self.client.wait_event("renderer", 10)
        r = self.client.events()["renderer"]
        assert r["master"] == 0.0 and r["music"] == 0.0, "client is not silent: " + str(r)
        self.addr = self.client.server
        self.S = Line(self.line, prefix=self.dispatch + "/")
        self.C = Line(self.live)
        self.clientpid = self.client.java_pid()
        self.serverpid = self.server.proc.p.pid
        self.S("time", player=self.p)
        self.C("observe", needle='"compiledAt"', timeoutMs=20000)
        self.front = front_app()
        return self

    def __exit__(self, *exc):
        try:
            self.client.stop()
        finally:
            try:
                self.server.stop()
            finally:
                stop_all()
        if not self.keep:
            shutil.rmtree(self.run, ignore_errors=True)
        return False


def cpu_seconds(pid):
    out = subprocess.run(["ps", "-o", "time=", "-p", str(pid)], capture_output=True, text=True).stdout.strip()
    parts = out.replace(",", ".").split(":")
    return sum(float(x) * 60 ** i for i, x in enumerate(reversed(parts)))


def pct(v, p):
    v = sorted(v)
    return v[min(len(v) - 1, int(round(p / 100 * (len(v) - 1))))]


def stat(v):
    if not v:
        return None
    return {"n": len(v), "median": round(statistics.median(v), 4), "p95": round(pct(v, 95), 4), "max": round(max(v), 4), "min": round(min(v), 4)}


def needle_for(kind, token, material):
    if kind == "title":
        return f'"title":"{token}"'
    if kind == "chat":
        return f'"chat":["{token}"'
    if kind == "block":
        return f'"relBlock":"minecraft:{material.lower()}"'
    return f'"text":"{token}"'


def leftovers(p, me="probe1"):
    """Everything still visible to the player that the next requirement would inherit."""
    out = {}
    if p.get("title") not in (None, "null") or p.get("titleTime", 0) > 0:
        out["title"] = p.get("title")
    if p.get("bar") not in (None, "", "null") and p.get("barTime", 0) > 0:
        out["bar"] = p.get("bar")
    if p.get("chatCount", 0) > 0:
        out["chat"] = p.get("chatCount")
    if p.get("relBlock") != "minecraft:air":
        out["block"] = p.get("relBlock")
    others = [e.get("name") or e["type"] for e in p.get("entities", []) if e["type"] != "minecraft:player"]
    if others:
        out["entity"] = others
    if p.get("effects", 0) > 0:
        out["effects"] = p["effects"]
    if p.get("fire"):
        out["fire"] = True
    if p.get("inv", 0) > 0:
        out["inv"] = p["inv"]
    if any(abs(x) > 0.05 for x in p.get("vel", [0, 0, 0])):
        out["velocity"] = p["vel"]
    return out


class Reset:
    """Arranges the clean place for one approach and reports the wait that covers it."""

    def __init__(self, s, approach, need="compiledAt"):
        self.s, self.approach, self.need = s, approach, need
        self.arr_detail = []
        if approach == "R3":
            self.init_ms = s.S("poolInit", _dispatch="tick", n=8)["initMs"]
        if approach == "R1p":
            for i in range(8):
                s.S("region", player=s.p, idx=i)
                s.C("observe", needle=f'"{need}"', timeoutMs=15000)

    def arrange(self, i):
        s = self.s
        a = self.approach
        if a == "R4":
            return True
        if a == "R1":
            r = s.S("region", player=s.p, idx=i)
        elif a == "R1p":
            r = s.S("region", player=s.p, idx=i % 8)
        elif a == "R2":
            r = s.S("worldNew", player=s.p, idx=i)
            self.arr_detail.append(r)
        elif a == "R3":
            r = s.S("poolSwap", player=s.p, idx=i + 1)
        elif a == "R5":
            s.C("reconnect", addr=s.addr)
            r = {"dim": "minecraft:overworld", "cx": 0, "cz": 0}
        else:
            raise ValueError(a)
        needle = f'"{self.need}":"{r["dim"]}|{r["cx"]},{r["cz"]}"'
        return s.C("observe", needle=needle, timeoutMs=35000)["ok"]


def cmd_c3(a):
    label = f"c3-{a.approach}-{a.dispatch}" + (f"-gate{a.gate}" if a.gate else "") + (f"-rate{a.rate}" if a.rate != 20 else "") + ("-stock" if a.stock else "") + ("-uncap" if a.uncap else "") + (f"-fps{a.fps}" if a.fps != 260 else "") + (f"-late{a.late_ticks}" if a.late_ticks else "")
    rows = []
    wrong, ready_fail, dirty, after_broken_ok, after_broken_n, errors = 0, 0, 0, 0, 0, []
    dirty_kinds = {}
    with Session(label, dispatch=a.dispatch, rd=a.rd, tuned=not a.stock) as s:
        if a.rate != 20:
            s.S("tickrate", player=s.p, rate=a.rate)
        if a.uncap:
            s.C("uncap", on=1)
        if a.fps != 260:
            s.C("fps", limit=a.fps)
        if a.gate:
            s.C("gate", mode=a.gate, parkMicros=a.park)
        need = "readyAt" if a.gate else "compiledAt"
        reset = Reset(s, a.approach, need=need)
        time.sleep(0.5)
        load0 = os.getloadavg()
        cpu0 = (cpu_seconds(s.clientpid), cpu_seconds(s.serverpid), time.time())
        start = time.time()
        prev_broken = False
        for i in range(a.n):
            kind = KINDS[i % 4]
            token = f"T{i}x"
            material = MATERIALS[i % len(MATERIALS)]
            broken = (i + 1) % 20 == 0
            act_ping, end_ping = 2 * i + 1000, 2 * i + 1001
            t0 = time.perf_counter()
            if not reset.arrange(i):
                ready_fail += 1
            t1 = time.perf_counter()
            act = s.S("act", player=s.p, kind=kind, token=token, material=material, broken="1" if broken else "0", ping=act_ping, lateTicks=a.late_ticks)
            t2 = time.perf_counter()
            params = {"needle": needle_for(kind, token, material), "timeoutMs": a.obs_timeout}
            if a.fail == "barrier":
                params["ping"] = act_ping
            obs = s.C("observe", **params)
            t3 = time.perf_counter()
            verdict = obs["ok"]
            if verdict == broken:
                wrong += 1
                errors.append({"i": i, "kind": kind, "broken": broken, "obs": obs})
            if prev_broken:
                after_broken_n += 1
                after_broken_ok += 1 if verdict else 0
            prev_broken = broken
            s.S("reset", player=s.p, ping=end_ping)
            s.C("clearChat")
            st = s.C("state", ping=end_ping)
            t4 = time.perf_counter()
            left = leftovers(st["p"])
            if left:
                dirty += 1
                for k in left:
                    dirty_kinds[k] = dirty_kinds.get(k, 0) + 1
            rows.append({"broken": broken, "kind": kind, "arrange": t1 - t0, "act": t2 - t1, "observe": t3 - t2, "cleanup": t4 - t3, "total": t4 - t0,
                         "seen_ms": (obs["at"] - act["sentMicros"]) / 1000, "why": obs["why"]})
        wall = time.time() - start
        cpu = {"client_pct": round((cpu_seconds(s.clientpid) - cpu0[0]) / (time.time() - cpu0[2]) * 100), "server_pct": round((cpu_seconds(s.serverpid) - cpu0[1]) / (time.time() - cpu0[2]) * 100)}
        status = s.S("status", player=s.p)
        fps = s.C("stats")
        rss = {"client": rss_mb(s.clientpid), "server": rss_mb(s.serverpid)}
        front = front_app()
    good = [r for r in rows if not r["broken"]]
    bad = [r for r in rows if r["broken"]]
    result = {
        "label": label, "args": {k: v for k, v in vars(a).items() if k != "func"}, "n": len(rows), "wall_s": round(wall, 1), "load_start": load0[0], "load_end": os.getloadavg()[0],
        "per_requirement_s": stat([r["total"] for r in good]),
        "phases_median_ms": {k: round(statistics.median(r[k] for r in good) * 1000, 1) for k in ("arrange", "act", "observe", "cleanup")},
        "phases_p95_ms": {k: round(pct([r[k] for r in good], 95) * 1000, 1) for k in ("arrange", "act", "observe", "cleanup")},
        "by_kind_median_ms": {k: round(statistics.median(r["total"] for r in good if r["kind"] == k) * 1000, 1) for k in KINDS if any(r["kind"] == k for r in good)},
        "send_to_seen_ms": stat([r["seen_ms"] for r in good]),
        "fail": {"n": len(bad), "decided_ms_observe": stat([r["observe"] * 1000 for r in bad]), "total_s": stat([r["total"] for r in bad]), "why": sorted({r["why"] for r in bad})},
        "wrong_verdicts": wrong, "errors": errors[:3], "after_broken_passed": f"{after_broken_ok}/{after_broken_n}", "ready_failures": ready_fail,
        "dirty_after_cleanup": dirty, "dirty_kinds": dirty_kinds, "cpu": cpu, "rss_mb": rss, "status": status, "fps": fps["fps"], "front": front,
    }
    if a.approach == "R2":
        result["r2_detail_median_ms"] = {k: round(statistics.median(d[k] for d in reset.arr_detail), 1) for k in ("createMs", "platformMs", "teleportMs", "unloadMs")}
    if a.approach == "R3":
        result["pool_init_ms"] = reset.init_ms
    result["leaks"] = leak_check()
    RESULTS.open("a").write(json.dumps(result) + "\n")
    show = {k: result[k] for k in ("label", "wall_s", "load_start", "load_end", "per_requirement_s", "phases_median_ms", "phases_p95_ms", "by_kind_median_ms", "send_to_seen_ms", "fail", "wrong_verdicts", "errors", "after_broken_passed", "ready_failures", "dirty_after_cleanup", "dirty_kinds", "cpu", "status", "fps", "front", "leaks") + (("r2_detail_median_ms",) if a.approach == "R2" else ()) + (("pool_init_ms",) if a.approach == "R3" else ())}
    print(json.dumps(show))


def cmd_leak(a):
    """Leaves one of everything, resets with the approach only, and lists what the next requirement sees."""
    table = []
    with Session(f"leak-{a.approach}", dispatch="tick") as s:
        reset = Reset(s, a.approach)
        for i in range(a.rounds):
            ping = 5000 + 2 * i
            s.S("dirty", player=s.p)
            time.sleep(0.15)
            s.C("state", ping=-1)
            ok = reset.arrange(i)
            s.S("noop", player=s.p, ping=ping)
            st = s.C("state", ping=ping)
            before = leftovers(st["p"])
            s.S("reset", player=s.p, full=1, ping=ping + 1)
            s.C("clearChat")
            st2 = s.C("state", ping=ping + 1)
            time.sleep(0.15)
            st3 = s.C("state", ping=-1)
            table.append({"ready": ok, "left_by_reset": sorted(before), "detail": before, "after_full_clean": sorted(leftovers(st2["p"])), "after_settle": sorted(leftovers(st3["p"]))})
    summary = {"label": f"leak-{a.approach}", "load": os.getloadavg()[0], "rounds": a.rounds, "left": {}, "after_full_clean": {}, "after_settle": {}}
    for t in table:
        for k in t["left_by_reset"]:
            summary["left"][k] = summary["left"].get(k, 0) + 1
        for k in t["after_full_clean"]:
            summary["after_full_clean"][k] = summary["after_full_clean"].get(k, 0) + 1
        for k in t["after_settle"]:
            summary["after_settle"][k] = summary["after_settle"].get(k, 0) + 1
    summary["sample"] = table[-1]["detail"]
    summary["leaks"] = leak_check()
    RESULTS.open("a").write(json.dumps(summary) + "\n")
    print(json.dumps(summary))


def diff(a, b, threshold=8):
    from PIL import Image
    import numpy as np
    x = np.asarray(Image.open(a).convert("RGB"), dtype=np.int16)
    y = np.asarray(Image.open(b).convert("RGB"), dtype=np.int16)
    if x.shape != y.shape:
        return {"shape": [x.shape, y.shape]}
    d = np.abs(x - y).max(axis=2)
    return {"pixels": int((d > threshold).sum()), "of": int(d.size), "max": int(d.max())}


def cmd_ready(a):
    """Is the wait right? Screenshot immediately at each signal, compare with the same place a second later."""
    out = {"label": f"ready-{a.approach}", "load": os.getloadavg()[0], "by_signal": {}}
    counter = 0
    with Session(f"ready-{a.approach}", dispatch="tick", keep=False) as s:
        shots = pathlib.Path(s.run) / "shots"
        shots.mkdir()
        for signal in ("none", "readyAt", "compiledAt", "settledAt", "settledAt+5"):
            if not out["by_signal"]:
                reset = Reset(s, a.approach, need="compiledAt")
            rows, waits = [], []
            for i in range(a.rounds):
                counter += 1
                idx = counter
                t0 = time.perf_counter()
                if a.approach == "R1":
                    r = s.S("region", player=s.p, idx=idx)
                else:
                    r = s.S("poolSwap", player=s.p, idx=idx)
                base = signal.split("+")[0]
                if base != "none":
                    res = s.C("observe", needle=f'"{base}":"{r["dim"]}|{r["cx"]},{r["cz"]}"', timeoutMs=20000)
                    if not res["ok"]:
                        rows.append({"timeout": True})
                        continue
                waits.append(time.perf_counter() - t0)
                extra = int(signal.split("+")[1]) if "+" in signal else 0
                early = str(shots / f"{signal}-{i}-a.png")
                s.C("oneshot", frames=1 + extra, path=early)
                time.sleep(1.0)
                late = str(shots / f"{signal}-{i}-b.png")
                s.C("shot", path=late)
                rows.append(diff(early, late))
            pix = [r.get("pixels", -1) for r in rows]
            out["by_signal"][signal] = {"wait_ms": stat([w * 1000 for w in waits]), "bad_frames": sum(1 for p in pix if p != 0), "of": len(pix), "pixels_median": statistics.median(pix) if pix else None, "pixels_max": max(pix) if pix else None}
    out["leaks"] = leak_check()
    RESULTS.open("a").write(json.dumps(out) + "\n")
    print(json.dumps(out))


def cmd_ready2(a):
    """After a world swap, when does the frame stop changing? Saves the frames for a look."""
    outdir = RUNS / "shots" / "ready2"
    outdir.mkdir(parents=True, exist_ok=True)
    out = []
    with Session("ready2", dispatch="tick") as s:
        Reset(s, a.approach)
        shots = pathlib.Path(s.run) / "shots"
        shots.mkdir()
        time.sleep(9)  # toast and join chat line gone
        s.C("clearChat")
        for i in range(a.rounds):
            if a.approach == "R1":
                r = s.S("region", player=s.p, idx=i)
            elif a.approach == "R3":
                r = s.S("poolSwap", player=s.p, idx=i + 1)
            else:
                s.C("reconnect", addr=s.addr)
                r = {"dim": "minecraft:overworld", "cx": 0, "cz": 0}
            t00 = time.perf_counter()
            s.C("observe", needle=f'"settledAt":"{r["dim"]}|{r["cx"]},{r["cz"]}"', timeoutMs=20000)
            waited = time.perf_counter() - t00
            t0 = time.perf_counter()
            names = []
            for delay in (0, 0.05, 0.1, 0.2, 0.4, 0.8, 1.6, 3.0, 6.0):
                while time.perf_counter() - t0 < delay:
                    time.sleep(0.002)
                path = str(shots / f"{i}-{delay}.png")
                s.C("shot", path=path)
                names.append((delay, path))
            final = names[-1][1]
            row = {str(d): diff(p, final) for d, p in names[:-1]}
            out.append({"settled_ms": round(waited * 1000), **{k: v["pixels"] for k, v in row.items()}})
            if i == a.rounds - 1:
                for d, p in names:
                    shutil.copy(p, outdir / f"{a.approach}-{d}.png")
    res = {"label": f"ready2-{a.approach}", "load": os.getloadavg()[0], "rows": out, "leaks": leak_check()}
    RESULTS.open("a").write(json.dumps(res) + "\n")
    print(json.dumps(res))


def scene(s, i, ping):
    token = f"S{i}x"
    S = lambda *x, **k: s.S(*x, _dispatch="direct", **k)
    S("title", player=s.p, text=token, sub="sub", **{"in": 1, "stay": 2000, "out": 1})
    S("act", player=s.p, kind="chat", token=token, material="GOLD_BLOCK", broken="0")
    S("act", player=s.p, kind="block", token=token, material="GOLD_BLOCK", broken="0")
    r = S("act", player=s.p, kind="entity", token=token, material="GOLD_BLOCK", broken="0", ping=ping)
    return token, r


def perceived_subset(p, token):
    q = {k: p.get(k) for k in ("title", "sub", "fade", "bar", "chat", "relBlock", "under", "effects", "inv", "pos")}
    q["texts"] = sorted(e.get("text") or "" for e in p.get("entities", []) if e["type"] != "minecraft:player")
    return json.loads(json.dumps(q).replace(token, "TOKEN"))


def cmd_c1(a):
    if a.what == "cpu":
        modes = [("unlimited", 260, 0), ("fps60", 60, 0), ("fps20", 20, 0), ("gate1", 260, 1), ("gate2", 260, 2)]
        if a.park_sweep:
            modes = [("gate2-p0", 260, 2, 0), ("gate2-p200us", 260, 2, 200), ("gate2-p1ms", 260, 2, 1000), ("gate2-p2ms", 260, 2, 2000), ("gate2-p5ms", 260, 2, 5000)]
        table = {m[0]: {"cpu": [], "fps": [], "tps": [], "lat": [], "loads": [], "content": []} for m in modes}
        with Session("c1-cpu", dispatch="direct") as s:
            for rnd in range(a.rounds):
                for m in modes:
                    name, fps, gate = m[0], m[1], m[2]
                    s.C("gate", mode=gate, parkMicros=m[3] if len(m) > 3 else 2000)
                    s.C("fps", limit=fps)
                    time.sleep(2)
                    c0, t0 = cpu_seconds(s.clientpid), time.time()
                    f0 = s.C("stats")
                    time.sleep(a.seconds)
                    c1, t1 = cpu_seconds(s.clientpid), time.time()
                    f1 = s.C("stats")
                    span = (f1["at"] - f0["at"]) / 1e6
                    row = table[name]
                    row["cpu"].append(round((c1 - c0) / (t1 - t0) * 100))
                    row["fps"].append(round((f1["frame"] - f0["frame"]) / span))
                    row["tps"].append(round((f1["tick"] - f0["tick"]) / span, 1))
                    row["loads"].append(round(os.getloadavg()[0], 1))
                    lat = []
                    for i in range(a.samples):
                        tok = f"L{rnd}{name}{i}"
                        r = s.S("act", _dispatch="direct", player=s.p, kind=KINDS[i % 2], token=tok, material="GOLD_BLOCK", broken="0")
                        o = s.C("observe", needle=needle_for(KINDS[i % 2], tok, "GOLD_BLOCK"), timeoutMs=2000)
                        lat.append((o["at"] - r["sentMicros"]) / 1000 if o["ok"] else 9999)
                        s.S("reset", _dispatch="direct", player=s.p)
                        s.C("clearChat")
                    row["lat"].extend(lat)
                    token, sc = scene(s, f"{rnd}{name}", ping=100000 + rnd * 10 + modes.index(m))
                    st = s.C("state", ping=100000 + rnd * 10 + modes.index(m))
                    row["content"].append(perceived_subset(st["p"], f"S{rnd}{name}x"))
                    s.S("reset", _dispatch="direct", player=s.p)
                    s.C("clearChat")
                    s.C("state", ping=-1)
        base = table[modes[0][0]]["content"][0]
        out = {"label": "c1-cpu", "rows": {}}
        for name, row in table.items():
            out["rows"][name] = {"cpu_pct": row["cpu"], "cpu_median": statistics.median(row["cpu"]), "fps": row["fps"], "tps": row["tps"], "latency_ms": stat(row["lat"]), "load": row["loads"],
                                 "content_same": [c == base for c in row["content"]], "content_sample": None if all(c == base for c in row["content"]) else row["content"][0]}
        out["base_content"] = base
        out["leaks"] = leak_check()
        RESULTS.open("a").write(json.dumps(out) + "\n")
        print(json.dumps(out))
    elif a.what == "frame":
        out = {"label": "c1-frame", "load_start": os.getloadavg()[0], "rows": {}}
        with Session("c1-frame", dispatch="direct") as s:
            shots = pathlib.Path(s.run) / "shots"
            shots.mkdir()
            for gate in (1, 2):
                for k in (1, 2, 3, 5, 10, 30):
                    rows, lat_drawn, lat_written = [], [], []
                    for rnd in range(a.rounds):
                        ping = 200000 + gate * 1000 + k * 10 + rnd
                        s.S("reset", _dispatch="direct", player=s.p)
                        s.C("clearChat")
                        s.C("state", ping=-1)
                        s.C("gate", mode=gate)
                        time.sleep(0.1)
                        token, r = scene(s, f"{gate}{k}{rnd}", ping=ping)
                        st = s.C("state", ping=ping)
                        early = str(shots / f"g{gate}-k{k}-{rnd}-a.png")
                        o = s.C("oneshot", frames=k, path=early)
                        lat_drawn.append((o["drawn"] - o["start"]) / 1000)
                        lat_written.append((o["written"] - o["start"]) / 1000)
                        s.C("gate", mode=0)
                        time.sleep(0.8)
                        late = str(shots / f"g{gate}-k{k}-{rnd}-b.png")
                        s.C("shot", path=late)
                        rows.append(diff(early, late))
                        if rnd == 0 and a.keep_shots:
                            for path in (early, late):
                                shutil.copy(path, RUNS / "shots" / f"c1-{pathlib.Path(path).name}")
                        s.S("reset", _dispatch="direct", player=s.p)
                    out["rows"][f"gate{gate}-frames{k}"] = {"drawn_ms": stat(lat_drawn), "written_ms": stat(lat_written), "pixels": [r.get("pixels") for r in rows], "max_delta": [r.get("max") for r in rows]}
        out["load_end"] = os.getloadavg()[0]
        out["leaks"] = leak_check()
        RESULTS.open("a").write(json.dumps(out) + "\n")
        print(json.dumps(out))
    elif a.what == "broke":
        out = {"label": "c1-broke", "load_start": os.getloadavg()[0]}
        with Session("c1-broke", dispatch="tick") as s:
            # Teleport while gated: chunk data versus meshes.
            s.C("gate", mode=2)
            r = s.S("region", player=s.p, idx=0)
            base = f'{r["dim"]}|{r["cx"]},{r["cz"]}'
            t0 = time.perf_counter()
            o1 = s.C("observe", needle=f'"readyAt":"{base}"', timeoutMs=10000)
            t1 = time.perf_counter()
            o2 = s.C("observe", needle=f'"compiledAt":"{base}"', timeoutMs=3000)
            t2 = time.perf_counter()
            out["teleport_gated"] = {"readyAt_ok": o1["ok"], "readyAt_ms": round((t1 - t0) * 1000), "compiledAt_ok_within_3s": o2["ok"]}
            t3 = time.perf_counter()
            s.C("gate", mode=0)
            o3 = s.C("observe", needle=f'"compiledAt":"{base}"', timeoutMs=10000)
            out["teleport_gated"]["compiled_after_open_ms"] = round((time.perf_counter() - t3) * 1000)
            # World swap while gated: LevelLoadingScreen waits on the section callback.
            s.S("poolInit", n=2)
            for gate in (0, 1, 2):
                s.C("gate", mode=gate)
                r = s.S("poolSwap", player=s.p, idx=gate)
                t0 = time.perf_counter()
                o = s.C("observe", needle=f'"readyAt":"{r["dim"]}|0,0"', timeoutMs=36000)
                out[f"world_swap_gate{gate}"] = {"ok": o["ok"], "ms": round((time.perf_counter() - t0) * 1000)}
                s.C("gate", mode=0)
                s.C("observe", needle=f'"compiledAt":"{r["dim"]}|0,0"', timeoutMs=36000)
            out["errors_in_log"] = len(re.findall(r"ERROR|Exception", pathlib.Path(s.client.proc.log_path).read_text(errors="replace")))
        out["leaks"] = leak_check()
        RESULTS.open("a").write(json.dumps(out) + "\n")
        print(json.dumps(out))


def facts_since(path, token, start_at):
    rows = []
    with open(path) as f:
        for line in f:
            if line.startswith('{"k":"e"'):
                continue
            if token not in line:
                continue
            try:
                j = json.loads(line)
            except json.JSONDecodeError:
                continue
            if j["at"] >= start_at:
                rows.append(j)
    return rows


def title_life(s, token, fade=(10, 40, 10)):
    t0 = now_micros()
    s.S("title", _dispatch="direct", player=s.p, text=token, sub="c2", **{"in": fade[0], "stay": fade[1], "out": fade[2]})
    o = s.C("observe", needle=f'"title":"{token}"', timeoutMs=5000)
    if not o["ok"]:
        return None
    gone = s.C("observe", needle='"titleTime":0,', timeoutMs=20000)
    return (gone["at"] - o["at"]) / 1e6 if gone["ok"] else None


def entity_track(rows, token):
    out = []
    for f in rows:
        for e in f.get("entities", []):
            if e.get("text") == token:
                out.append((f["at"], e["x"], e["rx"]))
    return out


def move_display(s, token, duration, distance=10):
    s.S("moveDisplay", _dispatch="tick", player=s.p, token=token, duration=duration, distance=distance, after=5)
    s.C("observe", needle=f'"text":"{token}"', timeoutMs=5000)
    time.sleep((5 + duration) / s.crate + 0.7)
    s.client  # facts flush at each tick
    rows = facts_since(s.client.facts, f'"text":"{token}"', 0)
    tr = entity_track(rows, token)
    if not tr:
        return None
    x0 = tr[0][2]
    x1 = tr[-1][2]
    if abs(x1 - x0) < 1:
        return {"moved": False, "samples": len(tr)}
    mid = [t for t in tr if x0 + 0.02 < t[2] < x1 - 0.02]
    first = next(t for t in tr if abs(t[2] - x0) > 0.02)
    last = next(t for t in tr if abs(t[2] - x1) <= 0.02)
    elapsed = (last[0] - first[0]) / 1e6
    backwards = sum(1 for p, q in zip(tr, tr[1:]) if q[2] < p[2] - 1e-3)
    err = 0.0
    if mid and elapsed > 0:
        for at, _, rx in mid:
            expected = x0 + (at - first[0]) / 1e6 / elapsed * (x1 - x0)
            err = max(err, abs(rx - expected))
    distinct = len({round(t[2], 3) for t in tr})
    return {"elapsed_s": round(elapsed, 3), "distance": round(x1 - x0, 2), "samples": len(tr), "distinct_x": distinct, "backwards": backwards, "max_err_from_line_blocks": round(err, 2)}


def move_tick(s, token, ticks=40):
    s.S("moveTick", _dispatch="tick", player=s.p, token=token, ticks=ticks)
    time.sleep(ticks / s.crate + 0.7)
    tr = entity_track(facts_since(s.client.facts, f'"text":"{token}"', 0), token)
    if not tr:
        return None
    x0, x1 = tr[0][2], tr[-1][2]
    if abs(x1 - x0) < 1:
        return {"moved": False, "samples": len(tr)}
    first = next(t for t in tr if abs(t[2] - x0) > 0.02)
    last = next(t for t in tr if abs(t[2] - x1) <= 0.02)
    return {"elapsed_s": round((last[0] - first[0]) / 1e6, 3), "distance": round(x1 - x0, 2), "samples": len(tr), "backwards": sum(1 for p, q in zip(tr, tr[1:]) if q[2] < p[2] - 1e-3)}


def cmd_c2(a):
    out = {"label": "c2", "load_start": os.getloadavg()[0], "rows": []}
    conditions = [
        ("rate20", 20, False, 260, 0), ("rate40", 40, True, 260, 0), ("rate100", 100, True, 260, 0), ("rate200", 200, True, 260, 0),
        ("rate400", 400, True, 260, 0), ("rate200-gate2", 200, True, 260, 2), ("rate200-cap", 200, False, 260, 0),
        ("rate200-fps20", 200, True, 20, 0), ("rate200-fps10", 200, True, 10, 0), ("rate40-nocap-off", 40, False, 260, 0),
    ]
    with Session("c2", dispatch="tick") as s:
        for name, rate, uncap, fps, gate in conditions:
            s.S("tickrate", player=s.p, rate=rate)
            s.C("uncap", on=1 if uncap else 0)
            s.C("fps", limit=fps)
            s.C("gate", mode=gate)
            s.crate = min(rate if uncap else 20, fps * 10)
            time.sleep(0.5)
            row = {"name": name, "rate": rate, "uncap": uncap, "fps_limit": fps, "gate": gate, "title_s": [], "display": [], "tick_path": []}
            c0, t0 = cpu_seconds(s.clientpid), time.time()
            sc0 = cpu_seconds(s.serverpid)
            f0 = s.C("stats")
            st0 = s.S("status", player=s.p)
            time.sleep(1.0)
            f1 = s.C("stats")
            st1 = s.S("status", player=s.p)
            span = (f1["at"] - f0["at"]) / 1e6
            row["client_tps"] = round((f1["tick"] - f0["tick"]) / span, 1)
            row["frames_per_s"] = round((f1["frame"] - f0["frame"]) / span)
            row["server_ticks_per_s"] = round((st1["tick"] - st0["tick"]) / span, 1)
            row["cpu_client_pct"] = round((cpu_seconds(s.clientpid) - c0) / (time.time() - t0) * 100)
            row["cpu_server_pct"] = round((cpu_seconds(s.serverpid) - sc0) / (time.time() - t0) * 100)
            for i in range(a.rounds):
                row["title_s"].append(round(title_life(s, f"{name}T{i}") or -1, 3))
                row["display"].append(move_display(s, f"{name}D{i}", duration=20))
                row["tick_path"].append(move_tick(s, f"{name}P{i}", ticks=40))
                s.S("reset", player=s.p, full=1)
                s.C("clearChat")
            row["expected_title_s"] = round(60 / rate, 3)
            row["expected_display_s"] = round(20 / rate, 3)
            row["expected_tick_path_s"] = round(40 / rate, 3)
            row["status"] = s.S("status", player=s.p)
            row["load"] = round(os.getloadavg()[0], 1)
            print(json.dumps(row), flush=True)
            out["rows"].append(row)
        # pixel proof at speed
        s.S("tickrate", player=s.p, rate=200)
        s.C("uncap", on=1)
        s.C("fps", limit=260)
        s.C("gate", mode=0)
        path = RUNS / "shots" / "c2-rate200.png"
        path.parent.mkdir(exist_ok=True)
        s.S("title", _dispatch="direct", player=s.p, text="SPEED", sub="rate200", **{"in": 40, "stay": 200, "out": 40})
        time.sleep(0.5)
        out["shot"] = s.C("shot", path=str(path))
        out["errors_in_server_log"] = len(re.findall(r"Can't keep up|moved too quickly|ERROR", pathlib.Path(s.server.proc.log_path).read_text(errors="replace")))
        out["errors_in_client_log"] = len(re.findall(r"ERROR|Exception", pathlib.Path(s.client.proc.log_path).read_text(errors="replace")))
    out["load_end"] = os.getloadavg()[0]
    out["leaks"] = leak_check()
    RESULTS.open("a").write(json.dumps(out) + "\n")
    print(json.dumps({k: out[k] for k in ("load_start", "load_end", "shot", "errors_in_server_log", "errors_in_client_log", "leaks") if k in out}))


def cmd_trace(a):
    """Timeline of one move as the client saw it."""
    with Session("trace", dispatch="direct") as s:
        reset = Reset(s, a.approach)
        out = []
        for i in range(a.rounds):
            time.sleep(0.6)
            t0 = now_micros()
            if a.approach == "R1":
                r = s.S("region", player=s.p, idx=i)
            elif a.approach == "R3":
                r = s.S("poolSwap", player=s.p, idx=i + 1)
            else:
                s.C("reconnect", addr=s.addr)
                r = {"dim": "minecraft:overworld", "cx": 0, "cz": 0}
            t1 = now_micros()
            s.C("observe", needle=f'"compiledAt":"{r["dim"]}|{r["cx"]},{r["cz"]}"', timeoutMs=20000)
            t2 = now_micros()
            time.sleep(0.2)
            rows = []
            with open(s.client.facts) as f:
                for line in f:
                    if line.startswith('{"k":"e"'):
                        continue
                    try:
                        j = json.loads(line)
                    except json.JSONDecodeError:
                        continue
                    if j["at"] >= t0:
                        rows.append(j)
            seq, last = [], None
            for j in rows:
                key = (j.get("screen"), j.get("loaded"), "readyAt" in j, "compiledAt" in j, tuple(j.get("pos", [])), j.get("dim"))
                if key != last:
                    seq.append({"ms": round((j["at"] - t0) / 1000), "screen": j.get("screen"), "loaded": j.get("loaded"), "ready": "readyAt" in j, "compiled": "compiledAt" in j, "x": j.get("pos", [0])[0], "dim": j.get("dim")})
                    last = key
            out.append({"cmd_ms": round((t1 - t0) / 1000), "compiled_ms": round((t2 - t0) / 1000), "seq": seq[:40] if i == a.rounds - 1 else None})
    print(json.dumps(out))
    print(json.dumps({"leaks": leak_check()}))


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    c = sub.add_parser("c3")
    c.add_argument("--approach", required=True, choices=["R1", "R1p", "R2", "R3", "R4", "R5"])
    c.add_argument("--n", type=int, default=200)
    c.add_argument("--dispatch", default="tick", choices=["tick", "direct"])
    c.add_argument("--fail", default="barrier", choices=["barrier", "timeout"])
    c.add_argument("--obs-timeout", type=int, default=2000)
    c.add_argument("--gate", type=int, default=0)
    c.add_argument("--park", type=int, default=2000)
    c.add_argument("--rate", type=float, default=20)
    c.add_argument("--uncap", action="store_true")
    c.add_argument("--fps", type=int, default=260)
    c.add_argument("--rd", type=int, default=2)
    c.add_argument("--late-ticks", type=int, default=0, help="the server shows the thing this many ticks after the barrier")
    c.add_argument("--stock", action="store_true", help="Paper's default chunk rates and view distance")
    l = sub.add_parser("leak")
    l.add_argument("--approach", required=True)
    l.add_argument("--rounds", type=int, default=6)
    r = sub.add_parser("ready")
    r.add_argument("--approach", required=True, choices=["R1", "R3"])
    r.add_argument("--rounds", type=int, default=6)
    o = sub.add_parser("c1")
    o.add_argument("what", choices=["cpu", "frame", "broke"])
    o.add_argument("--rounds", type=int, default=3)
    o.add_argument("--seconds", type=int, default=10)
    o.add_argument("--samples", type=int, default=30)
    o.add_argument("--park-sweep", action="store_true")
    o.add_argument("--keep-shots", action="store_true")
    t = sub.add_parser("c2")
    t.add_argument("--rounds", type=int, default=3)
    r2 = sub.add_parser("ready2")
    r2.add_argument("--rounds", type=int, default=3)
    r2.add_argument("--approach", default="R3")
    tr = sub.add_parser("trace")
    tr.add_argument("--approach", required=True)
    tr.add_argument("--rounds", type=int, default=4)
    a = ap.parse_args()
    RUNS.mkdir(exist_ok=True)
    try:
        {"c3": cmd_c3, "leak": cmd_leak, "ready": cmd_ready, "c1": cmd_c1, "c2": cmd_c2, "trace": cmd_trace, "ready2": cmd_ready2}[a.cmd](a)
    finally:
        stop_all()
        left = leak_check()
        if left:
            print("LEAK", left, file=sys.stderr)


if __name__ == "__main__":
    main()
