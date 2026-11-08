#!/usr/bin/env python3
"""Restore prototype: a restart requirement restores a CRaC checkpoint of Paper instead of booting it.

  restore.py image --point boot|data|done --engine warp|criu [--policy none|boot|done] [--opts compression=true]
  restore.py compare --image NAME --n 5          boot against restore to Done, same dirs restarted (wall, CPU, memory)
  restore.py parallel --image NAME --k 4          k restores at once (and k boots at once for comparison)
  restore.py scenes --image NAME|boot --n 3       spike K's restart scenes plus a world value, good and broken

Checkpoint points (step agent prefix, probe.agent.Crac):
  boot  Main after Bootstrap.validate, before anything reads the server folder. The restore moves into the new
        folder (probe.agent.Restored dir=...), so everything Paper reads from the folder is read after the restore.
  data  Main after level.dat and the data packs are loaded (MinecraftServer.spin): level.dat state is baked in.
  done  after Done (probe plugin asks): every boot read state is baked in, like spike K's standby.

Paper here is K's direct, trimmed launch with the step agent, the probe plugin, the void world and the AppCDS
archive, logging to stdout only. Every command stops what it started.
"""
import argparse, json, os, pathlib, re, resource, shutil, signal, statistics, subprocess, sys, time

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import run as R
import k as K
from run import Proc, RUNS, CACHE, MARKER, free_port, leak_check, stop_all, now_micros
from speed import Line, needle_for

ROOT = pathlib.Path(__file__).resolve().parent.parent
AGENT = ROOT / "step-agent/build/libs/step-agent-0.jar"
LOG4J = pathlib.Path(__file__).resolve().parent / "log4j2-console.xml"
IMAGES = CACHE / "crac"
RESULTS = RUNS / "restore.jsonl"
TCK = os.sysconf("SC_CLK_TCK")
COMMON = ["-XX:+UnlockDiagnosticVMOptions", "-XX:+AllowArchivingWithJavaAgent", f"-javaagent:{AGENT}=lag=tick",
          "--add-opens", "java.base/java.io=ALL-UNNAMED", "--add-opens", "java.base/sun.nio.fs=ALL-UNNAMED",
          "--enable-native-access=ALL-UNNAMED", f"-Dlog4j.configurationFile={LOG4J}"]

POLICIES = {
    "none": None,
    # Files the JDK opened before the boot point that the restored JVM may keep (found by the strict run).
    "data": """type: socket
action: close
---
type: file
path: **/*.jar
action: ignore
warn: false
---
type: file
action: ignore
""",
    "boot": """type: file
path: **/*.jar
action: ignore
warn: false
---
type: file
path: **/*.jsa
action: ignore
warn: false
""",
    # After Done: listeners reopen on the same port, connections close, world and plugin files reopen.
    "done": """type: socket
listening: true
action: reopen
---
type: socket
action: close
---
type: file
path: **/*.jar
action: ignore
warn: false
---
type: file
path: **/*.jsa
action: ignore
warn: false
---
type: file
action: ignore
---
type: pipe
action: close
""",
}

hooks = {"record": None}


def record(kind, **row):
    row = {"kind": kind, "at": time.strftime("%Y-%m-%dT%H:%M:%S"), "load": round(os.getloadavg()[0], 1), **row}
    RUNS.mkdir(exist_ok=True)
    with RESULTS.open("a") as f:
        f.write(json.dumps(row) + "\n")
    if hooks["record"]:
        hooks["record"]("r-" + kind, **{k: v for k, v in row.items() if k != "kind"})
    print(json.dumps(row)[:1500], flush=True)


def stat(v):
    return K.stat(v)


# ---------- process facts ----------

def pids_in(d):
    """Processes whose working folder is d (a CRIU restore is not our child and not in our process group)."""
    d = str(pathlib.Path(d).resolve())
    out = []
    for p in pathlib.Path("/proc").iterdir():
        if p.name.isdigit():
            try:
                if os.readlink(p / "cwd") == d:
                    out.append(int(p.name))
            except OSError:
                pass
    return out


def cpu_s(pid):
    try:
        f = pathlib.Path(f"/proc/{pid}/stat").read_text().rsplit(")", 1)[1].split()
        return (int(f[11]) + int(f[12])) / TCK
    except OSError:
        return None


def mem_mb(pid):
    out = {}
    try:
        for line in pathlib.Path(f"/proc/{pid}/smaps_rollup").read_text().splitlines():
            k, _, v = line.partition(":")
            if k in ("Rss", "Pss", "Shared_Clean", "Private_Dirty", "Private_Clean"):
                out[k.lower()] = round(int(v.split()[0]) / 1024)
    except OSError:
        pass
    return out


