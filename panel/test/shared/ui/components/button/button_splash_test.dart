import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets("a held press splashes from where it was pressed and the "
      "splash stays full while held", (tester) async {
    var presses = 0;
    await tester.showComponent(
      busyButton(ButtonFace.quiet, label: "Copy", onPressed: () => presses++),
    );
    final button = find.byType(Button);
    final corner = tester.getTopLeft(button) + const Offset(6, 6);

    final gesture = await tester.startGesture(corner);
    // A held pointer counts as a press once the tap timeout passed.
    await tester.pump(kPressTimeout);
    await tester.pump(tester.settleTimeOf(MotionToken.splash));
    await tester.pump();

    final ink = tester.inkOf(button)!;
    expect(ink.center, corner - tester.getTopLeft(button));
    expect(ink.grown, 1);
    expect(presses, 0);
    await gesture.up();
  });

  testWidgets("letting go inside acts and the splash drains", (tester) async {
    var presses = 0;
    final panel = await tester.showComponent(
      busyButton(ButtonFace.quiet, label: "Copy", onPressed: () => presses++),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(Button)),
    );
    await tester.pump(tester.settleTimeOf(MotionToken.splash));
    await gesture.up();
    await panel.settle();

    expect(presses, 1);
    expect(tester.inkOf(find.byType(Button)), isNull);
  });

  testWidgets("sliding off while held cancels: nothing happens and the "
      "splash drains", (tester) async {
    var presses = 0;
    final panel = await tester.showComponent(
      busyButton(ButtonFace.quiet, label: "Copy", onPressed: () => presses++),
    );
    final rect = tester.getRect(find.byType(Button));

    final gesture = await tester.startGesture(rect.center);
    await tester.pump(tester.settleTimeOf(MotionToken.splash));
    await gesture.moveTo(rect.bottomRight + const Offset(80, 80));
    await gesture.up();
    await panel.settle();

    expect(presses, 0);
    expect(tester.inkOf(find.byType(Button)), isNull);
  });

  testWidgets("Space held splashes from the middle and acts only when let "
      "go", (tester) async {
    var presses = 0;
    final panel = await tester.showComponent(
      Button(label: "Copy", autofocus: true, onPressed: () => presses++),
    );

    await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
    await tester.pump(tester.settleTimeOf(MotionToken.splash));
    final size = tester.getSize(find.byType(Button));
    expect(tester.inkOf(find.byType(Button))!.center, size.center(Offset.zero));
    expect(presses, 0);

    await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
    await panel.settle();
    expect(presses, 1);
  });

  testWidgets("Escape while a key is held cancels the press", (tester) async {
    var presses = 0;
    final panel = await tester.showComponent(
      Button(label: "Copy", autofocus: true, onPressed: () => presses++),
    );

    await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
    await panel.settle();

    expect(presses, 0);
    expect(tester.inkOf(find.byType(Button)), isNull);
  });

  for (final (face, light) in [
    (ButtonFace.quiet, false),
    (ButtonFace.outlined, false),
    (ButtonFace.filled, true),
  ]) {
    testWidgets("a ${face.name} button's splash is "
        "${light ? "its label colour on the fill" : "the brand colour"}", (
      tester,
    ) async {
      await tester.showComponent(
        busyButton(face, label: "Publish", onPressed: () {}),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(Button)),
      );
      await tester.pump(tester.settleTimeOf(MotionToken.splash));

      final ink = tester.inkOf(find.byType(Button))!;
      final context = tester.element(find.byType(Button));
      final brand = context.colors.brand;
      expect(
        ink.color.withValues(alpha: 1).toARGB32(),
        (light ? brand.on(context) : brand).toARGB32(),
      );
      await gesture.up();
    });
  }

  testWidgets("with reduced motion a press shows no splash", (tester) async {
    await tester.showComponent(
      ReducedMotion(
        child: busyButton(ButtonFace.quiet, label: "Copy", onPressed: () {}),
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(Button)),
    );
    await tester.pump(tester.settleTimeOf(MotionToken.splash));

    expect(tester.inkOf(find.byType(Button)), isNull);
    await gesture.up();
  });
}
