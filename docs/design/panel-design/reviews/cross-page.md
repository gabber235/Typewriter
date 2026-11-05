# Cross page report

Reviewed at `8e115a5f0` on 2026-11-06: every surface in the `panel-review` inventory. Page reports sit beside this file.

## Summary

No page meets the rules yet. Most faults come from a few shared causes, so fix those first: each one clears findings on many pages at once.

## Shared causes, in fix order

| Cause | Where | Clears |
|---|---|---|
| Confirmation dialog focuses the destructive button, and Shift skips it | `popups.dart:151,191,198`, `shortcuts.dart:81-88` | MEMBERS-1, MEMBERS-2, SERVICES-1, JOINREQ-1, JOINCODES-1, ORGS-5 |
| Permanent actions on one press with no hold | Publish and Discard in the inbox, Use saved in conflict review | SHEETS-1, SHEETS-2, CONFLICT-1 |
| No focus on open, and no focus target after remove or create | Every route; focus scopes in `panes.dart` | MEMBERS-3, MEMBERS-4, SERVICES-2, SERVICES-3, RESOURCE-1, RESOURCE-2, SIGNIN-1, ORGS-1, JOINREQ-2, JOINREQ-3, JOINCODES-3, JOINCODES-4, SHEETS-3, CONFLICT-2 |
| No motion tokens; every widget writes its own durations and curves | `panel/lib`, `animation.dart`, `Expansible` uses, bulk bars, `StaggerEntrance` per cell | MOTION-1 to MOTION-38, SEARCH-4 to SEARCH-6, GRAPH-1, GRAPH-2, JOINCODES-10 to JOINCODES-13, JOINREQ-7, JOINREQ-9 |
| Failures go to snackbars or tooltips with raw text | `ScaffoldMessenger` call sites, `LoadingButton`, `skir_mutation.dart:188` | MEMBERS-5, MEMBERS-10, SERVICES-8, RESOURCE-12, SIGNIN-3, ORGS-4, JOINREQ-6, SHARED-JOINCODES-2, SEARCH-2 |
| A lost service shows the crash screen with "report this to the Typewriter discord" | Crash and start up screens | MEMBERS-6, SERVICES-9, SEARCH-1, SCREENS-1, SCREENS-2 |
| Theme: sentences in mono, grey focus ring, danger and brand colours as text under 4.5:1 | `color_scheme.dart`, `component_themes.dart:158`, text theme | MEMBERS-8, MEMBERS-14, RESOURCE-7, RESOURCE-20, RESOURCE-21, SHARED-SIGNIN-1, SHARED-JOINREQ-1, SHARED-CONFLICT-1, SHARED-SCREENS-1, JOINCODES-9, GRAPH-7, SHEETS-7 |
| Focus drawn as a fill, the same as selection | Row and card focus | MEMBERS-9, SERVICES-7, SEARCH-3, JOINCODES-8 |
| Actions without an Intent, key, or command list entry | Callbacks on buttons | RESOURCE-3, RESOURCE-4, SIGNIN-2, ORGS-3, JOINCODES-5, TYPE-4, CONFLICT-3, SCREENS-4, SHEETS-6, SHARED-GRAPH-1 |
| Key caps never shown or glowing | `ShortcutDisplay` | MEMBERS-17, RESOURCE-15, SEARCH-13, SHEETS-12, JOINREQ-16, JOINCODES-22, SHARED-TYPE-2 |
| Compact starts at 450 px, not 900 px | `responsive.dart:17` | RESOURCE-6, SHEETS-S1 |
| `EmptyState` has no mascot, playful line, or keyed action | Shared component | MEMBERS-23, SERVICES-20, SEARCH-10, SHEETS-13, ORGS-13, JOINREQ-17, JOINCODES-21, GRAPH-14 |

## One action, different names or keys

| Action | Today |
|---|---|
| Remove | D and Shift+D on Members, Join requests, Join codes; Ctrl+Backspace on Services; no key on Organizations. Named Remove member, Remove Member, Remove, Decline, Revoke, Unbind, Cancel request, Revoke request |
| A | Apply roles on Members, Accept on Join requests, Create in the editor |
| Create | N, A, and numpad + in the editor; no key for Generate, Create organization, or New book |
| Accept | Accept, Approve, Accept All, Accept requests, Confirm & Add Member |
| Save | Apply in the inbox, Save in activity |
| Needs attention | Orange on the inbox button, red on the activity button |
| Status colours | Graph and inspector use different maps; graph and timeline mode chips use different colours |

## Pages that differ

| Aspect | Today | Rule |
|---|---|---|
| Row height | Rail 28, Search 64, Members 74, Organizations 78 to 90, Join codes 81, Join requests 98 px | About 42 px |
| Many things with details | Table on Members and Join codes, cards on Join requests and Services; inspector only on Services | Table with inspector |
| Heading | `PageHeading` on some pages; local `Text` on the editor, Sign in, Organizations | `PageHeading` |
| Main action | Floating in the editor; filled in the body on Services, Join codes, Organizations, the inbox | Pane header, with its key |
| Loading | Spinner on Services, editor, Organizations; random skeleton in Search; mismatched skeleton on Members; blank on realm home | Skeleton of the real layout, or a doorway |
| Larger surface | Centred dialogs for search, type picker, conflict review; elastic sheets; framework popovers | Grows from its opener with `surfaceIn` |

## Moves that lose the user's place

- Every page opens with nothing focused.
- Opening an organization, a realm, or a rail row replaces the page; the row never becomes the heading.
- Closing the inbox returns focus to the page, not the inbox button.
- A reconnect hides the whole panel behind the start up screen.

## Outside the panel

- Services send durations and curves in the presentation contract (`SurfaceLayouts.kt:11-14`, `PresentationPaint.kt:88-91`). See MOTION-20 and the maintainer choice on motion from services.
- The story renderer skips each knob's first option (`support/stories.dart:200`), and a Loading knob past the 10 s timeout captures the crash screen. Several states never render because of this.