def mem_used_mb():
    m = {}
    for line in pathlib.Path("/proc/meminfo").read_text().splitlines():
        k, _, v = line.partition(":")
        m[k] = int(v.split()[0])
    return round((m["MemTotal"] - m["MemAvailable"]) / 1024)


def du_mb(p):
    return round(sum(f.stat().st_size for f in pathlib.Path(p).rglob("*") if f.is_file()) / 1e6, 1)


# ---------- images ----------

class Image:
    def __init__(self, name):
        self.name = name
        self.home = IMAGES / name
        self.dir = self.home / "img"
        self.srv = self.home / "srv"
        self.meta = json.loads((self.home / "meta.json").read_text()) if (self.home / "meta.json").exists() else {}

    @property
    def point(self):
        return self.meta["point"]

    @property
    def engine(self):
        return self.meta["engine"]


class RPaper(K.KPaper):
    """K's killable Paper with the step agent; start() restores when an image is given, else boots."""

    def __init__(self, run_dir, img=None, cds=True):
        super().__init__(run_dir, cds=cds)
        self.jvm += COMMON
        self.img = img
        if img and img.point == "done":
            # Ports and folder are baked into a done image: the restore runs in the image's own folder.
            self.dir = img.srv
            self.port, self.control, self.line = img.meta["port"], img.meta["control"], img.meta["line"]
        elif img and img.point == "data":
            # server.properties is read before the data point: the restored Paper listens on the image's port.
            self.port = img.meta["port"]

    def start(self):
        if self.img is None:
            return super().start()
        if self.img.point != "done":
            self.setup()
        cmd = ["java", f"-XX:CRaCRestoreFrom={self.img.dir}", f"-XX:CRaCEngine={self.img.engine}", *self.img.meta.get("restore_opts", []),
               "probe.agent.Restored", f"-D{MARKER}=1"]
        if self.img.point != "done":
            cmd += [f"dir={self.dir.resolve()}", f"-Dprobe.line.port={self.line}", f"-Dprobe.control.port={self.control}"]
        self.proc = Proc(cmd, self.dir, self.dir / "server.log")
        return self

    def wait_done(self, timeout=240):
        try:
            return self._wait_done(timeout)
        except Exception as e:
            keep = RUNS / f"fail-{self.dir.name}-{int(time.time())}.log"
            try:
                keep.write_text(pathlib.Path(self.proc.log_path).read_text(errors="replace")[-40000:])
                for f in sorted(self.img.dir.glob("*.log"))[-3:] if self.img else []:
                    keep.with_suffix("." + f.name).write_text(f.read_text(errors="replace")[-40000:])
            except Exception:
                pass
            raise RuntimeError(f"{e}; log kept at {keep}") from e

    def restored_s(self):
        """Spawn to the restored JVM's first line (the engine's restore alone)."""
        text = pathlib.Path(self.proc.log_path).read_text(errors="replace")
        m = re.findall(r"\[crac\] restored at \w+ wall=(\d+)", text)
        return round(int(m[-1]) / 1000 - self.proc.spawn_micros / 1e6, 3) if m else None

    def _wait_done(self, timeout):
        if not self.img or self.img.point != "done":
            return super().wait_done(timeout)
        # A done image printed Done before the checkpoint: ready is the plugin answering a tick dispatched call.
        deadline = time.time() + timeout
        while time.time() < deadline:
            if not self.proc.alive() and not pids_in(self.dir):
                raise RuntimeError("restore exited, see " + str(self.proc.log_path))
            try:
                S = Line(self.line, prefix="tick/")
                S("k.files")
                self.done_seconds = (now_micros() - self.proc.spawn_micros) / 1e6
                return self.done_seconds
            except Exception:
                time.sleep(0.05)
        raise RuntimeError("restore never answered")

    def pids(self):
        pids = set(pids_in(self.dir))
        if self.proc and self.proc.alive():
            pids.add(self.proc.p.pid)
        return sorted(pids)

    def facts(self):
        pids = self.pids()
        return {"cpu_s": round(sum(cpu_s(p) or 0 for p in pids), 2), **(mem_mb(pids[0]) if pids else {}), "pids": len(pids)}

    def kill(self):
        t0 = time.time()
        for p in self.pids():
            try:
                os.kill(p, signal.SIGKILL)
            except OSError:
                pass
        try:
            os.killpg(self.proc.p.pid, signal.SIGKILL)
        except OSError:
            pass
        self.proc.p.wait(30)
        while self.pids():
            time.sleep(0.02)
        self.proc.log.close()
        if self.proc in R.live:
            R.live.remove(self.proc)
        return round(time.time() - t0, 3)

    def stop(self):
        if self.img:
            self.kill()  # a restored Paper is thrown away; no clean stop is needed
        else:
            super().stop()


