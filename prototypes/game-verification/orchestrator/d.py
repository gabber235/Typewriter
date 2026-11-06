#!/usr/bin/env python3
"""Spike D: how many clients on how many Papers, and who disturbs whom.

  d.py fleet --layout 2 [--seconds 20] [--rate 200] [--scope server|player] [--join gated|together|stagger]
  d.py interfere [--seconds 8] [--spacing 1]

A fleet is a list of Papers, each with k clients, every client in its own region. Each client runs the
mixed requirement loop with the E signals: verdict E3t (fact polled every client loop, failed only by a
window barrier the server scheduler sends w ticks after the effect) and done E6 (plugin quiet barrier,
then a client loop with nothing in flight). The Mac runs it without Xvfb; ci.py plugs in Xvfb, the
renderer assertion and /proc CPU on the runner.
"""
import argparse, gzip, json, os, pathlib, random, statistics, sys, threading, time

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import run as R
from run import Client, RUNS, free_port, leak_check, rss_mb, stop_all
from speed import Line, TunedPaper, MATERIALS, needle_for, pct

RESULTS = RUNS / "d-clients.jsonl"
RAW = RUNS / "d-clients"
LEVEL, SCREEN_NONE, CHUNKS, HANDS = 16, 32, 64, 4096
READY = LEVEL | SCREEN_NONE | CHUNKS | HANDS

# The mixed set: kind, window in ticks (None: late chat d ticks after the command, window d + 2).
MIX = [("title", 2), ("chat", 2), ("block", 2), ("entity", 2), ("late", None), ("async", 4), ("chat", 2), ("late", None), ("title", 2), ("entity", 2)]
CHATTY = {"chat", "late", "async"}
hooks = {"env": lambda i: {}, "usage": None, "paper": TunedPaper, "client_kw": {}, "after_join": None, "record": None}


def record(kind, **row):
    if hooks["record"]:
        return hooks["record"](kind, **row)
    RUNS.mkdir(exist_ok=True)
    row = {"kind": kind, **row, "load1": round(os.getloadavg()[0], 1)}
    with RESULTS.open("a") as f:
        f.write(json.dumps(row) + "\n")
    print(json.dumps(row)[:1500], flush=True)


def stat(v):
    if not v:
        return None
    return {"n": len(v), "median": round(statistics.median(v), 1), "p95": round(pct(v, 95), 1), "max": round(max(v), 1)}


class NullUsage:
    def __init__(self, pids):
        pass

    def __enter__(self):
        return self

    def __exit__(self, *exc):
        return False

    def row(self):
        return {"load1": round(os.getloadavg()[0], 1)}


# ---------- one client ----------

class Node:
    def __init__(self, paper, i, gi, run, limit):
        self.paper, self.i, self.gi = paper, i, gi
        self.name = f"probe{gi + 1}"
        self.live = free_port()
        self.client = Client(run / f"client{gi}", name=self.name, xmx="1g", rd=2, facts_mode="changes", extra_jvm=[limit, f"-Dprobe.live.port={self.live}"],
                             env=hooks["env"](gi), **hooks["client_kw"])
        self.next_ping = 1000
        self.k = 0
        self.C = None
        self.S = None

    def pings(self, n):
        out = list(range(self.next_ping, self.next_ping + n))
        self.next_ping += n
        return out

    def connect(self, timeout=240):
        deadline = time.time() + timeout
        while True:
            try:
                self.C = Line(self.live)
                return
            except OSError:
                if time.time() > deadline:
                    raise
                time.sleep(0.2)

    def bits(self):
        return self.C("r.bits", radius=2)["bits"]

    def wait_ready(self, timeout=240, x=None):
        """E's start signal for facts and frames: level, no screen, radius chunks held, hands settled."""
        deadline = time.time() + timeout
        while time.time() < deadline:
            if self.C is not None:
                try:
                    if self.bits() & READY == READY:
                        if x is None:
                            return time.time()
                        st = self.C("state", timeoutMs=2000)
                        if st.get("ok") and abs(st["p"].get("pos", [0])[0] - x) < 2:
                            return time.time()
                except (RuntimeError, OSError):
                    pass
            time.sleep(0.05)
        raise TimeoutError(f"{self.name} not ready")


