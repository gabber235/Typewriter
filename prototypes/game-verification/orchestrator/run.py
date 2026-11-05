#!/usr/bin/env python3
"""Throwaway orchestrator for the game verification spikes.

  run.py prepare                                 download and patch Paper into cache/
  run.py boot --world void --mode fresh          one Paper boot, prints seconds to Done
  run.py menu                                    client with no server, time to title screen
  run.py scene --world void --rd 2 --xmx 2g      full scene, verified from facts
Every command stops what it started, also on failure, and checks with pgrep at the end.
"""
import argparse, atexit, json, os, pathlib, re, shutil, signal, socket, subprocess, sys, threading, time, urllib.parse, urllib.request

ROOT = pathlib.Path(__file__).resolve().parent.parent
CACHE = ROOT / "cache"
PAPER_JAR = CACHE / "paper-26.3-242.jar"
PATCHED = CACHE / "patched"
RUNS = ROOT / "runs"
PLUGIN_JAR = ROOT / "probe-plugin/build/libs/probe-plugin-0.jar"
LAUNCH_JSON = ROOT / "probe-mod/build/client-launch.json"
MARKER = "probe.gv.run"  # every JVM carries -Dprobe.gv.run=1 so the leak check can find it

live = []


def now_micros():
    return time.time_ns() // 1000


def free_port():
    with socket.socket() as s:
        s.bind(("127.0.0.1", 0))
        return s.getsockname()[1]


def tree_pids(root):
    out = subprocess.run(["ps", "-A", "-o", "pid=,ppid="], capture_output=True, text=True).stdout
    children = {}
    for line in out.splitlines():
        pid, ppid = map(int, line.split())
        children.setdefault(ppid, []).append(pid)
    seen, todo = [], [root]
    while todo:
        p = todo.pop()
        seen.append(p)
        todo.extend(children.get(p, []))
    return seen


def rss_mb(root):
    pids = tree_pids(root)
    out = subprocess.run(["ps", "-o", "rss=", "-p", ",".join(map(str, pids))], capture_output=True, text=True).stdout
    return round(sum(int(x) for x in out.split()) / 1024)


def footprint_mb(pid):
    """Physical footprint as Activity Monitor shows it; includes GPU memory attributed to the process."""
    out = subprocess.run(["top", "-l", "1", "-pid", str(pid), "-stats", "mem"], capture_output=True, text=True).stdout
    m = re.findall(r"^(\d+(?:\.\d+)?)([KMG])\+?-?\s*$", out, re.M)
    if not m:
        return None
    value, unit = m[-1]
    return round(float(value) * {"K": 1 / 1024, "M": 1, "G": 1024}[unit])


def front_app():
    try:
        asn = subprocess.run(["lsappinfo", "front"], capture_output=True, text=True, timeout=3).stdout.strip()
        info = subprocess.run(["lsappinfo", "info", asn], capture_output=True, text=True, timeout=3).stdout
        m = re.search(r'"([^"]+)"', info)
        return m[1] if m else info[:40]
    except Exception as e:
        return "?" + str(e)


class Proc:
    def __init__(self, cmd, cwd, log, env=None):
        self.log_path = log
        self.log = open(log, "wb")
        self.spawn_micros = now_micros()
        full_env = dict(os.environ)
        if env:
            full_env.update(env)
        self.p = subprocess.Popen(cmd, cwd=cwd, stdout=self.log, stderr=subprocess.STDOUT, start_new_session=True, env=full_env)
        live.append(self)

    def alive(self):
        return self.p.poll() is None

    def stop(self, grace=20):
        if self.alive():
            try:
                os.killpg(self.p.pid, signal.SIGTERM)
            except ProcessLookupError:
                pass
            try:
                self.p.wait(grace)
            except subprocess.TimeoutExpired:
                try:
                    os.killpg(self.p.pid, signal.SIGKILL)
                except ProcessLookupError:
                    pass
                self.p.wait(10)
        self.log.close()
        if self in live:
            live.remove(self)


def stop_all(*_):
    for p in list(live):
        p.stop(grace=5)


atexit.register(stop_all)
signal.signal(signal.SIGTERM, lambda *a: sys.exit(143))


def leak_check():
    out = subprocess.run(["pgrep", "-fl", MARKER], capture_output=True, text=True).stdout.strip()
    lines = [l[:160] for l in out.splitlines() if "pgrep" not in l and "run.py" not in l]
    if lines:
        print("LEAKED PROCESSES:", lines, file=sys.stderr)
    return lines


