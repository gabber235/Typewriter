#!/usr/bin/env python3
"""Boot prototype: how far can the boot of a restart requirement's Paper be cut?

  boot.py run --variants base,aot,slim --n 1 [--par 1|4] [--scenes reward,grace,mail] [--label mac]
  boot.py phases --variant base [--label mac]

run: warm clients stay up across variants. Per variant: build its cache if it has one (trained on a real boot with
the step agent; `join` variants also train a client join), boot its Paper, move the clients there, then run K's
restart scenes (reward, grace, mail), each good and deliberately broken. A trial is SIGKILL, boot the same directory
and ports, the client connects at Done, waits for the facts start signal (radius chunks) and the scene's state is read.
Every time is measured from the new process's spawn. With --par 4 four Papers, each with its own client, are killed
and booted at the same moment.

phases: one restart trial with every line of Paper's log stamped as it arrives, per thread CPU (jcmd Thread.print)
at Done and at ready, a JFR recording dumped at Done and class load sources.

Throwaway Papers and clients start only under runs/, on free ports, and every command stops what it started.
"""
import argparse, json, os, pathlib, platform, random, re, shutil, statistics, subprocess, sys, threading, time

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import run as R
from run import RUNS, PAPER_JAR, MARKER, free_port, leak_check, stop_all, rss_mb, now_micros
import k as K
import topo as T
from speed import Line, needle_for
from c4 import AOT, classpath

RESULTS = RUNS / "boot.jsonl"
hooks = {"record": None}
LINUX = platform.system() == "Linux"

# One axis changed against the baseline (today's restart Paper of the topology rig) per variant; `best` combines.
FAST = ["-XX:TieredStopAtLevel=1", "-XX:+UseSerialGC", "-XX:-UsePerfData", "-Xss512k"]
VARIANTS = {
    "base": {"cache": "cds"},
    "nocache": {"cache": None},
    "xshareoff": {"cache": None, "jvm": ["-Xshare:off"]},
    "cdsjoin": {"cache": "cds", "join": True},
    # JDK 25 cannot archive Minecraft's MethodType table (one 262 KB array, over the 256 KB object limit) when
    # AOTClassLinking archives invokedynamic sites; "aot" keeps class linking without them.
    "aot": {"cache": "aot", "join": True, "aot": ["-XX:-AOTInvokeDynamicLinking"]},
    "aotfull": {"cache": "aot", "join": True, "aot": []},
    "aotnolink": {"cache": "aot", "join": True, "aot": ["-XX:-AOTClassLinking"]},
    "aotnojoin": {"cache": "aot", "aot": ["-XX:-AOTInvokeDynamicLinking"]},
    "slim": {"cache": "cds", "slim": True},
    "c1": {"cache": "cds", "jvm": ["-XX:TieredStopAtLevel=1"]},
    "serial": {"cache": "cds", "jvm": ["-XX:+UseSerialGC"]},
    "parallel": {"cache": "cds", "jvm": ["-XX:+UseParallelGC"]},
    "fastjvm": {"cache": "cds", "jvm": FAST},
    # Paperclip runs the server in its own class loader, which cannot see the agent's classes on the app class path.
    "jar": {"cache": "cds", "launch": "jar", "jvm": [f"-Xbootclasspath/a:{T.AGENT}"]},
    "cold": {"cache": "cds", "cold": True, "cache_of": "base"},
    "best": {"cache": "aot", "join": True, "slim": True, "jvm": FAST, "aot": ["-XX:-AOTInvokeDynamicLinking"]},
    # The client stays gated (draws no frames) while Paper boots and is ungated when it connects at Done.
    "baseq": {"cache": "cds", "quiet": True, "cache_of": "base"},
    "bestq": {"cache": "aot", "join": True, "slim": True, "jvm": FAST, "aot": ["-XX:-AOTInvokeDynamicLinking"], "quiet": True, "cache_of": "best"},
    "bestcds": {"cache": "cds", "join": True, "slim": True, "jvm": FAST},
}


def record(kind, **row):
    row = {"kind": kind, "at": time.strftime("%Y-%m-%dT%H:%M:%S"), "load": round(os.getloadavg()[0], 1), **row}
    RUNS.mkdir(exist_ok=True)
    with RESULTS.open("a") as f:
        f.write(json.dumps(row) + "\n")
    if hooks["record"]:
        hooks["record"]("boot-" + kind, **{k: v for k, v in row.items() if k != "kind"})
    print(json.dumps(row)[:1200], flush=True)


