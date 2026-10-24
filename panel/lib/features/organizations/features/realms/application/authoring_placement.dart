import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "authoring_placement.freezed.dart";

final elementValuePath = editorRootPath;

// The placement type ids mirror the `@TypewriterType` ids declared in
// services/sdk/typewriter-api/src/main/kotlin/com/typewritermc/authoring/Placement.kt.
// The catalog names a resource type's placement field but not these types.
final placementRootTypeRef = skir.TypeDefinitionId(
  typeId: skir.TypeId.createDeclared(value: "d134aec7caa54a288ab42275756cfe8d"),
  revision: 1,
);
final graphPlacementTypeRef = skir.TypeDefinitionId(
  typeId: skir.TypeId.createDeclared(value: "578f0d42bc964b1fab52c8de5e02f9c5"),
  revision: 1,
);
final timelineEntryPlacementTypeRef = skir.TypeDefinitionId(
  typeId: skir.TypeId.createDeclared(value: "bf3c5268557a4dfba0e7c1f72d3e67bd"),
  revision: 1,
);
final timelineSegmentPlacementTypeRef = skir.TypeDefinitionId(
  typeId: skir.TypeId.createDeclared(value: "54e38e56871243d2ae747ed6c0083381"),
  revision: 1,
);
final timelineKeyframePlacementTypeRef = skir.TypeDefinitionId(
  typeId: skir.TypeId.createDeclared(value: "e0369811aac94bf6a291f65d1c719e1b"),
  revision: 1,
);

/// The PlacementAnchor type that operation inputs use for a drop point.
final placementAnchorTypeRef = skir.TypeDefinitionId(
  typeId: skir.TypeId.createDeclared(value: "0a18ceeaa4c94c2c87f705c327355af0"),
  revision: 1,
);

@freezed
sealed class Placement with _$Placement {
  const factory Placement.graph({
    required int x,
    required int y,
    required int width,
    required int height,
  }) = GraphPlacement;
  const factory Placement.timelineEntry({required int trackIndex}) =
      TimelineEntryPlacement;
  const factory Placement.timelineSegment({
    required int startFrame,
    required int endFrame,
  }) = TimelineSegmentPlacement;
  const factory Placement.timelineKeyframe({required int frame}) =
      TimelineKeyframePlacement;
  const Placement._();

  skir.TypeDefinitionId get concreteType => switch (this) {
    GraphPlacement() => graphPlacementTypeRef,
    TimelineEntryPlacement() => timelineEntryPlacementTypeRef,
    TimelineSegmentPlacement() => timelineSegmentPlacementTypeRef,
    TimelineKeyframePlacement() => timelineKeyframePlacementTypeRef,
  };

  skir.DataValue toAuthoredValue() {
    final invalid = problem;
    if (invalid != null) throw ArgumentError(invalid);
    final fields = switch (this) {
      GraphPlacement(:final x, :final y, :final width, :final height) => {
        "x": x,
        "y": y,
        "width": width,
        "height": height,
      },
      TimelineEntryPlacement(:final trackIndex) => {"trackIndex": trackIndex},
      TimelineSegmentPlacement(:final startFrame, :final endFrame) => {
        "startFrame": startFrame,
        "endFrame": endFrame,
      },
      TimelineKeyframePlacement(:final frame) => {"frame": frame},
    };
    return skir.DataValue.createNamed(
      actualType: skir.NamedTypeUse(
        definition: concreteType,
        arguments: const [],
      ),
      payload: skir.DataValue.createRecord(
        fields: fields.entries.map(
          (field) => skir.FieldValue(
            name: field.key,
            value: skir.DataValue.wrapInteger(field.value.toString()),
          ),
        ),
      ),
    );
  }
}

@freezed
sealed class PlacementReading with _$PlacementReading {
  const factory PlacementReading.ready({
    required Placement placement,
    required skir.DataValue authored,
  }) = ReadyPlacement;
  const factory PlacementReading.unfinished(skir.ValuePath path) =
      UnfinishedPlacement;
  const factory PlacementReading.unavailable(String message) =
      UnavailablePlacement;
}

