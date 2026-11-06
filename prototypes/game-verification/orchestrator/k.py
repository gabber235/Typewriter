#!/usr/bin/env python3
"""Spike K: Paper restarts and isolation per requirement with warm clients.

  k.py prep                                   build the dynamic AppCDS archive for the tuned Paper
  k.py restart --kind K1|K1auto|K1stop|K2|K3 --n 4 [--scenes grace,reward,mail] [--after 5] [--label mac]
  k.py iso --mode I1|I0|I2naive|I2full --n 200 --rate 20 [--clients 1] [--need hands|chunks] [--label mac]

restart: each trial arranges a scene (grace: session must end when Paper dies; reward: an item given before the
restart is there exactly once after it; mail: queued while Paper is down, delivered once at the next join), half of
the trials with the imitated plugin deliberately broken, restarts the chosen way, waits for E's start signal, then
judges. A wrong verdict is a pass on a broken trial or a fail on a good one. `after` ordinary chat requirements run
after each restart to see that verdicts still hold.

iso: every requirement reads every kind of per player state (one chat line KREQ), then writes all of them. The
isolation step before it is a fresh identity (I1: new offline name, reconnect), the same name reconnecting (I0, the
control), or a wipe of the connected player (I2naive: plugin store, inventory, effects, position, chat; I2full:
every kind the plugin knows). A leak is any kind the next requirement still sees.

Every command stops what it started; leak_check at the end. Clients launch through run.Client (direct java,
silent options, zero volume asserted).
"""
import argparse, json, os, pathlib, random, shutil, signal, statistics, sys, threading, time

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import run as R
from run import Client, RUNS, free_port, leak_check, stop_all, rss_mb, now_micros
from speed import Line, needle_for
from c4 import Variant, AOT, FAST_JVM

RESULTS = RUNS / "k.jsonl"
JSA = AOT / "k-paper.jsa"
LEVEL, SCREEN_NONE, CHUNKS, HANDS = 16, 32, 64, 4096
NEED = {"hands": LEVEL | SCREEN_NONE | CHUNKS | HANDS, "chunks": LEVEL | SCREEN_NONE | CHUNKS}
DEFAULTS = {"stored": "-", "history": 0, "session": 0, "hold": 0, "team": "-", "perm": 0, "sperm": "-", "inv": 0, "eff": 0, "pos": 0.0,
            "xp": 0, "mail": 0, "pdc": 0, "ptime": 0, "ender": 0, "boss": 0, "meta": 0}
# ci.py swaps these for Xvfb, the runner's renderer and its records.
hooks = {"client_kw": {"backend": "opengl", "window_clear": "0x2000"}, "env": lambda i: {}, "after_join": None, "record": None, "cleanup": None}


def record(kind, **row):
    row = {"kind": kind, "at": time.strftime("%Y-%m-%dT%H:%M:%S"), "load": round(os.getloadavg()[0], 1), **row}
    RUNS.mkdir(exist_ok=True)
    with RESULTS.open("a") as f:
        f.write(json.dumps(row) + "\n")
    if hooks["record"]:
        hooks["record"]("k-" + kind, **{k: v for k, v in row.items() if k != "kind"})
    print(json.dumps(row)[:900], flush=True)


def stat(v):
    v = sorted(x for x in v if x is not None)
    if not v:
        return None
    return {"n": len(v), "med": round(statistics.median(v), 3), "p95": round(v[min(len(v) - 1, int(len(v) * 0.95))], 3), "max": round(v[-1], 3)}


def load():
    return round(os.getloadavg()[0], 1)


# ---------- Paper that can be killed and booted again on the same ports ----------

