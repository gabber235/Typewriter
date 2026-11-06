#!/usr/bin/env python3
"""Spike J: real player input into a real 26.3 client.

  input.py run --paths J2,J1,J3,J4 --ops all --n 200 [--gate 2] [--rate 200] [--label mac]
  input.py lag --paths J2,J3 --ops break,use,sneak --n 20 --where client|server --ms 300
  input.py report runs/j-input/<file>.jsonl.gz

One input at a time: the plugin arranges the same start state, a barrier makes sure the client has it,
the client runs the input through one path as a script on client ticks and then sends a mark payload,
and the plugin's log up to that mark (plus a short grace for async events) is the server's view.

Paths: J1 SDL events pushed into the client's own SDL queue (Mac and Linux, in process), X: XTest
on the virtual X server (Linux CI only, driven from here), J2 the client's input callbacks, J3 the
game's actions (KeyMapping, screen methods, rotation set), J4 packets. J2 is the reference for
what a person's input causes.
"""
import argparse, collections, gzip, json, os, pathlib, random, re, sys, time

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from run import RUNS, leak_check, front_app, now_micros
import speed

OUT = RUNS / "j-input"
RESULTS = RUNS / "j-input.jsonl"

# op name -> (client op, client params, arrange params)
OPS = {
    "chat": ("chat", {"text": "hello {tok}"}, {}),
    "cmd": ("cmd", {"text": "claim here {tok}"}, {}),
    "suggest": ("suggest", {"text": "claim h", "want": "home"}, {}),
    "break": ("break", {"max": 60, "hold": 7}, {"material": "OAK_LEAVES"}),
    "breakCancel": ("break", {"max": 20, "hold": 7}, {"cancel": 1, "material": "OAK_LEAVES"}),
    "breakDirt": ("break", {"max": 80, "hold": 16}, {}),
    "use": ("use", {"hold": 10}, {}),
    "swap": ("swap", {}, {}),
    "scroll": ("scroll", {"dir": -1}, {}),
    "num": ("num", {"n": 3}, {}),
    "sneak": ("sneak", {"hold": 4}, {}),
    "jump": ("jump", {"hold": 3}, {}),
    "attack": ("attack", {}, {}),
    "attackPacket": ("attack", {}, {"packet": 1}),
    "interact": ("interact", {}, {}),
    "interactPacket": ("interact", {}, {"packet": 1}),
    "inv": ("inv", {"slot": 37}, {}),
    "move": ("move", {"max": 80}, {}),
    "fly": ("fly", {"hold": 3}, {"mode": "SPECTATOR"}),
}

# A packet walk sends positions the server counts against one per tick and gets the player kicked
# ("Invalid move player packet received"), which ends the session; measured in the smoke runs, then left out.
SKIP = {("move", "J4")}

# What must be true for the input to have done its job, from the server log and the client's notes.
def outcome(op, ev, notes, tok):
    names = [e.split(":", 1)[0] for e in ev]
    has = lambda n: n in names
    d = lambda n: [e.split(":", 1)[1] for e in ev if e.startswith(n + ":")]
    if op == "chat":
        return any(tok in x for x in d("AsyncChatEvent"))
    if op == "cmd":
        return any(tok in x for x in d("ClaimCommand"))
    if op == "suggest":
        return notes.get("drawnHasWant") is True and "home" in str(notes.get("suggestions", ""))
    if op in ("break", "breakDirt"):
        return any("cancelled" not in x for x in d("BlockBreakEvent")) and notes.get("blockAfter") == "minecraft:air"
    if op == "breakCancel":
        return any("cancelled" in x for x in d("BlockBreakEvent")) and notes.get("blockAfter") not in (None, "minecraft:air")
    if op == "use":
        return has("PlayerStopUsingItemEvent") and notes.get("scoping") is True
    if op == "swap":
        return has("PlayerSwapHandItemsEvent") and notes.get("offhand") == "minecraft:spyglass"
    if op == "scroll":
        return "0->1" in d("PlayerItemHeldEvent") and notes.get("slot") == 1
    if op == "num":
        return "0->2" in d("PlayerItemHeldEvent") and notes.get("slot") == 2
    if op == "sneak":
        return d("PlayerToggleSneakEvent") == ["true", "false"]
    if op == "jump":
        return has("PlayerJumpEvent") and notes.get("rise", 0) > 1.0
    if op == "attack":
        return has("PrePlayerAttackEntityEvent") and notes.get("hit") == "ENTITY"
    if op == "attackPacket":
        return any("attack" in x for x in d("PlayerUseUnknownEntityEvent")) and notes.get("hit") == "ENTITY"
    if op == "interact":
        return (has("PlayerInteractEntityEvent") or has("PlayerInteractAtEntityEvent")) and notes.get("hit") == "ENTITY"
    if op == "interactPacket":
        return any("interact" in x for x in d("PlayerUseUnknownEntityEvent")) and notes.get("hit") == "ENTITY"
    if op == "inv":
        return has("InventoryClickEvent") and has("InventoryCloseEvent") and notes.get("carried") == "minecraft:stick"
    if op == "move":
        x, y, z = (float(v) for v in notes.get("pos", "0,0,0").split(","))
        return abs(x - 0.5) < 0.1 and 4.2 < z < 5.4
    if op == "fly":
        return any("jump" in x and "spectator" in x for x in d("PlayerInputEvent"))
    return False


