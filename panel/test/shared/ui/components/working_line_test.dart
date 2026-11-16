import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  const line = SizedBox(width: 200, child: WorkingLine(label: "Searching"));

  testWidgets("a working line is a thin line across its parent, heard by its "
      "label", (tester) async {
    await tester.mountComponent(line);
    await tester.pump();

    expect(tester.getSize(find.byType(WorkingLine)), const Size(200, 2));
    expect(find.bySemanticsLabel("Searching"), findsOneWidget);
  });

  testWidgets("a working line sweeps while the work runs", (tester) async {
    await tester.mountComponent(line);
    await tester.pump();
    final first = tester.workingLineSweep;
    await tester.pump(tester.settleTimeOf(MotionToken.skeleton) ~/ 4);

    expect(tester.workingLineSweep, isNot(first));
  });

  testWidgets("with reduced motion a working line stands still", (
    tester,
  ) async {
    await tester.mountComponent(const ReducedMotion(child: line));
    await tester.pump();
    final first = tester.workingLineSweep;
    await tester.pump(tester.settleTimeOf(MotionToken.skeleton));

    expect(tester.workingLineSweep, first);
    expect(tester.hasRunningAnimations, isFalse);
  });
}
