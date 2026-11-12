#!/usr/bin/env python3
"""In process input prototype: the client mod sends real window input itself, under stepped ticks.

  inproc.py fid --paths J2,XF --setup real --ops all --n 100 --gates 2,0     J's 17 inputs, compared with J2
  inproc.py cross --path XF --setup real --n 50 [--clients 4]                every client sends at the same step
  inproc.py sug --paths J2,J1,XF --setup real --n 200 [--pool 4] [--retry 0] typed suggestions, why some get no reply
  inproc.py report <trace.jsonl.gz>...                                       tables again from kept traces

Paths, all sent from inside the client process:
  J2   the client's input handlers (spike J's reference)
  J1   SDL_PushEvent into the client's own SDL queue (spike J's Mac path)
  XF   XTest through the foreign function API on the client's own X connection (Linux)
  XS   XSendEvent to the client's own X window (Linux), real focus and real grab taken by a sent click
  XSf  XSendEvent with real focus and the probe grab (no SDL relative mode)

Setups: fake (probe focus and grab), real (X focus on the own window, grab by an XTest click), send (X focus,
grab by a sent click), fakegrab (X focus, probe grab). Paper runs with the step agent, the break clock in ticks,
and auto stepping: a tick runs as soon as every subject client acked the last one. Every command stops what it
started and checks for leftover processes.
"""
import argparse, collections, gzip, json, os, pathlib, random, statistics, sys, threading, time

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import n as N
import input as I
from run import RUNS, leak_check, front_app

OUT = RUNS / "inproc"
RESULTS = RUNS / "inproc.jsonl"
hooks = {"record": None}


def load():
    return round(os.getloadavg()[0], 1)


def record(kind, **row):
    row = {"kind": kind, "at": time.strftime("%Y-%m-%dT%H:%M:%S"), "load": load(), **row}
    RUNS.mkdir(exist_ok=True)
    with RESULTS.open("a") as f:
        f.write(json.dumps(row) + "\n")
    if hooks["record"]:
        hooks["record"]("inproc-" + kind, **{k: v for k, v in row.items() if k != "kind"})
    print(json.dumps(row)[:4000], flush=True)


def stat(v, nd=3):
    v = sorted(x for x in v if x is not None)
    if not v:
        return None
    return {"n": len(v), "med": round(statistics.median(v), nd), "p95": round(v[min(len(v) - 1, int(len(v) * 0.95))], nd), "min": round(v[0], nd), "max": round(v[-1], nd)}


def setup_client(C, setup, wait_ticks):
    """Focus and grab for one client. Returns what the client reports after the setup."""
    if setup == "fake":
        C("in.setup", focus="fake", grab="fake")
    elif setup in ("real", "send"):
        C("in.setup", focus="real", grab="real")
        x = C("in.xsetup", focus=1, click="xtest" if setup == "real" else "send")
        assert x.get("ok"), x
    elif setup == "fakegrab":
        C("in.setup", focus="real", grab="fake")
        x = C("in.xsetup", focus=1, click="")
        assert x.get("ok"), x
    else:
        raise ValueError(setup)
    wait_ticks(4)
    st = C("in.state")
    return {"focused": st["focused"], "grabbed": st["grabbed"]}


class Stepped:
    """The stepped rig with auto stepping: ticks run as fast as the subjects ack."""

    def __init__(self, label, clients=1):
        self.rig = N.Rig(label, lag="tick", clients=clients)

    def __enter__(self):
        self.rig.__enter__()
        r = self.rig
        names = ",".join(c.name for c in r.clients)
        for c in r.clients:
            c.C("n.mode", on=1)
        r.S("n.mode", _dispatch="direct", on=1, subject=names, ack=1, quiet=1, auto=1, limitMs=1000, lag="tick")
        return self

    def __exit__(self, *exc):
        r = self.rig
        try:
            r.S("n.mode", _dispatch="direct", on=0, auto=0)
            for c in r.clients:
                c.C("n.mode", on=0)
        except Exception as e:
            print("step off:", e, file=sys.stderr)
        return r.__exit__(*exc)

    def auto(self, on):
        self.rig.S("n.mode", _dispatch="direct", auto=int(on))

    def tick(self):
        return self.rig.S("n.stats", _dispatch="direct")["tick"]

    def wait_ticks(self, n, timeout=20):
        t0, deadline = self.tick(), time.time() + timeout
        while self.tick() < t0 + n:
            if time.time() > deadline:
                raise RuntimeError("stepping stalled")
            time.sleep(0.002)