# ---------- Paper ----------

VOID_GEN = '{"layers":[{"block":"minecraft:air","height":1}],"biome":"minecraft:the_void"}'
FLAT_GEN = '{"layers":[{"block":"minecraft:bedrock","height":1},{"block":"minecraft:stone","height":2}],"biome":"minecraft:plains"}'


def prepare():
    CACHE.mkdir(exist_ok=True)
    if not PAPER_JAR.exists():
        url = json.load(urllib.request.urlopen("https://fill.papermc.io/v3/projects/paper/versions/26.3/builds/242"))["downloads"]["server:default"]["url"]
        urllib.request.urlretrieve(url, PAPER_JAR)
    if not (PATCHED / "versions").exists():
        PATCHED.mkdir(exist_ok=True)
        subprocess.check_call(["java", "-Dpaperclip.patchonly=true", "-jar", str(PAPER_JAR)], cwd=PATCHED)


class Paper:
    def __init__(self, run_dir, world="void", xmx="1g", patched=True, extra_jvm=()):
        self.dir = pathlib.Path(run_dir)
        self.world = world
        self.xmx = xmx
        self.patched = patched
        self.extra_jvm = list(extra_jvm)
        self.port = free_port()
        self.control = free_port()
        self.proc = None
        self.done_seconds = None

    def setup(self):
        d = self.dir
        d.mkdir(parents=True, exist_ok=True)
        if self.patched:
            for name in ("versions", "libraries", "cache"):
                link = d / name
                if not link.exists():
                    link.symlink_to(PATCHED / name)
        (d / "plugins").mkdir(exist_ok=True)
        if PLUGIN_JAR.exists():
            shutil.copy(PLUGIN_JAR, d / "plugins/probe-plugin.jar")
        (d / "eula.txt").write_text("eula=true\n")  # throwaway dir, the developer asked for servers here
        props = [
            "online-mode=false", f"server-port={self.port}", "server-ip=127.0.0.1", "enforce-secure-profile=false",
            "white-list=false", "enforce-whitelist=false", "spawn-protection=0", "view-distance=8", "simulation-distance=4", "motd=probe", "max-players=8", "enable-query=false",
            "enable-rcon=false", "difficulty=peaceful", "spawn-monsters=false", "gamemode=creative", "pause-when-empty-seconds=-1",
        ]
        if self.world == "void":
            props += ["level-type=minecraft\\:flat", f"generator-settings={VOID_GEN}", "generate-structures=false"]
        elif self.world == "flat":
            props += ["level-type=minecraft\\:flat", f"generator-settings={FLAT_GEN}", "generate-structures=false"]
        (d / "server.properties").write_text("\n".join(props) + "\n")

    def start(self):
        self.setup()
        cmd = ["java", f"-D{MARKER}=1", f"-Xmx{self.xmx}", f"-Dprobe.control.port={self.control}", "-Dprobe.maxRuntimeSec=900",
               *self.extra_jvm, "-jar", str(PAPER_JAR), "--nogui"]
        self.proc = Proc(cmd, self.dir, self.dir / "server.log")
        return self

    def wait_done(self, timeout=240):
        deadline = time.time() + timeout
        pat = re.compile(rb'Done \((\d+[.,]\d+)s\)!')
        while time.time() < deadline:
            data = pathlib.Path(self.proc.log_path).read_bytes()
            m = pat.search(data)
            if m:
                self.done_seconds = (now_micros() - self.proc.spawn_micros) / 1e6
                self.reported = float(m.group(1).replace(b",", b"."))
                return self.done_seconds
            if not self.proc.alive():
                raise RuntimeError("Paper exited before Done, see " + str(self.proc.log_path))
            time.sleep(0.05)
        raise RuntimeError("Paper did not reach Done")

    def cmd(self, name, **params):
        q = urllib.parse.urlencode(params)
        with urllib.request.urlopen(f"http://127.0.0.1:{self.control}/cmd/{name}?{q}", timeout=40) as r:
            return json.load(r)

    def status(self):
        with urllib.request.urlopen(f"http://127.0.0.1:{self.control}/status", timeout=40) as r:
            return json.load(r)

    def stop(self):
        if self.proc is None:
            return
        try:
            if self.proc.alive():
                self.cmd("stop")
                self.proc.p.wait(30)
        except Exception as e:
            print("server stop fell back to signal:", e, file=sys.stderr)
        self.proc.stop()


