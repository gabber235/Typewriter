import "package:typewriter_panel/typewriter_panel.dart";

/// Advertises unbinding for one selectable.
///
/// The callback owns the resource side effect. [UnbindOperation] invokes
/// callbacks serially and keeps failed items selected for retry.
class UnbindSelectionCapability extends SelectionCapability {
  UnbindSelectionCapability({required this.onUnbind});
  final FutureOr<void> Function() onUnbind;
}

/// Unbinds the selected items with a hold on D, Delete or Backspace.
///
/// Successful items leave the selection. Refused items stay selected, and the
/// Unbind button and menu entry jam with the first refusal.
class UnbindOperation extends IntentShortcutOperation {
  const UnbindOperation();

  @override
  String get name => "Unbind";

  @override
  String get description => "Disconnect the selected services";

  @override
  Type get intent => DeleteIntent;

  @override
  OperationSection get section => OperationSection.destructive;

  @override
  OperationEmphasis get emphasis => OperationEmphasis.filled;

  @override
  bool canExecuteOn(List<Selectable> selection) =>
      selection.allHaveCapability<UnbindSelectionCapability>();

  // Service rows are not AnimatedRows: no rows, so a refusal jams the Unbind
  // button and menu entry, and the refused service stays selected.
  @override
  ActionRun get run => ActionRun.hold(
    HoldPlan<SelectableIdentifier>(
      // The service must be bound again.
      weight: HoldWeight.heavy,
      // A selection that failed to resolve offers nothing to unbind; the
      // preview runs while the button builds, so it never throws.
      targets: (ref) => {
        for (final selectable
            in ref.read(selectedProvider).value ?? const <Selectable>[])
          selectable.id,
      },
      verb: "Unbind",
      doneWord: "Unbound",
      outcome: (targets) => targets.length == 1
          ? "Unbind this service? It disconnects straight away."
          : "Unbind ${targets.length} services? "
                "They disconnect straight away.",
      each: _unbindOne,
    ),
  );

  /// Unbinds one captured service and lets it leave the selection.
  static Future<void> _unbindOne(WidgetRef ref, SelectableIdentifier id) async {
    final selection = ref.read(selectedProvider).value ?? const [];
    final capability = selection
        .where((selectable) => selectable.id == id)
        .collectCapabilitiesWithSelectables<UnbindSelectionCapability>()
        .firstOrNull
        ?.$2;
    if (capability == null) return;
    await capability.onUnbind();
    if (ref.context.mounted) {
      ref.read(selectionProvider.notifier).unselectAll([id]);
    }
  }

  /// The shortcut, menu and inspector run the hold; nothing calls this
  /// without one.
  @override
  FutureOr<void> executeOn(WidgetRef ref) =>
      throw StateError("Unbind runs only through its hold.");

  @override
  MenuItem menuItem(WidgetRef ref) {
    return MenuItem.command(
      command: shortcut,
      icon: const Icon(Icons.link_off),
    );
  }

  @override
  Widget inspectorButton(
    List<Selectable> selection, {
    required OperationEmphasis emphasis,
  }) {
    return CommandButton(
      command: shortcut,
      face: emphasis.face,
      icon: const Icon(Icons.link_off, size: 16),
      label: selection.length > 1 ? "Unbind ${selection.length}" : "Unbind",
    );
  }
}
