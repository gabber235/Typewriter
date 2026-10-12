# Editing ownership

`EditingWorkspace<S, E>` owns confirmed observations, the pending operation log, working values, groups, interaction gates, scheduling, captures, and settlement. `S` and `E` are immutable domain values. Feature facades translate user operations into `E` and project `S`; they do not own another draft or save loop.

| Component | Responsibility |
| :--- | :--- |
| `EditModel<S, E>` | Interpret observations, replay edits, identify semantic dependencies, validate proposals, and describe effects |
| `EditPersistence<S, E>` | Observe authoritative state and capture one existing server request |
| `ScopedWorkSession` | Own registered drivers, view leases, reservations, and the submission journal for an authenticated scope |
| `EditingWorkDriver<S, E>` | Project common work into activity and supply an optional disposable review view |
| `EditControl` | Expose allowed actions for the group reached through a presentation binding |
| `EditApplyCoordinator` | Reserve and prepare a selection before starting its independent requests |

Realm uses `RealmEditModel` and `RealmEditPersistence`. Service identity and host configuration both use `ValueEditModel`, with their respective persistence adapters. Their server endpoints and transaction boundaries remain separate.

| Domain | Edit admission | Save boundary | Publication boundary |
| :--- | :--- | :--- | :--- |
| Service identity | Valid service name | Snapshot and backend validation | Direct metadata, no separate publication |
| Realm authoring | Representable prepared intent | Structure, consistency, catalog and graph invariants | Completeness and semantic findings |
| Host configuration | Representable configuration | Complete valid execution configuration | Explicit Apply changes desired execution |

`EditorCommitPolicy` chooses when work is submitted. The composed model chooses which work may be saved. Presentation diagnostics explain findings; their severity alone never defines a universal save policy.

| Registration | Timing | Admission |
| :--- | :--- | :--- |
| Realm form or command | Existing manual or automatic policy | Preserve blocked intent and semantic group dependencies |
| Service identity | Automatic after editing | Save applicable operations outside active interactions; allow a later local tail |
| Host configuration | Explicit Apply | Validate the complete configuration, lock submitted work, and require review of authoritative changes during preparation |

A group identifies pending intent, rather than a private copy of the document. Display reads create no dependencies. Captured semantic reads identify dependencies on other groups. Requesting Apply on a dependent group does not request Apply on its manual predecessor.

Submitted operations form an immutable prefix. Later edits remain local. Discard removes only unsent operations. A definite acceptance followed by failed refresh permits observation recovery without resending. Unknown delivery retains its request and resource reservations; retry is available only when the captured request explicitly supports identical replay. Independent selection members release their own resources when settled, while overlapping keys remain reserved until every request using them settles.

`ApplyControls` hides when its bound group is clean. The portable renderer resolves the declared commit binding through the host. Runtime and historical views expose no writable control. No ambient save callback or concrete domain switch is needed.

To compose another supported use case, implement a pure model and a persistence adapter, register an `EditingWorkDriver` with the scoped session, and expose disposable group controls to the view. Confirmed subscriptions belong to that registration. Inspector rebuilds acquire prospective leases before releasing installed views. A rebuild may replace the adapter for future captures; already prepared requests retain their original send and integration functions.

The common lifecycle, selection preparation, controls, value facade, Realm workflows, and service inspectors have regression coverage under `panel/test`. Widgetbook scenarios use the production owners with controlled external responses.

The shared lifecycle contract is `panel/test/shared/editing/editing_workspace_contract_test.dart`. The same scenarios run against both production models. Captured request replay is owned by the submission journal; a value result carries no independent replay callback. Borrowed value views cannot dispose the registered owner.
