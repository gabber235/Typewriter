import "package:flutter/material.dart" show Color;
import "package:typewriter_panel/generated/models/common.pb.dart" as proto;

/// Extension on uint32 (int) to convert to/from Flutter Color
extension ColorIntExtension on int {
  /// Convert uint32 to Flutter Color
  Color toFlutterColor() {
    return Color(this);
  }
}

/// Extension on Flutter Color to convert to/from uint32
extension FlutterColorExtension on Color {
  /// Convert Flutter Color to uint32
  int toUint32() {
    return toARGB32();
  }

  proto.Color toProtoColor() {
    return proto.Color()..value = toUint32();
  }
}

/// Extension on proto Color message to convert to/from Flutter Color
extension ProtoColorExtension on proto.Color {
  /// Convert proto Color to Flutter Color
  Color toFlutterColor() {
    return Color(value);
  }
}
