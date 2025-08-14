# TypeWriter Panel — Recipe: Add an Inspector Editor (and Custom Modifiers)

Intent
Add a new field editor used by the Inspector to edit values described by `DataBlueprint` or extend the system with a custom modifier or a custom editor for a `CustomBlueprint`.

When to use
- A new data shape (or constraint) requires a distinct editing UX.
- You want richer interactions than existing primitive/list/object editors provide.
- You introduce a `CustomBlueprint` (custom editor id) or a new `Modifier` that changes behavior.

---

## Architecture Primer (How Editors Plug In)

- Data model: `DataBlueprint` (and variants: primitive, enum, list, map, object, algebraic, custom).
- Modifiers: Union cases on `Modifier` (e.g. `min`, `max`, `multiline`) that augment editor behavior.
- Dispatch: `FieldEditor` picks the first `Editor` whose `canEdit` returns true from the ordered list in the `editors` provider (`editors.dart`). Order matters (more specific editors must precede generic ones).
- Editor contract:
  - `bool canEdit(DataBlueprint dataBlueprint)`
  - `Widget build(String path, DataBlueprint dataBlueprint, EditorMode mode)`
  - Optional: Override `headerActions` if the editor needs nested children or custom header widgets (see `BooleanEditor`, `ObjectEditor`, `ListEditor` patterns).
- Value states handled centrally by `FieldValueEditor`:
  - `Value` → passes through the concrete value.
  - `ConflictValue` → conflict UI.
  - `NoneValue` → "missing" UI with reset action.
  - `LoadingValue` → shimmer placeholder.
- Header actions: Implement a `HeaderAction` subclass and rely on a provider (e.g. `headerActionsProvider`) to aggregate them. Your editor’s `headerActions` override can append nested blueprint paths (list items, object fields) to the traversal.

---

## Checklist: Add a New Editor

1. Plan
   - Determine which `DataBlueprint` kinds and/or modifiers it should handle.
   - Decide if it replaces an existing one (needs to appear earlier in the `editors` provider list).
   - Decide whether it uses inline controls (like `BooleanEditor`) or a wrapped field layout (`FieldHeader` + nested editors).

2. Create the widget(s)
   - Place editor widget(s) in:
     `lib/widgets/app/components/inspector/editors/`
   - Prefer small composable widgets:
     - Simple: a single `HookConsumerWidget`.
     - Complex value editing with validation: consider `ValidatedEditorTextField<T>` pattern (see `NumberEditor` / `ValidatedEditorTextField`).
   - Use `FieldValueEditor` when you need automatic handling of conflict/none/loading states. Prefer to use this if possible.
   - Use `FieldHeader` if you need expansion, header text, or header actions.

3. Implement the `Editor` subclass
   - Extend `Editor`.
   - Implement `canEdit` precisely; leverage existing helpers:
     - `dataBlueprint.matches(DataBlueprint.string())`
     - `dataBlueprint is ListBlueprint`
   - Implement `build(path, dataBlueprint, mode)` returning the root widget.
   - If your editor must traverse child blueprints (e.g. collection/object-like), override `headerActions` copying the pattern in `ObjectEditor` or `ListEditor`.

4. Register the editor
   - Open `lib/widgets/app/components/inspector/editors.dart`.
   - Add an import for your editor file (absolute import).
   - Insert your editor in the returned list of `editors(Ref ref) => [...]`.
     Place it before broader editors to ensure it is selected (e.g. a specialized primitive editor before a generic primitive editor).

5. Widgetbook story
   - Mirror existing story patterns:
     - Path: `widgetbook/lib/stories/components/editors/<your_editor>.stories.dart`
     - Use `@widgetbook.UseCase`.
     - Reuse `EditorStory` if editing an object field blueprint, or build a small wrapper with overrides that feed a test `selectionProvider`.
   - Feed a `DataBlueprint` that your editor can handle (create `ObjectBlueprint` with a field referencing your target blueprint if needed).
   - Expose knobs if variation is useful (e.g. selecting `EditorMode` like existing stories do).

