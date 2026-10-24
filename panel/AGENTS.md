# Panel guidance

## Dart imports

For panel APIs and external runtime dependencies, use the main package barrel:

```dart
import "package:typewriter_panel/typewriter_panel.dart";
```

Import Skir declarations and runtime APIs through their separate named library:

```dart
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart" as skir;
```

Keep dependency exports and collision names in `lib/dependencies.dart`. Keep
generated protocol exports in the Skir library. These library boundaries own
the direct dependency imports. Generated files retain their generator imports.
Testing and Widgetbook tools stay in their own packages and may be imported
directly. Do not add individual panel imports or named runtime imports to
consumer files.

## Module boundaries

The panel's modules and their allowed dependencies are declared in
`test/architecture/module_graph.dart`. A module may use the modules below it, never above it
or beside it. When code needs something from above, move the concept down to its true owner
or let the upper module pass it in (a parameter, an inherited widget, or a provider override
in the composition root). `module_graph_test.dart` names every violating file, line and symbol.

## Riverpod providers

Prefer annotated generated Riverpod providers over manual provider declarations. Use manual declarations only when Riverpod generation cannot express the required behavior.

## Widgets

Prefer `HookConsumerWidget` or `HookWidget` over `StatefulWidget` and `ConsumerStatefulWidget`. Keep local state, controllers, and lifecycles in hooks.

Never write `build` with an expression body (`=>`). Always use a block body.

In `build`, use `ref.watch`. Use `ref.read` only inside callbacks such as `onPressed`.

## Extension methods

Prefer extension methods and getters over top level functions when behavior has a clear primary receiver. Use top level functions only for factories, entry points, and coordination with no natural receiver.

## Keyboard accessibility

Every UI component and interaction must be fully usable with a keyboard alone. Users must never need a mouse to operate the web panel.

When designing or changing UI, define how users can focus, navigate, activate, edit, confirm, cancel, and leave the interaction using only the keyboard. Preserve visible focus indicators and use established panel shortcut and focus patterns where available.

When adding keyboard shortcuts, prefer invoking an existing Intent instead of handling the key binding directly. Reuse the Intent that represents the action whenever one already exists, so every shortcut follows the same action path and enablement rules. Introduce custom shortcut handling only when no suitable Intent exists.

## Immutable models

Prefer Freezed for immutable Dart models instead of manually implementing immutable classes or using typedef. This includes union and sealed model shapes, which should use Freezed unions instead of manually implemented class hierarchies. Use an ordinary class when the object is intentionally mutable or Freezed cannot express the required behavior cleanly.

Never declare typedef record aliases. Use a Freezed value object.

Use `mapUnready` instead of `whenData` so previous values survive reload.

## Widgetbook stories

Every new UI component must include an accompanying Widgetbook story in the same change so the component can always be inspected visually.

Represent clear, distinct variants in Widgetbook. Prefer knobs within one use case when they can expose the variants clearly. Add separate use cases when variants need meaningfully different scenarios, state, layout, or supporting data.

### Panel Testing
Use `testApp()` and `pumpTestApp()` from `test/test_utils.dart`.
Widgetbook components: wrap with `FakeApp`.
