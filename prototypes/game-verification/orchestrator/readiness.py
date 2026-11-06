#!/usr/bin/env python3
"""Spike E: when is a client ready, a scene arranged, a requirement done.

  readiness.py scenes [--mode gated|rendered] [--n 200] [--only now,late1] [--label mac]
  readiness.py start  [--kind swap|reconnect|reset|fresh] [--world void|terrain] [--n 100] [--label mac]
  readiness.py report [--runs runs/e-readiness.jsonl]

Every repeat records one client trace (each loop's facts, barrier acks, drawn state and frame hash) while the
plugin sends the effect and three barriers: right after the command (E1), after the declared window (E1w, also
what closes E3t), and once the plugin is quiet (E4). Each signal is judged afterwards on that same trace, so
the signals see exactly the same events. The client launches through speed.Session (direct java, silent
options, zero volume asserted).
"""
import argparse, gzip, json, os, pathlib, random, statistics, sys, time

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import speed
from run import RUNS, leak_check

RESULTS = RUNS / "e-readiness.jsonl"
TRACES = RUNS / "e-readiness"

HELD, VIEW, TITLE_IN, DRAWN, LEVEL, SCREEN_NONE, CHUNKS, FEET, SETTLED, QUEUE_EMPTY, TOASTS_NONE, MESHED, HANDS = (1 << i for i in range(13))
MATERIALS = ["DIAMOND_BLOCK", "GOLD_BLOCK", "EMERALD_BLOCK", "REDSTONE_BLOCK", "LAPIS_BLOCK", "IRON_BLOCK"]
REGION_A, REGION_B = 4096, 8192

# w: the window the requirement declares, in ticks. truth: the fact bit that says "seen" (gated). e2: what the
# client reports as drawn. pix: "app" = the thing appears (half its final pixels), "any" = any part of it shows,
# "eq" = the frame equals the final one (and the final one is not a clean frame).
SCENES = {
    "now": dict(w=2, truth=HELD, e2=DRAWN, pix="app", spec="chat"),
    "late1": dict(w=3, truth=HELD, e2=DRAWN, pix="app", spec="chat"),
    "late2": dict(w=4, truth=HELD, e2=DRAWN, pix="app", spec="chat"),
    "async": dict(w=4, truth=HELD, e2=DRAWN, pix="app", spec="chat"),
    "section": dict(w=2, truth=HELD, e2=MESHED, pix="app", spec="section"),
    "walk": dict(w=15, truth=VIEW, e2=DRAWN, pix="any", spec="walk"),
    "title": dict(w=12, truth=TITLE_IN, e2=DRAWN, pix="eq", spec="title"),
    "clientlag": dict(w=2, truth=HELD, e2=DRAWN, pix="app", spec="chat", lag=400),
    "serverlag": dict(w=3, truth=HELD, e2=DRAWN, pix="app", spec="chat", lag=400),
    "chunk": dict(w=20, truth=HELD, e2=MESHED, pix="eq", spec="chunk"),
}
SIGNALS = ["E1", "E1w", "E3t", "E3ms", "E4"]


def record(row):
    RUNS.mkdir(exist_ok=True)
    row = {"at": time.strftime("%Y-%m-%dT%H:%M:%S"), "load": round(os.getloadavg()[0], 1), **row}
    with RESULTS.open("a") as f:
        f.write(json.dumps(row) + "\n")
    print(json.dumps(row)[:600], flush=True)


def session(label, rd=2):
    s = speed.Session(label, dispatch="tick", rd=rd)
    s.client.window_clear = "0x2000"  # true 854x480 framebuffer on a high density screen
    return s


SESSION = session  # ci.py replaces this with one that runs under Xvfb on the runner's renderer


class Pings:
    """Barrier ids never repeat on a connection (spike H)."""

    def __init__(self):
        self.next = 2_000_000 + random.randrange(1000) * 10_000

    def block(self, n=10):
        b = self.next
        self.next += n
        return b


def prep(s, gate):
    S, C, p = s.S, s.C, s.p
    S("gprep", player=p)  # spend advancement and recipe toasts once
    S("e.home", player=p)
    S("e.calm", player=p)
    C("g.knobs", vignette=0, bob=0, flicker=1, glint=0, hud=1)
    time.sleep(3)
    C("g.knobs", hud=1)
    C("gate", mode=gate)


def barrier(s, pings):
    b = pings.block(1)
    s.S("noop", player=s.p, ping=b)
    s.C("state", ping=b, timeoutMs=10000)


