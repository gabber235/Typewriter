import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/core/trait.dart";
import "package:typewriter_testkit/src/core/world.dart";

/// The window of a tablet, where the panel collapses its side panels.
const compactWindow = Size(800, 1000);

/// The panel renders in a compact window.
const Trait compact = _Window(compactWindow, "compact");

/// The panel renders in a window of [size].
Trait window(Size size) => _Window(size, "window($size)");

final class _Window extends Trait {
  const _Window(this.size, this.description);

  final Size size;

  @override
  final String description;

  @override
  Slot get slot => Slot.window;

  @override
  void applyTo(WorldBuilder world) => world.window = size;
}

/// The user chose the dark theme.
const Trait dark = _Appearance(ThemeMode.dark);

final class _Appearance extends Trait {
  const _Appearance(this.mode);

  final ThemeMode mode;

  @override
  Slot get slot => Slot.appearance;

  @override
  String get description => "appearance(${mode.name})";

  @override
  void applyTo(WorldBuilder world) => world.themeMode = mode;
}
