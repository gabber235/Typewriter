import "package:flutter/material.dart";
import "package:iconify_flutter_plus/icons/fa6_solid.dart";
import "package:iconify_flutter_plus/icons/icon_park_solid.dart";
import "package:iconify_flutter_plus/icons/ph.dart";
import "package:typewriter_panel/typewriter_panel.dart";

extension PageTypeExtensions on PageType {
  /// The tag string used for matching blueprint tags
  String get tag => switch (this) {
    PageType.sequence => "trigger",
    PageType.static => "static",
    PageType.scene => "scene",
    PageType.manifest => "manifest",
  };

  /// List of linking tags for this page type
  List<String> get linkingTags => switch (this) {
    PageType.sequence => ["triggerable"],
    PageType.static => [],
    PageType.scene => [],
    PageType.manifest => ["manifest", "audience"],
  };

  /// Icon identifier string for this page type
  String get icon => switch (this) {
    PageType.sequence => Fa6Solid.diagram_project,
    PageType.static => Ph.push_pin_fill,
    PageType.scene => Fa6Solid.film,
    PageType.manifest => IconParkSolid.chart_graph,
  };

  /// Display color for this page type
  Color get color => switch (this) {
    PageType.sequence => Colors.blue,
    PageType.static => Colors.deepPurple,
    PageType.scene => Colors.orange,
    PageType.manifest => Colors.green,
  };

  /// Graph direction for this page type, null if not applicable
  GraphDirection? get direction => switch (this) {
    PageType.static => GraphDirection.bottomToTop,
    PageType.sequence => GraphDirection.leftToRight,
    PageType.manifest => GraphDirection.topToBottom,
    PageType.scene => null,
  };

  /// Display name for this page type
  String get displayName => switch (this) {
    PageType.sequence => "sequence",
    PageType.static => "static",
    PageType.scene => "scene",
    PageType.manifest => "manifest",
  };
}
