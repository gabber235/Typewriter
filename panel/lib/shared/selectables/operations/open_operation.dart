import "package:typewriter_panel/typewriter_panel.dart";

/// Advertises opening for one selectable.
///
/// [allowMultiSelect] controls whether this item may participate in a batch
/// open. The callback owns the actual navigation or presentation side effect.
class OpenSelectionCapability extends SelectionCapability {
  OpenSelectionCapability({required this.onOpen, this.allowMultiSelect = true});

  final FutureOr<void> Function() onOpen;

  /// Whether this item may participate in a multi item open.
  final bool allowMultiSelect;
}

/// Opens the selected items when every item supports opening.
///
/// A multi item open is available only when every capability allows it. Items
/// are opened in selection order.
class OpenOperation extends IntentShortcutOperation {
  const OpenOperation();

  @override
  String get name => "Open";

  @override
  String get description => "Open selected items";

  @override
  Type get intent => PrimaryActionIntent;

  @override
  OperationSection get section => OperationSection.navigation;

  @override
  OperationEmphasis get emphasis => OperationEmphasis.filled;

  @override
  bool canExecuteOn(List<Selectable> selection) {
    if (!selection.allHaveCapability<OpenSelectionCapability>()) return false;

    // Single selection: always allowed
    if (selection.length == 1) return true;

    // Multi selection requires every item to allow batch opening.
    return selection.collectCapabilities<OpenSelectionCapability>().none(
      (op) => !op.allowMultiSelect,
    );
  }

  @override
  FutureOr<void> executeOn(WidgetRef ref) async {
    final selection = ref.read(selectedProvider).requireValue;
    for (final (_, op)
        in selection
            .collectCapabilitiesWithSelectables<OpenSelectionCapability>()) {
      await op.onOpen();
      if (!ref.context.mounted) return;
    }
  }

  @override
  MenuItem menuItem(WidgetRef ref) {
    return MenuItem(
      icon: const Icon(Icons.open_in_new),
      label: "Open",
      onPressed: () => executeOn(ref),
    );
  }

  @override
  Widget inspectorButton(
    List<Selectable> selection, {
    required OperationEmphasis emphasis,
  }) => CommandButton(
    command: shortcut,
    face: emphasis.face,
    icon: const Icon(Icons.open_in_new, size: 16),
    label: selection.length > 1 ? "Open (${selection.length})" : "Open",
    busyLabel: "Opening",
  );
}
