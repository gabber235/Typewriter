# Realm home review

Route `realm/:realmId/`. Story images under
`.xtask/results/stories/features/realms/presentation/realmhomepage/default/` (`initial`, `dark`,
`Realm=Online|Host-offline|Checking|Unavailable|Content-unreadable` at `Window=Desktop|Compact`).
Source: `panel/lib/features/realms/presentation/resource_route.dart:5-23` (`RealmHomePage`),
`resource_navigator.dart:133-154` (`RealmSectionsNavigator`),
`panel/lib/features/organizations/presentation/organization_route.dart` (shell, sidebar, app bar),
`realm_suspension.dart`, `panel/lib/authoring/presentation/resource_issue_badge.dart`.

The realm home is the resource surface of the root's first section (Library), so most of its body
is the resource editor already reviewed in `resource-editor.md`. This report covers what the realm
home adds: the route, the realm part of the shell (sidebar sections, realm breadcrumb, inbox
button), and the realm states. The inbox, activity, and realm selector sheets are in
`realm-sheets.md`.

Key paths were checked with a throwaway widget probe on `pumpStory` (deleted after the run);
"probe" below refers to it.

## Summary

Not good yet. The page shows the right things, but a keyboard user is locked inside the body:
Tab and Ctrl+Arrows only cycle the two book cards and New book, so the realm sections, the realm
selector, search, and the inbox button can never be focused. Nothing is focused on open
(RESOURCE-1), and offline states blur the page behind a centred card (RESOURCE-8).

Single most valuable change: make the shell reachable. Tab should move between groups (sidebar
sections, breadcrumb, app bar actions, body) and Ctrl+Arrows between panes, starting from the
routed section row on open.

## Findings

- id: REALMHOME-1
  rule: "Any action"
  severity: 3
  region: "Sidebar Realm sections (Library, Tags), breadcrumb realm selector, app bar inbox button"
  evidence: "probe: on open focus is the route scope; Tab 1 to 12 cycles The Lost Village, Atlas of Echoes, New book; Ctrl+Left, Up, Right, Down stay on those three; organization_route.dart:219-223"
  observed: "With keys only, the user cannot reach the realm sections, the realm selector, or the inbox button. Switch Panes in the hint bar does not leave the body. Only Shift+P reaches the inbox."
  fix: "Make the sidebar and app bar focus groups that Tab visits, and let Ctrl+Arrows move to the sidebar pane."

- id: REALMHOME-2
  rule: "A value revealed on hover"
  severity: 3
  region: "Orange question mark right of the Library heading, inbox Unavailable"
  evidence: "story realminboxbutton/live-review/Review=Unavailable.png (top right of the heading); resource_issue_badge.dart:32-58 (status only in Tooltip and Semantics, icon has no text when issues are empty)"
  observed: "When issue review is unavailable the heading shows a lone 14 px orange question mark. 'Issue review unavailable' appears only in a hover tooltip; it is not focusable and touch cannot reveal it."
  fix: "Write the status next to the mark, for example 'Issues unknown', in the quiet style."

- id: REALMHOME-3
  rule: "Something is empty"
  severity: 2
  region: "Sidebar 'REALM' heading, Content unreadable"
  evidence: "stories Realm=Content-unreadable,Window=Desktop.png and Compact.png; organization_route.dart:219-220; resource_navigator.dart:146 (returns SizedBox.shrink when the root is unknown)"
  observed: "The REALM heading stays with nothing under it, so the sidebar looks broken rather than saying why sections are missing."
  fix: "Hide the heading with its content, or show one quiet line under it that the realm content could not be read."

- id: REALMHOME-4
  rule: "Nothing about the page is known yet"
  severity: 2
  region: "Whole body before the authoring scope is known"
  evidence: "resource_route.dart:12-13 (`if (scope == null) return const SizedBox.shrink()`); no story shows it"
  observed: "While the realm scope is unresolved the body is blank: no doorway screen and no words."
  fix: "Show the doorway screen, 'Connecting to the realm', until the scope resolves."