def stat(v):
    v = sorted(x for x in v if x is not None)
    if not v:
        return None
    return {"n": len(v), "med": round(statistics.median(v), 3), "min": round(v[0], 3), "max": round(v[-1], 3)}


def cpu(pid):
    return T.proc_cpu(pid) if pid else None


# ---------- a Paper whose log lines are stamped as they arrive ----------

class StampedProc(R.Proc):
    """Like run.Proc, but stdout comes through a pipe so every line gets its arrival time."""

    def __init__(self, cmd, cwd, log):
        self.log_path = log
        self.log = open(log, "wb")
        self.lines = []
        self.spawn_micros = now_micros()
        self.p = subprocess.Popen(cmd, cwd=cwd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, start_new_session=True)
        R.live.append(self)
        self.reader = threading.Thread(target=self._read, daemon=True)
        self.reader.start()

    def _read(self):
        for raw in iter(self.p.stdout.readline, b""):
            self.lines.append((time.time(), raw.decode(errors="replace").rstrip("\n")))
            try:
                self.log.write(raw)
                self.log.flush()
            except ValueError:
                pass

    def first(self, pattern):
        rx = re.compile(pattern)
        for t, l in list(self.lines):
            if rx.search(l):
                return t
        return None


def java_major():
    out = subprocess.run(["java", "-version"], capture_output=True, text=True).stderr
    return int(re.search(r'version "(\d+)', out).group(1))


JAVA = java_major()


def cache_file(name, v):
    owner = v.get("cache_of", name)
    return AOT / f"boot-{owner}.{'jsa' if v['cache'] == 'cds' else 'aot'}"


class BPaper(T.TPaper):
    """The topology rig's unstepped restart Paper, with the variant's cache, launch, JVM flags and config."""

    def __init__(self, run_dir, name, variant, mode="use"):
        super().__init__(run_dir, name, stepped=False)
        self.vname, self.v, self.mode = name, VARIANTS[name], mode
        # TPaper inherits K's archive and its silenced cds logs; this prototype names its own cache and keeps warnings.
        self.jvm = [j for j in self.jvm if not j.startswith("-XX:SharedArchiveFile") and not j.startswith("-Xlog:cds")]
        if JAVA >= 26:
            # Java 26 removed the flag; an agent no longer keeps classes out of the archive.
            self.jvm = [j for j in self.jvm if j != "-XX:+AllowArchivingWithJavaAgent"]
        self.jvm += self.v.get("jvm", [])
        c = self.v["cache"]
        f = cache_file(name, self.v) if c else None
        if c == "cds":
            self.jvm.append(f"-XX:ArchiveClassesAtExit={f}" if mode == "train" else f"-XX:SharedArchiveFile={f}")
        elif c == "aot":
            self.jvm = [j for j in self.jvm if not j.startswith("-Xshare")]
            if mode == "train":
                self.jvm += ["-XX:AOTMode=record", f"-XX:AOTConfiguration={f}conf"]
            else:
                self.jvm += ["-XX:AOTMode=on", f"-XX:AOTCache={f}", *self.v.get("aot", [])]
        self.cache = f
        self.trim = True
        self.direct = self.v.get("launch", "direct") == "direct"

    def setup(self):
        super().setup()
        if self.v.get("slim"):
            slim(self.dir)

    def start(self):
        self.setup()
        launch = ["-cp", classpath(), "org.bukkit.craftbukkit.Main"] if self.direct else ["-jar", str(PAPER_JAR)]
        cmd = ["java", f"-D{MARKER}=1", f"-Xmx{self.xmx}", f"-Dprobe.control.port={self.control}", *self.jvm, *launch, "--nogui"]
        self.cmdline = cmd
        self.proc = StampedProc(cmd, self.dir, self.dir / "server.log")
        return self

    def wait_done(self, timeout=240):
        deadline = time.time() + timeout
        while time.time() < deadline:
            t = self.proc.first(r"Done \((\d+[.,]\d+)s\)!")
            if t:
                self.done_at = t
                self.done_seconds = t - self.proc.spawn_micros / 1e6
                return self.done_seconds
            if not self.proc.alive():
                time.sleep(0.2)
                raise RuntimeError("Paper exited before Done, see " + str(self.proc.log_path) + "\n" + "\n".join(l for _, l in self.proc.lines[-15:]))
            time.sleep(0.01)
        raise RuntimeError("Paper did not reach Done")

    def pid(self):
        return self.proc.p.pid


