# TypeWriter Panel — Recipe: Migrate Legacy Inspector Editors to the New Editors System

Intent
A precise, mechanical step plan to migrate legacy Inspector editors (pre–EditorMode/FieldValueEditor system) to the new architecture. This guide ensures:
- All modifiers are ported to the new Freezed-based `Modifier` union.
- Custom editors are modeled via `CustomBlueprint` and registered.
- Editors use new value/state handling via `FieldValueEditor`.
- Header traversal, names, and widgets are updated (`FieldHeader`, `FieldEditor`, `EditorMode`).
- Editors are added to the editors list.
- Widgetbook stories and tests are added and aligned with repository utilities.

Outcome
Given a legacy editor implementation, an AI can follow this plan and deliver a fully migrated editor consistent with the app architecture, stories, and tests.

---

High-level differences you must account for
- Value model changed: field values are surfaced via a SelectedValue union (Loading/None/Conflict/Value). Use `FieldValueEditor` to render each state consistently.
- Editor discovery changed: implement `class YourEditor extends Editor`, not `EditorFilter`, and return your UI from `build(path, dataBlueprint, editorMode)`.
- Header actions changed: provide header traversal and actions via `Editor.headerActions(...)` and `HeaderAction` implementations that consider `EditorMode`.
- Modifiers changed: string-based lookups became strongly-typed `Modifier` unions (e.g., `MultilineModifier`, `SnakeCaseModifier`, `MinModifier`, `MaxModifier`, `NegativeModifier`, `ReadOnlyModifier`, `ExpandedModifier`).
- Path/header rendering changed: use `FieldHeader(path: ..., dataBlueprint: ..., editorMode: ...)` and `pathDisplayNameProvider` for names.
- Updates changed: write values by calling `ref.read(selectedProvider.notifier).updateFieldValue(path, value)`.

---

Phase 0 — Pre-flight and placement
- Where to put editors
  - Editor classes/widgets: lib/widgets/app/components/inspector/editors/
  - Central registry: lib/widgets/app/components/inspector/editors.dart
  - Header actions: lib/widgets/app/components/inspector/header.dart (in the `headerActions` provider) or editor-specific `headerActions()` override.
- Where to put stories
  - widgetbook/lib/stories/app/components/inspector/editors/
- Where to put tests
  - test/widgets/app/components/inspector/editors/

---

Phase 1 — Convert imports and symbol names
- Use package imports only, prefixed with typewriter_panel:
  - Replace old “package:typewriter/...” with “package:typewriter_panel/...”.
- Replace legacy helpers with new counterparts:
  - Value access
    - Old: `ref.watch(fieldValueProvider(path, default))` returns raw value
    - New: `ref.watch(fieldValueProvider(path))` returns SelectedValue (Loading/None/Conflict/Value). Don’t unwrap it directly in editors. Wrap your editor UI in `FieldValueEditor`.
  - Value updates
    - Old: `ref.read(inspectingEntryDefinitionProvider)?.updateField(ref.passing, path, value)`
    - New: `ref.read(selectedProvider.notifier).updateFieldValue(path, value)`
  - WritersIndicator and writer providers
    - Remove WritersIndicator or writer overlays from legacy code unless a new equivalent exists. The new inspector does not surface writers in editors by default.
  - PassingRef and focus-current-field hooks
    - Remove PassingRef usage. Replace any “focused-based current editing” hook with local `FocusNode` usage when needed. The new architecture doesn’t use “current editing field” tracking for Inspector chrome.
  - FieldHeader
    - Old: `FieldHeader(path: path, canExpand: true, child: ...)`
    - New: `FieldHeader(path: path, dataBlueprint: dataBlueprint, editorMode: editorMode, canExpand: true, child: ...)`
  - FieldEditor
    - Old: `FieldEditor(path: childPath, dataBlueprint: dataBlueprint)`
    - New: `FieldEditor(path: childPath, dataBlueprint: dataBlueprint, editorMode: editorMode)`
  - Reorderable list
    - Old: ReorderableList
    - New: ReorderableListView with `buildDefaultDragHandles: false` if you handle drag handles yourself.

---

