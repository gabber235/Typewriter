#!/usr/bin/env python3
"""Topology spike: one stepped Paper shared by 4 clients (A) against one stepped Paper per attempt slot (B).

  topo.py run --topo A|B --mixes 0,0.1,0.3 --n 1000 --seed 1 [--warm 100] [--label mac]

Both topologies run the same synthetic requirements from the same seeds. A requirement is a full wipe of every
claimed player, a probe call as the stimulus (n.att), and a window check closed by the E3t barrier: pass at the
first ack in which every member saw the token, fail once the window's ticks have run with every member acked and
quiet. Every tenth requirement (exactly 10 percent) is broken: the last member never gets the effect. Restart
requirements (exactly 1 percent) run K's reward scene (an item saved before a SIGKILL is there once after the
boot; broken skips the save) and are started first, since they are the longest.

A, shared: Paper S stepped by the widened policy (every claimed client acked, every claimed player quiet), up to 4
attempts at once, plus one unstepped extra Paper X for restarts: the client moves S to X, X is killed and booted,
the client moves back.

B, Paper per attempt slot: 4 stepped Papers, one attempt at a time each. Clients start on their own Paper and stay
where they are until moved. A claim of k players takes the free Paper holding most free clients and moves the
rest there. A restart kills and boots its own Paper in place, with every client that sits on it.
"""
import argparse, json, os, pathlib, random, statistics, subprocess, sys, threading, time

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import k as K
import run as R
from run import RUNS, ROOT, leak_check, stop_all
from speed import Line

AGENT = ROOT / "step-agent/build/libs/step-agent-0.jar"
RESULTS = RUNS / "topo.jsonl"
def cpu_model():
    try:
        return next(l.split(":", 1)[1].strip() for l in pathlib.Path("/proc/cpuinfo").read_text().splitlines() if l.startswith("model name"))
    except Exception:
        return subprocess.run(["sysctl", "-n", "machdep.cpu.brand_string"], capture_output=True, text=True).stdout.strip() or None


CPU = cpu_model()
hooks = {"record": None, "machine": lambda: {"cpu": CPU, "ncpu": os.cpu_count()}}


def load():
    return round(os.getloadavg()[0], 2)


def record(kind, **row):
    row = {"kind": kind, "at": time.strftime("%Y-%m-%dT%H:%M:%S"), "load": load(), **hooks["machine"](), **row}
    RUNS.mkdir(exist_ok=True)
    with RESULTS.open("a") as f:
        f.write(json.dumps(row) + "\n")
    if hooks["record"]:
        hooks["record"]("topo-" + kind, **{k: v for k, v in row.items() if k != "kind"})
    print(json.dumps({k: v for k, v in row.items() if k != "rows"})[:2500], flush=True)


def stat(v):
    v = sorted(x for x in v if x is not None)
    if not v:
        return None
    q = lambda p: v[min(len(v) - 1, int(len(v) * p))]
    return {"n": len(v), "p50": round(statistics.median(v), 4), "p95": round(q(0.95), 4), "max": round(v[-1], 4), "mean": round(sum(v) / len(v), 4)}


# ---------- requirements ----------

def generate(seed, n, group, restart=0.01):
    """Exact shares, shuffled by the seed: 1 % restart, 10 % async 50 to 150 ms, `group` share of 2 or 3 players,
    10 % broken; the rest half chat now (window 2), half late 1 to 8 ticks (window late + 2)."""
    rng = random.Random(seed)
    n_restart = round(n * restart)
    rest = n - n_restart
    n_async, n_group = round(n * 0.10), round(rest * group)
    shape = ["async"] * n_async + ["sync"] * (rest - n_async)
    rng.shuffle(shape)
    players = [rng.choice((2, 3)) for _ in range(n_group)] + [1] * (rest - n_group)
    rng.shuffle(players)
    broken = [True] * round(n * 0.10) + [False] * (n - round(n * 0.10))
    rng.shuffle(broken)
    reqs = []
    for i in range(n_restart):
        reqs.append({"id": i, "kind": "restart", "players": 1, "broken": broken[i]})
    for j in range(rest):
        i = n_restart + j
        r = {"id": i, "players": players[j], "broken": broken[i]}
        if shape[j] == "async":
            r.update(kind="asyncsync", asyncMs=rng.randint(50, 150), w=4)
        elif rng.random() < 0.5:
            r.update(kind="chat", w=2)
        else:
            late = rng.randint(1, 8)
            r.update(kind="late", late=late, w=late + 2)
        reqs.append(r)
    head, tail = reqs[:n_restart], reqs[n_restart:]
    rng.shuffle(tail)
    return head + tail  # restarts first: the scheduler starts the longest work first