def slim(d):
    """Everything at boot a void restart Paper can do without: no nether, smallest distances, no advancements,
    no bStats. Applied on top of the trimmed setup (no nether, no end, no spark)."""
    props = d / "server.properties"
    text = props.read_text()
    text = re.sub(r"view-distance=\d+", "view-distance=2", text)
    text = re.sub(r"simulation-distance=\d+", "simulation-distance=2", text)
    props.write_text(text + "enable-jmx-monitoring=false\nenable-status=true\nsync-chunk-writes=false\n")
    (d / "spigot.yml").write_text("advancements:\n  disable-saving: true\n  disabled:\n  - '*'\nstats:\n  disable-saving: true\nsettings:\n  save-user-cache-on-stop-only: true\n")
    # Paper 26 ignores allow-nether in server.properties; its switch is paper-global.yml misc.enable-nether.
    cfg = d / "config" / "paper-global.yml"
    cfg.write_text(cfg.read_text().replace("enable-nether: true", "enable-nether: false", 1))
    (d / "plugins/bStats").mkdir(parents=True, exist_ok=True)
    (d / "plugins/bStats/config.yml").write_text("enabled: false\nserverUuid: 00000000-0000-0000-0000-000000000000\nlogFailedRequests: false\n")


# ---------- clients that outlive the variants ----------

class Addr:
    def __init__(self):
        self.addr = None


class Pool:
    def __init__(self, label, n):
        self.run = RUNS / f"boot-{label}-{int(time.time())}"
        self.slot = [Addr() for _ in range(n)]
        self.clients = [K.KClient(self.run, i, f"probe{i + 1}", self.slot[i]) for i in range(n)]
        self.joined = [False] * n

    def to(self, i, paper):
        """Connect client i to paper: the first time by starting it there, afterwards like the pause menu."""
        c = self.clients[i]
        self.slot[i].addr = paper.addr
        if not self.joined[i]:
            c.join()
            self.joined[i] = True
        else:
            r = c.reconnect(paper.addr, K.NEED["chunks"])
            assert r["ok"], r
        paper.S = Line(paper.line, prefix="tick/")
        paper.prepare_world([c.name])
        c.C("clearToasts")
        c.C("clearChat")

    def stop(self):
        for c in self.clients:
            c.stop()


def boot(paper):
    paper.start()
    paper.wait_done()
    paper.S = Line(paper.line, prefix="tick/")


def drop_page_cache():
    if LINUX:
        subprocess.run(["sudo", "sh", "-c", "sync; echo 3 > /proc/sys/vm/drop_caches"], check=True, timeout=60)
        return True
    return False


