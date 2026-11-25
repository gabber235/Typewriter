# Intended `.github/workflows/ci.yml` change: delegate a cgroup to the game suites

One step in the `e2e` job, after `./.github/actions/devenv` and before the verdict run. It runs only
for the game suites (`GAME_SUITE`); the panel suites measure nothing.

```yaml
      - uses: ./.github/actions/devenv
        with:
          ...
      # The game suites measure each part's memory in a cgroup of its own. The step remounts the
      # runner's cgroup tree writable, moves the job's processes into `typewriter/job`, gives the
      # job user `typewriter` and names it in `TYPEWRITER_CGROUP` for the steps after it.
      - if: env.GAME_SUITE
        run: devenv --profile e2e shell -- cargo xtask cgroup delegate
      - run: devenv --profile e2e shell -- cargo xtask e2e ${{ matrix.suite }} --base "$BASE_SHA"
```

## What it does

- `sudo mount -o remount,rw /sys/fs/cgroup`, then `sudo mkdir -p /sys/fs/cgroup/typewriter/job`.
- Moves every process of the root cgroup into `typewriter/job`, so the runner, its worker and
  every later step start below `typewriter`, the common ancestor the job user must own to move its
  own processes between leaves.
- Enables `+memory +pids` on the root and on `typewriter`, and `chown -R`s `typewriter` to the job
  user.
- Appends `TYPEWRITER_CGROUP=/sys/fs/cgroup/typewriter` to `$GITHUB_ENV`.

## What the later steps do with it

- `cargo xtask e2e <suite>` makes `typewriter/run-<id>/{stack/<service>, gradle, game}`, starts
  each stack service and Gradle in its leaf, and hands Gradle `PLAYTEST_CGROUP` naming `game`.
- The pool reads the budget from `game/memory.max`, moves itself into `game/pool` and each part it
  starts into `game/<part>-<pid>`, records each part's peak (`memory.peak`) in the run file, and
  names a part the kernel killed for memory (`memory.events` `oom_kill`) as lost to `memory_limit`.
- Report mode: every cgroup's `memory.max` is the runner's total, so nothing is killed. Admission
  records whether each part's planned limit fits the budget and never refuses a part.
- The demo run makes its own tree the same way.
- Without this step the suites run as before and print that memory per part is not measured.
