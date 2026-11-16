import "package:typewriter_panel/typewriter_panel.dart";

/// How a test names [key] pressed with Shift held when [shifted], such as
/// `Shift+Delete`.
String keyName(LogicalKeyboardKey key, {bool shifted = false}) =>
    "${shifted ? "Shift+" : ""}${key.keyLabel}";
