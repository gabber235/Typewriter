#!/usr/bin/env python3
"""Frames spike: what do drawn frames and the live perception stream cost the shared stepped Paper (topology A)?

  frames.py run --instances "default;lp=1;w=427x240" [--n 1000] [--warm 99] [--label mac]

Topology A from topo.py (one stepped Paper shared by 4 warm gated clients, no restarts), P1's requirement mix
(10 percent async, 10 percent broken, chat now or 1 to 8 ticks late, groups of 2 or 3 at the given share). Every
variant runs the same requirements (fixed seeds) on the same rig, so variants compare within one job.

An instance is one client configuration (needs fresh clients): lp=N (LP_NUM_THREADS), bg=N (max.bg.threads,
the client's own worker pool), w=WxH (window size). Inside an instance the runtime variants switch live:

  base          stream off, no frames, the verdict from the step ack (P1 exactly)
  fack          stream on, a frame after every client tick, the verdict still from the step ack
  f             stream on, a frame after every client tick, the verdict from the stream
  demand        stream on, frames only while a check of the client's requirement waits, verdict from the stream
  wake          as f, and barrier pings wake the parked render thread
  demand+wake   both levers

Stream verdict: pass once every member's stream holds a legible chat run with the token (the test process then
ends the attempt with n.end); when the window runs out Paper sends each member a barrier, and the verdict is
what the member's stream held when the echo arrived.
"""
import argparse, concurrent.futures, json, os, pathlib, random, socket, statistics, struct, sys, threading, time

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import k as K
import run as R
import topo as T
from run import RUNS, leak_check, stop_all

RESULTS = RUNS / "frames.jsonl"
hooks = {"record": None}

VARIANTS = {
    "base": dict(stream=False, every=1, wake=0, verdict="ack"),
    "fack": dict(stream=True, every=1, wake=0, verdict="ack"),
    "f": dict(stream=True, every=1, wake=0, verdict="stream"),
    "demand": dict(stream=True, every=0, wake=0, verdict="stream"),
    "wake": dict(stream=True, every=1, wake=1, verdict="stream"),
    "demand+wake": dict(stream=True, every=0, wake=1, verdict="stream"),
}
HDR = struct.Struct(">qiqqqqqqqq")  # seq tick clientTick frameNo tickEnd frameStart frameEnd build a4 sent


def record(kind, **row):
    row = {"kind": kind, "at": time.strftime("%Y-%m-%dT%H:%M:%S"), "load": T.load(), **T.hooks["machine"](), **row}
    RUNS.mkdir(exist_ok=True)
    with RESULTS.open("a") as f:
        f.write(json.dumps(row) + "\n")
    if hooks["record"]:
        hooks["record"]("frames-" + kind, **{k: v for k, v in row.items() if k not in ("kind", "rows")})
    print(json.dumps({k: v for k, v in row.items() if k != "rows"})[:3000], flush=True)


def stat(v, nd=3):
    v = sorted(x for x in v if x is not None)
    if not v:
        return None
    q = lambda p: v[min(len(v) - 1, int(len(v) * p))]
    return {"n": len(v), "p50": round(statistics.median(v), nd), "p95": round(q(0.95), nd), "max": round(v[-1], nd), "mean": round(sum(v) / len(v), nd)}


# ---------- the listener: one socket per client, decoded live ----------

G = threading.Condition()  # every stream change and every finished n.att notifies it


def utf(b, i):
    n = struct.unpack_from(">H", b, i)[0]
    return b[i + 2:i + 2 + n].decode("utf-8", "replace"), i + 2 + n