def collapse(seq):
    out = []
    for x in seq:
        if not out or out[-1] != x:
            out.append(x)
    return out


def norm(e, ent, tok=None):
    d = re.sub(r" gt=\d+ start=\d+ bt=\d+( ground=\w+)?", "", re.sub(r"held=\d+", "held=N", e["d"]))
    if tok:
        d = d.replace(tok, "TOK")
    if ent is not None:
        d = d.replace(str(ent), "E")
    return f'{e["n"]}:{d}'


class Bench:
    def __init__(self, s, xtest=None):
        self.s, self.S, self.C, self.p = s, s.S, s.C, s.p
        self.ids = random.randint(10_000, 20_000) * 1000
        self.xtest = xtest
        self.wait_ground = True

    def nid(self):
        self.ids += 1
        return self.ids

    def one(self, name, path, extra_arrange=None, before=None):
        op, params, arr = OPS[name]
        tok = f"t{self.nid()}"
        self.C("in.reset")
        a = self.S("in.arrange", player=self.p, op=op, **arr, **(extra_arrange or {}))
        ping = self.nid()
        self.S("noop", player=self.p, ping=ping)
        self.C("state", ping=ping, timeoutMs=5000)
        self.C("in.mark", mark=0, settle=3)  # the teleport confirm and its position packet settle first
        if self.wait_ground and arr.get("mode", "SURVIVAL") == "SURVIVAL":
            # The server's onGround comes from the client's next position packet after the teleport; mining
            # speed is a fifth while it is false, so a break checked against it fails (seen at rates 50 to 200).
            deadline = time.time() + 2
            while not self.S("in.ground", _dispatch="direct", player=self.p)["ground"] and time.time() < deadline:
                time.sleep(0.001)
        seq0 = self.S("in.seq", _dispatch="direct", player=self.p)["seq"]
        mark = self.nid()
        q = {k: (v.format(tok=tok) if isinstance(v, str) else v) for k, v in params.items()}
        for k in ("x", "y", "z", "entity"):
            if k in a:
                q[k] = a[k]
        if before:
            before(self)
        t0 = time.perf_counter()
        if path == "X":
            res = self.xtest.run(op, q, mark)
        else:
            res = self.C("in.run", path=path, op=op, mark=mark, **q)
        t1 = time.perf_counter()
        log, seen_at = self.wait_mark(seq0, mark)
        t2 = time.perf_counter()
        # Async events (chat, tab complete) may land after the mark; give them two more server ticks.
        self.S("noop", player=self.p)
        self.S("noop", player=self.p)
        log = self.S("in.log", _dispatch="direct", player=self.p, since=seq0)["log"]
        cut = next((i for i, e in enumerate(log) if e["n"] == "mark" and e["d"] == str(mark)), len(log))
        after_mark = [e for e in log[cut + 1:] if e["k"] == "ev" and e["n"] not in ("mark", "PlayerMoveEvent")]
        body = log[:cut]
        ent = a.get("entity")
        # Main thread events keep their order; async ones (chat, tab complete) race each other, so compare them sorted.
        ev = collapse([norm(e, ent, tok) for e in body if e["k"] == "ev" and e["n"] not in ("mark", "ground", "breakSpeed") and e["th"] != "async"])
        ev_async = sorted(norm(e, ent, tok) for e in body if e["k"] == "ev" and e["th"] == "async")
        late = sorted(norm(e, ent, tok) for e in after_mark)
        moves = op in ("move", "jump", "fly")
        pk = collapse([norm(e, ent, tok) for e in body if e["k"] == "pk" and (moves or e["n"] != "MovePlayer")])
        notes = {k: v for k, v in res.items() if k not in ("ok",)}
        raw_ev = [f'{e["n"]}:{e["d"]}' for e in log if e["k"] == "ev"]
        ok = outcome(name, raw_ev, notes, tok)
        held = [int(m) for e in body for m in re.findall(r"held=(\d+)", e["d"])]
        kinds = list(dict.fromkeys(e.split(":", 1)[0] for e in ev + ev_async))
        return {"op": name, "path": path, "ok": ok, "held": held, "kinds": kinds, "scriptOk": res.get("ok"), "ev": ev, "evAsync": ev_async, "late": late, "pk": pk, "notes": notes,
                "input_s": round(t1 - t0, 4), "mark_s": round(t2 - t1, 4), "total_s": round(t2 - t0, 4),
                "ticks": res.get("ticks"), "raw": [f'{e["tick"]} {e["th"]} {e["k"]} {e["n"]} {e["d"]}' for e in log if e["n"] not in ("MovePlayer",)], "threads": collapse([e["th"] for e in body if e["k"] == "ev"])}

    def wait_mark(self, seq0, mark, timeout=10):
        deadline = time.time() + timeout
        while time.time() < deadline:
            log = self.S("in.log", _dispatch="direct", player=self.p, since=seq0)["log"]
            for e in log:
                if e["n"] == "mark" and e["d"] == str(mark):
                    return log, time.perf_counter()
            time.sleep(0.002)
        raise RuntimeError(f"mark {mark} never arrived")


