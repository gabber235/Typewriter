import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../support/test_utils.dart";

void main() {
  testWidgets("solid style resolves explicit colors", (tester) async {
    const backgroundColor = Color(0xFF123456);
    const foregroundColor = Color(0xFFABCDEF);
    const shadowColor = Color(0xFF654321);

    await tester.pumpTestApp(
      child: const Center(
        child: ShortcutDisplay(
          shortcut: SingleActivator(LogicalKeyboardKey.keyA),
          style: KeyStyle.solid(
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            shadowColor: shadowColor,
          ),
        ),
      ),
    );

    final decoration = _keyDecoration(tester);
    final textStyle = _keyTextStyle(tester);

    expect(decoration.color, backgroundColor);
    expect(decoration.boxShadow!.single.color, shadowColor);
    expect(textStyle.color, foregroundColor);
  });

  testWidgets("outline style resolves explicit colors", (tester) async {
    const foregroundColor = Color(0xFFABCDEF);
    const borderColor = Color(0xFF123456);

    await tester.pumpTestApp(
      child: const Center(
        child: ShortcutDisplay(
          shortcut: SingleActivator(LogicalKeyboardKey.keyA),
          style: KeyStyle.outline(
            foregroundColor: foregroundColor,
            borderColor: borderColor,
          ),
        ),
      ),
    );

    final decoration = _keyDecoration(tester);
    final textStyle = _keyTextStyle(tester);

    expect(decoration.border, Border.all(color: borderColor));
    expect(textStyle.color, foregroundColor);
  });

  testWidgets("solid style infers omitted colors from the theme", (
    tester,
  ) async {
    await tester.pumpTestApp(
      child: const Center(
        child: ShortcutDisplay(
          shortcut: SingleActivator(LogicalKeyboardKey.keyA),
        ),
      ),
    );

    final context = tester.element(find.byType(ShortcutDisplay));
    final theme = Theme.of(context);
    final decoration = _keyDecoration(tester);
    final textStyle = _keyTextStyle(tester);

    expect(decoration.color, theme.colorScheme.surfaceContainerHighest);
    expect(decoration.boxShadow, isNotEmpty);
    expect(textStyle.color, theme.colorScheme.onSurface);
  });

  testWidgets("solid style infers colors around a custom background", (
    tester,
  ) async {
    const backgroundColor = Colors.black;

    await tester.pumpTestApp(
      child: const Center(
        child: ShortcutDisplay(
          shortcut: SingleActivator(LogicalKeyboardKey.keyA),
          style: KeyStyle.solid(backgroundColor: backgroundColor),
        ),
      ),
    );

    final context = tester.element(find.byType(ShortcutDisplay));
    final theme = Theme.of(context);
    final decoration = _keyDecoration(tester);
    final textStyle = _keyTextStyle(tester);

    expect(decoration.color, backgroundColor);
    expect(decoration.boxShadow, isNotEmpty);
    expect(textStyle.color, theme.colorScheme.surface);
  });

  testWidgets("rotating shortcuts preserve the supplied style", (tester) async {
    const style = KeyStyle.outline(borderColor: Color(0xFF123456));

    await tester.pumpTestApp(
      child: const Center(
        child: RotatingShortcuts(
          shortcuts: [SingleActivator(LogicalKeyboardKey.keyA)],
          style: style,
        ),
      ),
    );

    final shortcut = tester.widget<ShortcutDisplay>(
      find.byType(ShortcutDisplay),
    );
    expect(shortcut.style, style);
  });
}

BoxDecoration _keyDecoration(WidgetTester tester) {
  final container = tester.widget<AnimatedContainer>(
    find
        .descendant(
          of: find.byType(ShortcutDisplay),
          matching: find.byType(AnimatedContainer),
        )
        .first,
  );
  return container.decoration! as BoxDecoration;
}

TextStyle _keyTextStyle(WidgetTester tester) {
  final textStyle = tester.widget<DefaultTextStyle>(
    find
        .descendant(
          of: find.byType(ShortcutDisplay),
          matching: find.byType(DefaultTextStyle),
        )
        .first,
  );
  return textStyle.style;
}
