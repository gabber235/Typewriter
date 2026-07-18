import "package:flutter/material.dart";
import "package:iconify_flutter_plus/icons/fa6_solid.dart";
import "package:iconify_flutter_plus/icons/icon_park_solid.dart";
import "package:iconify_flutter_plus/icons/ph.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/domain/graph_direction.dart";
import "package:typewriter_panel/infrastructure/protocols/protobuf/generated/models/book.pb.dart";

extension PageTypeExtensions on PageType {
  /// The tag string used for matching blueprint tags
  String get tag => switch (this) {
    PageType.PAGE_TYPE_SEQUENCE => "trigger",
    PageType.PAGE_TYPE_STATIC => "static",
    PageType.PAGE_TYPE_SCENE => "scene",
    PageType.PAGE_TYPE_MANIFEST => "manifest",
    _ => throw UnsupportedError("Unknown page type: $this"),
  };

  /// List of linking tags for this page type
  List<String> get linkingTags => switch (this) {
    PageType.PAGE_TYPE_SEQUENCE => ["triggerable"],
    PageType.PAGE_TYPE_STATIC => [],
    PageType.PAGE_TYPE_SCENE => [],
    PageType.PAGE_TYPE_MANIFEST => ["manifest", "audience"],
    _ => throw UnsupportedError("Unknown page type: $this"),
  };

  /// Icon identifier string for this page type
  String get icon => switch (this) {
    PageType.PAGE_TYPE_SEQUENCE => Fa6Solid.diagram_project,
    PageType.PAGE_TYPE_STATIC => Ph.push_pin_fill,
    PageType.PAGE_TYPE_SCENE => Fa6Solid.film,
    PageType.PAGE_TYPE_MANIFEST => IconParkSolid.chart_graph,
    _ => throw UnsupportedError("Unknown page type: $this"),
  };

  /// Display color for this page type
  Color get color => switch (this) {
    PageType.PAGE_TYPE_SEQUENCE => Colors.blue,
    PageType.PAGE_TYPE_STATIC => Colors.deepPurple,
    PageType.PAGE_TYPE_SCENE => Colors.orange,
    PageType.PAGE_TYPE_MANIFEST => Colors.green,
    _ => throw UnsupportedError("Unknown page type: $this"),
  };

  /// Graph direction for this page type, null if not applicable
  GraphDirection? get direction => switch (this) {
    PageType.PAGE_TYPE_STATIC => GraphDirection.bottomToTop,
    PageType.PAGE_TYPE_SEQUENCE => GraphDirection.leftToRight,
    PageType.PAGE_TYPE_MANIFEST => GraphDirection.topToBottom,
    PageType.PAGE_TYPE_SCENE => null,
    _ => throw UnsupportedError("Unknown page type: $this"),
  };

  /// Display name for this page type
  String get displayName => switch (this) {
    PageType.PAGE_TYPE_SEQUENCE => "sequence",
    PageType.PAGE_TYPE_STATIC => "static",
    PageType.PAGE_TYPE_SCENE => "scene",
    PageType.PAGE_TYPE_MANIFEST => "manifest",
    _ => throw UnsupportedError("Unknown page type: $this"),
  };
}
