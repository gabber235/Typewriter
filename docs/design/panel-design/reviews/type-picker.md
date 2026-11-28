# Type picker review

Overlay in the editor, opened when creating a page whose kind has several concrete types.
Story `authoring/presentation/authoredresourceeditor/creation-type-picker` (`initial`, `dark`);
supporting row story `authoring/search/presentation/authoredresourcesearchresult/creation-result/*`.
Source: `panel/lib/authoring/presentation/authored_type_picker.dart`,
`panel/lib/shared/editors/presentation/type_search.dart`,
`panel/lib/authoring/application/resource_creation_questions.dart`, and the shared search components
it renders through (`search_modal.dart`, `search_body.dart`, `search_tree_results.dart`,
`search_tree_animated_body.dart`, `search_result_card.dart`, `search_result_visuals.dart`,
`search_shortcuts.dart`, `panel/lib/shared/ui/components/shortcut_display.dart`).
Key paths were checked with a throwaway widget probe built on `pumpStory`, once on the story and
once on a probe story with a focused opener button calling `showCreationConcreteTypePicker`, with
and without `onBack` (deleted after the run). "probe" in evidence refers to it.

Generic search modal faults (centred entrance, filter motion, compact layout, empty and error
states) belong to `search.md`. This report covers what changes when the search is used to pick a
type, and the shared row and key cap faults it exposed.

## Summary

Usable but generic. The keyboard path works: the field is focused on open, Enter, Ctrl+digit,
J and K, and a click all choose, two Esc presses close it, and focus returns to the opener.
It fails where picking a type differs from searching: four fixed types open as a full centred
search overlay away from the create control, Enter chooses an unhighlighted first row, and in a
multi question creation Esc throws away the earlier answers while the only way back is a pointer
button with no key.

The single most valuable change: open the picker as a popover at the create control, with the
first type focused, so the choice is visible, close to where it was asked, and Esc steps back one
question.

## Findings

- id: TYPE-1
  rule: "A choice comes from a short fixed list"
  severity: 2
  region: "Whole overlay; four page types in a centred search frame"
  evidence: "authored_type_picker.dart:135-162; story creation-type-picker/initial.png; probe: focus on open is the 'Search QueryBar' text field, Enter and Down then Enter both return Manifest"
  observed: "Four fixed page types (Manifest, Scene, Sequence, Static) open in the full search overlay at the centre, with a text field focused and about 60% of the frame empty. No row is highlighted, yet Enter creates the first type, so the user cannot see what Enter will make."
  fix: "Open a popover at the create control with the first type focused. Keep the search overlay only when the catalog offers more types than fit a popover."

- id: TYPE-2
  rule: "The user causes something to arrive"
  severity: 3
  region: "Picker entrance and exit"
  evidence: "search_modal.dart:203-237 (500 ms ElasticOutCurve(0.8), scale from 0.96 at Center, reverse easeInCubic); story creation-type-picker/initial.png shows it centred over the scrim"
  observed: "The picker is caused by a create control but strikes in at the centre of the window over a dimmed page and leaves to the centre. Nothing ties it to the control that asked. Severity 3: opening a surface is an everyday action."
  fix: "Grow the picker from the create control with surfaceIn and return it there on close."

- id: TYPE-3
  rule: "Moving around"
  severity: 2
  region: "Creation with several questions (type, then references)"
  evidence: "resource_creation_questions.dart:44-63; search_modal.dart:136-156; probe with onBack: Esc, Backspace, Esc closed the picker with result null and onBack never called"
  observed: "Esc in a later question cancels the whole creation and drops the earlier answers. Stepping back one question needs the BackButton."
  fix: "Make Esc in a question with a previous question step back to it; Esc on the first question cancels."

- id: TYPE-4
  rule: "Adding an action"
  severity: 3
  region: "Back button left of the query field, multi question creation"
  evidence: "search_modal.dart:144-153 (plain Material BackButton calling pop then onBack); probe: one BackButton, Backspace and Esc never call onBack"
  observed: "Previous question is a pointer button with no Intent, no key, no key cap, and no command list entry."
  fix: "Make Previous question one command through an Intent, bound to Esc as in TYPE-3, with its key cap on the button."

- id: TYPE-5
  rule: "A surface is new or changed"
  severity: 2
  region: "Story creation-type-picker"
  evidence: "authored_type_picker.stories.dart:9-38; images initial.png and dark.png only"
  observed: "No image shows a filtered query, no matching type, a focused type row, hover, the previous question button, a single candidate skipping the picker, many types, or compact width. The creation-result row story renders a different row widget (AuthoredResourceSearchResult), not `_TypeSearchResultItem`."
  fix: "Add knobs for query, focused row, previous question, catalog size, and window size."