# ---------- Client ----------

def options_txt(rd, sim=5, width=854, height=480):
    lines = {
        "version": 5023,
        "soundCategory_master": 0.0, "soundCategory_music": 0.0, "soundCategory_record": 0.0, "soundCategory_weather": 0.0,
        "soundCategory_block": 0.0, "soundCategory_hostile": 0.0, "soundCategory_neutral": 0.0, "soundCategory_player": 0.0,
        "soundCategory_ambient": 0.0, "soundCategory_voice": 0.0, "soundCategory_ui": 0.0,
        "pauseOnLostFocus": "false", "inactivityFpsLimit": '"minimized"',
        "maxFps": 260, "enableVsync": "false",
        "graphicsPreset": '"custom"', "ao": "false", "renderClouds": '"false"', "entityShadows": "false", "particles": 2,
        "biomeBlendRadius": 0, "mipmapLevels": 0, "improvedTransparency": "false", "cutoutLeaves": "false",
        "chunkSectionFadeInTime": 0.0, "menuBackgroundBlurriness": 0,
        "renderDistance": rd, "simulationDistance": sim,
        "fullscreen": "false", "overrideWidth": width, "overrideHeight": height, "guiScale": 2,
        "tutorialStep": "none", "narrator": 0, "narratorHotkey": "false", "onboardAccessibility": "false",
        "skipMultiplayerWarning": "true", "joinedFirstServer": "true", "realmsNotifications": "false", "hideSplashTexts": "true",
    }
    return "".join(f"{k}:{v}\n" for k, v in lines.items())


class Client:
    def __init__(self, game_dir, name="probe1", server=None, backend=None, xmx="2g", rd=2, facts_mode="all", launcher="direct",
                 watch="", window_flags="0", window_clear="0", background_app=True, extra_jvm=(), env=None, width=854, height=480):
        self.dir = pathlib.Path(game_dir)
        self.name = name
        self.server = server
        self.backend = backend
        self.xmx = xmx
        self.rd = rd
        self.facts_mode = facts_mode
        self.launcher = launcher
        self.watch = watch
        self.window_flags = window_flags
        self.window_clear = window_clear
        self.background_app = background_app
        self.extra_jvm = list(extra_jvm)
        self.env = env or {}
        self.width, self.height = width, height
        self.facts = self.dir / f"facts-{name}.jsonl"
        self.stop_file = self.dir / "probe.stop"
        self.proc = None

    def start(self):
        d = self.dir
        d.mkdir(parents=True, exist_ok=True)
        sets = options_txt(self.rd, width=self.width, height=self.height)
        (d / "options.txt").write_text(sets)
        assert "soundCategory_master:0.0" in sets and "soundCategory_music:0.0" in sets  # never make noise on this machine
        props = [f"-D{MARKER}=1", f"-Xmx{self.xmx}", f"-Dprobe.facts={self.facts}", f"-Dprobe.factsMode={self.facts_mode}",
                 f"-Dprobe.watchBlocks={self.watch}", f"-Dprobe.stopFile={self.stop_file}", "-Dprobe.maxRuntimeSec=600",
                 f"-Dprobe.windowFlags={self.window_flags}", f"-Dprobe.windowFlagsClear={self.window_clear}", f"-Xlog:gc:file={self.dir}/gc.log", *self.extra_jvm]
        args = ["--username", self.name, "--offlineDeveloperMode", "--gameDir", str(d), "--width", str(self.width), "--height", str(self.height)]
        if self.backend:
            args += ["--graphicsBackend", self.backend]
        if self.server:
            args += ["--quickPlayMultiplayer", self.server]
        env = dict(self.env)
        if self.background_app:
            env["SDL_MAC_BACKGROUND_APP"] = "1"
        if self.launcher == "direct":
            launch = json.load(open(LAUNCH_JSON))
            jvm = [a for a in launch["jvmArgs"] if not a.startswith("@")]
            cmd = ["java", *jvm, *props, "-cp", ":".join(launch["classpath"]), launch["main"], *args]
            self.proc = Proc(cmd, d, d / "client.log", env=env)
        else:
            env["PROBE_JVM_ARGS"] = " ".join(props)
            env["PROBE_CLIENT_ARGS"] = " ".join(args)
            cmd = ["cargo", "xtask", "heavy", "--", "bash", "-c",
                   "cd prototypes/game-verification && ./gradlew --console=plain :probe-mod:runClient"]
            self.proc = Proc(cmd, ROOT.parent.parent, d / "client.log", env=env)
        return self

    def java_pid(self):
        """The JVM that actually runs the game (differs from the spawned process under Gradle)."""
        out = subprocess.run(["pgrep", "-f", f"probe.facts={self.facts}"], capture_output=True, text=True).stdout.split()
        return int(out[0]) if out else None

    def events(self):
        out = {}
        if not self.facts.exists():
            return out
        with open(self.facts) as f:
            for line in f:
                if line.startswith('{"k":"e"'):
                    try:
                        e = json.loads(line)
                    except json.JSONDecodeError:
                        continue
                    out.setdefault(e["name"], e)
                    if e["name"] == "screen":
                        out.setdefault("screen:" + e["screen"], e)
        return out

    def wait_event(self, name, timeout=180):
        deadline = time.time() + timeout
        while time.time() < deadline:
            events = self.events()
            e = events.get(name)
            if e:
                return e
            if '"DisconnectedScreen"' in pathlib.Path(self.facts).read_text(errors="replace") if self.facts.exists() else False:
                raise RuntimeError(f"client was disconnected before {name}, see {self.proc.log_path}")
            if not self.proc.alive():
                raise RuntimeError(f"client exited before {name}, see {self.proc.log_path}")
            time.sleep(0.1)
        raise RuntimeError(f"client never reached {name}, see {self.proc.log_path}")

    def stop(self):
        if self.proc is None:
            return
        self.stop_file.touch()
        try:
            self.proc.p.wait(20)
        except subprocess.TimeoutExpired:
            print("client did not stop from stop file, signalling", file=sys.stderr)
        self.proc.stop()
        pid = self.java_pid()
        if pid:
            os.kill(pid, signal.SIGKILL)


