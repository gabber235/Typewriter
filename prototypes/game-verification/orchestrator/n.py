#!/usr/bin/env python3
"""Spike N: the test runner decides when each tick happens.

  n.py freeze [--label mac]                          N1: what still runs under vanilla's tick freeze
  n.py steps --n 2000 [--park 2000,200]              cost of one stepped tick (server only, and with the client acking)
  n.py req --n 200 [--kinds ...]                     requirements under stepping: verdicts, effect step, seconds
  n.py exact --n 100                                 window k against an effect k ticks late: pass at w=k, fail at w=k-1
  n.py base --n 500                                  same trivial requirement unstepped at rate 200 (C's recipe)
  n.py break --n 200 [--lag tick|wall]               J's break and cancelled break, client and server in lockstep
  n.py pause --seconds 35                            the runner stops stepping: does anything drop the client

Paper runs with the step agent (orchestrator adds -javaagent). The plugin's step policy grants the next tick
only when the client acked the previous one and the subject's async work is quiet; the client's clock moves
one tick per step ping. Every command stops what it started and checks for leftover processes.
"""
import argparse, collections, json, os, pathlib, random, statistics, sys, time

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import k as K
from run import RUNS, ROOT, leak_check, front_app

AGENT = ROOT / "step-agent/build/libs/step-agent-0.jar"
RESULTS = RUNS / "n.jsonl"
hooks = {"record": None}

# kind -> (window ticks, params). Windows are E's and D's: chat 2, late k + 2, async 4.
KINDS = {
    "chat": (2, {}),
    "late": (None, {}),
    "asyncx": (4, {}),
    "async": (4, {}),
    "asyncslow": (4, {}),
    "asyncsync": (4, {}),
}


def load():
    return round(os.getloadavg()[0], 1)


def record(kind, **row):
    row = {"kind": kind, "at": time.strftime("%Y-%m-%dT%H:%M:%S"), "load": load(), **row}
    RUNS.mkdir(exist_ok=True)
    with RESULTS.open("a") as f:
        f.write(json.dumps(row) + "\n")
    if hooks["record"]:
        hooks["record"]("n-" + kind, **{k: v for k, v in row.items() if k != "kind"})
    print(json.dumps(row)[:1500], flush=True)


def stat(v):
    v = sorted(x for x in v if x is not None)
    if not v:
        return None
    q = lambda p: v[min(len(v) - 1, int(len(v) * p))]
    return {"n": len(v), "med": round(statistics.median(v), 4), "p95": round(q(0.95), 4), "max": round(v[-1], 4), "min": round(v[0], 4)}


class Rig(K.Rig):
    """K's rig with the step agent on Paper."""

    def __init__(self, label, lag="wall", gate=2):
        super().__init__(label, clients=1, gate=gate)
        self.label = f"{label}-{int(time.time())}"
        args = "lag=tick" if lag == "tick" else "lag=wall"
        self.paper.jvm.append(f"-javaagent:{AGENT}={args}")
        setup = self.paper.setup

        def setup_without_packet_limit():
            # Paper's packet limiter counts packets per wall clock second (500 per s over 7 s) and kicks a client
            # stepped faster than about 170 ticks per s, since the client sends 2 to 3 packets per tick.
            setup()
            cfg = self.paper.dir / "config" / "paper-global.yml"
            cfg.write_text(cfg.read_text().replace("max-packet-rate: 500.0", "max-packet-rate: 0.0", 1))
        self.paper.setup = setup_without_packet_limit

    def __enter__(self):
        super().__enter__()
        self.c = self.clients[0]
        self.S, self.C, self.p = self.paper.S, self.c.C, self.c.name
        log = (self.paper.dir / "server.log").read_text(errors="replace")
        self.prefixed = sorted({l.split("prefixed ", 1)[1].strip() for l in log.splitlines() if "[step-agent] prefixed" in l})
        print("agent prefixed:", self.prefixed, flush=True)
        return self

    def __exit__(self, *exc):
        try:
            self.S("n.mode", _dispatch="direct", on=0, auto=0)
        except Exception as e:
            print("step off at exit:", e, file=sys.stderr)
        logs = RUNS / "n-logs"
        logs.mkdir(parents=True, exist_ok=True)
        for src, name in ((self.paper.dir / "server.log", "server"), (self.c.client.dir / "client.log", "client")):
            try:
                (logs / f"{self.label}-{name}.log").write_bytes(src.read_bytes())
            except Exception as e:
                print("log copy:", e, file=sys.stderr)
        return super().__exit__(*exc)

    def step_on(self, auto=False, ack=True, quiet=True, limit_ms=1000, lag=None):
        q = dict(on=1, subject=self.p, ack=int(ack), quiet=int(quiet), auto=int(auto), limitMs=limit_ms)
        if lag:
            q["lag"] = lag
        self.C("n.mode", on=1)
        return self.S("n.mode", _dispatch="direct", **q)

    def step_off(self):
        self.S("n.mode", _dispatch="direct", on=0, auto=0)
        self.C("n.mode", on=0)

    def steps_run(self, max_steps, stop_on_seen=True, timeout_ms=60000):
        return self.S("n.run", max=max_steps, stopOnSeen=int(stop_on_seen), timeoutMs=timeout_ms)