- id: TYPE-6
  rule: "A shared component does the job"
  severity: 2
  region: "Type composition step (generic type arguments and Allow no value)"
  evidence: "authored_type_picker.dart:54-65, 199-248, 258-264"
  observed: "After a generic type is picked, a separate AlertDialog asks for its arguments, with a literal width of 480, a Material SwitchListTile, and a FilledButton Choose in the dialog footer. A rejected argument shows through ScaffoldMessenger. AlertDialog and ScaffoldMessenger are both under Never."
  fix: "Grow the chosen row into a surface for the arguments, say a rejection under the argument it concerns, and use the shared dialog only if the question truly blocks other work."

## Cannot verify

- "Choosing how strong a move is" and "Any move runs": feel and mid move retargeting of the route transition; a maintainer judging it live, or a test sending keys during the 500 ms entrance, would settle it.
- Type icons: every icon tile renders as an empty coloured square in both images, while Material icons in the query field render. Whether `ResourceIcon` shows the type icon in the real panel cannot be told from the images.
- "Writing text" on tinted and focused rows: theme values for `onSurfaceVariant` on a 6% kind tint, and `color.on(context)` on a fully filled kind colour, were not computed. Visually all pass.
- "Anything needs saying" for a rejected type argument (TYPE-6): the snackbar is away from the argument, but no story reaches the rejection; a catalog fixture with a constrained generic type would settle the placement and the severity.
- "Only touch is available": no touch story.

## Rule results

<details>
<summary>Every checked rule</summary>