class FactReader:
    """Follows the facts file and answers: first fact whose raw line contains a needle."""

    def __init__(self, path):
        self.path = pathlib.Path(path)
        self.lines = []
        self.pos = 0
        self.tail = b""

    def poll(self):
        if not self.path.exists():
            return
        with open(self.path, "rb") as f:
            f.seek(self.pos)
            data = f.read()
            self.pos = f.tell()
        data = self.tail + data
        parts = data.split(b"\n")
        self.tail = parts.pop()
        self.lines.extend(parts)

    def first(self, needle, start=0):
        n = needle.encode()
        for i in range(start, len(self.lines)):
            line = self.lines[i]
            if n in line and not line.startswith(b'{"k":"e"'):
                return i, json.loads(line)
        return None, None

    def wait(self, needle, timeout=10, start=0):
        deadline = time.time() + timeout
        while time.time() < deadline:
            self.poll()
            i, fact = self.first(needle, start)
            if fact:
                return i, fact
            time.sleep(0.02)
        return None, None


def seconds_since(event, spawn):
    return round((event["at"] - spawn) / 1e6, 2)


def client_timeline(client):
    ev = client.events()
    spawn = client.proc.spawn_micros
    out = {k: seconds_since(v, spawn) for k, v in ev.items() if k in ("mod_init", "renderer", "load_finished", "level_ready", "first_world_frame", "feet_section_compiled", "screen:TitleScreen", "screen:ConnectScreen", "screen:LevelLoadingScreen")}
    if "mod_init" in ev:
        out["jvm_started"] = round((ev["mod_init"]["jvmStartMicros"] - spawn) / 1e6, 2)
    out["renderer_info"] = {k: ev["renderer"].get(k) for k in ("gpu", "vendor", "driver", "backend", "fbWidth", "fbHeight", "master", "music", "renderDistance", "focused")} if "renderer" in ev else None
    return out


def measure_fps(client, seconds):
    reader = FactReader(client.facts)
    reader.poll()
    last = None
    for line in reversed(reader.lines):
        if not line.startswith(b'{"k":"e"'):
            last = json.loads(line)
            break
    a = (time.time(), last)
    time.sleep(seconds)
    reader.poll()
    for line in reversed(reader.lines):
        if not line.startswith(b'{"k":"e"'):
            b = json.loads(line)
            break
    span = (b["at"] - a[1]["at"]) / 1e6
    return {"seconds": round(span, 1), "fps": round((b["frame"] - a[1]["frame"]) / span, 1), "tps": round((b["tick"] - a[1]["tick"]) / span, 1), "client_reported_fps": b["fps"]}