class ClientStream:
    def __init__(self, name):
        self.name = name
        self.srv = socket.socket()
        self.srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.srv.bind(("127.0.0.1", 0))
        self.srv.listen(2)
        self.port = self.srv.getsockname()[1]
        self.label, self.token, self.n, self.ticks = None, None, 0, []
        self.seen = None  # (records until seen, tick, text, recv ns)
        self.echo = {}  # barrier id -> (recv ns, client handled ns, records so far, seen so far)
        self.log = []  # (tick, recv ns, client tickEnd, frameStart, sent, nbytes)
        self.records = self.bytes = self.resets = 0
        threading.Thread(target=self.accept, daemon=True).start()

    def accept(self):
        while True:
            try:
                conn, _ = self.srv.accept()
            except OSError:
                return
            threading.Thread(target=self.read, args=(conn,), daemon=True).start()

    def read(self, conn):
        f = conn.makefile("rb", buffering=1 << 16)
        try:
            while True:
                h = f.read(4)
                if len(h) < 4:
                    return
                body = f.read(struct.unpack(">i", h)[0])
                t = time.monotonic_ns()
                typ, b = body[0], body[1:]
                with G:
                    if typ == 1:
                        self.on_record(b, t)
                    elif typ == 2:
                        bid, at, _sent, _seq = struct.unpack_from(">iqqq", b)
                        self.echo[bid] = (t, at, self.n, self.seen is not None)
                    elif typ == 3:
                        self.label, _ = utf(b, 0)
                        self.token = self.label.split(":", 1)[1] if ":" in self.label else None
                        self.n, self.seen, self.ticks = 0, None, []
                        self.resets += 1
                    G.notify_all()
        finally:
            conn.close()

    def on_record(self, b, t):
        h = HDR.unpack_from(b, 0)
        self.records += 1
        self.bytes += len(b) + 5
        self.n += 1
        self.ticks.append(h[1])
        self.log.append((h[1], t, h[4], h[5], h[9], len(b) + 5))
        if self.seen is None and self.token:
            i = HDR.size
            runs = struct.unpack_from(">h", b, i)[0]
            i += 2
            for _ in range(runs):
                tag, i = utf(b, i)
                text, i = utf(b, i)
                if tag == "chat" and self.token in text:
                    self.seen = (self.n, h[1], text, t)
                    break

    def take_log(self):
        with G:
            out, self.log = self.log, []
        return out


# ---------- topology A without the restart Paper ----------

class FShared(T.Shared):
    def __init__(self, label, cfg):
        T.Topology.__init__(self, label)
        self.S = T.TPaper(self.run / "shared", "S")
        self.cfg = cfg
        self.streams = {c.name: ClientStream(c.name) for c in self.clients}
        for c in self.clients:
            if cfg.get("lp"):
                c.client.env["LP_NUM_THREADS"] = str(cfg["lp"])
            if cfg.get("bg"):
                c.client.extra_jvm.append(f"-Dmax.bg.threads={cfg['bg']}")
            if cfg.get("w"):
                c.client.width, c.client.height = cfg["w"]
        self.variant, self.stream_on = None, False
        self.pool = concurrent.futures.ThreadPoolExecutor(max_workers=8)  # n.att callers keep their own lines

    def __exit__(self, *exc):
        self.pool.shutdown(wait=False)
        for s in self.streams.values():
            s.srv.close()
        return super().__exit__(*exc)

    def papers(self):
        return [self.S]

    def __enter__(self):
        try:
            self.boot = self.boot_parallel([self.S])
            for c in self.clients:
                self.join(c, self.S)
            self.S.prepare_world([c.name for c in self.clients])
            for c in self.clients:
                c.C("clearToasts")
                c.C("clearChat")
            self.S.step_on()
            for c in self.clients:
                c.C("n.mode", on=1)
                self.S.D("n.sync", player=c.name)
            return self
        except BaseException:
            self.__exit__(*sys.exc_info())
            raise

    def try_claim(self, req):
        free = [c for c in self.clients if not c.busy]
        if len(free) < req["players"]:
            return None
        cs = free[:req["players"]]
        for c in cs:
            c.busy = True
        return {"clients": cs}

    def release(self, plan):
        for c in plan["clients"]:
            c.busy = False

    def set_variant(self, name):
        v = VARIANTS[name]
        for c in self.clients:
            if v["stream"] and not self.stream_on:
                c.C("st.on", port=self.streams[c.name].port, a4=0)
            elif not v["stream"] and self.stream_on:
                c.C("st.off")
            c.C("st.mode", every=v["every"])
            c.C("n.wake", barriers=v["wake"])
        self.stream_on = v["stream"]
        self.variant = v

    def execute(self, req, plan):
        cs = plan["clients"]
        if self.variant["verdict"] == "ack":
            r = T.attempt(self.S, cs, req)
            return {"pass": r["pass"], "ticks": r["ticks"], "lost_quiet_ms": r["lostQuietMicros"] / 1000, "lost_ack_ms": r["lostAckMicros"] / 1000}
        return self.attempt_stream(cs, req)

    def attempt_stream(self, cs, req):
        S = self.S
        tok = f"t{req['id']}x{random.randrange(10**9)}"
        label = f"{req['id']}:{tok}"
        for c in cs:
            S.D("k.wipe", player=c.name, scope="full")
            c.C("st.begin", name=label)
        streams = [self.streams[c.name] for c in cs]
        out = {}

        def call():
            try:
                out["r"] = S.D("n.att", players=",".join(c.name for c in cs), max=req["w"], kind=req["kind"], token=tok,
                               late=req.get("late", 0), asyncMs=req.get("asyncMs", 0), broken=int(req["broken"]), timeoutMs=20000, stream=1)
            except Exception as e:
                out["e"] = e
            with G:
                G.notify_all()

        fut = self.pool.submit(call)
        ended = None
        with G:
            while "r" not in out and "e" not in out:
                if ended is None and all(s.label == label and s.seen for s in streams):
                    ended = time.monotonic_ns()
                    break
                G.wait(0.05)
        if ended is not None:
            S.D("n.end", token=tok)  # skips the main thread; the attempt ends at the next idle pass
        fut.result()
        if "e" in out:
            raise out["e"]
        r = out["r"]
        echo_ms, verdict = [], None
        if r["pass"]:
            verdict = True
            counts = [s.seen[0] for s in streams]
        else:
            bars = r.get("barriers") or {}
            deadline = time.time() + 20
            got = []
            with G:
                for c, s in zip(cs, streams):
                    bid, sent = bars[c.name]
                    while bid not in s.echo:
                        left = deadline - time.time()
                        if left <= 0:
                            raise RuntimeError(f"no echo of barrier {bid} from {c.name}")
                        G.wait(min(left, 0.05))
                    e = s.echo.pop(bid)
                    got.append(e)
                    echo_ms.append((e[0] - sent) / 1e6)
            verdict = all(e[3] for e in got)
            counts = [e[2] for e in got]
        if self.variant["every"] == 0:
            for c in cs:
                c.C("st.end")
        seen_ticks = [(s.seen[1] - r["startTick"]) if s.seen and s.label == label else None for s in streams]
        texts = [s.seen[2] if s.seen and s.label == label else None for s in streams]
        rec_ticks = [[t - r["startTick"] for t in s.ticks[:k]] for s, k in zip(streams, counts)]
        return {"pass": verdict, "ticks": r["endTick"] - r["startTick"], "counts": counts, "seen_ticks": seen_ticks,
                "texts": texts, "rec_ticks": rec_ticks, "echo_ms": echo_ms, "lost_quiet_ms": r["lostQuietMicros"] / 1000, "lost_ack_ms": r["lostAckMicros"] / 1000}


