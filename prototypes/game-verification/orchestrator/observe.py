#!/usr/bin/env python3
"""Spike A: four observers against a lying battery.

  observe.py battery --reps 5 [--gate 0|2] [--only 1,6,18a] [--shots]
  observe.py ride --reps 5
  observe.py cost
  observe.py flex
  observe.py probe
  observe.py report

Every scene has a ground truth for "the player perceives X", set from a frame looked at by eye.
Results append to runs/a-observers.jsonl; truth frames go to runs/a-frames/.
Client launches through Session in speed.py: direct java, silent options, zero volume asserted, and
a mixin that forces the sound engine's computed channel volume to zero.
"""
import argparse, json, os, pathlib, statistics, sys, time

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from run import RUNS, leak_check
from speed import Session, cpu_seconds

OUT = RUNS / "a-observers.jsonl"
FRAMES = RUNS / "a-frames"
THR_PIX = 30  # pixels that must differ to call a thing present
GOLD = 0xFFAA00
GOLD_RGB = (255, 170, 0)
HOTBAR_GUI = (330, 430, 525, 480)
HOTBAR_FB = "670,860,1050,960"


class Ctx:
    def __init__(self, s, rep, gate, perceive=False):
        self.s, self.rep, self.gate, self.perceive = s, rep, gate, perceive
        self.S, self.C, self.p = s.S, s.C, s.p
        self.ping = 500000 + rep * 10000
        self.vals = {}

    def barrier(self):
        self.ping += 1
        self.S("noop", player=self.p, ping=self.ping)
        self.C("state", ping=self.ping, timeoutMs=5000)


# ---- Observers. Each returns (verdict True/False/None for cannot tell, detail) ----

def a1(c, q, ctx):
    h = c("held")
    k, t = q["kind"], q.get("t")
    d = {}
    if k == "title":
        v = t in (h["title"] or "") and h["titleTime"] > 0
    elif k == "title_color":
        v = t in (h["title"] or "") and h["titleTime"] > 0 and h["titleColor"] == q["color"]
    elif k == "title_whole":
        v = t in (h["title"] or "") and h["titleTime"] > 0  # holds nothing about layout
    elif k == "chat":
        v = any(t in m for m in h["chat"])
    elif k == "bar":
        v = t in (h["bar"] or "") and h["barTime"] > 0
    elif k == "entity":
        v = any(e["id"] == ctx.vals["id"] for e in h["ents"])
    elif k == "wtext":
        v = any(t in (e.get("text") or "") or t in (e.get("name") or "") for e in h["ents"])
    elif k == "block":
        v = c("drawnBlock", x=q["x"], y=q["y"], z=q["z"], frames=0)["state"] == q["block"]
    elif k in ("items", "items_any"):
        v = any(i.startswith(q["item"]) for i in h["inv"])
    elif k == "sound":
        return None, {}
    elif k == "boss":
        v = any(t in (b["name"] or "") for b in h["boss"])
    elif k == "sidebar":
        s = h["sidebar"]
        v = bool(s) and (t in (s["title"] or "") or any(t in l for l in s["lines"]))
    elif k == "any_text":
        return None, {}
    else:
        raise ValueError(k)
    return bool(v), d


def covered(elems, idx, blur_at):
    """Painted over later: a later opaque rectangle or a textured panel holding the run's box."""
    e = elems[idx]
    if 0 <= idx < blur_at:
        return "blur"
    x0, y0, x1, y1 = e["b"]
    area = max(1, (x1 - x0) * (y1 - y0))
    for j in range(idx + 1, len(elems)):
        o = elems[j]
        if o["k"] not in "RB":
            continue
        if o["k"] == "R" and ((o["c"] >> 24) & 255) < 240:
            continue
        ox0, oy0, ox1, oy1 = o["b"]
        ix = max(0, min(x1, ox1) - max(x0, ox0))
        iy = max(0, min(y1, oy1) - max(y0, oy0))
        if ix * iy >= 0.9 * area:
            return o["k"]
    return None


def gui_run(f, needle):
    """Best run holding the needle: alpha, on screen share, and whether something paints over it."""
    best = None
    for i, e in enumerate(f["elems"]):
        if e["k"] != "T" or needle not in e.get("t", ""):
            continue
        alpha = (e["c"] >> 24) & 255
        x0, y0, x1, y1 = e["b"]
        gw, gh = f["gui"]
        ix = max(0, min(x1, gw) - max(x0, 0))
        iy = max(0, min(y1, gh) - max(y0, 0))
        share = ix * iy / max(1, (x1 - x0) * (y1 - y0))
        cov = covered(f["elems"], i, f["blurAt"])
        run = dict(alpha=alpha, share=round(share, 3), cover=cov, style=e.get("s"), box=e["b"])
        if best is None or (cov is None and best["cover"] is not None):
            best = run
    return best


def world_runs(f, needle):
    return [w for w in f["world"] if needle in w["t"]]


def a2p(c, q, ctx):
    """A2 read from a perceive frame: extract and submit ran, the GPU draw did not (P11)."""
    return a2(c, q, ctx, perceive=1)


def a2r(c, q, ctx):
    """The record's own legibility rules (Stream.snapshot) on the last perceive frame, for the text kinds."""
    k, t = q["kind"], q.get("t")
    if k not in ("title", "chat", "bar", "boss", "sidebar", "any_text", "wtext"):
        return None, {}
    runs = c("st.judge")["runs"]
    hit = [r for r in runs if t in r[1] and (k != "wtext" or r[0] in ("world", "nametag"))]
    return bool(hit), {"runs": hit[:2]}


