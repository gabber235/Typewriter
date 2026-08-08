import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  testWidgets("rebuilds when the refresh date is reached", (tester) async {
    final refreshAt = DateTime.now().add(const Duration(seconds: 2));

    await tester.pumpWidget(_RefreshAtHarness(refreshAt: refreshAt));
    expect(find.text("1"), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text("1"), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text("2"), findsOneWidget);
  });

  testWidgets("reschedules when the refresh date changes", (tester) async {
    final refreshAt = ValueNotifier(
      DateTime.now().add(const Duration(seconds: 2)),
    );
    addTearDown(refreshAt.dispose);

    await tester.pumpWidget(_RefreshAtListenableHarness(refreshAt: refreshAt));
    expect(find.text("1"), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    refreshAt.value = DateTime.now().add(const Duration(seconds: 3));
    await tester.pump();
    expect(find.text("2"), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text("2"), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    expect(find.text("3"), findsOneWidget);
  });

  testWidgets("does nothing for a date that has already passed", (
    tester,
  ) async {
    final refreshAt = DateTime.now().subtract(const Duration(seconds: 1));

    await tester.pumpWidget(_RefreshAtHarness(refreshAt: refreshAt));
    expect(find.text("1"), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text("1"), findsOneWidget);
  });

  testWidgets("does nothing for the current date", (tester) async {
    final refreshAt = DateTime.now();

    await tester.pumpWidget(_RefreshAtHarness(refreshAt: refreshAt));
    expect(find.text("1"), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text("1"), findsOneWidget);
  });

  testWidgets("cancels a refresh changed to a past date", (tester) async {
    final refreshAt = ValueNotifier(
      DateTime.now().add(const Duration(seconds: 2)),
    );
    addTearDown(refreshAt.dispose);

    await tester.pumpWidget(_RefreshAtListenableHarness(refreshAt: refreshAt));
    await tester.pump(const Duration(seconds: 1));

    refreshAt.value = DateTime.now().subtract(const Duration(seconds: 1));
    await tester.pump();
    expect(find.text("2"), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    expect(find.text("2"), findsOneWidget);
  });
}

class _RefreshAtHarness extends HookWidget {
  const _RefreshAtHarness({required this.refreshAt});

  final DateTime refreshAt;

  @override
  Widget build(BuildContext context) {
    final buildCount = useRef(0);
    buildCount.value++;
    useRefreshAt(refreshAt);
    return Text("${buildCount.value}", textDirection: TextDirection.ltr);
  }
}

class _RefreshAtListenableHarness extends HookWidget {
  const _RefreshAtListenableHarness({required this.refreshAt});

  final ValueNotifier<DateTime> refreshAt;

  @override
  Widget build(BuildContext context) {
    return _RefreshAtHarness(refreshAt: useValueListenable(refreshAt));
  }
}