def train(pool, i, name, run):
    """Builds the variant's cache on a real boot with the agent loaded; join variants also train a client joining,
    leaving and joining again, and reading the scene state."""
    v = VARIANTS[name]
    f = cache_file(name, v)
    if f.exists():
        return None
    AOT.mkdir(parents=True, exist_ok=True)
    t0 = time.time()
    p = BPaper(run / f"train-{name}", name, None, mode="train")
    boot(p)
    if v.get("join"):
        pool.to(i, p)
        c = pool.clients[i]
        p.S("k.cfg", graceTicks=100, holdGrace=10, saveOnReward=1, keepMail=0, persistSessions=0)
        p.S("k.owe", player=c.name, tok="train")
        c.barrier(p.S)
        c.C("k.inv", name="Rtrain")
        assert c.reconnect(p.addr, K.NEED["chunks"])["ok"]
        c.barrier(p.S)
        c.C("k.chat")
    p.stop_slow()
    out = {"variant": name, "train_s": round(time.time() - t0, 1)}
    if v["cache"] == "aot":
        conf = pathlib.Path(f"{f}conf")
        out["conf_mb"] = round(conf.stat().st_size / 1e6, 1) if conf.exists() else None
        launch = ["-cp", classpath()] if p.direct else ["-cp", str(PAPER_JAR)]
        flags = [j for j in p.jvm if j.startswith("-XX:+Use") or j.startswith("-XX:TieredStop") or j.startswith("-javaagent")
                 or j in ("-XX:+UnlockDiagnosticVMOptions", "-XX:+AllowArchivingWithJavaAgent")]
        tc = time.time()
        cr = subprocess.run(["java", f"-Xmx{p.xmx}", *flags, *v.get("aot", []), "-XX:AOTMode=create", f"-XX:AOTConfiguration={conf}", f"-XX:AOTCache={f}", *launch],
                            capture_output=True, text=True, timeout=900)
        out["create_s"] = round(time.time() - tc, 1)
        out["create_rc"] = cr.returncode
        out["create_tail"] = "\n".join(l for l in (cr.stdout + cr.stderr).splitlines() if "Skipping" not in l and "aot-resolve" not in l)[-1500:]
        if cr.returncode != 0:
            f.unlink(missing_ok=True)
    out["cache_mb"] = round(f.stat().st_size / 1e6, 1) if f.exists() else None
    tail = [l for _, l in p.proc.lines if re.search(r"(?i)\b(cds|aot)\b|archiv|warning.*share", l)][-8:]
    out["train_log"] = tail
    record("train", **out)
    shutil.rmtree(run / f"train-{name}", ignore_errors=True)
    return out


def cmdline(paper):
    c = list(paper.cmdline)
    if "-cp" in c:
        c[c.index("-cp") + 1] = "<classpath>"
    return " ".join(c)[:900]


def mapped(paper):
    """How the JVM says the cache was used: CDS and AOT lines of VM.info."""
    try:
        out = subprocess.run(["jcmd", str(paper.pid()), "VM.info"], capture_output=True, text=True, timeout=60).stdout
    except Exception as e:
        return str(e)
    keep = [l.strip() for l in out.splitlines() if re.search(r"(?i)shared|\bcds\b|\baot\b", l) and len(l) < 300]
    return keep[:12]


# ---------- one restart trial ----------

def arrange(paper, c, scene, broken, i):
    S = paper.S
    S("k.cfg", graceTicks=100, holdGrace=10, saveOnReward=int(not (scene == "reward" and broken)),
      keepMail=int(scene == "mail" and broken), persistSessions=int(scene == "grace" and broken))
    S("k.wipe", player=c.name, scope="full")
    c.C("clearChat")
    tok = f"{scene[0]}{i}x{random.randrange(10**6)}"
    uuid = c.C("k.user", name=c.name)["uuid"]
    if scene == "grace":
        assert c.reconnect(paper.addr, K.NEED["chunks"])["ok"]
        paper.S = Line(paper.line, prefix="tick/")
    elif scene == "reward":
        S("k.owe", player=c.name, tok=tok)
        c.barrier(S)
    return tok, uuid


def kill(paper, c, scene, tok, uuid):
    c.C("k.mark")
    paper.kill()
    c.C("k.gone", timeoutMs=20000)
    if not paper.v.get("quiet"):
        c.C("gate", mode=0)
    if scene == "mail":
        mail = paper.dir / "plugins/Probe/k/mail" / f"{uuid}.txt"
        mail.parent.mkdir(parents=True, exist_ok=True)
        mail.write_text(tok + "\n")


def after_reqs(paper, c, n):
    """Work right after the boot, to see whether a flag that speeds the boot slows what then runs on the Paper:
    n chat requirements at tick rate 200 (so a tick wait does not hide server latency), judged on the client, and
    5 region moves (teleport to fresh void chunks and build a 17x17 platform on the server thread, timed in Paper)."""
    if not n:
        return {}
    paper.S("tickrate", rate=200)
    times, wrong, plat = [], 0, []
    try:
        for j in range(n):
            token = f"BA{j}r{random.randrange(10**6)}"
            a0 = time.perf_counter()
            paper.S("act", player=c.name, kind="chat", token=token)
            seen = c.C("observe", needle=needle_for("chat", token, "STONE"), timeoutMs=3000)
            times.append((time.perf_counter() - a0) * 1000)
            wrong += 0 if seen.get("ok") else 1
        for j in range(5):
            r = paper.S("region", player=c.name, idx=random.randrange(1, 10**4), chunks=8)
            plat.append(r["platformMs"])
    finally:
        paper.S("tickrate", rate=20)
    times.sort()
    return {"after_n": n, "after_med_ms": round(statistics.median(times), 1), "after_p95_ms": round(times[int(len(times) * 0.95) - 1], 1),
            "after_wrong": wrong, "platform_med_ms": round(statistics.median(plat), 1), "platform_max_ms": round(max(plat), 1)}