class PaperNode:
    def __init__(self, idx, k, run, limit, first_gi, rate):
        self.idx, self.rate = idx, rate
        self.line = free_port()
        self.server = hooks["paper"](run / f"server{idx}", tuned=True, view=3, world="void", xmx="1g", extra_jvm=[limit, f"-Dprobe.line.port={self.line}"])
        self.nodes = [Node(self, i, first_gi + i, run, limit) for i in range(k)]
        self.S = None

    def line_for(self):
        return Line(self.line, prefix="tick/")


class Fleet:
    """Papers each with k clients, started and joined, every client parked in its own region."""

    def __init__(self, layout, join="gated", spacing=64, rate=200, label=None):
        self.layout, self.join, self.spacing = list(layout), join, spacing
        self.label = label or "x".join(map(str, layout))
        self.run = RUNS / f"d-{self.label}-{int(time.time())}"
        limit = "-Dprobe.maxRuntimeSec=1500"
        self.papers, gi = [], 0
        for idx, k in enumerate(self.layout):
            self.papers.append(PaperNode(idx, k, self.run, limit, gi, rate))
            gi += k
        self.nodes = [n for p in self.papers for n in p.nodes]

    def __enter__(self):
        try:
            return self._enter()
        except BaseException:
            # Keep the logs of a failed join: __exit__ does not run when __enter__ raises.
            self.__exit__(None, None, None)
            raise

    def _enter(self):
        t0 = time.time()
        for p in self.papers:
            p.server.start()
        for p in self.papers:
            p.done_s = round(p.server.wait_done(), 2)
            p.S = p.line_for()
        self.paper_s = round(time.time() - t0, 1)
        for n in self.nodes:
            n.client.server = f"127.0.0.1:{n.paper.server.port}"
        t0 = time.time()
        self.join_each = {}
        if self.join in ("stagger", "stagger-gate"):
            # One at a time; stagger-gate stops drawing each client once it is ready, so it costs the next one nothing.
            for n in self.nodes:
                s0 = time.time()
                n.client.start()
                n.connect()
                n.wait_ready()
                if self.join == "stagger-gate":
                    n.C("gate", mode=2)
                self.join_each[n.name] = round(time.time() - s0, 1)
        elif self.join == "ready-gate":
            # All at once, each client stops drawing the moment it is ready.
            starts = {}
            for n in self.nodes:
                starts[n.name] = time.time()
                n.client.start()

            def one(n):
                n.connect()
                n.wait_ready()
                n.C("gate", mode=2)
                self.join_each[n.name] = round(time.time() - starts[n.name], 1)
            threads = [threading.Thread(target=one, args=(n,)) for n in self.nodes]
            for t in threads:
                t.start()
            for t in threads:
                t.join()
            missing = [n.name for n in self.nodes if n.name not in self.join_each]
            if missing:
                raise TimeoutError(f"not ready: {missing}")
        else:
            starts = {}
            for n in self.nodes:
                starts[n.name] = time.time()
                n.client.start()
            connectors = [threading.Thread(target=self._connect_gate, args=(n,)) for n in self.nodes]
            for t in connectors:
                t.start()
            for t in connectors:
                t.join()
            for n in self.nodes:
                n.wait_ready()
                self.join_each[n.name] = round(time.time() - starts[n.name], 1)
        self.joined_s = round(time.time() - t0, 1)
        if hooks["after_join"]:
            self.renderers = [hooks["after_join"](n.client) for n in self.nodes]
        for n in self.nodes:
            n.S = n.paper.line_for()
            if self.join not in ("stagger-gate", "ready-gate"):
                n.C("gate", mode=0 if self.join != "gated" else 1)
        for p in self.papers:
            p.S("e.calm")
            p.S("time", player=p.nodes[0].name)
        t1 = time.time()
        for n in self.nodes:
            r = n.S("region", player=n.name, idx=n.i, chunks=self.spacing)
            n.region_x = r["cx"] * 16 + 0.5
        for n in self.nodes:
            n.wait_ready(60, x=n.region_x)
            n.C("clearChat")
            n.C("clearToasts")
            n.C("gate", mode=2)
        self.region_s = round(time.time() - t1, 1)
        for p in self.papers:
            p.S("tickrate", player=p.nodes[0].name, rate=p.rate)
        self.pids = {n.name: n.client.java_pid() for n in self.nodes}
        for p in self.papers:
            self.pids[f"server{p.idx}"] = p.server.proc.p.pid
        time.sleep(0.5)
        return self

    def _connect_gate(self, n):
        """Gated join: render nothing from the first moment, but keep extract so sections still compile."""
        n.connect()
        if self.join == "gated":
            n.C("gate", mode=1)

    def rss(self):
        return {k: rss_mb(v) for k, v in self.pids.items() if v}

    def __exit__(self, *exc):
        for n in self.nodes:
            try:
                n.client.stop()
            except Exception:
                pass
        for p in self.papers:
            try:
                p.server.stop()
            except Exception:
                pass
        stop_all()
        if hooks.get("cleanup"):
            hooks["cleanup"](self)
        import shutil
        shutil.rmtree(self.run, ignore_errors=True)
        return False