# ---------- Paper and clients ----------

class TPaper(K.KPaper):
    """K's killable Paper with the step agent, Paper's wall clock packet limiter off, one direct line per thread."""

    def __init__(self, run_dir, name, stepped=True):
        super().__init__(run_dir)
        self.name, self.stepped, self.gen = name, stepped, 0
        self.jvm.append(f"-javaagent:{AGENT}=lag=tick")
        self.tl = threading.local()
        setup = self.setup

        def setup_without_packet_limit():
            setup()
            cfg = self.dir / "config" / "paper-global.yml"
            cfg.write_text(cfg.read_text().replace("max-packet-rate: 500.0", "max-packet-rate: 0.0", 1))
        self.setup = setup_without_packet_limit

    def boot(self):
        s = super().boot()
        self.gen += 1
        return s

    def D(self, name, **q):
        """Direct dispatch (between ticks) on this thread's own connection."""
        if getattr(self.tl, "gen", None) != self.gen:
            self.tl.line, self.tl.gen = Line(self.line, prefix="direct/"), self.gen
        return self.tl.line(name, **q)

    def prepare_world(self, names):
        self.S("e.calm")
        self.S("time", player=names[0])
        for n in names:
            self.S("gprep", player=n)

    def step_on(self):
        self.D("n.mode", on=1, limitMs=1000, lag="tick", autoMinMicros=1000)

    def step_off(self):
        self.D("n.mode", on=0)

    def cpu_s(self):
        return proc_cpu(self.proc.p.pid)


def proc_cpu(pid):
    try:
        if pathlib.Path("/proc").exists():
            f = pathlib.Path(f"/proc/{pid}/stat").read_text().rsplit(")", 1)[1].split()
            return (int(f[11]) + int(f[12])) / os.sysconf("SC_CLK_TCK")
        out = subprocess.run(["ps", "-o", "time=", "-p", str(pid)], capture_output=True, text=True).stdout.strip()
        m, s = out.split(":")
        return int(m) * 60 + float(s)
    except Exception:
        return None


class Mem:
    """Peak memory over a window: the whole machine (Linux MemTotal minus MemAvailable) and our JVMs' RSS."""

    def __init__(self, pids):
        self.pids, self.peak_used, self.peak_rss, self.stop_ = pids, 0, 0, False
        self.t = threading.Thread(target=self.loop, daemon=True)

    def used(self):
        try:
            m = dict(l.split(":", 1) for l in pathlib.Path("/proc/meminfo").read_text().splitlines())
            return (int(m["MemTotal"].split()[0]) - int(m["MemAvailable"].split()[0])) // 1024
        except Exception:
            return None

    def rss(self):
        pids = [str(p) for p in self.pids() if p]
        out = subprocess.run(["ps", "-o", "rss=", "-p", ",".join(pids)], capture_output=True, text=True).stdout
        return sum(int(x) for x in out.split()) // 1024

    def loop(self):
        while not self.stop_:
            try:
                u = self.used()
                if u:
                    self.peak_used = max(self.peak_used, u)
                self.peak_rss = max(self.peak_rss, self.rss())
            except Exception:
                pass
            time.sleep(0.5)

    def __enter__(self):
        self.t.start()
        return self

    def __exit__(self, *a):
        self.stop_ = True
        self.t.join(2)


def machine_busy():
    """Busy jiffies and total jiffies from /proc/stat (Linux), for vCPU busy over a window."""
    try:
        f = [int(x) for x in pathlib.Path("/proc/stat").read_text().splitlines()[0].split()[1:]]
        idle = f[3] + f[4]
        return sum(f) - idle, sum(f)
    except Exception:
        return None


def move(c, dst):
    """Leave like the pause menu, connect to dst, wait for the facts start signal. A stepped dst runs auto ticks
    for the join; the client steps again once it is in."""
    t0 = time.perf_counter()
    c.C("n.mode", on=0)
    if dst.stepped:
        dst.D("n.auto", on=1)
    try:
        r = c.reconnect(dst.addr, K.NEED["chunks"])
        assert r["ok"], r
        if dst.stepped:
            c.C("n.mode", on=1)
            dst.D("n.sync", player=c.name)
    finally:
        if dst.stepped:
            dst.D("n.auto", on=0)
    c.at = dst
    return time.perf_counter() - t0


