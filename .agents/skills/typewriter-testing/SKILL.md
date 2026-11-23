---
name: typewriter-testing
description: Write, change or review Typewriter tests in services, backend, panel or xtask. Use before adding or editing a test, when judging whether a test proves anything, and when test code repeats setup a shared harness should own.
---

# Typewriter Testing

A test protects one requirement: an outcome a player, author, operator or caller relies on. Its
name states that outcome. It fails when the outcome is missed and keeps passing through every
refactor that keeps the outcome.

## Before writing

1. Say the requirement as one sentence: "a declined join request gives no access". If you cannot,
   there is nothing to test yet.
2. Pick the lowest layer that observes it through a public boundary.
3. Find the harness that already builds that state, and use it.

| Layer     | Proves                                                                                          | Harness                                                                                                  |
|-----------|-------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------|
| Unit      | rules with many cases: expressions, parsing, framing, admission                                 | plain tests beside the code                                                                              |
| Property  | an invariant over generated inputs                                                              | proptest, bolero, kotest-property                                                                        |
| Component | one backend component's contract on a real broker and database                                  | `TestContext` in backend/tests                                                                           |
| Realm     | authoring, commit and publication rules on a real Realm                                         | `setup(...)` with `withSetup`                                                                            |
| Widget    | panel behaviour: keyboard, overlays, unsaved work, offline states                               | `pumpPanel(traits)` from testkit                                                                         |
| Scenario  | a user journey through panel, backend and Realm; failures through faults                        | the `Panel` driver in integration_test                                                                   |
| Game      | what a player perceives in a real Minecraft client: chat, text, blocks, entities, input, frames | `requirement(...)` in a module's `src/gameTest`, real clients on a stepped Paper; `cargo xtask e2e game` |
| Harness   | CI runs the right checks, stacks clean up, evidence leaks no secret                             | tests beside the xtask module                                                                            |
| Scale     | a realm gate at full size; never in `:realm:test`                                               | the seeded realm measurement, run by `cargo xtask check realm-scale`                                     |

## What to assert

- The outcome where its user sees it: the reply, the state after a reload, what the screen shows.
- A refusal by its reason, and that nothing changed.
- A count or an order only when it is the requirement itself: "never sent twice".

## What to spot

- **The assertion is weaker than the name.** The name promises a denial; the test accepts any error.
- **It checks how, not what.** Planner output, expectation lists, widget tree shape, private fields,
  call logs on a fake.
- **It cannot fail.** It reads back a value it set, or checks the type a typed function returns.
- **It echoes.** Restated constants and slugs, generated code, the language, dependency wiring.
- **It copies production.** Grants, math or acceptance rules rebuilt inside the test.
- **It depends on the environment.** A skip or a branch on an environment variable.
- **It repeats.** The same rule in several suites; one table driven suite holds them.
- **It keeps dead code alive.** No production caller; delete both.

## Examples

```rust
// Name: jwks_failure_does_not_issue_credentials. Passes on a timeout or a decode error too.
assert!(result.is_err());
// The requirement: the callout answers with a denial and issues nothing.
assert_eq!(reply.decision, Decision::Denied(DenyReason::KeysUnavailable));
assert!(reply.user_jwt.is_none());
```

```dart
// Checks the six expectations the edit carries.
expect(edit.prepare().expectations, hasLength(6));
// Checks what they are for.
expect(edit, refusedAfter(renameBook, saved: saved));
```

```dart
// Cannot fail: overrides the provider, then reads the override.
isAuthenticatedProvider.overrideWithValue(const AsyncValue.data(true));
// A scenario signs in for real and sees the organization list.
```

```dart
// Checks how: the key the fake recorded on each send.
expect(realm.saves.last.submission, realm.saves.first.submission);
// Checks what: a held save whose reply was lost ends saved, once, without a
// review. The first save, since the resend is a second one.
realm.saves.first.keepAndLoseReply();
await eventually(() => expect(form.dirty, isFalse));
expect(realm.document.valueAt(title), saved);
expect(world.saveActivity, isNot(MutationActivityPhase.needsAttention));
```

## Game requirements

- When a requirement is about what a player perceives, write it as `requirement(id, sentence) { }` in
  the module's `src/gameTest`, inside `val X by testSuite(compartment = { GameCompartment }) { }`.
- When it needs several players, a failure case or a Paper restart, set `players = n`,
  `demonstrates = Demonstrates.FAILURE` or `EDGE_CASE`, and `restartsPaper = true` (then
  `restartPaper()` kills and boots that Paper).
- Every body makes a positive check, or it fails as refused: a `within(n.ticks) { player sees ... }`
  that holds, a `player.looksLike("name")` whose compare matched, the framework test kit's
  `holds`/`lacks` state check, or `shouldThrow<WindowMissed>` (also `WorkHung`, `ClientLost`,
  `PaperLost`) for a framework outcome the requirement expects. A read after one check held is not
  caught, so assert every read.
- When a body's only check is `looksLike`, add a window too: off the pinned renderer the golden is not
  checked and proves nothing, so the body fails as refused there.
- Set up the scene with `probe.*` and drive the player with its input (`typeInChat`, `press`,
  `click`, `aimAt`, `walkTo`); the window counts from the last of them.
- When a player must leave and come back to the same Paper, call `player.quit()` and
  `player.rejoin()`; while it is away, check only the players still on Paper (`stayer sees
  unlisted(leaver)`), since a window, input or frame of the away player is refused.
- When a requirement is not about joining, act on a player who is already online; quit and rejoin
  only when joining is what it proves, since a join costs far more ticks than any other input.
- When something must not happen, add a broad `player.never sees anyChat()` beside a positive check
  in the same window; a window of only `never` checks is refused.
- When a still scene must look exact, use `looksLike`. A new or changed golden fails on the pinned
  renderer until approved: `cargo xtask goldens approve` for a local Linux run, `cargo xtask goldens
  approve --pr <n>` for the frames a pull request's CI run captured. A Mac reports goldens as not
  checked.
- When a plugin keeps state per player, it resets that state on `PlayerWipeEvent`; a leak shows up as
  an unrelated requirement failing.
- When the thing to prove is a harness flag or launch setting (a heap cap, a JVM option), write a unit
  test of the command the pool builds, not a game requirement: a requirement must perceive something
  (HEAP-1 read JVM flags with no perceived check and became a unit test).

## Watch the harness

A test file holds only its entry point and its test cases; `cargo xtask check quality` fails on
any local helper or class. Pumps, setups, fakes, drivers, page objects, assertions and data
builders live in the stack's kit: panel testkit (end to end support in `integration_test/support`
and, for host side journeys, `test_driver/support`), Kotlin `testFixtures`, Rust `test_support` or
`tests/support`. Test data stays inline. A page object for one widget may have one user.
Generated fixtures are imported from the kit, never pasted as bytes or constants.

Grow the kit, not the test, when you see:

- The same setup or helper shape in several files, or a helper that hides what it sets up.
- A fake that reimplements production.
- Many narrow helpers (`createJoinCode`, `approveJoinRequest`, ...) where one general driver or
  builder would read as well.

Propose the growth to the user with the duplicated places before building it; never grow a large
harness silently, and never add one more narrow helper.

## Properties

When a rule must hold for every input, state it as a property and generate the inputs:
proptest or bolero in Rust, kotest-property in Kotlin, the seeded generator in testkit for Dart.
Fixed seeds and iteration counts keep runs deterministic. A shrunk failure becomes an example
test. Cross host rules (framing, expressions, Skir) compare hosts on one generated corpus.
