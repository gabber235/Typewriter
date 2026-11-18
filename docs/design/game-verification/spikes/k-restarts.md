# K: Paper restarts and isolation per requirement with warm clients

## Answer

- **Restart requirements: K1, SIGKILL and boot the same Paper again** (direct classpath, trimmed, dynamic AppCDS),
  with the client told to connect once Paper logs Done (or retrying by itself every 100 ms). **Back and ready
  (E's start signal) 5.1 s after the kill on the Mac and 12.9 s on the runner; 0 wrong verdicts** in every scene,
  good and broken. It is the only kind that is never wrong. The faster kinds each pass a broken plugin:
  - **K2 standby Paper** (pre booted, sharing the player data and plugin store, client switches port): 1.4 s Mac,
    2.8 s runner, but **wrong in every broken session trial** (5 of 5, 3 of 3): anything a plugin reads at boot was read before the state existed.
  - **K3 plugin disable and enable**: 0.65 to 0.70 s, but **wrong in every broken reward trial** (5 of 5, 3 of 3): Paper never loses the
    unsaved inventory, so "survives a Paper restart" is not tested.
  - A clean stop instead of a kill (K1stop) is as slow as K1 and **wrong in every broken reward trial** (3 of 3,
    2 of 2), because stop saves player data.
  A kill drops every client on that Paper, so a restart requirement needs a Paper of its own (or the whole pool).
  On the runner Paper's boot is 9.5 s of the 12.9, so 10 restart requirements in a 500 requirement suite cost about
  2 minutes on a Paper of their own, in parallel with the rest (**inferred** from the per restart time).
- **Isolation: a fresh player identity per requirement (I1)**, an offline name and UUID per requirement and a
  reconnect, gave **0 leaks in 2,540 requirements** on both machines without listing any kind of state. A wipe of the
  connected player is 10 to 25 times faster but only correct when it lists every kind: the full wipe (I2full,
  17 kinds) gave 0 leaks, the obvious wipe (plugin store, chat, inventory, effects, position) **leaked 11 of 17 kinds
  in every requirement**, and reconnecting under the same name (I0) leaked 11 kinds too (stored values, a
  resumed session with its chat history, team, PDC, ender chest and more).
- **500 requirement suite, trivial requirements, gated, runner** (measured per requirement, multiplied):

  | Start signal, rate | 1 client I1 | 1 client wipe | 4 clients I1 | 4 clients wipe |
  |---|---|---|---|---|
  | Facts (radius chunks), rate 200 | 108 s | 9 s | about 55 s (**inferred**) | about 5 s (**inferred**) |
  | Frames (hands settled), rate 200 | 227 s | 35 s | 115 s | 14 s |
  | Frames (hands settled), rate 20 | 333 s | 200 s | 137 s | about 50 s (**inferred**) |

  Mac, same cells measured: facts rate 200 76 s against 6.5 s on one client; frames rate 200 on 4 clients 52 s
  against 8 s. Fresh identity costs **0.14 to 0.6 s per requirement**, so a 500 requirement suite stays within
  2 to 6 minutes on 1 client and about 2 minutes on the pool of 4. That is affordable, and it removes a whole class
  of framework work (a wipe list per kind of state, for Paper and for Typewriter). Recommend I1 by default, with the
  facts start signal unless the requirement declares frames.

Machines: the developer's M1 Max (OpenGL on Metal, 854x480, render distance 2, void world, gated except while
joining, load 5 to 17, given per row) and the free runner run
[42235574190](https://github.com/gabber235/Typewriter/actions/runs/42235574190) (`ubuntu-24.04`, 4 vCPU, Vulkan
on lavapipe, load 2 to 14). Measured unless marked **inferred**.

## What a requirement here is

No Typewriter runs in the prototype. The probe plugin imitates per player state (`probe-plugin/.../K.java`):