def watch_args(sc, token, material, region):
    spec = sc["spec"]
    if spec == "chat":
        return dict(needles=f'"chat":["{token}"', chat=token)
    if spec == "section":
        return dict(block="0,66,18", material=f"minecraft:{material.lower()}")
    if spec == "walk":
        return dict(ent=token)
    if spec == "title":
        return dict(title=token)
    if spec == "chunk":
        return dict(block=f"{region + 2},65,2", material=f"minecraft:{material.lower()}")
    raise ValueError(spec)


def repeat(s, name, sc, i, pings, pix, region, tail=0.15):
    S, C, p = s.S, s.C, s.p
    token = f"E{name}{i}r{random.randrange(10**6)}"
    material = MATERIALS[i % len(MATERIALS)]
    broken = i % 10 == 9
    base = pings.block(10)
    C("r.watch", pix=int(pix), radius=2, **watch_args(sc, token, material, region))
    if name == "clientlag":
        C("r.lag", ms=sc["lag"])
    sent = time.time() * 1e6
    r = S("e.scene", player=p, kind=name, token=token, broken=int(broken), base=base, w=sc["w"], material=material, lagMs=sc.get("lag", 0))
    waited = C("r.wait", ids=f"{base + 1},{base + 2},{base + 3}", timeoutMs=20000)
    time.sleep(tail)
    tr = C("r.stop", pingFrom=base)
    info = S("e.info", player=p, token=token)
    S("e.clean", player=p, kind=name)
    C("clearChat")
    barrier(s, pings)
    return dict(token=token, broken=broken, base=base, sent_rel=sent - tr["start"], cmd_rel=r["sentMicros"] - tr["start"],
                effect_rel=(info["effectMicros"] - tr["start"]) if info.get("effectMicros", -1) > 0 else None,
                quiet=info.get("quietMicros"), quiet_polls=info.get("quietPolls"), quiet_timeout=info.get("quietTimeout"), wait_ok=waited["ok"], trace=tr)


# ---------- judging one trace ----------

def first_row(rows, bit, after_loop=-1):
    for r in rows:
        if r[0] >= after_loop and (r[4] & bit) == bit:
            return r
    return None


def row_at(rows, loop):
    """The row of the loop that handled a barrier: its facts already include everything before the barrier."""
    for r in rows:
        if r[0] >= loop:
            return r
    return None


def ack(trace, pid):
    """Exact id: the quiet barrier often arrives before the window barrier, so a later id proves nothing here."""
    for a in trace["acks"]:
        if a[0] == pid:
            return a
    return None


