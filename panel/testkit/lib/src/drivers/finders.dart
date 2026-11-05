import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

/// Finders for the panel's own widgets that `flutter_test` cannot see.
extension PanelFinders on CommonFinders {
  /// The tooltip whose message matches [message].
  ///
  /// `find.byTooltip` only knows the tooltip of `package:flutter/material`.
  /// The panel uses `package:material_ui`, whose tooltips `find.byTooltip`
  /// reaches through semantics alone, so it misses a tooltip that excludes
  /// itself from semantics. This finder reads the message itself.
  Finder tooltip(Pattern message, {bool skipOffstage = true}) =>
      byWidgetPredicate((widget) {
        final text = switch (widget) {
          Tooltip(message: final String plain) => plain,
          Tooltip(:final richMessage?) => richMessage.toPlainText(),
          _ => null,
        };
        if (text == null) return false;
        return message is RegExp ? message.hasMatch(text) : text == message;
      }, skipOffstage: skipOffstage);
}
