import "package:typewriter_panel/typewriter_panel.dart";

const coreSelectionOperations = <SelectionOperation>[
  OpenOperation(),
  UnbindOperation(),
];

/// The sections operations sit in, in display order. The inspector and the
/// context menu draw a divider between sections.
enum OperationSection {
  /// Going to the thing: Open, Inspect.
  navigation,

  /// Changing the thing itself.
  edit,

  /// Moving, linking and copying.
  organize,

  /// Removing or disconnecting; always held.
  destructive,
}

/// How strongly an operation's inspector button stands out.
enum OperationEmphasis {
  /// Most operations.
  flat,

  /// The likely next step.
  outline,

  /// The pane's main action; at most one per pane.
  filled;

  /// The button face this emphasis paints.
  ButtonFace get face => switch (this) {
    OperationEmphasis.flat => ButtonFace.quiet,
    OperationEmphasis.outline => ButtonFace.outlined,
    OperationEmphasis.filled => ButtonFace.filled,
  };
}

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

  /// The section this operation sits in, in the inspector and the context
  /// menu alike.
  OperationSection get section => OperationSection.edit;

  /// The position inside its [section]; lower comes first, and equal ones
  /// keep the order their source gave.
  int get order => 0;

  /// How strongly its inspector button wants to stand out. The inspector
  /// shows only the first filled operation filled.
  OperationEmphasis get emphasis => OperationEmphasis.flat;

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

  /// Builds the inspector control for this operation and [selection], in
  /// the [emphasis] the inspector gives it.
  ///
  /// The selection supplies presentation details such as the item count. The
  /// control invokes [executeOn] through its [WidgetRef] when activated.
  Widget inspectorButton(
    List<Selectable> selection, {
    required OperationEmphasis emphasis,
  });
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

/// Menu items for [operations] in their sections, with a divider between
/// sections: the same list the inspector shows.
List<MenuItem> selectionOperationMenuItems(
  Iterable<SelectionOperation> operations,
  WidgetRef ref,
) => [
  for (final (index, section) in operations.sections.indexed) ...[
    if (index > 0) const MenuItem.divider(),
    for (final operation in section) operation.menuItem(ref),
  ],
];

/// Operation names already reported for asking to be a second filled
/// button, so a rebuild does not report them again.
final _reportedSecondFilled = <String>{};

/// Sections and emphasis of an operation list.
extension SelectionOperationSections on Iterable<SelectionOperation> {
  /// The operations ordered by section, then order, then the order given,
  /// split into their non empty sections.
  List<List<SelectionOperation>> get sections {
    final ordered = indexed.toList()
      ..sort((a, b) {
        final bySection = a.$2.section.index.compareTo(b.$2.section.index);
        if (bySection != 0) return bySection;
        final byOrder = a.$2.order.compareTo(b.$2.order);
        return byOrder != 0 ? byOrder : a.$1.compareTo(b.$1);
      });
    final sections = <List<SelectionOperation>>[];
    OperationSection? current;
    for (final (_, operation) in ordered) {
      if (operation.section != current) sections.add([]);
      current = operation.section;
      sections.last.add(operation);
    }
    return sections;
  }

  /// The emphasis each operation shows with, in this order: the first one
  /// asking to be filled is filled, and every later one is flat, reported
  /// once, since a pane has at most one filled button.
  List<OperationEmphasis> get shownEmphases {
    final firstFilled = indexed
        .firstWhereOrNull((entry) => entry.$2.emphasis.isFilled)
        ?.$1;
    return [
      for (final (index, operation) in indexed)
        if (operation.emphasis.isFilled && index != firstFilled)
          operation._flatInstead()
        else
          operation.emphasis,
    ];
  }
}

extension on OperationEmphasis {
  bool get isFilled => this == OperationEmphasis.filled;
}

extension on SelectionOperation {
  /// Flat, for a second filled operation, reported once per name.
  OperationEmphasis _flatInstead() {
    if (_reportedSecondFilled.add(name)) {
      debugPrint(
        "Operation $name asks to be filled, but the pane already has a "
        "filled button; it shows flat.",
      );
    }
    return OperationEmphasis.flat;
  }
}
