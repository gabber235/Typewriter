import "package:typewriter_panel/typewriter_panel.dart";

extension type const DraftNodeId(int value) {}

final class MaterializationLocation {
  const MaterializationLocation(this.segments);
  const MaterializationLocation.root() : segments = const [];

  final List<String> segments;

  MaterializationLocation child(String segment) =>
      MaterializationLocation([...segments, segment]);

  String get key => segments.join("/");

  @override
  bool operator ==(Object other) =>
      other is MaterializationLocation && other.key == key;

  @override
  int get hashCode => key.hashCode;
}

/// Temporary value state used only while creating a complete typed value.
/// Missing nodes never enter [DataValue], Skir, codecs, or persistence.
sealed class DraftValue {
  const DraftValue(this.id);
  final DraftNodeId id;
}

final class MissingDraftValue extends DraftValue {
  const MissingDraftValue(super.id);
}

final class ScalarDraftValue extends DraftValue {
  const ScalarDraftValue(super.id, this.value);
  final DataValue value;
}

final class RecordDraftValue extends DraftValue {
  const RecordDraftValue(super.id, this.fields);
  final Map<String, DraftValue> fields;
}

final class ListDraftValue extends DraftValue {
  const ListDraftValue(super.id, this.items);
  final List<DraftValue> items;
}

final class MapDraftValue extends DraftValue {
  const MapDraftValue(super.id, this.entries);
  final List<DraftMapEntry> entries;
}

final class DraftMapEntry {
  const DraftMapEntry({
    required this.id,
    required this.key,
    required this.value,
  });

  final DraftNodeId id;
  final DraftValue key;
  final DraftValue value;
}

final class PolymorphicDraftValue extends DraftValue {
  const PolymorphicDraftValue(
    super.id, {
    required this.concreteType,
    required this.payload,
  });

  final ResolvedTypeRef? concreteType;
  final DraftValue? payload;
}

final class EditorListStructure {
  const EditorListStructure(this.items);
  final List<DraftNodeId> items;
}

final class EditorMapStructure {
  const EditorMapStructure(this.entries);
  final List<EditorMapEntryStructure> entries;
}

final class EditorMapEntryStructure {
  const EditorMapEntryStructure({
    required this.id,
    required this.key,
    required this.value,
    this.keyDiagnostics = const [],
    this.valueDiagnostics = const [],
  });

  final DraftNodeId id;
  final EditorValue key;
  final EditorValue value;
  final List<TypeDiagnostic> keyDiagnostics;
  final List<TypeDiagnostic> valueDiagnostics;

  List<TypeDiagnostic> get diagnostics => [
    ...keyDiagnostics,
    ...valueDiagnostics,
  ];
}

final class EditorPolymorphicStructure {
  const EditorPolymorphicStructure({
    required this.concreteType,
    required this.payload,
  });

  final ResolvedTypeRef? concreteType;
  final EditorValue payload;
}

/// Result returned by the authoritative type initializer when a polymorphic
/// editor selects a concrete type.
sealed class ConcreteTypeInitializationResult {
  const ConcreteTypeInitializationResult();
}

final class ConcreteTypeInitialized extends ConcreteTypeInitializationResult {
  const ConcreteTypeInitialized(this.value);

  final TypedValueEnvelope value;
}

final class ConcreteTypeNeedsInput extends ConcreteTypeInitializationResult {
  const ConcreteTypeNeedsInput({this.suppliedValue});

  final DataValue? suppliedValue;
}

final class ConcreteTypeInitializationRejected
    extends ConcreteTypeInitializationResult {
  const ConcreteTypeInitializationRejected(this.diagnostics);

  final List<TypeDiagnostic> diagnostics;
}

typedef ConcreteTypeInitializer =
    Future<ConcreteTypeInitializationResult> Function({
      required ResolvedTypeRef type,
      required DataValue? supplied,
    });

abstract interface class ConcreteTypeSelectionOwner {
  Future<EditorMutationResult> selectConcreteTypeAsync(
    DataPath path,
    ResolvedTypeRef type,
  );
}

/// Structural capability for an owner whose containers may be incomplete.
abstract interface class EditorStructureOwner
    implements EditOwner, ConcreteTypeSelectionOwner {
  EditorListStructure? listStructure(DataPath path);
  EditorMapStructure? mapStructure(DataPath path);
  EditorPolymorphicStructure? polymorphicStructure(DataPath path);

  EditorMutationResult appendListItem(DataPath path);
  EditorMutationResult removeListItem(DataPath path, int index);
  EditorMutationResult duplicateListItem(DataPath path, int index);
  EditorMutationResult reorderListItem(DataPath path, int from, int to);

  EditorMutationResult appendMapEntry(DataPath path);
  EditorMutationResult removeMapEntry(DataPath path, DraftNodeId entry);
  EditorMutationResult updateMapKey(
    DataPath path,
    DraftNodeId entry,
    DataValue value,
  );
  EditorMutationResult updateMapValue(
    DataPath path,
    DraftNodeId entry,
    DataValue value,
  );

  EditorValue concretePayloadValue(DataPath path, DataPath payloadPath);
  EditorMutationResult updateConcretePayloadAt(
    DataPath path,
    DataPath payloadPath,
    DataValue value,
  );
  EditorMutationResult updateConcretePayload(DataPath path, DataValue value);
}