def cmd_freeze(a):
    with Rig(f"n-{a.label}") as rig:
        r = rig.S("n.freeze", seconds=a.seconds, steps=a.steps)
        record("freeze", label=a.label, **r)
    leak_check()


def cmd_steps(a):
    """Stepping stays on for the whole command; only the policy (ack) and the client's gate park change."""
    with Rig(f"n-{a.label}") as rig:
        rows = []
        rig.step_on(ack=True)
        rig.steps_run(200, stop_on_seen=False)  # warm both sides
        for park in [int(x) for x in a.park.split(",")]:
            rig.C("gate", mode=2, parkMicros=park)
            for ack in (False, True):
                rig.S("n.mode", _dispatch="direct", ack=int(ack))
                rig.steps_run(50, stop_on_seen=False)
                c0 = rig.C("n.stats")
                s0 = rig.S("n.stats", _dispatch="direct")
                t0 = time.perf_counter()
                r = rig.steps_run(a.n, stop_on_seen=False)
                wall = time.perf_counter() - t0
                c1 = rig.C("n.stats")
                s1 = rig.S("n.stats", _dispatch="direct")
                rows.append(dict(park_us=park, ack=ack, n=a.n, ms_per_step=round(r["wallMicros"] / a.n / 1000, 4),
                                 ack_wait_ms_per_step=round(r["ackWaitMicros"] / a.n / 1000, 4),
                                 client_ticks=c1["clientTicks"] - c0["clientTicks"], client_steps=c1["steps"] - c0["steps"],
                                 client_extra=c1["extraTicks"] - c0["extraTicks"], server_ticks=r["tick"] - r["tick0"],
                                 pings=s1["pingsSent"] - s0["pingsSent"], acks=s1["acksReceived"] - s0["acksReceived"],
                                 client_loops=c1["loops"] - c0["loops"],
                                 wake_to_grant_us=round((c1["wakeToGrantUs"] - c0["wakeToGrantUs"]) / a.n, 1),
                                 grant_to_ack_us=round((c1["grantToAckUs"] - c0["grantToAckUs"]) / a.n, 1),
                                 wall_s=round(wall, 3), load=load()))
                print(rows[-1], flush=True)
        rig.step_off()
        record("steps", label=a.label, rows=rows)
    leak_check()


def one_req(rig, kind, w, broken, late=0, async_ms=0):
    tok = f"n{random.randrange(10**9)}"
    t0 = time.perf_counter()
    rig.C("n.watch", needle=tok)
    q = rig.S("n.req", _dispatch="direct", player=rig.p, kind=kind, token=tok, late=late, asyncMs=async_ms, broken=int(broken))
    r = rig.steps_run(w)
    t1 = time.perf_counter()
    passed = r["seenStep"] >= 0
    return {"kind": kind, "w": w, "late": late, "asyncMs": async_ms, "broken": broken, "pass": passed, "wrong": passed == broken,
            "seenStep": r["seenStep"], "effectTicks": (r["effectTick"] - q["stimTick"]) if r["effectTick"] >= 0 else None,
            "steps": r["steps"], "hung": r["hung"], "quietMs": r["quietWaitMicros"] / 1000, "s": t1 - t0}


