import "package:flutter/material.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "services_packed_models.freezed.dart";

@freezed
abstract class ServicesPackedNode with _$ServicesPackedNode {
  const factory ServicesPackedNode({
    required GraphIdentifier id,
    required int width,
    required int height,
    required WidgetBuilder builder,
    @Default(0) int priority,
  }) = _ServicesPackedNode;
}

@freezed
abstract class ServicesPackedConnection with _$ServicesPackedConnection {
  const factory ServicesPackedConnection({
    required String id,
    required GraphIdentifier source,
    required GraphIdentifier target,
    required Color color,
  }) = _ServicesPackedConnection;
}

@freezed
abstract class ServicesPackedComponentPlacement
    with _$ServicesPackedComponentPlacement {
  const factory ServicesPackedComponentPlacement({
    required String id,
    required int width,
    required int height,
    required Map<GraphIdentifier, ServicesPackedGridPlacement> placements,
  }) = _ServicesPackedComponentPlacement;
}

@freezed
abstract class ServicesPackedGridPlacement with _$ServicesPackedGridPlacement {
  const factory ServicesPackedGridPlacement({
    required int x,
    required int y,
    required int width,
    required int height,
  }) = _ServicesPackedGridPlacement;

  const ServicesPackedGridPlacement._();

  ServicesPackedGridPlacement translate(int dx, int dy) =>
      copyWith(x: x + dx, y: y + dy);
}
