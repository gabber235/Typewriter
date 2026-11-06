#!/usr/bin/env python3
"""Spike I: which plugin lines does each requirement cover, on one long lived Paper.

  coverage.py loop --cov off|agent|rt|tcp [--dispatch direct|tick] [--rate 200] [--gate 2] [--n 1000]
                   [--group 1] [--barrier naive|wait:K|quiet] [--kinds base|trap] [--includes probe.plugin.*] [--analyze]
  coverage.py boot --cov off|agent [--includes '*'] --repeat 3
  coverage.py intersect <lines.jsonl>      fake diffs against a saved run

The loop is spike C's R4 requirement (act, observe, reset, state) with one coverage step added.
Every command stops what it started; leak_check at the end. Results append to runs/i-coverage.jsonl.
"""
import argparse, json, os, pathlib, re, socket, statistics, struct, subprocess, sys, time

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import run as R
import speed
from run import RUNS, ROOT, free_port, leak_check
from speed import Line, needle_for, leftovers, stat, pct, cpu_seconds

RESULTS = RUNS / "i-coverage.jsonl"
OUT = RUNS / "i-coverage"
TOOL = json.loads((ROOT / "coverage-tool/build/coverage-tool.json").read_text())
SRC = ROOT / "probe-plugin/src/main/java/probe/plugin"
BASE = ["title", "chat", "block", "entity"]
TRAP = ["title", "tailTick", "chat", "tailAsync", "block", "tailRaw", "entity"]
MATERIALS = speed.MATERIALS


def agent_jvm(cov, label, includes, tcp_port=None):
    if cov == "off":
        return [], None
    classes = OUT / f"{label}-classes"
    opts = [f"includes={includes}", f"classdumpdir={classes}", "dumponexit=false"]
    if cov == "tcp":
        opts += ["output=tcpserver", "address=127.0.0.1", f"port={tcp_port}"]
    else:
        opts += ["output=none"]
    return [f"-javaagent:{TOOL['agent']}=" + ",".join(opts)], classes