extension CatalogPlacementReading on skir.DataValue {
  PlacementReading readPlacement(CheckedEditorCatalog catalog) {
    if (this == skir.DataValue.unfilled) {
      return PlacementReading.unfinished(editorRootPath);
    }
    final original = this;
    if (original is! skir.DataValue_namedWrapper) {
      return const PlacementReading.unavailable(
        "Placement must be named record data",
      );
    }
    final actual = skir.TypeUse.wrapNamed(original.value.actualType);
    final candidates =
        [
              graphPlacementTypeRef,
              timelineEntryPlacementTypeRef,
              timelineSegmentPlacementTypeRef,
              timelineKeyframePlacementTypeRef,
            ]
            .where(
              (type) => catalog.isReadableAs(
                actual,
                skir.TypeUse.createNamed(definition: type, arguments: const []),
              ),
            )
            .toList();
    if (candidates.length != 1) {
      return const PlacementReading.unavailable(
        "Placement has no unique supported nominal form",
      );
    }
    final target = candidates.single;
    final fields = target == graphPlacementTypeRef
        ? ["x", "y", "width", "height"]
        : target == timelineEntryPlacementTypeRef
        ? ["trackIndex"]
        : target == timelineSegmentPlacementTypeRef
        ? ["startFrame", "endFrame"]
        : ["frame"];
    final numbers = <String, int>{};
    for (final field in fields) {
      final value = original.authoredField(field);
      if (value == null || value == skir.DataValue.unfilled) {
        return PlacementReading.unfinished(editorRootPath.field(field));
      }
      final integer = value.authoredInteger;
      final number = integer == null ? null : int.tryParse(integer.toString());
      if (number == null || BigInt.from(number) != integer) {
        return PlacementReading.unavailable(
          "Placement field $field is not an exactly representable integer",
        );
      }
      numbers[field] = number;
    }
    final placement = target == graphPlacementTypeRef
        ? Placement.graph(
            x: numbers["x"]!,
            y: numbers["y"]!,
            width: numbers["width"]!,
            height: numbers["height"]!,
          )
        : target == timelineEntryPlacementTypeRef
        ? Placement.timelineEntry(trackIndex: numbers["trackIndex"]!)
        : target == timelineSegmentPlacementTypeRef
        ? Placement.timelineSegment(
            startFrame: numbers["startFrame"]!,
            endFrame: numbers["endFrame"]!,
          )
        : Placement.timelineKeyframe(frame: numbers["frame"]!);
    final problem = placement.problem;
    return problem == null
        ? PlacementReading.ready(placement: placement, authored: original)
        : PlacementReading.unavailable(problem);
  }
}

extension PlacementValidity on Placement {
  String? get problem => switch (this) {
    GraphPlacement(:final width, :final height)
        when width <= 0 || height <= 0 =>
      "Graph dimensions must be positive",
    TimelineEntryPlacement(:final trackIndex) when trackIndex < 0 =>
      "Track index must not be negative",
    TimelineSegmentPlacement(:final startFrame, :final endFrame)
        when startFrame < 0 || endFrame < startFrame =>
      "Timeline range is invalid",
    TimelineKeyframePlacement(:final frame) when frame < 0 =>
      "Keyframe must not be negative",
    _ => null,
  };
}

extension GraphPlacementGeometry on GraphPlacement {
  GraphGridRect get gridRect =>
      GraphGridRect(x: x, y: y, width: width, height: height);
}

extension AuthoredPlacementReading on skir.AuthoringRecord {
  /// Reads the placement at the field the catalog publishes for this record's
  /// type. Types without a published placement field have no placement.
  PlacementReading placement(CheckedEditorCatalog catalog) {
    final path = catalog.placementField(configuration);
    final expected = path == null
        ? null
        : catalog.valueTypeAt(configuration, path);
    if (path == null || expected == null) {
      return const PlacementReading.unavailable(
        "Placement type is unavailable",
      );
    }
    final value = switch (readAt(path)) {
      PortablePathValue(:final value) => value,
      _ => null,
    };
    if (value == null || value == skir.DataValue.unfilled) {
      return PlacementReading.unfinished(path);
    }
    final actual = value.authoredActualType;
    if (actual == null ||
        !catalog.isReadableAs(skir.TypeUse.wrapNamed(actual), expected)) {
      return const PlacementReading.unavailable(
        "Placement does not match the resource field type",
      );
    }
    return switch (value.readPlacement(catalog)) {
      UnfinishedPlacement(path: final relative) => PlacementReading.unfinished(
        skir.ValuePath(segments: [...path.segments, ...relative.segments]),
      ),
      final reading => reading,
    };
  }

  GraphGridRect? graphRect(CheckedEditorCatalog catalog) =>
      switch (placement(catalog)) {
        ReadyPlacement(placement: final GraphPlacement graph) => graph.gridRect,
        _ => null,
      };
}