# ---------- fidelity: J's inputs per path, compared with J2 under the same stepping ----------

def one(b, op, path):
    r = b.one(op, path)
    nt = r.get("notes", {})
    step = nt.get("injectStep")
    r["latEv"] = (r["firstEvSt"] - step) if step is not None and step >= 0 and r.get("firstEvSt") is not None else None
    r["latPk"] = (r["firstPkSt"] - step) if step is not None and step >= 0 and r.get("firstPkSt") is not None else None
    return r


def summarize(rows):
    out = []
    by_gate = collections.defaultdict(list)
    for r in rows:
        by_gate[r["gate"]].append(r)
    for gate, rs in sorted(by_gate.items()):
        rs = I.renorm([r for r in rs if "error" not in r])
        for s in I.summarize(rs):
            cell = [r for r in rs if r["op"] == s["op"] and r["path"] == s["path"]]
            nt = lambda k: [r["notes"].get(k) for r in cell]
            out.append({"gate": gate, **{k: s[k] for k in ("op", "path", "n", "ok", "variants", "sameEvAsJ2", "samePkAsJ2", "sameKindsAsJ2", "median_s", "p95_s")},
                        "latEv": dict(collections.Counter(r.get("latEv") for r in cell)), "latPk": dict(collections.Counter(r.get("latPk") for r in cell)),
                        "handledDelay": dict(collections.Counter(nt("handledDelay"))), "handledInTick": dict(collections.Counter(nt("handledInTick"))),
                        "injectUs": stat(nt("injectUs"), 1), "injectN": stat(nt("injectN"), 1), "injectMaxUs": stat(nt("injectMaxUs"), 1),
                        "ticks": stat([r.get("ticks") for r in cell], 1),
                        "modeEv": s["modeEv"][:12], "modePk": s["modePk"][:12]})
        errors = collections.Counter((r["op"], r["path"], r["error"][:160]) for r in by_gate[gate] if "error" in r)
        for k, v in errors.items():
            out.append({"gate": gate, "op": k[0], "path": k[1], "errors": v, "error": k[2]})
    return out


def print_summary(summ):
    for s in summ:
        if "errors" in s:
            print(f'g{s["gate"]} {s["op"]:15} {s["path"]:4} ERRORS {s["errors"]} {s["error"]}')
            continue
        print(f'g{s["gate"]} {s["op"]:15} {s["path"]:4} n={s["n"]:4} ok={s["ok"]:4} var={s["variants"]:2} evJ2={s["sameEvAsJ2"]} pkJ2={s["samePkAsJ2"]} '
              f'latEv={s["latEv"]} hd={s["handledDelay"]} inj={s["injectUs"] and s["injectUs"]["med"]}us med={s["median_s"]:.3f}', flush=True)


def cmd_fid(a):
    paths, ops = a.paths.split(","), (list(I.OPS) if a.ops == "all" else a.ops.split(","))
    ops = [o for o in ops if o != "breakDirt"]
    OUT.mkdir(parents=True, exist_ok=True)
    trace = OUT / f"{a.label}-fid-{a.setup}-{'-'.join(paths)}-{int(time.time())}.jsonl.gz"
    rows, meta = [], {"label": a.label, "paths": paths, "setup": a.setup, "n": a.n, "gates": a.gates, "load_start": load(), "front": front_app()}
    t0 = time.time()
    with Stepped(f"inproc-{a.label}") as sp:
        rig = sp.rig
        b = I.Bench(N.Shim(rig))
        meta["setup_state"] = setup_client(rig.C, a.setup, sp.wait_ticks)
        with gzip.open(trace, "wt") as f:
            for gate in [int(g) for g in a.gates.split(",")]:
                rig.C("gate", mode=gate, parkMicros=2000)
                for rep in range(a.n):
                    for op in ops:
                        for path in paths:
                            if (op, path) in I.SKIP:
                                continue
                            try:
                                r = one(b, op, path)
                            except Exception as e:
                                r = {"op": op, "path": path, "ok": False, "error": str(e)[:300], "ev": [], "pk": [], "total_s": 0, "ticks": None}
                            r.update(rep=rep, gate=gate)
                            rows.append(r)
                            f.write(json.dumps(r) + "\n")
                    if rep % 10 == 0:
                        print(f"g{gate} rep {rep} {time.time() - t0:.0f}s load {load()}", flush=True)
        meta["setup_state_end"] = rig.C("in.state")
    meta.update(wall_s=round(time.time() - t0, 1), load_end=load(), front_end=front_app(), trace=str(trace))
    summ = summarize(rows)
    print_summary(summ)
    record("fid", meta=meta, summary=summ)
    leak_check()


