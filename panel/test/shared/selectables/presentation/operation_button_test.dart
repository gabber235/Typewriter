import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../support/test_utils.dart";

void main() {
  const foregroundColor = Color(0xFF123456);

  testWidgets("delete operation denies invocation when mutation is disabled", (
    tester,
  ) async {
    var deletions = 0;
    final identifier = _DeleteIdentifier(() => deletions++);
    final operation = DeleteOperation(canMutate: () => false);
    final container = await _pumpDeleteOperation(tester, operation, identifier);

    expect(operation.canExecuteOn([_DeleteSelectable(identifier)]), isFalse);
    await tester.tap(find.text("Invoke deletion"));
    await tester.pumpAndSettle();

    expect(find.byType(ConfirmationDialogue), findsNothing);
    expect(deletions, 0);
    expect(container.read(selectionProvider), [identifier]);
  });

  testWidgets("delete operation rechecks access after confirmation", (
    tester,
  ) async {
    var allowed = true;
    var deletions = 0;
    final identifier = _DeleteIdentifier(() => deletions++);
    final operation = DeleteOperation(canMutate: () => allowed);
    final container = await _pumpDeleteOperation(tester, operation, identifier);

    await tester.tap(find.text("Invoke deletion"));
    await tester.pumpAndSettle();
    expect(find.byType(ConfirmationDialogue), findsOneWidget);
    allowed = false;
    await tester.tap(find.widgetWithText(FilledButton, "Delete"));
    await tester.pumpAndSettle();

    expect(deletions, 0);
    expect(container.read(selectionProvider), [identifier]);
    expect(find.byType(ConfirmationDialogue), findsNothing);
  });

  testWidgets("ordinary delete operation deletes and clears its selection", (
    tester,
  ) async {
    var deletions = 0;
    final identifier = _DeleteIdentifier(() => deletions++);
    const operation = DeleteOperation();
    final container = await _pumpDeleteOperation(tester, operation, identifier);

    expect(operation.canExecuteOn([_DeleteSelectable(identifier)]), isTrue);
    await tester.tap(find.text("Invoke deletion"));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, "Delete"));
    await tester.pumpAndSettle();

    expect(deletions, 1);
    expect(container.read(selectionProvider), isEmpty);
  });

  testWidgets("filled button shows the operation shortcut", (tester) async {
    await tester.pumpTestApp(
      child: Center(
        child: OperationButton.filledIcon(
          operation: const _TestOperation(),
          icon: const Icon(Icons.bolt),
          label: const Text("Run"),
          onPressed: () {},
          style: const ButtonStyle(
            foregroundColor: WidgetStatePropertyAll(foregroundColor),
          ),
        ),
      ),
    );

    expect(find.byType(FilledButton), findsOneWidget);
    expect(find.byType(OutlinedButton), findsNothing);
    expect(_shortcutForegroundColor(tester), foregroundColor);
  });

  testWidgets("outlined button shows the operation shortcut", (tester) async {
    await tester.pumpTestApp(
      child: Center(
        child: OperationButton.outlinedIcon(
          operation: const _TestOperation(),
          icon: const Icon(Icons.bolt),
          label: const Text("Run"),
          onPressed: () {},
          style: const ButtonStyle(
            foregroundColor: WidgetStatePropertyAll(foregroundColor),
          ),
        ),
      ),
    );

    expect(find.byType(OutlinedButton), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
    expect(_shortcutForegroundColor(tester), foregroundColor);
  });

  testWidgets("button omits unavailable shortcuts", (tester) async {
    await tester.pumpTestApp(
      child: Center(
        child: OperationButton.filledIcon(
          operation: const _TestOperation(activators: []),
          icon: const Icon(Icons.bolt),
          label: const Text("Run"),
          onPressed: () {},
        ),
      ),
    );

    expect(find.byType(ShortcutDisplay), findsNothing);
  });

  testWidgets("narrow button keeps its shortcut without overflowing", (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpTestApp(
      child: SizedBox(
        width: 150,
        child: OperationButton.filledIcon(
          operation: const _TestOperation(),
          icon: const Icon(Icons.bolt),
          label: const Text("Run this operation with a long label"),
          onPressed: () {},
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(ShortcutDisplay), findsOneWidget);
    expect(find.text("Run this operation with a long label"), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp("^Run this operation with a long label")),
      findsOneWidget,
    );
    semantics.dispose();
  });
}

Future<ProviderContainer> _pumpDeleteOperation(
  WidgetTester tester,
  DeleteOperation operation,
  _DeleteIdentifier identifier,
) async {
  await tester.pumpTestApp(
    child: Consumer(
      builder: (context, ref, _) => Center(
        child: TextButton(
          onPressed: () => operation.executeOn(ref),
          child: const Text("Invoke deletion"),
        ),
      ),
    ),
  );
  final container = tester.container(of: find.text("Invoke deletion"));
  container.read(selectionProvider.notifier).selectAll([identifier]);
  await tester.pumpAndSettle();
  return container;
}

class _DeleteIdentifier extends SelectableIdentifier {
  const _DeleteIdentifier(this.onDelete);

  final VoidCallback onDelete;

  @override
  String get id => "deletable";

  @override
  AsyncValue<Selectable> create(Ref ref) => AsyncData(_DeleteSelectable(this));
}

class _DeleteSelectable extends Selectable<_DeleteIdentifier> {
  const _DeleteSelectable(this.id);

  @override
  final _DeleteIdentifier id;

  @override
  String get name => id.id;

  @override
  List<SelectionCapability> get capabilities => [
    DeleteSelectionCapability(onDelete: id.onDelete),
  ];
}

Color? _shortcutForegroundColor(WidgetTester tester) {
  final display = tester.widget<ShortcutDisplay>(find.byType(ShortcutDisplay));
  return switch (display.style) {
    OutlineKeyStyle(:final foregroundColor) => foregroundColor,
    SolidKeyStyle() => null,
  };
}

class _TestOperation extends ActivatorShortcutOperation {
  const _TestOperation({
    this.activators = const [SingleActivator(LogicalKeyboardKey.keyR)],
  });

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
