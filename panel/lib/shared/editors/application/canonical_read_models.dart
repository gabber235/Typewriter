part of "portable_expression.dart";

/// Generated intrinsic schemas are read only and never appear in type choices.
final canonicalReadModels = CanonicalReadModels();

/// Bridges native Skir metadata to the intrinsic authored read schema.
///
/// The generated manifest defines allowed model fields in the reserved
/// `typewriter.read` namespace; declared catalog types such as Color keep their
/// declared identity. Reflection supplies their current wire values,
/// while projection charges the invoking expression's budgets. Decoders accept
/// this intrinsic schema when a query needs a type selection or type witness.
final class CanonicalReadModels {
  CanonicalReadModels() {
    final manifest = jsonDecode(_canonicalReadManifest) as Map<String, dynamic>;
    for (final model in manifest["models"] as List<dynamic>) {
      final entry = model as Map<String, dynamic>;
      _fields[entry["native"] as String] = [
        for (final field in entry["fields"] as List<dynamic>)
          field["name"] as String,
      ];
    }
    final definitions = [
      for (final definition in manifest["definitions"] as List<dynamic>)
        skir.TypeDefinition.serializer.fromJson(definition),
    ];
    for (final definition in definitions) {
      final fields = switch (definition.representation) {
        skir.RepresentationTemplate_recordWrapper(:final value) => value.fields,
        _ => const <skir.FieldDeclaration>[],
      };
      _definitions[definition.id] = skir.PublishedType(
        placementField: null,
        definition: definition,
        status: skir.DeclarationStatus.ready,
        effectiveFields: [
          for (final field in fields)
            skir.EffectiveFieldTemplate(
              key: field.owner.name,
              owner: field.owner,
              type: field.type,
              rules: const [],
            ),
        ],
        ancestorTemplates: definition.parents,
        display: defaultTypeDisplay(_modelDisplayName(definition.id)),
        searchKey: null,
      );
    }
  }

  final _definitions = <skir.TypeDefinitionId, skir.PublishedType>{};

  static String _modelDisplayName(skir.TypeDefinitionId id) =>
      switch (id.typeId) {
        skir.TypeId_qualifiedWrapper(:final value) =>
          value.name.split(".").last,
        _ => "Type",
      };
  final _fields = <String, List<String>>{};
  skir.PublishedType? published(skir.TypeDefinitionId id) => _definitions[id];

  skir.TypeUse get typeUseUse =>
      skir.TypeUse.wrapNamed(_use("com.typewritermc.types.TypeUse"));

  skir.TypeUse get typeSelectionUse =>
      skir.TypeUse.wrapNamed(_use("com.typewritermc.authoring.TypeSelection"));
  skir.TypeUse get publishedTypeUse => skir.TypeUse.wrapNamed(
    _use("com.typewritermc.types.catalog.PublishedType"),
  );

  skir.NamedTypeUse _use(String name) => skir.NamedTypeUse(
    definition: skir.TypeDefinitionId(
      typeId: skir.TypeId.createQualified(
        namespace: "typewriter.read",
        name: name,
      ),
      revision: 1,
    ),
    arguments: const [],
  );

  skir.DataValue project(
    Object value,
    skir.ReflectiveTypeDescriptor<dynamic> descriptor,
    List<String> fields,
    void Function() consumeStep,
    void Function(int) consumeItems,
  ) => _project(value, descriptor, fields, consumeStep, consumeItems, 0);