class KPaper(Variant):
    def __init__(self, run_dir, line=None, port=None, control=None, cds=True, max_runtime=3000):
        self.line = line or free_port()
        jvm = [f"-Dprobe.line.port={self.line}", f"-Dprobe.maxRuntimeSec={max_runtime}", "-Xlog:cds=off,aot=off", "-Xshare:auto"]
        if cds and JSA.exists():
            jvm.append(f"-XX:SharedArchiveFile={JSA}")
        super().__init__(run_dir, xmx="1g", world="void", direct=True, trim=True, jvm=jvm)
        if port:
            self.port = port
        if control:
            self.control = control
        self.S = None

    def boot(self):
        t0 = time.time()
        self.start()
        self.wait_done()
        self.S = Line(self.line, prefix="tick/")
        self.boot_s = round(time.time() - t0, 3)
        return self.boot_s

    def kill(self):
        """SIGKILL to the process group this orchestrator started; nothing is saved."""
        t0 = time.time()
        os.killpg(self.proc.p.pid, signal.SIGKILL)
        self.proc.p.wait(30)
        self.proc.log.close()
        if self.proc in R.live:
            R.live.remove(self.proc)
        return round(time.time() - t0, 3)

    def stop_clean(self):
        t0 = time.time()
        self.stop()
        return round(time.time() - t0, 3)

    @property
    def addr(self):
        return f"127.0.0.1:{self.port}"


def cmd_prep(a):
    AOT.mkdir(parents=True, exist_ok=True)
    JSA.unlink(missing_ok=True)
    run = RUNS / f"k-prep-{int(time.time())}"
    s = KPaper(run / "s", cds=False)
    s.jvm.append(f"-XX:ArchiveClassesAtExit={JSA}")
    s.start()
    s.wait_done()
    s.stop_slow()
    shutil.rmtree(run, ignore_errors=True)
    record("prep", jsa_mb=round(JSA.stat().st_size / 1e6) if JSA.exists() else None)


# ---------- warm clients ----------

class KClient:
    def __init__(self, run, i, name, paper, gate=2):
        self.i, self.name, self.paper, self.gate = i, name, paper, gate
        self.live = free_port()
        self.client = Client(run / f"client{i}", name=name, xmx="1g", rd=2, facts_mode="changes",
                             extra_jvm=["-Dprobe.maxRuntimeSec=3000", f"-Dprobe.live.port={self.live}"], env=hooks["env"](i), **hooks["client_kw"])
        self.C = None
        self.ping = 3_000_000 + i * 1_000_000 + random.randrange(1000) * 100

    def next_ping(self):
        self.ping += 1
        return self.ping

    def join(self):
        t0 = time.time()
        self.client.server = self.paper.addr
        self.client.start()
        deadline = time.time() + 240
        while True:
            try:
                self.C = Line(self.live)
                break
            except OSError:
                if time.time() > deadline:
                    raise
                time.sleep(0.2)
        r = self.C("k.ready", need=NEED["hands"], timeoutMs=180000)
        assert r["ok"], r
        ev = self.client.events().get("renderer")
        assert ev and ev["master"] == 0.0 and ev["music"] == 0.0, "client is not silent: " + str(ev)
        if hooks["after_join"]:
            self.renderer = hooks["after_join"](self.client)
        self.C("gate", mode=self.gate)
        self.join_s = round(time.time() - t0, 1)

    def reconnect(self, addr, need, connect=True):
        """The loading screen closes only once the player's section is compiled, which needs drawn frames
        (LevelLoadTracker.WaitingForPlayerChunk), so a gated client draws until it is ready again."""
        self.C("gate", mode=0)
        self.C("k.mark")
        if connect:
            self.C("k.connect", addr=addr)
        r = self.C("k.ready", need=need, newLevel=1, timeoutMs=60000)
        self.C("gate", mode=self.gate)
        return r

    def barrier(self, S, player=None):
        b = self.next_ping()
        S("noop", player=player or self.name, ping=b)
        r = self.C("state", ping=b, timeoutMs=20000)
        return r

    def stop(self):
        try:
            self.client.stop()
        except Exception as e:
            print("client stop:", e, file=sys.stderr)


