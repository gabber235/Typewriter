/// Reads the form of a record: concrete, open or closed.
///
/// A concrete record has values of its own; an open record accepts any
/// subtype that names it as a parent; a closed record accepts only the cases
/// it lists, in their declared order. An enum is a closed record whose cases
/// are all unit, and its value is the case itself: a named unit value whose
/// actual type is the case's member id. The Kotlin counterpart is
/// `RecordForms.kt` in typewriter-contracts.
library;

import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;

extension TypeDefinitionIdMembers on skir.TypeDefinitionId {
  /// The id of the case [name] of this closed record, at this revision.
  skir.TypeDefinitionId member(String name) => skir.TypeDefinitionId(
    typeId: skir.TypeId.createMember(owner: typeId, name: name),
    revision: revision,
  );

  /// The closed record that lists this case when this id is a member.
  skir.TypeDefinitionId? get memberOwner => switch (typeId) {
    skir.TypeId_memberWrapper(:final value) => skir.TypeDefinitionId(
      typeId: value.owner,
      revision: revision,
    ),
    _ => null,
  };

  /// The case name when this id is a member of a closed record.
  String? get memberName => switch (typeId) {
    skir.TypeId_memberWrapper(:final value) => value.name,
    _ => null,
  };
}

extension NamedTypeUseMembers on skir.NamedTypeUse {
  /// The use of the unit case [name] of the enum this use applies.
  skir.NamedTypeUse member(String name) => skir.NamedTypeUse(
    definition: definition.member(name),
    arguments: const [],
  );
}

extension RepresentationTemplateForms on skir.RepresentationTemplate {
  /// The cases this closed record lists, or null for any other form.
  List<skir.NamedTypeTemplate>? get closedCases => switch (this) {
    skir.RepresentationTemplate_recordWrapper(:final value) =>
      switch (value.form) {
        skir.RecordForm_closedWrapper(:final value) => value.cases.toList(),
        _ => null,
      },
    _ => null,
  };

  /// False for an open or closed record, whose values always carry one of
  /// its subtypes.
  bool get isInstantiable => switch (this) {
    skir.RepresentationTemplate_recordWrapper(:final value) =>
      value.form == skir.RecordForm.concrete,
    _ => true,
  };
}

extension TypeDefinitionForms on skir.TypeDefinition {
  /// Whether this declaration is an enum: a closed record whose cases are all
  /// unit members of it, looked up through [definition].
  bool isEnum(
    skir.TypeDefinition? Function(skir.TypeDefinitionId id) definition,
  ) {
    final cases = representation.closedCases;
    if (cases == null || cases.isEmpty) return false;
    return cases.every((caseUse) {
      final name = caseUse.definition.memberName;
      if (name == null || caseUse.definition != id.member(name)) return false;
      return switch (definition(caseUse.definition)?.representation) {
        skir.RepresentationTemplate_scalarWrapper(:final value) =>
          value.kind == skir.ScalarKind.unit,
        _ => false,
      };
    });
  }

  /// The case names of this enum in declaration order, or null when it is
  /// not an enum.
  List<String>? enumCases(
    skir.TypeDefinition? Function(skir.TypeDefinitionId id) definition,
  ) => isEnum(definition)
      ? [
          for (final caseUse in representation.closedCases!)
            caseUse.definition.memberName!,
        ]
      : null;
}

extension DataValueCases on skir.DataValue {
  /// The case name of this value when it is a unit case of a closed record,
  /// such as an enum value.
  String? get enumCaseName => switch (this) {
    skir.DataValue_namedWrapper(:final value)
        when value.payload == skir.DataValue.unit =>
      value.actualType.definition.memberName,
    _ => null,
  };
}