# ---------- one requirement with the E signals ----------

def strip(p):
    """Perceived state without clocks, for E6's "equal to the loop before"."""
    return {k: v for k, v in p.items() if k not in ("titleTime", "barTime", "ping", "loaded", "vel")}


def calm(prev, cur):
    p = cur["p"]
    fade = p.get("fade", [0, 0, 0])
    fading_in = p.get("title") not in (None, "null") and p.get("titleTime", 0) > fade[1] + fade[2]
    return "readyAt" in p and not fading_in and strip(prev["p"]) == strip(cur["p"])


def e6(n, scope, qping, timeout=20):
    """Done: the plugin quiet barrier (server wide or this player's work), then a client loop with nothing in flight."""
    n.S("d.quiet", _dispatch="direct", player=n.name, scope=scope, qping=qping)
    prev = n.C("state", ping=qping, timeoutMs=int(timeout * 1000))
    if not prev.get("ok"):
        raise RuntimeError(f"{n.name}: quiet barrier {qping} never acked")
    t_quiet = time.perf_counter()
    deadline = time.time() + 3
    while time.time() < deadline:
        cur = n.C("state", timeoutMs=2000)
        if calm(prev, cur):
            return cur, t_quiet
        prev = cur
    return prev, t_quiet


def expect(kind, token, broken, material):
    """What the player should perceive at done: own effect only."""
    e = {"chat": [], "title": None, "ents": [], "block": "minecraft:air"}
    if broken:
        return e
    if kind in CHATTY or kind == "bcast":
        e["chat"] = [token]
    if kind in ("title", "titleall"):
        e["title"] = token
    if kind in ("entity", "wentity"):
        e["ents"] = [token]
    if kind == "block":
        e["block"] = f"minecraft:{material.lower()}"
    return e


def particles(held):
    """countParticles() is "<group> <count> ..." per render type."""
    words = str(held.get("particles", "")).split()
    return sum(int(w) for w in words if w.isdigit())


def leaks_in(p, e, me, extra=None, base=None):
    """Everything the player perceives that its own requirement did not cause."""
    out = {}
    title = p.get("title")
    title = None if title in (None, "null") else title
    if p.get("chat", []) != e["chat"]:
        out["chat"] = p.get("chat")
    if title != e["title"] and (title is not None or e["title"] is not None):
        out["title"] = title
    if p.get("relBlock") != e["block"]:
        out["block"] = p.get("relBlock")
    ents = [x for x in p.get("entities", []) if x.get("type") != "minecraft:player"]
    names = sorted((x.get("name") or x.get("text") or x["type"]) for x in ents)
    if names != sorted(e["ents"]):
        out["entity"] = names
    others = [x for x in p.get("entities", []) if x.get("type") == "minecraft:player"]
    if len(others) > 1:
        out["player"] = len(others) - 1
    if extra is not None:
        if extra.get("boss"):
            out["boss"] = [b["name"] for b in extra["boss"]]
        if extra.get("sidebar"):
            out["sidebar"] = extra["sidebar"].get("title")
        # setTime back to noon moves the clock a day forward, so compare the time of day.
        if base is not None and extra.get("day") % 24000 != base.get("day") % 24000:
            out["day"] = extra.get("day") % 24000
        if extra.get("rain", 0) > 0:
            out["rain"] = extra["rain"]
        if base is not None and particles(extra) > particles(base):
            out["particles"] = particles(extra)
        # Background music starts by itself on the client; it is nobody's leak.
        heard = [s["id"] for s in extra.get("sounds", []) if not s["id"].startswith("minecraft:music")]
        if heard:
            out["sound"] = heard[:3]
    return out