Phase 2 — Migrate modifiers
- Replace stringly-typed modifier checks with strongly-typed union checks:
  - Old: `primitiveBlueprint.hasModifier("multiline")`
  - New: `primitiveBlueprint.hasModifier<MultilineModifier>()`
  - Old: `hasModifier("snake_case")`
  - New: `hasModifier<SnakeCaseModifier>()`
  - Old: `get("negative")`, `get("min")`, `get("max")`
  - New: `hasModifier<NegativeModifier>()`, `getModifiers<MinModifier>()`, `getModifiers<MaxModifier>()` and fold/min/max their values as needed.
- Respect read-only and expanded:
  - Read-only: `dataBlueprint.hasModifier<ReadOnlyModifier>()` or `EditorMode.resolve()` with recursive behavior.
  - Expanded: `dataBlueprint.hasModifier<ExpandedModifier>()` affects FieldHeader default expansion.

---

Phase 3 — Convert EditorFilter to Editor
- Replace `class XEditorFilter extends EditorFilter` with `class XEditor extends Editor`.
- Implement:
  - `bool canEdit(DataBlueprint dataBlueprint)` using:
    - `dataBlueprint.matches(DataBlueprint.string())` for strings
    - `dataBlueprint is ListBlueprint` for lists
    - `dataBlueprint is ObjectBlueprint` for objects
    - Primitive checks: `dataBlueprint is PrimitiveBlueprint && (dataBlueprint.type == PrimitiveType.integer || ...)`
  - `Widget build(String path, DataBlueprint dataBlueprint, EditorMode editorMode)`
- If your editor has nested children (object fields, list items), override `headerActions(...)` to append children similar to the object/list examples.

Skeleton
```
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/logic/selectable/data_blueprint.dart";
import "package:typewriter_panel/widgets/app/components/inspector/editors.dart";
import "package:typewriter_panel/widgets/app/components/inspector/editors/field_editor.dart";
import "package:typewriter_panel/widgets/app/components/inspector/header.dart";
import "package:flutter/material.dart";

class MyEditor extends Editor {
  @override
  bool canEdit(DataBlueprint dataBlueprint) {
    return dataBlueprint.matches(DataBlueprint.string());
  }

  @override
  Widget build(String path, DataBlueprint b, EditorMode editorMode) {
    final primitiveBlueprint = b as PrimitiveBlueprint;
    return FieldHeader(
      path: path,
      dataBlueprint: primitiveBlueprint,
      editorMode: editorMode,
      canExpand: false,
      child: MyEditorWidget(
        path: path,
        primitiveBlueprint: primitiveBlueprint,
        editorMode: editorMode,
      ),
    );
  }

  @override
  (HeaderActions, Iterable<(String, HeaderContext, DataBlueprint)>)
      headerActions(
    Ref ref,
    String path,
    DataBlueprint dataBlueprint,
    HeaderContext context,
    EditorMode mode,
  ) {
    final parent = super.headerActions(ref, path, dataBlueprint, context, mode);
    return (parent.$1, parent.$2);
  }
}

class MyEditorWidget extends HookConsumerWidget {
  const MyEditorWidget({
    required this.path,
    required this.primitiveBlueprint,
    required this.editorMode,
    super.key,
  });

  final String path;
  final PrimitiveBlueprint primitiveBlueprint;
  final EditorMode editorMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FieldValueEditor(
      path: path,
      dataBlueprint: primitiveBlueprint,
      editorMode: editorMode,
      builder: (value) {
        return Text(value?.toString() ?? "");
      },
    );
  }
}
```

---

Phase 4 — Use FieldValueEditor for value and states
- Wrap the actual input UI with `FieldValueEditor`:
  - Use `builder: (value) { ... }` to render the editor with the resolved value.
  - FieldValueEditor handles:
    - Loading: shimmer placeholder
    - None: “missing” box with reset-to-default on tap (if editable)
    - Conflict: “different values” box with reset-to-default on tap (if editable)
- If your widget needs a focus node or controller, manage them normally (hook/state) inside your editor widget’s build.