class Rig:
    """One Paper (plus a standby for K2) and k warm clients."""

    def __init__(self, label, clients=1, standby=False, gate=2):
        self.run = RUNS / f"k-{label}-{int(time.time())}"
        self.paper = KPaper(self.run / "server-a")
        self.standby = KPaper(self.run / "server-b") if standby else None
        self.clients = [KClient(self.run, i, f"probe{i + 1}", self.paper, gate) for i in range(clients)]

    def __enter__(self):
        try:
            self.boot_s = self.paper.boot()
            if self.standby:
                self.share(self.paper, self.standby)
                self.standby.boot()
            for c in self.clients:
                c.join()
            S = self.paper.S
            S("e.calm")
            S("time", player=self.clients[0].name)
            for c in self.clients:
                S("gprep", player=c.name)
                c.C("clearToasts")
                c.C("clearChat")
            return self
        except BaseException:
            self.__exit__(*sys.exc_info())
            raise

    @staticmethod
    def share(a, b):
        """Standby reads the same per player files: the plugin's k dir and the world's player data. Its world is its own."""
        b.setup()
        # Minecraft refuses symlinks inside a world unless allowed_symlinks.txt names their target.
        for p in (a, b):
            (p.dir / "allowed_symlinks.txt").write_text(f"[prefix]{RUNS.resolve()}\n")
        for sub in ("plugins/Probe/k",):
            src, dst = a.dir / sub, b.dir / sub
            src.mkdir(parents=True, exist_ok=True)
            dst.parent.mkdir(parents=True, exist_ok=True)
            if not dst.exists():
                dst.symlink_to(src.resolve())
        for sub in ("world/players",):
            src, dst = a.dir / sub, b.dir / sub
            src.mkdir(parents=True, exist_ok=True)
            dst.parent.mkdir(parents=True, exist_ok=True)
            if not dst.exists() and not dst.is_symlink():
                dst.symlink_to(src.resolve())

    def __exit__(self, et=None, ev=None, tb=None):
        for c in self.clients:
            c.stop()
        for p in (self.paper, self.standby):
            if p and p.proc and p.proc.alive():
                try:
                    p.stop()
                except Exception as e:
                    print("server stop:", e, file=sys.stderr)
        stop_all()
        if hooks["cleanup"]:
            hooks["cleanup"](self)
        if et is None:
            shutil.rmtree(self.run, ignore_errors=True)
        else:
            print("kept run dir after failure:", self.run, file=sys.stderr)
        return False


# ---------- restarts ----------

def chat_lines(c):
    return c.C("k.chat")["lines"]


def gone(c, t, t0):
    """Waits gated until the client has noticed the dead connection, then lets it draw for the join."""
    g = c.C("k.gone", timeoutMs=20000)
    t["gone_s"] = round(g["at"] / 1e6 - t0, 3) if g["ok"] else None
    c.C("gate", mode=0)


def restart(rig, kind, c, before_boot=None):
    """Restarts the chosen way; returns timings in seconds from the moment the restart began."""
    S = rig.paper.S
    t = {}
    c.C("k.mark")
    t0 = time.time()
    if kind in ("K1", "K1auto", "K1stop"):
        if kind == "K1auto":
            c.C("k.auto", addr=rig.paper.addr, on=1, everyMs=100)
        t["stop_s"] = rig.paper.kill() if kind != "K1stop" else rig.paper.stop_clean()
        gone(c, t, t0)
        if before_boot:
            before_boot()
        tb = time.time()
        rig.paper.start()
        rig.paper.wait_done()
        t["done_s"] = round(time.time() - t0, 3)
        t["boot_s"] = round(time.time() - tb, 3)
        if kind != "K1auto":
            c.C("k.connect", addr=rig.paper.addr)
        r = c.C("k.ready", need=NEED["hands"], newLevel=1, timeoutMs=60000)
        c.C("gate", mode=c.gate)
        rig.paper.S = Line(rig.paper.line, prefix="tick/")
        if kind == "K1auto":
            t["attempts"] = c.C("k.auto", on=0)["attempts"]
    elif kind == "K2":
        old, new = rig.paper, rig.standby
        t["stop_s"] = old.kill()
        if before_boot:
            before_boot()
        t["done_s"] = 0.0
        gone(c, t, t0)
        c.C("k.connect", addr=new.addr)
        r = c.C("k.ready", need=NEED["hands"], newLevel=1, timeoutMs=60000)
        c.C("gate", mode=c.gate)
        rig.paper, rig.standby = new, old
        # The next standby boots on the dead Paper's ports while requirements continue (not counted in the switch).
        tb = time.time()
        rig.standby.port, rig.standby.control = free_port(), free_port()
        rig.share(rig.paper, rig.standby)
        t["next_standby_boot_s"] = rig.standby.boot()
        t["_ready_rel"] = tb - t0
    elif kind == "K3":
        rr = rig.paper.S("k.reload", _dispatch="direct")
        t["reload_ms"] = round(rr["reloadUs"] / 1000, 2)
        t["reload_wall_s"] = round(time.time() - t0, 3)
        if before_boot:
            before_boot()
        c.C("gate", mode=0)
        c.C("k.connect", addr=rig.paper.addr)
        r = c.C("k.ready", need=NEED["hands"], newLevel=1, timeoutMs=60000)
        c.C("gate", mode=c.gate)
    else:
        raise ValueError(kind)
    assert r["ok"], r
    t["ready_s"] = round(r["at"] / 1e6 - t0, 3)
    t["level_s"] = round(r["levelAt"] / 1e6 - t0, 3)
    t["chunks_s"] = round(r["chunksAt"] / 1e6 - t0, 3) if r["chunksAt"] > 0 else None
    t.setdefault("attempts", None)
    t.pop("_ready_rel", None)
    return t