class JacocoTcp:
    """JaCoCo's remote control protocol: header, then 0x40 dump reset; reply blocks end with 0x20."""
    HEADER = b"\x01" + struct.pack(">HH", 0xC0C0, 0x1007)

    def __init__(self, port):
        deadline = time.time() + 60
        while True:
            try:
                self.s = socket.create_connection(("127.0.0.1", port), timeout=30)
                break
            except OSError:
                if time.time() > deadline:
                    raise
                time.sleep(0.1)
        self.s.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
        self.f = self.s.makefile("rb")
        self.s.sendall(self.HEADER)
        assert self.f.read(5) == self.HEADER

    def utf(self, out):
        raw = self.f.read(2)
        n = struct.unpack(">H", raw)[0]
        out += raw + self.f.read(n)

    def varint(self, out):
        v, shift = 0, 0
        while True:
            b = self.f.read(1)
            out += b
            v |= (b[0] & 0x7F) << shift
            if not b[0] & 0x80:
                return v
            shift += 7

    def dump(self, reset=True):
        """Returns a complete exec file (header plus the blocks of this dump)."""
        self.s.sendall(b"\x40\x01" + (b"\x01" if reset else b"\x00"))
        out = bytearray(self.HEADER)
        while True:
            t = self.f.read(1)
            if t == b"\x20":
                return bytes(out)
            out += t
            if t == b"\x10":
                self.utf(out)
                out += self.f.read(16)
            elif t == b"\x11":
                out += self.f.read(8)
                self.utf(out)
                n = self.varint(out)
                out += self.f.read((n + 7) // 8)
            else:
                raise RuntimeError(f"unknown block {t!r}")


def act(s, kind, token, material, ping, extra):
    if kind.startswith("tail"):
        return s.S("tail", player=s.p, kind=kind, token=token, ping=ping, **extra)
    return s.S("act", player=s.p, kind=kind, token=token, material=material, broken="0", ping=ping, **extra)


def needle(kind, token, material):
    return needle_for("chat" if kind.startswith("tail") else kind, token, material)


def cmd_loop(a):
    label = f"i-{a.cov}-{a.dispatch}-r{int(a.rate)}-g{a.gate}-{a.barrier.replace(':', '')}-{a.kinds}-grp{a.group}" + ("-all" if a.includes != "probe.plugin.*" else "") + (f"-tail{a.tail_ms}" if a.tail_ms != 2 else "")
    stamp = f"{label}-{int(time.time())}"
    tcp_port = free_port() if a.cov == "tcp" else None
    jvm, classes = agent_jvm(a.cov, stamp, a.includes, tcp_port)
    kinds = TRAP if a.kinds == "trap" else BASE
    rows, wrong, dirty, cov_us, cov_bytes, tcp_bytes, waits = [], 0, 0, [], [], [], []
    execs = OUT / f"{stamp}-exec"
    with speed.Session(label, dispatch=a.dispatch, server_jvm=jvm) as s:
        boot = s.server_done
        if a.rate != 20:
            s.S("tickrate", player=s.p, rate=a.rate)
        if a.gate:
            s.C("gate", mode=a.gate, parkMicros=2000)
        tcp = JacocoTcp(tcp_port) if a.cov == "tcp" else None
        if a.cov in ("rt", "tcp"):  # boot and join coverage is nobody's
            s.S("noop", player=s.p, cov="boot") if a.cov == "rt" else tcp.dump()
        time.sleep(0.5)
        load0 = os.getloadavg()
        cpu0 = (cpu_seconds(s.serverpid), time.time())
        start = time.time()
        for i in range(a.n):
            kind, token, material = kinds[i % len(kinds)], f"T{i}x", MATERIALS[i % len(MATERIALS)]
            act_ping, end_ping = 2 * i + 1000, 2 * i + 1001
            rid = f"{i:05d}" if a.group == 1 else f"g{i // a.group:05d}"
            last_of_group = (i + 1) % a.group == 0 or i == a.n - 1
            t0 = time.perf_counter()
            r_act = act(s, kind, token, material, act_ping, {"tailMs": a.tail_ms} if kind.startswith("tail") else {})
            obs = s.C("observe", needle=needle(kind, token, material), timeoutMs=2000, ping=act_ping)
            t1 = time.perf_counter()
            if not obs["ok"]:
                wrong += 1
            fold = a.cov == "rt" and a.barrier == "naive" and last_of_group
            reset = s.S("reset", player=s.p, ping=end_ping, **({"cov": rid} if fold else {}))
            s.C("clearChat")
            st = s.C("state", ping=end_ping)
            t2 = time.perf_counter()
            if fold:
                cov_us.append(reset["covUs"]); cov_bytes.append(reset["covBytes"])
            elif a.cov == "rt" and last_of_group:
                q = {"id": rid, **({"quiet": 1} if a.barrier == "quiet" else {"wait": a.barrier.split(":")[1]})}
                d = s.S("covDump", **q)
                cov_us.append(d["covUs"]); cov_bytes.append(d["covBytes"]); waits.append(d["waitMs"])
            elif a.cov == "tcp" and last_of_group:
                data = tcp.dump()
                tcp_bytes.append(len(data))
                if a.analyze:
                    execs.mkdir(parents=True, exist_ok=True)
                    (execs / f"{rid}.exec").write_bytes(data)
            t3 = time.perf_counter()
            if leftovers(st["p"]):
                dirty += 1
            rows.append({"kind": kind, "total": t3 - t0, "cov": t3 - t2, "seen_ms": (obs["at"] - r_act["sentMicros"]) / 1000})
        wall = time.time() - start
        server_cpu = round((cpu_seconds(s.serverpid) - cpu0[0]) / (time.time() - cpu0[1]) * 100)
        rss = R.rss_mb(s.serverpid)
        saved = s.S("covSave", dir=str(execs)) if a.cov == "rt" else None
        status = s.S("status", player=s.p)
    result = {
        "label": label, "args": {k: v for k, v in vars(a).items() if k != "func"}, "n": len(rows), "wall_s": round(wall, 1),
        "load_start": round(load0[0], 1), "load_end": round(os.getloadavg()[0], 1), "boot_s": round(boot, 2),
        "per_requirement_s": stat([r["total"] for r in rows]), "cov_step_ms": stat([r["cov"] * 1000 for r in rows]),
        "by_kind_median_ms": {k: round(statistics.median(r["total"] for r in rows if r["kind"] == k) * 1000, 2) for k in kinds},
        "dump_main_thread_us": stat(cov_us), "dump_bytes": stat(cov_bytes or tcp_bytes), "wait_ms": stat(waits),
        "wrong_verdicts": wrong, "dirty": dirty, "server_cpu_pct": server_cpu, "server_rss_mb": rss, "status": status, "saved": saved,
    }
    if a.analyze and a.cov in ("rt", "tcp"):
        result["analysis"] = analyze(classes, execs, OUT / f"{stamp}-lines.jsonl", kinds, a.n, a.group)
    result["leaks"] = leak_check()
    RESULTS.open("a").write(json.dumps(result) + "\n")
    print(json.dumps({k: v for k, v in result.items() if k != "args"}))
    return result


# ---------- reading the dumps ----------

def method_lines(path, start_pat):
    """Line numbers of the block that starts at the first line matching start_pat, by brace depth."""
    lines = path.read_text().splitlines()
    for i, l in enumerate(lines):
        if re.search(start_pat, l):
            depth, out = 0, []
            for j in range(i, len(lines)):
                depth += lines[j].count("{") - lines[j].count("}")
                out.append(j + 1)
                if depth <= 0 and j > i:
                    return set(out)
            return set(out)
    raise ValueError(start_pat)


def paths():
    """Each kind's own code: its case in Speed.act, or its tail method in Coverage."""
    speed_src = SRC / "Speed.java"
    act_block = method_lines(speed_src, r"private static void act\(")
    text = speed_src.read_text().splitlines()
    out = {}
    for kind in BASE:
        start = next(n for n in sorted(act_block) if re.search(rf'case "{kind}" ->', text[n - 1]))
        out[kind] = ("probe/plugin/Speed.java", method_lines(speed_src, rf'case "{kind}" ->') if text[start - 1].rstrip().endswith("{") else {start})
    for kind in ("tailTick", "tailAsync", "tailRaw"):
        out[kind] = ("probe/plugin/Coverage.java", method_lines(SRC / "Coverage.java", rf"private static void {kind}\("))
    return out


def analyze(classes, execs, out, kinds, n, group):
    cp = ":".join(TOOL["classpath"])
    t0 = time.perf_counter()
    subprocess.run(["java", "-cp", cp, "probe.cov.Lines", str(classes), str(execs), str(out)], check=True)
    tool_s = time.perf_counter() - t0
    rows = [json.loads(l) for l in out.read_text().splitlines()]
    all_lines, reqs, summary = rows[0]["lines"], [r for r in rows if "id" in r], rows[-1]
    own = {}
    for k, (f, ls) in paths().items():
        own[k] = (f, ls & set(all_lines.get(f, [])))
    res = {"tool_s": round(tool_s, 2), "tool": summary, "per_dump_analyze_us": stat([r["us"] for r in reqs]),
           "lines_json_bytes": stat([len(json.dumps(r["files"])) for r in reqs if r["id"] != "boot"]),
           "covered_lines": stat([sum(len(v) for v in r["files"].values()) for r in reqs if r["id"] != "boot"]),
           "own_path_lines": {k: len(v[1]) for k, v in own.items()}}
    if group != 1:
        return res
    by_id = {r["id"]: r["files"] for r in reqs}
    missing, foreign, foreign_from = {}, {}, {}
    examples = []
    for i in range(n):
        kind = kinds[i % len(kinds)]
        files = by_id.get(f"{i:05d}", {})
        f, ls = own[kind]
        if not ls <= set(files.get(f, [])):
            missing[kind] = missing.get(kind, 0) + 1
        for other, (of, ols) in own.items():
            if other == kind or other not in kinds:
                continue
            if ols & set(files.get(of, [])):
                foreign[kind] = foreign.get(kind, 0) + 1
                foreign_from[other] = foreign_from.get(other, 0) + 1
                if len(examples) < 4:
                    prev = [j for j in range(max(0, i - 10), i) if kinds[j % len(kinds)] == other]
                    examples.append({"req": i, "kind": kind, "has": other, "that_kind_ran_reqs_back": (i - prev[-1]) if prev else None})
    res.update({"own_missing": missing, "foreign_in": foreign, "foreign_from": foreign_from, "examples": examples,
                "boot_dump_has_paths": [k for k, (f, ls) in own.items() if ls & set(by_id.get("boot", {}).get(f, []))]})
    return res


def cmd_intersect(a):
    """Fake diffs: a changed block case, a changed tail, a shared line (reset). Times the intersect."""
    rows = [json.loads(l) for l in pathlib.Path(a.lines).read_text().splitlines()]
    reqs = [r for r in rows if "id" in r and r["id"] != "boot"]
    own = paths()
    reset = method_lines(SRC / "Speed.java", r"private static void reset\(")
    diffs = {"block case": {own["block"][0]: own["block"][1]}, "tailTick body": {own["tailTick"][0]: own["tailTick"][1]},
             "reset method": {"probe/plugin/Speed.java": reset}, "untouched file": {"probe/plugin/Golden.java": set(range(1, 90))}}
    t0 = time.perf_counter()
    sets = [(r["id"], {f: set(v) for f, v in r["files"].items()}) for r in reqs]
    build_s = time.perf_counter() - t0
    out = {"requirements": len(reqs), "build_sets_ms": round(build_s * 1000, 2)}
    for name, diff in diffs.items():
        t0 = time.perf_counter()
        hit = [rid for rid, files in sets if any(files.get(f, set()) & ls for f, ls in diff.items())]
        out[name] = {"touched": len(hit), "ms": round((time.perf_counter() - t0) * 1000, 3), "first": hit[:3]}
    RESULTS.open("a").write(json.dumps({"label": "intersect", "lines": a.lines, **out}) + "\n")
    print(json.dumps(out))


def cmd_boot(a):
    """Paper alone, Done seconds, with and without the agent."""
    out = []
    for k in range(a.repeat):
        stamp = f"i-boot-{a.cov}-{k}-{int(time.time())}"
        jvm, _ = agent_jvm(a.cov, stamp, a.includes)
        p = speed.TunedPaper(RUNS / stamp / "server", world="void", xmx="1g", extra_jvm=jvm)
        load = os.getloadavg()[0]
        try:
            p.start()
            done = p.wait_done()
            rss = R.rss_mb(p.proc.p.pid)
        finally:
            p.stop()
            R.stop_all()
        classes = OUT / f"{stamp}-classes"
        n_classes = sum(1 for _ in classes.rglob("*.class")) if classes.exists() else 0
        out.append({"done_s": round(done, 2), "reported_s": p.reported, "rss_mb": rss, "load": round(load, 1), "instrumented_classes": n_classes})
        import shutil
        shutil.rmtree(RUNS / stamp, ignore_errors=True)
    result = {"label": f"boot-{a.cov}", "includes": a.includes, "boots": out, "median_s": statistics.median(b["done_s"] for b in out), "leaks": leak_check()}
    RESULTS.open("a").write(json.dumps(result) + "\n")
    print(json.dumps(result))


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    l = sub.add_parser("loop")
    l.add_argument("--cov", default="off", choices=["off", "agent", "rt", "tcp"])
    l.add_argument("--dispatch", default="direct", choices=["direct", "tick"])
    l.add_argument("--rate", type=float, default=20)
    l.add_argument("--gate", type=int, default=2)
    l.add_argument("--n", type=int, default=1000)
    l.add_argument("--group", type=int, default=1)
    l.add_argument("--barrier", default="naive")
    l.add_argument("--kinds", default="base", choices=["base", "trap"])
    l.add_argument("--includes", default="probe.plugin.*")
    l.add_argument("--analyze", action="store_true")
    l.add_argument("--tail-ms", type=int, default=2, help="async tails sleep this long before their own lines run")
    b = sub.add_parser("boot")
    b.add_argument("--cov", default="off", choices=["off", "agent"])
    b.add_argument("--includes", default="probe.plugin.*")
    b.add_argument("--repeat", type=int, default=3)
    i = sub.add_parser("intersect")
    i.add_argument("lines")
    a = ap.parse_args()
    RUNS.mkdir(exist_ok=True)
    OUT.mkdir(exist_ok=True)
    {"loop": cmd_loop, "boot": cmd_boot, "intersect": cmd_intersect}[a.cmd](a)


if __name__ == "__main__":
    main()