Example: String editor conversion
```
import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:iconify_flutter_plus/icons/heroicons_solid.dart";
import "package:typewriter_panel/logic/selectable/data_blueprint.dart";
import "package:typewriter_panel/logic/selectable/selection.dart";
import "package:typewriter_panel/widgets/app/components/inspector/editors.dart";
import "package:typewriter_panel/widgets/app/components/inspector/editors/field_editor.dart";
import "package:typewriter_panel/widgets/generic/components/formatted_text_field.dart";
import "package:typewriter_panel/utils/snake_case_input_formatter.dart";

class StringEditor extends Editor {
  @override
  bool canEdit(DataBlueprint dataBlueprint) =>
      dataBlueprint.matches(DataBlueprint.string());

  @override
  Widget build(String path, DataBlueprint b, EditorMode editorMode) {
    return StringEditorWidget(
      path: path,
      primitiveBlueprint: b as PrimitiveBlueprint,
      editorMode: editorMode,
    );
  }
}

class StringEditorWidget extends HookConsumerWidget {
  const StringEditorWidget({
    required this.path,
    required this.primitiveBlueprint,
    required this.editorMode,
    this.forceValue,
    this.icon = HeroiconsSolid.pencil,
    this.hint = "",
    this.onChanged,
    super.key,
  });

  final String path;
  final PrimitiveBlueprint primitiveBlueprint;
  final EditorMode editorMode;

  final String? forceValue;
  final String icon;
  final String hint;
  final void Function(String)? onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusNode = useFocusNode();
    final controller = useTextEditingController();

    final multiline = primitiveBlueprint.hasModifier<MultilineModifier>();
    final snakeCase = primitiveBlueprint.hasModifier<SnakeCaseModifier>();
    final canEdit = (editorMode, primitiveBlueprint).canEdit;

    return FieldValueEditor(
      path: path,
      dataBlueprint: primitiveBlueprint,
      editorMode: editorMode,
      forceValue: forceValue,
      builder: (value) {
        return FormattedTextField(
          controller: controller,
          focusNode: focusNode,
          icon: icon,
          hintText: hint.isNotEmpty ? hint : "Enter a ${primitiveBlueprint.type.name}",
          text: value,
          singleLine: !multiline,
          inputFormatters: [
            if (snakeCase) SnakeCaseInputFormatter(),
          ],
          onChanged: onChanged ??
              (next) => ref.read(selectedProvider.notifier).updateFieldValue(path, next),
          readOnly: !canEdit,
        );
      },
    );
  }
}
```

---

Phase 5 — Header actions and nested traversal
- If an editor contributes nested child fields (list/object/custom shape), override `headerActions(...)` and append children:
  - For each nested field item produce a `(childPath, childContext, childBlueprint)` tuple.
  - Always call `super.headerActions(...)` to get the base actions for this path and merge with children.
- Example: list/object traversal mirrors repository patterns (copy these if needed):
  - Object: iterate `objectBlueprint.fields.entries`
  - List: compute length from `fieldValueProvider(path)` and enqueue `[index]` paths

Example: Object traversal
```
@override
(HeaderActions, Iterable<(String, HeaderContext, DataBlueprint)>)
    headerActions(
  Ref ref,
  String path,
  DataBlueprint dataBlueprint,
  HeaderContext context,
  EditorMode mode,
) {
  final objectBlueprint = dataBlueprint as ObjectBlueprint;
  final parent = super.headerActions(ref, path, dataBlueprint, context, mode);
  final childContext = context.copyWith(parentBlueprint: dataBlueprint);
  final children = objectBlueprint.fields.entries.map(
    (entry) => (path.join(entry.key), childContext, entry.value),
  );
  return (parent.$1, parent.$2.followedBy(children));
}
```

Example: Boolean rendered as header trailing action
```
class BooleanEditor extends Editor {
  @override
  bool canEdit(DataBlueprint dataBlueprint) =>
      dataBlueprint.matches(DataBlueprint.boolean());

  @override
  Widget build(String path, DataBlueprint b, EditorMode mode) {
    if (mode.hasHeaderActions) return SizedBox();
    return BooleanEditorWidget(
      path: path,
      primitiveBlueprint: b as PrimitiveBlueprint,
      editorMode: mode,
    );
  }
}

class BooleanHeaderAction extends HeaderAction {
  @override
  bool shouldShow(
    String path,
    HeaderContext context,
    DataBlueprint dataBlueprint,
    EditorMode editorMode,
  ) =>
      dataBlueprint.matches(DataBlueprint.boolean());

  @override
  HeaderActionLocation location(
    String path,
    HeaderContext context,
    DataBlueprint dataBlueprint,
    EditorMode editorMode,
  ) =>
      HeaderActionLocation.trailing;

  @override
  Widget build(
    String path,
    HeaderContext context,
    DataBlueprint dataBlueprint,
    EditorMode editorMode,
  ) =>
      BooleanEditorWidget(
        path: path,
        primitiveBlueprint: dataBlueprint as PrimitiveBlueprint,
        editorMode: editorMode,
      );
}
```