# ---------- cross talk: every client sends at the same step ----------

def cmd_cross(a):
    OUT.mkdir(parents=True, exist_ok=True)
    meta = {"label": a.label, "path": a.path, "setup": a.setup, "n": a.n, "clients": a.clients, "display": a.display, "load_start": load(), "front": front_app()}
    rounds = []
    t0 = time.time()
    with Stepped(f"inproc-cross-{a.label}", clients=a.clients) as sp:
        rig = sp.rig
        names = [c.name for c in rig.clients]
        meta["setup_state"] = [setup_client(c.C, a.setup, sp.wait_ticks) for c in rig.clients]
        meta["xsetup"] = [c.C("in.state") for c in rig.clients]
        for rep in range(a.n):
            sp.auto(False)
            rig.S("x.arrange", _dispatch="direct", players=",".join(names))
            for c in rig.clients:
                c.C("in.reset")
            sp.auto(True)
            sp.wait_ticks(5)
            sp.auto(False)
            at = sp.tick() + 3
            toks = [f"q{random.randrange(10**6)}" for _ in names]
            res = [None] * len(names)

            def go(i, c):
                try:
                    res[i] = c.C("in.run", path=a.path, op="cross", atStep=at, n=i + 1, hold=2 * (i + 1), turn=15 * (i + 1), tok=toks[i], mark=0)
                except Exception as e:
                    res[i] = {"ok": False, "error": str(e)[:200]}

            th = [threading.Thread(target=go, args=(i, c)) for i, c in enumerate(rig.clients)]
            for t in th:
                t.start()
            time.sleep(0.3)  # every request has reached its client before the ticks run
            sp.auto(True)
            for t in th:
                t.join(90)
            sp.wait_ticks(4)
            log = rig.S("x.log", _dispatch="direct")["log"]
            state = rig.S("x.state", _dispatch="direct", players=",".join(names))["players"]
            rounds.append(judge_cross(names, toks, res, log, state, rep))
            if rep % 10 == 0:
                print(f"cross rep {rep} {time.time() - t0:.0f}s {rounds[-1]['verdict']}", flush=True)
    meta.update(wall_s=round(time.time() - t0, 1), load_end=load(), front_end=front_app())
    summ = summarize_cross(rounds)
    OUT.joinpath(f"{a.label}-cross-{a.path}-{a.display}-{int(time.time())}.json").write_text(json.dumps({"meta": meta, "rounds": rounds}))
    record("cross", meta=meta, summary=summ)
    leak_check()


