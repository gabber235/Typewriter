# Widgetbook guidance

## Story placement

Mirror the source ownership below `panel/lib` inside `panel/widgetbook/lib/stories`.

For example, a component from `panel/lib/shared/editors/presentation` belongs in `panel/widgetbook/lib/stories/shared/editors/presentation`. A component owned by a feature belongs beneath the matching feature path.

Do not place shared component stories beneath a feature merely because that feature currently consumes the component. When a component moves to a different owner, move its stories in the same change.

Use a component directory when one component needs several story files or shared scenario support. Name annotated files with the `.stories.dart` suffix. Keep unannotated scenario builders and support files beside the stories that use them.

## Widgetbook navigation

Prefer navigation derived from correct source and story ownership. Use a custom `UseCase.path` only when a deliberate category improves navigation. A custom path must not suggest different ownership from the physical story location.

Group variants by the component they demonstrate. Do not use feature terminology for shared protocol or design system components.

## Story construction

Every story returns a `Story` (`lib/support/story.dart`): the real panel over a test kit world, the
same `PanelStage` widget tests pump. Screens open at their real route
(`at: PanelLocation.route(...)`); components that no route shows alone use
`PanelLocation.component(...)`. Never build a separate app, scaffold or provider override list.

State is chosen with the test kit's traits, never with provider overrides: `signedIn`, `realm`,
`membership`, `offline`, `compact`, `dark` and the rest. A knob that changes state is a trait knob,
`context.knobs.traits("Join codes", {"None": [...], "Few": [...]})`, so every edge case a widget
test can set up is a knob. Story data is seeded: build it with the test kit's `Generator` from the
`context.knobs.seed()` knob, so it looks the same on every reload. Stateful doubles keep stories
clickable: saving, creating and failing go through them.

Show states a user meets (loading, empty, failing, offline, compact), not helper demos, debug text
or instructions inside the preview. One story per component; variants are knobs unless they need a
different world. Keep knob labels unique within each use case.

`test/every_story_test.dart` renders every story in every combination of its choice knobs and
fails when one throws or overflows; it writes each variant as an image below
`.xtask/results/stories/` for the pull request evidence. Behaviour tests of a story pump it with
`pumpStory` from `test/support/stories.dart` and act through the test kit's drivers.

## Generated files and verification

`lib/main.directories.g.dart` is generated and ignored by Git. `cargo xtask generate` (and every `cargo xtask check`) regenerates it after annotated stories are added, removed, renamed, or moved.

Format changed Dart files. Run Widgetbook analysis and tests. Add behavioral tests for interactive stories and completeness tests for catalogs that represent an exhaustive protocol hierarchy.
