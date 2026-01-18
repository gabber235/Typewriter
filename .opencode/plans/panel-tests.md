# Panel Test Coverage Plan

This document tracks which areas of the panel codebase need tests. Work through these one by one using `/new-tests`.

## Current State

The panel has partial test coverage for low-level utilities (DynamicData, collection masking) and specific UI interactions (graph zoom/drag, inspector editors). However, core business logic and state management are almost entirely untested.

---

## Priority 1: Critical Infrastructure

These are the foundation systems. If they break, the entire app is unusable.

### NATS Communication (`logic/nats.dart`)
- [ ] Connection lifecycle: connect, disconnect, reconnect on failure
- [ ] JWT handling and refresh before expiry
- [ ] Inbox prefixing for request/response patterns
- [ ] Protobuf request/response serialization
- [ ] Error handling for timeouts and no responders
- [ ] Streaming subscription management

### Authentication (`logic/auth.dart`)
- [ ] OAuth2 flow state management
- [ ] User info parsing from JWT claims
- [ ] Token refresh handling
- [ ] Logout cleanup of dependent state
- [ ] Error states: network failure, invalid token, expired session

---

## Priority 2: Core Data Engine

These systems manage the editor's data. Bugs here cause data corruption or editor crashes.

### Entry Blueprints (`logic/pages/entries.dart`)
- [ ] Blueprint matching against entry data
- [ ] Field path resolution and validation
- [ ] Entry placement logic (positioning in the graph)
- [ ] Entry creation from blueprint templates
- [ ] Entry modification and field updates

### Dynamic Data (`logic/selectable/dynamic_data.dart`)
- [x] Deep path-based JSON mutation (existing tests)
- [x] Nested object access (existing tests)
- [ ] Edge cases: arrays, null values, missing paths
- [ ] Type coercion and validation

### Data Blueprints (`logic/selectable/data_blueprint.dart`)
- [ ] Blueprint validation logic
- [ ] Blueprint-to-form generation
- [ ] Default value handling
- [ ] Required vs optional field semantics

---

## Priority 3: Organization and Resource Management

These manage top-level resources. Bugs affect multi-user collaboration.

### Organization Logic (`logic/organization/organization.dart`)
- [ ] Organization creation flow
- [ ] Invite link generation and validation
- [ ] Organization switching and state cleanup
- [ ] Member role management
- [ ] State synchronization with backend

### Books Management (`logic/books.dart`)
- [ ] Book lifecycle: create, delete, rename
- [ ] Book switching and dependent state invalidation
- [ ] Book data persistence

---

## Priority 4: UI Logic

Interactive components with complex state management.

### Graph Component (`widgets/app/components/graph/`)
- [x] Node positioning (partial existing tests)
- [x] Drag-and-drop (partial existing tests)
- [ ] Connection creation between nodes
- [ ] Node selection and multi-select
- [ ] Overlapping node handling
- [ ] Cyclical edge detection and prevention
- [ ] Zoom and pan boundaries

### Inspector (`widgets/app/components/inspector/`)
- [x] Form generation (partial existing tests)
- [ ] Missing field handling
- [ ] Validation error display
- [ ] Dynamic field types based on blueprint
- [ ] Nested object editing

### Tree View (`utils/tree_view/tree_view.dart`)
- [x] Recursive structure management (existing tests)
- [ ] Expand/collapse state persistence
- [ ] Drag-and-drop reordering
- [ ] Search and filter

---

## Priority 5: Utilities and Helpers

Lower risk, but worth covering for completeness.

### API Exception Handling (`logic/proto/api_exception.dart`)
- [ ] Error code parsing
- [ ] User-friendly error message mapping
- [ ] Unexpected error fallback

### String Utilities (`utils/string.dart`)
- [ ] Formatting functions
- [ ] Case conversion
- [ ] Singularization/pluralization

### Collection Utilities (`utils/collection.dart`, `utils/map.dart`)
- [x] Recursive merging/masking (existing tests)
- [ ] Edge cases for deep merge conflicts

---

## How to Use This Plan

1. Pick an unchecked item from the highest available priority level.
2. Run `/new-tests` with the target file or module.
3. Complete the tests and mark the item as done with `[x]`.
4. Commit and move to the next item.

Work top-down through priorities to maximize impact.