def come_back(paper, c, scene, broken, tok, ccpu0, snap=None, after=0):
    """Boot, connect at Done, facts start signal, read the scene's state. Times are seconds from spawn."""
    paper.start()
    spawn = paper.proc.spawn_micros / 1e6
    paper.wait_done()
    if snap:
        snap("done")
    if paper.v.get("quiet"):
        c.C("gate", mode=0)
    c.C("k.connect", addr=paper.addr)
    r = c.C("k.ready", need=K.NEED["chunks"], newLevel=1, timeoutMs=60000)
    assert r["ok"], r
    if snap:
        snap("ready")
    paper.S = Line(paper.line, prefix="tick/")
    c.barrier(paper.S)
    if scene == "reward":
        count = c.C("k.inv", name="R" + tok)["count"]
        passed, detail = count == 1, count
    elif scene == "grace":
        lines = c.C("k.chat")["lines"]
        j = [l for l in lines if l.startswith(f"KJOIN {c.name} ")]
        passed, detail = bool(j) and "resumed=0" in j[0], (j[0] if j else None)
    else:
        first = sum(1 for l in c.C("k.chat")["lines"] if l == f"KMAIL {tok}")
        passed, detail = first == 1, first
    t_state = time.time()
    pcpu = cpu(paper.pid())
    ccpu = cpu(c.client.java_pid())
    rss = rss_mb(paper.pid())
    c.C("gate", mode=c.gate)
    if scene == "mail":
        assert c.reconnect(paper.addr, K.NEED["chunks"])["ok"]
        paper.S = Line(paper.line, prefix="tick/")
        c.barrier(paper.S)
        second = sum(1 for l in c.C("k.chat")["lines"] if l == f"KMAIL {tok}")
        passed, detail = passed and second == 0, [detail, second]
    paper.prepare_world([c.name])
    extra = after_reqs(paper, c, after)
    lines = paper.proc.lines
    first_line = lines[0][0] - spawn if lines else None
    return {
        "scene": scene, "broken": broken, "passed": passed, "wrong": passed == broken, "detail": detail,
        "first_log_s": round(first_line, 3) if first_line is not None else None,
        "done_s": round(paper.done_at - spawn, 3), "ready_s": round(r["at"] / 1e6 - spawn, 3),
        "state_s": round(t_state - spawn, 3), "paper_cpu_s": round(pcpu, 2) if pcpu is not None else None,
        "client_cpu_s": round(ccpu - ccpu0, 2) if ccpu is not None and ccpu0 is not None else None,
        "paper_rss_mb": rss, **extra, "reported_done": float(re.search(r"Done \((\d+[.,]\d+)s\)", "\n".join(l for _, l in lines)).group(1).replace(",", ".")),
    }


def trial(paper, c, scene, broken, i, sync=None, after=0):
    tok, uuid = arrange(paper, c, scene, broken, i)
    if sync:
        sync.wait(120)
    ccpu0 = cpu(c.client.java_pid())
    t_kill = time.time()
    kill(paper, c, scene, tok, uuid)
    if paper.v.get("cold"):
        drop_page_cache()
    out = come_back(paper, c, scene, broken, tok, ccpu0, after=after)
    out["kill_to_state_s"] = round(out["state_s"] + paper.proc.spawn_micros / 1e6 - t_kill, 3)
    out["t_kill"] = t_kill
    return out


# ---------- commands ----------