# ---------- one measured run of n requirements ----------

def pids_of(topo):
    return {"paper": topo.S.proc.p.pid, **{c.name: c.client.java_pid() for c in topo.clients}}


def measure(topo, inst, vname, mix, seed, n, keep_rows):
    reqs = [r for r in T.generate(seed, n, mix, 0.0)]
    topo.set_variant(vname)
    for s in topo.streams.values():
        s.take_log()
    st0 = topo.S.D("n.stats")
    topo.S.D("n.ticklog", on=1)
    pids = pids_of(topo)
    cpu0 = {k: T.proc_cpu(p) for k, p in pids.items()}
    rec0 = {k: (s.records, s.bytes) for k, s in topo.streams.items()}
    b0 = T.machine_busy()
    rows, wall = topo.run_reqs(reqs)
    b1 = T.machine_busy()
    cpu1 = {k: T.proc_cpu(p) for k, p in pids.items()}
    ticks = topo.S.D("n.ticklog", on=0)["ticks"]
    st1 = topo.S.D("n.stats")
    logs = {k: s.take_log() for k, s in topo.streams.items()}
    tick_ns = {t: ns for t, ns in ticks}
    gaps = [(ticks[i + 1][1] - ticks[i][1]) / 1e6 for i in range(len(ticks) - 1) if ticks[i + 1][0] == ticks[i][0] + 1]
    late_srv, late_cli = [], []
    for lg in logs.values():
        for tick, recv, tick_end, frame_start, sent, nb in lg:
            if tick in tick_ns and 0 <= frame_start - tick_end < 5_000_000:  # a frame drawn for that tick
                late_srv.append((recv - tick_ns[tick]) / 1e6)
                late_cli.append((recv - tick_end) / 1e6)
    ok = [r for r in rows if "error" not in r]
    vcpu = round((b1[0] - b0[0]) / max(1, b1[1] - b0[1]) * (os.cpu_count() or 4), 2) if b0 and b1 else None
    steps = st1["stepsTotal"] - st0["stepsTotal"]
    s = dict(
        inst=inst, variant=vname, mix=mix, seed=seed, n=len(rows), errors=len(rows) - len(ok), wall_s=round(wall, 2),
        wrong=sum(1 for r in ok if r["wrong"]), broken=sum(1 for r in rows if r["broken"]), groups=sum(1 for r in rows if r["players"] > 1),
        wrong_detail=[{k: r.get(k) for k in ("id", "kind", "players", "broken", "pass", "seen_ticks", "counts", "ticks", "w")} for r in ok if r["wrong"]][:10],
        first_error=next((r for r in rows if "error" in r), None),
        req_s=stat([r["s"] for r in ok], 4), steps=steps, ms_per_step=round(wall * 1000 / max(1, steps), 3),
        tick_gap_ms=stat(gaps), cpu_s={k: (round(cpu1[k] - cpu0[k], 2) if cpu1[k] is not None and cpu0[k] is not None else None) for k in pids},
        busy_vcpu=vcpu, records=sum(s.records - rec0[k][0] for k, s in topo.streams.items()),
        stream_kb=round(sum(s.bytes - rec0[k][1] for k, s in topo.streams.items()) / 1000, 1),
        late_srv_ms=stat(late_srv), late_cli_ms=stat(late_cli), echo_ms=stat([e for r in ok for e in r.get("echo_ms", [])]),
        lost_quiet_s=round(sum(r.get("lost_quiet_ms", 0) for r in ok) / 1000, 2), lost_ack_s=round(sum(r.get("lost_ack_ms", 0) for r in ok) / 1000, 2),
        client_stats={c.name: c.C("st.stats") for c in topo.clients} if topo.stream_on else None,
    )
    s["cores"] = {k: (round(v / wall, 2) if v is not None else None) for k, v in s["cpu_s"].items()}
    # Per requirement, compact: id, pass, wrong, seconds, records until the verdict per member, seen tick per member, text.
    s["rows"] = [[r["id"], r.get("pass"), r.get("wrong"), r["s"], r.get("counts"), r.get("seen_ticks"), r.get("texts"), r.get("rec_ticks")] for r in sorted(ok, key=lambda r: r["id"])] if keep_rows else None
    return s