# ---------- commands ----------

def extract_sources():
    """Unpacks Loom's decompiled 26.3 sources after `genSources`; search with `rg -n X .mc-sources`."""
    import zipfile
    jar = next((ROOT / ".gradle/loom-cache/minecraftMaven/net/minecraft").glob("minecraft-merged-*/26.3/*-sources.jar"))
    zipfile.ZipFile(jar).extractall(ROOT / ".mc-sources")
    print(jar)


def cmd_boot(a):
    run = RUNS / f"boot-{a.world}-{a.mode}-{int(time.time())}"
    results = []
    server = Paper(run, world=a.world, xmx=a.xmx, patched=a.mode != "cold")
    try:
        for i in range(a.repeat):
            server.port, server.control = free_port(), free_port()
            server.start()
            done = server.wait_done()
            rss = rss_mb(server.proc.p.pid)
            results.append({"boot": i + 1, "wall_to_done_s": round(done, 2), "paper_reported_s": server.reported, "rss_mb_at_done": rss, "load": os.getloadavg()[0]})
            server.stop()
    finally:
        server.stop()
        stop_all()
    print(json.dumps({"world": a.world, "mode": a.mode, "xmx": a.xmx, "results": results, "leaks": leak_check()}))
    shutil.rmtree(run, ignore_errors=True)


def shot(client, name, timeout=5):
    """Asks the mod for a screenshot of the render target; returns the png path."""
    target = client.dir / f"{name}.png"
    (client.dir / "probe.shot").write_text(str(target))
    deadline = time.time() + timeout
    while time.time() < deadline:
        if target.exists() and target.stat().st_size > 0:
            return str(target)
        time.sleep(0.05)
    return None


def cmd_menu(a):
    run = RUNS / f"menu-{int(time.time())}"
    client = Client(run / "client", backend=a.backend, xmx=a.xmx, rd=a.rd, launcher=a.launcher,
                    window_flags=a.window_flags, window_clear=a.window_clear, background_app=not a.foreground_app)
    try:
        client.start()
        client.wait_event("screen:TitleScreen", 180)
        client.wait_event("load_finished", 60)
        time.sleep(2)
        pid = client.java_pid()
        fps = measure_fps(client, a.fps_seconds) if a.fps_seconds else None
        result = {"label": a.label, "launcher": a.launcher, "timeline": client_timeline(client), "front": front_app(), "load": os.getloadavg()[0],
                  "rss_mb": rss_mb(pid) if pid else None, "fps": fps}
        (RUNS / "results.jsonl").open("a").write(json.dumps(result) + "\n")
        print(json.dumps(result))
    finally:
        client.stop()
        stop_all()
    leaks = leak_check()
    print(json.dumps({"leaks": leaks}))