def a2(c, q, ctx, perceive=0):
    k, t = q["kind"], q.get("t")
    pf = {"perceive": 1} if perceive else {}
    if k == "sound":
        since = ctx.vals.get("sound_since", 0)
        ss = [x for x in c("sounds", since=since)["sounds"] if q["id"] in x["id"]]
        return any(x["effective"] > 0.01 for x in ss), {"sounds": ss[:2]}
    if k == "block":
        b = c("drawnBlock", x=q["x"], y=q["y"], z=q["z"], frames=1, **pf)
        v = b["state"] == q["block"] and b["compiled"] and b["sectionVisible"] and b["inFrustum"] and b["meshNewSinceChange"]
        return bool(v), b
    f = c("drawn", frames=1, **pf)
    if k in ("title", "chat", "bar", "boss", "sidebar"):
        run = gui_run(f, t)
        if not run:
            return False, {"run": None, "screen": f["screen"]}
        return run["alpha"] >= 8 and run["share"] > 0.5 and run["cover"] is None, {"run": run}
    if k == "title_color":
        run = gui_run(f, t)
        return bool(run) and run["style"] == q["color"] and run["alpha"] >= 8 and run["cover"] is None, {"run": run}
    if k == "title_whole":
        run = gui_run(f, t)
        return bool(run) and run["share"] >= 0.999 and run["cover"] is None, {"run": run}
    if k == "entity":
        es = [e for e in f["ents"] if e["id"] == ctx.vals["id"]]
        return bool(es) and es[0]["geo"] > 0, {"ent": es[:1]}
    if k == "wtext":
        rs = world_runs(f, t)
        ok = False
        for w in rs:
            alpha = (w["c"] >> 24) & 255
            color = w["s"] if w["s"] >= 0 else (w["c"] & 0xFFFFFF)
            same_bg = ((w["bg"] >> 24) & 255) > 200 and (w["bg"] & 0xFFFFFF) == color
            p = w["p"]
            on = False
            if p:
                xs, ys = p[0::2], p[1::2]
                fw, fh = f["fb"]
                on = max(xs) > 0 and min(xs) < fw and max(ys) > 0 and min(ys) < fh
            facing = w["mode"] == "NAMETAG" or w["area"] > 0
            if on and facing and alpha >= 26 and not same_bg:
                ok = True
        return ok, {"world": rs[:1]}
    if k == "items":
        gx0, gy0, gx1, gy1 = HOTBAR_GUI
        return any(e["k"] == "I" and e.get("t", "").startswith(q["item"]) and e["b"][0] >= gx0 and e["b"][1] >= gy0 and e["b"][2] <= gx1 and e["b"][3] <= gy1 for e in f["elems"]), {}
    if k == "items_any":
        return any(e["k"] == "I" and e.get("t", "").startswith(q["item"]) for e in f["elems"]), {}
    if k == "any_text":
        return any_text(f, t), {}
    raise ValueError(k)


def any_text(f, t):
    """The kind free check: any text with this content was drawn visibly, GUI or world."""
    run = gui_run(f, t)
    if run and run["alpha"] >= 8 and run["share"] > 0 and run["cover"] is None:
        return True
    return any(w["mode"] == "NAMETAG" or w["area"] > 0 for w in world_runs(f, t))


def a3(c, q, ctx):
    k = q["kind"]
    if k == "sound":
        return None, {}
    args = dict(a="base", b="now", thr=8)
    if k == "items":
        args["rect"] = HOTBAR_FB
    d = c("pix.diff", **args)
    n = d["count"]
    if k == "title_color":
        hits = c("pix.color", slot="now", rgb="%d,%d,%d" % GOLD_RGB, tol=30)["count"] - c("pix.color", slot="base", rgb="%d,%d,%d" % GOLD_RGB, tol=30)["count"]
        return hits >= THR_PIX, {"count": n, "gold": hits}
    if k == "title_whole":
        w = ctx.vals.get("w", 1708)
        touches = d["bbox"][0] <= 1 and d["bbox"][2] >= w - 2
        return n >= THR_PIX and not touches, {"count": n, "bbox": d["bbox"], "w": w}
    return n >= THR_PIX, {"count": n, "bbox": d["bbox"], "rgb": d["rgb"]}


def a4(c, q, ctx):
    k, t = q["kind"], q.get("t")
    args = {"settle": 1}
    if k == "sound":
        return None, {}
    if k in ("title", "title_color", "title_whole", "chat", "bar", "boss", "sidebar", "any_text"):
        args.update(kind="text", needle=t)
    elif k == "entity":
        args.update(kind="entity", id=ctx.vals["id"])
    elif k == "wtext":
        args.update(kind="entity", id=ctx.vals["id"])
    elif k == "block":
        args.update(kind="block", x=q["x"], y=q["y"], z=q["z"])
    elif k == "items":
        args.update(kind="item", id=q["item"], rect=HOTBAR_FB)
    elif k == "items_any":
        args.update(kind="item", id=q["item"])
    else:
        raise ValueError(k)
    if k == "title_color":
        args["rgb"] = "%d,%d,%d" % GOLD_RGB
    d = c("vis", **args)
    # Crossing a tick moves everything else, so the pair is invalid: draw it again.
    # Not for a block: the hide and restore compile the section, which repairs a stale mesh, so a second
    # try measures a world the first try changed. This retry caused scene 12's false positives.
    for _ in range(3):
        if not d.get("tickCrossed") or k == "block":
            break
        d = c("vis", **args)
    n = d["count"] if d["hits"] else 0
    det = {"count": d["count"], "hits": d["hits"], "tickCrossed": d.get("tickCrossed"), "bbox": d["bbox"], "rgb": d["rgb"]}
    if k == "title_color":
        return n >= THR_PIX and d["rgbHits"] >= THR_PIX, dict(det, rgbHits=d["rgbHits"])
    if k == "title_whole":
        w = ctx.vals.get("w", 1708)
        return n >= THR_PIX and not (d["bbox"][0] <= 1 and d["bbox"][2] >= w - 2), det
    return n >= THR_PIX, det