def parse_inst(text):
    cfg = {}
    for part in filter(None, text.split(",")):
        if part == "default":
            continue
        k, v = part.split("=")
        cfg[k] = tuple(int(x) for x in v.split("x")) if k == "w" else int(v)
    return cfg


def cmd_run(a):
    for inst in a.instances.split(";"):
        cfg = parse_inst(inst)
        plan = a.plan_default if inst == "default" else a.plan_other
        steps = [tuple(x.split("@")) for x in plan.split(",")]
        t0 = time.time()
        with FShared(f"{a.label}-{inst.replace('=', '').replace(',', '-')}", cfg) as topo:
            record("setup", label=a.label, inst=inst, cfg={k: list(v) if isinstance(v, tuple) else v for k, v in cfg.items()},
                   boot=topo.boot, joins={c.name: c.join_s for c in topo.clients}, setup_s=round(time.time() - t0, 1),
                   renderer=getattr(topo.clients[0], "renderer", None))
            if a.warm:
                topo.set_variant("f")
                warm = T.generate(a.seed + 999, a.warm, 0.1, 0.0)
                rows, wall = topo.run_reqs(warm)
                record("warm", label=a.label, inst=inst, n=len(warm), wall_s=round(wall, 2), wrong=sum(1 for r in rows if r.get("wrong")),
                       errors=sum(1 for r in rows if "error" in r))
            for vname, mix in steps:
                mix = float(mix)
                seed = a.seed * 100 + {0.0: 0, 0.1: 1, 0.3: 2}.get(mix, 9)
                s = measure(topo, inst, vname, mix, seed, a.n, a.keep_rows)
                record("run", label=a.label, **s)
    print(json.dumps({"leaks": leak_check()}))


def main(argv=None):
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    r = sub.add_parser("run")
    r.add_argument("--instances", default="default")
    r.add_argument("--plan-default", default="base@0.1,f@0.1,fack@0.1,demand@0.1,wake@0.1,demand+wake@0.1,f@0.1,base@0.1,base@0,f@0,base@0.3,f@0.3")
    r.add_argument("--plan-other", default="base@0.1,f@0.1,demand+wake@0.1")
    r.add_argument("--n", type=int, default=1000)
    r.add_argument("--seed", type=int, default=1)
    r.add_argument("--warm", type=int, default=99)
    r.add_argument("--label", default="mac")
    r.add_argument("--keep-rows", type=int, default=1)
    a = ap.parse_args(argv)
    print("load", T.load(), flush=True)
    try:
        cmd_run(a)
    finally:
        stop_all()
    print("load", T.load(), flush=True)


if __name__ == "__main__":
    main()
