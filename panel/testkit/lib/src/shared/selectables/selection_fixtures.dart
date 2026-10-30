import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/core/stage.dart";
import "package:typewriter_testkit/src/core/pump_panel.dart";
import "package:typewriter_testkit/src/drivers/panel_driver.dart";

import "test_selectable.dart";

/// A target whose selectable stays loading until [resolve] runs, or stays
/// in whatever [result] the test assigns (for example an error).
final class DeferredSelectableIdentifier extends TestSelectableIdentifier {
  DeferredSelectableIdentifier({required super.id});

  /// The state reported until the target resolves.
  AsyncValue<Selectable> result = const AsyncLoading();

  bool _resolved = false;

  @override
  AsyncValue<Selectable> create(Ref ref) =>
      _resolved ? super.create(ref) : result;

  /// Lets the target resolve and cancels nothing: the panel decides what a
  /// waiting menu does once the selection settles.
  void resolve(PanelDriver panel) {
    _resolved = true;
    panel.container.invalidate(selectedProvider);
  }
}

/// A selection operation that records each run with the resolved targets
/// and can be made unavailable by the test.
final class RecordingSelectionOperation extends SelectionOperation {
  final executions = <List<SelectableIdentifier>>[];
  bool available = true;

  @override
  String get name => "Record selection";

  @override
  String get description => "Record the resolved action targets";

  @override
  bool canExecuteOn(List<Selectable> selection) =>
      available && selection.isNotEmpty;

  @override
  void executeOn(WidgetRef ref) {
    executions.add(
      ref.read(selectedProvider).requireValue.map((item) => item.id).toList(),
    );
  }

  @override
  MenuItem menuItem(WidgetRef ref) =>
      MenuItem(label: name, onPressed: () => executeOn(ref));

  @override
  Widget inspectorButton(List<Selectable> selection) => const SizedBox.shrink();
}

/// A selectable card offering one recorded action, as features build them.
final class SelectionCard extends HookWidget {
  SelectionCard(this.target, {this.moveOnSelection = false, super.key});

  final TestSelectableIdentifier target;
  final bool moveOnSelection;
  final operation = RecordingSelectionOperation();

  /// Whether the card's actions are registered.
  final actionsEnabled = ValueNotifier(true);

  @override
  Widget build(BuildContext context) {
    final focus = useFocusNode();
    useEffect(() => actionsEnabled.dispose, const []);
    return Consumer(
      builder: (context, ref, _) {
        final selected = ref.watch(isSelectedProvider(target));
        return ValueListenableBuilder(
          valueListenable: actionsEnabled,
          builder: (context, enabled, _) => SelectionOperationsRoot(
            source: RegisteredSelectionOperations([if (enabled) operation]),
            child: Align(
              alignment: moveOnSelection && selected
                  ? Alignment.centerRight
                  : Alignment.center,
              child: Selector(
                selectableId: target,
                focusNode: focus,
                builder: (selected, focused, hovered) => const SizedBox(
                  width: 180,
                  height: 80,
                  child: Text("Target"),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// An activator operation that counts its runs; the shortcut tests bind it
/// to a key and read [executions] afterwards.
final class RecordingShortcutOperation extends ActivatorShortcutOperation {
  int executions = 0;

  @override
  List<ShortcutActivator> get activators => const [
    SingleActivator(LogicalKeyboardKey.keyR),
  ];

  @override
  String get name => "Record";

  @override
  String get description => "Record a run";

  @override
  bool canExecuteOn(List<Selectable> selection) => selection.isNotEmpty;

  @override
  void executeOn(WidgetRef ref) => executions++;

  @override
  Widget inspectorButton(List<Selectable> selection) => const SizedBox.shrink();

  @override
  MenuItem menuItem(WidgetRef ref) =>
      MenuItem(label: name, onPressed: () => executeOn(ref));
}

/// A selectable whose only capability deletes it, counting nothing itself:
/// the test passes the callback that records the deletion.
final class DeletableSelectableIdentifier extends SelectableIdentifier {
  DeletableSelectableIdentifier(this.onDelete);

  final VoidCallback onDelete;

  @override
  String get id => "deletable";

  @override
  AsyncValue<Selectable> create(Ref ref) =>
      AsyncData(DeletableSelectable(this));
}

/// The selectable a [DeletableSelectableIdentifier] resolves to.
final class DeletableSelectable
    extends Selectable<DeletableSelectableIdentifier> {
  const DeletableSelectable(this.id);

  @override
  final DeletableSelectableIdentifier id;

  @override
  String get name => id.id;

  @override
  List<SelectionCapability> get capabilities => [
    DeleteSelectionCapability(onDelete: id.onDelete),
  ];
}

/// A shortcut operation whose activators are supplied by the test.
final class ShortcutTestOperation extends ActivatorShortcutOperation {
  const ShortcutTestOperation({required this.activators});

  @override
  final List<ShortcutActivator> activators;

  @override
  String get name => "Run";

  @override
  String get description => "Run the test operation";

  @override
  bool canExecuteOn(List<Selectable> selection) => true;

  @override
  FutureOr<void> executeOn(WidgetRef ref) {}

  @override
  Widget inspectorButton(List<Selectable> selection) =>
      throw UnimplementedError();

  @override
  MenuItem menuItem(WidgetRef ref) => throw UnimplementedError();
}

/// Mounts a button that runs [operation] on a selection holding
/// [identifier], the way an inspector or menu invokes it.
extension DeletionButtonPump on WidgetTester {
  Future<PanelDriver> pumpDeletion(
    DeleteOperation operation,
    SelectableIdentifier identifier,
  ) async {
    final panel = await pumpPanel(
      const [],
      at: PanelLocation.component(
        Consumer(
          builder: (context, ref, _) => TextButton(
            onPressed: () => operation.executeOn(ref),
            child: const Text("Invoke deletion"),
          ),
        ),
      ),
    );
    panel.container.read(selectionProvider.notifier).selectAll([identifier]);
    await panel.settle();
    return panel;
  }
}

/// A selectable that never finishes loading, for targets that stay pending.
final class LoadingSelectableIdentifier extends SelectableIdentifier {
  const LoadingSelectableIdentifier(this.id);

  @override
  final String id;

  @override
  AsyncValue<Selectable> create(Ref ref) => const AsyncLoading();
}