6. Code generation & analysis
   - If you only added a new editor class (no new Riverpod annotations / no Freezed changes): run `dart analyze`.
   - If you modified:
     - Freezed unions (new `Modifier`, new `DataBlueprint` variant) or
     - Riverpod annotated providers
     Then run:
       `dart run build_runner build -d`
     If issues:
       `dart run build_runner clean && dart run build_runner build -d`
   - Re-run `dart analyze`.

7. Test considerations
   - Unit test modifier logic and `DataBlueprint` default value generation.
   - Widget tests for:
     - Editing flows (enter value, update provider).
     - Boundary conditions (min/max, conflict, none).
   - Golden tests for stable visual components.

---

## Adding a Custom Modifier

Purpose
Extend the semantic constraints or formatting hints that editors can read.

Steps
1. Open `lib/logic/selectable/data_blueprint.dart`.
2. Add a new variant to `Modifier`:
   ```
   const factory Modifier.myCustom({required int something}) = MyCustomModifier;
   ```
3. Run codegen (Freezed will generate the supporting classes).
4. Integrate behavior:
   - Add checks in your editor:
     `final hasMyCustom = blueprint.hasModifier<MyCustomModifier>();`
   - For value constraints that affect default generation, extend logic in `DataBlueprintExtension` if necessary.
5. Storybook: create / adapt a story where a field uses your modifier (add it to the blueprint’s `modifiers: [...]` list).
6. Analyze & test.

Notes
- Use explicit field names (avoid `dynamic` unless absolutely required).
- Group related numeric constraints (e.g. `min`, `max`) rather than creating overlapping semantics.

---

## Adding a Custom Editor (CustomBlueprint)

Use when a field needs fully bespoke UX not expressible by existing blueprint types.

1. Produce blueprint in domain logic:
   ```
   DataBlueprint.custom(
     editor: "color_picker",
     shape: DataBlueprint.string(),
   )
   ```
   - `editor` is the lookup key for your editor.
   - `shape` describes the internal value structure (still influences default value and nested layout logic).
   - Create a static method on the `DataBlueprint` class as a nice shortcut to generate this blueprint. `static CustomBlueprint color({int? defaultValue, List<Modifier> modifiers = const []}) => DataBlueprint.custom(
     editor: "color",
     shape: DataBlueprint.integer(),
     internalDefaultValue: defaultValue,
     modifiers: modifiers,
   );`

2. Create an `Editor` subclass:
   - `canEdit` returns true for `CustomBlueprint` matching your `editor` id.
   - Build UI using `FieldValueEditor` for consistent state handling.

3. Respect shape if you want nested editing:
   - If `shape` is an object / list, you may still choose to surface nested editors via overriding `headerActions` to append children the way `ObjectEditor` / `ListEditor` do; otherwise treat it as opaque.

4. Register editor in `editors.dart` before generic fallbacks.

5. Optionally add a specific header action set (toggle, apply, etc.).

6. Provide a Widgetbook story constructing a blueprint with your custom editor id.

7. Run codegen only if you added or modified Freezed declarations (not needed for just referencing `CustomBlueprint`).

---

## Default Value & Modifier Utilities

Available helpers inside editors:
- `blueprint.defaultValue()` — resolves a safe default including modifier effects (e.g. generated string).
- `blueprint.hasModifier<SomeModifier>()`
- `blueprint.getModifiers<SomeModifier>()` — returns iterable (useful when multiples are allowed like `min` / `max`).

If you introduce new semantics that alter defaults, extend the relevant private `_defaultXValue` logic or add conditional branches before returning the fallback.

---

## Ordering & Conflict Avoidance

- Put specific editors (e.g. `ColorEditor` for `DataBlueprint.color()`) before generic ones (like a fallback `StringEditor`).
- Never broaden `canEdit` so much that multiple editors will logically match the same blueprint; only the first will be used, potentially hiding the intended editor.