# ---- Scenes ----

class Scene:
    def __init__(self, id, name, truth, q, arrange=None, act=None, wait=0.0, after=None, cleanup=None, settle=30, truth_note=None, stable=True):
        self.stable = stable
        self.id, self.name, self.truth, self.q = id, name, truth, q
        self.arrange, self.act, self.wait, self.after, self.cleanup, self.settle = arrange, act, wait, after, cleanup, settle


def tok(ctx, sc):
    return f"Q{ctx.rep}{sc.id.upper()}"[:5]


def title(ctx, text, **kw):
    ctx.S("ttl", player=ctx.p, text=text, **kw)


GOLD_BLOCK = {"x": 2, "y": 66, "z": 5, "block": "minecraft:gold_block"}
BEHIND = {"x": 0, "y": 66, "z": 6, "block": "minecraft:gold_block"}


def zombie(ctx, **kw):
    ctx.vals["id"] = ctx.S("pzombie", player=ctx.p, **kw)["id"]


def ptext(ctx, t, **kw):
    ctx.vals["id"] = ctx.S("ptext", player=ctx.p, text=t, **kw)["id"]


def sound_since(ctx):
    ctx.vals["sound_since"] = ctx.C("sounds", since=10 ** 9)["seq"]


def scene_list():
    T = lambda kind, **k: dict(kind=kind, **k)
    out = []

    def add(*a, **k):
        out.append(Scene(*a, **k))

    def wall(ctx, z=3):
        ctx.S("wall", player=ctx.p, z=z)

    add("0", "null control, nothing happens", False, T("title", t="NOPE"))

    add("1", "entity behind a wall", False, T("entity"), arrange=wall, act=lambda c, s: zombie(c, z=6.5))
    add("2", "entity behind the player", False, T("entity"), act=lambda c, s: zombie(c, z=-5.5, yaw=0))
    add("3", "text display facing away", False, T("wtext", t="TOKAWAY"), act=lambda c, s: ptext(c, "TOKAWAY", yaw=0))
    add("4", "entity with the invisible flag", False, T("entity"), act=lambda c, s: zombie(c, z=4.5, invisible=1))
    add("5a", "text display, opacity zero, no background", False, T("wtext", t="TOKZERO"), act=lambda c, s: ptext(c, "TOKZERO", opacity=0, bg="0"))
    add("5b", "text display, black text on opaque black background", False, T("wtext", t="TOKBLACK"), act=lambda c, s: ptext(c, "TOKBLACK", color="000000", bg="FF000000"))

    def t_inv_arrange(ctx):
        ctx.C("blur", v=5)
        ctx.C("screen", which="inventory")

    def t_inv_clean(ctx):
        ctx.C("screen", which="none")
        ctx.C("blur", v=0)

    add("6", "title under the inventory screen", False, T("title", t="@"), arrange=t_inv_arrange, act=lambda c, s: title(c, tok(c, s)), cleanup=t_inv_clean)
    add("7", "title with HUD hidden", False, T("title", t="@"), arrange=lambda c: c.C("hud", hidden=1), act=lambda c, s: title(c, tok(c, s)), cleanup=lambda c: c.C("hud", hidden=0))

    add("8", "title under an opaque GUI rectangle", False, T("title", t="@"),
        arrange=lambda c: c.C("overdraw", box="0,0,854,480,FF204060"), act=lambda c, s: title(c, tok(c, s)), cleanup=lambda c: c.C("overdraw"))

    add("9", "chat line after its fade time", False, T("chat", t="TOKFADE"), act=lambda c, s: c.S("say", player=c.p, text="TOKFADE"), wait=10.6)

    def scrolled_arr(ctx):
        ctx.S("saymany", player=ctx.p, n=30, prefix="spam")

    def scrolled_act(ctx, sc):
        ctx.C("clearChat")
        ctx.S("say", player=ctx.p, text="TOKSCROLL")
        ctx.S("saymany", player=ctx.p, n=30, prefix="spam")

    add("10", "chat line scrolled out of the page", False, T("chat", t="TOKSCROLL"), arrange=scrolled_arr, act=scrolled_act)

    def hidden_arr(ctx):
        ctx.C("chatVis", v="hidden")

    def hidden_act(ctx, sc):
        ctx.C("chatVis", v="full")
        ctx.S("say", player=ctx.p, text="TOKHIDE")
        ctx.barrier()
        ctx.C("chatVis", v="hidden")

    add("11", "chat line received, then chat set to hidden", False, T("chat", t="TOKHIDE"), arrange=hidden_arr, act=hidden_act, cleanup=lambda c: c.C("chatVis", v="full"))

    def uncompiled_act(ctx, sc):
        ctx.C("gate", mode=1)
        ctx.S("block", player=ctx.p, x=GOLD_BLOCK["x"], y=GOLD_BLOCK["y"], z=GOLD_BLOCK["z"], material="GOLD_BLOCK", fake=1)
        ctx.barrier()
        ctx.C("draw", frames=1)
        time.sleep(0.15)
        ctx.C("gate", mode=ctx.gate if ctx.gate else 0)

    add("12", "per player block in client state, section never compiled", False, T("block", **GOLD_BLOCK), act=uncompiled_act)
    add("13", "block behind a wall", False, T("block", **BEHIND), arrange=wall, act=lambda c, s: c.S("block", player=c.p, x=BEHIND["x"], y=BEHIND["y"], z=BEHIND["z"], material="GOLD_BLOCK", fake=1))

    def snd(ctx, **k):
        sound_since(ctx)
        ctx.S("sound", player=ctx.p, **k)

    add("14a", "sound far beyond its range", False, T("sound", id="zombie.ambient"), act=lambda c, s: snd(c, dz=400))

    def cat_arr(ctx):
        ctx.C("category", src="HOSTILE", v=0)

    add("14b", "sound in a category at volume zero", False, T("sound", id="zombie.ambient"), arrange=cat_arr, act=lambda c, s: snd(c, dz=2), cleanup=lambda c: c.C("category", src="HOSTILE", v=1))

    def inv_a(ctx, sc):
        ctx.S("items", player=ctx.p, item="DIAMOND", slot=3)
        ctx.barrier()
        ctx.S("fakeInv", player=ctx.p)

    def inv_b(ctx, sc):
        ctx.S("fakeInv", player=ctx.p, slot=3)

    add("15a", "server holds diamonds, client shown empty", False, T("items", item="minecraft:diamond"), act=inv_a)
    add("15b", "server empty, client shown diamonds", True, T("items", item="minecraft:diamond"), act=inv_b)

    add("17a", "title in the right place, wrong colour (asked: gold)", False, T("title_color", t="@", color=GOLD), act=lambda c, s: title(c, tok(c, s), color="FF0000"))
    add("17c", "title gold as asked", True, T("title_color", t="@", color=GOLD), act=lambda c, s: title(c, tok(c, s), color="FFAA00"))

    def narrow(ctx):
        ctx.C("window", w=340, h=480)
        time.sleep(0.4)
        ctx.vals["w"] = 680

    def wide(ctx):
        ctx.C("window", w=854, h=480)
        time.sleep(0.4)

    LONG = "LONGTITLEWHOLEVISIBLE"
    add("17b", "long title cut off by a narrow window (asked: whole)", False, T("title_whole", t=LONG), arrange=narrow, act=lambda c, s: title(c, LONG), cleanup=wide)
    add("17d", "long title fits (asked: whole)", True, T("title_whole", t=LONG), act=lambda c, s: title(c, LONG))

    add("18a", "true positive title", True, T("title", t="@"), act=lambda c, s: title(c, tok(c, s)))
    add("18b", "true positive chat", True, T("chat", t="TOKCHAT"), act=lambda c, s: c.S("say", player=c.p, text="TOKCHAT"))
    add("18c", "true positive action bar", True, T("bar", t="TOKBAR"), act=lambda c, s: c.S("bar", player=c.p, text="TOKBAR"))
    add("18d", "true positive per player block", True, T("block", **GOLD_BLOCK), act=lambda c, s: c.S("block", player=c.p, x=GOLD_BLOCK["x"], y=GOLD_BLOCK["y"], z=GOLD_BLOCK["z"], material="GOLD_BLOCK", fake=1))
    add("18e", "true positive entity", True, T("entity"), act=lambda c, s: zombie(c, z=4.5))
    add("18f", "true positive sound", True, T("sound", id="zombie.ambient"), act=lambda c, s: snd(c, dz=2))
    add("18g", "true positive text display facing the player", True, T("wtext", t="TOKFACE"), act=lambda c, s: ptext(c, "TOKFACE"))
    add("18h", "true positive entity half behind a wall", True, T("entity"), arrange=lambda c: c.S("wall", player=c.p, z=3, x0=-3, x1=0, y0=65, y1=69),
        act=lambda c, s: zombie(c, x=1.7, z=5.5))

    def wiggle(ctx):
        z = ctx.S("pzombie", player=ctx.p, x=-1.5, z=4.5)["id"]
        ctx.S("wiggle", player=ctx.p, id=z, x=-1.5, z=4.5)
        ctx.S("wall", player=ctx.p, z=3, x0=1, x1=4, y0=65, y1=69)

    add("19", "entity behind a wall while another entity moves in view", False, T("entity"), arrange=wiggle, act=lambda c, s: zombie(c, x=2.5, z=6.5), stable=False)
    add("20", "true positive entity while another entity moves in view", True, T("entity"), arrange=wiggle2, act=lambda c, s: zombie(c, x=2.5, z=4.5), stable=False)
    return out


