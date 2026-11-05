#!/usr/bin/env python3
"""Spike B: video of what the client player saw.

  video.py cost  [--world void|default] [--seconds 8] [--configs none,all-null,rt30-null,rt30-x264,...]
  video.py reqs  [--n 40] [--mode rt|step] [--rate 20] [--linger 0.6] [--grab x11]
  video.py step  [--cap 20]

B1 is the mod's Video class: async readback of mainRenderTarget piped into ffmpeg, a sidecar line per
video frame with the fact frame and client tick. B2 is ffmpeg x11grab of the Xvfb display (Linux
only, via ci.py). B4 is the mod's step mode: the client clock advances 1/fps per frame.

Every command runs through speed.Session (silent client, stops everything) and appends one JSON row
per measurement to runs/b-video.jsonl. Videos, clips, previews and frames go to runs/video/<label>/.
"""
import argparse, json, os, pathlib, platform, shutil, statistics, subprocess, sys, time

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import run as R
import speed
from run import RUNS, leak_check, now_micros
from speed import KINDS, MATERIALS, needle_for, leftovers, stat, cpu_seconds

RESULTS = RUNS / "b-video.jsonl"
OUT = RUNS / "video"
FFMPEG = shutil.which("ffmpeg") or "ffmpeg"
MAC = platform.system() == "Darwin"
GRAB = None  # set by ci.py: a callable (session, path, fps) -> X11Grab for B2


def record(row):
    RUNS.mkdir(exist_ok=True)
    row = {"load": round(os.getloadavg()[0], 1), "machine": platform.machine(), **row}
    with RESULTS.open("a") as f:
        f.write(json.dumps(row) + "\n")
    print(json.dumps(row)[:1500], flush=True)
    return row


def session(label, world="void", **k):
    """speed.Session (or ci.CiSession when run on the runner) with a true 854x480 framebuffer on the Mac."""
    s = speed.Session(label, client_jvm=[f"-Dprobe.ffmpeg={FFMPEG}"], **k)
    if MAC:
        s.client.window_clear = "0x2000"
        if world != "void":
            s.server.world = world
            s.server.view = max(3, k.get("rd", 2))
            base_setup = s.server.setup

            def setup():
                base_setup()
                props = s.server.dir / "server.properties"
                props.write_text(props.read_text() + "level-seed=20261105\n")  # same seed as the runner: spawn in the open
            s.server.setup = setup
    return s


def proc_cpu(pid):
    try:
        if pathlib.Path(f"/proc/{pid}/stat").exists():
            f = pathlib.Path(f"/proc/{pid}/stat").read_text().rsplit(")", 1)[1].split()
            return (int(f[11]) + int(f[12])) / os.sysconf("SC_CLK_TCK")
    except Exception:
        pass
    try:
        return cpu_seconds(pid)
    except ValueError:
        return None  # process already gone


# ---------- reading a video back ----------

def probe_video(path):
    out = subprocess.run(["ffprobe", "-v", "error", "-select_streams", "v:0", "-count_frames", "-show_entries", "stream=width,height,nb_read_frames,r_frame_rate,duration",
                          "-of", "json", str(path)], capture_output=True, text=True).stdout
    try:
        st = json.loads(out)["streams"][0]
        return {"w": st["width"], "h": st["height"], "frames": int(st.get("nb_read_frames", 0)), "rate": st.get("r_frame_rate"), "duration": float(st.get("duration", 0) or 0)}
    except Exception:
        return {"error": out[:200]}


