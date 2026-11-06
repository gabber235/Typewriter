#!/usr/bin/env python3
"""Spike H: run.py and speed.py on a GitHub free runner, under Xvfb on a software renderer.

  ci.py plan smoke|fps|speed|flake|multi|compare [--backend opengl|vulkan] [--cycles 3]

Linux only. Everything the runner needs that the Mac spikes do not lives here: one Xvfb per client,
Mesa environment, a renderer assertion so a silent fallback fails, CPU from /proc, and a JSON result
file (runs/h.jsonl) where every row names the CPU, renderer and Mesa version it was measured on.
A failed step is recorded and the plan goes on, so one bad cell cannot hide the others.
"""
import argparse, json, os, pathlib, platform, re, shutil, socket, subprocess, sys, threading, time, traceback

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import run as R
import speed
from run import Client, RUNS, free_port, leak_check, rss_mb, stop_all
import video
from speed import Line, TunedPaper, KINDS, MATERIALS, needle_for, leftovers, stat

RESULTS = RUNS / "h.jsonl"
SHOTS = RUNS / "shots"
EVIDENCE = RUNS / "h-evidence"
JOB_T0 = float(os.environ.get("JOB_T0", time.time()))
# Leaves room in the 25 minute job for the artifact upload.
BUDGET_S = float(os.environ.get("CI_BUDGET_S", 21 * 60))
meta = {}
failures = []


def elapsed():
    return time.time() - JOB_T0


def over_budget():
    return elapsed() > BUDGET_S


def record(kind, **row):
    full = {"kind": kind, "job_s": round(elapsed()), **row, "machine": meta}
    RUNS.mkdir(exist_ok=True)
    with RESULTS.open("a") as f:
        f.write(json.dumps(full) + "\n")
    print(json.dumps({k: v for k, v in full.items() if k != "machine"}), flush=True)


# ---------- machine facts ----------

def sh(*cmd, timeout=30):
    try:
        out = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
        return (out.stdout + out.stderr).strip()
    except Exception as e:
        return f"unavailable: {e}"


def collect_meta():
    cpuinfo = pathlib.Path("/proc/cpuinfo").read_text()
    model = re.search(r"model name\s*:\s*(.+)", cpuinfo)
    meminfo = pathlib.Path("/proc/meminfo").read_text()
    meta.update({
        "arch": platform.machine(),
        "cpu": model[1].strip() if model else sh("lscpu").split("Model name:")[-1].splitlines()[0].strip(),
        "vcpus": os.cpu_count(),
        "mem_total_mb": int(re.search(r"MemTotal:\s*(\d+)", meminfo)[1]) // 1024,
        "kernel": platform.release(),
        "os": sh("lsb_release", "-ds"),
        "java": sh("java", "-version").splitlines()[0],
        "mesa_pkg": sh("dpkg-query", "-W", "-f=${Version}", "libgl1-mesa-dri"),
        "lavapipe_pkg": sh("dpkg-query", "-W", "-f=${Version}", "mesa-vulkan-drivers"),
        "runner": os.environ.get("RUNNER_NAME", "?"),
        "run": os.environ.get("GITHUB_RUN_ID", "?"),
    })


def cmd_env():
    out = {"lscpu": sh("lscpu"), "free": sh("free", "-m"), "dpkg": sh("sh", "-c", "dpkg -l | grep -Ei 'mesa|llvm|vulkan|xvfb|libsdl' | awk '{print $2, $3}'")}
    display = Xvfb().start()
    env = {**os.environ, "DISPLAY": display.name, "LIBGL_ALWAYS_SOFTWARE": "1"}
    out["glxinfo"] = subprocess.run(["glxinfo", "-B"], capture_output=True, text=True, env=env, timeout=30).stdout
    out["vulkaninfo"] = subprocess.run(["vulkaninfo", "--summary"], capture_output=True, text=True, env=env, timeout=30).stdout[-3000:]
    out["eglinfo"] = sh("sh", "-c", "eglinfo -B 2>&1 | head -40")
    display.stop()
    record("env", **out)


# ---------- Xvfb and renderer settings ----------