def requirement(n, k, kind, w, scope="server", broken=False, late=0, check=False, base=None, rnd=None, params=None):
    """One requirement: effect, E3t verdict, E6 done, leftover check, reset. Returns one raw row."""
    rnd = rnd or random
    token = f"{n.name}R{k}"
    material = MATERIALS[k % len(MATERIALS)]
    wping, qping, rping = n.pings(3)
    sound_seq = n.C("sounds", since=10 ** 12)["seq"] if check else None
    t0 = time.perf_counter()
    q = dict(player=n.name, kind=kind, token=token, w=w, broken=int(broken), wping=wping, material=material, late=late, **(params or {}))
    n.S("d.req", **q)
    t_sent = time.perf_counter()
    needle_kind = {"late": "chat", "async": "chat", "bcast": "chat", "titleall": "title"}.get(kind, kind)
    if needle_kind in ("title", "chat", "block", "entity"):
        obs = n.C("observe", needle=needle_for(needle_kind, token, material), ping=wping, timeoutMs=20000)
        ok = obs["ok"]
        why = obs["why"]
    else:
        st = n.C("state", ping=wping, timeoutMs=20000)
        ok, why = bool(st.get("ok")), "window"
    t_verdict = time.perf_counter()
    cur, t_quiet = e6(n, scope, qping)
    t_done = time.perf_counter()
    row = {"c": n.name, "k": k, "kind": kind, "w": w, "broken": broken, "ok": ok, "why": why, "wrong": ok == broken if needle_kind in ("title", "chat", "block", "entity") else False,
           "sent_ms": round((t_sent - t0) * 1000, 2), "verdict_ms": round((t_verdict - t0) * 1000, 2), "quiet_ms": round((t_quiet - t_verdict) * 1000, 2),
           "done_ms": round((t_done - t0) * 1000, 2), "server_tick": None}
    extra = None
    if check:
        extra = n.C("held")
        extra["sounds"] = n.C("sounds", since=sound_seq)["sounds"]
    leaks = leaks_in(cur["p"], expect(kind, token, broken, material), n.name, extra, base)
    if leaks:
        row["leaks"] = leaks
    n.S("d.reset", player=n.name, ping=rping)
    n.C("clearChat")
    n.C("state", ping=rping, timeoutMs=20000)
    row["total_ms"] = round((time.perf_counter() - t0) * 1000, 2)
    row["t"] = round(time.time(), 3)
    return row


