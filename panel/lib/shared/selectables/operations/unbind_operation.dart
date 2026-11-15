import "package:typewriter_panel/typewriter_panel.dart";

/// Advertises unbinding for one selectable.
///
/// [target] is what the selectable unbinds, and [batch] owns the resource
/// side effect. Selected items whose batches are equal unbind together in one
/// all or nothing request.
class UnbindSelectionCapability extends SelectionCapability {
  UnbindSelectionCapability({required this.batch, required this.target});
  final UnbindBatch batch;
  final Object target;
}

/// Unbinds several targets as one change.
///
/// Equal batches serve the same owner, so the operation joins their targets.
abstract interface class UnbindBatch {
  /// Unbinds every one of [targets], or none of them. A refusal throws
  /// [RefusedTargets] naming the refused targets.
  Future<void> unbind(List<Object> targets);
}

/// Unbinds the selected items with a hold on D, Delete or Backspace.
///
/// Items of one owner unbind together, all or nothing, and leave the
/// selection. A refused batch keeps its items selected, and the Unbind
/// button and menu entry jam with its refusal.
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
    HoldPlan<SelectableIdentifier>.all(
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
      work: _unbindAll,
      heldBack: (ref, target) => heldBackReason(
        name: _nameOf(ref, target),
        noun: "service",
        done: "unbound",
      ),
    ),
  );

  static String? _nameOf(WidgetRef ref, SelectableIdentifier id) => ref
      .read(selectedProvider)
      .value
      ?.firstWhereOrNull((selectable) => selectable.id == id)
      ?.name;

  /// Unbinds the captured items one batch per owner. Each unbound batch
  /// leaves the selection; a refused batch names its refused items.
  static Future<void> _unbindAll(
    WidgetRef ref,
    Set<SelectableIdentifier> ids,
  ) async {
    final selection = ref.read(selectedProvider).value ?? const [];
    final batches = <UnbindBatch, List<(SelectableIdentifier, Object)>>{};
    for (final (selectable, capability)
        in selection
            .where((selectable) => ids.contains(selectable.id))
            .collectCapabilitiesWithSelectables<UnbindSelectionCapability>()) {
      batches.putIfAbsent(capability.batch, () => []).add((
        selectable.id,
        capability.target,
      ));
    }
    for (final MapEntry(key: batch, value: members) in batches.entries) {
      try {
        await batch.unbind(members.map((member) => member.$2).toSet().toList());
      } on RefusedTargets catch (refused) {
        throw RefusedTargets(refused.reason, {
          for (final (id, target) in members)
            if (refused.targets.contains(target)) id,
        });
      }
      if (ref.context.mounted) {
        ref.read(selectionProvider.notifier).unselectAll([
          for (final (id, _) in members) id,
        ]);
      }
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