def scene_cfg(rig, scene, broken):
    for p in (rig.paper, rig.standby):
        if p is None or p.S is None or not p.proc.alive():
            continue
        p.S("k.cfg", graceTicks=100, holdGrace=10, saveOnReward=int(not (scene == "reward" and broken)),
          keepMail=int(scene == "mail" and broken), persistSessions=int(scene == "grace" and broken))


def trial(rig, kind, scene, broken, i, after):
    c = rig.clients[0]
    S = rig.paper.S
    scene_cfg(rig, scene, broken)
    S("k.wipe", player=c.name, scope="full")
    c.C("clearChat")
    tok = f"{scene[0]}{i}x{random.randrange(10**5)}"
    uuid = c.C("k.user", name=c.name)["uuid"]
    before = None
    if scene == "grace":
        # The session exists before the restart (the join made it); a rejoin within the grace keeps it unless Paper died.
        assert c.reconnect(rig.paper.addr, NEED["chunks"])["ok"]
    elif scene == "reward":
        S("k.owe", player=c.name, tok=tok)
        c.barrier(S)
    elif scene == "mail":
        def before():
            # The realm queues mail for the player while Paper is down (or reloading): written straight to the store.
            p = rig.paper if kind != "K2" else rig.standby
            mail = p.dir / "plugins/Probe/k/mail" / f"{uuid}.txt"
            mail.parent.mkdir(parents=True, exist_ok=True)
            mail.write_text(tok + "\n")
    t = restart(rig, kind, c, before)
    S = rig.paper.S
    c.barrier(S)
    lines = chat_lines(c)
    out = {"kind_": kind, "scene": scene, "broken": broken, **t}
    if scene == "grace":
        j = [l for l in lines if l.startswith(f"KJOIN {c.name} ")]
        out["join_line"] = j[0] if j else None
        passed = bool(j) and "resumed=0" in j[0]
    elif scene == "reward":
        inv = c.C("k.inv", name="R" + tok)
        out["count"] = inv["count"]
        passed = inv["count"] == 1
    else:
        first = sum(1 for l in lines if l == f"KMAIL {tok}")
        assert c.reconnect(rig.paper.addr, NEED["chunks"])["ok"]
        c.barrier(S)
        second = sum(1 for l in chat_lines(c) if l == f"KMAIL {tok}")
        out["mail"] = [first, second]
        passed = first == 1 and second == 0
    out["passed"] = passed
    out["wrong"] = passed == broken
    # Ordinary requirements after the restart: a chat line through the tick dispatch, judged on the client's facts.
    wrong_after, after_s = 0, []
    for j in range(after):
        token = f"KA{i}x{j}r{random.randrange(10**5)}"
        a0 = time.time()
        S("act", player=c.name, kind="chat", token=token)
        seen = c.C("observe", needle=needle_for("chat", token, "STONE"), timeoutMs=3000)
        after_s.append(time.time() - a0)
        if not seen.get("ok"):
            wrong_after += 1
    out["after_wrong"] = wrong_after
    out["after_med_ms"] = round(statistics.median(after_s) * 1000, 1) if after_s else None
    return out


def dump(rig):
    import subprocess
    for c in rig.clients:
        pid = c.client.java_pid()
        if pid:
            out = subprocess.run(["jstack", str(pid)], capture_output=True, text=True, timeout=60).stdout
            (c.client.dir / "jstack.txt").write_text(out)