def attempt(paper, cs, req):
    """The ordinary requirement: full wipe of every member, watch the token, stimulus and window in one call."""
    tok = f"t{req['id']}x{random.randrange(10**9)}"
    for c in cs:
        paper.D("k.wipe", player=c.name, scope="full")
        c.C("clearChat")
        c.C("n.watch", needle=tok)
    r = paper.D("n.att", players=",".join(c.name for c in cs), max=req["w"], kind=req["kind"], token=tok,
                late=req.get("late", 0), asyncMs=req.get("asyncMs", 0), broken=int(req["broken"]))
    for c in cs:
        c.C("n.watch", needle="")
    return r


def restart_scene(paper, subject, broken, riders=()):
    """K's reward scene on an unstepped Paper: an item is given (and saved unless broken), Paper is SIGKILLed and
    booted on the same ports, the client reconnects; the item must be there exactly once."""
    S = paper.S
    S("k.cfg", graceTicks=100, holdGrace=10, saveOnReward=int(not broken), keepMail=0, persistSessions=0)
    S("k.wipe", player=subject.name, scope="full")
    subject.C("clearChat")
    tok = f"r{random.randrange(10**6)}"
    S("k.owe", player=subject.name, tok=tok)
    subject.barrier(S)
    everyone = [subject, *riders]
    for c in everyone:
        c.C("k.mark")
    t0 = time.perf_counter()
    paper.kill()
    for c in everyone:
        c.C("k.gone", timeoutMs=20000)
        c.C("gate", mode=0)
    tb = time.perf_counter()
    paper.boot()
    boot = time.perf_counter() - tb
    for c in everyone:
        c.C("k.connect", addr=paper.addr)
    for c in everyone:
        r = c.C("k.ready", need=K.NEED["chunks"], newLevel=1, timeoutMs=60000)
        assert r["ok"], r
        c.C("gate", mode=c.gate)
    ready = time.perf_counter() - t0
    paper.prepare_world([c.name for c in everyone])
    subject.barrier(paper.S)
    count = subject.C("k.inv", name="R" + tok)["count"]
    return {"pass": count == 1, "boot_s": round(boot, 3), "kill_to_ready_s": round(ready, 3)}


def client_pids(clients):
    return [c.client.java_pid() for c in clients]


# ---------- topologies ----------

class Topology:
    def __init__(self, label):
        self.run = RUNS / f"topo-{label}-{int(time.time())}"
        self.lock = threading.Condition()
        self.clients = [K.KClient(self.run, i, f"probe{i + 1}", None, gate=2) for i in range(4)]
        for c in self.clients:
            c.busy, c.at = False, None
        self.moves = []

    def papers(self):
        raise NotImplementedError

    def boot_parallel(self, papers):
        out = {}
        ts = [threading.Thread(target=lambda p=p: out.__setitem__(p.name, p.boot())) for p in papers]
        t0 = time.perf_counter()
        for t in ts:
            t.start()
        for t in ts:
            t.join()
        wall = time.perf_counter() - t0
        return {"wall_s": round(wall, 2), "each_s": out, "cpu_s": {p.name: p.cpu_s() for p in papers},
                "rss_mb": {p.name: R.rss_mb(p.proc.p.pid) for p in papers}}

    def join(self, c, paper):
        c.paper = paper
        c.join()
        c.at = paper

    def __enter__(self):
        return self

    def __exit__(self, *exc):
        for c in self.clients:
            c.stop()
        for p in self.papers():
            if p.proc and p.proc.alive():
                try:
                    p.proc.stop(grace=5)
                except Exception as e:
                    print("server stop:", e, file=sys.stderr)
        stop_all()
        if K.hooks["cleanup"]:
            K.hooks["cleanup"](self)
        import shutil
        if exc[0] is None:
            shutil.rmtree(self.run, ignore_errors=True)
        else:
            print("kept run dir after failure:", self.run, file=sys.stderr)
        return False

    def stats_all(self):
        return {p.name: p.D("n.stats") for p in self.papers() if p.stepped}

    # The scheduler starts requirements in order as resources free up. A normal requirement that cannot start
    # holds its place (a group reserves the clients it waits for); a restart that cannot start is passed over.
    def run_reqs(self, reqs):
        rows, threads = [], []
        self.t0 = t0 = time.perf_counter()
        pending, self.running = list(reqs), 0
        with self.lock:
            while pending:
                for req in list(pending):
                    plan = self.try_claim(req)
                    if plan is None:
                        if req["kind"] == "restart":
                            continue
                        break
                    pending.remove(req)
                    self.running += 1
                    th = threading.Thread(target=self.worker, args=(req, plan, time.perf_counter() - t0, rows))
                    th.start()
                    threads.append(th)
                if pending:
                    self.lock.wait()
        for th in threads:
            th.join()
        return rows, time.perf_counter() - t0

    def worker(self, req, plan, started, rows):
        t0 = time.perf_counter()
        waited = started
        row = {"id": req["id"], "kind": req["kind"], "players": req["players"], "broken": req["broken"], "w": req.get("w"),
               "start_s": round(waited, 3)}
        try:
            row.update(self.execute(req, plan))
            row["wrong"] = row["pass"] == req["broken"]
        except Exception as e:
            row.update(error=str(e)[:300], wrong=None)
            print("attempt error:", req, e, file=sys.stderr, flush=True)
        row["s"] = round(time.perf_counter() - t0, 4)
        row["end_s"] = round(time.perf_counter() - self.t0, 3)
        rows.append(row)
        with self.lock:
            self.running -= 1
            self.release(plan)
            self.lock.notify_all()


