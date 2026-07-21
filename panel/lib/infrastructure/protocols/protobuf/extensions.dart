import "package:flutter/material.dart" show Color;
import "package:protobuf/protobuf.dart";
import "package:protobuf/well_known_types/google/protobuf/timestamp.pb.dart";
import "package:typewriter_panel/infrastructure/protocols/protobuf/generated/models/common.pb.dart"
    as proto;
import "package:typewriter_panel/typewriter_panel.dart";

/// Extension on uint32 (int) to convert to/from Flutter Color
extension ColorIntExtension on int {
  /// Convert uint32 to Flutter Color
  Color toFlutterColor() {
    return Color(this);
  }
}

/// Extension on Flutter Color to convert to/from uint32
extension FlutterColorToProtoExtension on Color {
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

extension DateTimeExtension on DateTime {
  Timestamp toTimestamp() => Timestamp.fromDateTime(this);
}

extension GeneratedMessageJsonExtension on GeneratedMessage {
  Map<String, dynamic> toJsonMap() => stringMap(toProto3Json());
}
