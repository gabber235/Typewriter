# Boot prototype: how far can a restart requirement's Paper boot be cut?

Question: restart requirements (SIGKILL Paper, boot it again, the client rejoins) take 82 to 89 percent of the suite's
wall time in the topology prototype. How far can one boot of Paper 26.3 with the step agent, the probe plugin and a
void world be cut on GitHub's free runner, alone and four at once, without changing a verdict?

## Answer

- **Best combination (`bestq`): kill to state readable 5.0 s against 8.8 s for today's flags (−45 %, −44 to −47),
  Paper CPU −65 %.** Four restarts at once: **a round of 4 in 15.5 to 23.2 s against 48 to 72 s (−68 %)**, so about
  4 to 6 s per restart when they overlap. **0 wrong verdicts in 1,494 restart trials on Java 25 and 26** (747 deliberately
  broken) over every variant, plus 0 wrong in the ordinary requirements run right after each boot.
- `bestq` is: **Java 25 AOT cache** (JEP 483/514/515) trained on a real boot with the agent and a client join, with
  `-XX:-AOTInvokeDynamicLinking`; **C1 only and SerialGC** (`-XX:TieredStopAtLevel=1 -XX:+UseSerialGC -XX:-UsePerfData
  -Xss512k`); the slim server; and **the client kept gated (no frames drawn) while Paper boots**, ungated when it
  connects at Done.
- **The two levers that matter: C1 only (−27 % wall, −52 % CPU alone) and a quiet client during the boot (−23 % alone,
  −35 % with 4 at once).** The AOT cache gives −15 %, the join trained AppCDS −6 %. The slim server, SerialGC,
  ParallelGC and a hot page cache give nothing measurable or cost time on their own. Today's baseline already holds
  the two that do help among those listed (direct classpath without Paperclip: +8 % if removed; AppCDS: +22 % if removed).
- **What dominates a boot is JVM warm up, not the world.** On the runner a boot to Done costs about 28 to 30 CPU s:
  the JIT 10 to 15 s (C2 alone 7.5 to 11.9 s, up to 41 %), the main thread 4.3 to 4.7 s, GC 2.4 to 2.6 s, world gen
  workers 1.8 s, the server thread 1.4 s. On the wall clock, Minecraft's bootstrap (registries, blocks) takes 4.0 s and
  the datapack load (recipes, 1,866 advancements, tags) 3.1 s of a 12.6 s profiled boot; the void world, its level and
  the plugin together take under 1.2 s.
- **Per restart requirement on the shared Paper topology (A): about 5 s from kill to state instead of 8 to 11 s,
  plus the two client moves (0.6 to 1.4 s each in the topology run)**, so roughly 7 to 8 s instead of 11 to 21 s
  per restart requirement (**inferred**: these boots ran with nothing else on the runner; in A the other attempts
  compete for the same 4 vCPU).
- **Java 26**: full AOT class linking builds there (it fails on Java 25) and the same combination gives −54 % against
  no cache, about the same absolute time as Java 25's `bestq` on the same CPU. Java 26 refuses dynamic AppCDS with a
  Java agent altogether, so the AOT cache is the only archive left with the step agent.

Machine: GitHub hosted `ubuntu-24.04`, x86, 4 vCPU, 16 GB, Temurin 25.0.x (setup-java), Vulkan on lavapipe for the
client, gated clients (render gate 2), 854x480, render distance 2, Paper 26.3 build 242, rate 20. CPUs drawn: AMD EPYC
9V45 (3 jobs), 9V74 (3), 7763 (1), Intel Xeon 8370C (2), 8573C (1), 6975P (1). The fleet differs up to 2 times in
speed, so every comparison is against the baseline measured in the same job; ranges are over jobs. Measured unless
marked **inferred**.

Evidence:

