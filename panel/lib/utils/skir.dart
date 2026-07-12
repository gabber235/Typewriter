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

skir.RecordId recordId(String id) {
  final parts = id.split(":");
  assert(parts.length == 2, "id must be of format `<table>:<id>`");
  return skir.RecordId(
    table: parts[0],
    key: skir.RecordIdKey.wrapString(parts[1]),
  );
}
