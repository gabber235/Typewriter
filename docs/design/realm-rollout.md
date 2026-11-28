# Realm rollout

How a Realm keeps its hosts (the Realm host itself and every Paper or standalone host running a primary engine) on
one deployment: which hosts take part, how a new deployment is proved and committed, and what happens when a host
leaves, comes back or joins while that is going on.

Code: `services/runtime/loader/core/src/main/kotlin/com/typewritermc/loader/rollout/RealmRollout.kt` and
`RealmMembership.kt`. The host side (`HostRolloutParticipant`) keeps its commands; the wire contract
(`skir-src/service/v1/rollout.skir`) only lost the presence's unused active projection.

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
- **Membership has lease semantics** (review, 2026-11-28): a host stays a member until it has been silent for longer
  than a grace of 10 s, the rule leased presence gives later.
- **The committed record keeps exact projection references** (review, 2026-11-28): recorded hosts converge without
  manifests; see "When the committed deployment can no longer be projected".
- **A member's progress lives as long as the target** (review, 2026-11-28): its deadline, a refused command, its
  attempt and a command in flight survive an absence; only its health window restarts.
- **A participant commits only under the attempt it staged with**: a projection staged under another attempt is staged
  again under the member's attempt first, which moves it without reloading anything.
- **Leaving is not evidence against a deployment** (accepted downside, below).
- A presence answer carries no active projection any more: steps come from participant status alone.
- The old "abort when the host set changed during staging" check is deleted: production never gave it a live value,
  and live membership replaces it.

## The model

```
every pass (1 s)
  members  = hosts that answered the presence probe within the last 10 s
  target   = candidate being proved, or the committed deployment
  for each member, on its own:
      next step toward its projection of the target (stage, commit, abort, roll back), unless one is in flight
  candidate: every current member ran it healthy for 30 s  -> commit
             a member refused a command or is 5 min late   -> revert to the committed deployment
```

### Members

- A member is a host that answered a presence probe within the grace (10 s) and holds the Realm or primary engine
  role. Every answer renews its lease; a host that misses a probe, for example because it answered after the probe's
  half second quiet period, stays a member.
- A host silent for longer than the grace is not a member: nothing waits for it and nothing is sent to it.
- A host that is no longer a member keeps its progress toward the target: when it answers again it continues with the
  same deadline, the same attempt and any refusal it gave, so neither a short absence nor flapping resets a deadline or
  hides a refusal. Its health window restarts, because nothing was observed while it was away.
- Dropping a real member is not free: it stops counting for the commit, and its window restarts when it returns. The
  grace is there so that a late answer never does that.
- A host whose host API the target's runtimes cannot run is not a member of that target; the next content resolution
  includes it.

### Why the grace is 10 s

- The probe stops collecting half a second after the last answer, and the Realm host answers first, so a Paper that
  answers later than that misses one probe without having left.
- A pass is one probe, one status request (up to 5 s while a member does not reply) and the 1 s pause: about 6.5 s at
  worst. A 10 s grace covers one missed probe even in such a pass.
- A host that is really gone stops counting after at most 10 s plus one pass, a third of the 30 s healthy window.

### One member's step

Chosen from the member's status (its phase and the attempt it staged under) and its projection of the target
(`ParticipantStatus.step`):

| Member's phase | Step |
| --- | --- |
| idle | stage the projection |
| staged the projection under the member's attempt | commit it (a candidate waits for the stage barrier, below) |
| staged the projection under another attempt | stage it again under the member's attempt (moves it, reloads nothing) |
| staged something else, running the projection underneath | abort |
| staged something else | stage the projection |
| running the projection | nothing (a committed member that reports it unhealthy is staged again) |
| running something else, retaining the projection | roll back to it exactly |
| running something else | stage the projection |

Each member's commands run on their own; one member never waits for another's command.

A participant binds one projection to each attempt and commits a staged projection only under the attempt it was
staged with. Each member therefore carries its own attempt: a new one whenever its next command names another
projection. When a member's status shows the projection staged under another attempt (the Realm host restarted and
its new attempts are newer), it is staged again under the member's attempt before the commit.

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

- A host that comes back or boots is converged to the target at once, whatever any other host is doing. A recorded
  host gets exactly its recorded projection.
- A member that refuses a command, never proves its projection within 5 minutes, or reports the projection it proved
  unhealthy is staged again. A missing reply alone never restages a host.
- A member that joined after the commit has its projection added to the committed record, so artifact maintenance
  keeps it.

### When the committed deployment can no longer be projected

Decided with a maintainer on 2026-11-28 (option A).

- The committed record keeps each host's exact projection reference, not only its digest.
- A recorded host converges to exactly that reference: a revert rolls it back, and a host that lost its projection
  gets it again, without the deployment's manifests.
- A host without a recorded projection needs the manifests to be projected. When one of the committed deployment's
  artifacts is no longer accepted (a newer import of the same release replaced it), such a host is left alone, the
  same rule as a host whose host API cannot run the target, and a degraded `artifact-rollout-host-unprojectable` span
  records it once per target.
- This also covers a restarted Realm host whose committed artifacts were replaced: the record still gives it a
  target, so a Paper that loses its projection gets it back.

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
- **Replacing the Realm host restarts the attempt counter.** The rollout state file lives on the Realm host. A new
  Realm host starts its attempts from one, which every participant that saw newer attempts refuses as stale until it
  restarts too.
- **A host that always answers late is never a member.** The probe's half second quiet period starts at the first
  answer; a host that answers later than that on every probe never renews its lease. Leased presence rows remove this.
- **Retry pacing.** A candidate that keeps failing is tried again as soon as its members are back on the committed
  deployment, as before. A backoff is its own topic.

Not proven: a full game run with Paper restarts (the case that found this) exercises join and leave on real hosts;
the unit tests in `RealmRolloutTest` run the rollout against real `HostRolloutParticipant`s with fixture runtimes and
messaging on virtual time.