def flex_list():
    """New kinds the framework was not built for: boss bar, scoreboard sidebar, and the kind free check."""
    T = lambda kind, **k: dict(kind=kind, **k)
    out = []

    def add(*a, **k):
        out.append(Scene(*a, **k))

    def boss(c, **k):
        c.S("boss", player=c.p, text="TOKBOSS", **k)

    def side(c):
        c.S("sidebar", player=c.p, title="TOKSIDE", lines="alpha|beta|gamma")

    add("f1", "boss bar shown", True, T("boss", t="TOKBOSS"), act=lambda c, s: boss(c))
    add("f2", "boss bar, HUD hidden", False, T("boss", t="TOKBOSS"), arrange=lambda c: c.C("hud", hidden=1), act=lambda c, s: boss(c), cleanup=lambda c: c.C("hud", hidden=0))
    add("f3", "sidebar shown", True, T("sidebar", t="TOKSIDE"), act=lambda c, s: side(c))
    add("f4", "sidebar line shown", True, T("sidebar", t="beta"), act=lambda c, s: side(c))
    add("f5", "sidebar, HUD hidden", False, T("sidebar", t="TOKSIDE"), arrange=lambda c: c.C("hud", hidden=1), act=lambda c, s: side(c), cleanup=lambda c: c.C("hud", hidden=0))
    add("g1", "any text: action bar", True, T("any_text", t="TOKG1"), act=lambda c, s: c.S("bar", player=c.p, text="TOKG1"))
    add("g2", "any text: sign with text on its far side, seen from behind", False, T("any_text", t="TOKG2"), act=lambda c, s: c.S("sign", player=c.p, x=0, y=65, z=3, text="TOKG2"))
    add("g2b", "any text: sign facing the player", True, T("any_text", t="TOKG2B"), act=lambda c, s: c.S("sign", player=c.p, x=0, y=65, z=3, text="TOKG2B", face="NORTH"))
    add("g3", "any text: entity name tag", True, T("any_text", t="TOKG3"), act=lambda c, s: zombie(c, z=4.5, name="TOKG3"))
    add("g4", "any text: label inside a screen", True, T("any_text", t="Crafting"), act=lambda c, s: c.C("screen", which="inventory"), cleanup=lambda c: c.C("screen", which="none"))
    add("g5", "any text: sign facing the player, behind a wall", False, T("any_text", t="TOKG5"), arrange=lambda c: c.S("wall", player=c.p, z=2), act=lambda c, s: c.S("sign", player=c.p, x=0, y=65, z=3, text="TOKG5", face="NORTH"))
    add("g6", "any text: nothing shows it", False, T("any_text", t="TOKG6"))
    add("t1", "first Diamonds toast: any diamond icon on screen, hotbar empty", True, T("items_any", item="minecraft:diamond"), act=lambda c, s: (c.S("items", player=c.p, item="DIAMOND", slot=3), c.barrier(), time.sleep(0.2), c.S("fakeInv", player=c.p)))
    return out