| Kind | Where it lives | Survives |
|---|---|---|
| stored value, stored permission, owed and given reward | file per UUID in the plugin's store | restart |
| mail | file per UUID, delivered at join and deleted | restart |
| session | memory; a rejoin within 100 ticks resumes it and replays its chat history | quit within grace |
| hold | memory; ended holds wait 10 ticks, a hold started within that adopts it | its grace |
| permission attachment, boss bar | memory, per Player object | nothing |
| team | main scoreboard, by player name | restart |
| inventory, effects, position, xp, ender chest, PDC, player time, metadata | Paper's player | Paper's rules |

**Restart scenes**, each run good and deliberately broken; a wrong verdict is a pass on broken or a fail on good:

| Scene | Requirement (roadmap) | Good | Broken |
|---|---|---|---|
| grace | killing Paper ends the session (L3) | rejoin says `resumed=0` | sessions persisted to a file, rejoin resumes |
| reward | an item given before the restart is there exactly once after it (L6) | `saveData()` after giving | no save, item lost on kill |
| mail | queued while Paper is down, delivered once at the next join (L7) | delivered, deleted | never deleted, delivered again |

After every restart five ordinary chat requirements ran (judged on the client's facts).

**Isolation**: every requirement first reads all 17 kinds (one `KREQ` chat line the client reads) and checks the
client's chat for any earlier requirement's lines, then writes all 17 kinds. A leak is a kind the next requirement
still sees.

## Restarts: Mac, 30 trials per kind (18 for K1stop), rate 20

Seconds from the restart's start. Cell: median (p95).

| Kind | Paper Done | Client in level | Ready (hands) | Wrong verdicts | After restart | Load |
|---|---|---|---|---|---|---|
| **K1 kill, connect at Done** | 3.86 (4.34) | 4.76 (5.26) | **5.14 (5.61)** | **0 of 30** | 0 of 150 wrong | 7.2 |
| K1auto kill, client retries every 100 ms | 3.81 (4.33) | 4.56 (5.08) | 4.92 (5.47) | 0 of 30 | 0 of 150 | 9.0 |
| K1stop clean stop | 4.29 (4.40) | 5.18 (5.29) | 5.53 (5.66) | **3 of 18**, all broken reward | 0 of 90 | 7.3 |
| K2 standby, switch port | none | 0.99 (1.48) | 1.37 (1.87) | **5 of 30**, all broken grace | 0 of 150 | 10.9 |
| K3 disable and enable, then reconnect | reload 5.1 ms (9.4) | 0.20 (0.22) | 0.65 (0.70) | **5 of 30**, all broken reward | 0 of 150 | 8.9 |

- The kill itself takes 0.02 to 0.05 s; the client notices the dropped connection within 0.05 to 0.08 s.
- K2's next standby boots in 3.7 s (3.9) after each switch; it overlaps later requirements in a real suite but
  costs CPU while it does (**inferred**).
- Ordinary requirements after a restart are as fast as before (median 50 ms with the chat round trip).

## Restarts: runner

Run 42235574190 (job 127965851156), Intel Xeon Platinum 8370C, 4 vCPU, Vulkan on lavapipe, rate 20, 18 trials
per kind (12 for K1stop), load 5.1 to 6.7. Same cells as the Mac.

| Kind | Paper Done | Client in level | Ready (hands) | Wrong verdicts | After restart |
|---|---|---|---|---|---|
| **K1 kill, connect at Done** | 10.07 (10.48) | 12.24 (12.68) | **12.88 (13.39)** | **0 of 18** | 0 of 90 wrong |
| K1auto | 9.97 (10.44) | 11.95 (12.57) | 12.60 (13.36) | 0 of 18 | 0 of 90 |
| K1stop | 10.45 (10.81) | 12.53 (12.89) | 13.18 (13.67) | **2 of 12**, broken reward | 0 of 60 |
| K2 standby | none | 2.16 (2.29) | 2.80 (3.02) | **3 of 18**, broken grace | 0 of 90 |
| K3 reload, then reconnect | reload 8.2 ms (20.4) | 0.32 (0.68) | 0.70 (1.05) | **3 of 18**, broken reward | 0 of 90 |

- **Paper boots in about 9.5 s on the runner** (`Done (9.464s)` in its own log) against 3.9 s on the Mac, with the
  same trimmed direct launch and a 158 MB AppCDS archive built on the runner in the same job. C4 measured boot on the
  Mac only. Whether the archive mapped on the runner is not verified (`-Xshare:auto` falls back silently and the run
  had CDS logging off), so the runner boot may still have room (**inferred**).
- After Done the client needs 2.2 s to be in the level (0.9 s on the Mac), and the next standby boots in 7.5 s.
- Every verdict pattern matches the Mac exactly.

## Isolation: seconds per requirement

Wall clock per requirement over the run (with 4 clients the wall clock divided by all their requirements);
isolation step median (p95). Gated, trivial requirement. Rate is the server tick rate.

| Machine | Mode | Rate | Start | Clients | n | Per requirement | Isolation step | Leaks |
|---|---|---|---|---|---|---|---|---|
| Mac | **I1** fresh identity | 20 | hands | 1 | 200 | 0.614 | 0.555 (0.607) | **0** |
| Mac | I2full wipe | 20 | hands | 1 | 200 | 0.345 | 0.354 (0.403) | 0 |
| Mac | I2naive wipe | 20 | hands | 1 | 100 | 0.429 | 0.392 | **11 kinds, 99 of 99** |
| Mac | I0 same name | 20 | hands | 1 | 100 | 0.700 | 0.663 | **11 kinds, 99 of 99** |
| Mac | **I1** | 200 | hands | 1 | 200 | 0.395 | 0.392 (0.394) | 0 |
| Mac | I2full | 200 | hands | 1 | 200 | 0.094 | 0.007 (0.359) | 0 |
| Mac | I2naive | 200 | hands | 1 | 100 | 0.066 | 0.007 | 11 kinds |
| Mac | I0 | 200 | hands | 1 | 100 | 0.504 | 0.495 | 11 kinds |
| Mac | **I1** | 200 | chunks | 1 | 200 | 0.152 | 0.140 (0.144) | 0 |
| Mac | I2full | 200 | chunks | 1 | 200 | 0.013 | 0.004 (0.009) | 0 |
| Mac | **I1** | 200 | hands | 4 | 500 | 0.105 | 0.389 (0.483) | 0 |
| Mac | **I1** | 20 | hands | 4 | 500 | 0.155 | 0.576 (0.637) | 0 |
| Mac | I2full | 200 | hands | 4 | 500 | 0.016 | 0.005 (0.353) | 0 |
| runner | **I1** | 20 | hands | 1 | 100 | 0.666 | 0.595 (0.696) | 0 |
| runner | I2full | 20 | hands | 1 | 100 | 0.399 | 0.360 (0.361) | 0 |
| runner | I2naive | 20 | hands | 1 | 40 | 0.403 | 0.352 | 11 kinds, 39 of 39 |
| runner | I0 | 20 | hands | 1 | 40 | 0.795 | 0.704 (1.136) | 11 kinds, 39 of 39 |
| runner | **I1** | 200 | hands | 1 | 100 | 0.454 | 0.431 (0.574) | 0 |
| runner | I2full | 200 | hands | 1 | 100 | 0.070 | 0.004 (0.354) | 0 |
| runner | I2naive | 200 | hands | 1 | 40 | 0.067 | 0.004 | 11 kinds |
| runner | I0 | 200 | hands | 1 | 40 | 0.657 | 0.589 (1.060) | 11 kinds |
| runner | **I1** | 200 | chunks | 1 | 100 | 0.216 | 0.186 (0.273) | 0 |
| runner | I2full | 200 | chunks | 1 | 100 | 0.018 | 0.004 (0.017) | 0 |
| runner | **I1** | 200 | hands | 4 | 400 | 0.229 | 0.792 (1.271) | 0 |
| runner | I2full | 200 | hands | 4 | 400 | 0.028 | 0.007 (0.358) | 0 |
| runner | **I1** | 20 | hands | 4 | 240 | 0.274 | 0.922 (1.475) | 0 |

Loads: Mac 5.3 to 17.4, runner 2.2 to 13.9 (the 4 client rows are the high ones). No requirement failed to join or
to see its own line in 4,900 requirements.

- **Hands against chunks**: a reconnect's level is complete (radius chunks held) 0.1 to 0.4 s before the hands
  settle; a fact requirement can start there (spike E). Fresh identity is 2 to 3 times cheaper with the facts
  signal at rate 200.
- **A wipe settles at once at rate 200 in the median but not always**: p95 0.35 s, the same as at rate 20, when
  clearing the inventory restarts the hand animation (held item changed). At rate 20 every wipe waits for it.
- **4 clients on the runner** make each reconnect slower (0.79 against 0.43 s, load 14 on 4 vCPU), yet the pool's
  wall clock per requirement still halves.
- **Leaks of the same name reconnect (I0)**: stored, history, session (resumed with its chat replayed), team,
  stored permission, inventory, effects, xp, PDC, ender chest, metadata. Not leaked: hold (its 10 tick grace ended
  during the reconnect), attachment permission and boss bar (die with the Player object), position (the join
  teleports), mail (delivered at the join, so it shows as a foreign chat line instead).
- **Leaks of the obvious wipe (I2naive)**: history, hold (adopted by the next requirement, `KHOLD adopted`), team,
  permission, xp, mail, PDC, player time, ender chest, boss bar, metadata.

## Leftovers and memory over many identities

500 fresh identities on one Paper (Mac, 4 clients, rate 200, 52 s):

| Item | Before | After 500 |
|---|---|---|
| Paper player files (`world/players/{data,advancements,stats}`) | 0 | 1,500 files, 2.7 MB (5.4 KB per identity) |
| `usercache.json` | 417 B | 53 KB |
| `Bukkit.getOfflinePlayers()` | 4 | 504 |
| plugin store and mail files | 0 | 1,000 files, 37 KB |
| Paper heap after GC | 264 MB | 266 MB |
| Paper RSS | 1,243 MB | 1,266 MB |
| each client RSS | 1,139 to 1,187 MB | 1,071 to 1,247 MB, no trend |

The same on the runner (400 identities): Paper RSS 870 to 1,000 MB, clients +90 to 140 MB. A wipe run leaves 4
files per kind. The offline player list grows without bound, so anything that walks it (a plugin listing offline
players, a leaderboard) slows with the suite (**inferred**); a suite should start from an empty world folder.

Restart leftovers: each killed connection leaves one crash report in the client's `debug/` folder (11 to 14 per
30 kills on the Mac); each K1 restart reuses the same files, so nothing else grows.