---

## Naming Conventions

- Editor class: `PascalCase` + `Editor` suffix (`ColorEditor`).
- Editor file: `snake_case` + `_editor.dart`.
- Custom editor id (for `CustomBlueprint.editor`): lower snake or kebab; stay consistent (e.g. `"color_picker"`).
- Modifier: `PascalCaseModifier` names (e.g. `RangeModifier`).

---

## Minimal Example (Conceptual Only)

(Do not copy blindly; adjust specifics.)

1) Blueprint Definition in DataBlueprint:
```
class DataBlueprint {
// ...
const factory DataBlueprint.custom({
// ...
}) = CustomBlueprint;
// ...
static CustomBlueprint tag({String? defaultValue, List<Modifier> modifiers = const []}) {
  return CustomBlueprint(
    editor: "tag",
    shape: DataBlueprint.string(),
    defaultValue: defaultValue,
    modifiers: modifiers,
  );
}
// ...
}
```

2) Editor class:
```
class TagEditor extends Editor {
  @override
  bool canEdit(DataBlueprint dataBlueprint) =>
      dataBlueprint.matches(DataBlueprint.tag());

  @override
  Widget build(String path, DataBlueprint b, EditorMode mode) {
    return TagEditorWidget(
      path: path,
      customBlueprint: b as CustomBlueprint,
      editorMode: mode,
    );
  }
}

class TagEditorWidget extends HookConsumerWidget {
  const TagEditorWidget({
    required this.path,
    required this.customBlueprint,
    required this.editorMode,
    super.key,
  });

  final String path;
  final CustomBlueprint customBlueprint;
  final EditorMode editorMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Example: basic text display / placeholder for a future chip input.
    // Use FieldValueEditor to get consistent handling for conflict / none / loading states.
    return FieldValueEditor(
      path: path,
      dataBlueprint: customBlueprint,
      editorMode: editorMode,
      builder: (value) {
        // Replace with a richer chip input, token field, etc. as needed.
        return Text("Tag: $value");
      },
    );
  }
}
```

3) Register (`editors.dart`):
```
@riverpod
List<Editor> editors(Ref ref) => [
  TagEditor(),
  StringEditor(),
  NumberEditor(),
  ...
];
```

4) Story (`widgetbook/.../tag_editor.stories.dart`):
```
@widgetbook.UseCase(name: "Default", type: TagEditor)
Widget tagEditorUseCase(BuildContext context) {
  return EditorStory(
    dataBlueprint: ObjectBlueprint(fields: {
      "tag": DataBlueprint.tag(),
    }),
  );
}
```

---

## Verification Steps

After implementing:
1. `dart run build_runner build -d` (only if Freezed / Riverpod annotations modified).
2. `dart analyze`
3. Launch Widgetbook and verify:
   - Editor appears for the intended field.
   - Conflict / none / loading states still render (simulate via overrides if needed).
4. Exercise modifier-driven behaviors if you added a new modifier.

---

## Troubleshooting

Issue: Editor not picked
- Confirm it’s imported and listed in `editors` provider before a broader editor.
- Log or temporarily print which editors are evaluated (if needed).

Issue: Modifier not applied
- Check that the new modifier factory is inside `Modifier` union and codegen ran.
- Ensure you’re calling `hasModifier<YourModifier>()` or iterating `getModifiers`.

Issue: Custom editor shape children not visible
- Override `headerActions` and forward child tuples if you intend recursive traversal; otherwise only your top-level widget is rendered.

---

## Summary

You:
1. Implement a focused `Editor` subclass.
2. Register it in `editors.dart` (ordering matters).
3. (Optional) Provide header actions and nested traversal.
4. (Optional) Add new modifiers in the `Modifier` union with supporting editor logic.
5. Add Widgetbook story mirroring existing patterns.
6. Run codegen (if Freezed or Riverpod shapes changed) and analyze.

Follow these steps to keep the Inspector extensible, consistent, and maintainable.
