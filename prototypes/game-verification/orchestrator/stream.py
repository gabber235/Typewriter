#!/usr/bin/env python3
"""Stream prototype: a gated, stepped real client streams what its player perceives, record by record, to a
listener in a separate JVM (orchestrator/Listener.java). A record is sent whenever the perceived content changes;
a barrier (vanilla ping below 2^30) is echoed after the record of the first frame drawn after it.

  stream.py run [--label mac] [--typical 1000] [--scenes actionbar,title,chat,boss,walk,walka4,typing,tags]
  stream.py report runs/stream-<label>-<t>     tables from a finished run directory

Paper runs with spike N's step agent; the client is gated (mode 2) and in lockstep. Every command stops what it
started and checks for leftover processes.
"""
import argparse, collections, json, os, pathlib, random, statistics, subprocess, sys, time

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import n as N
from run import RUNS, ROOT, Proc, leak_check

HERE = pathlib.Path(__file__).resolve().parent
RESULTS = RUNS / "stream.jsonl"
hooks = {"record": None}
BARRIER0 = 100_000_000

# Which tag each scene's text must carry: (scene, substring) -> tag.
EXPECT = {
    "actionbar": [("moonpetals", "actionbar"), ("Mana ", "actionbar")],
    "title": [("The Journey Begins", "title"), ("Chapter One", "subtitle")],
    "chat": [("[Keeper] Line", "chat")],
    "boss": [("The Warden Awakens", "bossbar")],
    "walk": [("Old Keeper", "nametag"), ("Welcome to Riverside", "world")],
    "walka4": [("Old Keeper", "nametag"), ("Welcome to Riverside", "world")],
    "typing": [("/give", "screen")],
    "tags": [("Quest Log", "sidebar"), ("Find the keeper", "sidebar"), ("probe1", "tablist")],
}
SCENE_TICKS = {"actionbar": 110, "title": 80, "chat": 30, "boss": 110, "walk": 60, "walka4": 60, "typing": 60, "tags": 30}


def load():
    return round(os.getloadavg()[0], 1)


def record(kind, **row):
    row = {"kind": kind, "at": time.strftime("%Y-%m-%dT%H:%M:%S"), "load": load(), **row}
    RUNS.mkdir(exist_ok=True)
    with RESULTS.open("a") as f:
        f.write(json.dumps(row) + "\n")
    if hooks["record"]:
        hooks["record"]("stream-" + kind, **{k: v for k, v in row.items() if k != "kind"})
    print(json.dumps(row)[:3000], flush=True)


def stat(v, nd=3):
    v = sorted(x for x in v if x is not None)
    if not v:
        return None
    q = lambda p: v[min(len(v) - 1, int(len(v) * p))]
    return {"n": len(v), "mean": round(statistics.mean(v), nd), "med": round(statistics.median(v), nd), "p95": round(q(0.95), nd), "max": round(v[-1], nd)}


class Listener:
    def __init__(self, out_dir):
        out_dir.mkdir(parents=True, exist_ok=True)
        self.port_file = out_dir / "listener.port"
        self.out = out_dir / "stream.jsonl"
        self.port_file.unlink(missing_ok=True)
        self.proc = Proc(["java", "-Dprobe.gv.run=1", str(HERE / "Listener.java"), str(self.port_file), str(self.out)], out_dir, out_dir / "listener.log")
        deadline = time.time() + 60
        while not self.port_file.exists() or not self.port_file.read_text().strip():
            if time.time() > deadline or not self.proc.alive():
                raise RuntimeError("listener did not start, see " + str(out_dir / "listener.log"))
            time.sleep(0.1)
        self.port = int(self.port_file.read_text())

    def stop(self):
        self.proc.stop(grace=5)