class Shared(Topology):
    """A: Paper S stepped and shared by all 4 clients; X unstepped for restart requirements."""
    name = "A"

    def __init__(self, label):
        super().__init__(label)
        self.S = TPaper(self.run / "shared", "S")
        self.X = TPaper(self.run / "extra", "X", stepped=False)
        self.x_busy = False

    def papers(self):
        return [self.S, self.X]

    def __enter__(self):
        try:
            self.boot = self.boot_parallel([self.S, self.X])
            for c in self.clients:
                self.join(c, self.S)
            self.S.prepare_world([c.name for c in self.clients])
            self.X.S("e.calm")
            self.X.S("time")
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
        if req["kind"] == "restart":
            if self.x_busy or not free:
                return None
            self.x_busy = True
            free[0].busy = True
            return {"clients": [free[0]], "restart": True}
        if len(free) < req["players"]:
            return None
        cs = free[:req["players"]]
        for c in cs:
            c.busy = True
        return {"clients": cs}

    def release(self, plan):
        for c in plan["clients"]:
            c.busy = False
        if plan.get("restart"):
            self.x_busy = False

    def execute(self, req, plan):
        cs = plan["clients"]
        if not plan.get("restart"):
            r = attempt(self.S, cs, req)
            return {"pass": r["pass"], "ticks": r["ticks"], "seen": r["seen"], "wall_ms": r["wallMicros"] / 1000,
                    "lost_quiet_ms": r["lostQuietMicros"] / 1000, "lost_ack_ms": r["lostAckMicros"] / 1000,
                    "own_quiet_ms": r["ownQuietMicros"] / 1000, "own_ack_ms": r["ownAckMicros"] / 1000,
                    "hung": r["hung"], "concurrent": r["concurrent"], "moves_s": 0.0}
        c = cs[0]
        m1 = move(c, self.X)
        out = restart_scene(self.X, c, req["broken"])
        m2 = move(c, self.S)
        self.moves += [("S>X", m1), ("X>S", m2)]
        return {**out, "moves_s": round(m1 + m2, 3), "move_out_s": round(m1, 3), "move_back_s": round(m2, 3)}


