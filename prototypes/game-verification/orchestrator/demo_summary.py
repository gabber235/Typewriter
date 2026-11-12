"""Prints the tables of a demo report compactly."""
import json, sys
r = json.load(open(sys.argv[1] + "/report.json"))
print("== verdicts (pass/first tick)")
for k, v in r["verdicts"].items():
    print(k, {p: (x["pass"], x["first_tick"]) for p, x in v.items()}, "gated pt", v.get("gated", {}).get("pt"))
print("== timeline")
for k, v in r["timeline"].items():
    if any(v[x] for x in ("gaps", "frames_without_record", "record_tick_off_schedule", "partial_off_schedule")) or k.endswith(":0"):
        print(k, v)
print("== smooth")
for k, v in r["smooth"].items():
    if not v or not k.endswith(":0"):
        continue
    m = v.get("motion") or {}
    g = v["game_ticks_per_frame"]
    print(k, "frames", v["frames"], "dg mean/std/min/max", g["mean"], g["std"], g["min"], g["max"], "zero", v["zero_game_step"], "dupslot", v["dup_slots"],
          "identical_in_motion", v.get("identical_in_motion"), "| motion cv", m.get("cv"), "max/med", m.get("max_over_med"), "still", m.get("still"), "edge/inside", m.get("boundary_over_inside"))
print("== pixels")
for k, v in r["pixels"].items():
    print(k, json.dumps(v))
print("== cost")
for k, v in r["cost"].items():
    print(k, {x: v.get(x) for x in ("ms_per_tick", "frames", "block_ms", "video_bytes", "ffmpeg_cpu_ms")}, "issue", (v.get("issue_us") or {}).get("med"),
          "cb", (v.get("callback_us") or {}).get("med"), "req med ms", (v.get("req_ms") or {}).get("med"), "fps", v.get("client_fps"))
print("== identical")
for k, v in r["identical"].items():
    print(k, json.dumps(v)[:400])