def mixed(n, k, rnd, scope, check=False, base=None):
    kind, w = MIX[k % len(MIX)]
    late = 0
    if kind == "late":
        late = rnd.randint(1, 8)
        w = late + 2
    if kind == "async":
        # Wall clock work under a tick window: 4 ticks is 20 ms at rate 200, shorter than the work (wrong 22 of 51 on
        # the Mac). The window must cover the work at the fastest rate the suite runs.
        w = max(4, 4 * n.paper.rate // 20)
    broken = (k + 1) % 10 == 0
    return requirement(n, k, kind, w, scope=scope, broken=broken, late=late, check=check, base=base, rnd=rnd)


def loop(n, until, scope, out, check=False, base=None, stop=None):
    rnd = random.Random(n.gi * 1000 + n.k)
    rows = []
    try:
        while time.time() < until and not (stop and stop.is_set()):
            rows.append(mixed(n, n.k, rnd, scope, check=check, base=base))
            n.k += 1
    except Exception as e:
        rows.append({"c": n.name, "error": repr(e)[:300]})
    out[n.name] = rows


def summarise(rows, wall, n_clients):
    good = [r for r in rows if "error" not in r]
    passes = [r for r in good if not r["broken"]]
    fails = [r for r in good if r["broken"]]
    leak_kinds = {}
    for r in good:
        for k in r.get("leaks", {}):
            leak_kinds[k] = leak_kinds.get(k, 0) + 1
    return {"requirements": len(good), "per_min": round(len(good) / wall * 60), "per_min_per_client": round(len(good) / wall * 60 / max(1, n_clients)),
            "wrong": sum(r["wrong"] for r in good), "errors": [r["error"] for r in rows if "error" in r][:4],
            "total_ms": stat([r["total_ms"] for r in good]), "pass_verdict_ms": stat([r["verdict_ms"] for r in passes]),
            "fail_verdict_ms": stat([r["verdict_ms"] for r in fails]), "quiet_ms": stat([r["quiet_ms"] for r in good]),
            "done_after_verdict_ms": stat([r["done_ms"] - r["verdict_ms"] for r in good]), "leaks": leak_kinds}


def save_raw(name, rows):
    RAW.mkdir(parents=True, exist_ok=True)
    with gzip.open(RAW / f"{name}.jsonl.gz", "at") as f:
        for r in rows:
            f.write(json.dumps(r) + "\n")


def measure(fleet, seconds, scope, label, nodes=None, check=False, base=None):
    nodes = nodes or fleet.nodes
    out = {}
    until = time.time() + seconds
    usage = (hooks["usage"] or NullUsage)({k: v for k, v in fleet.pids.items() if v})
    with usage as u:
        threads = [threading.Thread(target=loop, args=(n, until, scope, out), kwargs={"check": check, "base": base}) for n in nodes]
        t0 = time.time()
        for t in threads:
            t.start()
        for t in threads:
            t.join()
        wall = time.time() - t0
    rows = [r for n in nodes for r in out.get(n.name, [])]
    save_raw(label, rows)
    return {**summarise(rows, wall, len(nodes)), "wall_s": round(wall, 1), "scope": scope, **u.row()}


def fleet_cell(layout, seconds=20, rate=200, scopes=("server", "player"), join="gated", spacing=64, label=None):
    """Throughput of one arrangement, once per E6 scope."""
    label = label or f"{'x'.join(map(str, layout))}-r{rate}-{join}"
    with Fleet(layout, join=join, spacing=spacing, rate=rate, label=label) as f:
        row = {"layout": layout, "clients": len(f.nodes), "papers": len(f.papers), "rate": rate, "join": join, "spacing": spacing, "paper_s": f.paper_s,
               "joined_s": f.joined_s, "join_each_s": f.join_each, "region_s": f.region_s}
        row["phases"] = []
        for scope in scopes:
            row["phases"].append(measure(f, seconds, scope, f"{label}-{scope}-{int(time.time())}"))
        row["rss_mb"] = f.rss()
        if hooks.get("renderer_row"):
            row["renderer"] = hooks["renderer_row"](f)
    record("fleet", label=label, **row)
    return row


# ---------- interference ----------

def aggressor(n, kind, scope, until, hold, out, params=None, between=0.3, rate=None, render=False, base=None):
    """Runs one leaky requirement over and over: effect, held for `hold` ticks, done, reset."""
    rows, k, seen = [], 0, {}
    try:
        if render:
            n.C("gate", mode=0)
        if rate:
            n.S("tickrate", player=n.name, rate=rate)
        while time.time() < until:
            t0 = time.perf_counter()
            wping, qping, rping = n.pings(3)
            seq = n.C("sounds", since=10 ** 12)["seq"]
            n.S("d.req", player=n.name, kind=kind, token=f"LEAK{n.name}K{k}", w=hold, broken=0, wping=wping, material="GOLD_BLOCK", late=0, scope=scope, **(params or {}))
            st = n.C("state", ping=wping, timeoutMs=20000)
            # Self check: the aggressor must perceive its own effect, or a 0 on the victims proves nothing.
            extra = n.C("held")
            extra["sounds"] = n.C("sounds", since=seq)["sounds"]
            for key in leaks_in(st["p"], expect("none", "", True, "GOLD_BLOCK"), n.name, extra, base):
                seen[key] = seen.get(key, 0) + 1
            e6(n, "player", qping)
            n.S("d.reset", player=n.name, ping=rping)
            n.C("clearChat")
            n.C("state", ping=rping, timeoutMs=20000)
            rows.append(round((time.perf_counter() - t0) * 1000, 1))
            k += 1
            time.sleep(between)
    except Exception as e:
        rows.append(repr(e)[:300])
    finally:
        if rate:
            n.S("tickrate", player=n.name, rate=n.paper.rate)
        if render:
            n.C("gate", mode=2)
    out["aggressor"] = rows
    out["aggressor_sees"] = seen


def interfere_phase(fleet, agg, victims, name, kind, scope, seconds, victim_scope="server", hold=10, params=None, rate=None, render=False, base=None, between=0.3):
    out = {}
    until = time.time() + seconds
    usage = (hooks["usage"] or NullUsage)({k: v for k, v in fleet.pids.items() if v})
    with usage as u:
        threads = [threading.Thread(target=loop, args=(n, until, victim_scope, out), kwargs={"check": True, "base": base}) for n in victims]
        if kind:
            threads.append(threading.Thread(target=aggressor, args=(agg, kind, scope, until, hold, out), kwargs={"params": params, "rate": rate, "render": render, "between": between, "base": base}))
        t0 = time.time()
        for t in threads:
            t.start()
        for t in threads:
            t.join()
        wall = time.time() - t0
    rows = [r for n in victims for r in out.get(n.name, [])]
    save_raw(f"{fleet.label}-{name}", rows)
    agg_rows = out.get("aggressor", [])
    return {"phase": name, "leak": kind, "scope": scope, "victim_scope": victim_scope, **summarise(rows, wall, len(victims)), "wall_s": round(wall, 1),
            "aggressor_n": len([a for a in agg_rows if isinstance(a, float)]), "aggressor_sees": out.get("aggressor_sees"), "aggressor_errors": [a for a in agg_rows if isinstance(a, str)][:2], **u.row()}


# Leak, world wide scope against its per player counterpart; spatial ones depend on spacing.
LEAKS = [
    ("bcast", "world"), ("bcast", "player"),
    ("titleall", "world"), ("titleall", "player"),
    ("time", "world"), ("time", "player"),
    ("weather", "world"), ("weather", "player"),
    ("boss", "world"), ("boss", "player"),
    ("sidebar", "world"), ("sidebar", "player"),
    ("wentity", "world"), ("wentity", "player"),
    ("sound", "world"), ("sound", "player"),
    ("particle", "world"), ("particle", "player"),
]


def interfere(layout=(4,), seconds=8, spacing=1, label=None, leaks=LEAKS, server_wide=True):
    """Client 0 is the aggressor; the rest run the mixed set with a leftover check after every done."""
    label = label or f"int-{'x'.join(map(str, layout))}-s{spacing}"
    # Particles on: the shared options turn them to minimal, which hides every particle a neighbour sends.
    plain = R.options_txt
    R.options_txt = lambda *a, **k: plain(*a, **k).replace("particles:2", "particles:0")
    try:
        return _interfere(layout, seconds, spacing, label, leaks, server_wide)
    finally:
        R.options_txt = plain


def _interfere(layout, seconds, spacing, label, leaks, server_wide):
    with Fleet(layout, join="gated", spacing=spacing, rate=200, label=label) as f:
        agg = f.nodes[0]
        victims = f.nodes[1:]
        agg.C("clearChat")
        base = victims[0].C("held")
        phases = [interfere_phase(f, agg, victims, "baseline", None, None, seconds, base=base)]
        for kind, scope in leaks:
            phases.append(interfere_phase(f, agg, victims, f"{kind}-{scope}", kind, scope, seconds, base=base))
        if server_wide:
            phases.append(interfere_phase(f, agg, victims, "lag400", "lag", "world", seconds, hold=4, params={"lagMs": 400}, base=base, between=0.6))
            for vs in ("server", "player"):
                phases.append(interfere_phase(f, agg, victims, f"slowasync-{vs}", "slowasync", "player", seconds, victim_scope=vs, hold=2, params={"asyncMs": 300}, base=base, between=0.0))
            phases.append(interfere_phase(f, agg, victims, "rate10-render", "none", "player", seconds, hold=10, rate=10, render=True, base=base, between=0.0))
            phases.append(interfere_phase(f, agg, victims, "baseline-end", None, None, seconds, base=base))
        row = {"layout": list(layout), "spacing": spacing, "joined_s": f.joined_s, "base_held": {k: base.get(k) for k in ("day", "rain", "particles")}, "phases": phases, "rss_mb": f.rss()}
    record("interfere", label=label, **row)
    return row


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("what", choices=["fleet", "interfere"])
    ap.add_argument("--layout", default="1")
    ap.add_argument("--seconds", type=float, default=15)
    ap.add_argument("--rate", type=int, default=200)
    ap.add_argument("--scope", default="server,player")
    ap.add_argument("--join", default="gated")
    ap.add_argument("--spacing", type=int, default=64)
    ap.add_argument("--leaks", default="")
    a = ap.parse_args()
    layout = [int(x) for x in a.layout.split("x")]
    try:
        if a.what == "fleet":
            fleet_cell(layout, a.seconds, a.rate, a.scope.split(","), a.join, a.spacing)
        else:
            leaks = [tuple(x.split(":")) for x in a.leaks.split(",")] if a.leaks else LEAKS
            interfere(tuple(layout), a.seconds, a.spacing, leaks=leaks)
    finally:
        stop_all()
        print("leaks", leak_check())


if __name__ == "__main__":
    main()