class PerSlot(Topology):
    """B: four stepped Papers, one attempt at a time each."""
    name = "B"

    def __init__(self, label):
        super().__init__(label)
        self.P = [TPaper(self.run / f"paper{i}", f"P{i}") for i in range(4)]
        for p in self.P:
            p.busy = False

    def papers(self):
        return self.P

    def __enter__(self):
        try:
            self.boot = self.boot_parallel(self.P)
            for c, p in zip(self.clients, self.P):
                self.join(c, p)
            for c, p in zip(self.clients, self.P):
                p.prepare_world([c.name])
                c.C("clearToasts")
                c.C("clearChat")
                p.step_on()
                c.C("n.mode", on=1)
                p.D("n.sync", player=c.name)
            return self
        except BaseException:
            self.__exit__(*sys.exc_info())
            raise

    def try_claim(self, req):
        free_p = [p for p in self.P if not p.busy]
        free_c = [c for c in self.clients if not c.busy]
        k = req["players"]
        if not free_p or len(free_c) < k:
            return None
        # The free Paper that already holds the most free clients; ties go to the lower index.
        p = max(free_p, key=lambda p: (sum(1 for c in free_c if c.at is p), -self.P.index(p)))
        here = [c for c in free_c if c.at is p]
        crowd = lambda c: -sum(1 for o in self.clients if o.at is c.at)
        others = sorted((c for c in free_c if c.at is not p), key=crowd)
        cs = (here + others)[:k]
        plan = {"paper": p, "clients": cs, "move": [(c, c.at) for c in cs if c.at is not p]}
        for c, _ in plan["move"]:
            c.at = p  # where it will be; a restart must not count it as a rider of its old Paper
        if req["kind"] == "restart":
            # A kill drops every client on the Paper: they ride along and reconnect after the boot.
            plan["riders"] = [c for c in free_c if c.at is p and c not in cs]
        p.busy = True
        for c in cs + plan.get("riders", []):
            c.busy = True
        return plan

    def release(self, plan):
        plan["paper"].busy = False
        for c in plan["clients"] + plan.get("riders", []):
            c.busy = False

    def execute(self, req, plan):
        p, cs = plan["paper"], plan["clients"]
        mt = 0.0
        for c, src in plan["move"]:
            m = move(c, p)
            self.moves.append((f"{src.name}>{p.name}", m))
            mt += m
        if req["kind"] != "restart":
            r = attempt(p, cs, req)
            return {"pass": r["pass"], "ticks": r["ticks"], "seen": r["seen"], "wall_ms": r["wallMicros"] / 1000,
                    "lost_quiet_ms": r["lostQuietMicros"] / 1000, "lost_ack_ms": r["lostAckMicros"] / 1000,
                    "own_quiet_ms": r["ownQuietMicros"] / 1000, "own_ack_ms": r["ownAckMicros"] / 1000,
                    "hung": r["hung"], "concurrent": r["concurrent"], "moves_s": round(mt, 3), "n_moves": len(plan["move"])}
        everyone = cs + plan["riders"]
        p.step_off()
        for c in everyone:
            c.C("n.mode", on=0)
        out = restart_scene(p, cs[0], req["broken"], plan["riders"])
        p.step_on()
        for c in everyone:
            c.C("n.mode", on=1)
            p.D("n.sync", player=c.name)
        return {**out, "moves_s": round(mt, 3), "n_moves": len(plan["move"]), "riders": len(plan["riders"])}


def summarize(topo, mix, seed, rows, wall, mem, busy0, busy1, warm):
    ok = [r for r in rows if "error" not in r]
    normal = [r for r in ok if r["kind"] != "restart"]
    restarts = [r for r in ok if r["kind"] == "restart"]
    vcpu = None
    if busy0 and busy1:
        vcpu = round((busy1[0] - busy0[0]) / max(1, busy1[1] - busy0[1]) * (os.cpu_count() or 4), 2)
    return dict(
        topo=topo, mix=mix, seed=seed, n=len(rows), errors=len(rows) - len(ok), warm=warm,
        wall_s=round(wall, 2), wrong=sum(1 for r in ok if r["wrong"]),
        wrong_detail=[{k: r.get(k) for k in ("id", "kind", "players", "broken", "pass", "seen", "ticks", "w")} for r in ok if r["wrong"]][:10],
        broken=sum(1 for r in rows if r["broken"]), groups=sum(1 for r in rows if r["players"] > 1),
        req_s=stat([r["s"] for r in ok]), normal_s=stat([r["s"] for r in normal]),
        normal_end_s=max((r["end_s"] for r in normal), default=None),
        restart_end_s=max((r["end_s"] for r in restarts), default=None),
        single_s=stat([r["s"] for r in normal if r["players"] == 1]), group_s=stat([r["s"] for r in normal if r["players"] > 1]),
        async_s=stat([r["s"] for r in normal if r["kind"] == "asyncsync"]),
        restart_s=stat([r["s"] for r in restarts]), restart_boot_s=stat([r.get("boot_s") for r in restarts]),
        restart_kill_to_ready_s=stat([r.get("kill_to_ready_s") for r in restarts]),
        moves_s=stat([r["moves_s"] for r in ok if r.get("moves_s")]), n_move_reqs=sum(1 for r in ok if r.get("moves_s")),
        lost_quiet_ms_total=round(sum(r.get("lost_quiet_ms", 0) for r in normal), 1),
        lost_quiet_ms=stat([r.get("lost_quiet_ms") for r in normal]),
        lost_quiet_ms_affected=stat([r.get("lost_quiet_ms") for r in normal if r.get("lost_quiet_ms", 0) > 0]),
        lost_ack_ms_total=round(sum(r.get("lost_ack_ms", 0) for r in normal), 1),
        own_quiet_ms_total=round(sum(r.get("own_quiet_ms", 0) for r in normal), 1),
        wall_ms=stat([r.get("wall_ms") for r in normal]),
        concurrent=stat([r.get("concurrent") for r in normal]),
        peak_used_mb=mem.peak_used or None, peak_rss_mb=mem.peak_rss, busy_vcpu=vcpu,
        first_error=next((r for r in rows if "error" in r), None),
    )