def renorm(rows):
    """Offline re-judging: typed prefixes of the unique token ('t1', 't12', ...) count as one name."""
    tokre = re.compile(r"\bt\d+\b|\bt\b(?=[ '\]]|$)")
    def fix(xs):
        return [re.sub(r" gt=\d+ start=\d+ bt=\d+( ground=\w+)?", "", tokre.sub("tN", re.sub(r"held=\d+", "held=N", x))) for x in xs]
    for r in rows:
        r["ev"] = collapse(fix(r.get("ev", [])))
        r["evAsync"] = sorted(fix(r.get("evAsync") or []))
        r["pk"] = collapse(fix(r.get("pk", [])))
        r["kinds"] = list(dict.fromkeys(e.split(":", 1)[0] for e in r["ev"] + r["evAsync"]))
    return rows


def cmd_report(a):
    rows = []
    for t in a.traces:
        with gzip.open(t, "rt") as f:
            rows += [json.loads(l) for l in f]
    rows = renorm([r for r in rows if "error" not in r])
    summ = summarize(rows)
    print_summary(summ)
    return summ


def summarize(rows):
    by = collections.defaultdict(list)
    for r in rows:
        by[(r["op"], r["path"])].append(r)
    ref = {}
    for (op, path), rs in by.items():
        if path == "J2":
            ref[op] = collections.Counter(json.dumps([r["ev"], r.get("evAsync"), r["pk"]]) for r in rs).most_common(1)[0][0]
    ref_kinds = {op: json.loads(collections.Counter(json.dumps(r.get("kinds")) for r in by[(op, "J2")]).most_common(1)[0][0])
                 for (op, path) in by if path == "J2"}
    out = []
    for (op, path), rs in sorted(by.items()):
        sigs = collections.Counter(json.dumps([r["ev"], r.get("evAsync"), r["pk"]]) for r in rs)
        mode, count = sigs.most_common(1)[0]
        evsig = collections.Counter(json.dumps(r["ev"]) for r in rs)
        r_ev = json.loads(ref[op])[:2] if op in ref else None
        r_pk = json.loads(ref[op])[2] if op in ref else None
        out.append({
            "op": op, "path": path, "n": len(rs), "ok": sum(r["ok"] for r in rs),
            "flake": len(rs) - count, "variants": len(sigs),
            "kindsFlake": len(rs) - collections.Counter(json.dumps(r.get("kinds")) for r in rs).most_common(1)[0][1],
            "sameKindsAsJ2": sum(r.get("kinds") == ref_kinds.get(op) for r in rs) if op in ref_kinds else None,
            "held": dict(collections.Counter(h for r in rs for h in r.get("held", []))),
            "sameEvAsJ2": sum([r["ev"], r.get("evAsync")] == r_ev for r in rs) if r_ev is not None else None,
            "samePkAsJ2": sum(r["pk"] == r_pk for r in rs) if r_pk is not None else None,
            "median_s": speed.stat([r["total_s"] for r in rs])["median"], "p95_s": speed.stat([r["total_s"] for r in rs])["p95"],
            "ticks": speed.stat([r["ticks"] for r in rs if r["ticks"] is not None]),
            "modeEv": json.loads(mode)[0], "modeEvAsync": json.loads(mode)[1], "modePk": json.loads(mode)[2],
        })
    return out