def judge_cross(names, toks, res, log, state, rep):
    """Per client: did its own player get exactly its own inputs, and did any other player get them."""
    per = []
    by = collections.defaultdict(list)
    for e in log:
        by[e["p"]].append(e)
    for i, name in enumerate(names):
        mine = by.get(name, [])
        held = [e["d"] for e in mine if e["k"] == "held"]
        sneak = [e for e in mine if e["k"] == "sneak"]
        chats = [e["d"] for e in mine if e["k"] == "chat"]
        r = res[i] or {}
        own = {
            "held": held == [f"0->{i + 1}"],
            "sneak": [e["d"] for e in sneak] == ["true", "false"],
            "sneakTicks": (sneak[1]["st"] - sneak[0]["st"]) if len(sneak) == 2 else None,
            "chat": chats == [f"x{i + 1} {toks[i]}"],
            "turned": r.get("turned"),
            "turnOk": r.get("turned") is not None and abs(float(r.get("turned")) - 15 * (i + 1)) < 1.0,
        }
        # Content that belongs to another client, found on this player.
        foreign = [h for h in held if h != f"0->{i + 1}" and any(h.endswith(f"->{j + 1}") for j in range(len(names)) if j != i)]
        foreign += [c for c in chats if any(toks[j] in c for j in range(len(names)) if j != i)]
        per.append({"name": name, **own, "foreign": foreign, "slotClient": r.get("slot"), "ifm": r.get("ifm"), "ifmAfter": r.get("ifmAfter"), "active": r.get("active"), "movesSeen": r.get("movesSeen"), "focused": r.get("focused"), "grabbed": r.get("grabbed"),
                    "startStep": r.get("startStep"), "injectStep": r.get("injectStep"), "error": r.get("error"), "scriptOk": r.get("ok")})
    wrong = sum(len(p["foreign"]) for p in per)
    lost = sum(1 for p in per for k in ("held", "sneak", "chat", "turnOk") if not p[k])
    starts = {p["startStep"] for p in per}
    return {"rep": rep, "per": per, "wrong": wrong, "lost": lost, "sameStart": len(starts) == 1, "verdict": "wrong" if wrong else ("lost" if lost else "clean")}


def summarize_cross(rounds):
    v = collections.Counter(r["verdict"] for r in rounds)
    per_client = []
    if rounds:
        for i in range(len(rounds[0]["per"])):
            ps = [r["per"][i] for r in rounds]
            per_client.append({"name": ps[0]["name"], **{k: sum(bool(p[k]) for p in ps) for k in ("held", "sneak", "chat", "turnOk")},
                               "foreign": sum(len(p["foreign"]) for p in ps), "sneakTicks": dict(collections.Counter(p["sneakTicks"] for p in ps)),
                               "turned": dict(collections.Counter(p["turned"] for p in ps).most_common(4)),
                               "focused": dict(collections.Counter(p["focused"] for p in ps)), "grabbed": dict(collections.Counter(p["grabbed"] for p in ps)),
                               "errors": sum(1 for p in ps if p["error"]), "ifm": dict(collections.Counter(p.get("ifm") for p in ps)), "movesSeen": dict(collections.Counter(p.get("movesSeen") for p in ps)), "active": dict(collections.Counter(p.get("active") for p in ps))})
    return {"rounds": len(rounds), "verdicts": dict(v), "wrongEvents": sum(r["wrong"] for r in rounds), "lostChecks": sum(r["lost"] for r in rounds),
            "sameStartStep": sum(r["sameStart"] for r in rounds), "perClient": per_client,
            "exampleWrong": next((r for r in rounds if r["wrong"]), None)}


# ---------- suggestions: which typed requests get a reply ----------

def classify_suggest(r):
    """From the server log: typed requests in arrival order, the order Paper's pool handed them on, what ran."""
    raw = r.get("raw", [])
    pk = [x.split(" ", 4)[4] for x in raw if x.split(" ")[2] == "pk" and x.split(" ")[3] == "CommandSuggestion"]
    asy = [x.split(" ", 4)[4] for x in raw if x.split(" ")[3] == "AsyncTabCompleteEvent"]
    ran = [x.split(" ", 4)[4] if len(x.split(" ", 4)) > 4 else "" for x in raw if x.split(" ")[3] == "ClaimTabCompleter"]
    sent = [x.split(" ", 4)[4] for x in raw if x.split(" ")[3] == "AsyncPlayerSendSuggestionsEvent"]
    reordered = bool(pk) and bool(asy) and asy[-1] != pk[-1]
    return {"pk": pk, "async": asy, "ran": ran, "sent": sent, "reordered": reordered, "lastRanIsLast": bool(ran) and bool(pk) and pk[-1].endswith(ran[-1])}


