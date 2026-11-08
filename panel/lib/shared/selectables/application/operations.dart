import "package:typewriter_panel/typewriter_panel.dart";

const coreSelectionOperations = <SelectionOperation>[
  OpenOperation(),
  UnbindOperation(),
];

/// Defines an action available for the current resolved selection.
///
/// Instances are registered through a [SelectionOperationSource]. Availability is
/// evaluated against the resolved selection, while execution reads the latest
/// provider state at invocation so menus, shortcuts and inspector controls share
/// one operation implementation. A held operation captures its targets when
/// the hold starts.
abstract class SelectionOperation {
  const SelectionOperation();

  /// Human readable label displayed in menus and buttons.
  String get name;

  /// Human readable description displayed in tooltips and shortcut displays.
  String get description;

  /// Whether this operation is offered among the inspector controls.
  bool get showInInspector => true;

  /// The menu section this operation belongs to. Menus separate neighboring
  /// operations of different groups; null groups operations together.
  Object? get menuGroup => null;

  /// Returns whether this operation is valid for [selection].
  ///
  /// Callers use this as a fast, side effect free availability check. An empty
  /// selection is not executable.
  bool canExecuteOn(List<Selectable> selection);

  /// Executes against the latest resolved selection in [ref].
  ///
  /// Implementations may mutate model state, emit provider changes, or trigger
  /// UI effects. The caller may await the returned [Future]. Availability is
  /// checked before invocation.
  FutureOr<void> executeOn(WidgetRef ref);

  /// What pressing does: a press runs [executeOn]; a hold runs its work
  /// after the fill, and every path (key, menu, inspector) reaches it
  /// through the operation's shortcut. Null when the operation cannot run.
  ActionRun? get run => ActionRun.press(executeOn);

  /// Builds the context menu item that invokes this operation.
  ///
  /// The item is created only after [canExecuteOn] filtering. Keep construction
  /// cheap and side effect free; the callback may perform the actual work.
  MenuItem menuItem(WidgetRef ref);

  /// Builds the inspector control for this operation and [selection].
  ///
  /// The selection supplies presentation details such as the item count. The
  /// control invokes [executeOn] through its [WidgetRef] when activated.
  Widget inspectorButton(List<Selectable> selection);
}

abstract class ShortcutableOperation extends SelectionOperation {
  const ShortcutableOperation();

  /// Returns the shortcut registration for this operation.
  ActionShortcut get shortcut;
}

abstract class ActivatorShortcutOperation extends ShortcutableOperation {
  const ActivatorShortcutOperation();

  /// Keyboard activators that trigger this operation.
  List<ShortcutActivator> get activators;

  @override
  ActionShortcut get shortcut => ActionShortcut(
    id: "operation_${name.snakeCase()}",
    label: name,
    description: description,
    activators: activators,
    priority: 10,
    run: run,
  );
}

abstract class IntentShortcutOperation extends ShortcutableOperation {
  const IntentShortcutOperation();

  /// Intent type that triggers this operation.
  Type get intent;

  @override
  ActionShortcut get shortcut => ActionShortcut.intent(
    id: "operation_${name.snakeCase()}",
    label: name,
    description: description,
    intent: intent,
    priority: 10,
    run: run,
  );
}

/// Resolves capability requirements and callbacks across a selectable batch.
extension SelectionCapabilitySelectionX on Iterable<Selectable> {
  /// Whether every item exposes a capability of type [T].
  ///
  /// Returns false for an empty iterable.
  bool allHaveCapability<T extends SelectionCapability>() =>
      isNotEmpty && every((s) => s.capabilities.any((o) => o is T));

  /// Whether at least one item exposes a capability of type [T].
  bool anyHaveCapability<T extends SelectionCapability>() =>
      any((s) => s.capabilities.any((o) => o is T));

  /// Collects capabilities of type [T] in selection order.
  Iterable<T> collectCapabilities<T extends SelectionCapability>() =>
      expand((s) => s.capabilities.whereType<T>());

  /// Collects each capability of type [T] with its owning selectable.
  Iterable<(Selectable, T)>
  collectCapabilitiesWithSelectables<T extends SelectionCapability>() =>
      expand((s) => s.capabilities.whereType<T>().map((o) => (s, o)));

  /// Whether no item exposes a capability of type [T].
  bool noneHaveCapabilities<T extends SelectionCapability>() =>
      !anyHaveCapability<T>();
}

/// Filters registered operations to those valid for [selected].
///
/// A null or empty resolved selection produces an empty list. This shared
/// filter drives inspector controls, context menu items, and keyboard
/// shortcuts, so all entry points use the same availability rules.
List<SelectionOperation> availableSelectionOperations(
  List<SelectionOperation> operations,
  List<Selectable>? selected,
) {
  if (selected == null) return [];
  if (selected.isEmpty) return [];
  return operations
      .where((operation) => operation.canExecuteOn(selected))
      .toList();
}

/// Menu items for [operations] in their order, with a divider at every change
/// of [SelectionOperation.menuGroup].
List<MenuItem> selectionOperationMenuItems(
  Iterable<SelectionOperation> operations,
  WidgetRef ref,
) {
  final items = <MenuItem>[];
  Object? group;
  for (final (index, operation) in operations.indexed) {
    if (index > 0 && operation.menuGroup != group) {
      items.add(const MenuItem.divider());
    }
    group = operation.menuGroup;
    items.add(operation.menuItem(ref));
  }
  return items;
}
