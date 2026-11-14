# Resource editor review

Route `realm/:realmId/resource/:resourceId`. Stories under
`.xtask/results/stories/features/realms/presentation/resourcesurface/routed-resource/`
(`initial`, `dark`, `Routed-resource=Book|Library|Tags|Removed-elsewhere`,
`Realm=Checking|Host-offline|Unavailable|Content-unreadable`, `Window=Compact`).
Source: `panel/lib/features/realms/presentation/resource_route.dart`,
`resource_navigator.dart`, `panel/lib/shared/ui/components/floating_button.dart`,
`panel/lib/shared/editors/presentation/portable_renderer/resources.dart` and `actions.dart`,
`panel/lib/features/realms/presentation/realm_suspension.dart`.
Key paths were checked with a throwaway widget probe built on `pumpStory` (deleted after the run);
"probe" in evidence below refers to it.

## Summary

Not good yet. The page shows the right things, but the keyboard path is broken: nothing has focus
when the page opens, the create key only works once focus is inside the main pane, Esc steps out of
nothing, and a new page lands with focus nowhere near its name. Visually the rail is dominated by
three bright filled "New page" buttons that overlap the chapter names, and the compact window keeps
three columns side by side.

The single most valuable change: give the page a real focus path. Focus the routed row on open, run
creation from the focused row or chapter, and land focus in the new page's name field.

## Findings

- id: RESOURCE-1
  rule: "A page or surface opens"
  severity: 3
  region: "Whole surface on open, Page and Book stories"
  evidence: "probe: after pumpStory for Page and Book, primaryFocus is the route's _ModalScopeState focus scope"
  observed: "Nothing is focused when the page opens; the first Tab goes to the rail header."
  fix: "Focus the routed row in the rail (or the first field when the resource has no rail) when the surface opens."

- id: RESOURCE-2
  rule: "A create action"
  severity: 3
  region: "New page: floating button, N key, and rail chapter buttons"
  evidence: "probe: Enter on a rail 'New page' routes to /resource/48fk... with focus on the route scope; N in the main pane routes to /resource/44vx... with focus left on the old pane's surrounding node"
  observed: "Creating a page opens it, but focus does not land on its name field."
  fix: "After creation, focus the new page's first empty required field (its name)."

- id: RESOURCE-3
  rule: "Any action"
  severity: 3
  region: "Create shortcut (N, A, numpad +), main pane"
  evidence: "resource_route.dart:106-126; probe: N pressed on open and with focus in the rail leaves the path unchanged"
  observed: "The create key is bound only inside the main pane. On open, and from the rail, N does nothing; the user must first Ctrl+L into the pane."
  fix: "Bind creation at the page level, and let N on a focused chapter in the rail create in that chapter."

- id: RESOURCE-4
  rule: "Adding an action"
  severity: 3
  region: "'New page' button on each chapter in the rail"
  evidence: "actions.dart:145-151 (button calls executeAction directly); services/sdk/typewriter-api/src/main/kotlin/com/typewritermc/library/BookSdkProvider.kt:121-125"
  observed: "The chapter create buttons are plain buttons with no Intent, no key and no command list entry."
  fix: "Route portable button actions through one command per action so key, button, menu and command list share it."

- id: RESOURCE-5
  rule: "Any action"
  severity: 3
  region: "Rail rows and main pane"
  evidence: "probe: Esc with focus on a rail chapter button, and Esc with focus in the main pane, both leave focus where it was"
  observed: "Esc does not step out one level anywhere on the page."
  fix: "Esc from a control returns focus to its pane; Esc from a pane returns to the shell."

- id: RESOURCE-6
  rule: "The window is too narrow for side by side"
  severity: 3
  region: "Whole page, compact window"
  evidence: "story routed-resource/Window=Compact.png; resource_route.dart:80 uses context.isMobile, which is width 0 to 450 (responsive.dart:17), while the compact window is 800 wide (testkit window.dart:6)"
  observed: "At compact width the shell sidebar, the rail and the content all stay side by side; the content pane is about 240 px and the breadcrumb is clipped at 'Library'."
  fix: "Collapse to one pane at a time at the compact breakpoint, in the order tree, content, inspector."