def wiggle2(ctx):
    z = ctx.S("pzombie", player=ctx.p, x=-1.5, z=4.5)["id"]
    ctx.S("wiggle", player=ctx.p, id=z, x=-1.5, z=4.5)


def run_scene(ctx, sc, shots):
    S, C, p = ctx.S, ctx.C, ctx.p
    c = ctx.client
    ctx.vals = {}
    S("arena", player=p)
    C("clearChat")
    C("clearToasts")
    C("clearMeshes")
    ctx.barrier()
    C("pix.stable", maxMs=2500)
    if sc.arrange:
        sc.arrange(ctx)
    ctx.barrier()
    C("draw", frames=sc.settle)
    if sc.stable:
        C("pix.stable", maxMs=2000)
    C("pix.grab", slot="base", frames=2)
    if sc.q.get("t") == "@":
        sc.q = dict(sc.q, t=None)
    q = dict(sc.q)
    if q.get("t") is None and "t" in q:
        q["t"] = tok(ctx, sc)
    if sc.act:
        sc.act(ctx, sc)
    ctx.barrier()
    if sc.wait:
        time.sleep(sc.wait)
    timing = {}
    row = {"scene": sc.id, "name": sc.name, "truth": sc.truth, "rep": ctx.rep, "gate": ctx.gate, "perceive": ctx.perceive, "verdicts": {}, "details": {}}
    if ctx.perceive:
        # P11: the scene settles on perceive frames only, A2 and the record rules read a perceive frame first.
        C("perceive", frames=sc.settle)
        for name, fn in (("A2p", a2p), ("A2r", a2r)):
            t0 = time.perf_counter()
            try:
                v, d = fn(c, q, ctx)
            except Exception as e:
                v, d = "error", {"error": str(e)}
            timing[name] = (time.perf_counter() - t0) * 1000
            row["verdicts"][name] = v
            row["details"][name] = d
    else:
        C("draw", frames=sc.settle)
    # Stale after skipped draws: the first drawn frame against the next one, both right away.
    C("pix.grab", slot="first", frames=1)
    C("pix.grab", slot="second", frames=1)
    row["firstVsSecond"] = C("pix.diff", a="first", b="second", thr=8)["count"]
    t0 = time.perf_counter()
    C("pix.grab", slot="now", frames=1)
    timing["grab"] = (time.perf_counter() - t0) * 1000
    if shots and ctx.rep == 0:
        FRAMES.mkdir(parents=True, exist_ok=True)
        tag = f"s{sc.id}" + (f"-gate{ctx.gate}" if ctx.gate else "") + ("-perceive" if ctx.perceive else "")
        C("pix.png", slot="now", path=str(FRAMES / f"{tag}.png"))
        C("pix.mask", a="base", b="now", path=str(FRAMES / f"{tag}-diffmask.png"))
    for name, fn in (("A1", a1), ("A2", a2), ("A3", a3), ("A4", a4)):
        t0 = time.perf_counter()
        try:
            v, d = fn(c, q, ctx)
        except Exception as e:
            v, d = "error", {"error": str(e)}
        timing[name] = (time.perf_counter() - t0) * 1000
        if name == "A3":
            timing[name] += timing["grab"]
        row["verdicts"][name] = v
        row["details"][name] = d
    row["timing"] = timing
    # Did the truth move while the observers ran? Compare a fresh frame with the frame the truth came from.
    C("pix.grab", slot="after", frames=1)
    row["truthMoved"] = C("pix.diff", a="now", b="after", thr=8)["count"]
    if sc.cleanup:
        sc.cleanup(ctx)
    return row