def log_facts(path):
    text = pathlib.Path(path).read_text(errors="replace") if pathlib.Path(path).exists() else ""
    out = {"refused": [l.split("refused: ", 1)[1][:300] for l in text.splitlines() if "[crac]   refused: " in l],
           "failed": next((l.split("checkpoint failed: ", 1)[1][:300] for l in text.splitlines() if "checkpoint failed: " in l), None),
           "cwd": [l.split("[crac] ", 1)[1][:600] for l in text.splitlines() if "[crac] cwd" in l or "[crac] moved" in l],
           "errors": [l[:300] for l in text.splitlines() if ("Error" in l or "error" in l or "Exception" in l) and "crac" in l.lower()][:12]}
    m = re.search(r"\[crac\] checkpoint at \w+ wall=(\d+)", text)
    out["checkpoint_wall_ms"] = int(m.group(1)) if m else None
    return out


def cmd_image(a):
    name = a.name or f"{a.point}-{a.engine}-{a.policy}" + ("-" + a.opts.replace("=", "").replace(",", "-") if a.opts else "") + ("-warm" if a.warm else "")
    img = Image(name)
    shutil.rmtree(img.home, ignore_errors=True)
    img.home.mkdir(parents=True)
    p = RPaper(img.srv)
    # The JVM itself keeps the class path jars open (native descriptors, not covered by policies) and JNA's libffi
    # keeps a deleted temp file for closures.
    allowed = [str((ROOT / "cache/patched").resolve()), str(AGENT.parent.resolve())] + (["/tmp/ffi"] if a.allow_ffi else [])
    if a.warm:
        p.jvm.append("-Dprobe.crac.warm=true")
    p.jvm += [f"-XX:CRaCCheckpointTo={img.dir}", f"-XX:CRaCEngine={a.engine}", "-XX:+CRaCPrintResourcesOnCheckpoint",
              f"-XX:CRaCAllowedOpenFilePrefixes={','.join(allowed)}",
              "-Djdk.crac.collect-fd-stacktraces=true", "-Dprobe.crac.haltOnFail=true"]
    if a.opts:
        p.jvm.append(f"-XX:CRaCEngineOptions={a.opts}")
    if POLICIES[a.policy]:
        pol = img.home / "policy.yml"
        pol.write_text(POLICIES[a.policy])
        p.jvm.append(f"-Djdk.crac.resource-policies={pol}")
    if a.point != "done":
        p.jvm.append(f"-Dprobe.crac.at={a.point}")
    if a.point == "done":
        # Native epoll descriptors are not the JDK's; Netty's NIO transport keeps every socket a JDK socket.
        setup = p.setup

        def setup_nio():
            setup()
            props = p.dir / "server.properties"
            props.write_text(props.read_text() + "use-native-transport=false\n")
        p.setup = setup_nio
    ru0 = resource.getrusage(resource.RUSAGE_CHILDREN)
    t0 = time.time()
    p.start()
    row = {"name": name, "point": a.point, "engine": a.engine, "policy": a.policy, "opts": a.opts}
    try:
        if a.point == "done":
            p.wait_done()
            row["done_s"] = round(time.time() - t0, 3)
            time.sleep(1.0)
            S = Line(p.line, prefix="tick/")
            S("k.checkpoint")
            S.s.close()
        code = p.proc.p.wait(300)
    except Exception as e:
        row["error"] = str(e)[:300]
        code = None
        p.kill()
    ru1 = resource.getrusage(resource.RUSAGE_CHILDREN)
    row["exit"] = code
    row["wall_s"] = round(time.time() - t0, 3)
    row["cpu_s"] = round((ru1.ru_utime - ru0.ru_utime) + (ru1.ru_stime - ru0.ru_stime), 2)
    row["maxrss_mb"] = round(ru1.ru_maxrss / 1024)
    f = log_facts(p.dir / "server.log")
    row.update(f)
    if f["checkpoint_wall_ms"]:
        row["to_point_s"] = round(f["checkpoint_wall_ms"] / 1000 - p.proc.spawn_micros / 1e6, 3)
        row["write_s"] = round(row["wall_s"] - row["to_point_s"], 3)
    row["image_mb"] = du_mb(img.dir) if img.dir.exists() else None
    row["image_files"] = sorted(f.name for f in img.dir.iterdir())[:30] if img.dir.exists() else []
    row["ok"] = bool(row["image_mb"]) and not f["failed"] and "error" not in row
    restore_opts = [f"-XX:CRaCEngineOptions={a.restore_opts}"] if a.restore_opts else []
    (img.home / "meta.json").write_text(json.dumps({"point": a.point, "engine": a.engine, "policy": a.policy, "port": p.port,
                                                     "control": p.control, "line": p.line, "ok": row["ok"], "restore_opts": restore_opts}))
    log = (p.dir / "server.log").read_text(errors="replace")
    (RUNS / f"image-{name}.log").write_text(log[-60000:])
    record("image", **row)
    return row