def cmd_restart(a):
    scenes = a.scenes.split(",")
    with Rig(f"{a.label}-{a.kind}", clients=1, standby=a.kind == "K2", gate=a.gate) as rig:
        rig.paper.S("tickrate", rate=a.rate)
        rows = []
        for i in range(a.n):
            for scene in scenes:
                for broken in (False, True):
                    if rig.standby and rig.standby.S is not None:
                        rig.standby.S("tickrate", rate=a.rate)
                    try:
                        rows.append(trial(rig, a.kind, scene, broken, i, a.after))
                    except Exception:
                        dump(rig)
                        raise
                    print(json.dumps({k: v for k, v in rows[-1].items()})[:400], flush=True)
        leftovers = rig.paper.S("k.files")
        reports = len(list((rig.clients[0].client.dir / "debug").glob("disconnect-*")))
    by = {}
    for r in rows:
        by.setdefault(r["scene"], []).append(r)
    summary = {
        "ready_s": stat([r["ready_s"] for r in rows]), "done_s": stat([r.get("done_s") for r in rows]),
        "boot_s": stat([r.get("boot_s") for r in rows]), "level_s": stat([r["level_s"] for r in rows]),
        "chunks_s": stat([r["chunks_s"] for r in rows]), "reload_ms": stat([r.get("reload_ms") for r in rows]),
        "next_standby_boot_s": stat([r.get("next_standby_boot_s") for r in rows]),
        "wrong": {s: sum(r["wrong"] for r in v) for s, v in by.items()},
        "wrong_detail": {s: [(r["broken"], r["passed"]) for r in v if r["wrong"]][:6] for s, v in by.items()},
        "trials": {s: len(v) for s, v in by.items()},
        "after_wrong": sum(r["after_wrong"] for r in rows), "after_n": a.after * len(rows),
        "after_med_ms": stat([r["after_med_ms"] for r in rows]),
    }
    record("restart", label=a.label, restart=a.kind, rate=a.rate, gate=a.gate, n=a.n, scenes=a.scenes, cds=JSA.exists(), **summary,
           client_disconnect_reports=reports, files=leftovers.get("files"),
           rows=[{k: r[k] for k in ("scene", "broken", "passed", "ready_s") if k in r} for r in rows][:40])
    print(json.dumps({"leaks": leak_check()}))


# ---------- isolation ----------

def leaks_of(saw, lines, tok):
    kinds = [k for k, d in DEFAULTS.items() if str(saw.get(k, d)) != str(d)]
    foreign = [l for l in lines if l.startswith(("KH ", "KMAIL ", "KHOLD ", "KGIVEN ", "KREQ ")) and tok not in l]
    if any(l.startswith("KJOIN") and "resumed=1" in l for l in lines):
        foreign.append("resumed")
    return kinds, foreign


def iso_loop(rig, c, mode, n, need, prefix, out, stop_at=None):
    S = rig.paper.S if len(rig.clients) == 1 else Line(rig.paper.line, prefix="tick/")
    name = c.name
    for i in range(n):
        if stop_at and time.time() > stop_at:
            break
        t0 = time.time()
        if mode in ("I1", "I0"):
            if mode == "I1":
                name = f"{prefix}{i}"
                c.C("k.user", name=name)
            r = c.reconnect(rig.paper.addr, need)
        else:
            w = S("k.wipe", player=name, scope="full" if mode == "I2full" else "naive")
            c.C("clearChat")
            c.C("clearToasts")
            r = c.C("k.ready", need=need, timeoutMs=30000)
        if not r["ok"]:
            out.append({"i": i, "client": c.i, "error": "not ready", "r": r})
            continue
        t1 = time.time()
        tok = f"T{c.i}x{i}r{random.randrange(10**5)}"
        b = c.next_ping()
        res = S("k.req", player=name, tok=tok, ping=b)
        c.C("state", ping=b, timeoutMs=20000)
        lines = c.C("k.chat")["lines"]
        mine = [l for l in lines if l.startswith(f"KREQ {tok}")]
        t2 = time.time()
        kinds, foreign = leaks_of({k[2:]: v for k, v in res.items() if k.startswith("s_")}, lines, tok)
        out.append({"i": i, "client": c.i, "iso_s": t1 - t0, "req_s": t2 - t1, "total_s": t2 - t0, "chunks_s": (r["chunksAt"] / 1e6 - t0) if r.get("chunksAt", -1) > 0 else None,
                    "seen": bool(mine), "kinds": kinds, "foreign": foreign[:3], "wipe_us": w.get("wipeUs") if mode.startswith("I2") else None})


