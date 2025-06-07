import "package:flutter/material.dart";
import "package:json_annotation/json_annotation.dart";

class NullableColorConverter extends JsonConverter<Color?, String?> {
  const NullableColorConverter();

  @override
  Color? fromJson(String? json) {
    if (json == null) return null;
    var text = json.trim().replaceFirst("#", "");

    if (text.length == 3) {
      text = text[0] * 2 + text[1] * 2 + text[2] * 2;
    }

    if (text.length == 6 || text.length == 8) {
      var i = int.parse(text, radix: 16);

      if (text.length != 8) {
        i = 0xff000000 + i;
      }

      return Color(i);
    }

    throw const FormatException("Unsupported_Json_Value");
  }

  @override
  String? toJson(Color? object) {
    if (object == null) return null;

    // ignore: deprecated_member_use
    final hex = object.value.toRadixString(16).padLeft(8, "0");
    return "#$hex";
  }
}

class ColorConverter extends JsonConverter<Color, String> {
  const ColorConverter();

  @override
  Color fromJson(String json) {
    return const NullableColorConverter().fromJson(json)!;
  }

  @override
  String toJson(Color object) {
    return const NullableColorConverter().toJson(object)!;
  }
}
