#!/usr/bin/env python3
"""Spike C4: lowest Paper boot and client start on Java 25.

  c4.py paper [--repeat 3]    boot variants, wall seconds to Done
  c4.py client [--repeat 3]   client to title screen and to in world, with and without an AOT cache
"""
import argparse, json, os, pathlib, shutil, statistics, subprocess, sys, time, zipfile

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import run as R
from run import Paper, Client, Proc, RUNS, CACHE, PAPER_JAR, PATCHED, MARKER, free_port, leak_check, stop_all, now_micros
from speed import TunedPaper, RESULTS

AOT = CACHE / "aot"
FAST_JVM = ["-XX:TieredStopAtLevel=1", "-XX:+UseSerialGC", "-XX:-UsePerfData", "-Xss512k"]


def classpath():
    z = zipfile.ZipFile(PAPER_JAR)
    libs = [l.split("\t")[2] for l in z.read("META-INF/libraries.list").decode().splitlines() if l.strip()]
    vers = [l.split("\t")[2] for l in z.read("META-INF/versions.list").decode().splitlines() if l.strip()]
    return ":".join([str(PATCHED / "versions" / v) for v in vers] + [str(PATCHED / "libraries" / l) for l in libs])


class Variant(TunedPaper):
    def __init__(self, *a, direct=False, trim=False, jvm=(), **k):
        super().__init__(*a, **k)
        self.direct, self.trim, self.jvm = direct, trim, list(jvm)

    def setup(self):
        super().setup()
        if self.trim:
            props = self.dir / "server.properties"
            props.write_text(props.read_text() + "allow-nether=false\n")
            (self.dir / "bukkit.yml").write_text("settings:\n  allow-end: false\n")
            cfg = self.dir / "config" / "paper-global.yml"
            text = cfg.read_text()
            head, tail = text.split("spark:\n", 1)
            cfg.write_text(head + "spark:\n" + tail.replace("enabled: true", "enabled: false", 1))

    def start(self):
        self.setup()
        launch = ["-cp", classpath(), "org.bukkit.craftbukkit.Main"] if self.direct else ["-jar", str(PAPER_JAR)]
        cmd = ["java", f"-D{MARKER}=1", f"-Xmx{self.xmx}", f"-Dprobe.control.port={self.control}", "-Dprobe.maxRuntimeSec=300", *self.jvm, *launch, "--nogui"]
        self.proc = Proc(cmd, self.dir, self.dir / "server.log")
        return self

    def stop_slow(self, wait=240):
        """Clean stop that leaves time for the JVM to write its AOT cache at exit."""
        try:
            self.cmd("stop")
            self.proc.p.wait(wait)
        except Exception as e:
            print("stop:", e, file=sys.stderr)
        self.proc.stop()


def boot_series(name, repeat, fresh=False, train=None, **kwargs):
    """Boots repeat times in one dir, so the world exists from the second boot on; fresh=True new dir each."""
    run = RUNS / f"c4-{name}-{int(time.time())}"
    times, reported, rss = [], [], []
    try:
        if train:
            s = Variant(run / "train", jvm=kwargs.get("jvm", []) + [f"-XX:AOTCacheOutput={train}"], **{k: v for k, v in kwargs.items() if k != "jvm"})
            s.start()
            s.wait_done()
            t = time.time()
            s.stop_slow()
            print(name, "training exit seconds", round(time.time() - t, 1), "cache MB", round(pathlib.Path(train).stat().st_size / 1e6) if pathlib.Path(train).exists() else None, flush=True)
            if not pathlib.Path(train).exists():
                print((run / "train/server.log").read_text(errors="replace")[-1500:], flush=True)
                return {"name": name, "error": "no cache"}
            kwargs["jvm"] = kwargs.get("jvm", []) + [f"-XX:AOTCache={train}"]
        for i in range(repeat + (0 if fresh else 1)):
            d = run / (f"s{i}" if fresh else "s")
            s = Variant(d, **kwargs)
            s.port, s.control = free_port(), free_port()
            s.start()
            try:
                done = s.wait_done()
                if fresh or i > 0:
                    times.append(round(done, 2))
                    reported.append(s.reported)
                    rss.append(R.rss_mb(s.proc.p.pid))
            finally:
                s.stop()
        log = (d / "server.log").read_text(errors="replace")
        warn = [l[:200] for l in log.splitlines() if "AOT" in l or "CDS" in l or "aot" in l.split("]")[0]][:3]
    finally:
        stop_all()
        shutil.rmtree(run, ignore_errors=True)
    out = {"name": name, "wall_to_done_s": times, "median": statistics.median(times), "paper_reported": reported, "rss_mb": rss, "load": round(os.getloadavg()[0], 1), "warnings": warn}
    print(json.dumps(out), flush=True)
    RESULTS.open("a").write(json.dumps({"label": "c4-paper", **out}) + "\n")
    return out