class Xvfb:
    size = (1280, 1024)  # the video plan sets the client size, so x11grab sees only the game

    def __init__(self, width=None, height=None):
        self.width, self.height = width or Xvfb.size[0], height or Xvfb.size[1]
        self.proc = None

    def start(self):
        for n in range(90, 140):
            if os.path.exists(f"/tmp/.X11-unix/X{n}"):
                continue
            self.name = f":{n}"
            self.proc = subprocess.Popen(["Xvfb", self.name, "-screen", "0", f"{self.width}x{self.height}x24", "+extension", "GLX", "+render", "-noreset", "-nolisten", "tcp"],
                                         stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            deadline = time.time() + 10
            while time.time() < deadline:
                if os.path.exists(f"/tmp/.X11-unix/X{n}"):
                    displays.append(self)
                    return self
                if self.proc.poll() is not None:
                    break
                time.sleep(0.05)
        raise RuntimeError("no Xvfb display could be started")

    def stop(self):
        if self.proc and self.proc.poll() is None:
            self.proc.terminate()
            try:
                self.proc.wait(5)
            except subprocess.TimeoutExpired:
                self.proc.kill()
        if self in displays:
            displays.remove(self)


displays = []


class Cfg:
    """One renderer setup. gl picks how SDL gets its OpenGL context under Xvfb."""

    def __init__(self, backend="opengl", width=854, height=480, rd=2, world="void", lp=None, gl="srgb-skip", audio="null"):
        self.backend, self.width, self.height, self.rd, self.world, self.lp, self.gl, self.audio = backend, width, height, rd, world, lp, gl, audio

    def env(self, display):
        env = {"DISPLAY": display, "SDL_VIDEODRIVER": "x11", "SDL_AUDIODRIVER": "dummy", "LIBGL_ALWAYS_SOFTWARE": "1", "GALLIUM_DRIVER": "llvmpipe"}
        if self.gl == "srgb-skip":
            env["SDL_OPENGL_FORCE_SRGB_FRAMEBUFFER"] = "skip"
        elif self.gl == "egl":
            env["SDL_VIDEO_FORCE_EGL"] = "1"
        if self.lp is not None:
            env["LP_NUM_THREADS"] = str(self.lp)
        if self.audio:
            env["ALSOFT_DRIVERS"] = self.audio
        return env

    def row(self):
        return {"backend": self.backend, "fb_asked": f"{self.width}x{self.height}", "rd": self.rd, "world": self.world, "lp": self.lp if self.lp is not None else "default", "gl": self.gl}


def assert_renderer(client, want_backend):
    """A failed backend falls back silently, so the renderer fact is what decides."""
    client.wait_event("renderer", 30)
    r = client.events()["renderer"]
    assert r["master"] == 0.0 and r["music"] == 0.0, f"client is not silent: {r}"
    if want_backend:
        assert want_backend in r["backend"].lower(), f"asked {want_backend}, got {r['backend']} on {r['gpu']}"
    assert "llvmpipe" in (r["gpu"] + " " + r["driver"]).lower() or "lavapipe" in (r["gpu"] + " " + r["driver"]).lower(), f"not a software renderer: {r}"
    return r


def renderer_row(r):
    return {k: r.get(k) for k in ("gpu", "vendor", "driver", "backend", "fbWidth", "fbHeight", "screenWidth", "screenHeight", "master", "music", "renderDistance")}


# ---------- CPU and memory from /proc, sub second unlike ps ----------

TICK = os.sysconf("SC_CLK_TCK")


def proc_cpu_seconds(pid):
    with open(f"/proc/{pid}/stat") as f:
        fields = f.read().rsplit(")", 1)[1].split()
    return (int(fields[11]) + int(fields[12])) / TICK


speed.cpu_seconds = proc_cpu_seconds


def machine_cpu():
    fields = list(map(int, pathlib.Path("/proc/stat").read_text().splitlines()[0].split()[1:9]))
    idle = fields[3] + fields[4]
    return sum(fields), idle, fields[7]


def mem_available_mb():
    return int(re.search(r"MemAvailable:\s*(\d+)", pathlib.Path("/proc/meminfo").read_text())[1]) // 1024


class Usage:
    """CPU of named processes and of the whole machine over a window, lowest free memory seen."""

    def __init__(self, pids):
        self.pids = pids

    def __enter__(self):
        self.t0 = time.time()
        self.c0 = {k: proc_cpu_seconds(v) for k, v in self.pids.items()}
        self.m0 = machine_cpu()
        self.low = mem_available_mb()
        self.done = threading.Event()
        self.thread = threading.Thread(target=self._watch, daemon=True)
        self.thread.start()
        return self

    def _watch(self):
        while not self.done.wait(0.5):
            self.low = min(self.low, mem_available_mb())

    def __exit__(self, *exc):
        self.done.set()
        self.wall = time.time() - self.t0
        self.cpu = {k: round((proc_cpu_seconds(v) - self.c0[k]) / self.wall * 100) for k, v in self.pids.items()}
        total, idle, steal = machine_cpu()
        dt = total - self.m0[0]
        self.busy_vcpus = round((dt - (idle - self.m0[1])) / dt * os.cpu_count(), 2) if dt else None
        self.steal_pct = round((steal - self.m0[2]) / dt * 100, 2) if dt else None
        return False

    def row(self):
        return {"cpu_pct": self.cpu, "busy_vcpus": self.busy_vcpus, "steal_pct": self.steal_pct, "mem_available_min_mb": self.low, "mem_used_max_mb": meta["mem_total_mb"] - self.low, "load1": round(os.getloadavg()[0], 1)}


# ---------- Paper and a session configured for the runner ----------

class CiPaper(TunedPaper):
    def setup(self):
        super().setup()
        props = self.dir / "server.properties"
        props.write_text(props.read_text() + "level-seed=20261105\n")


def capture(run, label, note=""):
    """Keeps logs out of the run dir: symlinks there point at the whole Paper cache, so never upload it."""
    dest = EVIDENCE / label
    dest.mkdir(parents=True, exist_ok=True)
    counts = {}
    for name, rel in (("client.log", "client/client.log"), ("server.log", "server/server.log"), ("gc.log", "client/gc.log")):
        src = pathlib.Path(run) / rel
        if src.exists():
            data = src.read_bytes()
            (dest / name).write_bytes(data[-300_000:])
            text = data.decode(errors="replace")
            if name != "gc.log":
                counts[name] = {"errors": len(re.findall(r"\bERROR\b|Exception", text)), "cant_keep_up": text.count("Can't keep up"), "glx_visual": text.count("Couldn't find matching GLX visual")}
    if note:
        (dest / "note.txt").write_text(note)
    for crash in pathlib.Path(run).rglob("hs_err*.log"):
        shutil.copy(crash, dest / crash.name)
    return counts


BaseSession = speed.Session  # speed.Session becomes CiSession below, so speed.py's commands get it


class CiSession(BaseSession):
    cfg = Cfg()

    def __init__(self, label, dispatch="tick", rd=2, **k):
        cfg = CiSession.cfg
        super().__init__(label, dispatch=dispatch, rd=cfg.rd if cfg.rd != 2 else rd, **k)
        old = self.server
        self.server = CiPaper(old.dir, tuned=old.tuned, view=max(3, cfg.rd), world=cfg.world, xmx=old.xmx, extra_jvm=old.extra_jvm)
        self.label = label
        self.display = Xvfb().start()
        self.client.backend = cfg.backend
        self.client.width, self.client.height = cfg.width, cfg.height
        self.client.env.update(cfg.env(self.display.name))
        self.client.background_app = False

    def __enter__(self):
        spawn = time.time()
        try:
            super().__enter__()
            r = assert_renderer(self.client, CiSession.cfg.backend)
        except BaseException as e:
            counts = capture(self.run, f"{self.label}-enter-failed", traceback.format_exc())
            record("session_failed", label=self.label, error=repr(e)[:400], logs=counts, **CiSession.cfg.row())
            self.client_stop()
            raise
        self.renderer = renderer_row(r)
        ev = self.client.events()
        record("session", label=self.label, server_done_s=round(self.server_done, 2), timeline=R.client_timeline(self.client), renderer=self.renderer, session_start_s=round(time.time() - spawn, 2),
               job_to_in_world_s=round(ev["first_world_frame"]["at"] / 1e6 - JOB_T0, 1), **CiSession.cfg.row())
        return self

    def client_stop(self):
        BaseSession.__exit__(self, None, None, None)
        self.display.stop()

    def __exit__(self, *exc):
        counts = capture(self.run, self.label)
        record("session_end", label=self.label, logs=counts)
        self.client_stop()
        return False


speed.Session = CiSession


def set_cfg(cfg):
    CiSession.cfg = cfg
    return cfg


def run_speed(*argv):
    """Runs one speed.py command unchanged and copies its result rows into h.jsonl with the machine facts."""
    before = speed.RESULTS.stat().st_size if speed.RESULTS.exists() else 0
    old = sys.argv
    sys.argv = ["speed.py", *argv]
    try:
        speed.main()
    finally:
        sys.argv = old
        if speed.RESULTS.exists():
            with speed.RESULTS.open() as f:
                f.seek(before)
                for line in f:
                    record("speed", argv=" ".join(argv), cfg=CiSession.cfg.row(), result=json.loads(line))


def step(name, fn, *a, **k):
    """A failed step is data, not the end of the job."""
    if over_budget():
        record("skipped", step=name, why="job budget")
        return None
    t0 = time.time()
    try:
        out = fn(*a, **k)
        record("step_ok", step=name, seconds=round(time.time() - t0, 1))
        return out
    except Exception as e:
        failures.append(name)
        record("step_failed", step=name, seconds=round(time.time() - t0, 1), error=repr(e)[:500], trace=traceback.format_exc()[-1500:])
        stop_all()
        for d in list(displays):
            d.stop()
        return None


# ---------- what to measure ----------

def try_setup(name, backend, gl, timeout=150, audio=None):
    """Which SDL and Mesa setting gives which renderer: client alone, up to the title screen."""
    cfg = Cfg(backend=backend, gl=gl, audio=audio)
    run = RUNS / f"setup-{name}-{int(time.time())}"
    display = Xvfb().start()
    client = Client(run / "client", backend=backend, xmx="1g", rd=2, facts_mode="changes", background_app=False, env=cfg.env(display.name))
    row = {"variant": name, "backend_asked": backend, "gl": gl}
    t0 = time.time()
    try:
        client.start()
        client.wait_event("screen:TitleScreen", timeout)
        row["title_screen_s"] = round(time.time() - t0, 1)
        client.wait_event("renderer", 10)
        row["renderer"] = renderer_row(client.events()["renderer"])
        row["silent"] = row["renderer"]["master"] == 0.0 and row["renderer"]["music"] == 0.0
        row["got_asked_backend"] = backend is None or backend in row["renderer"]["backend"].lower()
        client.wait_event("load_finished", 60)
        time.sleep(1)
        row["shot"] = R.shot(client, "title")
        if row["shot"]:
            SHOTS.mkdir(exist_ok=True)
            shutil.copy(row["shot"], SHOTS / f"setup-{name}.png")
    except Exception as e:
        row["error"] = repr(e)[:400]
    finally:
        client.stop()
        stop_all()
        display.stop()
    logs = capture(run, f"setup-{name}")
    row["logs"] = logs
    row["audio"] = audio
    text = (run / "client/client.log").read_text(errors="replace") if (run / "client/client.log").exists() else ""
    row["log_hits"] = [l[:200] for l in text.splitlines() if re.search(r"GLX|falling back|fall back|Vulkan|OpenGL|SDL|Graphics|OpenAL|Sound engine|SoundSystem", l, re.I)][:15]
    shutil.rmtree(run, ignore_errors=True)
    record("setup", **row)
    return row


def scene_shot(s, name, wait=1.5):
    """Title, chat, per player block and packet only entity in one drawn frame, saved for a look."""
    SHOTS.mkdir(exist_ok=True)
    direct = lambda *a, **k: s.S(*a, _dispatch="direct", **k)
    direct("title", player=s.p, text="TITLE-shot", sub="SUB-shot", **{"in": 1, "stay": 2000, "out": 1})
    direct("act", player=s.p, kind="chat", token="CHAT-shot", material="GOLD_BLOCK", broken="0")
    direct("act", player=s.p, kind="block", token="BLOCK-shot", material="GOLD_BLOCK", broken="0")
    direct("act", player=s.p, kind="entity", token="ENTITY-shot", material="GOLD_BLOCK", broken="0")
    time.sleep(wait)
    path = SHOTS / f"{name}.png"
    reply = s.C("shot", path=str(path))
    direct("reset", player=s.p)
    s.C("clearChat")
    return {"path": str(path), "bytes": path.stat().st_size if path.exists() else 0, "ms": (reply["written"] - reply["start"]) / 1000}


def fps_cell(cfg, seconds=10, shot=True):
    """Frames per second with Paper alongside, after the visible sections have settled."""
    set_cfg(cfg)
    label = f"fps-{cfg.backend}-{cfg.world}-{cfg.width}x{cfg.height}-rd{cfg.rd}-lp{cfg.lp if cfg.lp is not None else 'def'}"
    with CiSession(label, dispatch="tick") as s:
        # settledAt never came in the default world in 45 s, inference: occluded sections never count as visible.
        settled = s.C("observe", needle='"settledAt"', timeoutMs=15000)
        time.sleep(2)
        f0 = s.C("stats")
        st0 = s.S("status", player=s.p)
        with Usage({"client": s.clientpid, "server": s.serverpid, "xvfb": s.display.proc.pid}) as u:
            time.sleep(seconds)
        f1 = s.C("stats")
        st1 = s.S("status", player=s.p)
        span = (f1["at"] - f0["at"]) / 1e6
        row = {"label": label, **cfg.row(), "renderer": s.renderer, "settled": settled["ok"], "fps": round((f1["frame"] - f0["frame"]) / span, 1), "client_tps": round((f1["tick"] - f0["tick"]) / span, 1),
               "server_ticks_per_s": round((st1["tick"] - st0["tick"]) / span, 1), "mspt": st1["mspt"], **u.row(),
               "rss_mb": {"client": rss_mb(s.clientpid), "server": rss_mb(s.serverpid)}}
        if shot:
            row["shot"] = scene_shot(s, label)
    record("fps", **row)


def first(cfg):
    """Paper boot, client to world, once per backend; also a frame to look at."""
    fps_cell(cfg, seconds=6)


def cmd_smoke(backends):
    step("env", cmd_env)
    for name, backend, gl in (("gl-plain", "opengl", "plain"), ("gl-srgb-skip", "opengl", "srgb-skip"), ("gl-egl", "opengl", "egl"), ("vulkan", "vulkan", "plain"), ("auto", None, "plain")):
        step(f"setup {name}", try_setup, name, backend, gl)
    step("setup audio null driver", try_setup, "audio-null", "opengl", "srgb-skip", audio="null")
    ok = []
    for backend in backends:
        if step(f"first {backend} void", first, Cfg(backend=backend)) is None and failures and failures[-1].startswith(f"first {backend}"):
            continue
        ok.append(backend)
        step(f"first {backend} default world", first, Cfg(backend=backend, world="default", rd=5))
    for backend in ok:
        set_cfg(Cfg(backend=backend))
        step(f"c3 {backend} R4 tick gate 0", run_speed, "c3", "--approach", "R4", "--n", "40")
        step(f"c3 {backend} R4 tick gate 2", run_speed, "c3", "--approach", "R4", "--n", "40", "--gate", "2")


def cmd_fps(backend):
    step("env", cmd_env)
    step(f"fps {backend} void baseline", fps_cell, Cfg(backend=backend))
    for w, h in ((854, 480), (427, 240)):
        for rd in (2, 5):
            for lp in (None, 2):
                step(f"fps {backend} {w}x{h} rd{rd} lp{lp}", fps_cell, Cfg(backend=backend, world="default", width=w, height=h, rd=rd, lp=lp), shot=(w == 854 and lp is None))


def cmd_speed(backend):
    set_cfg(Cfg(backend=backend))
    c3 = lambda *a: step("c3 " + " ".join(a), run_speed, "c3", *a)
    c3("--approach", "R4", "--n", "200")
    c3("--approach", "R4", "--n", "200", "--gate", "2")
    c3("--approach", "R4", "--n", "1000", "--dispatch", "direct", "--gate", "2")
    c3("--approach", "R4", "--n", "1000", "--rate", "200", "--gate", "2")
    c3("--approach", "R4", "--n", "200", "--rate", "200")
    c3("--approach", "R3", "--n", "200", "--rate", "200")
    c3("--approach", "R3", "--n", "200", "--rate", "200", "--gate", "2")
    c3("--approach", "R3", "--n", "200", "--rate", "200", "--gate", "2", "--uncap")
    c3("--approach", "R4", "--n", "100", "--late-ticks", "1")
    c3("--approach", "R4", "--n", "100", "--late-ticks", "1", "--fail", "timeout", "--obs-timeout", "150")
    step("c1 frame", run_speed, "c1", "frame", "--rounds", "3", "--keep-shots")
    step("c1 cpu", run_speed, "c1", "cpu", "--rounds", "2", "--seconds", "8", "--samples", "20")


def cmd_flake(backend, cycles):
    """The whole thing over and over: fresh Paper, fresh client, join, requirements, frame."""
    set_cfg(Cfg(backend=backend))
    for i in range(cycles):
        step(f"flake {i} R4 tick", run_speed, "c3", "--approach", "R4", "--n", "100")
        step(f"flake {i} R4 tick gate 2 rate 200", run_speed, "c3", "--approach", "R4", "--n", "500", "--rate", "200", "--gate", "2")
        step(f"flake {i} R3 rate 200", run_speed, "c3", "--approach", "R3", "--n", "100", "--rate", "200")
    step("flake frame", fps_cell, Cfg(backend=backend, world="default", rd=5), seconds=4)


# ---------- first look at spike D: N clients on one runner ----------

class Multi:
    def __init__(self, n, cfg):
        self.n, self.cfg = n, cfg
        self.next_ping = 1000
        self.run = RUNS / f"multi-{n}-{int(time.time())}"
        self.line = free_port()
        limit = "-Dprobe.maxRuntimeSec=1200"
        self.server = CiPaper(self.run / "server", tuned=True, view=3, world="void", xmx="1g", extra_jvm=[limit, f"-Dprobe.line.port={self.line}"])
        self.clients, self.lives, self.displays = [], [], []
        for i in range(n):
            display = Xvfb().start()
            live = free_port()
            c = Client(self.run / f"client{i}", name=f"probe{i + 1}", backend=cfg.backend, xmx="1g", rd=2, facts_mode="changes", background_app=False,
                       extra_jvm=[limit, f"-Dprobe.live.port={live}"], env=cfg.env(display.name))
            self.clients.append(c)
            self.lives.append(live)
            self.displays.append(display)

    def __enter__(self):
        self.server.start()
        self.server_done = self.server.wait_done()
        t0 = time.time()
        for c in self.clients:
            c.server = f"127.0.0.1:{self.server.port}"
            c.start()
        for c in self.clients:
            c.wait_event("first_world_frame", 240)
            c.wait_event("load_finished", 120)
        self.joined_s = round(time.time() - t0, 1)
        self.renderers = [renderer_row(assert_renderer(c, self.cfg.backend)) for c in self.clients]
        self.S = Line(self.line, prefix="tick/")
        self.C = [Line(p) for p in self.lives]
        # Own region each: players on one spot push each other, which moves what they look at.
        for i, c in enumerate(self.clients):
            r = self.S("region", player=c.name, idx=i)
            ok = self.C[i]("observe", needle=f'"compiledAt":"{r["dim"]}|{r["cx"]},{r["cz"]}"', timeoutMs=60000)["ok"]
            assert ok, f"client {i} not ready in its region"
            self.C[i]("clearChat")
        self.S("time", player=self.clients[0].name)
        self.pids = {c.name: c.java_pid() for c in self.clients}
        self.pids["server"] = self.server.proc.p.pid
        return self

    def __exit__(self, *exc):
        logs = capture(self.run, self.run.name)
        for c in self.clients:
            c.stop()
        self.server.stop()
        stop_all()
        for d in self.displays:
            d.stop()
        shutil.rmtree(self.run, ignore_errors=True)
        record("multi_end", n=self.n, logs=logs)
        return False


def multi_requirements(m, i, n, base, out):
    """cmd_c3's R4 loop for one client, on its own sockets, against the shared Paper."""
    c = m.clients[i]
    S, C = Line(m.line, prefix="tick/"), Line(m.lives[i])
    totals, wrong, dirty, details = [], 0, 0, []
    for k in range(n):
        kind = KINDS[k % 4]
        token = f"M{i}T{k}x"
        material = MATERIALS[k % len(MATERIALS)]
        broken = (k + 1) % 20 == 0
        act_ping, end_ping = base + 2 * k, base + 2 * k + 1  # higher than any earlier ping, or the barrier has already passed
        t0 = time.perf_counter()
        S("act", player=c.name, kind=kind, token=token, material=material, broken="1" if broken else "0", ping=act_ping)
        obs = C("observe", needle=needle_for(kind, token, material), timeoutMs=2000, ping=act_ping)
        if obs["ok"] == broken:
            wrong += 1
            details.append({"k": k, "kind": kind, "broken": broken, "why": obs["why"], "ms": (obs["at"] - obs["start"]) / 1000})
        S("reset", player=c.name, ping=end_ping)
        C("clearChat")
        st = C("state", ping=end_ping)
        if leftovers(st["p"]):
            dirty += 1
        if not broken:
            totals.append(time.perf_counter() - t0)
    out[i] = {"wrong": wrong, "dirty": dirty, "total": stat(totals), "details": details[:5]}


def multi_phase(m, gate, rate, n):
    m.S("tickrate", player=m.clients[0].name, rate=rate)
    for line in m.C:
        line("gate", mode=gate)
    time.sleep(1)
    out = {}
    base = m.next_ping
    m.next_ping += 2 * n + 10
    start = time.time()
    with Usage(m.pids) as u:
        threads = [threading.Thread(target=multi_requirements, args=(m, i, n, base, out)) for i in range(m.n)]
        for t in threads:
            t.start()
        for t in threads:
            t.join()
    wall = time.time() - start
    if len(out) != m.n:
        raise RuntimeError(f"only {len(out)} of {m.n} clients finished")
    return {"gate": gate, "rate": rate, "n_each": n, "wall_s": round(wall, 1), "requirements_per_s": round(m.n * n / wall, 1), "wrong": sum(v["wrong"] for v in out.values()), "dirty": sum(v["dirty"] for v in out.values()),
            "per_client": [out[i]["total"] for i in range(m.n)], "wrong_details": [d for i in range(m.n) for d in out[i]["details"]][:8], **u.row()}


def multi(n, cfg, reqs):
    with Multi(n, cfg) as m:
        row = {"n": n, **cfg.row(), "server_done_s": round(m.server_done, 2), "all_joined_s": m.joined_s, "renderers": m.renderers[:1]}
        for line in m.C:
            line("gate", mode=0)
        time.sleep(3)
        f0 = [line("stats") for line in m.C]
        with Usage(m.pids) as u:
            time.sleep(10)
        f1 = [line("stats") for line in m.C]
        row["rendered"] = {"fps_each": [round((b["frame"] - a["frame"]) / ((b["at"] - a["at"]) / 1e6), 1) for a, b in zip(f0, f1)], **u.row(),
                           "rss_mb": {k: rss_mb(v) for k, v in m.pids.items()}}
        row["phases"] = [multi_phase(m, 0, 20, reqs), multi_phase(m, 2, 20, reqs), multi_phase(m, 2, 200, reqs * 5)]
        record("multi", **row)


def cmd_compare(cycles):
    """Backends on one runner, alternating, because runners differ more than backends do."""
    for i in range(cycles):
        for backend in ("opengl", "vulkan"):
            set_cfg(Cfg(backend=backend))
            step(f"compare {i} {backend} void", fps_cell, Cfg(backend=backend), shot=False)
            step(f"compare {i} {backend} default rd5", fps_cell, Cfg(backend=backend, world="default", rd=5))
            set_cfg(Cfg(backend=backend))
            step(f"compare {i} {backend} R4 rate 200", run_speed, "c3", "--approach", "R4", "--n", "200", "--rate", "200")
            step(f"compare {i} {backend} R3 rate 200", run_speed, "c3", "--approach", "R3", "--n", "100", "--rate", "200")
    for backend in ("opengl", "vulkan"):
        set_cfg(Cfg(backend=backend, world="default", rd=5))
        step(f"frame in terrain {backend}", run_speed, "c1", "frame", "--rounds", "3", "--keep-shots")


# ---------- spike B: video ----------

class X11Grab:
    """B2: ffmpeg records the client's Xvfb display, as the panel's evidence recorder does."""

    def __init__(self, display, path, fps, w, h):
        self.path = pathlib.Path(path)
        self.log = self.path.with_suffix(".x11.log")
        self.t0 = time.time()
        self.proc = subprocess.Popen([video.FFMPEG, "-hide_banner", "-loglevel", "info", "-y", "-f", "x11grab", "-draw_mouse", "0", "-video_size", f"{w}x{h}", "-framerate", str(fps),
                                      "-i", f"{display}+0,0", "-c:v", "libx264", "-preset", "veryfast", "-crf", "23", "-pix_fmt", "yuv420p", str(self.path)],
                                     stdin=subprocess.PIPE, stdout=subprocess.DEVNULL, stderr=open(self.log, "wb"))

    def cpu(self):
        return video.proc_cpu(self.proc.pid)

    def stop(self):
        cpu = self.cpu()
        wall = time.time() - self.t0
        try:
            self.proc.stdin.write(b"q")
            self.proc.stdin.close()
        except Exception:
            pass
        try:
            self.proc.wait(60)
        except subprocess.TimeoutExpired:
            self.proc.kill()
        text = self.log.read_text(errors="replace")
        m = re.search(r"start: ([0-9.]+)", text)
        drop = re.findall(r"drop=\s*(\d+)", text)
        dup = re.findall(r"dup=\s*(\d+)", text)
        return {"start": float(m.group(1)) if m else None, "cpu_pct": round(cpu / wall * 100) if cpu is not None else None, "bytes": self.path.stat().st_size if self.path.exists() else 0,
                "wall_s": round(wall, 1), "ffmpeg_drop": int(drop[-1]) if drop else None, "ffmpeg_dup": int(dup[-1]) if dup else None, "exit": self.proc.returncode}


def grab_for(s, path, fps):
    return X11Grab(s.display.name, path, fps, s.client.width, s.client.height)


def x11_cost(cfg, seconds=8):
    """B2 cost: client rendering uncapped while ffmpeg grabs the display at 30 fps."""
    set_cfg(cfg)
    out = video.OUT / f"x11-cost-{cfg.world}-{int(time.time())}"
    out.mkdir(parents=True, exist_ok=True)
    with CiSession(f"x11cost-{cfg.world}", dispatch="tick") as s:
        time.sleep(12)
        s.C("clearChat")
        for name in ("none", "x11-30", "none"):
            f0, c0, t0 = s.C("stats"), video.proc_cpu(s.clientpid), time.time()
            g = X11Grab(s.display.name, out / f"{name}.mp4", 30, s.client.width, s.client.height) if name != "none" else None
            time.sleep(seconds)
            f1, c1, t1 = s.C("stats"), video.proc_cpu(s.clientpid), time.time()
            gs = g.stop() if g else None
            row = {"kind": "cost", "label": f"x11-{cfg.world}", "world": cfg.world, "rd": cfg.rd, "config": name, "fps": round((f1["frame"] - f0["frame"]) / ((f1["at"] - f0["at"]) / 1e6), 1),
                   "client_cpu_pct": round((c1 - c0) / (t1 - t0) * 100), "renderer": s.renderer.get("gpu") if isinstance(s.renderer, dict) else None}
            if gs:
                row.update({"ffmpeg_cpu_pct": gs["cpu_pct"], "file_bytes": gs["bytes"], "kb_per_s": round(gs["bytes"] / gs["wall_s"] / 1024, 1), "grab": gs, "probe": video.probe_video(out / f"{name}.mp4")})
                video.still(out / f"{name}.mp4", 60, 30, out / f"{name}-frame60.png")
            video.record(row)


def video_cost(cfg, configs):
    set_cfg(cfg)
    video.cmd_cost(argparse.Namespace(world=cfg.world, rd=cfg.rd, seconds=8, settle=12, reps=1, configs=configs, keep_frame=True))


def video_reqs(cfg, **k):
    set_cfg(cfg)
    a = dict(n=60, mode="rt", rate=20, cap=0, fps=30, rd=cfg.rd, linger=0.6, settle=12, grab=None, pre=0.15)
    a.update(k)
    video.cmd_reqs(argparse.Namespace(**a))


def video_step(cfg, cases):
    set_cfg(cfg)
    video.cmd_step(argparse.Namespace(cases=cases, fps=30, rd=cfg.rd, reps=1, settle=12))


def cmd_video(backend):
    Xvfb.size = (854, 480)
    video.GRAB = grab_for
    void, terrain = Cfg(backend=backend), Cfg(backend=backend, world="default", rd=5)
    cost = "none,all-null,rt30-null,rt30-x264,rt30-x264uf,rt30-x264-half,all-x264,none"
    step("video cost void", video_cost, void, cost)
    step("video cost terrain", video_cost, terrain, cost)
    step("video x11 cost terrain", x11_cost, terrain)
    step("video reqs rt void", video_reqs, void)
    step("video reqs x11 void", video_reqs, void, grab="x11")
    step("video step terrain", video_step, terrain, "rt:20:0,step:20:0,step:10:0,step:5:0")
    step("video reqs step terrain", video_reqs, terrain, n=40, mode="step", rate=10)
    step("video reqs rt terrain", video_reqs, terrain, n=40)


# ---------- spike F: golden frames ----------

def golden(kind, backend, n, **k):
    import goldens
    world, rd = ("void", 2) if kind == "session" else ("default", 5)
    set_cfg(Cfg(backend=backend, world=world, rd=rd))
    goldens.SESSION = lambda label, world, rd: CiSession(label, dispatch="tick")
    cpu = re.sub(r"[^A-Za-z0-9]+", "", meta["cpu"].replace("AMD EPYC", "epyc").replace("Intel(R) Xeon(R) Platinum", "xeon").replace("(R)", "").replace("Processor", ""))[:14]
    label = f"{meta['arch']}-{backend}-{cpu}-{os.environ.get('GITHUB_RUN_ID', 'local')[-4:]}{os.environ.get('MATRIX_REPEAT', '')}-{kind[0]}{n}"
    a = argparse.Namespace(label=label, runs=k.get("runs", 3), break_runs=k.get("break_runs", 2), sets=k.get("sets", ""))
    out = goldens.cmd_session(a) if kind == "session" else goldens.cmd_terrain(a)
    record("goldens", label=label, dir=str(out), golden=kind, backend=backend)


def cmd_goldens(backends):
    for backend in backends:
        step(f"goldens {backend} session full", golden, "session", backend, 1)
        step(f"goldens {backend} session fresh", golden, "session", backend, 2, sets="all,no-anim0,no-early", break_runs=1)
        step(f"goldens {backend} terrain", golden, "terrain", backend, 1)


def cmd_multi(backend):
    cfg = Cfg(backend=backend)
    for n in (1, 2, 4):
        step(f"multi {n}", multi, n, cfg, 100)


# ---------- spike I: coverage per requirement ----------

def run_cov(*argv):
    """Runs one coverage.py command unchanged and copies its result rows into h.jsonl."""
    import coverage
    before = coverage.RESULTS.stat().st_size if coverage.RESULTS.exists() else 0
    old = sys.argv
    sys.argv = ["coverage.py", *argv]
    try:
        coverage.main()
    finally:
        sys.argv = old
        if coverage.RESULTS.exists():
            with coverage.RESULTS.open() as f:
                f.seek(before)
                for line in f:
                    record("coverage", argv=" ".join(argv), cfg=CiSession.cfg.row(), result=json.loads(line))


def cmd_coverage(backend):
    set_cfg(Cfg(backend=backend))
    for cov in ("off", "agent"):
        step(f"boot {cov}", run_cov, "boot", "--cov", cov, "--repeat", "3")
    step("boot agent all classes", run_cov, "boot", "--cov", "agent", "--includes", "*", "--repeat", "1")
    for recipe in (("--dispatch", "direct"), ("--dispatch", "tick", "--rate", "200")):
        for cov in ("off", "agent", "rt", "tcp", "off", "rt"):
            step(f"cov {cov} {' '.join(recipe)}", run_cov, "loop", "--cov", cov, "--n", "1000", *recipe)
        step(f"cov rt group 10 {' '.join(recipe)}", run_cov, "loop", "--cov", "rt", "--n", "1000", "--group", "10", *recipe)
    for barrier in ("naive", "quiet"):
        step(f"cov trap {barrier}", run_cov, "loop", "--cov", "rt", "--n", "700", "--kinds", "trap", "--analyze", "--barrier", barrier)
    step("cov rt analyze tick 200", run_cov, "loop", "--cov", "rt", "--n", "1000", "--analyze", "--dispatch", "tick", "--rate", "200")
    step("cov all classes", run_cov, "loop", "--cov", "rt", "--n", "200", "--includes", "*")


# ---------- spike E: readiness signals ----------

def run_ready(*argv, world="void", rd=2):
    """Runs one readiness.py command unchanged and copies its result rows into h.jsonl."""
    import readiness
    set_cfg(Cfg(backend=CiSession.cfg.backend, world=world, rd=rd))
    readiness.SESSION = lambda label, rd=2, **k: CiSession(label, dispatch="tick", rd=rd)
    before = readiness.RESULTS.stat().st_size if readiness.RESULTS.exists() else 0
    old = sys.argv
    sys.argv = ["readiness.py", *argv]
    try:
        readiness.main()
    finally:
        sys.argv = old
        if readiness.RESULTS.exists():
            with readiness.RESULTS.open() as f:
                f.seek(before)
                for line in f:
                    row = json.loads(line)
                    record("readiness", argv=" ".join(argv), cfg=CiSession.cfg.row(), result={k: v for k, v in row.items() if k != "renderer"})


def cmd_readiness(backend):
    set_cfg(Cfg(backend=backend))
    lbl = f"ci{os.environ.get('MATRIX_REPEAT', '')}"
    step("readiness rendered", run_ready, "scenes", "--mode", "rendered", "--n", "50", "--label", lbl)
    step("start swap void", run_ready, "start", "--kind", "swap", "--n", "30", "--label", lbl)
    step("start reset void", run_ready, "start", "--kind", "reset", "--n", "30", "--tail", "1.5", "--label", lbl)
    step("start reconnect void", run_ready, "start", "--kind", "reconnect", "--n", "10", "--tail", "6", "--label", lbl)
    step("start reconnect terrain", run_ready, "start", "--kind", "reconnect", "--world", "default", "--n", "6", "--tail", "8", "--label", lbl, world="default", rd=5)
    step("start fresh void", run_ready, "start", "--kind", "fresh", "--n", "3", "--tail", "10", "--label", lbl)
    step("readiness gated", run_ready, "scenes", "--mode", "gated", "--n", "30", "--label", lbl)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("what", choices=["plan"])
    ap.add_argument("plan", choices=["smoke", "fps", "speed", "flake", "multi", "compare", "video", "goldens", "coverage", "readiness"])
    ap.add_argument("--backend", default="opengl")
    ap.add_argument("--cycles", type=int, default=3)
    a = ap.parse_args()
    RUNS.mkdir(exist_ok=True)
    SHOTS.mkdir(exist_ok=True)
    collect_meta()
    record("start", plan=a.plan, backend=a.backend, cwd=os.getcwd())
    try:
        if a.plan == "smoke":
            cmd_smoke(["opengl", "vulkan"])
        elif a.plan == "fps":
            cmd_fps(a.backend)
        elif a.plan == "speed":
            cmd_speed(a.backend)
        elif a.plan == "flake":
            cmd_flake(a.backend, a.cycles)
        elif a.plan == "multi":
            cmd_multi(a.backend)
        elif a.plan == "video":
            cmd_video(a.backend)
        elif a.plan == "goldens":
            cmd_goldens(["vulkan", "opengl"] if a.backend == "both" else [a.backend])
        elif a.plan == "coverage":
            cmd_coverage(a.backend)
        elif a.plan == "readiness":
            cmd_readiness(a.backend)
        elif a.plan == "compare":
            cmd_compare(2)
    finally:
        stop_all()
        for d in list(displays):
            d.stop()
    record("end", failures=failures, leaks=leak_check(), elapsed_s=round(elapsed()))
    sys.exit(1 if failures else 0)


if __name__ == "__main__":
    main()