def judge(rep, sc, mode):
    tr = rep["trace"]
    rows, pix = tr["rows"], tr["pix"]
    base, broken, W = rep["base"], rep["broken"], sc["w"]
    bit = sc["truth"]
    truth = first_row(rows, bit)
    t_at = truth[1] if truth else None
    zero = rep["cmd_rel"]
    out = {"broken": broken, "truth_ms": None if t_at is None else round((t_at - zero) / 1000, 2)}
    if not broken and truth is None:
        out["no_truth"] = True
    acks = {k: ack(tr, base + n) for k, n in (("E1", 1), ("E1w", 2), ("E4", 3))}
    out["missing_ack"] = [k for k, v in acks.items() if v is None]
    # Last moment anything perceivable changed: the requirement is only done after it.
    last_change = None
    for a, b in zip(rows, rows[1:]):
        if a[5] != b[5]:
            last_change = b
    verdict = {}
    FACTS = HELD | VIEW | TITLE_IN
    for n_ticks in (1, 2):
        # E5: the quiet barrier, then nothing perceivable (state and requirement facts) changes for n client ticks.
        a = acks["E4"]
        if a is None:
            continue
        last = None
        hit = None
        for r in rows:
            key = (r[5], r[4] & FACTS)
            if last is None or key != last[0]:
                last = (key, r[2])
            if r[0] >= a[1] and r[2] - last[1] >= n_ticks:
                hit = r
                break
        if hit is None:
            continue
        ok = (hit[4] & bit) == bit
        v = {"ok": ok, "wrong": ok == broken, "decide_ms": round((hit[1] - zero) / 1000, 2), "loop": hit[0]}
        if ok and not broken and t_at is not None:
            v["wasted_ms"] = round(max(0, hit[1] - t_at) / 1000, 2)
        if last_change is not None:
            v["changed_after"] = last_change[0] > hit[0]
            v["changed_after_ms"] = round(max(0, last_change[1] - hit[1]) / 1000, 2)
        verdict[f"E5t{n_ticks}"] = v
    # E6: the quiet barrier, then the client reports nothing of its own in flight: radius chunks held, no title fading
    # in, and no perceivable state still moving from one loop to the next (interpolation).
    a = acks["E4"]
    if a is not None:
        prev = None
        hit = None
        for r in rows:
            fading = sc["spec"] == "title" and (r[4] & HELD) and not (r[4] & TITLE_IN)
            if r[0] >= a[1] and (r[4] & CHUNKS) and not fading and prev is not None and prev[5] == r[5]:
                hit = r
                break
            prev = r
        if hit is not None:
            ok = (hit[4] & bit) == bit
            v = {"ok": ok, "wrong": ok == broken, "decide_ms": round((hit[1] - zero) / 1000, 2), "loop": hit[0]}
            if ok and not broken and t_at is not None:
                v["wasted_ms"] = round(max(0, hit[1] - t_at) / 1000, 2)
            if last_change is not None:
                v["changed_after"] = last_change[0] > hit[0]
                v["changed_after_ms"] = round(max(0, last_change[1] - hit[1]) / 1000, 2)
            verdict["E6"] = v
    for sig in SIGNALS:
        if sig in ("E1", "E1w", "E4"):
            a = acks[sig]
            if a is None:
                continue
            r = row_at(rows, a[1])
            ok = r is not None and (r[4] & bit) == bit
            at = a[2]
            loop = a[1]
        elif sig == "E3t":
            a = acks["E1w"]
            if a is None:
                continue
            if truth is not None and truth[0] <= a[1]:
                ok, at, loop = True, truth[1], truth[0]
            else:
                ok, at, loop = False, a[2], a[1]
        else:  # E3ms: the same poll, closed by wall clock instead of a barrier
            deadline = rep["cmd_rel"] + W * 50_000
            if truth is not None and truth[1] <= deadline:
                ok, at, loop = True, truth[1], truth[0]
            else:
                ok, at, loop = False, deadline, None
        wrong = ok == broken
        v = {"ok": ok, "wrong": wrong, "decide_ms": round((at - zero) / 1000, 2)}
        if ok and not broken and t_at is not None:
            v["wasted_ms"] = round(max(0, at - t_at) / 1000, 2)
        if last_change is not None and loop is not None:
            v["changed_after"] = last_change[0] > loop
            v["changed_after_ms"] = round(max(0, last_change[1] - at) / 1000, 2)
        v["loop"] = loop
        verdict[sig] = v
    if mode == "rendered":
        pixel_truth(rep, sc, out, verdict, rows, pix)
    for v in verdict.values():
        v.pop("loop", None)
    out["v"] = verdict
    return out


def pix_final(rep):
    pix = rep["trace"]["pix"]
    return pix[-1] if pix else None


CLEAN = {}  # scene -> final frame hashes of broken repeats: what the place looks like without the effect


def pix_ok(row, fin, sc):
    """The pixel check a requirement would make on this frame: the thing is shown (eq: the frame is the final one)."""
    if row is None or fin is None or fin[1] < 30:
        return False
    if sc["pix"] == "eq":
        return row[2] == fin[2] and fin[2] not in CLEAN.get(sc["spec"], ())
    if sc["pix"] == "any":
        return row[1] >= 30
    return row[1] >= fin[1] / 2


def learn_clean(sc, reps):
    CLEAN[sc["spec"]] = {r["trace"]["pix"][-1][2] for r in reps if r["broken"] and r["trace"]["pix"]}


def pix_from(pix, loop):
    for x in pix:
        if x[0] >= loop:
            return x
    return None


def loop_at_time(rows, at):
    for r in rows:
        if r[1] >= at:
            return r[0]
    return None


# Pixel recipes: what a requirement does after its fact signal before it reads a frame.
RECIPES = ["f1", "f2", "f3", "stable", "obj", "objq"]


def recipe_frame(name, sc, rows, pix, after_loop):
    """The frame a pixel check would read when it starts at after_loop."""
    drawn = [r for r in rows if r[3] == 1 and r[0] >= after_loop]
    if name in ("f1", "f2", "f3"):
        k = int(name[1])
        return pix_from(pix, drawn[k - 1][0]) if len(drawn) >= k else None
    if name == "stable":
        # F's render barrier: two frames with the same hash, the second a client tick after the first.
        tick = {r[0]: r[2] for r in rows}
        px = [x for x in pix if x[0] >= after_loop]
        for i, a in enumerate(px):
            for b in px[i + 1:]:
                if tick.get(b[0], 0) > tick.get(a[0], 0):
                    if b[2] == a[2]:
                        return b
                    break
        return None
    bit = sc["e2"]
    need = bit | (QUEUE_EMPTY | CHUNKS if name == "objq" else 0)
    hit = None
    for r in drawn:
        if (r[4] & need) == need:
            hit = r
            break
    if hit is None:
        return None
    if bit & MESHED:
        # The mesh is swapped in during the frame that still drew the old one: read the next frame.
        nxt = [r for r in drawn if r[0] > hit[0]]
        return pix_from(pix, nxt[0][0]) if nxt else None
    return pix_from(pix, hit[0])