def summarize(rows):
    by = collections.defaultdict(list)
    for r in rows:
        by[(r["kind"], r["w"], r.get("late", 0), r["broken"])].append(r)
    out = []
    for (kind, w, late, broken), rs in sorted(by.items(), key=lambda x: str(x[0])):
        out.append({"kind": kind, "w": w, "late": late, "broken": broken, "n": len(rs), "wrong": sum(r["wrong"] for r in rs),
                    "seenStep": dict(collections.Counter(r["seenStep"] for r in rs)),
                    "effectTicks": dict(collections.Counter(r["effectTicks"] for r in rs)),
                    "hung": sum(r["hung"] for r in rs), "quietMs": stat([r["quietMs"] for r in rs]), "s": stat([r["s"] for r in rs])})
    return out


def cmd_req(a):
    kinds = a.kinds.split(",")
    with Rig(f"n-{a.label}") as rig:
        rig.C("gate", mode=2, parkMicros=a.park)
        rig.step_on(limit_ms=a.limit_ms)
        rows = []
        t0 = time.time()
        for i in range(a.n):
            for kind in kinds:
                broken = i % 5 == 4
                late, ms = 0, 0
                if kind == "late":
                    late = 1 + i % 8
                    w = late + 2
                elif kind == "asyncslow":
                    ms, w = random.randint(50, 150), 4
                elif kind in ("async", "asyncx", "asyncsync"):
                    ms, w = (random.randint(0, 20) if a.async_ms < 0 else a.async_ms), 4
                elif kind == "hang":
                    w, broken = 4, True
                else:
                    w = KINDS[kind][0]
                rows.append(one_req(rig, "async" if kind == "asyncslow" else kind, w, broken, late, ms))
                rows[-1]["kind"] = kind if a.async_ms < 0 or kind not in ("async", "asyncx", "asyncsync") else f"{kind}{a.async_ms}ms"
            if i % 50 == 49:
                rig.C("clearChat")
                print(f"{i + 1} {time.time() - t0:.0f}s load {load()}", flush=True)
        rig.step_off()
        summ = summarize(rows)
        for s in summ:
            print(s, flush=True)
        good = [r for r in rows if not r["broken"]]
        record("req", label=a.label, n=a.n, kinds=kinds, park_us=a.park, wall_s=round(time.time() - t0, 1), wrong=sum(r["wrong"] for r in rows),
               total=len(rows), pass_s=stat([r["s"] for r in good if r["kind"] in ("chat",)]), fail_s=stat([r["s"] for r in rows if r["broken"] and r["kind"] == "chat"]),
               summary=summ)
    leak_check()


def cmd_exact(a):
    with Rig(f"n-{a.label}") as rig:
        rig.C("gate", mode=2, parkMicros=a.park)
        rig.step_on()
        rows = []
        for i in range(a.n):
            late = 1 + i % 8
            for w in (late, late - 1):
                if w < 1:
                    continue
                r = one_req(rig, "late", w, False, late)
                r["wrong"] = r["pass"] != (w >= late)
                rows.append(r)
            if i % 50 == 49:
                rig.C("clearChat")
        rig.step_off()
        summ = summarize(rows)
        for s in summ:
            print(s, flush=True)
        record("exact", label=a.label, n=a.n, wrong=sum(r["wrong"] for r in rows), total=len(rows), summary=summ)
    leak_check()


def cmd_base(a):
    """C's R4 tick recipe on this rig, unstepped, at rate 200: chat on the next tick, window barrier right after."""
    with Rig(f"n-{a.label}") as rig:
        rig.C("gate", mode=2, parkMicros=a.park)
        rig.S("tickrate", rate=a.rate)
        rig.C("uncap", on=1)
        rows = []
        for i in range(a.n):
            tok = f"b{random.randrange(10**9)}"
            ping = rig.c.next_ping()
            t0 = time.perf_counter()
            rig.S("act", player=rig.p, kind="chat", token=tok, broken="0", ping=ping)
            o = rig.C("observe", needle=tok, ping=ping, timeoutMs=2000)
            rows.append({"ok": o["ok"], "s": time.perf_counter() - t0})
        record("base", label=a.label, rate=a.rate, n=a.n, wrong=sum(not r["ok"] for r in rows), s=stat([r["s"] for r in rows]))
        rig.S("tickrate", rate=20)
    leak_check()


class Shim:
    def __init__(self, rig):
        self.S, self.C, self.p, self.front = rig.S, rig.C, rig.p, front_app()