  skir.DataValue _project(
    Object? value,
    skir.ReflectiveTypeDescriptor<dynamic> descriptor,
    List<String> path,
    void Function() step,
    void Function(int) items,
    int depth,
  ) {
    step();
    if (depth > 512) {
      throw const FormatException(
        "Canonical projection exceeded its depth limit",
      );
    }
    if (value == null) return skir.DataValue.null_;
    if (descriptor is skir.ReflectiveOptionalDescriptor) {
      return _project(
        value,
        descriptor.otherType,
        path,
        step,
        items,
        depth + 1,
      );
    }
    if (descriptor is skir.PrimitiveDescriptor) {
      if (path.isNotEmpty) {
        throw const FormatException("A canonical scalar has no fields");
      }
      return switch (descriptor.primitiveType) {
        skir.PrimitiveType.bool => skir.DataValue.wrapBoolean(value as bool),
        skir.PrimitiveType.int32 ||
        skir.PrimitiveType.int64 ||
        skir.PrimitiveType.hash64 => skir.DataValue.wrapInteger(
          value.toString(),
        ),
        skir.PrimitiveType.float32 || skir.PrimitiveType.float64 =>
          skir.DataValue.wrapFloat((value as num).toDouble()),
        skir.PrimitiveType.string => skir.DataValue.wrapStringValue(
          value as String,
        ),
        skir.PrimitiveType.timestamp => skir.DataValue.wrapTimestamp(
          value as DateTime,
        ),
        skir.PrimitiveType.bytes => skir.DataValue.wrapBytes(
          value as skir.ByteString,
        ),
      };
    }
    if (descriptor is skir.ReflectiveArrayDescriptor) {
      if (path.isNotEmpty) {
        throw const FormatException(
          "A canonical collection needs an item binding before field access",
        );
      }
      final values = value as Iterable;
      items(values.length);
      return skir.DataValue.createListValue(
        items: [
          for (final (index, item) in values.indexed)
            skir.ListItem(
              id: skir.ItemId(value: "canonical:$index"),
              value: _project(
                item,
                descriptor.itemType,
                const [],
                step,
                items,
                depth + 1,
              ),
            ),
        ],
      );
    }
    if (value is skir.Icon) {
      final icon = iconValue(value);
      if (path.isEmpty) return icon;
      final record =
          (icon as skir.DataValue_namedWrapper).value.payload
              as skir.DataValue_recordWrapper;
      if (path.length == 1) {
        final field = record.value.fields
            .where((field) => field.name == path.single)
            .firstOrNull;
        if (field != null) return field.value;
      }
      throw FormatException("The canonical field ${path.first} is absent");
    }
    if (descriptor is skir.ReflectiveEnumDescriptor) {
      final variant = descriptor.getVariant(value);
      if (variant.number == 0) {
        throw const FormatException("Unknown canonical enum variant");
      }
      final constants = _enumConstants[descriptor.name];
      if (constants != null) {
        if (path.isNotEmpty) {
          throw const FormatException("A canonical enum has no fields");
        }
        final key = constants[variant.name];
        if (key == null) {
          throw const FormatException("Unknown canonical enum variant");
        }
        return skir.DataValue.createNamed(
          actualType: _use(_nativeNames[descriptor.name]!),
          payload: skir.DataValue.wrapEnumCase(key),
        );
      }
      final base = _nativeNames[descriptor.name];
      if (base == null) {
        throw FormatException("No canonical model for ${descriptor.name}");
      }
      final variantName =
          _variantNames[descriptor.name]?[variant.name] ??
          _pascal(variant.name);
      final model = "$base.$variantName";
      if (!_fields.containsKey(model)) {
        throw FormatException("No canonical model for $model");
      }
      final payload = variant is skir.ReflectiveEnumWrapperVariant
          ? variant.get(value)
          : value;
      final payloadDescriptor = variant is skir.ReflectiveEnumWrapperVariant
          ? variant.type
          : descriptor;
      final virtualField = _virtualFields["${descriptor.name}.${variant.name}"];
      return _record(
        model,
        payload,
        payloadDescriptor,
        path,
        step,
        items,
        depth,
        virtualField: virtualField,
      );
    }
    if (value is skir.Color) {
      if (path.isNotEmpty) {
        throw const FormatException("A canonical scalar has no fields");
      }
      return colorValue(value.argb.toUnsigned(32));
    }
    if (descriptor is skir.ReflectiveStructDescriptor) {
      final model = _nativeNames[descriptor.name];
      if (model == null) {
        throw FormatException("No canonical model for ${descriptor.name}");
      }
      if (_scalarModels.contains(descriptor.name)) {
        if (path.isNotEmpty) {
          throw const FormatException("A canonical scalar has no fields");
        }
        final field = descriptor.getFieldByName("value")!;
        return skir.DataValue.createNamed(
          actualType: _use(model),
          payload: _project(
            field.get(value),
            field.type,
            const [],
            step,
            items,
            depth + 1,
          ),
        );
      }
      return _record(model, value, descriptor, path, step, items, depth);
    }
    throw const FormatException("Unsupported canonical reflection descriptor");
  }