- id: RESOURCE-7
  rule: "Writing text"
  severity: 3
  region: "Heading description under the title, e.g. 'Every book of the realm'"
  evidence: "resource_route.dart:333-335 (contentDisabled); computed from buildTypewriterColors: 2.34:1 on canvas in light, 3.03:1 in dark; story Routed-resource=Library.png"
  observed: "The description uses the disabled colour and is well under 4.5:1 in both themes."
  fix: "Use contentSecondary for the description."

- id: RESOURCE-8
  rule: "The connection or a service is lost"
  severity: 3
  region: "Realm connection card over the page"
  evidence: "realm_suspension.dart:101 (blur sigma 3); stories Realm=Host-offline.png, Realm=Checking.png, Realm=Unavailable.png"
  observed: "The page is blurred and a card strikes in at the centre; content is not readable while the realm is offline or checking."
  fix: "Show one steady notice at page level (header or status bar) and keep content readable, read only."

- id: RESOURCE-9
  rule: "Something fails"
  severity: 3
  region: "Main area, Content unreadable"
  evidence: "resource_route.dart:247-249; story Realm=Content-unreadable.png"
  observed: "Shows 'Authoring is unavailable: Bad state: The Realm did not answer': a raw exception, no next step, no way to retry."
  fix: "Write what happened and the next step in plain words, with a retry control, e.g. 'The realm did not answer. Press Retry to try again.'"

- id: RESOURCE-10
  rule: "Something fails"
  severity: 3
  region: "Breadcrumb bar, Unavailable"
  evidence: "story Realm=Unavailable.png"
  observed: "'ProviderException: Tried to use a provider that is in error state.' is painted over the breadcrumb bar; a top bar widget fails to build when the realm topology fails."
  fix: "Handle the error state in the breadcrumb (show the last known name or nothing) instead of throwing during build."

- id: RESOURCE-11
  rule: "Showing a state"
  severity: 3
  region: "Rail header row (the Book) when the Book is routed"
  evidence: "resource_navigator.dart:111-113 (ListTile selected); component_themes.dart:128-136 (no selected fill); story Routed-resource=Book.png versus initial.png"
  observed: "A routed page row gets a fill, but the routed Book row in the rail header has none, so 'selected' looks different in one list."
  fix: "Render the header as the same row widget as members so selection is always the fill."

- id: RESOURCE-12
  rule: "Something fails"
  severity: 3
  region: "Floating 'New page' / 'New book' button"
  evidence: "floating_button.dart:37-45 catches only Exception; resource_creation_action.dart:24 throws StateError; floating_button.dart:41-45,54-58 (snackbar, red fill, tooltip). Source only, not run through a fake."
  observed: "A StateError from creation escapes the button with no message. Other failures show a raw e.toString() in a snackbar and a hover tooltip, and the button stays red."
  fix: "Catch every failure in the button, shake once, return to normal, and state the cause and next step at the button."

- id: RESOURCE-13
  rule: "Choosing an action's weight"
  severity: 2
  region: "Rail, a 'New page' button on every chapter"
  evidence: "story initial.png and dark.png (three filled buttons at act1, arrival, act2); actions.dart:145 defaults the variant to filled; BookSdkProvider.kt:121-125"
  observed: "Three brand filled buttons sit in one pane, always visible, and overlap the chapter names ('act1', 'arrival')."
  fix: "Make chapter creation a quiet row action that shows on hover and focus and in the context menu."

- id: RESOURCE-14
  rule: "Choosing an action's weight"
  severity: 2
  region: "Floating main action, bottom right"
  evidence: "resource_route.dart:142-152; stories Routed-resource=Book.png, Library.png, Tags.png"
  observed: "The main action floats over the body at the bottom right, far from the heading."
  fix: "Put the main action in the pane header, right side."

- id: RESOURCE-15
  rule: "A button has a key"
  severity: 2
  region: "Floating main action"
  evidence: "resource_route.dart:113-118 binds N, A and numpad +; floating_button.dart:67-77 shows no key cap; story Routed-resource=Book.png"
  observed: "The button has keys but shows no key cap."
  fix: "Show the N key cap on the button."

