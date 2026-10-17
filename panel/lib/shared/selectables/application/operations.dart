import "package:typewriter_panel/typewriter_panel.dart";

const coreSelectionOperations = <SelectionOperation>[
  OpenOperation(),
  UnbindOperation(),
  DeleteOperation(),
];

/// Defines an action available for the current resolved selection.
///
/// Instances are registered by [SelectionOperationsRoot]. Availability is
/// evaluated against the resolved selection, while execution reads the latest
/// provider state at invocation so menus, shortcuts and inspector controls share
/// one operation implementation. An operation may retain that captured batch
/// while awaiting confirmation.
abstract class SelectionOperation {
  const SelectionOperation();

  /// Human readable label displayed in menus and buttons.
  String get name;

  /// Human readable description displayed in tooltips and shortcut displays.
  String get description;

  /// Returns whether this operation is valid for [selection].
  ///
  /// Callers use this as a fast, side effect free availability check. An empty
  /// selection is not executable.
  bool canExecuteOn(List<Selectable> selection);

  /// Executes against the latest resolved selection in [ref].
  ///
  /// Implementations may mutate model state, emit provider changes, or trigger
  /// UI effects. The caller may await the returned [Future]. Availability is
  /// checked before invocation. A confirmation flow can retain the selection
  /// captured when the operation begins.
  FutureOr<void> executeOn(WidgetRef ref);

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
    onInvoke: executeOn,
    priority: 10,
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
    onInvoke: executeOn,
    priority: 10,
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

/// Shows per item failures collected during a batch operation.
///
/// Successful items are handled by the operation before this dialog opens.
/// The dialog reports only failures and leaves recovery decisions to the
/// operation's caller.
Future<void> showOperationErrorsPopup(
  BuildContext context,
  List<(Selectable, Object)> errors,
  String operationName,
) async {
  await showAdvancedDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        titlePadding: const EdgeInsets.only(
          left: 24,
          top: 16,
          right: 8,
          bottom: 0,
        ),
        title: Row(
          children: [
            Expanded(child: Text("$operationName errors")),
            IconButton(
              autofocus: true,
              splashRadius: 18,
              icon: const Icon(Icons.close),
              tooltip: "Close",
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                Text(
                  "Failed to ${operationName.toLowerCase()} ${errors.length} item(s). Others were ${operationName.toLowerCase()}d successfully.",
                ),
                for (final (selectable, err) in errors)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 2,
                      children: [
                        Text(
                          selectable.name,
                          style: Theme.of(context).textTheme.bodyMedium!
                              .copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 13,
                              ),
                        ),
                        Text(
                          err.toString(),
                          style: Theme.of(context).textTheme.bodyMedium!
                              .copyWith(
                                color: Theme.of(context).colorScheme.error,
                                fontSize: 12,
                              ),
                        ),
                        const Divider(height: 8),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
