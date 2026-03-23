import "package:flutter/material.dart";
import "package:json_annotation/json_annotation.dart";

class NullableRectConverter
    extends JsonConverter<Rect?, Map<String, dynamic>?> {
  const NullableRectConverter();

  @override
  Rect? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;

    final left = _readCoordinate(json, "left");
    final top = _readCoordinate(json, "top");
    final right = _readCoordinate(json, "right");
    final bottom = _readCoordinate(json, "bottom");

    return Rect.fromLTRB(left, top, right, bottom);
  }

  @override
  Map<String, dynamic>? toJson(Rect? object) {
    if (object == null) return null;

    return {
      "left": object.left,
      "top": object.top,
      "right": object.right,
      "bottom": object.bottom,
    };
  }
}

class RectConverter extends JsonConverter<Rect, Map<String, dynamic>> {
  const RectConverter();

  @override
  Rect fromJson(Map<String, dynamic> json) {
    return const NullableRectConverter().fromJson(json)!;
  }

  @override
  Map<String, dynamic> toJson(Rect object) {
    return const NullableRectConverter().toJson(object)!;
  }
}

double _readCoordinate(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is num) return value.toDouble();
  throw const FormatException("Unsupported_Json_Value");
}