class Driver:
    def __init__(self, rig, out_dir):
        self.rig, self.S, self.C, self.p = rig, rig.S, rig.C, rig.p
        self.barriers = []  # (id, sentNanos, scene)
        self.bid = BARRIER0 + random.randrange(1000) * 1000
        self.runs = []  # n.run results with scene
        self.out_dir = out_dir

    def steps(self, n, scene):
        r = self.rig.steps_run(n, stop_on_seen=False)
        r["scene"] = scene
        self.runs.append(r)
        return r

    def barrier(self, scene):
        self.bid += 1
        r = self.S("st.barrier", _dispatch="direct", player=self.p, id=self.bid)
        self.barriers.append((self.bid, r["sentNanos"], scene))

    def tidy(self):
        self.S("st.clear", _dispatch="direct", player=self.p)
        self.C("st.close")
        self.C("st.watch", ids="", blocks="")
        self.C("st.a4", on=0)
        self.C("clearChat")
        self.steps(5, "tidy")

    def scene(self, name, chunk=10):
        self.tidy()
        self.C("st.reset", name=name)
        self.steps(2, name)
        sc = "walk" if name.startswith("walk") else name
        if name == "typing":
            self.S("st.op", _dispatch="direct", player=self.p)
            self.steps(3, name)
            self.C("st.chat", text="/give @s minecraft:diamond_sword 1")
        elif name == "tags":
            self.S("st.scn", _dispatch="direct", player=self.p, name="tags")
            self.C("st.tab", down=1)
        else:
            r = self.S("st.scn", _dispatch="direct", player=self.p, name=sc)
            if sc == "walk":
                self.steps(20, name)  # chunks and the entities reach the client before the walk starts
                self.C("st.watch", ids=f"{r['villager']},{r['display']}", blocks=r["blocks"])
                self.C("st.a4", on=1 if name == "walka4" else 0)
                self.C("st.walk", blocks=4)
        left = SCENE_TICKS[name]
        while left > 0:
            k = min(chunk, left)
            self.steps(k, name)
            left -= k
            self.barrier(name)
        walked = self.C("st.walked") if sc == "walk" else None
        return walked

    def typical(self, n):
        kinds = ["chat", "bar", "title", "boss", "display"]
        for i in range(n):
            kind = kinds[i % len(kinds)]
            self.S("st.clear", _dispatch="direct", player=self.p)
            self.C("clearChat")
            self.C("st.watch", ids="", blocks="")
            self.C("st.reset", name=f"req:{kind}")
            r = self.S("st.stim", _dispatch="direct", player=self.p, kind=kind, token=f"t{random.randrange(10**6)}")
            if kind == "display":
                self.C("st.watch", ids=str(r["id"]), blocks="")
            self.steps(5, "typical")
            self.barrier("typical")
            if i % 100 == 99:
                print(f"typical {i + 1} load {load()}", flush=True)
        self.S("st.clear", _dispatch="direct", player=self.p)
        self.steps(5, "typical-tail")