def cmd_iso(a):
    need = NEED[a.need]
    with Rig(f"{a.label}-{a.mode}", clients=a.clients, gate=a.gate) as rig:
        S = rig.paper.S
        S("k.cfg", graceTicks=100, holdGrace=10, saveOnReward=1, keepMail=0, persistSessions=0)
        S("tickrate", rate=a.rate)
        prefix = f"k{random.randrange(100):02d}"
        mem0 = {"server": rss_mb(rig.paper.proc.p.pid), **{f"c{c.i}": rss_mb(c.client.java_pid()) for c in rig.clients}}
        files0 = S("k.files")
        out = []
        t0 = time.time()
        threads = [threading.Thread(target=iso_loop, args=(rig, c, a.mode, a.n, need, f"{prefix}{c.i}_", out)) for c in rig.clients]
        for t in threads:
            t.start()
        for t in threads:
            t.join()
        wall = time.time() - t0
        time.sleep(0.5)
        files1 = S("k.files")
        mem1 = {"server": rss_mb(rig.paper.proc.p.pid), **{f"c{c.i}": rss_mb(c.client.java_pid()) for c in rig.clients}}
        status = S("status")
        reasons = []
        for c in rig.clients:
            for line in (c.client.dir / "client.log").read_text(errors="replace").splitlines():
                if "disconnected with reason" in line or "Connection throttled" in line or "kicked" in line.lower():
                    reasons.append(line[-160:])
        srv = [l[-200:] for l in (rig.paper.dir / "server.log").read_text(errors="replace").splitlines() if "lost connection" in l and "Disconnected" not in l][:5]
    ok = [r for r in out if "error" not in r]
    kinds = {}
    for r in ok[len(rig.clients):] if a.mode != "I1" else ok:
        for k in r["kinds"]:
            kinds[k] = kinds.get(k, 0) + 1
    foreign = sum(1 for r in ok if r["foreign"])
    first_after = [r for r in ok if r["i"] > 0]
    record("iso", label=a.label, mode=a.mode, rate=a.rate, gate=a.gate, need=a.need, clients=a.clients, n=len(out), errors=len(out) - len(ok),
           wall_s=round(wall, 1), per_req_s=round(wall / max(1, len(ok)), 3), iso_s=stat([r["iso_s"] for r in ok]), req_s=stat([r["req_s"] for r in ok]),
           total_s=stat([r["total_s"] for r in ok]), chunks_s=stat([r["chunks_s"] for r in ok]), wipe_us=stat([r["wipe_us"] for r in ok]),
           unseen=sum(1 for r in ok if not r["seen"]), leak_kinds=kinds, leaky_reqs=sum(1 for r in first_after if r["kinds"]), foreign_chat=foreign,
           foreign_example=next((r["foreign"] for r in ok if r["foreign"]), None), mem_before=mem0, mem_after=mem1,
           files_before=files0, files_after=files1, tps=status.get("tps"), first_error=next((r for r in out if "error" in r), None),
           disconnect_reasons=sorted(set(x.split("reason: ", 1)[-1] for x in reasons))[:6], server_lost=srv)
    print(json.dumps({"leaks": leak_check()}))


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    sub.add_parser("prep")
    r = sub.add_parser("restart")
    r.add_argument("--kind", default="K1", choices=["K1", "K1auto", "K1stop", "K2", "K3"])
    r.add_argument("--n", type=int, default=3)
    r.add_argument("--scenes", default="grace,reward,mail")
    r.add_argument("--after", type=int, default=5)
    r.add_argument("--rate", type=float, default=20)
    r.add_argument("--gate", type=int, default=2)
    r.add_argument("--label", default="mac")
    i = sub.add_parser("iso")
    i.add_argument("--mode", default="I1", choices=["I1", "I0", "I2naive", "I2full"])
    i.add_argument("--n", type=int, default=100)
    i.add_argument("--rate", type=float, default=20)
    i.add_argument("--clients", type=int, default=1)
    i.add_argument("--gate", type=int, default=2)
    i.add_argument("--need", default="hands", choices=list(NEED))
    i.add_argument("--label", default="mac")
    a = ap.parse_args()
    try:
        {"prep": cmd_prep, "restart": cmd_restart, "iso": cmd_iso}[a.cmd](a)
    finally:
        stop_all()


if __name__ == "__main__":
    main()
