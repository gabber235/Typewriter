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

Wrap panel components with `FakeApp` unless the story uses a more specific existing application harness.

Build stories from realistic domain values and public component interfaces. Reuse focused scenario support when multiple variants represent the same component contract.

Add knobs for design relevant configuration such as width, read only state, enabled state, and content length. Keep knob labels unique within each use case.

## Generated files and verification

Do not edit `lib/main.directories.g.dart` manually. Regenerate it with `dart run build_runner build` after adding, removing, renaming, or moving annotated stories.

Format changed Dart files. Run Widgetbook analysis and tests. Add behavioral tests for interactive stories and completeness tests for catalogs that represent an exhaustive protocol hierarchy.
