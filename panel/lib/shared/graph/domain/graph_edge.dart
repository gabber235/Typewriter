import "package:flutter/material.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "graph_edge.freezed.dart";

@freezed
abstract class GraphEdge with _$GraphEdge {
  const factory GraphEdge({
    required String id,
    required GraphIdentifier source,
    required GraphIdentifier target,
    required Color color,
    @Default(EdgeSide.right) EdgeSide sourceSide,
    @Default(EdgeSide.left) EdgeSide targetSide,
  }) = _GraphEdge;

  const GraphEdge._();

  bool connectsTo(GraphElement element) {
    return source == element.id || target == element.id;
  }
}
