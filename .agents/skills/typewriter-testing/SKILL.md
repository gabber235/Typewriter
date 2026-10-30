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

| Layer     | Proves                                                                   | Harness                               |
|-----------|--------------------------------------------------------------------------|---------------------------------------|
| Unit      | rules with many cases: expressions, parsing, framing, admission          | plain tests beside the code           |
| Property  | an invariant over generated inputs                                       | proptest, bolero, kotest-property     |
| Component | one backend component's contract on a real broker and database          | `TestContext` in backend/tests        |
| Realm     | authoring, commit and publication rules on a real Realm                  | `setup(...)` with `withSetup`         |
| Widget    | panel behaviour: keyboard, overlays, unsaved work, offline states        | `pumpPanel(traits)` from testkit       |
| Scenario  | a user journey through panel, backend and Realm; failures through faults | the `Panel` driver in integration_test|
| Harness   | CI runs the right checks, stacks clean up, evidence leaks no secret      | tests beside the xtask module         |

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
await expectRefusedAfterRemoteChange(edit, saved: saved, remoteChange: renameBook);
```

```dart
// Cannot fail: overrides the provider, then reads the override.
isAuthenticatedProvider.overrideWithValue(const AsyncValue.data(true));
// A scenario signs in for real and sees the organization list.
```

```dart
// Good: the count is the requirement. A lost reply is never sent again.
await submission.run();
await submission.run();
expect(calls, 1);
```

## Watch the harness

A test file holds only its entry point and its test cases. Pumps, setups, fakes, driver actions,
assertions and data builders live in the stack's kit (panel testkit, the Kotlin test kit and
`testFixtures`, the Rust component kit); test data stays inline. `cargo xtask check quality`
fails on a local helper.

While writing or reviewing tests, ask whether the harness should grow instead of the test:

- The same private helper in several files (`_pump`, `_fixture`, `record()`), or a helper made
  for one test that hides what it sets up.
- Long setup repeated across cases, or a fake that reimplements production.
- Many narrow helpers (`createJoinCode`, `approveJoinRequest`, ...) where one general driver or
  builder would read as well.

When it should, propose it to the user with the duplicated places, at the right scope: a shared
helper in the file, a fixture for the module, or a project harness (testkit, setups, the scenario
driver). Do not grow a large harness silently, and do not add one more narrow helper.

## Properties

When a rule must hold for every input, state it as a property and generate the inputs:
proptest or bolero in Rust, kotest-property in Kotlin, the seeded generator in testkit for Dart.
Fixed seeds and iteration counts keep runs deterministic. A shrunk failure becomes an example
test. Cross host rules (framing, expressions, Skir) compare hosts on one generated corpus.