def cmd_run(a):
    out = RUNS / f"stream-{a.label}-{int(time.time())}"
    out.mkdir(parents=True, exist_ok=True)
    lis = Listener(out)
    meta = {"label": a.label, "load_start": load(), "scenes": a.scenes, "typical": a.typical, "machine": a.machine}
    try:
        with N.Rig(f"stream-{a.label}") as rig:
            d = Driver(rig, out)
            rig.C("in.setup", focus="fake", grab="fake")
            rig.C("gate", mode=2, parkMicros=a.park)
            rig.step_on()
            rig.steps_run(100, stop_on_seen=False)
            # Cost of a stepped tick without the stream, then with it (no scene, so few records).
            t0 = time.perf_counter()
            r0 = rig.steps_run(a.base_ticks, stop_on_seen=False)
            meta["base_ms_per_tick_off"] = round(r0["wallMicros"] / a.base_ticks / 1000, 3)
            rig.C("st.on", port=lis.port, a4=0)
            rig.S("st.ticks", _dispatch="direct")
            r1 = d.steps(a.base_ticks, "idle")
            meta["base_ms_per_tick_on"] = round(r1["wallMicros"] / a.base_ticks / 1000, 3)
            walks = {}
            for sc in a.scenes.split(","):
                if sc:
                    w = d.scene(sc)
                    if w:
                        walks[sc] = w
            meta["walked"] = walks
            if a.typical:
                d.typical(a.typical)
            d.tidy()
            st = rig.C("st.off")
            time.sleep(0.5)  # the listener flushes on EOF; the rig's exit stops every process it knows
            ticks = rig.S("st.ticks", _dispatch="direct")
            rig.step_off()
            meta["client_stats"] = st
            meta["load_end"] = load()
            (out / "ticks.json").write_text(json.dumps(ticks))
            (out / "runs.json").write_text(json.dumps(d.runs))
            (out / "barriers.json").write_text(json.dumps(d.barriers))
            (out / "meta.json").write_text(json.dumps(meta, indent=1))
    finally:
        time.sleep(0.5)
        lis.stop()
    leak_check()
    rep = report(out)
    record("run", label=a.label, dir=str(out), meta=meta, report=rep)


# ---------- analysis ----------

def segments(frames):
    """Splits the listener's frames at each reset; returns [(name, frames)]."""
    segs, cur, name = [], [], "start"
    for f in frames:
        if f["type"] == 3:
            segs.append((name, cur))
            cur, name = [], f["name"]
        else:
            cur.append(f)
    segs.append((name, cur))
    return segs