def cmd_paper(a):
    AOT.mkdir(parents=True, exist_ok=True)
    tiny = {"xmx": "512m", "world": "void"}
    boot_series("A jar, stock settings, existing world", a.repeat, tuned=False, **tiny)
    boot_series("B jar, tuned", a.repeat, **tiny)
    boot_series("C direct classpath, tuned", a.repeat, direct=True, **tiny)
    boot_series("D direct, tuned, trimmed", a.repeat, direct=True, trim=True, **tiny)
    boot_series("E direct, trimmed, C1 only, SerialGC", a.repeat, direct=True, trim=True, jvm=list(FAST_JVM), **tiny)
    cache = AOT / "paper.aot"
    cache.unlink(missing_ok=True)
    boot_series("F direct, trimmed, AOT cache", a.repeat, direct=True, trim=True, train=str(cache), **tiny)
    cache2 = AOT / "paper-fast.aot"
    cache2.unlink(missing_ok=True)
    boot_series("G direct, trimmed, C1, SerialGC, AOT cache", a.repeat, direct=True, trim=True, jvm=list(FAST_JVM), train=str(cache2), **tiny)
    boot_series("H as G, new world every boot", a.repeat, fresh=True, direct=True, trim=True, jvm=list(FAST_JVM) + [f"-XX:AOTCache={cache2}"], **tiny)
    print(json.dumps({"leaks": leak_check()}))


def client_once(name, jvm, server=None):
    run = RUNS / f"c4-client-{int(time.time() * 10)}"
    c = Client(run / "client", server=server, backend="opengl", xmx="1g", rd=2, facts_mode="changes", extra_jvm=jvm)
    c.start()
    try:
        c.wait_event("screen:TitleScreen" if not server else "first_world_frame", 180)
        c.wait_event("load_finished", 60)
        c.wait_event("renderer", 10)
        r = c.events()["renderer"]
        assert r["master"] == 0.0 and r["music"] == 0.0, "client is not silent"
        t = R.client_timeline(c)
        return {k: t.get(k) for k in ("mod_init", "renderer", "screen:TitleScreen", "load_finished", "first_world_frame", "level_ready")}, c, run
    except Exception:
        c.stop()
        raise


def cmd_client(a):
    AOT.mkdir(parents=True, exist_ok=True)
    cache = AOT / "client.aot"
    cache.unlink(missing_ok=True)
    out = {"label": "c4-client", "load": round(os.getloadavg()[0], 1), "baseline": [], "aot": []}
    for i in range(a.repeat):
        t, c, run = client_once("base", [])
        c.stop()
        shutil.rmtree(run, ignore_errors=True)
        out["baseline"].append(t)
        print("base", t, flush=True)
    t, c, run = client_once("train", [f"-XX:AOTCacheOutput={cache}", "-Xlog:aot*=warning:file=" + str(AOT / "client-train.log")])
    c.stop_file.touch()
    t0 = time.time()
    try:
        c.proc.p.wait(240)
    except subprocess.TimeoutExpired:
        print("training client did not exit", flush=True)
    c.stop()
    out["train_exit_s"] = round(time.time() - t0, 1)
    out["cache_mb"] = round(cache.stat().st_size / 1e6) if cache.exists() else None
    log = (run / "client/client.log").read_text(errors="replace")
    out["train_log"] = [l[:220] for l in log.splitlines() if "AOT" in l or "aot" in l[:60] or "CDS" in l][:8]
    tl = AOT / "client-train.log"
    out["aot_log"] = tl.read_text(errors="replace").splitlines()[:8] if tl.exists() else None
    shutil.rmtree(run, ignore_errors=True)
    print(json.dumps({k: out.get(k) for k in ("train_exit_s", "cache_mb", "train_log", "aot_log")}), flush=True)
    if cache.exists():
        for i in range(a.repeat):
            t, c, run = client_once("aot", [f"-XX:AOTCache={cache}", "-Xlog:class+load:file=" + str(AOT / "client-classload.log")])
            c.stop()
            shutil.rmtree(run, ignore_errors=True)
            out["aot"].append(t)
            print("aot", t, flush=True)
        text = (AOT / "client-classload.log").read_text(errors="replace").splitlines()
        shared = sum(1 for l in text if "shared objects file" in l or "aot" in l.lower().split("source:")[-1])
        mc = [l for l in text if " net.minecraft." in l]
        out["classes"] = {"total": len(text), "from_cache": shared, "minecraft_total": len(mc), "minecraft_from_cache": sum(1 for l in mc if "shared objects file" in l)}
    out["leaks"] = leak_check()
    RESULTS.open("a").write(json.dumps(out) + "\n")
    print(json.dumps(out))


def jar_only_launch():
    """Client classpath without directories, because CDS and AOT refuse those. The mod comes from its jar."""
    launch = json.load(open(R.LAUNCH_JSON))
    launch["classpath"] = [c for c in launch["classpath"] if c.endswith(".jar")] + [str(R.ROOT / "probe-mod/build/libs/probe-mod-0.jar")]
    out = AOT / "client-launch-jars.json"
    out.write_text(json.dumps(launch))
    return out