def cmd_scene(a):
    run = RUNS / f"scene-{int(time.time())}"
    rounds = a.rounds
    watch = ";".join(f"{2 + i},66,2" for i in range(rounds))
    server = Paper(run / "server", world=a.world, xmx=a.server_xmx)
    client = Client(run / "client", server=f"127.0.0.1:{server.port}", backend=a.backend, xmx=a.xmx, rd=a.rd, facts_mode=a.facts,
                    launcher=a.launcher, watch=watch, window_flags=a.window_flags, window_clear=a.window_clear, background_app=not a.foreground_app)
    result = {"label": a.label, "args": vars(a), "load_start": os.getloadavg()[0], "java": subprocess.run(["java", "-version"], capture_output=True, text=True).stderr.splitlines()[0]}
    fronts = set()
    try:
        server.start()
        result["server_done_s"] = round(server.wait_done(), 2)
        client.start()
        pre_front = front_app()
        client.wait_event("first_world_frame", a.timeout)
        fronts.add(front_app())
        result["timeline"] = client_timeline(client)
        result["front_before_client"] = pre_front
        joined = server.status()
        result["server_joins"] = joined["joins"]
        reader = FactReader(client.facts)
        reader.poll()
        # Wait until the section queue empties once: "chunks rendered".
        i, f = reader.wait('"queueEmpty":true', 30)
        result["sections_ready_s"] = round((f["at"] - client.proc.spawn_micros) / 1e6, 2) if f else None
        result["scene"] = run_scene(server, client, reader, rounds)
        if a.keep:
            server.cmd("title", player=client.name, text="TITLE-shot", sub="SUB-shot", **{"in": 1, "stay": 200, "out": 1})
            server.cmd("actionbar", player=client.name, text="BAR-shot")
            server.cmd("chat", player=client.name, text="CHAT-shot")
            time.sleep(0.3)
            result["screenshot"] = shot(client, "scene")
        fronts.add(front_app())
        if a.fps_seconds:
            result["fps"] = measure_fps(client, a.fps_seconds)
        pid = client.java_pid()
        result["rss_client_mb"] = rss_mb(pid) if pid else None
        result["footprint_client_mb"] = footprint_mb(pid) if pid else None
        result["rss_server_mb"] = rss_mb(server.proc.p.pid)
        result["footprint_server_mb"] = footprint_mb(server.proc.p.pid)
        result["server_tps"] = server.status()["tps"]
        fronts.add(front_app())
        result["front_during_run"] = sorted(fronts)
        result["heap_gc"] = gc_summary(pid) if pid else None
        result["client_gc_log"] = gc_log_summary(client.dir / "gc.log")
    except Exception as e:
        result["error"] = repr(e)
    finally:
        client.stop()
        server.stop()
        stop_all()
    result["load_end"] = os.getloadavg()[0]
    result["leaks"] = leak_check()
    (RUNS / "results.jsonl").open("a").write(json.dumps(result) + "\n")
    print(json.dumps(result, indent=1))
    if not a.keep:
        shutil.rmtree(run, ignore_errors=True)
    if "error" in result or result["leaks"]:
        sys.exit(1)


