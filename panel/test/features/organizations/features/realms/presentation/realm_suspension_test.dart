import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../../../support/test_utils.dart";

void main() {
  testWidgets("blocks interaction and exposes retry while unavailable", (
    tester,
  ) async {
    var childTaps = 0;
    var retries = 0;
    await tester.pumpTestApp(
      child: SizedBox(
        width: 800,
        height: 600,
        child: RealmSuspensionBarrier(
          interaction: const RealmInteractionState(
            connectionState: RealmConnectionState.unavailable,
          ),
          onRetry: () => retries++,
          child: FilledButton(
            onPressed: () => childTaps++,
            child: const Text("Change realm"),
          ),
        ),
      ),
    );

    await tester.tap(find.text("Change realm"), warnIfMissed: false);
    expect(childTaps, 0);
    expect(find.text("Realm unavailable"), findsOneWidget);

    await tester.tap(find.text("Check again"));
    expect(retries, 1);
  });

  testWidgets("removes focus while suspended", (tester) async {
    final connection = ValueNotifier(RealmConnectionState.online);
    addTearDown(connection.dispose);
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    await tester.pumpTestApp(
      child: SizedBox(
        width: 800,
        height: 600,
        child: ValueListenableBuilder(
          valueListenable: connection,
          builder: (context, state, child) => RealmSuspensionBarrier(
            interaction: RealmInteractionState(connectionState: state),
            child: child!,
          ),
          child: TextField(focusNode: focusNode),
        ),
      ),
    );

    await tester.tap(find.byType(TextField));
    expect(focusNode.hasFocus, isTrue);

    connection.value = RealmConnectionState.offline;
    await tester.pumpAndSettle();

    expect(focusNode.hasFocus, isFalse);
  });

  testWidgets("preserves child state and resumes interaction", (tester) async {
    final connection = ValueNotifier(RealmConnectionState.online);
    addTearDown(connection.dispose);

    await tester.pumpTestApp(
      child: SizedBox(
        width: 800,
        height: 600,
        child: ValueListenableBuilder(
          valueListenable: connection,
          builder: (context, state, child) => RealmSuspensionBarrier(
            interaction: RealmInteractionState(connectionState: state),
            child: child!,
          ),
          child: const _Counter(),
        ),
      ),
    );

    await tester.tap(find.text("Count 0"));
    await tester.pump();
    expect(find.text("Count 1"), findsOneWidget);

    connection.value = RealmConnectionState.offline;
    await tester.pumpAndSettle();
    expect(find.text("Realm connection lost"), findsOneWidget);

    await tester.tap(find.text("Count 1"), warnIfMissed: false);
    expect(find.text("Count 1"), findsOneWidget);

    connection.value = RealmConnectionState.online;
    await tester.pumpAndSettle();
    await tester.tap(find.text("Count 1"));
    await tester.pump();

    expect(find.text("Count 2"), findsOneWidget);
  });

  testWidgets("shows offline realm details", (tester) async {
    final realm = Service(
      serviceId: recordId("service:test"),
      revision: 1,
      name: "story_realm",
      role: CustomServiceRole(name: "realm", version: "1"),
      createdAt: DateTime.utc(2026),
      state: ServiceState(
        status: ServiceStateStatus.offline,
        lastSeen: DateTime.now().subtract(const Duration(minutes: 4)),
      ),
    );

    await tester.pumpTestApp(
      child: SizedBox(
        width: 800,
        height: 600,
        child: RealmSuspensionBarrier(
          interaction: const RealmInteractionState(
            connectionState: RealmConnectionState.offline,
          ),
          realm: realm,
          child: const ColoredBox(color: Colors.blue),
        ),
      ),
    );

    expect(find.text("Realm connection lost"), findsOneWidget);
    expect(
      find.textContaining("Changes to 'Story Realm' are paused"),
      findsOneWidget,
    );
    expect(find.text("4m ago"), findsOneWidget);
  });
}

class _Counter extends StatefulWidget {
  const _Counter();

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int count = 0;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: () => setState(() => count++),
      child: Text("Count $count"),
    );
  }
}
