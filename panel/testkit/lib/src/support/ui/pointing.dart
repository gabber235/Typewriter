import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/drivers/component_driver.dart";

/// Pointing at parts of a component the way a mouse user does.
extension Pointing on ComponentDriver {
  /// Moves a mouse onto [target] and lets the panel react.
  Future<void> hover(Finder target) async {
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(target));
    await settle();
  }

  /// Presses [target] down and holds it past the press timeout, so the
  /// press shows; the caller releases it.
  Future<TestGesture> pressDown(Finder target) async {
    final press = await tester.startGesture(tester.getCenter(target));
    await tester.pump(kPressTimeout);
    await tester.pump(const Duration(milliseconds: 100));
    return press;
  }

  /// Gives keyboard focus to the control that shows [label]; the label sits
  /// below the control's own Focus, so Focus.of finds that node.
  Future<void> focus(Finder label) async {
    Focus.of(tester.element(label)).requestFocus();
    await tester.pump();
  }

  /// The colour shown 4 px inside the left edge of the control around
  /// [label], halfway down: the face of a [ButtonContent] or the fill of a
  /// [SurfaceContainer], whichever is nearer.
  Future<Color> fillAt(Finder label) async {
    final control = find
        .ancestor(
          of: label,
          matching: find.byWidgetPredicate(
            (widget) => widget is ButtonContent || widget is SurfaceContainer,
          ),
        )
        .first;
    final rect = tester.getRect(control);
    var boundary = tester.renderObject(control);
    while (!boundary.isRepaintBoundary) {
      boundary = boundary.parent!;
    }
    final point = (boundary as RenderBox).globalToLocal(
      Offset(rect.left + 4, rect.center.dy),
    );
    final image = await tester.runAsync(
      () => captureImage(tester.element(control)),
    );
    final bytes = await tester.runAsync(
      () => image!.toByteData(format: ImageByteFormat.rawRgba),
    );
    final at = (point.dy.floor() * image!.width + point.dx.floor()) * 4;
    image.dispose();
    return Color.fromARGB(
      bytes!.getUint8(at + 3),
      bytes.getUint8(at),
      bytes.getUint8(at + 1),
      bytes.getUint8(at + 2),
    );
  }
}

/// The letters a [MotionLabel] shows on screen right now.
extension ShownLetters on WidgetTester {
  /// The letters of the one [MotionLabel] on screen, joined in order.
  String get visibleText => widgetList<Text>(
    find.descendant(of: find.byType(MotionLabel), matching: find.byType(Text)),
  ).map((text) => text.data ?? "").join();

  /// The letters of a [TypedParagraph] typed so far.
  String typedTextOf(Finder paragraph) {
    final text = widget<Text>(
      find.descendant(of: paragraph, matching: find.byType(Text)),
    );
    final typed = (text.textSpan! as TextSpan).children!.first;
    return typed.toPlainText();
  }
}