## Surprises

- **The prototype's reconnect never quit.** `Minecraft.disconnectWithProgressScreen` closes only the client's
  packet listener; the network connection stays open, and Paper keeps the old player until its 30 s timeout. With a
  new name the old identities piled up until "The server is full!" after 8. With the same name (spikes C and E) the
  new login kicked the ghost, so those reconnects measured a duplicate login, not a quit. Leaving the way the pause
  menu does (`disconnectFromWorld`, which calls `ClientLevel.disconnect` first) fixed it; every number here uses it.
- **`Minecraft.disconnect` drops every queued client task** (`dropAllTasks`). A probe read sent through
  `mc.execute` at that moment never answers; it looked like a 30 s render thread stall until traced. Reads around a
  disconnect must be resent or made off the client thread.
- **A gated client never leaves the level loading screen.** It waits for the player's section to compile
  (`LevelLoadTracker.WaitingForPlayerChunk`), which needs drawn frames, so a reconnect draws until ready and gates
  again. Gating from the first frame (spike D's 30 s loading timeout) is the same cause.
- **Minecraft refuses symlinks inside a world** (`ContentValidationException: forbidden symlinks`) unless
  `allowed_symlinks.txt` names their target; the standby shares player data through one.
- **A clean stop saves what a kill loses**: the broken reward passed after every clean stop.
- **The first standby trial of a run looked fine**, because the standby had booted before any state existed; the
  broken session file is read at boot, so K2 is wrong exactly where a real plugin recovers state in `onEnable`.

## What this means for the search

- **Restart requirements declare it** and get a Paper of their own: a kill disconnects every client on it. Use K1
  (kill, boot the same directory and ports, connect at Done). K2 and K3 each pass a real class of bug; use them only
  if a requirement states it needs no boot (K2) or no lost Paper data (K3), which none of L3, L6 or L7 does.
- **Fresh identity per requirement is the isolation**, not a wipe. It needs no list of state kinds, so a new kind
  of per player state (a new Typewriter runtime, a Paper field, a third party plugin's file) can never leak. It
  also runs the real join path every time, which L3, L6, L7 and dialogue's `ProtagonistJoined` history need anyway.
  Group requirements (L11) get as many fresh identities as clients they claim.
- **The framework's client must leave like a player** (`disconnectFromWorld`) and must not lose reads during a
  disconnect.
- **Start from an empty world per suite**; per identity files grow by about 5.4 KB each.
- **Rate**: restart requirements ran at rate 20; at rate 200 Paper's autosave (every 6000 ticks) comes 10 times
  sooner, so a broken "not saved" plugin could pass by luck in a long requirement (**inferred**, not run).
- **E**: the facts start signal (radius chunks) after a reconnect is what makes fresh identity cheap; frames
  requirements pay the hands wait.

## Rerun

Build, from the worktree root:

```
cargo xtask heavy -- bash -c 'cd prototypes/game-verification && ./gradlew --console=plain -q :probe-mod:writeClientLaunch :probe-mod:jar :probe-plugin:jar'
```

Mac, from `prototypes/game-verification`, one at a time, `SDL_MAC_BACKGROUND_APP=1`:

```
python3 orchestrator/k.py prep
python3 orchestrator/k.py restart --kind K1 --n 5 --label mac        # also K1auto, K2, K3, K1stop
python3 orchestrator/k.py iso --mode I1 --n 200 --rate 20 --label mac  # modes I1, I2full, I2naive, I0
python3 orchestrator/k.py iso --mode I1 --n 200 --rate 200 --need chunks --label mac
python3 orchestrator/k.py iso --mode I1 --n 125 --rate 200 --clients 4 --label mac
```

`restart` flags: `--scenes grace,reward,mail`, `--after` (ordinary requirements after each restart), `--rate`,
`--gate`. `iso` flags: `--need hands|chunks`, `--clients`, `--gate`. Results append to `runs/k.jsonl`.

CI: matrix rows `{ plan: restarts, backend: vulkan, runner: ubuntu-24.04, repeat: 0|1|2 }` run
`orchestrator/ci.py plan restarts`: repeat 0 the restart kinds, 1 isolation on one client at rates 20 and 200,
2 isolation on 4 clients. Rows are in the artifact's `k.jsonl` and `h.jsonl`.

## Reuse

- **Client** `probe-mod/.../k/K.java`: `k.user?name=` (next login's offline name, through the `UserAccessor`
  mixin on `Minecraft.user`), `k.connect?addr=` (leaves like the pause menu, then connects), `k.auto?addr=&on=&everyMs=`
  (reconnect by itself while disconnected), `k.mark` plus `k.ready?need=&newLevel=1&radius=` (first loop with the
  start bits on a new level, with level and chunk times), `k.gone` (the connection dropped), `k.chat`, `k.inv`.
- **Plugin** `probe-plugin/.../K.java`: per player state of 17 kinds, `k.cfg` (grace, hold grace, broken switches,
  kept in a file), `k.req`, `k.wipe?scope=naive|full`, `k.owe`, `k.reload`, `k.files`.
- **Orchestrator** `k.py`: `KPaper` (kill, boot on the same ports with AppCDS), `Rig` (Paper, standby, warm
  clients), `restart`, `trial`, `iso_loop`; `ci.py k_hooks` puts each client on its own Xvfb.