# ---------- boot against restore ----------

def one_start(paper):
    t0 = time.time()
    paper.start()
    paper.wait_done()
    wall = round(time.time() - t0, 3)
    f = paper.facts()
    return {"wall_s": wall, "restored_s": paper.restored_s() if paper.img else None, **f}


def cmd_compare(a):
    img = Image(a.image)
    run = RUNS / f"r-compare-{int(time.time())}"
    rows = {"boot": [], "restore": []}
    try:
        for i in range(a.n):
            for kind in (("boot", "restore") if i % 2 == 0 else ("restore", "boot")):
                p = RPaper(run / f"{kind}{i}", img=img if kind == "restore" else None)
                # First start makes the world; the measured start is the restart into the same folder.
                one_start(p)
                p.kill()
                r = one_start(p)
                r["log"] = log_facts(p.dir / "server.log")["cwd"][-1:] if kind == "restore" else None
                p.kill()
                rows[kind].append(r)
                print(kind, json.dumps(r)[:400], flush=True)
    finally:
        stop_all()
        shutil.rmtree(run, ignore_errors=True)
    out = {"image": a.image, "point": img.point, "engine": img.engine}
    for kind, rs in rows.items():
        out[kind] = {m: stat([r.get(m) for r in rs]) for m in ("wall_s", "restored_s", "cpu_s", "rss", "pss", "private_dirty")}
    out["rows"] = rows
    record("compare", **out)


def cmd_parallel(a):
    img = Image(a.image)
    run = RUNS / f"r-par-{int(time.time())}"
    try:
        for kind in a.kinds.split(","):
            ps = [RPaper(run / f"{kind}{i}", img=img if kind == "restore" else None) for i in range(a.k)]
            for p in ps:
                p.setup()
            base = mem_used_mb()
            t0 = time.time()
            for p in ps:
                p.start()
            walls = []
            for p in ps:
                p.wait_done()
                walls.append(round(time.time() - t0, 3))
            all_s = round(time.time() - t0, 3)
            facts = [p.facts() for p in ps]
            used = mem_used_mb() - base
            for p in ps:
                p.kill()
            record("parallel", image=a.image, what=kind, k=a.k, all_done_s=all_s, each_done_s=walls,
                   cpu_s=[f["cpu_s"] for f in facts], rss=[f.get("rss") for f in facts], pss=[f.get("pss") for f in facts], mem_used_mb=used)
    finally:
        stop_all()
        shutil.rmtree(run, ignore_errors=True)


# ---------- restart scenes ----------

def trial(rig, scene, broken, i, after):
    """K's trial with a fourth scene: a value in the overworld's level data, saved (good) or not (broken)."""
    c = rig.clients[0]
    S = rig.paper.S
    K.scene_cfg(rig, scene if scene != "world" else "reward", False if scene == "world" else broken)
    S("k.wipe", player=c.name, scope="full")
    c.C("clearChat")
    tok = f"{scene[0]}{i}x{__import__('random').randrange(10**5)}"
    uuid = c.C("k.user", name=c.name)["uuid"]
    before = None
    if scene == "grace":
        assert c.reconnect(rig.paper.addr, K.NEED["chunks"])["ok"]
    elif scene == "reward":
        S("k.owe", player=c.name, tok=tok)
        c.barrier(S)
    elif scene == "world":
        S("k.wset", player=c.name, tok=tok, save=int(not broken))
    elif scene == "mail":
        def before():
            mail = rig.paper.dir / "plugins/Probe/k/mail" / f"{uuid}.txt"
            mail.parent.mkdir(parents=True, exist_ok=True)
            mail.write_text(tok + "\n")
    t = K.restart(rig, "K1", c, before)
    t["facts"] = rig.paper.facts()
    t["restored_s"] = rig.paper.restored_s() if rig.paper.img else None
    S = rig.paper.S
    c.barrier(S)
    lines = K.chat_lines(c)
    out = {"scene": scene, "broken": broken, **t}
    if scene == "grace":
        j = [l for l in lines if l.startswith(f"KJOIN {c.name} ")]
        out["join_line"] = j[0] if j else None
        passed = bool(j) and "resumed=0" in j[0]
    elif scene == "reward":
        inv = c.C("k.inv", name="R" + tok)
        out["count"] = inv["count"]
        passed = inv["count"] == 1
    elif scene == "world":
        got = S("k.wget", player=c.name)["tok"]
        out["got"] = got
        passed = got == tok
    else:
        first = sum(1 for l in lines if l == f"KMAIL {tok}")
        assert c.reconnect(rig.paper.addr, K.NEED["chunks"])["ok"]
        c.barrier(S)
        second = sum(1 for l in K.chat_lines(c) if l == f"KMAIL {tok}")
        out["mail"] = [first, second]
        passed = first == 1 and second == 0
    out["passed"] = passed
    out["wrong"] = passed == broken
    wrong_after, after_s = 0, []
    for j in range(after):
        token = f"KA{i}x{j}r{__import__('random').randrange(10**5)}"
        a0 = time.time()
        S("act", player=c.name, kind="chat", token=token)
        seen = c.C("observe", needle=needle_for("chat", token, "STONE"), timeoutMs=3000)
        after_s.append(time.time() - a0)
        if not seen.get("ok"):
            wrong_after += 1
    out["after_wrong"] = wrong_after
    return out