- id: REALMHOME-5
  rule: "A surface is new or changed"
  severity: 2
  region: "Realm home story"
  evidence: "realm_home.stories.dart:5-8; realm_story.dart:27-44; resource_route.dart:15-19"
  observed: "No image shows: a realm with no sections ('This realm has no sections yet'), the scope still unknown, a focused or hovered section row, a section other than the first routed as home, the inbox open over the page, or a window under 450 px where the sidebar collapses. The Compact knob is 800 px and still renders the desktop shell."
  fix: "Add the empty realm and unresolved states, a focus image, and a phone width window."

## Shared

- id: REALMHOME-S1
  rule: "Text appears"
  severity: 2
  region: "Realm connection lost card: 'Just now' and Check again"
  evidence: "stories Realm=Host-offline,Window=Desktop.png and Compact.png; realm_suspension.dart:163-186 (a vertical SizedBox(height) is the only gap inside a Row)"
  observed: "The last seen status 'Just now' runs into the Check again button with no space between them. The card is shared by every realm route."
  fix: "Give the status its own reserved line under the title, or a horizontal gap token before the button."

## Known faults this page shows

Not repeated; listed so a maintainer can see the page's full state.

- RESOURCE-1: nothing focused on open (probe confirms on this route).
- RESOURCE-6: the 800 px Compact window keeps sidebar and body side by side; cause in SHEETS-S1.
- RESOURCE-8, MOTION-22: offline and checking blur the page behind a centred card that strikes in.
- RESOURCE-9: 'Authoring is unavailable: Bad state: The Realm did not answer'.
- RESOURCE-10: 'ProviderException' over the breadcrumb on Unavailable. Cause: the realm selector's error builders return the raw error text (`selector_popup.dart:83`, `:86`, `:89`, `error: (title, error) => Text(error)`).
- RESOURCE-13, RESOURCE-14, RESOURCE-15, RESOURCE-26: New book floats bottom right with a dark outline and no key cap.
- RESOURCE-20, RESOURCE-21: Lilex for sentences ('Every book of the realm'); grey focus ring.
- SERVICES-16: 'Switch Focus', 'Switch Panes' in the hint bar are title case.
- SHEETS-19: the breadcrumb and the offline card name the realm by its host ('Paper Alpha' for realm `main`).
- Motion: MOTION-15 (route change), MOTION-20 (book cards), MOTION-33 (body appears at once), MOTION-34 (opening a section does not carry the row into the heading), MOTION-3, MOTION-4 (sidebar rows).

## Action walk

| Action or state | Keys only | Focus after | Move expected | Code and move found |
|---|---|---|---|---|
| Open realm home | n/a | Route scope (RESOURCE-1) | Rows ripple in from the right, `loadIn` | Framework route; body appears at once. MOTION-15, MOTION-33 |
| Open a section (Library, Tags) | Unreachable. REALMHOME-1 | n/a | Row becomes the page heading | `resource_route.dart:78-79` navigates and replaces. MOTION-34 |
| Switch realm | Unreachable. REALMHOME-1 | n/a | See realm-sheets.md | SHEETS-5 |
| Open inbox | Shift+P works | Close button. SHEETS-3 | `surfaceIn` from the button | `AnchoredPopup`. MOTION-11 |
| New book | Tab reaches it | See resource-editor.md | `rowIn` | MOTION-36 |
| Search | Ctrl+K works | Query field | `panelIn` | Out of scope (search.md) |
| Realm goes offline or checking | n/a | Unchanged | One steady notice | Veil scales up on `ElasticOutCurve(0.7)`. MOTION-22 |
| Checking: realm name loads | n/a | n/a | Skeleton | `ShimmerBox` in the breadcrumb (`selector_popup.dart:103`). pass |
| Check again | Not probed | Not probed | Busy word ripples with `ripple` | `OutlinedButton.icon` with no busy state (`realm_suspension.dart:180-184`); the retry shows only the card's progress bar. MOTION-8, MOTION-18 |