def cmd_sug(a):
    paths = a.paths.split(",")
    OUT.mkdir(parents=True, exist_ok=True)
    trace = OUT / f"{a.label}-sug-p{a.pool}-r{a.retry}-{int(time.time())}.jsonl.gz"
    I.OPS["suggest"][1]["retry"] = a.retry
    rows, t0 = [], time.time()
    meta = {"label": a.label, "paths": paths, "setup": a.setup, "n": a.n, "pool": a.pool, "retry": a.retry, "load_start": load()}
    with Stepped(f"inproc-sug-{a.label}") as sp:
        rig = sp.rig
        b = I.Bench(N.Shim(rig))
        meta["setup_state"] = setup_client(rig.C, a.setup, sp.wait_ticks)
        meta["pool_set"] = rig.S("in.tabpool", _dispatch="direct", n=a.pool)
        rig.C("gate", mode=a.gate, parkMicros=2000)
        with gzip.open(trace, "wt") as f:
            for rep in range(a.n):
                for path in paths:
                    try:
                        r = one(b, "suggest", path)
                        r["cls"] = classify_suggest(r)
                    except Exception as e:
                        r = {"op": "suggest", "path": path, "ok": False, "error": str(e)[:300]}
                    r["rep"] = rep
                    rows.append(r)
                    f.write(json.dumps(r) + "\n")
                if rep % 50 == 0:
                    print(f"sug rep {rep} {time.time() - t0:.0f}s", flush=True)
    summ = []
    for path in paths:
        rs = [r for r in rows if r["path"] == path and "error" not in r]
        bad = [r for r in rs if not r["ok"]]
        summ.append({"path": path, "n": len(rs), "ok": len(rs) - len(bad), "errors": sum(1 for r in rows if r["path"] == path and "error" in r),
                     "retried": sum(1 for r in rs if r["notes"].get("retried")), "retriedOk": sum(1 for r in rs if r["notes"].get("retried") and r["ok"]),
                     "reorderedAll": sum(r["cls"]["reordered"] for r in rs), "reorderedBad": sum(r["cls"]["reordered"] for r in bad),
                     "badLastRanIsLast": sum(r["cls"]["lastRanIsLast"] for r in bad),
                     "requests": dict(collections.Counter(len(r["cls"]["pk"]) for r in rs)),
                     "suggestTicks": dict(collections.Counter(r["notes"].get("suggestTicks") for r in rs if r["ok"])),
                     "exampleBad": [{"cls": r["cls"], "notes": {k: r["notes"].get(k) for k in ("suggestions", "suggestTicks", "retried", "drawnHasWant")}} for r in bad[:3]]})
    meta.update(wall_s=round(time.time() - t0, 1), load_end=load(), trace=str(trace))
    record("sug", meta=meta, summary=summ)
    leak_check()


def cmd_report(a):
    rows = []
    for t in a.traces:
        with gzip.open(t, "rt") as f:
            rows += [json.loads(l) for l in f]
    print_summary(summarize(rows))


# ---------- CI: one matrix row runs a list of commands on the free runner ----------

CI_ROWS = {
    "smoke": [
        "fid --paths J2,XF --setup real --ops all --n 2 --gates 2",
        "fid --paths J2,XS --setup send --ops all --n 2 --gates 2",
        "fid --paths J2,XSf --setup fakegrab --ops all --n 2 --gates 2",
        "fid --paths J2,J1 --setup fake --ops all --n 2 --gates 2",
        "cross --path XF --setup real --n 3 --display own",
        "cross --path XF --setup real --n 3 --display shared",
        "cross --path XSf --setup fake --n 3 --display shared",
        "cross --path J1 --setup fake --n 3 --display shared",
        "sug --paths J2,J1,XF --setup real --n 10",
    ],
    "crossdbg": [
        "cross --path XF --setup real --n 10 --display own --clients 1",
        "cross --path XF --setup real --n 10 --display own",
    ],
    # Cross talk first: the cheap rows tell whether the long ones are worth their time.
    "crossown": [
        "cross --path XF --setup real --n 50 --display own",
        "cross --path J1 --setup fake --n 50 --display own",
        "cross --path XSf --setup fake --n 30 --display own",
    ],
    "crossshared": [
        "cross --path XF --setup real --n 30 --display shared",
        "cross --path XSf --setup fake --n 30 --display shared",
        "cross --path J1 --setup fake --n 50 --display shared",
    ],
    "fidxf": ["fid --paths J2,XF --setup real --ops all --n 100 --gates 2"],
    "fidj1": ["fid --paths J2,J1 --setup fake --ops all --n 100 --gates 2"],
    "fidxs": [
        "fid --paths J2,XS --setup send --ops all --n 30 --gates 2",
        "fid --paths J2,XSf --setup fakegrab --ops all --n 30 --gates 2",
    ],
    "rendered": [
        "fid --paths J2,XF --setup real --ops all --n 20 --gates 0",
        "fid --paths J2,J1 --setup fake --ops all --n 20 --gates 0",
        "fid --paths J2,XS --setup send --ops all --n 10 --gates 0",
    ],
    "sug": [
        "sug --paths J2,J1,XF --setup real --n 300 --pool 4",
        "sug --paths J2,J1,XF --setup real --n 300 --pool 1",
        "sug --paths J2,J1,XF --setup real --n 200 --pool 4 --retry 6",
        "sug --paths J2,J1,XF --setup real --n 100 --pool 4 --gate 0",
    ],
}