| When | Result |
|---|---|
| A user's action finishes and they have not moved on | pass (probe: focus returns to the opener after choosing; landing on the new page's field is RESOURCE-2) |
| The focused thing disappears | pass (rows filter out; focus stays in the field) |
| A page or surface opens | pass (probe: query field focused; typing filters) |
| Something happens that the user did not just do | pass (static catalog) |
| A task concerns something on screen | fail (TYPE-1) |
| A choice comes from a short fixed list | fail (TYPE-1) |
| A choice comes from a list that can grow or be searched | pass when the catalog is large |
| A task needs more room than its place has | fail (TYPE-2, TYPE-6) |
| Other work cannot continue until a question is answered | fail (TYPE-6) |
| The window is under 900 px, or a pane would be narrower than 320 px | cannot_verify (no compact story; TYPE-5) |
| Anything needs saying | cannot_verify (TYPE-6) |
| Something succeeds | pass (picker closes, creation continues) |
| Something fails | not applicable to the type list; composition rejection under TYPE-6 |
| Something is empty | cannot_verify (no story; generic empty in search.md) |
| A wait is too short to notice, under 300 ms | pass (synchronous source) |
| Loaded content arrives | fail (MOTION-17 ElasticTransition rows, search_tree_animated_body.dart:93-104) |
| An action cannot be undone, or undo is not built yet | not applicable |
| The user causes something to arrive | fail (TYPE-2) |
| Something exists before and after a change | cannot_verify (chosen type is not carried into the new page; RESOURCE-22 and MOTION-34 cover the page swap) |
| Showing any state on something | fail (SEARCH-3) |
| Anything changes state | fail (focus and selection swap colour in 180 ms literal, search_result_card.dart:45-47; MOTION-1) |
| Anything grows or responds over time | fail (MOTION-6, InkWell splash) |
| Text appears | pass |
| A key is in use | fail (SHARED-TYPE-2) |
| A control is busy or unavailable | not applicable (activation always enabled, type_search.dart:59-64) |
| Anything leaves | fail (TYPE-2, SEARCH-5) |
| The pointer reaches something you can act on | fail (MOTION-3, InkWell hoverColor, search_result_card.dart:68-75) |
| A button has a key | pass for type rows (Ctrl+digit caps); fail for the back button (TYPE-4) |
| Focus moves | fail (MOTION-4; scroll follows on a literal 300 ms easeOutCubic, search_tree_results.dart:334-345) |
| Several moves would play together | pass |
| You cannot name what a move tells the user | pass |
| Reduced motion is on | fail (MOTION-2; route transition ignores it, search_modal.dart:203-237) |
| Adding an action | fail (TYPE-4) |
| Something works with one input | pass for choosing (keys, click); fail for Previous question (TYPE-4) |
| Keys change meaning | pass (Esc hint shows Normal mode; title case is SERVICES-16) |
| An action means something the key language already covers | pass (Enter activates) |
| Choosing a key for a new meaning | fail (SEARCH-11) |
| Moving around | fail (TYPE-3, SHARED-TYPE-5) |
| Setting any visual value | fail (MOTION-1; literal 64, 6, 10, 140, 480 in search_result_card.dart:95-128 and authored_type_picker.dart:202) |
| Showing a state | fail (SEARCH-3) |
| Placing content | pass (field and rows share a left edge) |
| Adding colour to a page | pass (one colour tile per type) |
| Styling a static page | fail (SHARED-TYPE-6) |
| Writing text | cannot_verify |
| Choosing a font | fail (RESOURCE-20 for descriptions in Lilex; SHARED-TYPE-6 for key cap weight) |
| Naming an action | pass for this surface ("Normal Mode" is SERVICES-16) |
| A shared component does the job | fail (TYPE-6) |
| A surface is new or changed | fail (TYPE-5) |
| Keyboard behaviour is new or changed | cannot_verify (no committed test of the picker's key path was found; probe passed) |
| Walk: Any action, keys only | pass (probe: Enter, Ctrl+2, Esc then J J Enter all choose) |
| Walk: Any action that opens something, cancel | pass (probe: Esc leaves the field, second Esc closes, focus on the opener) |
| Walk: Compact width | cannot_verify |

</details>

## Skill friction

- The inventory lists the type picker as its own surface, but nearly all of it is the shared search modal, which another review owns. The skill does not say where a surface built on a shared overlay should stop.
- The creation-result row story named in the brief renders a different widget than the picker's rows, so it is no evidence for this surface. The inventory could point at the row widget each surface uses.
- The Focus rule "a text field only when typing is its purpose" conflicts with the Surfaces rule that sends searchable lists to the search overlay, whose purpose is typing. For a short list in a search overlay it is unclear which wins; I reported it under the short list rule.
- The skill asks for shared faults in `cross-page.md`; this brief asked for a `## Shared` section instead.
- Step 8 asks for a second check on severity 3 findings; for motion found in source, a probe cannot observe a route transition's origin, so the image showing the centred overlay served as the second way.

## Suggestions

- What it is for in two seconds: the hint "Search resource types" never says what is being created. Ask "Which kind of page?" and name the parent when known.
- What can be removed: the "TYPE" label on every row says nothing, since every row is a type. Drop it and let the key cap stand alone.
- Expert speed: Down in the query field does nothing (SHARED-TYPE-5), so picking the second type takes Ctrl+2 or Esc then J J. Arrows from the field should move through rows.
- Feels like this machine: the empty space under four rows reads as a missing list. Size the frame to its content.
- Rule gap, new row for Surfaces: When a question follows another in one task, Then Esc returns to the previous question with its answer kept, and only Esc on the first question cancels. Sev 3.
- Rule gap, new row for Keyboard: When Enter would act on something, Then that thing shows focus first; Enter never acts on an unhighlighted default. Sev 3.

## Shared

Search result focus and selection (SEARCH-3), the overlay exit (SEARCH-5), and Ctrl+digit keys (SEARCH-11) belong to the shared search components and are reported in `search.md`.

- id: SHARED-TYPE-2
  rule: "A key is in use"
  severity: 3
  region: "ShortcutDisplay key caps, including Ctrl+digit caps on result rows"
  evidence: "shortcut_display.dart:166-270 (stateless; no key listener); probe: cap decoration identical idle and with Ctrl held 300 ms"
  observed: "Key caps never glow while their key is pressed, even where they are on screen. Severity 3: a key press is an everyday press. MOTION-7 covers pages with no caps at all."
  fix: "Have ShortcutDisplay listen to HardwareKeyboard and glow while its keys are down."

- id: SHARED-TYPE-5
  rule: "Moving around"
  severity: 2
  region: "Search query field"
  evidence: "probe: Down, Down, Enter from the field chose Manifest; focus stayed in the field"
  observed: "Arrow keys in the query field do not move through results. Reaching a row needs Tab or Esc then J or K."
  fix: "Let Up and Down in the query field move the active result."

- id: SHARED-TYPE-6
  rule: "Styling a static page"
  severity: 2
  region: "Result icon tile and key caps"
  evidence: "search_result_visuals.dart:42-48 (BoxShadow blur 16 under the icon tile); shortcut_display.dart:228-252 (weight 700, hard 2 to 3 px drop shadow)"
  observed: "Icon tiles carry a coloured drop shadow and key caps are physical keys with a hard shadow at weight 700. Shadows are for menus, toasts, and dialogs only, and labels use weight 500 or 600."
  fix: "Remove both shadows and set key caps to weight 600."