def pixel_truth(rep, sc, out, verdict, rows, pix):
    """Rendered: first frame from which the thing stays shown; each fact signal's pixel check is the frame drawn at
    or after it; each recipe adds a render barrier after the fact signal before reading the frame."""
    at_of = {r[0]: r[1] for r in rows}
    fin = pix_final(rep)
    out["final_px"] = fin[1] if fin else None
    first = None
    for i, x in enumerate(pix):
        if pix_ok(x, fin, sc) and all(pix_ok(y, fin, sc) for y in pix[i:]):
            first = x
            break
    zero = rep["cmd_rel"]
    out["pix_truth_ms"] = round((at_of.get(first[0], 0) - zero) / 1000, 2) if first else None
    if not rep["broken"] and first is None:
        out["no_pix_truth"] = True
        return
    drawn_loops = [r[0] for r in rows if r[3] == 1]

    def judge_frame(x):
        ok = pix_ok(x, fin, sc)
        v = {"pix_ok": ok, "pix_wrong": ok == rep["broken"]}
        if x is not None:
            v["pix_decide_ms"] = round((at_of.get(x[0], 0) - zero) / 1000, 2)
            if ok and first is not None:
                v["pix_wasted_ms"] = round(max(0, at_of.get(x[0], 0) - at_of.get(first[0], 0)) / 1000, 2)
                v["frames_late"] = sum(1 for l in drawn_loops if first[0] <= l < x[0])
            elif first is not None:
                v["frames_early"] = sum(1 for l in drawn_loops if x[0] <= l < first[0])
        return v

    for sig, v in list(verdict.items()):
        if "+" in sig:
            continue
        loop = v.pop("loop", None)
        if loop is None and v.get("decide_ms") is not None:
            loop = loop_at_time(rows, zero + v["decide_ms"] * 1000)
        v.update(judge_frame(pix_from(pix, loop) if loop is not None else None))
        if sig in ("E3t", "E4", "E5t1", "E5t2", "E6") and loop is not None:
            for rc in RECIPES:
                verdict.setdefault(f"{sig}+{rc}", {}).update(judge_frame(recipe_frame(rc, sc, rows, pix, loop)))
    for rc in ("obj", "objq"):
        verdict[f"E2{rc}"] = judge_frame(recipe_frame(rc, sc, rows, pix, 0))
    verdict["E3pix"] = {"pix_ok": first is not None, "pix_wrong": (first is not None) == rep["broken"], "pix_wasted_ms": 0.0 if first else None,
                        "pix_decide_ms": out["pix_truth_ms"]}


# ---------- commands ----------

def cmd_scenes(a):
    gate = 2 if a.mode == "gated" else 0
    names = a.only.split(",") if a.only else list(SCENES)
    if "chunk" in names:
        names = [n for n in names if n != "chunk"] + ["chunk"]
    TRACES.mkdir(parents=True, exist_ok=True)
    with SESSION(f"e-{a.label}-{a.mode}") as s:
        pings = Pings()
        prep(s, gate)
        meta = {"label": a.label, "mode": a.mode, "renderer": s.client.events().get("renderer")}
        if gate == 0:
            ref = s.C("r.ref", frames=10)
            meta["ref"] = ref
        for name in names:
            sc = SCENES[name]
            t0 = time.time()
            reps, judged = [], []
            region = 0
            if name == "chunk":
                pass
            for i in range(a.n):
                if name == "chunk":
                    region = REGION_B if region == REGION_A else REGION_A
                reps.append(repeat(s, name, sc, i, pings, gate == 0, region))
            if name == "chunk":
                s.S("e.clean", player=s.p, kind=name, to="home")
                barrier(s, pings)
                time.sleep(1)
            path = TRACES / f"{a.label}-{a.mode}-{name}-{int(time.time())}.jsonl.gz"
            with gzip.open(path, "wt") as f:
                for rep in reps:
                    f.write(json.dumps(rep) + "\n")
            secs = round(time.time() - t0, 1)
            try:
                learn_clean(sc, reps)
                judged = [judge(rep, sc, a.mode) for rep in reps]
                summary = summarize(judged, a.mode)
            except Exception as e:  # the traces are saved; rejudge later
                summary = {"judge_error": repr(e)}
            record({**meta, "kind": "scene", "scene": name, "n": a.n, "w": sc["w"], "secs": secs, "traces": str(path), **summary})
    leak_check()