def mark(v, truth):
    if v is None:
        return "?"
    if v == "error":
        return "E"
    return "ok" if v == truth else ("FP" if v else "FN")


def cmd_battery(a):
    only = set(a.only.split(",")) if a.only else None
    scenes = [s for s in scene_list() if not only or s.id in only]
    rows = []
    with Session(f"a-battery-gate{a.gate}{'-perceive' if a.perceive else ''}", rd=3, max_runtime=3000, keep=a.keep) as s:
        cat = s.C("category", src="HOSTILE", v=1)
        assert cat["master"] == 0.0, cat
        s.C("prio")
        time.sleep(a.wait_toast)
        s.C("clearToasts")
        s.C("clearChat")
        if a.gate:
            s.C("gate", mode=a.gate, parkMicros=2000)
        load0 = os.getloadavg()[0]
        for rep in range(a.reps):
            ctx = Ctx(s, rep, a.gate, a.perceive)
            ctx.client = s.C
            for sc in scenes:
                row = run_scene(ctx, sc, a.shots)
                row["at"] = time.time()
                row["load"] = os.getloadavg()[0]
                row["label"] = a.label
                rows.append(row)
                ms = {k: round(v) for k, v in row["timing"].items()}
                print(rep, sc.id.ljust(4), "truth", str(sc.truth).ljust(5), " ".join(f"{k}:{mark(v, sc.truth):2}" for k, v in row["verdicts"].items()), ms, flush=True)
                with open(OUT, "a") as f:
                    f.write(json.dumps(row) + "\n")
        print("load", load0, os.getloadavg()[0])
    leak_check()


def cmd_flex(a):
    scenes = [s for s in flex_list() if a.reps == 1 or s.id != "t1"]
    with Session(f"a-flex{'-perceive' if a.perceive else ''}", rd=3, keep=False) as s:
        s.C("prio")
        time.sleep(a.wait_toast)
        s.C("clearToasts")
        s.C("clearChat")
        if a.gate:
            s.C("gate", mode=a.gate, parkMicros=2000)
        for rep in range(a.reps):
            ctx = Ctx(s, rep, a.gate, a.perceive)
            ctx.client = s.C
            for sc in scenes:
                row = run_scene(ctx, sc, a.shots)
                row["at"] = time.time()
                row["load"] = os.getloadavg()[0]
                row["set"] = "flex"
                row["label"] = a.label
                print(rep, sc.id.ljust(4), "truth", str(sc.truth).ljust(5), " ".join(f"{k}:{mark(v, sc.truth):2}" for k, v in row["verdicts"].items()), {k: round(v) for k, v in row["timing"].items()}, flush=True)
                with open(OUT, "a") as f:
                    f.write(json.dumps(row) + "\n")
    leak_check()


def speeds(rows, ti, zi):
    v = []
    for a, b in zip(rows, rows[1:]):
        dt = (b[ti] - a[ti]) / 1000
        if dt <= 0:
            continue
        v.append((b[zi] - a[zi]) / dt)
    return v


def path_metrics(rows, ti=0, zi=3, expected=5.0):
    """Motion window only. Speed per sample against the commanded speed, in blocks per second."""
    start = next((i for i in range(1, len(rows)) if abs(rows[i][zi] - rows[0][zi]) > 0.01), None)
    if start is None:
        return None
    end = len(rows) - 1
    while end > 0 and abs(rows[end][zi] - rows[-1][zi]) < 0.0005:
        end -= 1
    win = rows[max(0, start - 1):end + 1]
    # Frame times are uneven, so step per sample is compared to what the elapsed time asks for.
    v = speeds(win, ti, zi)
    if len(v) < 5:
        return {"n": len(v)}
    vs = sorted(v)
    med = statistics.median(vs)
    stalls = sum(1 for x in v if x < 0.2 * expected) / len(v)
    bursts = sum(1 for x in v if x > 2.0 * expected) / len(v)
    back = sum(1 for x in v if x < -0.01)
    return {"n": len(v), "median": round(med, 2), "p99": round(vs[int(0.99 * (len(vs) - 1))], 2), "stalls": round(stalls, 3), "bursts": round(bursts, 3), "back": back, "std": round(statistics.pstdev(v), 2)}


