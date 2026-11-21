# Search review

Overlay on any page, opened with Ctrl or Cmd+K or the app bar Search button. Stories under
`.xtask/results/stories/shared/search/presentation/searchmodal/default/` (`initial`, `dark`, and
the twelve `Source-state=…,Has-data=…,Include-guidance=…` images), with supporting images from
`searchresultrow/appearance-and-state/`, `query_bar/querybar/default/`, and
`authoring/search/presentation/authoredresourcesearchresult/`.
Source: `panel/lib/shared/search/presentation/` (`search_modal.dart`, `search_body.dart`,
`search_frame.dart`, `search_tree_results.dart`, `search_tree_animated_body.dart`,
`search_result_card.dart`, `search_result_row.dart`, `search_result_empty_state.dart`,
`search_command_info.dart`, `search_shortcuts.dart`, `search_tree_section_header.dart`,
`query_bar/`), `panel/lib/authoring/search/presentation/`.
Key paths were checked with a throwaway widget probe (deleted after the run): `pumpStory` on the
search story, and `pumpStory` on the Services route story followed by Ctrl+K so the real route
opened. "probe" in evidence below refers to it.

## Summary

Usable but not yet right. The basics hold: the query field has focus on open, Esc leaves the field
and a second Esc closes with focus back on the opener, J and K walk results, Space selects, and
every row shows its Ctrl+number key cap. What breaks trust is failure and state: a failing source
replaces the results with the crash screen ("Typewriter hit an error … report this to the
Typewriter discord"), a failing command reports far from its row with no next step, and a focused
row is a full colour fill while a selected row is a border, the reverse of the signal rules. The
overlay itself strikes in at the centre on a 500 ms elastic and leaves just as slowly.

The single most valuable change: treat a failing source as a still message in place ("The realm
did not answer. Search shows what it has; type again to retry.") and keep the results that did
arrive, instead of the crash screen.

## Findings

- id: SEARCH-1
  rule: "Something fails"
  severity: 3
  region: "Results area when every source fails"
  evidence: "search_result_empty_state.dart:82 (`ErrorScreen(title: \"\", message: \"\", child: …)`), error_screen.dart default title and discord line; story Source-state=error,Has-data=false,Include-guidance=false.png"
  observed: "A failed search fills the overlay with the crash screen: a 40 px red `Typewriter hit an error`, `Something went wrong, please report this to the Typewriter discord.`, and below it the source name and `Search source failed`. With no summaries the text is only `Search failed`. Nothing says what to do next, and the user is asked to report an ordinary outage. The crash screen wording itself is MEMBERS-6."
  fix: "Show a still message where the results go, naming the source and the next step (type again, or reconnect the realm). Keep the query and any results other sources returned."

- id: SEARCH-2
  rule: "Something fails"
  severity: 3
  region: "Command status above the results; the row a command ran on"
  evidence: "search_command_info.dart:59-67 (`Failed <label>: <message>` admonition above the results, shakeX), search_tree_results.dart:248-270, :353 (row shakes); no story image of a running, completed, or failed command"
  observed: "A failed result command shakes its row, but the message appears in a red bordered admonition under the query bar, away from the row, as `Failed <label>: <raw message>` with no next step. The busy state swaps the command icon for a spinner (MOTION-8) and shows `Running <label>...`."
  fix: "Say the failure at the row that failed, in words that give the next step, and keep the row's action as the retry. Drop the separate status strip."

- id: SEARCH-3
  rule: "Showing a state"
  severity: 3
  region: "Result rows: focused and selected"
  evidence: "search_result_card.dart:39-51 (focused: full kind colour fill; selected: 1.4 px kind colour border); search_result_row.dart:75 (`selected: row.selected || row.focused`); story searchresultrow/appearance-and-state/initial.png against Focused=false.png; probe: J on a row sets one card focused"
  observed: "In `SearchResultCard` focus is a full fill in the kind colour and selection is a coloured border, the reverse of the rules (fill is selected, ring is focus). In `SearchResultRow` focus and selection set the same `selected` tile, so the two cannot be told apart. The full purple or blue fill is also the largest colour on the overlay."
  fix: "Use the focus ring for focus and a quiet fill for selection in both row components, so a focused selected row shows both."

- id: SEARCH-4
  rule: "The user causes something to arrive"
  severity: 3
  region: "Opening the overlay (Ctrl or Cmd+K, Search button)"
  evidence: "search_modal.dart:204 (500 ms), :212-231 (fade and scale from 0.96 on ElasticOutCurve(0.8), centred over the scrim)"
  observed: "The overlay fades and scales in at the centre of the screen over a dimmed page on a 500 ms elastic. It does not come from the Search button or the focused place, and no token drives it. Severity 3: opening something is an everyday action."
  fix: "Grow the overlay from its opener with `surfaceIn` (from the app bar Search button, or from the top of the active pane for Ctrl+K)."

- id: SEARCH-5
  rule: "Anything leaves"
  severity: 3
  region: "Closing the overlay (Esc twice, Close, barrier tap)"
  evidence: "search_modal.dart:204 (no reverseTransitionDuration, so 500 ms both ways), :215 (reverseCurve easeInCubic)"
  observed: "Closing takes the same 500 ms as opening and shrinks towards the centre, not towards the opener. Severity 3: closing is an everyday action."
  fix: "Leave towards the opener on the Exit curve, faster than the arrival (as `panelOut`, 200 ms)."

- id: SEARCH-6
  rule: "Loaded content arrives"
  severity: 3
  region: "Result list as results arrive and change while typing"
  evidence: "search_tree_animated_body.dart:25-26 (750 ms insert, 500 ms remove), :86 (`initialItemCount`, so the first rows appear without motion), :113 (ElasticTransition per row)"
  observed: "Rows present when the list first builds appear at once. Rows that arrive later all grow together on a 750 ms elastic, and dropped rows shrink over 500 ms, longer than the 300 ms MOTION-17 measured for the same component. No `loadIn` ripple upwards from below. Severity 3: results arriving is the everyday moment of this surface."
  fix: "Ripple the visible rows in with `loadIn` once per answer, change rows that stay without motion, and let leaving rows close with `listOut`."

- id: SEARCH-7
  rule: "Content is on screen and refreshing"
  severity: 2
  region: "Results while a new query is answered"
  evidence: "search_body.dart:155-163 (progress only when no nodes are shown); story Source-state=loading,Has-data=true,Include-guidance=true.png"
  observed: "While a new answer is pending over existing results nothing says so: no status word, no ripple. The rows then jump through inserts and removals (SEARCH-6)."
  fix: "Keep the rows, ripple a short status word such as `Searching` with `ripple`, and swap values without motion."

- id: SEARCH-8
  rule: "The layout is known and its content is not"
  severity: 2
  region: "Results area on first load"
  evidence: "search_result_empty_state.dart:37-38 (ten shimmer boxes of random height 40 to 95 px); search_result_card.dart:95 (rows are 64 px); story Source-state=loading,Has-data=false,Include-guidance=false.png"
  observed: "The skeleton is ten full width boxes of random height, wider and taller than real rows and with no title or key cap shape, so the list jumps when results replace it. A looping progress bar runs over the query bar at the same time (MOTION-18)."
  fix: "Draw skeleton rows at the real row height, inset, and shaped like a row, and drop the progress bar."

- id: SEARCH-9
  rule: "A wait is too short to notice, under 300 ms"
  severity: 2
  region: "Results area and query bar on every query"
  evidence: "search_body.dart:155-163 and search_result_empty_state.dart:158 render loading as soon as the status is loading; no delay gate in either"
  observed: "The skeleton and progress bar show at once for every query with no results yet, so fast answers flash a skeleton."
  fix: "Show the skeleton only once the wait passes 300 ms."

- id: SEARCH-10
  rule: "Something is empty"
  severity: 2
  region: "Results area with no results"
  evidence: "search_result_empty_state.dart:99 (`EmptyScreen(title: \"No results found\", small: true)`); empty_screen.dart:41-44 (literal 20 px bold title, no subtitle slot); story Source-state=ready,Has-data=false,Include-guidance=false.png"
  observed: "Only `No results found`, low in the overlay under an empty mascot area. No playful line, no serious subtitle on what this search covers or how to widen it."
  fix: "A playful line (\"Nothing by that name.\") and a subtitle naming what the search covers, such as `Search looks through pages, books, entries and tags in this realm.`"

- id: SEARCH-11
  rule: "Choosing a key for a new meaning"
  severity: 2
  region: "Ctrl or Cmd+1 to 9 on the first nine results"
  evidence: "search_shortcuts.dart:100-118; key caps on every row in story initial.png"
  observed: "Ctrl or Cmd plus a digit opens the result with that number. This meaning is not in the key language."
  fix: "Add `Ctrl or Cmd+1 to 9: open the numbered result` to the key language, or drop the shortcut."

- id: SEARCH-12
  rule: "Moving around"
  severity: 2
  region: "Tab through the overlay"
  evidence: "probe: from the query, Esc then Tab visits the first row, the second row, then an unlabelled control, then the query again"
  observed: "Every result row is its own Tab stop, so Tab walks rows instead of moving between groups (query, results, actions)."
  fix: "Make the result list one Tab stop that remembers the focused row; arrows and J, K move inside it."

- id: SEARCH-13
  rule: "A button has a key"
  severity: 2
  region: "Close button at the right of the query bar"
  evidence: "search_body.dart:146-150 (InputIconButton with tooltip only); story initial.png"
  observed: "Close is what Esc does from Normal mode, but the button shows no key cap."
  fix: "Show the Esc key cap on Close and press both together."

- id: SEARCH-14
  rule: "Placing content"
  severity: 2
  region: "Query bar, guidance and error notices, result rows"
  evidence: "story Source-state=error,Has-data=true,Include-guidance=true.png (query icon at 35 px, query text at 70 px, notices at 16 px, row cards at 28 px with titles at 40 px); search_result_card.dart:95 (`minHeight: 64`)"
  observed: "Four left edges in one column, and rows are 64 px tall instead of about 42 px, so only a few results fit."
  fix: "Put the query text, notices, and row titles on one left edge, and bring compact rows to about 42 px."

- id: SEARCH-15
  rule: "Setting any visual value"
  severity: 2
  region: "Search frame, rows, preview, motion"
  evidence: "search_frame.dart:550 (radius 20), :552-556 (outline and elevation 3 shadow), :31-34 (880, 0.8, 320, 12); search_result_card.dart:39, :51, :95, :102-123 (alphas, 1.4 border, 64, 6, 10, 140); search_result_visuals.dart:161, :182 (font size 10); every duration and curve in this report"
  observed: "The overlay card uses radius 20 (the pane radius is 12) with an outline and a shadow, though shadows belong only to menus, toasts, and dialogs. Sizes, padding, alphas, and font sizes are literals. Motion literals are MOTION-1."
  fix: "Use the pane radius and spacing tokens, and drop the outline and shadow or make the overlay a token surface that the Values table names."

- id: SEARCH-16
  rule: "Something exists before and after a change"
  severity: 3
  region: "Preview beside or under the results"
  evidence: "search_frame.dart:361-380 (inline: SizeTransition on ElasticOutCurve(0.82), 420 ms), :405-420 (external: scale from 0.88 on ElasticOutCurve(0.5), 460 ms, opacity on the raw linear animation), :226, :256 (sheet: 750 ms elastic in, 400 ms out)"
  observed: "Focusing a result opens its preview on one of three private moves depending on window width. None carries the focused row into the preview, the external fade is linear (MOTION-19), and the sheet arrives over 750 ms. Severity 3: the preview opens on every focus move."
  fix: "Carry the focused row into the preview with `surfaceIn`, and switch previews between rows without motion."

- id: SEARCH-17
  rule: "Something succeeds"
  severity: 2
  region: "Command status above the results"
  evidence: "search_command_info.dart:43-57 (`Completed <label>` admonition with a 750 ms shimmer)"
  observed: "A finished command shows a green `Completed <label>` strip under the query bar, even when the result is visible."
  fix: "Say nothing when the result shows; otherwise type the result word at the row's control (`Copied`)."

- id: SEARCH-18
  rule: "A control is busy or unavailable"
  severity: 2
  region: "Unavailable creation result"
  evidence: "story authoredresourcesearchresult/creation-result/Unavailable=true,Focused=false.png against Unavailable=false,Focused=false.png"
  observed: "An unavailable creation result looks like an available one; only its subtitle `The Realm is read only` differs. It does not look pressed in."
  fix: "Show unavailable rows pressed in, and keep the reason as the subtitle."

- id: SEARCH-19
  rule: "A surface is new or changed"
  severity: 2
  region: "Search modal story"
  evidence: "search_modal.stories.dart:16-28 (renders `SearchModal` in `SizedBox.expand`, not through `showSearchModal`); images under searchmodal/default/"
  observed: "The story never shows the real overlay: no scrim, no 880 px cap (rows run the full 1400 px width), no route motion. No image shows a focused or selected row in the overlay, hover, Normal mode after Esc, a preview open, sections collapsed, the query suggestion popup or a selector chip, a validation issue, a running, completed, or failed command, compact width with the preview sheet, or offline."
  fix: "Render the story through `showSearchModal` over a page, and add knobs for focus, selection, preview, command state, and compact width."

## Cannot verify

- "Keys change meaning": inside the overlay the only mode text is the `Normal Mode [Esc]` hint (story initial.png). The probe found no `Insert` chip text while the query was focused, but the Services story may not host the app bar chip. Opening the overlay on a route whose app bar shows `ModeDisplayWidget` would settle it.
- "Choosing any key": Ctrl or Cmd+1 to 9 switch browser tabs. Chromium does not list them as reserved, so a page can likely intercept them, but no browser run confirmed it.
- "Writing text": the 10 px uppercase kind labels at 0.7 alpha (search_result_visuals.dart:182, :219) and the grey tag chips in authoring rows (resource-result/initial.png). Theme colours are generated in `color_scheme.dart` from families, so I could not compute exact values.
- "The window is under 900 px, or a pane would be narrower than 320 px": below 880 px the preview becomes a sheet (search_frame.dart:234-246), but no compact image shows the query and results.
- "Any move runs": implicit animations retarget; the route transition and row inserts are one shot. A test pressing keys mid open would settle it.
- "Choosing how strong a move is": feel, for a maintainer, once tokens exist.
- Rive assets (mascot on empty and error) do not render in story images.

## Rule results

<details>
<summary>Every checked rule</summary>

| When | Result |
|---|---|
| A user's action finishes and they have not moved on | pass (probe: closing returns focus to the opener node) |
| The focused thing disappears | cannot_verify (no probe removed a focused result) |
| A page or surface opens | pass (probe: query field focused on open; typing is the purpose) |
| Something happens that the user did not just do | pass (results only change from the user's query) |
| A task concerns something on screen | pass |
| A choice comes from a list that can grow or be searched | pass (this is the search overlay) |
| A task needs more room than its place has | fail (SEARCH-4) |
| Other work cannot continue until a question is answered | pass (no dialog) |
| The window is under 900 px, or a pane would be narrower than 320 px | cannot_verify |
| Anything needs saying | fail (SEARCH-2) |
| Something succeeds | fail (SEARCH-17) |
| Something fails | fail (SEARCH-1, SEARCH-2, SHARED-SEARCH-1) |
| Several things fail at once | fail (each failed source gets its own red notice, all equally loud; Source-state=error,Has-data=true images) folded into SEARCH-1 |
| A change appears elsewhere on screen | pass (none) |
| Something is empty | fail (SEARCH-10) |
| The connection or a service is lost | fail (SEARCH-1) |
| A wait is too short to notice, under 300 ms | fail (SEARCH-9) |
| The layout is known and its content is not | fail (SEARCH-8) |
| Content is on screen and refreshing | fail (SEARCH-7) |
| Loaded content arrives | fail (SEARCH-6) |
| A wait continues past 5 s | fail (the skeleton never changes its words; part of SEARCH-8) |
| An action can be undone | pass (no remove action in search itself) |
| The user causes something to arrive | fail (SEARCH-4) |
| Something exists before and after a change | fail (SEARCH-16) |
| Showing any state on something | fail (spinner added for a busy command, MOTION-8; selection border, SEARCH-3) |
| Anything changes state | fail (section chevron rotates on a 750 ms elastic, search_tree_section_header.dart:37-40; MOTION-1) |
| Anything grows or responds over time | fail (MOTION-6, MOTION-19) |
| Text appears | fail (status strips appear whole on an elastic; no typing) |
| A key is in use | fail (MOTION-7) |
| A control is busy or unavailable | fail (MOTION-8, SEARCH-18) |
| Anything leaves | fail (SEARCH-5, SEARCH-6) |
| The pointer reaches something you can act on | fail (MOTION-3; rows use InkWell hover colour, search_result_card.dart:68) |
| A button has a key | fail (SEARCH-13); rows pass |
| Focus moves | fail (MOTION-4; the focused row refills in 180 ms and scrolls 300 ms on easeOutCubic, search_tree_results.dart:339-345) |
| Several moves would play together | fail (the command status strip, the row pulse, and the row shake play together) |
| You cannot name what a move tells the user | fail (MOTION-18) |
| Reduced motion is on | fail (MOTION-2; only the row list checks it) |
| Adding an action | pass (result commands are ActionShortcuts in the hints and context menu) |
| Something works with one input | pass (commands by context menu, long press, and keys) |
| Keys change meaning | cannot_verify |
| An action means something the key language already covers | pass (Enter opens, Space selects, Esc steps out) |
| Choosing a key for a new meaning | fail (SEARCH-11) |
| Choosing any key | cannot_verify |
| Moving around | fail (SEARCH-12) |
| Showing a state | fail (SEARCH-3) |
| Setting any visual value | fail (SEARCH-15) |
| Choosing an action's weight | pass (no filled button) |
| Placing content | fail (SEARCH-14) |
| Writing text | cannot_verify |
| Choosing a font | pass (labels in Lilex) |
| Adding colour to a page | fail (focused row is a full colour fill, SEARCH-3) |
| Misreading would cost the user something | fail (SEARCH-1) |
| Naming an action | fail (SHARED-SEARCH-2) |
| A shared component does the job | fail (two result row components, `SearchResultCard` and `SearchResultRow`, with different state signals; SEARCH-3) |
| A surface is new or changed | fail (SEARCH-19) |
| Any action: reach and run with keys only (walk) | pass (probe: Esc, J, K, Space, Enter, Ctrl+K) |
| Any action that opens something: cancel it (walk) | pass (probe: second Esc closes, focus on the opener) |
| A failing action (walk) | fail (SEARCH-2) |
| Compact width (walk) | cannot_verify |

</details>

## Skill friction

- The brief asked for shared faults in a `## Shared` section here, while the skill says `cross-page.md`. I followed the brief.
- The inventory names only the `searchmodal/default` story, but that story renders the modal body, not the overlay route. The route motion, scrim, and width cap could only be checked from source, and the Escape and focus return path needed a route story (Services) plus Ctrl+K. The skill could name a story that opens Search through `showSearchModal`.
- No Motion row names the token for an overlay opened by a key with no on screen opener (Ctrl+K). I asked for `surfaceIn` from the active pane by analogy.
- "Several things fail at once" and "Something fails" overlap for partial source failures; I folded the partial case into SEARCH-1.
- The Values table has no rule for the radius or outline of a floating overlay that is neither a pane nor a dialog.

## Suggestions

- Purpose in two seconds: clear. The hint names what is searched.
- Where the eye lands: on the bright fill of the focused row or a red bordered notice, not on the query. SEARCH-3 and SHARED-SEARCH-1 fix this.
- What can be removed: the command status strip under the query (SEARCH-2, SEARCH-17), and the progress bar over the query (SEARCH-8).
- Feels like this machine: rows carry a colour tile per kind in authoring results, which is good; the mock rows in the modal story do not, so the story looks like a plain list.
- Expert speed: Down arrow in the query does nothing; the user must press Esc, then J. Proposal: Down or Ctrl+J from the query moves to the first result while the query keeps its text. Rule gap, new row for Keyboard: When a field filters a list below it, Then Down from the field moves into the list and Up from the first row returns to the field. Sev 2.
- First time user: `Normal Mode [Esc]` at the bottom right reads as a mode name, not as what Esc does here.

## Shared

- id: SHARED-SEARCH-1
  rule: "Something fails"
  severity: 3
  region: "`Admonition` (shared component), error and warning notices"
  evidence: "admonition.dart:70 (`Border.all(color: color, width: 1)`); story Source-state=error,Has-data=true,Include-guidance=true.png"
  observed: "Every Admonition draws a 1 px border in its status colour, so an error notice carries a red border, which the rule forbids. Search, the command status, and any other page using Admonition show it."
  fix: "Drop the border; show status by a small colour mark and the message words."

- id: SHARED-SEARCH-2
  rule: "Naming an action"
  severity: 2
  region: "Esc hint in every text field (`escapeToNormalAction`)"
  evidence: "normal_mode.dart:101-113 (label `Normal Mode`); story initial.png bottom right"
  observed: "The Esc hint is labelled `Normal Mode`, a mode name in Title Case, not an action in sentence case. In Search the same Esc leaves the field, and the next Esc closes Search with no hint at all."
  fix: "Name what Esc does here in sentence case (`Leave field`, then `Close search`)."
