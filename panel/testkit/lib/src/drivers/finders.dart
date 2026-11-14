import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

/// Finders for the panel's own widgets that `flutter_test` cannot see.
extension PanelFinders on CommonFinders {
  /// The tooltip whose message matches [message].
  ///
  /// `find.byTooltip` only knows the tooltip of `package:flutter/material`,
  /// so it misses [PanelTooltip]. This finder reads the message itself, from
  /// a [PanelTooltip] or from a [Button] that shows one.
  Finder tooltip(Pattern message, {bool skipOffstage = true}) =>
      byWidgetPredicate((widget) {
        final text = switch (widget) {
          PanelTooltip(:final message) => message,
          Button(:final tooltip?) => tooltip,
          _ => null,
        };
        if (text == null) return false;
        return message is RegExp ? message.hasMatch(text) : text == message;
      }, skipOffstage: skipOffstage);
}