def cmd_run(a):
    T = {"A": Shared, "B": PerSlot}[a.topo]
    mixes = [float(x) for x in a.mixes.split(",")]
    with T(f"{a.label}-{a.topo}") as topo:
        pids = lambda: [p.proc.p.pid for p in topo.papers() if p.proc and p.proc.alive()] + client_pids(topo.clients)
        record("setup", label=a.label, topo=a.topo, boot=topo.boot, joins={c.name: c.join_s for c in topo.clients},
               rss_mb={str(p): R.rss_mb(p) for p in pids() if p})
        if a.warm:
            warm = [r for r in generate(a.seed + 999, a.warm, 0.1) if r["kind"] != "restart"]
            rows, wall = topo.run_reqs(warm)
            record("warm", label=a.label, topo=a.topo, n=len(warm), wall_s=round(wall, 2), wrong=sum(1 for r in rows if r.get("wrong")),
                   errors=sum(1 for r in rows if "error" in r))
        for share, (i, mix) in [(float(x), im) for x in a.restart.split(",") for im in enumerate(mixes)]:
            seed = a.seed * 100 + i
            reqs = generate(seed, a.n, mix, share)
            topo.moves = []
            b0 = machine_busy()
            with Mem(pids) as mem:
                rows, wall = topo.run_reqs(reqs)
            b1 = machine_busy()
            s = summarize(a.topo, mix, seed, rows, wall, mem, b0, b1, a.warm)
            s["restart_share"] = share
            s["moves"] = {k: stat([m for kk, m in topo.moves if kk == k]) for k in sorted({kk for kk, _ in topo.moves})}
            s["move_each_s"] = stat([m for _, m in topo.moves])
            s["stats"] = topo.stats_all()
            record("run", label=a.label, **s, rows=rows if a.keep_rows else None)
    print(json.dumps({"leaks": leak_check()}))


def cmd_prep(a):
    """K's dynamic AppCDS archive, built with the step agent loaded (a different classpath would not map it)."""
    import shutil
    K.AOT.mkdir(parents=True, exist_ok=True)
    K.JSA.unlink(missing_ok=True)
    run = RUNS / f"topo-prep-{int(time.time())}"
    s = TPaper(run / "s", "prep", stepped=False)
    s.jvm.append(f"-XX:ArchiveClassesAtExit={K.JSA}")
    s.start()
    s.wait_done()
    s.stop_slow()
    shutil.rmtree(run, ignore_errors=True)
    record("prep", jsa_mb=round(K.JSA.stat().st_size / 1e6) if K.JSA.exists() else None)


def main(argv=None):
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    sub.add_parser("prep")
    r = sub.add_parser("run")
    r.add_argument("--topo", choices=["A", "B"], required=True)
    r.add_argument("--mixes", default="0,0.1,0.3")
    r.add_argument("--n", type=int, default=1000)
    r.add_argument("--seed", type=int, default=1)
    r.add_argument("--warm", type=int, default=100)
    r.add_argument("--restart", default="0.01")
    r.add_argument("--label", default="mac")
    r.add_argument("--keep-rows", type=int, default=0)
    a = ap.parse_args(argv)
    print("load", load(), flush=True)
    try:
        {"run": cmd_run, "prep": cmd_prep}[a.cmd](a)
    finally:
        stop_all()
    print("load", load(), flush=True)


if __name__ == "__main__":
    main()