def print_summary(summ):
    for s in summ:
        print(f'{s["op"]:15} {s["path"]:3} n={s["n"]:4} ok={s["ok"]:4} flake={s["flake"]:3} kflake={s["kindsFlake"]:3} kJ2={s["sameKindsAsJ2"]} var={s["variants"]:2} '
              f'evJ2={s["sameEvAsJ2"]} pkJ2={s["samePkAsJ2"]} med={s["median_s"]:.3f} p95={s["p95_s"]:.3f}')


def session(a, label):
    return speed.Session(label, dispatch="tick", keep=getattr(a, "keep", False))


def setup(b, a):
    b.C("in.setup", focus=a.focus, grab=a.grab)
    if b.xtest and a.grab == "real":
        assert b.xtest.grab(), "XTest click did not grab the mouse"
    if a.rate != 20:
        b.S("tickrate", rate=a.rate)
        b.C("uncap", on=1)
    b.C("gate", mode=a.gate)
    b.S("time", player=b.p)


def cmd_run(a, xtest=None, session_factory=None):
    paths = a.paths.split(",")
    ops = list(OPS) if a.ops == "all" else a.ops.split(",")
    OUT.mkdir(parents=True, exist_ok=True)
    stamp = int(time.time())
    trace = OUT / f"{a.label}-run-g{a.gate}-r{int(a.rate)}-{stamp}.jsonl.gz"
    load0 = os.getloadavg()
    rows = []
    with (session_factory or session)(a, f"j-{a.label}") as s:
        front0 = s.front
        b = Bench(s, xtest(s) if xtest else None)
        setup(b, a)
        t0 = time.time()
        with gzip.open(trace, "wt") as f:
            for rep in range(a.n):
                for name in ops:
                    for path in paths:
                        if (name, path) in SKIP:
                            continue
                        try:
                            r = b.one(name, path)
                        except Exception as e:
                            r = {"op": name, "path": path, "ok": False, "error": str(e), "ev": [], "pk": [], "total_s": 0, "ticks": None}
                        r["rep"] = rep
                        rows.append(r)
                        f.write(json.dumps(r) + "\n")
                if rep % 10 == 0:
                    print(f"rep {rep} {time.time() - t0:.0f}s load {os.getloadavg()[0]:.1f}", flush=True)
        wall = time.time() - t0
        front1 = front_app()
    summ = summarize([r for r in rows if "error" not in r])
    errors = collections.Counter((r["op"], r["path"], r["error"][:120]) for r in rows if "error" in r)
    print_summary(summ)
    for k, v in errors.items():
        print("error", v, k)
    row = {"kind": "run", "label": a.label, "gate": a.gate, "rate": a.rate, "paths": paths, "n": a.n, "wall_s": round(wall, 1),
           "load_start": load0[0], "load_end": os.getloadavg()[0], "front": [front0, front1], "trace": str(trace),
           "errors": [[*k, v] for k, v in errors.items()], "summary": summ}
    with open(RESULTS, "a") as f:
        f.write(json.dumps(row) + "\n")
    leak_check()
    return row