  skir.DataValue _record(
    String model,
    Object? value,
    skir.ReflectiveTypeDescriptor<dynamic> descriptor,
    List<String> path,
    void Function() step,
    void Function(int) items,
    int depth, {
    String? virtualField,
  }) {
    final fields = _fields[model]!;
    skir.DataValue field(String name, List<String> remaining) {
      if (!fields.contains(name)) {
        throw FormatException("The canonical field $name is absent");
      }
      if (virtualField == name) {
        return _project(value, descriptor, remaining, step, items, depth + 1);
      }
      if (descriptor is! skir.ReflectiveStructDescriptor) {
        throw FormatException("The canonical model $model has no field $name");
      }
      final wireName =
          _fieldAliases["${descriptor.name}.$name"] ??
          name.replaceAllMapped(
            RegExp("[A-Z]"),
            (match) => "_${match[0]!.toLowerCase()}",
          );
      final source = descriptor.getFieldByName(wireName);
      if (source == null) {
        throw FormatException("No canonical bridge for $model.$name");
      }
      return _project(
        source.get(value),
        source.type,
        remaining,
        step,
        items,
        depth + 1,
      );
    }

    if (path.isNotEmpty) return field(path.first, path.skip(1).toList());
    items(fields.length);
    return skir.DataValue.createNamed(
      actualType: _use(model),
      payload: skir.DataValue.createRecord(
        fields: [
          for (final name in fields)
            skir.FieldValue(name: name, value: field(name, const [])),
        ],
      ),
    );
  }

  skir.TypeSelection decodeTypeSelection(skir.DataValue value) {
    final name = _modelName(value);
    if (name == "com.typewritermc.authoring.TypeSelection.Complete") {
      final use = decodeTypeUse(_field(value, "use"));
      if (use is! skir.TypeUse_namedWrapper) {
        throw const FormatException(
          "A complete selection requires a named type",
        );
      }
      return skir.TypeSelection.wrapComplete(use.value);
    }
    if (name == "com.typewritermc.authoring.TypeSelection.Pending") {
      return skir.TypeSelection.createPending(
        definition: _decodeDefinition(_field(value, "definition")),
        arguments: [
          for (final argument in _list(_field(value, "arguments")))
            switch (_modelName(argument)) {
              "com.typewritermc.authoring.ArgumentSelection.Unfilled" =>
                skir.ArgumentSelection.unfilled,
              "com.typewritermc.authoring.ArgumentSelection.Chosen" =>
                skir.ArgumentSelection.wrapChosen(
                  decodeTypeUse(_field(argument, "type")),
                ),
              _ => throw const FormatException(
                "Unknown canonical argument selection",
              ),
            },
        ],
      );
    }
    throw const FormatException(
      "The expression is not a canonical type selection",
    );
  }

  skir.TypeUse decodeTypeUse(skir.DataValue value) => _decodeTypeUse(value, 0);

  skir.TypeUse _decodeTypeUse(skir.DataValue value, int depth) {
    if (depth > 128) {
      throw const FormatException(
        "Canonical type witness exceeded its depth limit",
      );
    }
    return switch (_modelName(value)) {
      "com.typewritermc.types.TypeUse.Named" => skir.TypeUse.createNamed(
        definition: _decodeDefinition(_field(value, "definition")),
        arguments: _list(_field(value, "arguments"))
            .map((argument) => _decodeTypeUse(argument, depth + 1)),
      ),
      "com.typewritermc.types.TypeUse.Nullable" => skir.TypeUse.createNullable(
        value: _decodeTypeUse(_field(value, "value"), depth + 1),
      ),
      "com.typewritermc.types.TypeUse.Scalar" => skir.TypeUse.wrapScalar(
        _decodeScalar(_field(value, "kind")),
      ),
      _ => throw const FormatException(
        "The expression is not a canonical type use",
      ),
    };
  }

  skir.TypeDefinitionId _decodeDefinition(skir.DataValue value) {
    if (_modelName(value) != "com.typewritermc.types.TypeDefinitionId") {
      throw const FormatException("Invalid canonical type definition identity");
    }
    final id = _field(value, "type");
    return skir.TypeDefinitionId(
      typeId: switch (_modelName(id)) {
        "com.typewritermc.types.TypeId.Declared" => skir.TypeId.createDeclared(
          value: _text(_field(id, "id")),
        ),
        "com.typewritermc.types.TypeId.Qualified" =>
          skir.TypeId.createQualified(
            namespace: _text(_field(id, "namespace")),
            name: _text(_field(id, "name")),
          ),
        _ => throw const FormatException("Invalid canonical type identity"),
      },
      revision: _integer(_field(value, "revision")).toInt(),
    );
  }

