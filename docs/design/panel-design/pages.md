# Pages

Every page and transient surface, with the story that captures it. The review walks this list in order. Paths
are below `.xtask/results/stories/`, and each folder holds one image per story variant.

## Page types

| Type | Shape | Judge it on |
| --- | --- | --- |
| **Editor** | Tree, form, inspector panes | Pane lift, tree density, one main action, focus after every action |
| **List** | Title, one table or list, row actions | Dense rows, one left edge, reveal without hover, selection and focus together |
| **Canvas** | Graph with an inspector | Keyboard pan and nudge, role colours, inspector contrast |
| **Doorway** | Sign in, organization picker, crash | The playful register, one obvious next step |
| **Overlay** | Search, dialog, menu, sheet | Origin, focus trap and return, Esc steps out |

## Inventory

| Order | Surface | Route | Type | Story |
| --- | --- | --- | --- | --- |
| 1 | Sign in | `/auth` | Doorway | `features/auth/presentation/authpage/default` |
| 2 | Organizations | `/` | Doorway | `features/organizations/presentation/indexpage/default` |
| 3 | Services | `services` | Canvas | `features/services/presentation/servicespage/default`, `.../inspector` |
| 4 | Members | `members/` | List | `features/members/presentation/memberlistpage/default` |
| 5 | Join requests | `members/join-requests` | List | `features/members/join_requests/presentation/joinrequestspage/default` |
| 6 | Join codes | `members/join-codes` | List | `features/members/join_codes/presentation/joincodespage/default` |
| 7 | Realm home | `realm/:realmId/` | List | `features/realms/presentation/realmhomepage/default` |
| 8 | Resource editor | `realm/:realmId/resource/:resourceId` | Editor | `features/realms/presentation/resourcesurface/routed-resource` |
| 9 | Search | Overlay on any page | Overlay | `shared/search/presentation/searchmodal/default` |
| 10 | Conflict review | Overlay in the editor | Overlay | `authoring/presentation/authoringconflictnotice/retained-conflict`, `.../authoringconflictcomparison/complete-group-comparison` |
| 11 | Type picker | Overlay in the editor | Overlay | `authoring/presentation/authoredresourceeditor/creation-type-picker` |
| 12 | Graph | Inside canvas pages | Canvas | `shared/graph/presentation/graph/default` |
| 13 | Start up, connection lost, crash | Any route | Doorway | `shared/ui/screens/` stories |
| 14 | Realm inbox, activity, selector | Sheets from any page | Overlay | Their stories under `features/realms` and `shared/` |

Golden pages do not exist yet, since no page meets this target. The first pages rebuilt to the target and approved
by a maintainer become the golden set for each type, and they are added here with their annotations.