extension PlacementEdits on AuthoringEdit {
  void _patchPlacement(
    skir.ResourceId id,
    Map<String, int> Function(Placement) fields,
  ) {
    final checked =
        catalog ?? (throw StateError("The editor catalog is unavailable"));
    final record = resource(id) ?? (throw StateError("The resource is absent"));
    final placementPath =
        checked.placementField(record.configuration) ??
        (throw StateError("This resource type declares no placement"));
    final reading = record.placement(checked);
    if (reading is! ReadyPlacement) {
      throw StateError(switch (reading) {
        UnfinishedPlacement() => "Placement is unfinished",
        UnavailablePlacement(:final message) => message,
        _ => "Placement is unavailable",
      });
    }
    final updates = fields(reading.placement);
    var candidate = reading.authored;
    for (final update in updates.entries) {
      final relative = editorRootPath.field(update.key);
      final before = candidate.editorValueAt(relative);
      if (before == null) throw StateError("The placement field is absent");
      final replaced = candidate.replaceAt(
        relative,
        before.withAuthoredPayload(
          skir.DataValue.wrapInteger(update.value.toString()),
        ),
      );
      if (replaced is! PortablePathValue<skir.DataValue>) {
        throw StateError("The placement patch is unavailable");
      }
      candidate = replaced.value;
    }
    final candidateRecord = switch (record.replaceAt(
      placementPath,
      candidate,
    )) {
      PortablePathValue(:final value) => value,
      PortablePathUnavailable(:final message) => throw StateError(message),
    };
    final checkedCandidate = candidateRecord.placement(checked);
    if (checkedCandidate is! ReadyPlacement) {
      throw StateError("The proposed placement is invalid");
    }
    // Only changed numeric fields become intent. Keep original named wrappers,
    // extension fields and unrelated coordinates intact.
    for (final update in updates.entries) {
      final location = skir.ValueLocation(
        resource: id,
        path: placementPath.field(update.key),
      );
      final existing = read(location);
      if (existing is! PortablePathValue<skir.DataValue>) {
        throw StateError("The placement field is unavailable");
      }
      final outcome = set(
        location,
        existing.value.withAuthoredPayload(
          skir.DataValue.wrapInteger(update.value.toString()),
        ),
      );
      if (outcome case PortablePathUnavailable(:final message)) {
        throw StateError(message);
      }
    }
  }

  void moveGraphPlacement(skir.ResourceId id, int x, int y) => _patchPlacement(
    id,
    (placement) => switch (placement) {
      GraphPlacement() => {"x": x, "y": y},
      _ => throw StateError("This resource has no graph placement"),
    },
  );
  void resizeGraphPlacement(skir.ResourceId id, int width, int height) =>
      _patchPlacement(
        id,
        (placement) => switch (placement) {
          GraphPlacement() => {"width": width, "height": height},
          _ => throw StateError("This resource has no graph placement"),
        },
      );
  void moveTimelinePlacement(skir.ResourceId id, int start, int end) =>
      _patchPlacement(
        id,
        (placement) => switch (placement) {
          TimelineKeyframePlacement() => {"frame": start},
          TimelineSegmentPlacement() => {"startFrame": start, "endFrame": end},
          _ => throw StateError("This resource has no timeline cue placement"),
        },
      );
}

extension CreatedResourcePlacement on AuthoringEdit {
  void placeCreatedResource(ResourceCreationRequest request) {
    final checked =
        catalog ?? (throw StateError("The editor catalog is unavailable"));
    final placementPath = checked.placementField(request.configuration);
    if (placementPath == null) return;
    final placementField = switch (placementPath.segments.firstOrNull) {
      skir.PathSegment_fieldWrapper(:final value) => value.name,
      _ => null,
    };
    if (request.supplied.any((field) => field.name == placementField)) return;
    final original = resource(request.id)?.graphRect(checked);
    if (original == null) return;
    final document = toDocument();
    final relations = document.relations;
    final parents = relations.parents[request.id] ?? const <skir.ResourceId>[];
    if (parents.length > 1) {
      throw StateError("The created resource has multiple owners");
    }
    final siblings = parents.isEmpty
        ? document.entries.values
              .where(
                (entry) =>
                    entry.content.configuration.definition ==
                    request.configuration.definition,
              )
              .map((entry) => entry.id)
        : relations.children[parents.single] ?? const <skir.ResourceId>[];
    final rect = const GraphIncrementalPlacer()
        .placeGroup(
          obstacles: [
            for (final id in siblings)
              if (id != request.id) ?resource(id)?.graphRect(checked),
          ],
          group: [original],
          anchor: original.center,
        )
        .single;
    moveGraphPlacement(request.id, rect.x, rect.y);
  }
}