def run_variant(pool, name, a):
    v = VARIANTS[name]
    run = pool.run
    if v["cache"]:
        train(pool, 0, v.get("cache_of", name), run)
        if not cache_file(name, v).exists():
            raise RuntimeError(f"no {v['cache']} cache could be built for {name}")
    papers = [BPaper(run / f"{name}-{i}", name, None) for i in range(a.par)]
    mem = T.Mem(lambda: [p.pid() for p in papers if p.proc] + [c.client.java_pid() for c in pool.clients])
    rows = []
    try:
        for i, p in enumerate(papers):
            boot(p)
            pool.to(i, p)
        info = {"variant": name, "par": a.par, "cmd": cmdline(papers[0]),
                "mapped": mapped(papers[0]), "cache_mb": round(papers[0].cache.stat().st_size / 1e6, 1) if papers[0].cache and papers[0].cache.exists() else None}
        with mem:
            scenes = a.scenes.split(",")
            plan = [(s, b, j) for j in range(a.n) for s in scenes for b in (False, True)]
            sync = threading.Barrier(a.par) if a.par > 1 else None
            errors = []

            def worker(k):
                try:
                    for s, b, j in plan:
                        r = trial(papers[k], pool.clients[k], s, b, j, sync, a.after)
                        r.update({"variant": name, "par": a.par, "slot": k, "label": a.label, "cpu_model": T.cpu_model()})
                        rows.append(r)
                        record("trial", **{x: y for x, y in r.items() if x != "t_kill"})
                except Exception as e:
                    errors.append(repr(e))
                    if sync:
                        sync.abort()
                    raise

            ts = [threading.Thread(target=worker, args=(k,)) for k in range(a.par)]
            for t in ts:
                t.start()
            for t in ts:
                t.join()
            if errors:
                raise RuntimeError("; ".join(errors))
        # Group wall for parallel rounds: first kill to last state read.
        rounds = []
        if a.par > 1:
            for s, b, j in plan:
                rr = [r for r in rows if r["scene"] == s and r["broken"] == b]
                if len(rr) == a.par:
                    rounds.append(max(r["t_kill"] + r["kill_to_state_s"] for r in rr) - min(r["t_kill"] for r in rr))
        summary = {**info, "label": a.label, "cpu_model": T.cpu_model(), "trials": len(rows), "wrong": sum(r["wrong"] for r in rows),
                   **{k: stat([r.get(k) for r in rows]) for k in ("first_log_s", "done_s", "ready_s", "state_s", "kill_to_state_s", "paper_cpu_s", "client_cpu_s", "paper_rss_mb", "after_med_ms", "after_p95_ms", "platform_med_ms")},
                   "after_wrong": sum(r.get("after_wrong", 0) for r in rows),
                   "round_wall_s": stat(rounds), "peak_used_mb": mem.peak_used or None, "peak_rss_mb": mem.peak_rss}
        record("summary", **summary)
        return summary
    finally:
        for p in papers:
            if p.proc and p.proc.alive():
                try:
                    p.kill()
                except Exception as e:
                    print("kill:", e, file=sys.stderr)
        for p in papers:
            shutil.rmtree(p.dir, ignore_errors=True)


def cmd_run(a):
    names = a.variants.split(",")
    for n in names:
        assert n in VARIANTS, n
    pool = Pool(a.label, a.par)
    try:
        for name in names:
            if a.deadline and time.time() > a.deadline:
                record("skipped", variant=name, par=a.par, label=a.label, why="deadline")
                continue
            try:
                run_variant(pool, name, a)
            except Exception as e:
                record("error", variant=name, par=a.par, label=a.label, error=repr(e)[:1500])
                if any(j and not c.client.proc.alive() for c, j in zip(pool.clients, pool.joined)):
                    raise
    finally:
        pool.stop()
        stop_all()
        if hooks.get("cleanup"):
            hooks["cleanup"](pool)
        if not a.keep:
            shutil.rmtree(pool.run, ignore_errors=True)
    print(json.dumps({"leaks": leak_check()}))


def threads(pid):
    """Per thread CPU ms from jcmd Thread.print (cpu=...ms), grouped by thread kind."""
    out = subprocess.run(["jcmd", str(pid), "Thread.print"], capture_output=True, text=True, timeout=60).stdout
    groups = {}
    for m in re.finditer(r'^"([^"]+)".*?cpu=([\d.]+)ms', out, re.M):
        name = re.sub(r"[#\-]?\d+$", "", m.group(1)).strip()
        name = re.sub(r"\d+$", "", name)
        groups[name] = groups.get(name, 0) + float(m.group(2))
    return {k: round(v) for k, v in sorted(groups.items(), key=lambda kv: -kv[1]) if v >= 20}


