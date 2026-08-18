# Panel guidance

## Dart imports

For internal panel APIs, always prefer the main package barrel:

```dart
import "package:typewriter_panel/typewriter_panel.dart";
```

Do not replace the main barrel with individual `typewriter_panel` imports.
External package imports remain direct.

## Riverpod providers

Prefer annotated generated Riverpod providers over manual provider declarations. Use manual declarations only when Riverpod generation cannot express the required behavior.

## Keyboard accessibility

Every UI component and interaction must be fully usable with a keyboard alone. Users must never need a mouse to operate the web panel.

When designing or changing UI, define how users can focus, navigate, activate, edit, confirm, cancel, and leave the interaction using only the keyboard. Preserve visible focus indicators and use established panel shortcut and focus patterns where available.

When adding keyboard shortcuts, prefer invoking an existing Intent instead of handling the key binding directly. Reuse the Intent that represents the action whenever one already exists, so every shortcut follows the same action path and enablement rules. Introduce custom shortcut handling only when no suitable Intent exists.

## Immutable models

Prefer Freezed for immutable Dart models instead of manually implementing immutable classes. This includes union and sealed model shapes, which should use Freezed unions instead of manually implemented class hierarchies. Use an ordinary class when the object is intentionally mutable or Freezed cannot express the required behavior cleanly.

## Widgetbook stories

Every new UI component must include an accompanying Widgetbook story in the same change so the component can always be inspected visually.

Represent clear, distinct variants in Widgetbook. Prefer knobs within one use case when they can expose the variants clearly. Add separate use cases when variants need meaningfully different scenarios, state, layout, or supporting data.

## Browser validation

After making UI changes, run the relevant panel or Widgetbook surface in Chrome on any available local port. Use the browser to inspect the rendered result and exercise the changed interaction directly. Confirm that the appearance, layout, states, keyboard behavior, and primary interaction flow work as intended. Fix any issues found before considering the change complete.
