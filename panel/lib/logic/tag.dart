import "package:flutter/material.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:typewriter_panel/utils/color_converter.dart";

part "tag.freezed.dart";
part "tag.g.dart";

@freezed
abstract class Tag with _$Tag {
  const factory Tag({
    required String id,
    required String name,
    @ColorConverter() @Default(Colors.redAccent) Color color,
    @Default([]) List<Tag> parents,
  }) = _Tag;

  factory Tag.fromJson(Map<String, dynamic> json) => _$TagFromJson(json);
}
