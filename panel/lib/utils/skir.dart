import "package:flutter/material.dart";
import "package:typewriter_panel/skir.dart" as skir;

extension SkirColorExtension on skir.Color {
  Color toFlutterColor() {
    return Color(argb);
  }
}

extension FlutterColorExtension on Color {
  skir.Color toSkirColor() {
    return skir.Color(argb: toARGB32());
  }
}

extension RecordIdExtension on skir.RecordId {
  String get id => key.toString();
}