def cmd_paper2(a):
    tiny = {"xmx": "512m", "world": "void", "direct": True, "trim": True}
    results = []
    conf = AOT / "paper.aot.config"
    cp = classpath()
    for name, extra in (("AOT create, no class linking", ["-XX:-AOTClassLinking"]), ("AOT create, SerialGC", ["-XX:+UseSerialGC"])):
        cache = AOT / ("p-" + name.split()[-1] + ".aot")
        t = time.time()
        r = subprocess.run(["java", "-Xmx512m", "-XX:AOTMode=create", f"-XX:AOTConfiguration={conf}", f"-XX:AOTCache={cache}", "-Xlog:aot=error", *extra, "-cp", cp], capture_output=True, text=True, timeout=280)
        size = cache.stat().st_size if cache.exists() else 0
        print(name, "rc", r.returncode, "seconds", round(time.time() - t, 1), "MB", round(size / 1e6), (r.stdout + r.stderr).splitlines()[-1:] , flush=True)
        if r.returncode == 0 and size > 0:
            results.append(boot_series("AOT " + name, a.repeat, jvm=[f"-XX:AOTCache={cache}", "-XX:AOTMode=on", *extra], **tiny))
    jsa = AOT / "paper.jsa"
    jsa.unlink(missing_ok=True)
    run = RUNS / f"c4-jsa-{int(time.time())}"
    s = Variant(run / "s", jvm=[f"-XX:ArchiveClassesAtExit={jsa}", "-Xlog:cds=error,aot=error"], **tiny)
    s.start()
    s.wait_done()
    s.stop_slow()
    shutil.rmtree(run, ignore_errors=True)
    print("dynamic AppCDS MB", round(jsa.stat().st_size / 1e6) if jsa.exists() else None, flush=True)
    if jsa.exists() and jsa.stat().st_size:
        boot_series("dynamic AppCDS, direct, trimmed", a.repeat, jvm=[f"-XX:SharedArchiveFile={jsa}"], **tiny)
        boot_series("dynamic AppCDS, trimmed, C1, SerialGC (archive from G1)", a.repeat, jvm=[f"-XX:SharedArchiveFile={jsa}", *FAST_JVM], **tiny)
    print(json.dumps({"leaks": leak_check()}))


def cmd_client2(a):
    orig = R.LAUNCH_JSON
    R.LAUNCH_JSON = jar_only_launch()
    out = {"label": "c4-client2", "load": round(os.getloadavg()[0], 1)}
    try:
        for label, train_flag, use in (("appcds", "-XX:ArchiveClassesAtExit={}", "-XX:SharedArchiveFile={}"), ("aot", "-XX:AOTCacheOutput={}", "-XX:AOTCache={}")):
            cache = AOT / f"client-{label}.bin"
            cache.unlink(missing_ok=True)
            base = []
            if label == "appcds":
                for i in range(a.repeat):
                    t, c, run = client_once("jars", [])
                    c.stop()
                    shutil.rmtree(run, ignore_errors=True)
                    base.append(t)
                out["jars_baseline"] = base
                print("jars baseline", base, flush=True)
            t, c, run = client_once("train", [train_flag.format(cache)])
            c.stop_file.touch()
            t0 = time.time()
            try:
                c.proc.p.wait(240)
            except subprocess.TimeoutExpired:
                print("training client did not exit", flush=True)
            exit_s = round(time.time() - t0, 1)
            log = (run / "client/client.log").read_text(errors="replace")
            c.stop()
            shutil.rmtree(run, ignore_errors=True)
            size = cache.stat().st_size if cache.exists() else 0
            print(label, "exit s", exit_s, "MB", round(size / 1e6), [l[:200] for l in log.splitlines() if "][error" in l][:4], flush=True)
            out[label + "_mb"] = round(size / 1e6)
            rows = []
            if size:
                cl = AOT / f"client-{label}-classload.log"
                for i in range(a.repeat):
                    t, c, run = client_once("use", [use.format(cache), f"-Xlog:class+load:file={cl}"])
                    c.stop()
                    shutil.rmtree(run, ignore_errors=True)
                    rows.append(t)
                text = cl.read_text(errors="replace").splitlines()
                mc = [l for l in text if " net.minecraft." in l or " com.mojang." in l]
                out[label + "_classes"] = {"total": len(text), "from_archive": sum(1 for l in text if "shared objects file" in l or "AOT" in l), "game_total": len(mc), "game_from_archive": sum(1 for l in mc if "shared objects file" in l or "AOT" in l)}
                cl.unlink(missing_ok=True)
            out[label] = rows
            print(label, rows, out.get(label + "_classes"), flush=True)
    finally:
        R.LAUNCH_JSON = orig
    out["leaks"] = leak_check()
    RESULTS.open("a").write(json.dumps(out) + "\n")
    print(json.dumps(out))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("what", choices=["paper", "client", "paper2", "client2"])
    ap.add_argument("--repeat", type=int, default=3)
    a = ap.parse_args()
    try:
        {"paper": cmd_paper, "client": cmd_client, "paper2": cmd_paper2, "client2": cmd_client2}[a.what](a)
    finally:
        stop_all()
        leak_check()


if __name__ == "__main__":
    main()
