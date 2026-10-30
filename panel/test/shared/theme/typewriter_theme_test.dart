import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  for (final brightness in Brightness.values) {
    group(brightness.name, () {
      late ThemeData theme;
      setUp(() => theme = buildTheme(brightness));

      test("semantic colors meet WCAG contrast", () {
        final c = theme.colors;
        final pairs = [
          (c.brand, c.onBrand),
          (c.brandContainer, c.onBrandContainer),
          (c.accent, c.onAccent),
          (c.info, c.onInfo),
          (c.success, c.onSuccess),
          (c.warning, c.onWarning),
          (c.danger, c.onDanger),
          (c.online, c.onOnline),
          (c.offline, c.onOffline),
        ];
        for (final (background, foreground) in pairs) {
          expect(
            wcagContrast(background, foreground),
            greaterThanOrEqualTo(4.5),
          );
        }
      });

      test("state precedence and disabled behavior are stable", () {
        final states = theme.states;
        final color = theme.colors.brand;
        expect(
          states.layer(color, {WidgetState.disabled, WidgetState.pressed}),
          isNull,
        );
        expect(
          states.layer(color, {WidgetState.pressed, WidgetState.focused}),
          color.withValues(alpha: states.pressedOpacity),
        );
        expect(
          states.layer(color, {WidgetState.dragged, WidgetState.focused}),
          color.withValues(alpha: states.draggedOpacity),
        );
        expect(
          states.layer(color, {WidgetState.focused, WidgetState.hovered}),
          states.focusRing.withValues(alpha: states.focusOpacity),
        );
      });
    });
  }
}