def pctl(v, p):
    v = sorted(v)
    return v[min(len(v) - 1, int(round(p / 100 * (len(v) - 1))))] if v else None


def summarize(judged, mode):
    out = {"no_truth": sum(1 for j in judged if j.get("no_truth")), "no_pix_truth": sum(1 for j in judged if j.get("no_pix_truth")),
           "missing_ack": sum(1 for j in judged if j["missing_ack"]), "broken": sum(1 for j in judged if j["broken"])}
    sigs = []
    for j in judged:
        for k in j["v"]:
            if k not in sigs:
                sigs.append(k)
    for sig in sigs:
        vs = [j["v"][sig] for j in judged if sig in j["v"]]
        good = [v for v in vs if "wasted_ms" in v]
        row = {"n": len(vs), "wrong": sum(1 for v in vs if v.get("wrong")),
               "wrong_fail": sum(1 for v, j in zip(vs, judged) if v.get("wrong") and not j["broken"]),
               "decide_med": pctl([v["decide_ms"] for v in vs if v.get("decide_ms") is not None], 50),
               "decide_p95": pctl([v["decide_ms"] for v in vs if v.get("decide_ms") is not None], 95),
               "wasted_med": pctl([v["wasted_ms"] for v in good], 50), "wasted_p95": pctl([v["wasted_ms"] for v in good], 95),
               "changed_after": sum(1 for v in vs if v.get("changed_after")),
               "changed_after_ms_p95": pctl([v["changed_after_ms"] for v in vs if v.get("changed_after")], 95)}
        if mode == "rendered":
            row["pix_wrong"] = sum(1 for v in vs if v.get("pix_wrong"))
            pw = [v["pix_wasted_ms"] for v in vs if v.get("pix_wasted_ms") is not None]
            row["pix_wasted_med"], row["pix_wasted_p95"] = pctl(pw, 50), pctl(pw, 95)
            pd = [v["pix_decide_ms"] for v in vs if v.get("pix_decide_ms") is not None]
            row["pix_decide_med"], row["pix_decide_p95"] = pctl(pd, 50), pctl(pd, 95)
            fe = [v["frames_early"] for v in vs if v.get("frames_early") is not None]
            if fe:
                row["frames_early"] = {str(k): fe.count(k) for k in sorted(set(fe))}
        out[sig] = row
    return out


# ---------- start: when is a freshly joined, swapped or reset client ready ----------

# Start candidates as trace bits, plus combinations. "stable" (two equal frames a tick apart) is judged from frames.
START_BITS = {"join": LEVEL, "screen": LEVEL | SCREEN_NONE, "chunks": LEVEL | SCREEN_NONE | CHUNKS, "feet": LEVEL | SCREEN_NONE | FEET,
              "settled": LEVEL | SCREEN_NONE | SETTLED, "meshed": LEVEL | SCREEN_NONE | CHUNKS | QUEUE_EMPTY,
              "toasts": LEVEL | SCREEN_NONE | TOASTS_NONE, "meshed+toasts": LEVEL | SCREEN_NONE | CHUNKS | QUEUE_EMPTY | TOASTS_NONE,
              "hands": LEVEL | SCREEN_NONE | HANDS, "meshed+hands": LEVEL | SCREEN_NONE | CHUNKS | QUEUE_EMPTY | HANDS}
# What the orchestrator can wait for online (a needle in the client's facts), to start a fact test at that moment.
START_NEEDLE = {"join": '"relBlock"', "chunks": '"readyAt":"{dim}|{cx},{cz}"', "feet": '"compiledAt":"{dim}|{cx},{cz}"',
                "settled": '"settledAt":"{dim}|{cx},{cz}"'}


def start_session(label, world, rd):
    if world == "void":
        return SESSION(label, rd=rd)
    if SESSION is not session:
        return SESSION(label, rd=rd)  # ci.py: the world comes from its config
    import goldens
    return goldens.mac_session(label, world, rd)