Register your `HeaderAction` in `headerActions(Ref ref)` if it’s global, or rely solely on your editor’s `headerActions` override to enqueue children.

---

Phase 6 — Register the editor
- Open lib/widgets/app/components/inspector/editors.dart and add your editor to the list:
  - Keep order: custom/specialized editors first, then primitive, then list/object.
  - Ensure your import is present with package: import.

Example
```
@riverpod
List<Editor> editors(Ref ref) => [
      // Custom/specialized first:
      // MyCustomEditor(),
      // Then primitives:
      StringEditor(),
      NumberEditor(),
      BooleanEditor(),
      // Then collections/objects:
      ListEditor(),
      ObjectEditor(),
    ];
```

---

Phase 7 — If this is a custom editor, add it to DataBlueprint
- Add a static constructor to DataBlueprint that returns a CustomBlueprint with your editor id and shape:
  - File: lib/logic/selectable/data_blueprint.dart
  - Choose an editor id, e.g., "tag", "color_picker".
  - Define `shape` to describe the data the editor manages (primitive/list/object), and set defaults if needed.
- canEdit in your editor should return true for `CustomBlueprint` with your id, or via a helper check.

Example
```
// Inside DataBlueprint (same style as moduleVersion() in the repo)
static CustomBlueprint tag({
  String? defaultValue,
  List<Modifier> modifiers = const [],
}) {
  return CustomBlueprint(
    editor: "tag",
    shape: DataBlueprint.string(defaultValue: defaultValue),
    modifiers: modifiers,
  );
}
```

---

Phase 8 — Widgetbook story
- Create a story under widgetbook/lib/stories/app/components/inspector/editors/<your_editor>.stories.dart.
- Use EditorStory from widgetbook workspace and pass an ObjectBlueprint with your field’s blueprint.
- Use package imports. Do not use relative imports.
- Run codegen (if UseCase annotations are new) and run Widgetbook.

Example
```
import "package:flutter/material.dart";
import "package:typewriter_panel/logic/selectable/data_blueprint.dart";
import "package:typewriter_panel/widgets/app/components/inspector/editors/string_editor.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/stories/app/components/inspector/editors/editors.stories.dart";

@widgetbook.UseCase(name: "Default", type: StringEditor)
Widget stringEditorUseCase(BuildContext context) {
  return EditorStory(
    dataBlueprint: ObjectBlueprint(
      fields: {
        "name": DataBlueprint.string(),
      },
    ),
  );
}
```

---

Phase 9 — Tests
- Prefer widget tests that render the editor in a minimal, controlled environment.
- Use the provided test utilities in test/test_utils.dart. Both testApp() and pumpTestApp() accept overrides: []. Prefer pumpTestApp(child: ..., overrides: [...]) to provide provider overrides. Also call setupMocks() in your test main() or setUpAll to register mocktail fallback values used by the testkit.
- Prefer using override helpers from the testkit package (package:typewriter_testkit/typewriter_testkit.dart) for common app providers (e.g., appearanceProviderOverrides(...), authProviderOverrides(...), booksProviderOverrides(...), manualsProviderOverrides(...), modulesProviderOverrides(...), organizationsProviderOverrides(...)).
- For Inspector editors, use WidgetTester.pumpEditor(...) from test/widgets/utils/editor_utils.dart to quickly mount an editor given a DataBlueprint, initial data, and optional EditorMode; it wires selectionProvider and test data helpers for you.
- Two typical patterns:

A) Directly test the widget using FieldValueEditor.forceValue (if your editor passes it through)
```
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/widgets/app/components/inspector/editors/string_editor.dart";
import "package:typewriter_panel/logic/selectable/data_blueprint.dart";
import "../test_utils.dart";

void main() {
  testWidgets("StringEditor renders forced value", (tester) async {
    await tester.pumpTestApp(
      child: StringEditorWidget(
        path: "name",
        primitiveBlueprint: DataBlueprint.string() as PrimitiveBlueprint,
        editorMode: EditorMode.interactiveInspector,
        forceValue: "hello",
      ),
    );
    expect(find.text("hello"), findsOneWidget);
  });
}
```

