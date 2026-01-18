# Panel Test Coverage Plan

This document tracks which areas of the panel codebase need tests. Work through these one by one using `/new-tests`.

## Current State

The panel has partial test coverage for low-level utilities (DynamicData, collection masking) and specific UI interactions (graph zoom/drag, inspector editors). However, core business logic and state management are almost entirely untested.

---

## Priority 1: Critical Infrastructure

These are the foundation systems. If they break, the entire app is unusable.

### NATS Communication (`logic/nats.dart`)
- [x] Connection lifecycle: connect, disconnect, reconnect on failure
- [ ] JWT handling and refresh before expiry
- [x] Inbox prefixing for request/response patterns
- [x] Protobuf request/response serialization
- [x] Error handling for timeouts and no responders
- [x] Streaming subscription management

### Authentication (`logic/auth.dart`)
- [ ] OAuth2 flow state management
- [x] User info parsing from JWT claims
- [ ] Token refresh handling
- [x] Logout cleanup of dependent state
- [ ] Error states: network failure, invalid token, expired session

---

## Priority 2: Core Data Engine

These systems manage the editor's data. Bugs here cause data corruption or editor crashes.

### Entry Blueprints (`logic/pages/entries.dart`)
- [x] Blueprint matching against entry data
- [x] Field path resolution and validation
- [x] Entry placement logic (positioning in the graph)
- [ ] Entry creation from blueprint templates
- [ ] Entry modification and field updates

### Dynamic Data (`logic/selectable/dynamic_data.dart`)
- [x] Deep path-based JSON mutation (existing tests)
- [x] Nested object access (existing tests)
- [x] Edge cases: arrays, null values, missing paths
- [x] Type coercion and validation

### Selection Logic (`logic/selectable/selection.dart`)
- [x] Selection state machine (select, unselect, clear, selectAll)
- [x] Single-select vs multi-select behavior
- [x] Shift-key multi-select integration (HardwareKeyboard)
- [x] hasSelection and isSelected providers
- [x] Selected provider (resolving identifiers to Selectables)
- [x] updateFieldValue propagation to all selected items
- [x] fieldValue aggregation (loading, none, value, conflict)
- [x] selectedDataBlueprint overlapping logic

### Data Blueprints (`logic/selectable/data_blueprint.dart`)
- [x] Blueprint validation logic
- [x] Blueprint-to-form generation
- [x] Default value handling
- [x] Required vs optional field semantics

---

## Priority 3: Organization and Resource Management ✅

These manage top-level resources. Bugs affect multi-user collaboration.

### Organization Logic (`logic/organization/organization.dart`)
- [x] JoinRequest expiration (isExpired, remainingDuration)
- [x] JoinCode expiration (isExpired, remainingDuration, never expires)
- [x] UserJoinRequest expiration
- [x] MemberRole model validation
- [x] JoinCodeOptions model and sealed class patterns
- [ ] Organization creation flow (requires NATS mocking)
- [ ] Invite link generation and validation (requires NATS mocking)
- [ ] Organization switching and state cleanup (requires NATS mocking)
- [ ] State synchronization with backend (requires NATS mocking)

### Books Management (`logic/books.dart`)
- [x] filteredBooksProvider filtering by title and tags
- [x] BookExtension.withColor immutability
- [x] BookIdentifier equality and hashCode
- [ ] Book lifecycle: create, delete, rename (requires NATS mocking)
- [ ] Book switching and dependent state invalidation (requires NATS mocking)

---

## Priority 4: UI Logic ✅

Interactive components with complex state management.

### Graph Component (`widgets/app/components/graph/`)
- [x] Node positioning (partial existing tests)
- [x] Drag-and-drop (partial existing tests)
- [x] GraphElement geometry (inside/outside checks)
- [x] EdgeSide vector math
- [x] GraphEdge connection logic
- [ ] Connection creation between nodes (requires widget tests)
- [ ] Node selection and multi-select (requires widget tests)
- [ ] Overlapping node handling (requires widget tests)
- [ ] Cyclical edge detection and prevention (requires widget tests)
- [ ] Zoom and pan boundaries (requires widget tests)
- [ ] Center-of-mass calculation (private classes, would need refactoring)

### Inspector (`widgets/app/components/inspector/`)
- [x] Form generation (partial existing tests)
- [x] ValidatedTextField validation and error display
- [ ] Missing field handling (requires widget tests)
- [ ] Dynamic field types based on blueprint (requires widget tests)
- [ ] Nested object editing (requires widget tests)

### Tree View (`utils/tree_view/tree_view.dart`)
- [x] Recursive structure management (existing tests)
- [x] Path construction algorithm (merging, splitting, edge cases)
- [ ] Expand/collapse state persistence (requires widget tests)
- [ ] Drag-and-drop reordering (requires widget tests)
- [ ] Search and filter (requires widget tests)

---

## Priority 5: Utilities and Helpers ✅

Lower risk, but worth covering for completeness.

### API Exception Handling (`logic/proto/api_exception.dart`)
- [x] Skipped (trivial pass-throughs, not worth testing)

### String Utilities (`utils/string.dart`)
- [x] Formatting functions (formatted, join)
- [x] Case conversion (titleCase, snakeCase)
- [x] Singularization (singular)
- [x] Helpers (asInt, nullIfEmpty)
- [x] Code generation (generateCode)

### Collection Utilities (`utils/collection.dart`, `utils/map.dart`)
- [x] Recursive merging/masking (existing tests)
- [x] Random selection (randomOrNull, randomElement, randomSubset)
- [x] List utilities (indices, joinWith, intersection)
- [x] Iterable utilities (minByOrNull, maxByOrNull, excluding, allAre)
- [x] stringMap conversion function

---

## How to Use This Plan

1. Pick an unchecked item from the highest available priority level.
2. Run `/new-tests` with the target file or module.
3. Complete the tests and mark the item as done with `[x]`.
4. Commit and move to the next item.

Work top-down through priorities to maximize impact.