def cmd_phases(a):
    """One restart trial with stamped log lines, thread CPU at Done and ready, a JFR recording and class sources."""
    name = a.variant
    pool = Pool(a.label + "-phases", 1)
    try:
        v = VARIANTS[name]
        if v["cache"]:
            train(pool, 0, name, pool.run)
        p = BPaper(pool.run / f"{name}-phases", name, None)
        boot(p)
        pool.to(0, p)
        c = pool.clients[0]
        out_dir = RUNS / "boot-phases" / f"{a.label}-{name}"
        shutil.rmtree(out_dir, ignore_errors=True)
        out_dir.mkdir(parents=True)
        jfr = out_dir / "boot.jfr"
        # JFR adds the jdk.jfr module; an AOT cache with linked classes refuses a module graph other than its own.
        use_jfr = v["cache"] != "aot"
        if use_jfr:
            p.jvm.append(f"-XX:StartFlightRecording=name=boot,settings=profile,filename={jfr}")
        p.jvm.append(f"-Xlog:class+load=info:file={out_dir}/classload.log:uptime")
        tok, uuid = arrange(p, c, "reward", False, 0)
        ccpu0 = cpu(c.client.java_pid())
        kill(p, c, "reward", tok, uuid)
        snaps = {}

        def snap(at):
            snaps[at] = {"t": round(time.time() - p.proc.spawn_micros / 1e6, 3), "cpu_s": cpu(p.pid()), "threads": threads(p.pid())}
            if at == "done" and use_jfr:
                subprocess.run(["jcmd", str(p.pid()), "JFR.dump", "name=boot", f"filename={jfr}"], capture_output=True, timeout=120)

        r = come_back(p, c, "reward", False, tok, ccpu0, snap=snap)
        spawn = p.proc.spawn_micros / 1e6
        log = [(round(t - spawn, 3), l) for t, l in p.proc.lines]
        (out_dir / "stamped.log").write_text("\n".join(f"{t:8.3f} {l}" for t, l in log))
        cl = (out_dir / "classload.log").read_text(errors="replace").splitlines() if (out_dir / "classload.log").exists() else []
        src = {}
        for l in cl:
            m = re.search(r"source: (.*)$", l)
            k = m.group(1) if m else "?"
            k = "shared" if "shared" in k else ("jrt" if k.startswith("jrt:") else ("agent/transformed" if "instrument" in k or "__JVM" in k else re.sub(r".*/", "", k)[:60]))
            src[k] = src.get(k, 0) + 1
        top_src = dict(sorted(src.items(), key=lambda kv: -kv[1])[:12])
        views = {}
        for view in ("hot-methods", "gc", "allocation-by-class") if use_jfr else ():
            try:
                o = subprocess.run(["jfr", "view", "--width", "160", view, str(jfr)], capture_output=True, text=True, timeout=120)
                views[view] = (o.stdout or o.stderr)[:4000]
            except Exception as e:
                views[view] = str(e)
        (out_dir / "views.txt").write_text("\n\n".join(f"== {k}\n{v}" for k, v in views.items()))
        record("phases", variant=name, label=a.label, cpu_model=T.cpu_model(), trial=r, snaps=snaps,
               classes=len(cl), class_sources=top_src, log=[f"{t:.3f} {l[:160]}" for t, l in log][:400])
        p.kill()
    finally:
        pool.stop()
        stop_all()
        if hooks.get("cleanup"):
            hooks["cleanup"](pool)
        shutil.rmtree(pool.run, ignore_errors=True)
    print(json.dumps({"leaks": leak_check()}))


def main(argv=None):
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    r = sub.add_parser("run")
    r.add_argument("--variants", default="base")
    r.add_argument("--n", type=int, default=1)
    r.add_argument("--par", type=int, default=1)
    r.add_argument("--scenes", default="reward,grace,mail")
    r.add_argument("--label", default="mac")
    r.add_argument("--keep", action="store_true")
    r.add_argument("--after", type=int, default=0)
    r.add_argument("--deadline", type=float, default=0)
    p = sub.add_parser("phases")
    p.add_argument("--variant", default="base")
    p.add_argument("--label", default="mac")
    a = ap.parse_args(argv)
    {"run": cmd_run, "phases": cmd_phases}[a.cmd](a)


if __name__ == "__main__":
    main()