def cmd_break(a):
    import input as I
    with Rig(f"n-{a.label}", lag=a.lag) as rig:
        b = I.Bench(Shim(rig))
        if a.trace:
            for op in ("break", "breakCancel"):
                I.OPS[op][1]["trace"] = "1"
        rig.C("in.setup", focus="fake", grab="fake")
        rig.C("gate", mode=2, parkMicros=a.park)
        mode = a.mode
        if mode == "step":
            rig.step_on(auto=True, lag=a.lag)
        else:
            rig.S("tickrate", rate=int(mode))
            rig.C("uncap", on=1)
            rig.S("n.mode", _dispatch="direct", lag=a.lag)
        rows = []
        t0 = time.time()
        for i in range(a.n):
            for op in a.ops.split(","):
                st0 = rig.S("n.stats", _dispatch="direct")
                try:
                    r = b.one(op, "J2")
                except Exception as e:
                    r = {"op": op, "ok": False, "error": str(e)[:200], "total_s": None}
                st1 = rig.S("n.stats", _dispatch="direct")
                r["serverTicks"] = st1["tick"] - st0["tick"]
                r["lagTicks"] = st1["lagTick"] - st0["lagTick"]
                keep = ("op", "ok", "error", "total_s", "ticks", "serverTicks", "lagTicks", "ev")
                if a.trace:
                    keep += ("pk", "notes", "late", "raw")
                rows.append({k: r.get(k) for k in keep})
            if i % 20 == 19:
                print(f"{i + 1} {time.time() - t0:.0f}s load {load()}", flush=True)
        if mode == "step":
            rig.step_off()
        else:
            rig.S("tickrate", rate=20)
        by = collections.defaultdict(list)
        for r in rows:
            by[r["op"]].append(r)
        summ = []
        for op, rs in by.items():
            summ.append({"op": op, "n": len(rs), "ok": sum(bool(r["ok"]) for r in rs), "errors": sum(1 for r in rs if r.get("error")),
                         "s": stat([r["total_s"] for r in rs]), "serverTicks": stat([r["serverTicks"] for r in rs]),
                         "lagTicks": stat([r["lagTicks"] for r in rs]),
                         "evVariants": len(collections.Counter(json.dumps(r.get("ev")) for r in rs)),
                         "firstError": next((r["error"] for r in rs if r.get("error")), None)})
        for s in summ:
            print(s, flush=True)
        record("break", label=a.label, mode=mode, lag=a.lag, n=a.n, wall_s=round(time.time() - t0, 1), summary=summ,
               **({"rows": rows} if a.trace else {}))
    leak_check()


def cmd_pause(a):
    """Stepping on, nobody steps for `seconds`: then one step and a chat requirement."""
    with Rig(f"n-{a.label}") as rig:
        rig.step_on()
        t0 = time.time()
        time.sleep(a.seconds)
        gone = rig.C("k.gone", timeoutMs=1)
        after = None
        err = None
        try:
            after = one_req(rig, "chat", 2, False)
        except Exception as e:
            err = str(e)[:300]
        st = rig.S("n.stats", _dispatch="direct")
        rig.step_off()
        log = (rig.paper.dir / "server.log").read_text(errors="replace")
        hits = [l[:200] for l in log.splitlines() if any(x in l for x in ("Watchdog", "timed out", "Timed out", "Can't keep up", "lost connection", "Not Responding", "stopped responding"))]
        record("pause", label=a.label, seconds=a.seconds, waited_s=round(time.time() - t0, 1), client_gone=gone, after=after, error=err,
               stats=st, server_log=hits[:20])
    leak_check()


def main(argv=None):
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    def add(name, f, **defaults):
        p = sub.add_parser(name)
        p.add_argument("--label", default="mac")
        p.add_argument("--park", type=int if name != "steps" else str, default=defaults.pop("park", 2000))
        for k, v in defaults.items():
            p.add_argument("--" + k.replace("_", "-"), type=type(v), default=v)
        p.set_defaults(f=f)
    add("freeze", cmd_freeze, seconds=2, steps=10)
    add("steps", cmd_steps, n=2000, park="2000,200")
    add("req", cmd_req, n=200, kinds="chat,late,asyncx,async,asyncslow,asyncsync", limit_ms=1000, async_ms=-1)
    add("exact", cmd_exact, n=100)
    add("base", cmd_base, n=500, rate=200)
    add("break", cmd_break, n=200, ops="break,breakCancel", lag="tick", mode="step", trace=0)
    add("pause", cmd_pause, seconds=35)
    a = ap.parse_args(argv)
    print("uptime load", load(), flush=True)
    a.f(a)
    print("uptime load", load(), flush=True)


if __name__ == "__main__":
    main()