- id: RESOURCE-16
  rule: "An action means something the key language already covers"
  severity: 2
  region: "Create shortcut"
  evidence: "resource_route.dart:113-117"
  observed: "Create is bound to N, A and numpad +; only N is in the key language."
  fix: "Keep N only."

- id: RESOURCE-17
  rule: "A control is busy or unavailable"
  severity: 2
  region: "Floating main action while creating"
  evidence: "floating_button.dart:64-66,103-121 (CircularProgressIndicator spinner)"
  observed: "Busy swaps the icon for a spinner instead of pressing the button in and rippling a busy word."
  fix: "Use LoadingButton behaviour: pressed in, label types 'Creating', letters ripple."

- id: RESOURCE-18
  rule: "Nothing about the page is known yet"
  severity: 2
  region: "Main area while the authoring document loads"
  evidence: "resource_route.dart:250-252"
  observed: "A centred CircularProgressIndicator instead of a doorway screen."
  fix: "Show the doorway screen."

- id: RESOURCE-19
  rule: "Placing content"
  severity: 2
  region: "Heading versus content; rail rows"
  evidence: "resource_route.dart:301-305 (heading padding space4 plus 32 px icon and space3 gap) versus :93 (content padding space2); initial.png: title 'Arrival' at x 570, field label at x 518; Library.png: title at x 290, cards at x 254; rail rows about 28 px high (initial.png, 'Arrival' row)"
  observed: "Title and content start on different left edges, and rail rows are about 28 px instead of about 42 px."
  fix: "Share one left edge between heading and body and use the standard row height in the rail."

- id: RESOURCE-20
  rule: "Choosing a font"
  severity: 2
  region: "Full sentences: suspension card text, error line, removed resource title"
  evidence: "typography.dart:26-28 (body roles are Lilex); stories Realm=Checking.png, Realm=Host-offline.png, Realm=Content-unreadable.png"
  observed: "Full sentences render in Lilex; IBM Plex Sans is not used."
  fix: "Use IBM Plex Sans for sentence text roles."

- id: RESOURCE-21
  rule: "Setting any visual value"
  severity: 2
  region: "Focus ring everywhere on the page; rail width; heading icon"
  evidence: "color_scheme.dart:92 (focusRing is neutral outline: #74777F light, #8E9199 dark); resource_route.dart:166 (width 280), :314 (size 32)"
  observed: "The focus ring is grey, not the brand ring value, and the page writes literal sizes."
  fix: "Set the focus ring to #006FB8 on light and #009FFF on dark; move 280 and 32 into tokens."

- id: RESOURCE-22
  rule: "Something exists before and after a change"
  severity: 2
  region: "Opening a row in the rail; moving between resources"
  evidence: "resource_route.dart:82 (body keyed by resource, so it is replaced); rg finds no use of loadIn, rowIn, surfaceIn, paneFocus, focusMove or hoverIn anywhere in panel/lib"
  observed: "Opening a rail row replaces the heading and body; no motion token exists to carry the row into the heading or ripple rows in."
  fix: "Add the motion tokens and move the opened row into the heading; ripple the body in with loadIn."

- id: RESOURCE-23
  rule: "Something is empty"
  severity: 2
  region: "Main area, Removed elsewhere"
  evidence: "resource_route.dart:253; story Routed-resource=Removed-elsewhere.png"
  observed: "Only 'This resource is no longer available'; no subtitle on what happened or where to go, no way back to the owner."
  fix: "Add a serious subtitle and an action back to the owning resource."

- id: RESOURCE-24
  rule: "A surface is new or changed"
  severity: 2
  region: "Story coverage"
  evidence: "widgetbook/lib/stories/features/realms/presentation/resource_route.stories.dart:10-29 and realm_story.dart:27-44"
  observed: "No story for: document loading, empty book or chapter, read only, creating (busy), creation failed, hover, focus, a heading with several creations, compact with the rail sheet open."
  fix: "Add those states as knobs on the routed resource story."

- id: RESOURCE-25
  rule: "A shared component does the job"
  severity: 2
  region: "Resource heading title"
  evidence: "resource_route.dart:321-327"
  observed: "The heading is a local Text with headlineSmall instead of PageHeading."
  fix: "Use PageHeading."