B) Override providers to simulate selection and a current value
```
import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/logic/selectable/data_blueprint.dart";
import "package:typewriter_panel/logic/selectable/selection.dart";
import "package:typewriter_panel/widgets/app/components/inspector/editors/number_editor.dart";
import "../test_utils.dart";

void main() {
  testWidgets("NumberEditor writes updated value", (tester) async {
    final overrides = <Override>[
      selectionProvider.overrideWithValue([
            TestSelectableIdentifier(
              id: "editor",
              dataBlueprint: ObjectBlueprint(fields: {
                "count": DataBlueprint.integer(),
              }),
            ),
          ]),
      fieldValueProvider.overrideWith((ref, path) {
        if (path == "count") return SelectedValue.value(2);
        return SelectedValue.none();
      }),
    ];

    await tester.pumpTestApp(
      child: NumberEditorWidget(
        path: "count",
        primitiveBlueprint: DataBlueprint.integer() as PrimitiveBlueprint,
        editorMode: EditorMode.interactiveInspector,
      ),
      overrides: overrides,
    );

    await tester.pumpAndSettle();
    expect(find.text("2"), findsOneWidget);
  });
}
```

- Use `pumpTestApp` from test/test_utils.dart (it already wraps ProviderScope and MaterialApp), or wrap your own ProviderScope to provide overrides.
- Capture screenshots with the provided extensions if visual verification helps.

---

Phase 10 — Analyze, codegen, and verify
- If you added new Freezed unions or Riverpod annotations:
  - dart run build_runner build -d
  - If issues: dart run build_runner clean && dart run build_runner build -d
- Always run:
  - dart analyze
- Launch Widgetbook:
  - flutter run -t widgetbook/lib/main.dart -d macos
- Manual verification
  - In Widgetbook, switch EditorMode knob to verify header actions hidden/visible behavior and read-only behavior.
  - Verify conflict/none/loading states in FieldValueEditor stories.

---

Mechanical mapping reference — old to new

- Value read/write
  - read: `ref.watch(fieldValueProvider(path))` now returns `SelectedValue`
  - write: `ref.read(selectedProvider.notifier).updateFieldValue(path, value)`
- Field wrapper widgets
  - Use `FieldHeader(path: ..., dataBlueprint: ..., editorMode: ..., canExpand: ...)`
  - Use `FieldEditor(path: ..., dataBlueprint: ..., editorMode: ...)`
  - Use `FieldValueEditor` to handle value state machine
- Modifiers
  - "multiline" => `MultilineModifier`
  - "snake_case" => `SnakeCaseModifier`
  - "negative" => `NegativeModifier`
  - "min" => `MinModifier`
  - "max" => `MaxModifier`
  - read-only => `ReadOnlyModifier(recursive: ...)`
  - expanded => `ExpandedModifier()`
- Types
  - PrimitiveType.string/integer/double/boolean => `DataBlueprint.string()/integer()/decimal()/boolean()`
  - Lists => `DataBlueprint.list(type: ...)`
  - Objects => `DataBlueprint.object(fields: {...})`
  - Custom => `DataBlueprint.custom(editor: "id", shape: ...)` or a `static` factory on DataBlueprint for reuse
- Header actions
  - Implement `HeaderAction` with `shouldShow`, `location`, `build` and register in `headerActions(Ref ref)` or inline via editor `headerActions(...)` override

---

Done checklist
- Editor refactored from EditorFilter to Editor (with EditorMode-aware build).
- Modifiers migrated to Freezed unions.
- Value handling via FieldValueEditor; write via selectedProvider.
- Header traversal implemented and/or header actions registered.
- Editor registered in editors() list in proper order.
- Widgetbook story created using EditorStory and package imports.
- Tests added using test utilities (forceValue or provider overrides).
- Analyze/codegen complete; Widgetbook verified.

Notes
- Keep editors small and composable; prefer a UI widget (XxxEditorWidget) for reuse in stories and tests.
- Follow the project’s conventions (package imports, trailing commas, double quotes).