def ci_hooks(backend, display):
    """Xvfb per client (own) or one Xvfb for every client (shared); the runner's renderer checks; h.jsonl records."""
    import ci, k, shutil
    cfg = ci.Cfg(backend=backend)
    owned = []

    def env(i):
        if display == "shared" and owned:
            return cfg.env(owned[0].name)
        x = ci.Xvfb().start()
        owned.append(x)
        return cfg.env(x.name)

    def cleanup(rig):
        for x in owned:
            x.stop()
        owned.clear()
        for sub in sorted(rig.run.glob("*")):
            dest = ci.EVIDENCE / rig.run.name / sub.name
            for log in ("client.log", "server.log"):
                src = sub / log
                if src.exists():
                    dest.mkdir(parents=True, exist_ok=True)
                    (dest / log).write_bytes(src.read_bytes()[-300_000:])
            for crash in sub.rglob("hs_err*.log"):
                dest.mkdir(parents=True, exist_ok=True)
                shutil.copy(crash, dest / crash.name)

    k.hooks.update({"env": env, "client_kw": {"backend": backend, "background_app": False},
                    "after_join": lambda c: ci.renderer_row(ci.assert_renderer(c, backend)), "record": ci.record, "cleanup": cleanup})
    hooks["record"] = ci.record
    N.hooks["record"] = ci.record


def cmd_ci(a):
    import ci
    from run import stop_all
    RUNS.mkdir(exist_ok=True)
    ci.collect_meta()
    ci.record("start", plan=f"inproc-{a.row}", backend=a.backend)
    try:
        for line in CI_ROWS[a.row]:
            argv = line.split() + ["--label", f"ci-{a.row}"]
            display = argv[argv.index("--display") + 1] if "--display" in argv else "own"
            ci_hooks(a.backend, display)
            ci.step(f"inproc {line}", main, argv)
    finally:
        stop_all()
        for d in list(ci.displays):
            d.stop()
    ci.record("end", failures=ci.failures, leaks=leak_check(), elapsed_s=round(ci.elapsed()))
    sys.exit(1 if ci.failures else 0)


def main(argv=None):
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    g = sub.add_parser("ci")
    g.add_argument("--row", default=os.environ.get("INPROC_ROW", "smoke"))
    g.add_argument("--backend", default="vulkan")
    f = sub.add_parser("fid")
    f.add_argument("--paths", default="J2,J1")
    f.add_argument("--setup", default="fake")
    f.add_argument("--ops", default="all")
    f.add_argument("--n", type=int, default=5)
    f.add_argument("--gates", default="2")
    f.add_argument("--label", default="mac")
    c = sub.add_parser("cross")
    c.add_argument("--path", default="J1")
    c.add_argument("--setup", default="fake")
    c.add_argument("--n", type=int, default=20)
    c.add_argument("--clients", type=int, default=4)
    c.add_argument("--display", default="own")
    c.add_argument("--label", default="mac")
    s = sub.add_parser("sug")
    s.add_argument("--paths", default="J2,J1")
    s.add_argument("--setup", default="fake")
    s.add_argument("--n", type=int, default=50)
    s.add_argument("--pool", type=int, default=4)
    s.add_argument("--retry", type=int, default=0)
    s.add_argument("--gate", type=int, default=2)
    s.add_argument("--label", default="mac")
    r = sub.add_parser("report")
    r.add_argument("traces", nargs="+")
    a = ap.parse_args(argv)
    {"fid": cmd_fid, "cross": cmd_cross, "sug": cmd_sug, "report": cmd_report, "ci": cmd_ci}[a.cmd](a)


if __name__ == "__main__":
    main()