## Cannot verify

- "Choosing how strong a move is", and how any move feels: no token runs, so nothing to judge.
- "Writing text" for 'Every book of the realm': light grey on canvas looks under 4.5:1; RESOURCE-7 already covers description contrast on this surface, so not recomputed.
- Command list contents for Library and Tags: the probe's Ctrl+K search fails in the story ('The Realm double has no search'), so section entries could not be listed.

## Rule results

<details>
<summary>One row per checked rule</summary>

| When | Result |
|---|---|
| A user's action finishes and they have not moved on | see realm-sheets.md |
| The focused thing disappears | cannot_verify: nothing on this page removes a focused item |
| A page or surface opens | fail: RESOURCE-1 |
| Something happens that the user did not just do | fail: MOTION-21, offline veil |
| A task concerns something on screen | pass |
| A choice comes from a short fixed list | pass: realm selector is a popover |
| A task needs more room than its place has | fail: RESOURCE-8 (centre strike) |
| The window is under 900 px, or a pane would be narrower than 320 px | fail: RESOURCE-6, SHEETS-S1 |
| Anything needs saying | pass |
| Something is empty | fail: REALMHOME-3 |
| Access is lost | cannot_verify: no story |
| The connection or a service is lost | fail: RESOURCE-8 |
| Nothing about the page is known yet | fail: REALMHOME-4 |
| The layout is known and its content is not | pass: breadcrumb shimmer while checking |
| Content is on screen and refreshing | cannot_verify: no story |
| Loaded content arrives | fail: MOTION-33 |
| Showing any state on something | fail: offline card outline button; RESOURCE-26 |
| A button has a key | fail: RESOURCE-15, SHEETS-12 |
| Focus moves | fail: MOTION-4 |
| A pane gains focus | fail: MOTION-5 |
| Reduced motion is on | fail: MOTION-2 |
| Adding an action | cannot_verify: command list unreadable in the story |
| Moving around | fail: REALMHOME-1 |
| Keys change meaning | pass: NORMAL chip |
| Placing an action | pass |
| Setting any visual value | fail: RESOURCE-21 |
| Showing a state | pass on this page; see SHEETS-8 for the inbox button |
| Showing the health of many things | pass: quiet inbox, words on problems |
| A static page feels boring | fail: grey book cards (resource-editor suggestion) |
| Adding colour to a page | pass |
| Styling a static page | fail: RESOURCE-26 |
| Writing text | cannot_verify (see above) |
| Choosing a font | fail: RESOURCE-20 |
| Misreading would cost the user something | fail: RESOURCE-9 |
| One thing shows in several places | fail: SHEETS-19 |
| A surface is new or changed | fail: REALMHOME-5 |
| A value revealed on hover | fail: REALMHOME-2 |

</details>

## Skill friction

- The realm home renders the same surface as the resource editor's Library story, so almost every visible fault already has a RESOURCE id. The inventory could mark it as "shell and realm states only".
- The inventory row's surface is mostly shell (sidebar, breadcrumb, app bar) that every realm page shares. It is unclear whether shell keyboard faults belong to a page or to `cross-page.md`; I kept REALMHOME-1 here because only realm routes add these controls.
- "Text appears" was the closest rule for two elements overlapping; no Look rule covers collision.
- The Compact knob is 800 px, while the design rule switches at 900 px and the code at 450 px. The skill does not say which width a compact image must be.

## Suggestions

- Purpose in two seconds: the page title says 'Library' and the realm appears only as a small breadcrumb chip. Say whose realm this is in the heading area, for example the realm name above the section name.
- First time user: an empty realm says 'This realm has no sections yet' with no next step. Sections come from installed services; say that, and link to Services.
- Rule gap, Look: When two elements share a row, Then keep at least `space2` between them and never let text run under a control. Sev 2.