- id: RESOURCE-26
  rule: "Styling a static page"
  severity: 2
  region: "Floating main action"
  evidence: "stories Routed-resource=Book.png, Library.png, Tags.png; probe shows no focus on open, so it is not the focus ring"
  observed: "The button carries a thick dark outline, a hard border on an otherwise soft page. Cause not traced."
  fix: "Remove the outline; let fill and depth carry the button."

## Cannot verify

- "Choosing how strong a move is", "Anything changes state", "The pointer reaches something you can act on", "A key is in use", "A pane gains focus", "Reduced motion is on": no motion tokens exist to inspect, and images never prove motion. A maintainer judging the live page would settle it.
- "Something works with one input" for the rail drag: `ResourceDragSource` exists (authored_resource_items.dart:482-496) and its doc says keyboard moves edit the grouped field, but I did not run Move mode. A widget test entering Shift+M on a rail row would settle it.
- "An action can be undone" and "A remove action on books, pages, or entries": no remove action is visible and I did not press D on a rail row. A probe pressing D on a focused page row would settle it.
- "Only touch is available": no touch story.
- "A wait is too short to notice": the Checking card shows a progress bar (Realm=Checking.png); whether it is delayed by 300 ms needs the source of realm_suspension timing and a timed test.
- Resource icons in the heading and rail header, and the mascot on the removed resource screen, do not render in any story image; whether they show in the real panel cannot be told from the images.
- Command list contents: no probe opened Ctrl+K; RESOURCE-4 rests on source.

## Suggestions

- Purpose in two seconds (Page story): the body shows one field, "name". The page's real content is not on this surface, so it reads like a settings form. Show what the page holds, or say what belongs here when it holds nothing.
- Where the eye lands: on the three bright "New page" buttons in the rail, not on the page being edited. RESOURCE-13 fixes this.
- What can be removed: the per chapter buttons (into row actions), and the separate rail header ListTile (make it a row like the others).
- Feels like this machine: Library cards are plain grey boxes with a centred title (Routed-resource=Library.png), though every Book has a colour and an icon. Use the Book's colour tile and icon on its card.
- Expert speed: creating a page in a chapter takes Tab presses to reach a small button. N on a focused chapter or page row should create in that chapter.
- First time user: field labels are raw keys in lowercase ("name", "title"), and chapters show raw paths ("act1", "arrival"). Show display names in sentence case.
- Rule gap, new row for Text: When a label comes from a data key, Then show its display name in sentence case, never the raw key. Sev 2.
- Rule gap, new row for Feedback: When the routed thing no longer exists, Then say so, say why if known, and offer the way back to its owner with focus on it. Sev 3.

## Skill friction

- The Values table (focus ring colour, radii, shadows) has no When or Sev, so a wrong focus ring colour has no row to quote. I filed it under "Setting any visual value".
- Theme wide problems (Lilex for sentences, grey focus ring, no motion tokens, the realm suspension overlay) show on every page. The skill does not say whether to report them on each page or only in `cross-page.md`. I reported each once here.
- Step 5 says to record pass, fail, or cannot_verify for every rule, but the Output format has no section for passes, so passes are lost. I kept to the format.
- The action walk row "Any action: Cancel it" does not say what cancelling means for an action that completes at once and navigates (create). I read it as "Esc steps out of where the action left focus".
- Step 8 asks to repeat a severity 3 check "from fresh evidence" without saying what counts as fresh (rerun the same probe, or a different method). I reran key probes with different paths and reread source for source-only findings.
- The evidence table says to use `pumpPanel`; route stories are driven with `pumpStory` in `widgetbook/test/support/stories.dart`. The skill should name the helper for route stories. It also gives no way to cite a throwaway test that must be deleted.
- Story images do not render resource icons or the Rive mascot. The skill does not say whether an asset missing from an image is a finding or `cannot_verify`.
- The inventory lists Graph separately, but the Tags routed resource of this route is a graph. I treated graph internals as out of scope for this page.
- The action walk asks whether the command list shows each action, but gives no recipe to read the command list in a test.
- Severity for blurred content and overlays is split across two rules ("The connection or a service is lost" at 3 and "A task needs more room" at 2, which also forbids striking in at the centre). It is unclear which rule owns a centred overlay that is not a task.