def report(out):
    out = pathlib.Path(out)
    frames = [json.loads(l) for l in (out / "stream.jsonl").read_text().splitlines() if l.strip()]
    ticks = json.loads((out / "ticks.json").read_text())
    ticks = {k: (json.loads(v) if isinstance(v, str) else v) for k, v in ticks.items()}
    tick_end = dict(zip(ticks["ticks"], ticks["nanos"]))
    runs = json.loads((out / "runs.json").read_text())
    barriers = json.loads((out / "barriers.json").read_text())
    meta = json.loads((out / "meta.json").read_text())
    stepped = collections.Counter()
    step_wall = collections.defaultdict(float)
    for r in runs:
        key = "typical" if r["scene"].startswith("typical") else r["scene"]
        stepped[key] += r["steps"]
        step_wall[key] += r["wallMicros"] / 1000
    echo = {f["id"]: f for f in frames if f["type"] == 2}
    barrier_rows = collections.defaultdict(list)
    for bid, sent, scene in barriers:
        e = echo.get(bid)
        barrier_rows[scene].append((e["recv"] - sent) / 1e6 if e else None)

    def summarize(name, recs):
        recs = [f for f in recs if f["type"] == 1]
        if not recs:
            return {"records": 0}
        later = [f for f in recs[1:]]
        # A record of a tick is one whose frame was drawn in the same client loop as the tick (under 1 ms after it);
        # the others were drawn for a barrier or a reset.
        of_tick = [f for f in recs if f["tickEnd"] > 0 and 0 <= f["frameStart"] - f["tickEnd"] < 1_000_000]
        lat_server = [(f["recv"] - tick_end[f["tick"]]) / 1e6 for f in of_tick if f["tick"] in tick_end]
        lat_client = [(f["recv"] - f["tickEnd"]) / 1e6 for f in of_tick]
        essential = [5 + 8 + f["content"] for f in recs]
        diffs = [f["diff"] for f in later if f["diff"] >= 0]
        full_later = [5 + 8 + f["content"] for f in later]
        tags = collections.Counter(t for f in recs for t, _ in f["runs"])
        return {
            "records": len(recs),
            "bytes_essential": stat(essential, 1),
            "bytes_wire_with_timing": stat([f["wire"] for f in recs], 1),
            "full_bytes_after_first": sum(full_later), "diff_bytes_after_first": sum(diffs),
            "diff_over_full": round(sum(diffs) / sum(full_later), 3) if full_later else None,
            "build_ms": stat([f["build"] / 1e6 for f in recs]),
            "frame_ms": stat([(f["frameEnd"] - f["frameStart"]) / 1e6 for f in recs if f["frameStart"] > 0]),
            "a4_ms": stat([f["a4"] / 1e6 for f in recs if f["a4"] > 0]),
            "send_ms": stat([(f["recv"] - f["enq"]) / 1e6 for f in recs]),
            "tick_to_recv_ms_server": stat(lat_server),
            "tick_to_recv_ms_client": stat(lat_client),
            "changed": dict(collections.Counter(c for f in later for c in f["changed"])),
            "tags": dict(tags),
        }

    segs = segments(frames)
    by = collections.defaultdict(list)
    for name, fs in segs:
        key = "typical" if name.startswith("req:") else name
        by[key].extend(fs)
    rep = {"meta": meta, "scenes": {}}
    for key, fs in by.items():
        s = summarize(key, fs)
        s["ticks"] = stepped.get(key)
        s["ms_per_tick"] = round(step_wall[key] / stepped[key], 3) if stepped.get(key) else None
        if s["ticks"] and s["records"]:
            s["records_per_tick"] = round(s["records"] / s["ticks"], 3)
        s["barrier_ms"] = stat(barrier_rows.get(key, []))
        s["barriers_missing"] = sum(1 for v in barrier_rows.get(key, []) if v is None)
        rep["scenes"][key] = s
    # Tag reliability per scene: runs whose text names the scene's element, and how many carry the right tag.
    tagrep = {}
    for name, fs in segs:
        if name not in EXPECT:
            continue
        for sub, want in EXPECT[name]:
            seen = collections.Counter(t for f in fs if f["type"] == 1 for t, x in f["runs"] if sub in x)
            tagrep[f"{name}:{sub}"] = {"want": want, "seen": dict(seen)}
    rep["tags"] = tagrep
    others = collections.Counter(x for name, fs in segs for f in fs if f["type"] == 1 for t, x in f["runs"] if t == "other")
    rep["untagged_texts"] = dict(others.most_common(15))
    typ = [fs for name, fs in segs if name.startswith("req:")]
    if typ:
        recs = [sum(1 for f in fs if f["type"] == 1) for fs in typ]
        byt = [sum(5 + 8 + f["content"] for f in fs if f["type"] == 1) for fs in typ]
        dif = [sum((f["diff"] if f["diff"] >= 0 else 5 + 8 + f["content"]) for f in fs if f["type"] == 1) for fs in typ]
        rep["per_1000_typical"] = {"requirements": len(typ), "records": round(sum(recs) / len(typ) * 1000), "bytes_full": round(sum(byt) / len(typ) * 1000),
                                   "bytes_diff": round(sum(dif) / len(typ) * 1000), "records_per_req": stat(recs, 2), "bytes_per_req": stat(byt, 1)}
    (out / "report.json").write_text(json.dumps(rep, indent=1))
    return rep


def cmd_report(a):
    print(json.dumps(report(a.dir), indent=1))


def main(argv=None):
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    r = sub.add_parser("run")
    r.add_argument("--label", default="mac")
    r.add_argument("--machine", default="M1 Max, OpenGL 4.1 on Metal, 854x480, gate 2")
    r.add_argument("--scenes", default="actionbar,title,chat,boss,walk,walka4,typing,tags")
    r.add_argument("--typical", type=int, default=1000)
    r.add_argument("--park", type=int, default=2000)
    r.add_argument("--base-ticks", type=int, default=500)
    r.set_defaults(f=cmd_run)
    p = sub.add_parser("report")
    p.add_argument("dir")
    p.set_defaults(f=cmd_report)
    a = ap.parse_args(argv)
    print("uptime load", load(), flush=True)
    a.f(a)
    print("uptime load", load(), flush=True)


if __name__ == "__main__":
    main()