def cmd_ride(a):
    rows = []
    with Session("a-ride", rd=3, keep=False) as s:
        s.C("prio")
        time.sleep(2)
        s.C("clearToasts")
        s.C("clearChat")
        if a.fps:
            s.C("fps", limit=a.fps)
        for rep in range(a.reps):
            for mode, dur in (("smooth", a.duration), ("jerky", 0)):
                for pix in (0, 1):
                    s.S("arena", player=s.p)
                    s.C("pix.stable", maxMs=1500)
                    s.C("ride.start", pix=pix)
                    s.S("ride", player=s.p, duration=dur, ticks=50, step=0.25)
                    if a.gate:
                        # Frames on demand: the requirement pays for each sample it wants.
                        s.C("gate", mode=a.gate, parkMicros=2000)
                        end = time.perf_counter() + 0.05 * 50 + 0.5
                        while time.perf_counter() < end:
                            s.C("draw", frames=1)
                            time.sleep(1 / a.draw_hz)
                    else:
                        time.sleep(0.05 * 50 + 0.5)
                    r = s.C("ride.stop")
                    if a.gate:
                        s.C("gate", mode=0)
                    if pix == 0 and rep == 0 and a.shots:
                        FRAMES.mkdir(parents=True, exist_ok=True)
                        s.C("pix.grab", slot="now", frames=1)
                        s.C("pix.png", slot="now", path=str(FRAMES / f"s16-{mode}-end.png"))
                    s.S("rideEnd", player=s.p)
                    s.C("camera")
                    if pix == 0:
                        row = dict(rep=rep, mode=mode, tick=path_metrics(r["tick"]), a1_frame=path_metrics(r["frame"], 0, 3), a2_frame=path_metrics(r["frame"], 0, 6), frames=len(r["frame"]), ticks=len(r["tick"]))
                    else:
                        fl = r["flow"]
                        counts = [x[1] for x in fl]
                        moving = counts[5:-5] if len(counts) > 12 else counts
                        # moving window: frames where anything changed, plus zeros between them
                        first = next((i for i, c in enumerate(counts) if c > 200), 0)
                        last = len(counts) - 1 - next((i for i, c in enumerate(reversed(counts)) if c > 200), 0)
                        mv = counts[first:last + 1] or [0]
                        row = dict(rep=rep, mode=mode, pix=True, flowFrames=len(fl), zeroFrames=sum(1 for c in mv if c < 200) / len(mv), mean=round(statistics.mean(mv)), cv=round(statistics.pstdev(mv) / max(1, statistics.mean(mv)), 2), peak=max(mv))
                    row.update(fps=a.fps, gate=a.gate, load=os.getloadavg()[0], scene="ride")
                    rows.append(row)
                    print(json.dumps(row), flush=True)
                    with open(OUT, "a") as f:
                        f.write(json.dumps(row) + "\n")
    leak_check()


def cmd_probe(a):
    """Two timing questions: when does the frame stop changing after join, and when does scene 12 heal."""
    with Session("a-probe", rd=3, keep=False) as s:
        s.C("prio")
        s.S("arena", player=s.p)
        s.C("clearToasts")
        s.C("clearChat")
        out = []
        t0 = time.perf_counter()
        s.C("pix.grab", slot="j0", frames=2)
        while time.perf_counter() - t0 < a.join:
            time.sleep(1.0)
            s.C("clearToasts")
            s.C("pix.grab", slot="j1", frames=1)
            d = s.C("pix.diff", a="j0", b="j1", thr=8)
            out.append((round(time.perf_counter() - t0, 1), d["count"]))
            s.C("pix.grab", slot="j0", frames=1)
        print("join frame to frame count per second", out, flush=True)
        for rep in range(a.reps):
            s.S("arena", player=s.p)
            s.C("clearChat")
            s.C("clearToasts")
            s.C("clearMeshes")
            s.C("draw", frames=30)
            s.C("pix.stable", maxMs=2500)
            s.C("pix.grab", slot="base", frames=2)
            s.C("gate", mode=1)
            s.S("block", player=s.p, x=2, y=66, z=5, material="GOLD_BLOCK", fake=1)
            Ctx(s, rep, a.gate).barrier()
            s.C("draw", frames=1)
            time.sleep(0.15)
            s.C("gate", mode=a.gate)
            s.C("draw", frames=30)
            t1 = time.perf_counter()
            series = []
            for i in range(40):
                s.C("pix.grab", slot="now", frames=1)
                d = s.C("pix.diff", a="base", b="now", thr=8)
                series.append((round((time.perf_counter() - t1) * 1000), d["count"]))
                if i > 5:
                    time.sleep(0.05)
            heal = next((t for t, c in series if c > 1000), None)
            stale = series[-1][1] < 1000
            forced = None
            if stale:
                v = s.C("vis", kind="block", x=2, y=66, z=5, settle=1)
                s.C("pix.grab", slot="now", frames=1)
                forced = dict(a4=v["count"], rgb=v.get("rgb"), after=s.C("pix.diff", a="base", b="now", thr=8)["count"])
            print(json.dumps(dict(rep=rep, gate=a.gate, healMs=heal, first=series[:3], last=series[-1], forced=forced, load=os.getloadavg()[0])), flush=True)
            s.C("gate", mode=0)
    leak_check()


def fps_window(s, seconds):
    a = s.C("stats")
    c0 = cpu_seconds(s.clientpid)
    time.sleep(seconds)
    b = s.C("stats")
    c1 = cpu_seconds(s.clientpid)
    dt = (b["at"] - a["at"]) / 1e6
    return (b["frame"] - a["frame"]) / dt, (c1 - c0) / dt * 100