  skir.ScalarKind _decodeScalar(skir.DataValue value) {
    final name = _modelName(value).split(".").last;
    return switch (name) {
      "Unit" => skir.ScalarKind.unit,
      "Boolean" => skir.ScalarKind.boolean,
      "Text" => skir.ScalarKind.text,
      "Bytes" => skir.ScalarKind.bytes,
      "Decimal" => skir.ScalarKind.decimal,
      "Timestamp" => skir.ScalarKind.timestamp,
      "Duration" => skir.ScalarKind.duration,
      "Integer" => skir.ScalarKind.createInteger(
        width:
            _integerWidths[_enum(_field(value, "width"))] ??
            (throw const FormatException("Unknown integer width")),
      ),
      "Float" => skir.ScalarKind.createFloat(
        width: switch (_enum(_field(value, "width"))) {
          "FLOAT_32" => skir.FloatWidth.thirtyTwo,
          "FLOAT_64" => skir.FloatWidth.sixtyFour,
          _ => throw const FormatException("Unknown floating width"),
        },
      ),
      _ => throw const FormatException("Unknown canonical scalar"),
    };
  }

  String _modelName(skir.DataValue value) {
    if (value case skir.DataValue_namedWrapper(:final value)) {
      if (value.actualType.definition.typeId
          case skir.TypeId_qualifiedWrapper(:final value)
          when value.namespace == "typewriter.read") {
        return value.name;
      }
    }
    throw const FormatException("Expected a canonical named value");
  }

  skir.DataValue _field(skir.DataValue value, String name) =>
      value.authoredField(name) ??
      (throw FormatException("Canonical field $name is absent"));
  Iterable<skir.DataValue> _list(skir.DataValue value) =>
      switch (_unwrap(value)) {
        skir.DataValue_listValueWrapper(:final value) => value.items.map(
          (item) => item.value,
        ),
        _ => throw const FormatException("Expected a canonical list"),
      };
  String _enum(skir.DataValue value) => switch (_unwrap(value)) {
    skir.DataValue_enumCaseWrapper(:final value) => value,
    _ => throw const FormatException("Expected a canonical enum"),
  };
}

String _pascal(String name) => name
    .split("_")
    .map(
      (part) =>
          part.isEmpty ? part : "${part[0].toUpperCase()}${part.substring(1)}",
    )
    .join();

