# Restore prototype: a CRaC checkpoint of Paper instead of a boot for restart requirements

Question: can a restart requirement restore a checkpointed Paper 26.3 in about a second instead of booting it, and
still read the state the killed Paper left behind?

## Answer

- **It works, at the boot point, and it is never wrong: 0 wrong verdicts in 84 restart trials** (spike K's three
  scenes plus three new ones, good and broken, 3 jobs). The checkpoint is taken in Paper's `Main` right after
  `Bootstrap.validate`, before anything reads the server folder; the restore moves the process into the requirement's
  folder before the boot continues. Everything a requirement can check (player data, world, plugin data,
  `usercache.json`, `ops.json`) is read after the restore, from the killed Paper's folder.
- **It is not a second.** Warp's restore itself takes **0.06 to 0.10 s**, but the boot after the point still runs:
  **restore to Done 3.9 to 4.9 s against 8.0 to 8.6 s for a boot** (minus 45 to 50 percent), **13.5 to 16.7 CPU s
  against 25.7 to 27.7** (minus 40 to 47 percent). With clients running (the restart requirement itself): **client
  rejoined and ready 8.8 to 9.1 s after the kill, against 13.9 to 14.5 s** (minus 37 percent), 21 against 34 CPU s.
- **A later point is faster and wrong**, exactly like spike K's standby:
  - **data point** (after `level.dat` and the data packs, before `MinecraftServer.spin`): restore to Done **1.8 to
    2.2 s**, ready **5.6 to 6.1 s**, but **wrong in every good usercache trial (7 of 7)**: `usercache.json` is loaded
    in `Main` before the point, so the restored Paper never sees names cached while it was down. It also bakes
    `server.properties` (the restored Paper listens on the image's port: 2 restores at once fail with "FAILED TO BIND
    TO PORT"), and (**inferred** from `Main`'s code) the Bukkit, Spigot and Paper configs and the data pack selection.
  - **done point** (after Done): the image is created (once listeners reopen, sockets close, files are ignored), but
    the restored Paper dies (watchdog thread dump, then "Bad file descriptor" on every region file) or never answers.
    By design it would also bake everything read at boot (the plugin's config and persisted sessions, the standby's
    failure), so it was not pursued further.
- **Warp, not CRIU.** Warp (Zulu's default engine) needs no root, restores in the launching process with a new PID,
  so parallel restores just work. CRIU restores the image's PID: **"Can't fork for 4423: File exists"** as soon as
  that PID is taken, serially and in parallel.
- **Parallel**: 4 restores at once reach Done in 25.5 to 26.0 s against 36.4 to 41.9 s for 4 boots, use 1.9 to
  2.3 GB against 2.9 to 3.1 GB (pages of the image are shared: PSS 545 to 776 MB against 722 to 829 MB), but each
  restore then costs about 25 CPU s instead of 16: the boot after the point is CPU bound and 4 vCPU are shared.

Machines: GitHub hosted `ubuntu-24.04`, 4 vCPU, 16 GB, Vulkan on lavapipe for the client. Final run
[42432909519](https://github.com/gabber235/Typewriter/actions/runs/42432909519): job 0 Intel Xeon Platinum 8370C,
jobs 1 and 2 AMD EPYC 7763. Azul Zulu 25.0.4.1 CRaC (`zulu25.36.205-ca-crac-jdk25.0.4.1-linux_x64`) for every JVM,
boots and restores alike. Paper 26.3 build 242, K's direct trimmed launch, step agent, probe plugin, void world,
dynamic AppCDS archive (157 MB, dumped with the same flags), log to stdout only. Measured unless marked **inferred**.

| Run | What |
|---|---|
| [42432909519](https://github.com/gabber235/Typewriter/actions/runs/42432909519) | **final**: 3 jobs, all tables below |
| [42430503770](https://github.com/gabber235/Typewriter/actions/runs/42430503770) | data scenes without usercache and ops (0 wrong), CRIU and done failure logs |
| [42428577188](https://github.com/gabber235/Typewriter/actions/runs/42428577188) | first working images; data image listening on the baked port |
| [42427417144](https://github.com/gabber235/Typewriter/actions/runs/42427417144) | every image refused (the list below) |

Raw rows: artifact `h-restore-vulkan-X64-<repeat>`, files `restore.jsonl` and `h.jsonl`; refusal logs `image-*.log`,
failed restores `fail-*`.

## Restore against boot (final run)

Restart into the same folder (the first start makes the world, the second is measured), seconds from spawn to Done.
Per job: Xeon 8370C / EPYC 7763 / EPYC 7763; median of 5 (3 for CRIU).

| Start | Wall to Done | Restore alone | CPU s | RSS MB |
|---|---|---|---|---|
| boot (plain, AppCDS) | 7.98 / 8.28 / 8.58 | | 25.7 / 26.1 / 27.7 | 780 to 800 |
| **restore, boot point** | 4.66 / 4.55 / 4.90 | 0.065 / 0.090 / 0.082 | 15.7 / 16.0 / 16.7 | 725 to 746 |
| **restore, boot point, converters warmed** | **3.94 / 4.24 / 4.29** | 0.056 / 0.072 / 0.071 | **13.5 / 14.0 / 14.1** | 773 to 784 |
| restore, data point (wrong, see scenes) | 1.82 / 1.97 / 2.18 | 0.059 / 0.072 / 0.080 | 5.5 / 6.3 / 7.0 | 681 to 730 |
| restore, boot point, CRIU compressed (job 0) | 4.65 | 0.343 | 15.4 | 757 |
| restore, boot point, CRIU (job 0) | failed: PID of the image taken | | | |
| restore, done point (job 0) | failed: never answered | | | |

"Converters warmed": DataConverter's type registry (`MCTypeRegistry`, pure code, 0.25 to 0.5 s) is initialised
before the checkpoint. Restore alone: spawn of `java -XX:CRaCRestoreFrom` to the restored JVM's first line.

## Restart requirements (final run)

K's restart scenes on a Paper with one warm client (gated, rate 20). Seconds from the start of the restart (kill)
to Paper Done and to the client rejoined and ready (E's start signal, hands settled). Per job, median (p95).

| Paper | Trials | **Wrong** | Done | **Ready** | CPU s at Done |
|---|---|---|---|---|---|
| boot | 36 / 24 / 24 | **0** | 11.16 / 11.42 / 11.79 | 13.88 (14.40) / 14.12 (14.80) / 14.54 (15.22) | 33.0 / 33.9 / 34.3 |
| **restore, boot point, warmed** | 36 / 24 / 24 | **0** | 6.06 / 6.07 / 6.27 | **8.78 (9.13) / 8.84 (9.37) / 9.11 (9.32)** | 20.9 / 20.8 / 21.1 |
| restore, data point | 36 / 24 / 24 | **3 / 2 / 2, all usercache good** | 2.81 / 3.21 / 3.30 | 5.64 (5.96) / 5.98 (6.28) / 6.12 (6.46) | 12.0 / 12.9 / 13.1 |

The kill takes 0.07 to 0.12 s. After every restart 3 ordinary chat requirements ran: 0 wrong in all rows. The world
of every restored Paper was in the requirement's folder, and the image's own folder was never written
(`world_in_run_dir`, `image_srv_world_mtime_unchanged` in the rows). Scenes, each good and deliberately broken; a wrong
verdict is a pass on broken or a fail on good:

| Scene | Good | Broken | Boot point | Data point |
|---|---|---|---|---|
| grace (K) | session ends with Paper | sessions persisted, rejoin resumes | 0 of 14 | 0 of 14 |
| reward (K) | saved before the kill, there once | not saved, lost | 0 of 14 | 0 of 14 |
| mail (K) | written while down, delivered once | never deleted, delivered again | 0 of 14 | 0 of 14 |
| world | value in the overworld's level data, saved | not saved | 0 of 14 | 0 of 14 |
| usercache | name written to `usercache.json` while down, found after | not written, not found | 0 of 14 | **7 of 7 good wrong** |
| ops | op written to `ops.json` while down, an operator after | not written | 0 of 14 | 0 of 14 |

Grace broken is the cell spike K's standby got wrong (it read the session file at its boot, before the requirement
wrote it). The boot point reads it after the restore: 0 wrong. The world scene was added for the data point and
passed (Paper reads each world's level data again when it loads the world, after `spin`); usercache found what the
data point bakes.

## Images (final run)

Created once per suite: the image Paper boots to the point, checkpoints and is killed by the engine.

| Point | Engine | Spawn to point s | Write s | CPU s | Image MB |
|---|---|---|---|---|---|
| boot | Warp | 3.5 / 4.0 / 4.1 | 0.61 to 0.64 | 11.9 / 13.8 / 14.0 | 396 to 402 |
| boot, converters warmed | Warp | 4.5 / 4.3 / 4.4 | 0.64 to 0.66 | 15.5 to 16.2 | 414 to 424 |
| data | Warp | 6.3 / 6.2 / 6.7 | 0.70 to 0.79 | 22.4 to 23.3 | 456 to 466 |
| done | Warp | 10.8 | 1.03 | 37.1 | 528 |
| boot | CRIU | 3.7 | 0.87 | 13.1 | 396 |
| boot | CRIU, `compression=true` | 3.8 | 10.6 | 13.0 | **89** |

Warp in this Zulu build refuses `compression` ("Unknown configure option"); CRIU compresses 4.5 times but writes 12
times slower and restores in 0.34 s instead of 0.06 to 0.10.

## Parallel restores (final run)

k Papers started at once in their own folders; Done of the last one, per job.

| What | k | All Done s | CPU s each | PSS MB each | Memory used, all, MB |
|---|---|---|---|---|---|
| restore, boot point | 2 | 12.3 / 11.9 / 13.1 | 23.4 to 26.1 | 617 to 822 | 908 / 756 / 905 |
| boot | 2 | 18.4 / 18.0 / 19.1 | 34.6 to 36.7 | 743 to 851 | 1,286 / 1,434 / 1,450 |
| restore, boot point | 4 | 25.5 / 25.9 / 26.0 | 24.7 to 26.3 | 545 to 776 | 2,331 / 1,973 / 1,855 |
| boot | 4 | 36.4 / 36.4 / 41.9 | 34.9 to 41.1 | 722 to 829 | 2,911 / 3,071 / 3,123 |
| restore, data point | 2 | second fails: port of the image in use | | | |
| restore, CRIU | 2 | second fails: PID of the image in use | | | |

On 4 vCPU parallel restores gain nothing over one after another (each 4 to 5 s alone); they only cost less memory
than parallel boots.

## What CRaC refused, and how each was handled

| Refused at checkpoint | Point | Handling |
|---|---|---|
| Class path jars (Paper, 46 to 67 libraries, the step agent): native descriptors the JVM keeps open | all | `-XX:CRaCAllowedOpenFilePrefixes=<patched Paper dir>,<agent dir>`; policies do not cover native descriptors |
| `plugins/probe-plugin.jar`: Paper discovers plugins before `Bootstrap` | all | policy `type: file, path: **/*.jar, action: ignore` |
| `/tmp/ffi… (deleted)`: libffi closure page of JNA, opened before the boot point | all | allowed by prefix; Warp replaces it with `/dev/null` at restore and warns; no failure seen |
| `logs/latest.log` (Paper's log4j file appender) | all | avoided: a console only log4j config (`-Dlog4j.configurationFile`), the framework reads stdout |
| HTTPS connections to `api.minecraftservices.com` and `discovery.minecraftservices.com` (services discovery in `Main`) | data, done | policy `type: socket, action: close` |
| `world/session.lock` (`FileChannel` with a lock) | data, done | policy `action: ignore`; `reopen` is unsupported for a `FileChannel` (`UnsupportedOperationException` in `reopenAfterRestore`) |
| Netty NIO listeners: `BusySelectorException` (selector with a registered `ServerSocketChannel`), epoll descriptors | done | `use-native-transport=false` (native epoll descriptors are not the JDK's) and policy `listening: true, action: reopen`; accepted |
| The probe plugin's line server, control HTTP server, the test process's open connection | done | listening `reopen`, connections `close`; the test process closes its side first |
| Region files `r.*.mca` (Moonrise keeps them open) | done | `ignore` is accepted at checkpoint, but after restore every write fails with "Bad file descriptor"; unsolved |
| Paper's watchdog | done | not refused; it fires after restore (the clock jumped), dumps threads and stops the server; unsolved |
| Step agent state | all | nothing to do: static flags and an idle permit are plain heap |

At the boot point nothing of Paper's server, world, network or plugins exists yet, so the only refusals are the class
path, the plugin jar and libffi. The restore needs, besides the image: `probe.agent.Restored dir=<folder>
-Dprobe.line.port=… -Dprobe.control.port=…` as the main class at restore (Warp runs it before the checkpoint call
returns; whether `-D` on the restore command line applies was not tested), a `chdir` through FFM and a patch of the two JDK caches
of `user.dir` (`java.io` file system `userDir`, `sun.nio.fs` `defaultDirectory`; needs `--add-opens` and
`--enable-native-access` on the image JVM). Warp restores the launcher's working folder; the JDK caches still hold the
image's.

## Surprises

- **Most of a boot comes after the safe point.** On the runner the boot point is 3.5 to 4.1 s into an 8 s boot; after
  it come the folder configs (about 0.7 s), DataConverter (0.5), the data packs (1.9 to 2.3, cold JIT) and the server
  to Done (1.5). That remainder is the restore time.
- **Warming the data packs before the checkpoint fails**: a throwaway vanilla load works, but the real load then
  throws "Registry already loaded!" (`PaperRegistryAccess.registerRegistry` binds the API registries to the first
  load). It would need Paper internals reset; not pursued. Gain would be at most about 1.5 s (**inferred**).
- **The data point bakes `usercache.json`**, found only by a scene written for it; world level data, ops, player
  data and plugin data are read after it. Any state `Main` reads before `spin` is baked; the list depends on Paper's
  version, so only the boot point is correct by construction.
- **`ThreadLocalRandom` repeats across restores of one image** (the same first value in two restores of the data
  image); `UUID.randomUUID` and `new Random()` differ. Anything seeded from `ThreadLocalRandom` on a thread created
  before the checkpoint repeats per image (**inferred** for Paper code; measured for the main thread).
- **Paper plugin bootstrappers run before the boot point** (`Initializing plugins` precedes `Bootstrap`). Plugins
  with a `paper-plugin.yml` bootstrapper that reads its data folder would have that read baked (**inferred**; the
  probe plugin is a Bukkit plugin and `services/` has no bootstrapper today).
- Paper's "Done (626.619s)" after a restore counts from the image's JVM start; harmless.

## What the framework would need

- **JDK**: Azul Zulu 25 CRaC for Linux x64 or arm64, for every Paper the suite starts. nixpkgs has `zulu25`
  (`zulu-ca-jdk-25.0.3`) without CRaC, so devenv would fetch the Azul tarball itself (the metadata API with
  `crac_supported=true`, a fixed hash) and patch it for Nix. macOS has only the simulated engine: on a Mac a restart
  requirement boots (as today) unless it runs in a Linux VM or container.
- **Engine**: Warp. No root, no setuid, new PID per restore, parallel restores work. CRIU needs a setuid binary
  and fails on PID reuse.
- **Image**: about 400 MB, created in 4 to 5 s (12 to 16 CPU s) at suite start, in the suite's cache folder on the
  machine that restores it (images are tied to the kernel and CPU features; creating per job is cheaper than moving
  them). Invalidate on any change to: the JDK build, Paper's jars and libraries, the step agent, the plugin jars
  (discovered before the point), the JVM flags, the AppCDS archive, the kernel or CPU.
- **Hooks**: the checkpoint call at `Util.startTimerHackThread` (an agent prefix, as here), the restore main class
  with folder and properties, the folder move (chdir plus two JDK caches), console only logging, the allowed prefixes
  and the plugin jar policy. About 170 lines in this prototype (`Crac.java`, `Restored.java`, the agent prefix).
- **Suite effect** (**inferred** from the per restart numbers): a restart requirement gets about 5 s and 13 CPU s
  cheaper on the runner (ready 8.8 to 9.1 s against 13.9 to 14.5). In the topology spike's A, 10 restarts took 82 to
  89 percent of 200 s; at roughly 5 s saved each that is about 50 s of 200, so restarts still dominate.

## Rerun

Build from the worktree root:

```
cargo xtask heavy -- bash -c 'cd prototypes/game-verification && ./gradlew --console=plain -q :step-agent:jar :probe-mod:writeClientLaunch :probe-mod:jar :probe-plugin:jar'
```

CI only (full CRaC needs Linux): matrix rows `{ plan: restore, backend: vulkan, runner: ubuntu-24.04, repeat: 0|1|2 }`
run `orchestrator/ci.py plan restore`; tables from `orchestrator/restore_report.py <h.jsonl>`. Single commands, on a
Linux machine with Zulu CRaC on the path, from `prototypes/game-verification`:

```
python3 orchestrator/run.py prepare
python3 orchestrator/restore.py prep
python3 orchestrator/restore.py image --point boot --engine warp --policy boot --warm 1
python3 orchestrator/restore.py compare --image boot-warp-boot-warm --n 5
python3 orchestrator/restore.py scenes --image boot-warp-boot-warm --n 3
```