def cmd_cost(a):
    with Session("a-cost", rd=3, keep=False) as s:
        s.C("prio")
        time.sleep(3)
        s.C("clearToasts")
        s.C("clearChat")
        s.S("arena", player=s.p)
        for i in range(4):
            s.S("pzombie", player=s.p, x=-3 + 2 * i, z=5.5)
            s.S("ptext", player=s.p, x=-3 + 2 * i, y=68, z=5.5, text=f"LABEL{i}")
        s.S("ttl", player=s.p, text="COSTTITLE", stay=20000)
        s.S("say", player=s.p, text="COST line")
        s.S("bar", player=s.p, text="COST bar")
        s.C("draw", frames=60)
        rows = []
        for round_ in range(a.rounds):
            for mode in ("off", "on"):
                s.C("a2", on=1 if mode == "on" else 0)
                s.C("hooks")
                fps, cpu = fps_window(s, a.seconds)
                h = s.C("hooks")
                row = dict(scene="cost", round=round_, a2=mode, fps=round(fps), cpu=round(cpu), hookUsPerFrame=round(h["hookNanos"] / max(1, h["frames"]) / 1000, 2), load=os.getloadavg()[0])
                rows.append(row)
                print(json.dumps(row), flush=True)
                with open(OUT, "a") as f:
                    f.write(json.dumps(row) + "\n")
        s.C("a2", on=1)
        # Cost per check, without a test around it. Each 30 samples. Rendering, then gate mode 2.
        for gate in (0, 2):
            s.C("gate", mode=gate, parkMicros=2000)
            time.sleep(0.5)
            zid = s.S("pzombie", player=s.p, x=0.5, z=4.5)["id"]
            s.C("draw", frames=30)
            s.C("pix.grab", slot="base", frames=2)
            def t(fn, n=30):
                out = []
                for _ in range(n):
                    t0 = time.perf_counter()
                    fn()
                    out.append((time.perf_counter() - t0) * 1000)
                return dict(median=round(statistics.median(out), 1), p95=round(sorted(out)[int(0.95 * (n - 1))], 1))
            checks = {
                "A1 held state": lambda: s.C("held"),
                "A2 one frame and text": lambda: s.C("drawn", frames=1),
                "A2 latest frame, no new draw": lambda: s.C("drawn", frames=0),
                "A3 grab": lambda: s.C("pix.grab", slot="now", frames=1),
                "A3 diff only": lambda: s.C("pix.diff", a="base", b="now"),
                "A3 grab plus diff": lambda: (s.C("pix.grab", slot="now", frames=1), s.C("pix.diff", a="base", b="now")),
                "A3 grab plus PNG": lambda: (s.C("pix.grab", slot="now", frames=1), s.C("pix.png", slot="now", path=str(RUNS / "a-cost.png"))),
                "A4 text": lambda: s.C("vis", kind="text", needle="COSTTITLE"),
                "A4 entity": lambda: s.C("vis", kind="entity", id=zid),
                "A4 block": lambda: s.C("vis", kind="block", x=2, y=65, z=3),
            }
            s.S("block", player=s.p, x=2, y=65, z=3, material="GOLD_BLOCK", fake=1)
            s.C("draw", frames=30)
            for name, fn in checks.items():
                row = dict(scene="costcheck", gate=gate, check=name, **t(fn), load=os.getloadavg()[0])
                print(json.dumps(row), flush=True)
                with open(OUT, "a") as f:
                    f.write(json.dumps(row) + "\n")
        s.C("gate", mode=0)
    leak_check()


def cmd_report(a):
    """Matrix per gate from the rows on disk: per cell counts, the truth moved column, and the median and p95 ms."""
    rows = [json.loads(l) for l in open(OUT)]
    rows = [r for r in rows if "verdicts" in r and r.get("set") != "flex"]
    names = ("A1", "A2", "A3", "A4")
    for gate in sorted({r["gate"] for r in rows}):
        print("gate", gate)
        cells = {}
        for r in rows:
            if r["gate"] != gate:
                continue
            d = cells.setdefault(r["scene"], {n: {} for n in names})
            d.setdefault("moved", []).append(r.get("truthMoved"))
            for n in names:
                m = mark(r["verdicts"][n], r["truth"])
                d[n][m] = d[n].get(m, 0) + 1
        for sid, d in cells.items():
            print(sid.ljust(4), " ".join(",".join(f"{k}{v}" for k, v in d[n].items()).ljust(10) for n in names), d["moved"] if any(d["moved"]) else "")
        good = sum((r["verdicts"]["A2"] if r["verdicts"]["A4"] is None else (r["verdicts"]["A2"] and r["verdicts"]["A4"])) == r["truth"] for r in rows if r["gate"] == gate)
        print("A2 and A4 correct", good, "of", sum(r["gate"] == gate for r in rows))
        for k in ("grab",) + names:
            v = sorted(r["timing"][k] for r in rows if r["gate"] == gate)
            print(k, "median", round(statistics.median(v), 1), "p95", round(v[int(0.95 * (len(v) - 1))], 1))


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    b = sub.add_parser("battery")
    b.add_argument("--reps", type=int, default=1)
    b.add_argument("--gate", type=int, default=0)
    b.add_argument("--only", default="")
    b.add_argument("--shots", action="store_true")
    b.add_argument("--keep", action="store_true")
    b.add_argument("--wait-toast", type=float, default=8)
    b.add_argument("--perceive", action="store_true")
    b.add_argument("--label", default="mac")
    f = sub.add_parser("flex")
    f.add_argument("--reps", type=int, default=1)
    f.add_argument("--gate", type=int, default=0)
    f.add_argument("--perceive", action="store_true")
    f.add_argument("--label", default="mac")
    f.add_argument("--shots", action="store_true")
    f.add_argument("--wait-toast", type=float, default=2)
    r = sub.add_parser("ride")
    r.add_argument("--reps", type=int, default=5)
    r.add_argument("--duration", type=int, default=3)
    r.add_argument("--fps", type=int, default=0)
    r.add_argument("--shots", action="store_true")
    r.add_argument("--gate", type=int, default=0)
    r.add_argument("--draw-hz", type=float, default=30)
    c = sub.add_parser("cost")
    c.add_argument("--rounds", type=int, default=4)
    c.add_argument("--seconds", type=int, default=8)
    pr = sub.add_parser("probe")
    pr.add_argument("--reps", type=int, default=8)
    pr.add_argument("--join", type=float, default=30)
    pr.add_argument("--gate", type=int, default=0)
    sub.add_parser("report")
    a = ap.parse_args()
    {"report": cmd_report, "probe": cmd_probe, "battery": cmd_battery, "flex": cmd_flex, "ride": cmd_ride, "cost": cmd_cost}[a.cmd](a)


if __name__ == "__main__":
    main()