def cmd_scenes(a):
    img = None if a.image == "boot" else Image(a.image)
    scenes = a.scenes.split(",")
    rig = K.Rig(f"r-{a.image}", clients=1, gate=2)
    rig.paper = RPaper(rig.run / "server-a", img=img)
    for c in rig.clients:
        c.paper = rig.paper
    rows = []
    with rig:
        rig.paper.S("tickrate", rate=20)
        for i in range(a.n):
            for scene in scenes:
                for broken in (False, True):
                    rows.append(trial(rig, scene, broken, i, a.after))
                    print(json.dumps(rows[-1])[:500], flush=True)
    by = {}
    for r in rows:
        by.setdefault(f"{r['scene']}-{'broken' if r['broken'] else 'good'}", []).append(r)
    record("scenes", image=a.image, point=img.point if img else "boot-plain", engine=img.engine if img else None,
           ready_s=stat([r["ready_s"] for r in rows]), done_s=stat([r["done_s"] for r in rows]), level_s=stat([r["level_s"] for r in rows]),
           chunks_s=stat([r.get("chunks_s") for r in rows]), restored_s=stat([r.get("restored_s") for r in rows]), stop_s=stat([r["stop_s"] for r in rows]),
           cpu_s=stat([r["facts"]["cpu_s"] for r in rows]), rss=stat([r["facts"].get("rss") for r in rows]),
           wrong=sum(r["wrong"] for r in rows), trials=len(rows), after_wrong=sum(r["after_wrong"] for r in rows),
           wrong_by={k: f"{sum(r['wrong'] for r in v)}/{len(v)}" for k, v in sorted(by.items())},
           rows=[{k: v for k, v in r.items() if k != "facts"} for r in rows])


def cmd_prep(a):
    """AppCDS archive with the same flags (agent, opens, log config) the boot and the image use."""
    K.AOT.mkdir(parents=True, exist_ok=True)
    K.JSA.unlink(missing_ok=True)
    run = RUNS / f"r-prep-{int(time.time())}"
    s = RPaper(run / "s", cds=False)
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
    i = sub.add_parser("image")
    i.add_argument("--point", choices=["boot", "data", "done"], required=True)
    i.add_argument("--engine", default="warp")
    i.add_argument("--policy", default="none", choices=list(POLICIES))
    i.add_argument("--opts", default="")
    i.add_argument("--restore-opts", default="")
    i.add_argument("--name", default="")
    i.add_argument("--warm", type=int, default=0)
    i.add_argument("--allow-ffi", type=int, default=1)
    c = sub.add_parser("compare")
    c.add_argument("--image", required=True)
    c.add_argument("--n", type=int, default=5)
    p = sub.add_parser("parallel")
    p.add_argument("--image", required=True)
    p.add_argument("--k", type=int, default=4)
    p.add_argument("--kinds", default="restore,boot")
    s = sub.add_parser("scenes")
    s.add_argument("--image", required=True)
    s.add_argument("--n", type=int, default=3)
    s.add_argument("--scenes", default="grace,reward,mail,world")
    s.add_argument("--after", type=int, default=3)
    a = ap.parse_args(argv)
    try:
        return {"prep": cmd_prep, "image": cmd_image, "compare": cmd_compare, "parallel": cmd_parallel, "scenes": cmd_scenes}[a.cmd](a)
    finally:
        stop_all()


if __name__ == "__main__":
    main()
