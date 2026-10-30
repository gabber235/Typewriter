import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets("an offline Realm pauses its changes, names itself and tells "
      "when its host was last seen", (tester) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      realm(name: "Story Realm", books: [book("First")]),
      realmHostStopped,
    ]);

    await tester.pump(const Duration(minutes: 4));
    await panel.settle();

    expect(panel.shows("Realm connection lost"), isTrue);
    expect(
      find.textContaining("Changes to 'Story Realm' are paused"),
      findsOneWidget,
    );
    expect(panel.shows("4m ago"), isTrue);
    expect(panel.shows("Check again"), isTrue);
  });

  testWidgets("an unavailable Realm blocks its content and offers a retry", (
    tester,
  ) async {
    var changes = 0;
    var retries = 0;
    final panel = await tester.pumpPanel(
      const [],
      at: PanelLocation.component(
        SizedBox.fromSize(
          size: _workspace,
          child: RealmSuspensionBarrier(
            interaction: const RealmInteractionState(
              connectionState: RealmConnectionState.unavailable,
            ),
            onRetry: () => retries++,
            child: FilledButton(
              onPressed: () => changes++,
              child: const Text("Change realm"),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text("Change realm"), warnIfMissed: false);
    await panel.settle();
    expect(changes, 0);
    expect(panel.shows("Realm unavailable"), isTrue);

    await panel.tapOn(find.text("Check again"));
    expect(retries, 1);
  });

  testWidgets("suspending a Realm takes focus away from its fields", (
    tester,
  ) async {
    final (:panel, :connection) = await tester.pumpSuspendable(
      const TextField(decoration: InputDecoration(labelText: "Name")),
      size: _workspace,
    );

    await panel.field("Name").focus();
    expect(panel.field("Name").isFocused, isTrue);

    connection.value = RealmConnectionState.offline;
    await panel.settle();

    expect(panel.hasFocusOn("Name"), isFalse);
  });

  testWidgets("a suspended Realm keeps its content and resumes where it was", (
    tester,
  ) async {
    final (:panel, :connection) = await tester.pumpSuspendable(
      const CountingButton(),
      size: _workspace,
    );

    await panel.tapOn(find.text("Count 0"));
    expect(panel.shows("Count 1"), isTrue);

    connection.value = RealmConnectionState.offline;
    await panel.settle();
    expect(panel.shows("Realm connection lost"), isTrue);

    await tester.tap(find.text("Count 1"), warnIfMissed: false);
    await panel.settle();
    expect(panel.shows("Count 1"), isTrue);

    connection.value = RealmConnectionState.online;
    await panel.settle();
    await panel.tapOn(find.text("Count 1"));

    expect(panel.shows("Count 2"), isTrue);
  });
}

/// The area a Realm workspace fills, so the veil has room to explain itself.
const _workspace = Size(800, 600);
