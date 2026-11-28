# Realm rollout

How a Realm keeps its hosts (the Realm host itself and every Paper or standalone host running a primary engine) on
one deployment: which hosts take part, how a new deployment is proved and committed, and what happens when a host
leaves, comes back or joins while that is going on.

Code: `services/runtime/loader/core/src/main/kotlin/com/typewritermc/loader/rollout/RealmRollout.kt`. The host side
(`HostRolloutParticipant`) and the wire contract (`skir-src/service/v1/rollout.skir`) are unchanged by this record.

## Decided

Decided with a maintainer on 2026-11-28.

- **A host that leaves or stops answering is dropped from the running rollout and picks up the current projection
  when it comes back; it never blocks the other hosts.**
- **The Realm keeps a target, and each member converges to it on its own.** The target is the committed deployment,
  or a candidate while one is being proved. Joining, repairing and rolling back are one operation: bring this member
  to its projection of the target.
- **A host that joins while a candidate is proved gets the candidate** and joins its gate: one switch, not two.
- **Membership is the presence probe now**, read through one `RealmMembership` interface, so leased presence rows
  (collaboration decision 16) can replace it later without touching the rollout.
- **Leaving is not evidence against a deployment** (accepted downside, below).
- The old "abort when the host set changed during staging" check is deleted: production never gave it a live value,
  and live membership replaces it.

## The model

```
every pass (1 s)
  members  = hosts answering the presence probe now
  target   = candidate being proved, or the committed deployment
  for each member, on its own:
      next step toward its projection of the target (stage, commit, abort, roll back), unless one is in flight
  candidate: every current member ran it healthy for 30 s  -> commit
             a member refused a command or is 5 min late   -> revert to the committed deployment
```

### Members

- A member is a host that answered this pass's presence probe and holds the Realm or primary engine role.
- A host missing from the probe is not a member: its in flight command is dropped and nothing waits for it.
- Dropping a host by mistake costs nothing. Steps are chosen from each host's observed phase, so a host that answers
  again is a member again and continues from where it is.
- A host whose host API the target's runtimes cannot run is not a member of that target; the next content resolution
  includes it.

### One member's step

Chosen from the member's phase and its projection of the target (`ParticipantPhase.step`):

| Member's phase | Step |
| --- | --- |
| idle | stage the projection |
| staged the projection | commit it (a candidate waits for the stage barrier, below) |
| staged something else, running the projection underneath | abort |
| staged something else | stage the projection |
| running the projection | nothing (a committed member that reports it unhealthy is staged again) |
| running something else, retaining the projection | roll back to it exactly |
| running something else | stage the projection |

Each member's commands run on their own; one member never waits for another's command.

### Proving a candidate

- **Stage barrier.** No member commits a candidate before every current member staged it. A candidate that a host
  cannot stage is aborted without switching any running host. A member that leaves drops out of the barrier; a member
  that joins after the barrier opened stages and commits right away.
- **Health gate.** The candidate commits when every current member has run its projection healthy for the last
  30 s. A member that leaves stops counting and the window does not restart for the others. A member that joins has
  to prove its own 30 s. A missing status reply restarts that member's window.
- **Deadline.** Each member has 5 minutes from joining the candidate to prove it, counted per member: a host that
  joins late gets its own 5 minutes.
- **Failure.** A member that refuses a command or misses its deadline fails the candidate. The target returns to the
  committed deployment and the members still present converge back to it (exact rollback to a retained projection, or
  abort when only staged). Hosts that left get nothing; they converge when they return. Once every present member is
  back, content that is still the newest is tried again.

### The committed deployment

- A host that comes back or boots is converged to the target at once, whatever any other host is doing.
- A member that refuses a command, never proves its projection within 5 minutes, or reports the projection it proved
  unhealthy is staged again. A missing reply alone never restages a host.
- A member that joined after the commit has its projection added to the committed record, so artifact maintenance
  keeps it.

## Example: a Paper restarts during a rollout

1. The Realm host and Papers A and B run generation 4. Generation 5 is imported.
2. All three stage generation 5; the barrier opens; all three commit.
3. Paper B restarts at second 10 of the health window. It stops answering the probe and is no longer a member.
4. At second 30 the Realm host and Paper A have proved generation 5: it commits. Before, the Realm waited 5 minutes for
   B, rolled every host back to 4, and waited 5 more minutes for B.
5. Paper B boots, answers the probe, and is staged and committed to generation 5 within a few seconds.

## Accepted downside

Leaving is not evidence against a candidate. A candidate that crashes a Paper's JVM commits without that host, and the
host gets the same deployment again when it returns. Engine faults inside Paper show up as an unhealthy projection,
which does fail a candidate; only a lost host is ignored.

## Open

- **Leased presence.** When presence becomes leased rows, a clean leave shows at once and a crash at the lease time;
  the probe implementation of `RealmMembership` is replaced, the rollout is not.
- **Retry pacing.** A candidate that keeps failing is tried again as soon as its members are back on the committed
  deployment, as before. A backoff is its own topic.

Not proven: a full game run with Paper restarts (the case that found this) exercises join and leave on real hosts;
the unit tests in `RealmRolloutTest` run the rollout against fake hosts on virtual time.
