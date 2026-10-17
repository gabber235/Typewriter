import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../../../../../../../../../../../support/test_utils.dart";

void main() {
  testWidgets("does not register realm mode shortcuts while suspended", (
    tester,
  ) async {
    await tester.pumpTestApp(
      overrides: [
        realmIdProvider.overrideWithValue(skir.recordId("service:test")),
        realmConnectionProvider.overrideWith(
          (ref) => Future.value(RealmConnectionState.offline),
        ),
      ],
      child: const SizedBox(
        width: 200,
        height: 100,
        child: TextField(autofocus: true),
      ),
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(TextField)),
    );
    container
        .read(currentInteractionModeProvider.notifier)
        .setMode(_ShortcutMode());
    await tester.pumpAndSettle();

    expect(
      container.read(actionShortcutsProvider),
      isNot(contains("realm_test_action")),
    );
  });

  testWidgets("registers realm mode shortcuts while online", (tester) async {
    await tester.pumpTestApp(
      overrides: [
        realmIdProvider.overrideWithValue(skir.recordId("service:test")),
        realmConnectionProvider.overrideWith(
          (ref) => Future.value(RealmConnectionState.online),
        ),
      ],
      child: const SizedBox(
        width: 200,
        height: 100,
        child: TextField(autofocus: true),
      ),
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(TextField)),
    );
    container
        .read(currentInteractionModeProvider.notifier)
        .setMode(_ShortcutMode());
    await tester.pumpAndSettle();

    expect(
      container.read(actionShortcutsProvider),
      contains("realm_test_action"),
    );
  });
}

class _ShortcutMode extends InteractionMode with ModeShortcut {
  @override
  String get name => "Realm test";

  @override
  List<ActionShortcut> getShortcuts() => [
    ActionShortcut(
      id: "realm_test_action",
      label: "Realm test action",
      description: "Test realm shortcut suspension",
      activators: [SingleActivator(LogicalKeyboardKey.keyR)],
      priority: 0,
      onInvoke: (_) {},
    ),
  ];
}