def frames(path, w, h, half=True):
    """Yields decoded frames as numpy int16 arrays (h, w, 3), at half size by default."""
    import numpy as np
    vf = ["-vf", "scale=iw/2:ih/2:flags=area"] if half else []
    ww, hh = (w // 2, h // 2) if half else (w, h)
    p = subprocess.Popen([FFMPEG, "-v", "error", "-i", str(path), *vf, "-f", "rawvideo", "-pix_fmt", "rgb24", "-"], stdout=subprocess.PIPE)
    size = ww * hh * 3
    try:
        while True:
            buf = p.stdout.read(size)
            if len(buf) < size:
                break
            yield np.frombuffer(buf, dtype=np.uint8).reshape(hh, ww, 3).astype(np.int16)
    finally:
        p.stdout.close()
        p.wait()


def still(video, v, fps, path):
    subprocess.run([FFMPEG, "-v", "error", "-y", "-i", str(video), "-vf", f"select=eq(n\\,{v})", "-frames:v", "1", str(path)], check=True)
    return str(path)


def cut(video, v0, v1, fps, clip, preview):
    """Clip as mp4 and a looping webp preview (640 wide, 8 fps) under 3 MB, like the panel's evidence."""
    t0, n = v0 / fps, max(1, v1 - v0)
    subprocess.run([FFMPEG, "-v", "error", "-y", "-ss", f"{t0:.4f}", "-i", str(video), "-frames:v", str(n), "-c:v", "libx264", "-preset", "veryfast", "-crf", "23", "-pix_fmt", "yuv420p", str(clip)], check=True)
    sizes = {}
    for q in ("60", "35", "15"):
        subprocess.run([FFMPEG, "-v", "error", "-y", "-i", str(clip), "-vf", "fps=8,scale=640:-2", "-loop", "0", "-an", "-c:v", "libwebp", "-quality", q, str(preview)], check=True)
        sizes[q] = preview.stat().st_size
        if sizes[q] <= 3 * 1024 * 1024:
            break
    return {"clip_bytes": clip.stat().st_size, "preview_bytes": preview.stat().st_size, "preview_quality": q, "frames": n}


def sidecar(path):
    rows = []
    p = pathlib.Path(str(path) + ".frames.jsonl")
    if p.exists():
        for line in p.read_text().splitlines():
            rows.append(json.loads(line))
    return rows


def v_of_frame(side, frame):
    """First non duplicate video frame that shows fact frame `frame` or later."""
    for r in side:
        if not r.get("dup") and r["f"] >= frame:
            return r["v"]
    return None


# ---------- cost ----------

CONFIGS = {
    "none": None,
    "all-null": dict(mode="all", enc="null", fps=30),
    "rt30-null": dict(mode="rt", enc="null", fps=30),
    "rt30-x264": dict(mode="rt", enc="x264", fps=30, preset="veryfast", crf=23),
    "rt30-x264uf": dict(mode="rt", enc="x264", fps=30, preset="ultrafast", crf=23),
    "rt60-x264": dict(mode="rt", enc="x264", fps=60, preset="veryfast", crf=23),
    "rt30-vt": dict(mode="rt", enc="vt", fps=30, bitrate="2M"),
    "rt30-x264-half": dict(mode="rt", enc="x264", fps=30, preset="veryfast", crf=23, scale=426),
    "all-x264": dict(mode="all", enc="x264", fps=30, preset="veryfast", crf=23),
}


def cmd_cost(a):
    label = f"cost-{a.world}"
    out = OUT / f"{label}-{int(time.time())}"
    out.mkdir(parents=True, exist_ok=True)
    with session(label, world=a.world, rd=a.rd) as s:
        time.sleep(a.settle)
        s.C("clearChat")
        for rep in range(a.reps):
            for name in a.configs.split(","):
                cfg = CONFIGS[name]
                if cfg and cfg["enc"] == "vt" and not MAC:
                    continue
                video = out / f"{name}-{rep}.mp4"
                f0, c0, t0 = s.C("stats"), proc_cpu(s.clientpid), time.time()
                rec = s.C("rec", path=str(video), **cfg) if cfg else None
                gpid = None
                time.sleep(a.seconds)
                f1, c1, t1 = s.C("stats"), proc_cpu(s.clientpid), time.time()
                fcpu = proc_cpu(rec["ffmpegPid"]) if rec and rec["ffmpegPid"] > 0 else None
                stop = s.C("recStop") if cfg else None
                span = (f1["at"] - f0["at"]) / 1e6
                row = {"kind": "cost", "label": label, "world": a.world, "rd": a.rd, "config": name, "rep": rep, "fps": round((f1["frame"] - f0["frame"]) / span, 1),
                       "client_cpu_pct": round((c1 - c0) / (t1 - t0) * 100)}
                if stop:
                    wall = (stop["t1"] - stop["t0"]) / 1e6
                    row.update({"w": rec["w"], "h": rec["h"], "captured": stop["captured"], "captured_per_s": round(stop["captured"] / wall, 1), "dups": stop["dups"],
                                "dropped": stop["droppedBusy"] + stop["droppedPool"], "issue_us": round(stop["issueUsPerCapture"], 1), "callback_us": round(stop["callbackUsPerCapture"], 1),
                                "render_thread_ms_per_capture": round((stop["issueUsPerCapture"] + stop["callbackUsPerCapture"]) / 1000, 3),
                                "pipe_mb_per_s": round(stop["bytes"] / wall / 1e6, 1), "encode_tail_ms": stop["encodeTailMs"], "exit": stop["exit"], "writer_error": stop["writerError"]})
                    if fcpu is not None and stop["exit"] == 0:
                        row["ffmpeg_cpu_pct"] = round(fcpu / (t1 - t0) * 100)
                    if video.exists() and cfg["enc"] != "null":
                        row["file_bytes"] = video.stat().st_size
                        row["kb_per_s"] = round(video.stat().st_size / wall / 1024, 1)
                        row["probe"] = probe_video(video)
                record(row)
        if a.keep_frame:
            # one frame from the x264 video for a look at full size
            for name in a.configs.split(","):
                v = out / f"{name}-0.mp4"
                if v.exists() and "x264" in name:
                    still(v, 30, 30, out / f"{name}-frame30.png")
    record({"kind": "cost_end", "label": label, "out": str(out), "leaks": leak_check()})


# ---------- requirements: gated verdicts against a recorded demo run ----------

def requirement(s, i, late=0, broken_every=20):
    kind = KINDS[i % 4]
    token = f"V{i}x{s.round_id}"
    material = MATERIALS[i % len(MATERIALS)]
    broken = (i + 1) % broken_every == 0
    return kind, token, material, broken


def run_reqs(s, n, ping_base, demo=None, linger=0.0, grab=None, pre=0.0):
    rows = []
    for i in range(n):
        kind, token, material, broken = requirement(s, i)
        act_ping, end_ping = ping_base + 2 * i, ping_base + 2 * i + 1
        if pre:
            time.sleep(pre)  # demo only: the last cleanup is drawn a few frames after the facts say clean
        m0 = s.C("mark") if demo else None
        t0 = time.perf_counter()
        act = s.S("act", player=s.p, kind=kind, token=token, material=material, broken="1" if broken else "0", ping=act_ping)
        obs = s.C("observe", needle=needle_for(kind, token, material), ping=act_ping, timeoutMs=2000)
        t1 = time.perf_counter()
        if linger:
            time.sleep(linger)
        m1 = s.C("mark") if demo else None
        s.S("reset", player=s.p, ping=end_ping)
        s.C("clearChat")
        st = s.C("state", ping=end_ping)
        left = leftovers(st["p"])
        rows.append({"i": i, "kind": kind, "broken": broken, "verdict": obs["ok"], "why": obs["why"], "frame": obs["frame"], "tick": obs["tick"], "obs_at": obs["at"],
                     "sent": act["sentMicros"], "s": t1 - t0, "dirty": bool(left), "m0": m0, "m1": m1})
    return rows


def analyse_sync(video, side, rows, w, h, fps, grab_start=None, fact_vs=None):
    """For each requirement: first video frame whose pixels differ from the frame at its start, against
    the video frame the facts name. With x11grab there is no sidecar, so the fact time maps through
    ffmpeg's first frame time."""
    import numpy as np
    spans = [(r["m0"]["slot"] if not grab_start else int((r["m0"]["at"] / 1e6 - grab_start) * fps), r["m1"]["slot"] if not grab_start else int((r["m1"]["at"] / 1e6 - grab_start) * fps), r) for r in rows]
    out = []
    it = enumerate(frames(video, w, h))
    cur = next(it, None)
    for v0, v1, r in spans:
        base = None
        first = None
        changed_max = 0
        while cur is not None and cur[0] < v1:
            v, img = cur
            # base is the last frame drawn before the mark: the mark's slot is a frame not yet drawn
            if v == v0 - 1 or (v0 == 0 and v == 0):
                base = img
            elif v >= v0 and base is not None:
                if True:
                    d = (np.abs(img - base).max(axis=2) > 40).sum()
                    changed_max = max(changed_max, int(d))
                    if first is None and d > 60:
                        first = v
            cur = next(it, None)
        if fact_vs is not None:
            fact_v = fact_vs[len(out)]
        elif grab_start:
            fact_v = int((r["obs_at"] / 1e6 - grab_start) * fps) if r["verdict"] else None
        else:
            fact_v = v_of_frame(side, r["frame"]) if r["verdict"] else None
        out.append({"i": r["i"], "kind": r["kind"], "broken": r["broken"], "verdict": r["verdict"], "span": [v0, v1], "pixel_first_v": first, "fact_v": fact_v,
                    "off": (first - fact_v) if (first is not None and fact_v is not None) else None, "changed_max": changed_max,
                    "fail_v": v_of_frame(side, r["frame"]) if (not r["verdict"] and side and r["frame"] is not None) else None})
    return out


def cmd_reanalyse(a):
    """Re-reads a reqs run's video with the current analysis, from its sync.json spans."""
    d = pathlib.Path(a.dir)
    video = d / ("demo-x11.mp4" if (d / "demo-x11.mp4").exists() else "demo.mp4")
    old = json.loads((d / "sync.json").read_text())
    side = sidecar(video)
    vp = probe_video(video)
    fps = round(eval(vp["rate"]))
    rows = [{"i": x["i"], "kind": x["kind"], "broken": x["broken"], "verdict": x["verdict"], "m0": {"slot": x["span"][0]}, "m1": {"slot": x["span"][1]}, "frame": None, "fact_v": x["fact_v"]} for x in old]
    sync = analyse_sync(video, side, rows, vp["w"], vp["h"], fps, fact_vs=[x["fact_v"] for x in old])
    offs = [x["off"] for x in sync if x["off"] is not None]
    by_kind = {}
    for x in sync:
        if x["off"] is not None:
            by_kind.setdefault(x["kind"], []).append(x["off"])
    agree = sum(1 for x in sync if (x["pixel_first_v"] is not None) == x["verdict"])
    (d / "sync2.json").write_text(json.dumps(sync))
    record({"kind": "reanalyse", "dir": str(d), "pixel_verdict_agree": f"{agree}/{len(sync)}", "sync_off_counts": {str(k): offs.count(k) for k in sorted(set(offs))},
            "sync_by_kind": {k: {str(o): v.count(o) for o in sorted(set(v))} for k, v in by_kind.items()}})


def cmd_reqs(a):
    label = f"reqs-{a.mode}-rate{a.rate}" + (f"-pre{a.pre}" if a.pre else "") + (f"-cap{a.cap}" if a.cap else "") + (f"-{a.grab}" if a.grab else "")
    out = OUT / f"{label}-{int(time.time())}"
    out.mkdir(parents=True, exist_ok=True)
    with session(label, rd=a.rd) as s:
        s.round_id = 0
        if a.rate != 20:
            s.S("tickrate", player=s.p, rate=a.rate)
        time.sleep(a.settle)
        s.C("clearChat")
        # 1. gated, as the suite would run
        s.C("gate", mode=2, parkMicros=2000)
        g0 = time.time()
        gated = run_reqs(s, a.n, 100000)
        g_wall = time.time() - g0
        s.C("gate", mode=0)
        time.sleep(0.5)
        if a.cap:
            s.C("fps", limit=a.cap)
        # 2. the same requirements again, rendered and recorded
        video = out / "demo.mp4"
        grab = None
        if a.grab:
            grab = GRAB(s, out / "demo-x11.mp4", a.fps)
            time.sleep(1.0)
        rec = s.C("rec", path=str(video), mode=a.mode, enc="x264", fps=a.fps, preset="veryfast", crf=23, speed=a.rate / 20) if not a.grab else None
        c0, d0 = proc_cpu(s.clientpid), time.time()
        demo = run_reqs(s, a.n, 200000, demo=True, linger=a.linger, pre=a.pre)
        d_wall = time.time() - d0
        c1 = proc_cpu(s.clientpid)
        if grab:
            # marks still come from the mod; they carry wall time for the x11 mapping
            time.sleep(0.5)
            gstat = grab.stop()
            video = out / "demo-x11.mp4"
            stop = None
        else:
            stop = s.C("recStop")
    side = sidecar(video) if not a.grab else []
    match = sum(1 for g, d in zip(gated, demo) if g["verdict"] == d["verdict"])
    wrong = lambda rows: sum(1 for r in rows if r["verdict"] == r["broken"])
    vp = probe_video(video)
    w, h = vp.get("w", 854), vp.get("h", 480)
    sync = analyse_sync(video, side, demo, w, h, a.fps, grab_start=gstat["start"] if a.grab else None)
    offs = [x["off"] for x in sync if x["off"] is not None]
    by_kind = {}
    for x in sync:
        if x["off"] is not None:
            by_kind.setdefault(x["kind"], []).append(x["off"])
    pixel_verdict_agree = sum(1 for x in sync if (x["pixel_first_v"] is not None) == x["verdict"])
    # clips: one passing title, one failing requirement, plus the whole run as one preview
    clips = {}
    for x in sync:
        r = demo[x["i"]]
        tag = None
        if x["kind"] == "title" and x["verdict"] and "pass_title" not in clips:
            tag = "pass_title"
        elif not x["verdict"] and "fail" not in clips:
            tag = "fail"
        if tag:
            clips[tag] = {"i": x["i"], **cut(video, x["span"][0], x["span"][1], a.fps, out / f"{tag}.mp4", out / f"{tag}.webp")}
            if x.get("fail_v") is not None:
                clips[tag]["fail_frame"] = still(video, x["fail_v"], a.fps, out / "fail-frame.png")
            if x.get("fact_v") is not None:
                clips[tag]["fact_frame"] = still(video, x["fact_v"], a.fps, out / f"{tag}-fact-frame.png")
                if x["fact_v"] > 0:
                    still(video, x["fact_v"] - 1, a.fps, out / f"{tag}-fact-frame-minus1.png")
    whole = cut(video, 0, vp.get("frames", 0), a.fps, out / "whole.mp4", out / "whole.webp") if vp.get("frames") else None
    row = {"kind": "reqs", "label": label, "mode": a.mode, "rate": a.rate, "cap": a.cap, "grab": a.grab, "n": a.n, "fps_out": a.fps,
           "gated_wall_s": round(g_wall, 2), "gated_per_req_s": stat([r["s"] for r in gated]), "demo_wall_s": round(d_wall, 2), "demo_per_req_s": stat([r["s"] for r in demo]),
           "verdicts_equal": f"{match}/{a.n}", "wrong_gated": wrong(gated), "wrong_demo": wrong(demo), "dirty_gated": sum(r["dirty"] for r in gated), "dirty_demo": sum(r["dirty"] for r in demo),
           "pixel_verdict_agree": f"{pixel_verdict_agree}/{a.n}", "sync_off_frames": stat(offs) if offs else None, "sync_off_counts": {str(k): offs.count(k) for k in sorted(set(offs))},
           "sync_by_kind": {k: {str(o): v.count(o) for o in sorted(set(v))} for k, v in by_kind.items()},
           "client_cpu_pct_demo": round((c1 - c0) / d_wall * 100), "video": vp, "video_bytes": video.stat().st_size if video.exists() else 0,
           "rec": stop, "clips": clips, "whole": whole, "out": str(out), "mismatch": [x for x in sync if x["off"] not in (0, None) or (x["pixel_first_v"] is not None) != x["verdict"]][:8]}
    if a.grab:
        row["grab"] = gstat
    (out / "sync.json").write_text(json.dumps(sync))
    record(row)
    record({"kind": "reqs_end", "label": label, "leaks": leak_check()})


# ---------- B4: fixed timestep against real time at a slow renderer ----------

def cmd_step(a):
    """Title 10/40/10 and an interpolated move, recorded in real time and in step mode, with the renderer
    capped to emulate a slow software renderer. Counts video frames the title is up and how evenly the
    moving text advances per video frame."""
    import numpy as np
    out = OUT / f"step-{int(time.time())}"
    out.mkdir(parents=True, exist_ok=True)
    cases = [(c.split(":")[0], int(c.split(":")[1]), int(c.split(":")[2])) for c in a.cases.split(",")]  # mode:rate:cap
    with session("step", rd=a.rd) as s:
        time.sleep(a.settle)
        s.C("clearChat")
        for rep in range(a.reps):
            for mode, rate, cap in cases:
                name = f"{mode}-rate{rate}-cap{cap}-{rep}"
                s.S("tickrate", player=s.p, rate=rate)
                s.C("fps", limit=cap if cap else 260)
                time.sleep(0.5)
                video = out / f"{name}.mp4"
                st0 = s.S("status", player=s.p)
                m0 = s.C("mark")
                rec = s.C("rec", path=str(video), mode=mode, enc="x264", fps=a.fps, preset="veryfast", crf=20, speed=rate / 20)
                game = lambda ticks: ticks / rate  # real seconds for game ticks at this rate
                time.sleep(game(4))
                mt = s.C("mark")
                s.S("title", _dispatch="tick", player=s.p, text="STEP", sub=name, **{"in": 10, "stay": 40, "out": 10})
                time.sleep(game(70))
                mm = s.C("mark")
                mv = s.S("moveDisplay", _dispatch="tick", player=s.p, token="MOVING", duration=20, distance=6, after=10)
                time.sleep(game(50))
                m1 = s.C("mark")
                stop = s.C("recStop")
                st1 = s.S("status", player=s.p)
                s.S("reset", player=s.p, full=1)
                time.sleep(0.3)
                side = sidecar(video)
                vp = probe_video(video)
                w, h = vp["w"], vp["h"]
                # title frames: centre band differs from the pre title frame
                imgs = list(frames(video, w, h))
                ft = mt["slot"]
                ref = imgs[min(ft, len(imgs) - 1)]
                hh, ww = ref.shape[:2]
                band = (slice(int(hh * 0.30), int(hh * 0.50)), slice(int(ww * 0.25), int(ww * 0.75)))
                title_frames = [v for v in range(ft, min(mm["slot"], len(imgs))) if (np.abs(imgs[v][band] - ref[band]).max(axis=2) > 40).sum() > 30]
                # move: x centroid of changed pixels against the frame before the move, per video frame
                fm = mm["slot"]
                ref2 = imgs[min(fm, len(imgs) - 1)]
                xs = []
                for v in range(fm, min(m1["slot"], len(imgs))):
                    d = np.abs(imgs[v] - ref2).max(axis=2) > 40
                    d[: int(hh * 0.2)] = False  # ignore the very top
                    cols = np.nonzero(d.sum(axis=0) > 0)[0]
                    xs.append(float(cols.mean()) if len(cols) > 20 else None)
                moving = [x for x in xs if x is not None]
                dx = [b - a_ for a_, b in zip(xs, xs[1:]) if a_ is not None and b is not None]
                active = [d for d in dx if abs(d) > 0.05]
                still_in_move = 0
                if moving:
                    # frames inside the move where nothing moved: the jerk a viewer sees
                    first = next(i for i, x in enumerate(xs) if x is not None)
                    end = max(i for i, d in enumerate(dx) if abs(d) > 0.05) if active else first
                    still_in_move = sum(1 for d in dx[first:end] if abs(d) <= 0.05)
                    span_frames = end - first
                else:
                    span_frames = 0
                dups = sum(1 for r in side if r.get("dup"))
                row = {"kind": "step", "case": name, "mode": mode, "rate": rate, "cap": cap, "fps_out": a.fps, "video": vp, "frames_written": len(side), "dup_frames": dups,
                       "title_frames": len(title_frames), "title_expected_frames": round(60 / 20 * a.fps), "move_frames": span_frames, "move_expected_frames": round(20 / 20 * a.fps),
                       "move_still_frames": still_in_move, "move_dx_median": round(statistics.median([abs(d) for d in active]), 2) if active else None,
                       "move_dx_cv": round(statistics.pstdev([abs(d) for d in active]) / statistics.mean([abs(d) for d in active]), 2) if len(active) > 2 else None,
                       "client_ticks": m1["tick"] - m0["tick"], "server_ticks": st1["tick"] - st0["tick"], "real_s": round((m1["at"] - m0["at"]) / 1e6, 2),
                       "step_lag_frames": stop["stepLagFrames"], "step_max_lag_ms": stop["stepMaxLagMs"], "captured": stop["captured"], "skipped": stop["skippedSlots"]}
                if rep == 0:
                    for tag, v in (("title", title_frames[len(title_frames) // 2] if title_frames else None), ("move", fm + len(xs) // 2)):
                        if v is not None and v < len(imgs):
                            still(video, v, a.fps, out / f"{name}-{tag}.png")
                    cut(video, 0, len(imgs), a.fps, out / f"{name}-clip.mp4", out / f"{name}.webp")
                record(row)
        s.S("tickrate", player=s.p, rate=20)
    record({"kind": "step_end", "out": str(out), "leaks": leak_check()})


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    c = sub.add_parser("cost")
    c.add_argument("--world", default="void")
    c.add_argument("--rd", type=int, default=2)
    c.add_argument("--seconds", type=float, default=8)
    c.add_argument("--settle", type=float, default=9)
    c.add_argument("--reps", type=int, default=1)
    c.add_argument("--configs", default="none,all-null,rt30-null,rt30-x264,rt30-x264uf,rt60-x264,rt30-x264-half,rt30-vt,all-x264")
    c.add_argument("--keep-frame", action="store_true")
    r = sub.add_parser("reqs")
    r.add_argument("--n", type=int, default=40)
    r.add_argument("--mode", default="rt")
    r.add_argument("--rate", type=int, default=20)
    r.add_argument("--cap", type=int, default=0)
    r.add_argument("--fps", type=int, default=30)
    r.add_argument("--rd", type=int, default=2)
    r.add_argument("--linger", type=float, default=0.6)
    r.add_argument("--settle", type=float, default=9)
    r.add_argument("--grab", default=None)
    r.add_argument("--pre", type=float, default=0.15)
    t = sub.add_parser("step")
    t.add_argument("--cases", default="rt:20:0,rt:20:20,step:20:20,step:10:20")
    t.add_argument("--fps", type=int, default=30)
    t.add_argument("--rd", type=int, default=2)
    t.add_argument("--reps", type=int, default=1)
    t.add_argument("--settle", type=float, default=9)
    ra = sub.add_parser("reanalyse")
    ra.add_argument("dir")
    a = ap.parse_args()
    {"cost": cmd_cost, "reqs": cmd_reqs, "step": cmd_step, "reanalyse": cmd_reanalyse}[a.cmd](a)


if __name__ == "__main__":
    main()