def gc_summary(pid):
    out = subprocess.run(["jcmd", str(pid), "GC.heap_info"], capture_output=True, text=True, timeout=20).stdout
    m = re.search(r"garbage-first heap\s+total reserved (\d+)K, committed (\d+)K, used (\d+)K", out)
    return {"reserved_mb": int(m[1]) // 1024, "committed_mb": int(m[2]) // 1024, "used_mb": int(m[3]) // 1024} if m else out[:200]


def gc_log_summary(path):
    text = pathlib.Path(path).read_text(errors="replace")
    pauses = [float(x) for x in re.findall(r"Pause .*?(\d+\.\d+)ms", text)]
    return {"pauses": len(pauses), "max_pause_ms": max(pauses) if pauses else 0, "total_pause_ms": round(sum(pauses)), "full_gcs": text.count("Pause Full"), "oom": "OutOfMemory" in text}


def run_scene(server, client, reader, rounds):
    """Sends each yardstick item `rounds` times and matches it to the first fact showing it."""
    p = client.name
    latencies = {"title": [], "chat": [], "actionbar": [], "block": [], "packetEntity": [], "hiddenEntity": []}
    checks = {}
    kinds = {}
    idx = len(reader.lines)

    def record(item, sent, needle, verify):
        nonlocal idx
        i, fact = reader.wait(needle, timeout=5, start=idx)
        if fact is None:
            checks.setdefault(item, []).append(f"missing {needle}")
            return None
        latencies[item].append((fact["at"] - sent) / 1000)
        kinds[fact["k"]] = kinds.get(fact["k"], 0) + 1
        ok = verify(fact)
        checks.setdefault(item, []).append(ok is True or ok)
        return fact

    # First round with long fades proves the fade times and the title lifetime as the client sees them.
    t = "TITLE-long"
    sent = server.cmd("title", player=p, text=t, sub="SUB-long", **{"in": 10, "stay": 40, "out": 10})["sentMicros"]
    fact = record("title", sent, f'"title":"{t}"', lambda f: f["sub"] == "SUB-long" and f["fade"] == [10, 40, 10] and f["titleTime"] > 0)
    title_life = None
    if fact:
        title_index, _ = reader.first(f'"title":"{t}"', idx)
        deadline = time.time() + 6
        while time.time() < deadline:
            reader.poll()
            i, gone = reader.first('"titleTime":0,', title_index)
            if gone and gone["at"] > fact["at"]:
                title_life = (gone["at"] - fact["at"]) / 1e6
                break
            time.sleep(0.05)
    for n in range(rounds):
        idx = len(reader.lines)
        t = f"TITLE-{n}"
        sent = server.cmd("title", player=p, text=t, sub=f"SUB-{n}", **{"in": 1, "stay": 4, "out": 1})["sentMicros"]
        record("title", sent, f'"title":"{t}"', lambda f: f["sub"] == f"SUB-{n}" and f["titleTime"] > 0)
        t = f"CHAT-{n}"
        sent = server.cmd("chat", player=p, text=t)["sentMicros"]
        record("chat", sent, f'"{t}"', lambda f: t in f["chat"])
        t = f"BAR-{n}"
        sent = server.cmd("actionbar", player=p, text=t)["sentMicros"]
        record("actionbar", sent, f'"bar":"{t}"', lambda f: f["barTime"] > 0)
        x = 2 + n
        r = server.cmd("block", player=p, x=x, y=66, z=2, material="DIAMOND_BLOCK")
        record("block", r["sentMicros"], f'"{x},66,2":"minecraft:diamond_block"', lambda f: r["serverBlock"] == "AIR")
        t = f"PACKET-{n}"
        r = server.cmd("packetEntity", player=p, text=t, x=n - 2, y=67, z=5)
        record("packetEntity", r["sentMicros"], f'"text":"{t}"', lambda f: any(e.get("text") == t and e["type"] == "minecraft:text_display" and e["name"] == t for e in f["entities"]))
        t = f"HIDDEN-{n}"
        r = server.cmd("hiddenEntity", player=p, text=t, x=n - 2, y=68, z=5)
        record("hiddenEntity", r["sentMicros"], f'"text":"{t}"', lambda f: any(e.get("text") == t and e["type"] == "minecraft:text_display" for e in f["entities"]))
    status = server.status()
    server_side = {
        "packet_entities_on_server": sum(1 for x in status["worldTextDisplays"] if x.startswith("PACKET")),
        "hidden_entities_on_server": sum(1 for x in status["worldTextDisplays"] if x.startswith("HIDDEN")),
    }

    def stats(v):
        if not v:
            return None
        v = sorted(v)
        return {"n": len(v), "min_ms": round(v[0], 1), "median_ms": round(v[len(v) // 2], 1), "max_ms": round(v[-1], 1)}

    return {
        "latency": {k: stats(v) for k, v in latencies.items()},
        "all_ok": {k: all(c is True for c in v) for k, v in checks.items()},
        "failures": {k: [c for c in v if c is not True][:3] for k, v in checks.items() if any(c is not True for c in v)},
        "seen_first_in": kinds,
        "title_life_s_expected_3": round(title_life, 2) if title_life else None,
        "server_side": server_side,
    }


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    sub.add_parser("prepare")
    sub.add_parser("sources")
    b = sub.add_parser("boot")
    b.add_argument("--world", default="void")
    b.add_argument("--mode", default="fresh", choices=["fresh", "cold"], help="fresh: patched cache, cold: paperclip patches too")
    b.add_argument("--repeat", type=int, default=2, help="boots in the same dir; the first generates the world")
    b.add_argument("--xmx", default="1g")
    m = sub.add_parser("menu")
    s = sub.add_parser("scene")
    for x in (m, s):
        x.add_argument("--backend", default=None, choices=[None, "opengl", "vulkan"])
        x.add_argument("--xmx", default="2g")
        x.add_argument("--rd", type=int, default=2)
        x.add_argument("--launcher", default="direct", choices=["direct", "gradle"])
        x.add_argument("--window-flags", default="0")
        x.add_argument("--window-clear", default="0", help="SDL flags to drop, 0x2000 gives real 854x480 on Retina")
        x.add_argument("--foreground-app", action="store_true")
        x.add_argument("--fps-seconds", type=int, default=0)
        x.add_argument("--label", default="")
    s.add_argument("--world", default="void")
    s.add_argument("--server-xmx", default="1g")
    s.add_argument("--rounds", type=int, default=10)
    s.add_argument("--facts", default="all", choices=["all", "changes"])
    s.add_argument("--timeout", type=int, default=180)
    s.add_argument("--keep", action="store_true")
    a = ap.parse_args()
    RUNS.mkdir(exist_ok=True)
    {"prepare": lambda _: prepare(), "sources": lambda _: extract_sources(), "boot": cmd_boot, "menu": cmd_menu, "scene": cmd_scene}[a.cmd](a)


if __name__ == "__main__":
    main()