def cmd_lag(a, xtest=None, session_factory=None):
    """A lag spike lands in the middle of each input: client thread sleep or server main thread sleep."""
    paths = a.paths.split(",")
    ops = a.ops.split(",")
    OUT.mkdir(parents=True, exist_ok=True)
    trace = OUT / f"{a.label}-lag-{a.where}{a.ms}-g{a.gate}-r{int(a.rate)}-{int(time.time())}.jsonl.gz"
    load0 = os.getloadavg()
    rows = []
    with (session_factory or session)(a, f"j-{a.label}") as s:
        b = Bench(s, xtest(s) if xtest else None)
        setup(b, a)

        # The spike thread gets its own connection: two threads on one line mix up the replies.
        side = speed.Line(b.C.port) if a.where == "client" else None

        def spike(bb):
            if a.where == "server":
                bb.S("in.lag", player=bb.p, ms=a.ms, after=a.after)
            else:
                # Client: sleep the client thread a few ticks into the input, from another thread.
                import threading
                def later():
                    time.sleep(a.after / max(1, a.rate))
                    side("r.lag", ms=a.ms)
                threading.Thread(target=later, daemon=True).start()

        with gzip.open(trace, "wt") as f:
            for rep in range(a.n):
                for name in ops:
                    for path in paths:
                        for lag in (False, True):
                            try:
                                r = b.one(name, path, before=spike if lag else None)
                            except Exception as e:
                                r = {"op": name, "path": path, "ok": False, "error": str(e), "ev": [], "pk": [], "total_s": 0, "ticks": None}
                            r["lag"] = lag
                            r["rep"] = rep
                            rows.append(r)
                            f.write(json.dumps(r) + "\n")
    out = []
    for name in ops:
        for path in paths:
            calm = [r for r in rows if r["op"] == name and r["path"] == path and not r["lag"] and "error" not in r]
            lagged = [r for r in rows if r["op"] == name and r["path"] == path and r["lag"]]
            ref = collections.Counter(json.dumps([r["ev"], r.get("evAsync"), r["pk"]]) for r in calm).most_common(1)[0][0] if calm else None
            same = sum(json.dumps([r["ev"], r.get("evAsync"), r["pk"]]) == ref for r in lagged)
            diffs = collections.Counter(json.dumps([r["ev"], r["notes"].get("ticks") if "notes" in r else None]) for r in lagged if json.dumps([r["ev"], r.get("evAsync"), r["pk"]]) != ref)
            out.append({"op": name, "path": path, "n": len(lagged), "ok": sum(r["ok"] for r in lagged), "okCalm": sum(r["ok"] for r in calm),
                        "sameAsCalm": same, "errors": sum("error" in r for r in lagged), "exampleDiff": diffs.most_common(1)[0][0] if diffs else None})
            print(f'{name:12} {path:3} lag n={len(lagged)} ok={out[-1]["ok"]} calmOk={out[-1]["okCalm"]} same={same} err={out[-1]["errors"]}')
    row = {"kind": "lag", "label": a.label, "where": a.where, "ms": a.ms, "after": a.after, "gate": a.gate, "rate": a.rate, "n": a.n,
           "load_start": load0[0], "load_end": os.getloadavg()[0], "trace": str(trace), "summary": out}
    with open(RESULTS, "a") as f:
        f.write(json.dumps(row) + "\n")
    leak_check()
    return row


def args(argv=None):
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    for name in ("run", "lag"):
        p = sub.add_parser(name)
        p.add_argument("--paths", default="J2,J1,J3,J4")
        p.add_argument("--ops", default="all")
        p.add_argument("--n", type=int, default=5)
        p.add_argument("--gate", type=int, default=2)
        p.add_argument("--rate", type=float, default=20)
        p.add_argument("--label", default="mac")
        p.add_argument("--focus", default="fake")
        p.add_argument("--grab", default="fake")
        p.add_argument("--keep", action="store_true")
        if name == "lag":
            p.add_argument("--where", default="client")
            p.add_argument("--ms", type=int, default=300)
            p.add_argument("--after", type=int, default=3, help="ticks into the input")
    r = sub.add_parser("report")
    r.add_argument("traces", nargs="+")
    return ap.parse_args(argv)


def main():
    a = args()
    {"run": cmd_run, "lag": cmd_lag, "report": cmd_report}[a.cmd](a)


if __name__ == "__main__":
    main()