const _nativeNames = <String, String>{
  "TypeUse": "com.typewritermc.types.TypeUse",
  "NamedTypeUse": "com.typewritermc.types.TypeUse.Named",
  "NullableTypeUse": "com.typewritermc.types.TypeUse.Nullable",
  "TypeSelection": "com.typewritermc.authoring.TypeSelection",
  "PendingTypeSelection": "com.typewritermc.authoring.TypeSelection.Pending",
  "ArgumentSelection": "com.typewritermc.authoring.ArgumentSelection",
  "PublishedType": "com.typewritermc.types.catalog.PublishedType",
  "TypeDefinition": "com.typewritermc.types.TypeDefinition",
  "TypeDefinitionId": "com.typewritermc.types.TypeDefinitionId",
  "TypeId": "com.typewritermc.types.TypeId",
  "DeclaredTypeId": "com.typewritermc.types.DeclaredTypeId",
  "QualifiedTypeId": "com.typewritermc.types.TypeId.Qualified",
  "TypeParameter": "com.typewritermc.types.TypeParameter",
  "ParameterKey": "com.typewritermc.types.ParameterKey",
  "TypeTemplate": "com.typewritermc.types.TypeTemplate",
  "NamedTypeTemplate": "com.typewritermc.types.TypeTemplate.Named",
  "NullableTypeTemplate": "com.typewritermc.types.TypeTemplate.Nullable",
  "RepresentationTemplate": "com.typewritermc.types.RepresentationTemplate",
  "ScalarRepresentationTemplate":
      "com.typewritermc.types.RepresentationTemplate.Scalar",
  "RecordRepresentationTemplate":
      "com.typewritermc.types.RepresentationTemplate.Record",
  "SequenceRepresentationTemplate":
      "com.typewritermc.types.RepresentationTemplate.Sequence",
  "MappingRepresentationTemplate":
      "com.typewritermc.types.RepresentationTemplate.Mapping",
  "EnumerationRepresentationTemplate":
      "com.typewritermc.types.RepresentationTemplate.Enumeration",
  "LinkRepresentationTemplate":
      "com.typewritermc.types.RepresentationTemplate.Link",
  "ScalarKind": "com.typewritermc.types.ScalarKind",
  "IntegerScalar": "com.typewritermc.types.ScalarKind.Integer",
  "FloatScalar": "com.typewritermc.types.ScalarKind.Float",
  "IntegerWidth": "com.typewritermc.types.IntegerWidth",
  "FloatWidth": "com.typewritermc.types.FloatWidth",
  "CollectionKind": "com.typewritermc.types.CollectionKind",
  "EnumVariant": "com.typewritermc.types.EnumVariant",
  "FieldDeclaration": "com.typewritermc.types.FieldDeclaration",
  "FieldOwner": "com.typewritermc.types.FieldOwner",
  "EndpointId": "com.typewritermc.types.EndpointId",
  "EffectiveFieldTemplate":
      "com.typewritermc.types.catalog.EffectiveFieldTemplate",
  "TypeDisplay": "com.typewritermc.types.TypeDisplay",
  "DeclarationStatus": "com.typewritermc.types.catalog.DeclarationStatus",
  "DeclarationDiagnostic":
      "com.typewritermc.types.catalog.DeclarationDiagnostic",
  "DeclarationOrigin": "com.typewritermc.types.catalog.DeclarationOrigin",
  "DeclarationOwner": "com.typewritermc.types.DeclarationOwner",
  "RuleId": "com.typewritermc.configuration.RuleId",
  "RuleOrigin": "com.typewritermc.configuration.RuleOrigin",
  "ContributionKey": "com.typewritermc.discovery.ContributionKey",
  "ContributionSourceId": "com.typewritermc.imprint.ContributionSourceId",
  "ProducerId": "com.typewritermc.imprint.ProducerId",
  "ContributionName": "com.typewritermc.imprint.ContributionName",
  "RelativeFieldPattern": "com.typewritermc.configuration.RelativeFieldPattern",
  "FieldPatternSegment": "com.typewritermc.configuration.FieldPatternSegment",
  "NamedFieldPatternSegment":
      "com.typewritermc.configuration.FieldPatternSegment.Field",
};
const _scalarModels = {
  "DeclaredTypeId",
  "EndpointId",
  "ContributionSourceId",
  "ProducerId",
  "ContributionName",
};
const _fieldAliases = {"TypeDefinitionId.type": "type_id"};
const _virtualFields = {
  "TypeSelection.complete": "use",
  "TypeUse.scalar": "kind",
  "TypeTemplate.scalar": "kind",
  "TypeTemplate.parameter": "key",
  "TypeId.declared": "id",
  "ArgumentSelection.chosen": "type",
  "DeclarationStatus.unavailable": "reasons",
};
const _variantNames = <String, Map<String, String>>{};
const _enumConstants = {
  "IntegerWidth": {
    "signed_eight": "SIGNED_8",
    "signed_sixteen": "SIGNED_16",
    "signed_thirty_two": "SIGNED_32",
    "signed_sixty_four": "SIGNED_64",
    "unsigned_eight": "UNSIGNED_8",
    "unsigned_sixteen": "UNSIGNED_16",
    "unsigned_thirty_two": "UNSIGNED_32",
    "unsigned_sixty_four": "UNSIGNED_64",
  },
  "FloatWidth": {"thirty_two": "FLOAT_32", "sixty_four": "FLOAT_64"},
  "CollectionKind": {"list": "LIST", "set": "SET"},
};
final _integerWidths = <String, skir.IntegerWidth>{
  "SIGNED_8": skir.IntegerWidth.signedEight,
  "SIGNED_16": skir.IntegerWidth.signedSixteen,
  "SIGNED_32": skir.IntegerWidth.signedThirtyTwo,
  "SIGNED_64": skir.IntegerWidth.signedSixtyFour,
  "UNSIGNED_8": skir.IntegerWidth.unsignedEight,
  "UNSIGNED_16": skir.IntegerWidth.unsignedSixteen,
  "UNSIGNED_32": skir.IntegerWidth.unsignedThirtyTwo,
  "UNSIGNED_64": skir.IntegerWidth.unsignedSixtyFour,
};