def fresh_client(s):
    """Stops the session's client and starts a new process at the title screen (same ports, silent)."""
    from run import Client
    old = s.client
    old.stop()
    c = Client(old.dir, name=old.name, server=None, backend=old.backend, xmx=old.xmx, rd=old.rd, facts_mode=old.facts_mode,
               window_clear=old.window_clear, extra_jvm=old.extra_jvm, env=old.env, width=old.width, height=old.height)
    if hasattr(old, "facts") and old.facts.exists():
        old.facts.unlink()
    # The old client's stop file would stop the new process at once.
    old.stop_file.unlink(missing_ok=True)
    c.start()
    c.wait_event("load_finished", 120)
    c.wait_event("renderer", 10)
    r = c.events()["renderer"]
    assert r["master"] == 0.0 and r["music"] == 0.0, "client is not silent: " + str(r)
    s.client = c
    s.C = speed.Line(s.live)
    return c


def start_trial(s, kind, world, i, pings, fact_signal, at, tail):
    """One transition with a full trace. A fact test (fake block behind the player plus a barrier) starts the moment
    the orchestrator sees fact_signal; frames are judged afterwards against the settled final frame."""
    S, C, p = s.S, s.C, s.p
    material = MATERIALS[i % len(MATERIALS)]
    fx, fy, fz = at
    fact = f"{fx},{fy},{fz - 3}"
    if kind == "reset":
        # Leftovers of a previous requirement, drawn for a while, before the trace starts.
        S("dirty", player=p)
        C("observe", needle='"DIRTY-chat"', timeoutMs=5000)
        time.sleep(0.3)
    C("r.watch", pix=1, radius=s.client.rd, block=fact, material=f"minecraft:{material.lower()}", freeze=int(world != "void"), hud=1)
    t0 = time.time() * 1e6
    dim = "minecraft:overworld"
    if kind == "swap":
        r = S("poolSwap", player=p, idx=i + 1)
        dim = r["dim"]
    elif kind in ("reconnect", "fresh"):
        C("reconnect", addr=s.addr)
    elif kind == "reset":
        S("reset", player=p, full=1)
        C("clearChat")
    fb = pings.block(1)
    needle = START_NEEDLE.get(fact_signal, "").format(dim=dim, cx=fx >> 4, cz=fz >> 4)
    if kind == "swap" and fact_signal == "join":
        needle = f'"dim":"{dim}"'  # the old level also has a player; only the new dimension proves the join
    seen = None
    if kind == "reset":
        # A reset has no join: the test starts at the cleanup barrier.
        seen = {"ok": True}
    elif needle:
        seen = C("observe", needle=needle, timeoutMs=30000)
    S("block", player=p, x=fx, y=fy, z=fz - 3, material=material, fake=1, ping=fb)
    C("r.wait", ids=str(fb), timeoutMs=30000)
    time.sleep(tail)
    tr = C("r.stop", pingFrom=fb)
    S("reset", player=p)
    if kind == "reset":
        # The leftovers push the player; drift adds up over trials until the player falls off the platform.
        S("e.clean", player=p, kind="none", to="home")
    barrier(s, pings)
    return dict(kind=kind, world=world, fact_signal=fact_signal, seen=seen, fact_ping=fb, t0_rel=t0 - tr["start"], trace=tr)