| Run | What |
|---|---|
| [42430101477](https://github.com/gabber235/Typewriter/actions/runs/42430101477) | **final**: 3 sequential jobs (19 variants, work after boot), 3 parallel jobs (6 variants, 4 at once), phase profiles |
| [42427457708](https://github.com/gabber235/Typewriter/actions/runs/42427457708) | first full run: 3 sequential jobs (17 variants), 3 parallel jobs (4 variants), phase profiles |
| [42433205261](https://github.com/gabber235/Typewriter/actions/runs/42433205261) | Java 26: 3 sequential jobs (6 variants against no cache), 1 parallel job |

Raw rows: artifacts `h-bootseq-java25-X64-<repeat>`, `h-bootpar-java25-X64-<repeat>`, `h-bootphases-java25-X64-0`,
`h-bootseq-java26-X64-<repeat>`, file `boot.jsonl` (one row per trial, one summary per variant), phase logs in
`boot-phases/`.

## The boot measured

Each trial is K's restart scene on an unstepped Paper with the step agent loaded (the topology's restart Paper X):

1. Arrange the scene with the plugin good or deliberately broken: **reward** (an item given and saved; broken: not
   saved), **grace** (the session must end when Paper dies; broken: sessions persisted), **mail** (queued while Paper
   is down, delivered once; broken: never deleted).
2. SIGKILL the process group; the client notices the dropped connection.
3. Start Paper on the same directory and ports. **Every time below is from this process spawn.** Paper's log lines are
   stamped as they arrive (stdout through a pipe).
4. At Done the client connects; **ready** is K's facts start signal (radius chunks held on a new level).
5. **State**: one probe barrier, then the scene's state is read (item count, join line, mail count). Paper's process
   CPU seconds and RSS are read here; client CPU is the delta from just before the kill.
6. After the state read (not timed in the boot): 20 chat requirements at tick rate 200 and 5 region moves (teleport to
   fresh void chunks, build a 17x17 platform on the server thread, timed in Paper), to see whether a flag that speeds
   the boot slows what runs next.

A variant runs each scene good and broken (6 trials) per job; caches are built in the same job on the same runner.
"Kill to state" adds the kill and the client noticing it (0.3 s) to "state".

## Each try alone, then the combination (sequential, one restart at a time)

Median over jobs of each job's median; range over jobs. Against base is per job. Kill to state, CPU and client CPU:
6 jobs over both runs (3 for the variants added in the final run). Chat and platform: the final run's 3 jobs.

| # | Variant | What changes against base | Kill to state s | Against base | Paper CPU against base | Client CPU s | Paper RSS MB | Chat at 200, ms | Platform ms | Wrong |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | **base** | today's flags: direct classpath (patched files, no Paperclip), trimmed, dynamic AppCDS dumped and mapped with the agent, G1, 1 GB heap | **9.45** (7.68 to 11.46) | | | 9.1 | 826 | 4 | 85 | 0 of 36 |
| 3 | nocache | no AppCDS archive (JDK default CDS only) | 11.51 (9.33 to 14.03) | **+22 %** (+20 to +28) | +16 % | 10.6 | 833 | 4 | 83 | 0 of 36 |
| 3 | xshareoff | `-Xshare:off`, no CDS at all | 11.80 (9.40 to 13.67) | +23 % (+14 to +33) | +17 % | 10.9 | 841 | 4 | 81 | 0 of 36 |
| 3 | cdsjoin | AppCDS trained on a boot plus a client join, rejoin and state read | 8.75 (7.35 to 11.34) | −6 % (−13 to −1) | −5 % | 7.9 | 841 | 4 | 82 | 0 of 36 |
| 2 | **aot** | AOT cache instead of AppCDS, trained with the agent and a join, `-XX:-AOTInvokeDynamicLinking` | 8.08 (6.89 to 9.88) | **−15 %** (−21 to −11) | −5 % | 7.2 | 802 | 5 | 69 | 0 of 36 |
| 2 | aotfull | AOT cache with full class linking | not buildable on Java 25 (see Surprises) | | | | | | | |
| 2 | aotnolink | AOT cache, `-XX:-AOTClassLinking` | 9.35 (7.88 to 11.58) | +2 % (−4 to +6) | +3 % | 8.6 | 852 | 4 | 86 | 0 of 36 |
| 2 | aotnojoin | as aot, trained on a boot without a join | 8.81 (7.45 to 10.41) | −3 % (−10 to −2) | +5 % | 7.9 | 798 | 4 | 58 | 0 of 36 |
| 4 | slim | no nether (`misc.enable-nether: false`), view and simulation distance 2, advancements off, bStats off | 9.25 (7.63 to 11.52) | −1 % (−5 to +1) | −2 % | 8.4 | 838 | 4 | 80 | 0 of 36 |
| 5 | **c1** | `-XX:TieredStopAtLevel=1` | 6.80 (5.83 to 8.45) | **−27 %** (−30 to −26) | **−52 %** | 6.6 | 836 | 4 | 39 | 0 of 36 |
| 5 | serial | `-XX:+UseSerialGC` | 10.09 (8.39 to 11.88) | +8 % (0 to +14) | −2 % | 10.0 | **684** | 4 | 145 | 0 of 36 |
| 5 | parallel | `-XX:+UseParallelGC` | 9.69 (7.60 to 10.53) | −1 % (−9 to +9) | −2 % | 9.2 | 933 | 4 | 93 | 0 of 36 |
| 5 | fastjvm | C1, SerialGC, `-XX:-UsePerfData`, `-Xss512k` | 7.48 (6.70 to 9.09) | −16 % (−26 to −13) | −54 % | 7.6 | 796 | 4 | 39 | 0 of 36 |
| 6 | jar | Paperclip launch (`-jar`, patch check each start), AppCDS trained the same way | 10.23 (8.46 to 12.01) | +8 % (+4 to +12) | +8 % | 9.3 | 822 | 4 | 83 | 0 of 36 |
| 6 | cold | base, page cache dropped between kill and start | 11.27 (9.63 to 14.95) | +18 % (+10 to +30) | −2 % | 10.8 | 836 | 4 | 83 | 0 of 24 |
| | baseq | base, client gated while Paper boots | 6.79 (6.56 to 8.32) | **−23 %** (−24 to −19) | −9 % | **1.9** | 809 | 4 | 77 | 0 of 18 |
| | bestcds | cdsjoin + slim + fastjvm | 7.11 (5.99 to 8.20) | −26 % (−29 to −22) | −57 % | 7.0 | 752 | 4 | 32 | 0 of 36 |
| | best | aot + slim + fastjvm | 6.28 (5.84 to 7.68) | −33 % (−37 to −24) | −61 % | 6.3 | 798 | 4 | 30 | 0 of 36 |
| | **bestq** | **best + client gated while Paper boots** | **4.99** (4.97 to 5.50) | **−45 %** (−47 to −44) | **−65 %** | **1.3** | **683** | 4 | 30 | 0 of 18 |

Absolute times in the final run's 3 jobs (EPYC 9V45 twice, Xeon 8573C), seconds from spawn, median (range):

| Variant | Done | Client ready | State | Kill to state | Paper CPU s |
|---|---|---|---|---|---|
| base | 6.95 (6.82 to 8.02) | 8.42 (8.27 to 9.76) | 8.48 (8.32 to 9.84) | 8.76 (8.63 to 10.14) | 21.2 (21.1 to 25.1) |
| aot | 6.12 (5.78 to 7.35) | 7.06 (6.61 to 8.29) | 7.12 (6.68 to 8.37) | 7.44 (7.14 to 8.72) | 19.6 (18.4 to 23.5) |
| c1 | 4.91 (4.77 to 5.75) | 5.97 (5.88 to 6.88) | 6.01 (5.92 to 6.92) | 6.34 (6.24 to 7.26) | 10.0 (9.9 to 11.9) |
| baseq | 5.00 (4.86 to 6.24) | 6.45 (6.23 to 7.94) | 6.50 (6.29 to 7.98) | 6.79 (6.56 to 8.32) | 19.3 (18.6 to 24.0) |
| best | 5.08 (4.69 to 5.50) | 5.67 (5.28 to 6.10) | 5.73 (5.52 to 6.20) | 6.03 (5.84 to 6.53) | 8.3 (7.9 to 9.5) |
| **bestq** | **4.05** (4.02 to 4.55) | **4.63** (4.62 to 5.11) | **4.69** (4.69 to 5.17) | **4.99** (4.97 to 5.50) | **7.5** (7.4 to 8.5) |

- Done to client ready is 1.5 s for base and baseq, 1.1 s for c1, 0.9 s for aot and 0.6 s for best and bestq: the
  login, configuration and chunk send paths are in the join trained cache, and C1 compiles them sooner.
- **Requirements right after the boot are not slower with C1**; they are faster: platform builds take 30 to 39 ms
  against 85 ms, because right after a boot C2 has not compiled the hot code yet and competes for CPU while it does.
  Chat round trips at rate 200 are 4 to 5 ms for every variant. C1's long run cost (slower compiled code once C2 would
  have finished) was not measured; a restart Paper lives one requirement, the shared stepped Paper should keep C2
  (**inferred**).
- SerialGC alone is slower (+8 %; GC runs on the VM thread inside the boot's critical path, platform 145 ms) but saves
  150 MB; with C1 it is neutral and saves memory, so the combination keeps it.

## Four boots at once

Four Papers, each with its own warm client, killed and booted at the same moment (a barrier before the kill), 6 rounds
per job. Kill to state per boot, median over jobs (range); round wall is first kill to last state read.

| Variant | Kill to state per boot s | Against base | Round of 4, wall s (per job median) | Paper CPU s per boot | Client CPU s per restart | Peak memory used, whole runner | Wrong |
|---|---|---|---|---|---|---|---|
| base | 60.7 (42.2 to 71.1) | | 43.5, 72.3, 68.1, 48.1, 69.7, 55.9 | 23 to 37 | 26.0 | 10.2 to 10.6 GB | 0 of 144 |
| aot | 53.0 (35.6 to 62.1) | −14 % | 37.1, 64.2, 62.6, 41.6, 60.5, 49.0 | 21 to 34 | 20.6 | 10.0 to 10.5 GB | 0 of 144 |
| fastjvm | 49.3 (33.9 to 56.6) | −20 % | 34.8, 57.8, 57.8, 40.1, 56.4, 44.8 | 13 to 20 | 29.2 | 9.6 to 10.2 GB | 0 of 144 |
| best | 39.9 (27.6 to 46.1) | −35 % | 28.2, 47.5, 45.1, 29.5, 45.0, 37.1 | 10 to 16 | 23.3 | 9.5 to 10.0 GB | 0 of 144 |
| baseq | 39.3 (30.6 to 44.7) | −35 % | 31.8, 46.7, 40.9 | 24 to 35 | 7.3 | 10.1 to 10.5 GB | 0 of 72 |
| **bestq** | **18.0** (15.0 to 22.4) | **−68 %** | **15.5, 23.2, 18.5** | 11 to 16 | **3.7** | 9.4 to 10.0 GB | 0 of 72 |

- **Parallel boots only pay off once the clients are quiet and C2 is off.** With today's flags 4 boots take 48 to 72 s,
  12 to 18 s per restart: worse than one at a time (8.8 s). With `bestq` a round of 4 is 15.5 to 23.2 s, 3.9 to 5.8 s
  per restart: better than one at a time (5.0 s). Four boots at about 12 CPU s each plus quiet clients fit the 4 vCPU.
- An ungated client draws its disconnected and loading screens on lavapipe for the whole boot: **13 to 35 CPU s per
  restart with 4 at once**, about as much as the Paper itself. Gated: 3 to 8 CPU s.
- Memory: 4 Papers (0.70 to 0.89 GB each) and 4 clients peak at 9.4 to 10.6 GB of 16.

## Java 26

Run 42433205261: Temurin 26.0.2, 3 sequential jobs (EPYC 7763 twice, 9V45 once) and one parallel job (7763). Java 26
refuses dynamic AppCDS with the agent, so the baseline here is no cache (Java 25's `nocache` was +22 % against base).

| Variant | What | Kill to state s | Against nocache | Paper CPU against nocache | Client CPU s | RSS MB | Platform ms | Wrong |
|---|---|---|---|---|---|---|---|---|
| nocache | no archive | 17.00 (9.54 to 17.28) | | | 18.7 | 990 | 126 | 0 of 18 |
| aot | AOT cache, `-XX:-AOTInvokeDynamicLinking` | 12.26 (7.78 to 12.45) | −28 % (−30 to −19) | −21 % | 12.9 | 920 | 82 | 0 of 18 |
| aotfull | AOT cache, full class linking (builds on 26) | 11.32 (7.10 to 11.88) | −31 % (−35 to −27) | −25 % | 11.8 | 958 | 91 | 0 of 18 |
| best | aot + slim + C1 + SerialGC | 10.46 (6.60 to 10.87) | −37 % (−40 to −32) | −63 % | 12.8 | 812 | 62 | 0 of 18 |
| bestfull | aotfull + slim + C1 + SerialGC | 9.43 (5.99 to 9.51) | −45 % (−46 to −39) | −66 % | 11.4 | 806 | 58 | 0 of 18 |
| **bestfullq** | bestfull + client gated while Paper boots | **7.84** (5.38 to 8.02) | **−54 %** (−56 to −45) | −68 % | 2.1 | 804 | 59 | 0 of 18 |

Four at once (7763): a round of 4 takes **24.5 s with `bestfullq` against 95.8 s with no cache (−75 %)**; per boot
23.5 against 93.2 s; peak memory used 11.2 and 11.5 GB; 0 wrong of 48.

- Full class linking is worth 3 to 4 points over linking without invokedynamic sites.
- On the same CPU (EPYC 9V45) Java 26's `bestfullq` (5.38 s) is about Java 25's `bestq` (4.97 to 5.0 s): Java 26 makes
  the full AOT cache possible but does not make the boot faster. The ranges above are wide because two of three jobs
  drew the slow 7763.
- `-XX:+AllowArchivingWithJavaAgent` makes Java 26 refuse to start; the rig drops it there.

## What a boot spends

Phase profile of one restart per variant (EPYC 9V74 in run 1, EPYC 7763 in the final run), with JFR (not for AOT
caches, see Surprises) and class load logging on, so 10 to 20 percent slower than the measured boots.

Wall clock from spawn, baseline (EPYC 7763):

| Phase | Starts at s | Takes s |
|---|---|---|
| JVM start, log4j, Paper's bootstrap line | 0 | 1.9 |
| Plugin discovery (probe plugin) | 1.9 | 0.3 |
| **Minecraft bootstrap** (registries, blocks, items, shapes), silent in the log | 2.2 | **4.0** |
| DataConverter type registry | 6.2 | 0.8 |
| **Datapack load** (recipes, 1,866 advancements, tags, loot) | 7.0 | **3.1** |
| Server init (properties, configs, network bind) | 10.1 | 1.3 |
| Level prepare (void, 0 spawn chunks kept) | 11.5 | 0.4 |
| Plugin enable, first save, delayed init | 11.9 | 0.7 |
| Done | 12.6 | |
| Client connect to facts ready | 12.6 | 3.5 |

The same marks for `best` (AOT, C1, SerialGC, slim): bootstrap 1.5 to 4.5 s (3.0), datapacks 4.9 to 7.3 s (2.3),
Done at 8.8 s, ready 10.5 s.

CPU seconds per thread at Done, read with `jcmd Thread.print` (live threads only):

| Thread | base (7763) | base (9V74) | aot (7763) | fastjvm (7763) | best (7763) |
|---|---|---|---|---|---|
| Process total at Done | 29.9 | 28.1 | 29.5 | 12.8 | 12.7 |
| C2 compiler threads | 7.5 | 11.6 | **16.3** | | |
| C1 compiler threads | 3.0 | 2.8 | 2.9 | 2.5 | 2.6 |
| Main thread (bootstrap, datapacks) | 4.7 | 4.3 | 3.9 | 3.9 | 3.4 |
| G1 or Serial GC (VM thread for Serial) | 2.6 | 2.4 | 1.7 | 1.5 | 1.5 |
| World gen and datapack workers (`Worker-Main`, common pool) | 2.6 | 2.4 | 2.3 | 2.5 | 3.3 |
| Server thread | 1.5 | 1.4 | 1.1 | 1.2 | 1.0 |

- The JIT is the largest CPU item: C1 and C2 together 10 to 19 s of 28 to 30. C2 compiler threads come and go, so
  their live total undercounts (base 7.5 s at Done, 9.4 s at ready on the same boot).
- The AOT cache moves work from the main thread into C2: its stored profiles (JEP 515) make C2 compile hot code early,
  16 s of C2 by Done. With C1 only that cost disappears, which is why AOT and C1 combine better than either alone.
- What C1 plus the caches leave is mostly single threaded: main thread 3.4 s, C1 2.6 s, workers, server thread.
  A further cut needs the bootstrap and datapack load not to run at all (see What this means).
- Class sources at the baseline restart: 28,488 of 32,666 classes from the AppCDS archive; the rest are skipped at
  dump time (old bytecode linked before dump, signed configurate jars, agent transformed classes, lambda proxies).

## Surprises

- **The client is the hidden cost of a restart.** The rig (and K before it) ungated the client the moment the kill
  landed, so it drew frames on lavapipe through the whole boot. Gating it until Paper logs Done and ungating it right
  before the connect cuts a restart by 23 % alone and by 35 % with 4 at once, and changes no verdict.
- **Paper 26 ignores `allow-nether` in `server.properties`.** The switch moved to `paper-global.yml`
  `misc.enable-nether`. Every "trimmed" Paper 26.3 in these prototypes, including the topology rig, still loaded the
  nether (its level and its chunk save show in the log). Turning it off saves about 0.1 to 0.2 s of the stamped log.
- **Java 25 cannot build a full AOT cache for Minecraft.** `AOTMode=create` fails archiving the heap: the JVM's
  MethodType intern table (`ReferencedKeySet`, one `ConcurrentHashMap$Node[]` of 262,160 bytes) is over the
  archiver's 256 KB object limit, because Minecraft makes that many lambdas. This is C4's "Cannot archive the
  sub-graph" error; it is not the agent. `-XX:-AOTInvokeDynamicLinking` (diagnostic) keeps class linking and builds;
  `-XX:-AOTClassLinking` builds but gains nothing.
- **The AOT cache refuses a different module graph.** `-XX:StartFlightRecording` adds `jdk.jfr`, and a cache with
  linked classes then fails to map (`AOTMode=on` stops the JVM; `auto` would drop it silently). Any flag that adds a
  module must also be present in training.
- **With `-XX:AOTMode=record`, `-Xshare:auto` is an error**, not ignored.
- **A failed AOT create leaves a file that looks like a cache** and makes the next boot fail to map it; delete it on a
  non zero exit.
- **Paperclip's class loader cannot see the step agent's classes** (`ClassNotFoundException: probe.agent.Step`): the
  agent rewrites Minecraft classes to call `probe.agent.Step`, which sits on the app class path, but Paperclip loads the
  server in its own `URLClassLoader`. `-Xbootclasspath/a:<agent jar>` fixes it. The direct classpath launch never hits it.
- **The slim server buys nothing measurable**: the world is under 1.2 s of the boot and the nether 0.1 to 0.2 s.
  spigot's `advancements.disabled: ['*']` works (`Loaded 0 advancements`), yet the datapack phase still takes 3.2 s
  against 3.1 s. Turning advancements off also changes behaviour a requirement may need (the probe's world prep grants
  advancements; with slim it grants 0).
- **Java 26 removed `-XX:+AllowArchivingWithJavaAgent`** (the JVM does not start with it) and refuses dynamic AppCDS
  dumps with any JVMTI agent: "JVMTI agents are not allowed when dumping CDS archives".
- **The runner fleet varies by up to 2 times** (EPYC 9V45 fastest, 7763 and 8370C slowest); a variant can look 20 %
  better or worse than another just by the draw, so only same job ratios are compared.

## What this means for the search

- **A restart Paper should run with C1 only, SerialGC and an AOT cache trained on a real boot with the agent and a
  client join**, and the framework must **keep the restart's clients gated while Paper boots**. That gives about 5 s
  from kill to state on the runner, and makes 4 restarts at once worth it (4 to 6 s each).
- The shared stepped Paper lives the whole suite and should keep tiered C2 (**inferred**: C1's steady state cost was
  not measured; right after a boot C1 is faster).
- The AOT cache must be trained in the same job (or keyed on JDK build, Paper build, plugin jars and every flag that
  changes modules or the class path); a mismatch stops the JVM rather than slowing it.
- On Java 26, AppCDS is no longer an option with the step agent; the AOT cache is, with full class linking.
- What is left is the main thread's Minecraft bootstrap and datapack load (about 5.5 s of CPU). Cutting that needs a
  JVM that has done them before the kill: a pre booted JVM held before any state is read (the world's `level.dat`
  is read for its datapack settings before the datapack load, so the hold point would be before that, around 2 s into
  a 4 to 5 s boot), or a checkpoint and restore (CRaC) of such a JVM. Both risk K2's flaw (state read before the kill)
  and were not tried (**inferred**).

## Rerun

Build from the worktree root:

```
cargo xtask heavy -- bash -c 'cd prototypes/game-verification && ./gradlew --console=plain -q :step-agent:jar :probe-mod:writeClientLaunch :probe-mod:jar :probe-plugin:jar'
```

Mac, from `prototypes/game-verification`, `SDL_MAC_BACKGROUND_APP=1`:

```
python3 orchestrator/run.py prepare
python3 orchestrator/boot.py run --variants base,aot,c1,bestq --n 1 --after 20 --label mac
python3 orchestrator/boot.py run --variants base,bestq --par 4 --label mac
python3 orchestrator/boot.py phases --variant base --label mac
python3 orchestrator/boot_report.py runs/boot.jsonl [--base nocache]
```

Variants are in `boot.py` `VARIANTS`. CI: matrix rows `{ plan: bootseq|bootpar|bootphases, java: "25"|"26", repeat }`
run `orchestrator/ci.py plan <plan>`; `variants` in a row overrides the list.

Mac development runs (M1 Max, load 10 to 28 from other worktrees) only checked that every variant works; no Mac number
is used above.
