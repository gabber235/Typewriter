import "package:typewriter_panel/typewriter_panel.dart";

part "mode_display.freezed.dart";

/// How a mode shows itself in the app bar chip.
///
/// A resting mode is [soft]: a pale fill and no icon. An active mode gets a
/// bold fill in its [tone] and an [icon], so modes never differ by colour
/// alone.
@freezed
abstract class ModeLook with _$ModeLook {
  const factory ModeLook({
    /// The mode's name, shown in capitals.
    required String label,

    /// The hue of the fill; the text takes the tone that reads on it.
    required Color tone,

    /// Shown before the label; an active mode has one.
    IconData? icon,

    /// A pale fill for the resting mode instead of a bold one.
    @Default(false) bool soft,
  }) = _ModeLook;

  /// Moving what is selected, such as graph nodes or timeline cues.
  static ModeLook move(BuildContext context) => ModeLook(
    label: "Move",
    tone: context.colors.accent,
    icon: Icons.open_with_rounded,
  );

  /// Resizing what is selected, such as graph nodes or timeline cues.
  static ModeLook resize(BuildContext context) => ModeLook(
    label: "Resize",
    tone: context.colors.info,
    icon: Icons.open_in_full_rounded,
  );
}

/// Adds an app bar look to an [InteractionMode].
///
/// The app bar mode chip shows this look while the implementing mode is
/// current, and moves between looks when the mode changes.
mixin ModeDisplay on InteractionMode {
  /// The mode's look for [context]; it describes the mode and changes no
  /// state.
  ModeLook look(BuildContext context);
}