def judge_start(rep):
    tr = rep["trace"]
    rows, pix = tr["rows"], tr["pix"]
    zero = rep["t0_rel"]
    at_of = {r[0]: r[1] for r in rows}
    tick = {r[0]: r[2] for r in rows}
    fin = pix[-1] if pix else None
    first = None
    for i, x in enumerate(pix):
        if all(y[2] == fin[2] for y in pix[i:]):
            first = x
            break
    out = {"kind": rep["kind"], "world": rep["world"], "truth_ms": round((at_of[first[0]] - zero) / 1000, 1) if first else None, "sig": {}}
    a = ack(tr, rep["fact_ping"])
    if a is not None:
        r = row_at(rows, a[1])
        out["fact_ok"] = r is not None and (r[4] & HELD) == HELD
        out["fact_signal"] = rep["fact_signal"]
    stable_after = None
    for name, need in START_BITS.items():
        hit = next((r for r in rows if r[1] >= zero and (r[4] & need) == need and (r[0] >= (rows[0][0]))), None)
        # A start signal must be new: for reconnect and fresh the level from before does not count.
        if rep["kind"] in ("reconnect", "fresh"):
            gone = next((r for r in rows if not (r[4] & LEVEL)), None)
            hit = next((r for r in rows if gone and r[0] > gone[0] and (r[4] & need) == need), None)
        if rep["kind"] == "swap":
            hit = next((r for r in rows if r[1] >= zero and (r[4] & need) == need and r[0] >= swap_loop(rows, zero)), None)
        if hit is None:
            out["sig"][name] = None
            continue
        x = next((y for y in pix if y[0] >= hit[0]), None)
        ok = x is not None and fin is not None and x[2] == fin[2]
        later = sum(1 for y in pix if first and hit[0] <= y[0] < first[0])
        out["sig"][name] = {"ms": round((hit[1] - zero) / 1000, 1), "frame_ok": ok, "frames_early": later if not ok else 0,
                            "wasted_ms": round((at_of[x[0]] - at_of[first[0]]) / 1000, 1) if ok and first else None}
    # The fact test's own barrier, sent right after the transition (reset) or at the signal the test waited for.
    if a is not None:
        x = next((y for y in pix if y[0] >= a[1]), None)
        ok = x is not None and fin is not None and x[2] == fin[2]
        out["sig"]["barrier"] = {"ms": round((a[2] - zero) / 1000, 1), "frame_ok": ok,
                                 "frames_early": sum(1 for y in pix if first and a[1] <= y[0] < first[0]) if not ok else 0,
                                 "wasted_ms": round((at_of[x[0]] - at_of[first[0]]) / 1000, 1) if ok and first else None}
    # Stable: first pair of equal frames a client tick apart, after the join (after the barrier for a reset).
    base = (out["sig"].get("screen") or {}).get("ms")
    if rep["kind"] == "reset":
        base = (out["sig"].get("barrier") or {}).get("ms")
    if base is not None:
        px = [y for y in pix if at_of.get(y[0], 0) - zero >= base * 1000]
        hit = None
        for k, a1 in enumerate(px):
            for b in px[k + 1:]:
                if tick.get(b[0], 0) > tick.get(a1[0], 0):
                    if b[2] == a1[2]:
                        hit = b
                    break
            if hit:
                break
        if hit:
            ok = hit[2] == fin[2]
            out["sig"]["stable"] = {"ms": round((at_of[hit[0]] - zero) / 1000, 1), "frame_ok": ok,
                                    "frames_early": sum(1 for y in pix if first and hit[0] <= y[0] < first[0]) if not ok else 0,
                                    "wasted_ms": round((at_of[hit[0]] - at_of[first[0]]) / 1000, 1) if ok and first else None}
        else:
            out["sig"]["stable"] = None
    return out


def swap_loop(rows, zero):
    """The swap is done when CHUNKS first drops (the client forgets the old level) or, failing that, at the start."""
    for r in rows:
        if r[1] >= zero and not (r[4] & CHUNKS):
            return r[0]
    return rows[0][0]


def cmd_start(a):
    TRACES.mkdir(parents=True, exist_ok=True)
    rd = a.rd or (2 if a.world == "void" else 5)
    with start_session(f"e-{a.label}-start", a.world, rd) as s:
        pings = Pings()
        s.C("r.opts")
        if a.world == "void":
            s.S("gprep", player=s.p)
            s.S("e.home", player=s.p)
            at = (0, 65, 0)
        else:
            s.S("gprep", player=s.p)
            r = s.S("gterrain", player=s.p, yaw=30, pitch=15)
            x, y, z = (int(v) for v in r["at"].split(","))
            at = (x, y - 1, z)
        if a.kind == "swap":
            s.S("poolInit", _dispatch="tick", n=8)
        s.S("e.calm", player=s.p)
        s.C("gate", mode=0)
        time.sleep(1)
        s.C("clearToasts")
        s.C("clearChat")
        time.sleep(2)
        s.C("r.ref", frames=3)
        meta = {"label": a.label, "kind": "start", "start": a.kind, "world": a.world, "rd": rd, "renderer": s.client.events().get("renderer")}
        reps, t0 = [], time.time()
        signals = [k for k in ("join", "chunks", "feet", "settled") if a.kind != "reset"] or ["reset"]
        for i in range(a.n):
            if a.kind == "fresh":
                fresh_client(s)
                s.C("r.opts")
                s.C("r.ref", frames=3)
            reps.append(start_trial(s, a.kind, a.world, i, pings, signals[i % len(signals)], at, a.tail))
        path = TRACES / f"{a.label}-start-{a.kind}-{a.world}-{int(time.time())}.jsonl.gz"
        with gzip.open(path, "wt") as f:
            for rep in reps:
                f.write(json.dumps(rep) + "\n")
        try:
            summary = summarize_start([judge_start(r) for r in reps])
        except Exception as e:
            summary = {"judge_error": repr(e)}
        record({**meta, "n": a.n, "secs": round(time.time() - t0, 1), "traces": str(path), **summary})
    leak_check()


def summarize_start(js):
    out = {"truth_med": pctl([j["truth_ms"] for j in js if j["truth_ms"] is not None], 50),
           "truth_p95": pctl([j["truth_ms"] for j in js if j["truth_ms"] is not None], 95),
           "truth_max": max([j["truth_ms"] for j in js if j["truth_ms"] is not None], default=None),
           "no_truth": sum(1 for j in js if j["truth_ms"] is None)}
    facts = {}
    for j in js:
        if "fact_ok" in j:
            f = facts.setdefault(j["fact_signal"], [0, 0])
            f[0] += 1
            f[1] += 0 if j["fact_ok"] else 1
    out["fact_tests"] = {k: {"n": v[0], "wrong": v[1]} for k, v in facts.items()}
    names = []
    for j in js:
        for k in j["sig"]:
            if k not in names:
                names.append(k)
    for k in names:
        vs = [j["sig"].get(k) for j in js]
        got = [v for v in vs if v]
        out[k] = {"n": len(got), "never": len(vs) - len(got), "frame_wrong": sum(1 for v in got if not v["frame_ok"]),
                  "ms_med": pctl([v["ms"] for v in got], 50), "ms_p95": pctl([v["ms"] for v in got], 95),
                  "wasted_med": pctl([v["wasted_ms"] for v in got if v["wasted_ms"] is not None], 50),
                  "wasted_p95": pctl([v["wasted_ms"] for v in got if v["wasted_ms"] is not None], 95),
                  "early_max": max([v["frames_early"] for v in got], default=None)}
    return out



def cmd_rejudge(a):
    """Judges saved traces again (after a change to the judging) and appends fresh summary rows."""
    for path in a.traces:
        name = pathlib.Path(path).name
        label, mode, scene = name.split("-")[:3]
        reps = [json.loads(l) for l in gzip.open(path, "rt")]
        learn_clean(SCENES[scene], reps)
        judged = [judge(rep, SCENES[scene], mode) for rep in reps]
        record({"label": label + a.suffix, "mode": mode, "kind": "scene", "scene": scene, "n": len(reps), "w": SCENES[scene]["w"], "traces": path,
                "rejudged": True, **summarize(judged, mode)})


def cmd_report(a):
    rows = [json.loads(l) for l in RESULTS.open()]
    rows = [r for r in rows if r.get("kind") == "scene" and (not a.label or r["label"] == a.label)]
    for r in rows:
        sigs = [k for k, v in r.items() if isinstance(v, dict) and "wrong" in v]
        head = f"{r['label']:>8} {r['mode']:>8} {r['scene']:>9} n={r['n']} w={r['w']} load={r['load']} noTruth={r['no_truth']} noPix={r.get('no_pix_truth')} missAck={r['missing_ack']}"
        print(head)
        for k in sigs:
            v = r[k]
            line = f"    {k:>12} wrong {v['wrong']:>3} (fail {v['wrong_fail']:>3})  decide {v['decide_med']}/{v['decide_p95']}  wasted {v['wasted_med']}/{v['wasted_p95']}  changedAfter {v['changed_after']} ({v.get('changed_after_ms_p95')})"
            if "pix_wrong" in v:
                line += f"  | pixWrong {v['pix_wrong']:>3} decide {v.get('pix_decide_med')}/{v.get('pix_decide_p95')} wasted {v['pix_wasted_med']}/{v['pix_wasted_p95']}" + (f" early {v['frames_early']}" if 'frames_early' in v else "")
            print(line)


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    sc = sub.add_parser("scenes")
    sc.add_argument("--mode", default="gated", choices=["gated", "rendered"])
    sc.add_argument("--n", type=int, default=200)
    sc.add_argument("--only", default="")
    sc.add_argument("--label", default="mac")
    st = sub.add_parser("start")
    st.add_argument("--kind", default="swap", choices=["swap", "reconnect", "reset", "fresh"])
    st.add_argument("--world", default="void", choices=["void", "default"])
    st.add_argument("--n", type=int, default=100)
    st.add_argument("--rd", type=int, default=0)
    st.add_argument("--tail", type=float, default=3.0)
    st.add_argument("--label", default="mac")
    rj = sub.add_parser("rejudge")
    rj.add_argument("traces", nargs="+")
    rj.add_argument("--suffix", default="")
    rp = sub.add_parser("report")
    rp.add_argument("--label", default="")
    a = ap.parse_args()
    {"scenes": cmd_scenes, "start": cmd_start, "report": cmd_report, "rejudge": cmd_rejudge}[a.cmd](a)


if __name__ == "__main__":
    main()
