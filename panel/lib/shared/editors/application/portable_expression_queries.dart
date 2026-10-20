part of "portable_expression.dart";

/// Canonical reads are pinned to the same observation as the expression bindings.
@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class PortableExpressionQueries with _$PortableExpressionQueries {
  factory PortableExpressionQueries({
    required CheckedEditorCatalog catalog,
    PortableAuthoringView? authored,
  }) {
    if (authored is PortableAuthoringEdit) {
      throw ArgumentError.value(
        authored,
        "authored",
        "Capture an immutable document before rendering",
      );
    }
    if (authored != null &&
        authored.generation != catalog.snapshot.generation) {
      throw StateError("Query document and catalog generations differ");
    }
    return PortableExpressionQueries._value(
      catalog: catalog,
      authored: authored,
    );
  }
  const PortableExpressionQueries._();
  const factory PortableExpressionQueries._value({
    required CheckedEditorCatalog catalog,
    required PortableAuthoringView? authored,
  }) = _PortableExpressionQueries;

  skir.AuthoringRecord? resource(skir.ResourceId id) {
    final view = authored;
    if (view == null) {
      throw StateError("Resource queries need an authoring view");
    }
    return view.resource(id);
  }

  skir.PublishedType? declaration(skir.TypeDefinitionId id) =>
      catalog.published(id);
}

final frameworkResourceIdUse = skir.NamedTypeUse(
  definition: skir.TypeDefinitionId(
    typeId: skir.TypeId.createQualified(
      namespace: "kotlin",
      name: "com.typewritermc.types.ResourceId",
    ),
    revision: 1,
  ),
  arguments: const [],
);

/// The group a tree layout binds while rendering each group header: its path,
/// last path segment as name, and direct members.
final hierarchyGroupUse = skir.NamedTypeUse(
  definition: skir.TypeDefinitionId(
    typeId: skir.TypeId.createDeclared(
      value: "c9ef8108a30f4e43805d8ee137e001dc",
    ),
    revision: 1,
  ),
  arguments: const [],
);

extension ResourceIdentityExpression on skir.ResourceId {
  skir.DataValue toExpressionValue() => skir.DataValue.createNamed(
    actualType: frameworkResourceIdUse,
    payload: skir.DataValue.wrapStringValue(value),
  );
  PortableExpressionBinding toExpressionBinding() => PortableExpressionBinding(
    value: toExpressionValue(),
    schema: CompletePortablePresentationBinding(
      skir.TypeUse.wrapNamed(frameworkResourceIdUse),
    ),
  );
}

extension PortableLexicalSchemas
    on Map<skir.ExpressionBindingId, PortableExpressionBinding> {
  Map<skir.ExpressionBindingId, PortablePresentationBindingSchema>
  get lexicalSchemas => Map.unmodifiable({
    for (final entry in entries) entry.key: ?entry.value.schema,
  });
}

@freezed
abstract class ExpressionOccurrence with _$ExpressionOccurrence {
  const factory ExpressionOccurrence({required List<int> path}) =
      _ExpressionOccurrence;
}

@freezed
abstract class CheckedQueryCall with _$CheckedQueryCall {
  const factory CheckedQueryCall({
    required skir.ExpressionQuery query,
    required skir.TypeUse? targetType,
    required skir.ExpressionType result,
    required bool sourceIsReference,
  }) = _CheckedQueryCall;
}

@freezed
abstract class CheckedExpressionProgram with _$CheckedExpressionProgram {
  const factory CheckedExpressionProgram({
    required skir.ExpressionNode body,
    required skir.ExpressionType result,
    required Map<ExpressionOccurrence, CheckedQueryCall> queries,
  }) = _CheckedExpressionProgram;
}

@freezed
sealed class CheckedExpressionResult with _$CheckedExpressionResult {
  const factory CheckedExpressionResult.ready(
    CheckedExpressionProgram program,
  ) = CheckedExpressionReady;
  const factory CheckedExpressionResult.invalid({
    required String code,
    required String message,
  }) = CheckedExpressionInvalid;
}

extension _CanonicalQueryEvaluation on PortableExpressionEvaluator {
  void _chargeCanonicalValue(skir.DataValue value, int depth) {
    _consumeStep();
    if (depth > 512) {
      throw const _ExpressionFailure(
        "expression_depth_limit",
        "The resource value exceeded its depth limit",
      );
    }
    switch (value) {
      case skir.DataValue_namedWrapper(:final value):
        _chargeCanonicalValue(value.payload, depth + 1);
      case skir.DataValue_recordWrapper(:final value):
        _consumeCollectionItems(value.fields.length);
        for (final field in value.fields) {
          _chargeCanonicalValue(field.value, depth + 1);
        }
      case skir.DataValue_listValueWrapper(:final value):
      case skir.DataValue_setValueWrapper(:final value):
        _consumeCollectionItems(value.items.length);
        for (final item in value.items) {
          _chargeCanonicalValue(item.value, depth + 1);
        }
      case skir.DataValue_mapValueWrapper(:final value):
        _consumeCollectionItems(value.rows.length);
        for (final row in value.rows) {
          _chargeCanonicalValue(row.key, depth + 1);
          _chargeCanonicalValue(row.value, depth + 1);
        }
      default:
        break;
    }
  }

  _Evaluation _query(
    skir.ExpressionQuery query,
    skir.ValuePath path,
    ExpressionOccurrence occurrence,
  ) {
    final contract = queryContracts[occurrence];
    if (contract == null) {
      throw const _ExpressionFailure(
        "unchecked_query",
        "Query requires a checked program",
      );
    }
    final previous = _occurrence;
    _occurrence = occurrence.path;
    try {
      switch (query) {
        case skir.ExpressionQuery_valueConfigurationWrapper(:final value):
          final source = _child(value, 0);
          if (source is _Unavailable) return source;
          final actual = (source as _Available).value;
          if (actual is! skir.DataValue_namedWrapper) {
            return const _Unavailable();
          }
          return _projectNative(
            skir.TypeSelection.wrapComplete(actual.value.actualType),
            skir.TypeSelection.serializer.typeDescriptor,
            path,
          );
        case skir.ExpressionQuery_catalogDeclarationWrapper(:final value):
          final source = _child(value, 0);
          if (source is _Unavailable) return source;
          final selection = canonicalReadModels.decodeTypeSelection(
            (source as _Available).value,
          );
          final definition =
              selection.definition ??
              (throw const _ExpressionFailure(
                "invalid_type_selection",
                "Unknown type selection",
              ));
          final native = queries?.declaration(definition);
          if (native == null) return const _Unavailable();
          return _projectNative(
            native,
            skir.PublishedType.serializer.typeDescriptor,
            path,
          );
        case skir.ExpressionQuery_resourceIdentityWrapper(:final value):
        case skir.ExpressionQuery_resourceValueWrapper(:final value):
        case skir.ExpressionQuery_resourceConfigurationWrapper(:final value):
          final sourceNode = switch (value) {
            skir.ResourceQuerySource_referenceWrapper(:final value) => value,
            skir.ResourceQuerySource_identityWrapper(:final value) =>
              value.identity,
            _ => throw const _ExpressionFailure(
              "invalid_query_source",
              "Unknown resource source",
            ),
          };
          final source = _child(sourceNode, 0);
          if (source is _Unavailable) return source;
          final actual = (source as _Available).value;
          if (actual == skir.DataValue.unfilled ||
              actual == skir.DataValue.null_) {
            return const _Unavailable();
          }
          final id = contract.sourceIsReference
              ? switch (_unwrap(actual)) {
                  skir.DataValue_linkWrapper(:final value) =>
                    value.target.resource,
                  _ => throw const _ExpressionFailure(
                    "expected_link",
                    "Expected resource reference",
                  ),
                }
              : skir.ResourceId(value: _text(actual));
          final environment = queries;
          if (environment?.authored == null) {
            throw const _ExpressionFailure(
              "unsupported_query",
              "Resource query needs an authoring observation",
            );
          }
          _reads.add(
            PortableExpressionRead(
              source: PortableExpressionReadSource.query(occurrence),
              path: path,
              location: skir.ValueLocation(
                resource: id,
                path: query is skir.ExpressionQuery_resourceValueWrapper
                    ? path
                    : editorRootPath,
              ),
            ),
          );
          final record = environment!.resource(id);
          if (record == null ||
              !_querySelectionMatches(
                environment.catalog,
                record.configuration,
                contract.targetType!,
              )) {
            return const _Unavailable();
          }
          if (query is skir.ExpressionQuery_resourceIdentityWrapper) {
            return _Available(id.toExpressionValue());
          }
          if (query is skir.ExpressionQuery_resourceConfigurationWrapper) {
            return _projectNative(
              record.configuration,
              skir.TypeSelection.serializer.typeDescriptor,
              path,
            );
          }
          final payload = skir.DataValue.createRecord(fields: record.fields);
          final selected = path.segments.isEmpty
              ? PortablePathValue(payload)
              : payload.readAt(path);
          if (selected is! PortablePathValue<skir.DataValue>) {
            if (record.configuration is skir.TypeSelection_completeWrapper) {
              throw const _ExpressionFailure(
                "invalid_resource_value",
                "The complete resource is missing a declared field",
              );
            }
            return const _Unavailable();
          }
          if (selected.value == skir.DataValue.unfilled ||
              selected.value == skir.DataValue.null_) {
            return const _Unavailable();
          }
          final schema = path.segments.isEmpty
              ? switch (record.configuration) {
                  skir.TypeSelection_completeWrapper(:final value) =>
                    skir.TypeUse.wrapNamed(value),
                  _ => null,
                }
              : environment.catalog.valueTypeAt(record.configuration, path);
          if (schema == null && path.segments.isNotEmpty) {
            return const _Unavailable();
          }
          final result =
              path.segments.isEmpty &&
                  record.configuration is skir.TypeSelection_completeWrapper
              ? skir.DataValue.createNamed(
                  actualType:
                      (record.configuration
                              as skir.TypeSelection_completeWrapper)
                          .value,
                  payload: payload,
                )
              : selected.value;
          _chargeCanonicalValue(result, 0);
          if (schema != null &&
              environment.catalog
                  .inspectPortableValue(schema, result)
                  .structuralProblems
                  .isNotEmpty) {
            throw const _ExpressionFailure(
              "invalid_resource_value",
              "Resource projection does not match its checked schema",
            );
          }
          return _Available(result);
        default:
          throw const _ExpressionFailure(
            "unknown_query",
            "Unknown query variant",
          );
      }
    } on FormatException catch (error) {
      throw _ExpressionFailure("invalid_canonical_value", error.message);
    } on TypeError catch (error) {
      throw _ExpressionFailure("invalid_canonical_value", error.toString());
    } on ArgumentError catch (error) {
      throw _ExpressionFailure("invalid_canonical_value", error.toString());
    } finally {
      _occurrence = previous;
    }
  }

  _Evaluation _projectNative(
    Object native,
    skir.ReflectiveTypeDescriptor<dynamic> descriptor,
    skir.ValuePath path,
  ) {
    final fields = <String>[];
    for (final segment in path.segments) {
      if (segment is! skir.PathSegment_fieldWrapper) {
        throw const _ExpressionFailure(
          "invalid_model_projection",
          "Native model projection requires field segments",
        );
      }
      fields.add(segment.value.name);
    }
    final result = canonicalReadModels.project(
      native,
      descriptor,
      fields,
      _consumeStep,
      _consumeCollectionItems,
    );
    return result == skir.DataValue.unfilled || result == skir.DataValue.null_
        ? const _Unavailable()
        : _Available(result);
  }
}

@freezed
abstract class _ExpressionProgramKey with _$ExpressionProgramKey {
  const factory _ExpressionProgramKey({
    required skir.ExpressionNode body,
    required Map<skir.ExpressionBindingId, PortablePresentationBindingSchema>
    lexicalTypes,
  }) = __ExpressionProgramKey;
}

/// Caches expression checking within one catalog and lexical schema.
///
/// Query contracts are indexed by occurrence path in the expression tree,
/// allowing runtime queries to use the type proved at that exact call site.
/// Values stay outside the cache key because compilation depends on schema.
/// Both invalid results and checked programs are retained for this owner.
final class PortableExpressionPrograms {
  PortableExpressionPrograms(this.catalog);
  final CheckedEditorCatalog catalog;
  final _programs = <_ExpressionProgramKey, CheckedExpressionResult>{};

  CheckedExpressionResult program(
    skir.ExpressionNode body, {
    required Map<skir.ExpressionBindingId, PortablePresentationBindingSchema>
    lexicalTypes,
  }) => _programs.putIfAbsent(
    _ExpressionProgramKey(
      body: body,
      lexicalTypes: Map.unmodifiable(lexicalTypes),
    ),
    () => _compile(body, lexicalTypes),
  );

  CheckedExpressionResult _compile(
    skir.ExpressionNode body,
    Map<skir.ExpressionBindingId, PortablePresentationBindingSchema>
    lexicalTypes,
  ) {
    final contracts = <ExpressionOccurrence, CheckedQueryCall>{};
    skir.ExpressionType? inferred;
    final errors = checkPortableExpression(
      body,
      catalog: catalog,
      bindings: {
        for (final entry in lexicalTypes.entries)
          if (entry.value case CompletePortablePresentationBinding(:final use))
            entry.key: nominalType(use, true),
      },
      partialBindings: {
        for (final entry in lexicalTypes.entries)
          if (entry.value case PartialPortablePresentationBinding(
            :final selection,
          ))
            entry.key: selection,
      },
      queryContracts: contracts,
      onInferred: (value) => inferred = value,
    );
    if (errors.isNotEmpty || inferred == null) {
      return CheckedExpressionResult.invalid(
        code: errors.firstOrNull ?? "expression_type_inference_failed",
        message: "The expression could not be checked: ${errors.join(', ')}",
      );
    }
    return CheckedExpressionResult.ready(
      CheckedExpressionProgram(
        body: body,
        result: inferred!,
        queries: Map.unmodifiable(contracts),
      ),
    );
  }
}

/// Checks canonical queries against lexical schemas before evaluating them.
/// Pure expressions use the evaluator directly, retaining support for lexical
/// values that do not need nominal query contracts.
extension PortableCheckedEvaluation on CheckedEditorCatalog {
  PortableExpressionResult evaluateExpression(
    skir.ExpressionNode expression, {
    required Map<skir.ExpressionBindingId, PortableExpressionBinding> bindings,
    required skir.EvaluationBudget budget,
    PortableExpressionQueries? queries,
  }) {
    // Pure expressions retain their existing runtime behavior and do not need
    // nominal schemas for unrelated lexical values.
    if (!expression.hasCanonicalQueries) {
      return PortableExpressionEvaluator.located(
        bindings,
        budget: budget,
      ).evaluate(expression);
    }
    if (queries != null && !identical(queries.catalog, this)) {
      return PortableExpressionFailed(
        "query_catalog_mismatch",
        "The query observation belongs to a different checked catalog",
        const [],
      );
    }
    final checked = expressionPrograms.program(
      expression,
      lexicalTypes: bindings.lexicalSchemas,
    );
    return switch (checked) {
      CheckedExpressionReady(:final program) =>
        PortableExpressionEvaluator.located(
          bindings,
          budget: budget,
          queries: queries,
          queryContracts: program.queries,
        ).evaluate(program.body),
      CheckedExpressionInvalid(:final code, :final message) =>
        PortableExpressionFailed(code, message, const []),
    };
  }

  skir.TypeUse expressionPayloadType(skir.TypeUse use) {
    if (use case skir.TypeUse_nullableWrapper(:final value)) {
      return expressionPayloadType(value.value);
    }
    final named = namedUse(use);
    if (named == null) return use;
    final representation = published(named.definition)
        ?.definition
        .representation;
    if (representation case skir.RepresentationTemplate_scalarWrapper(
      :final value,
    )) {
      return skir.TypeUse.wrapScalar(value.kind);
    }
    return use;
  }

  skir.ExpressionType? expressionPathType(
    skir.ExpressionType source,
    skir.ValuePath path,
  ) {
    if (path.segments.isEmpty) return source;
    if (source.value is! skir.ExpressionValueType_nominalWrapper) return null;
    final named = namedUse(
      (source.value as skir.ExpressionValueType_nominalWrapper).value,
    );
    if (named == null) return null;
    final use = valueTypeAt(skir.TypeSelection.wrapComplete(named), path);
    return use == null ? null : nominalType(use, true);
  }
}

extension CanonicalQueryPresence on skir.ExpressionNode {
  bool get hasCanonicalQueries =>
      this is skir.ExpressionNode_queryWrapper ||
      (this is! skir.ExpressionNode_unknown &&
          children.any((child) => child.hasCanonicalQueries));
}

bool _querySelectionMatches(
  CheckedEditorCatalog catalog,
  skir.TypeSelection selection,
  skir.TypeUse expected,
) {
  if (selection is skir.TypeSelection_completeWrapper) {
    return catalog.selectionMatches(selection, expected);
  }
  final named = catalog.namedUse(expected);
  if (named == null ||
      !catalog.nominalDefinitions(selection).contains(named.definition)) {
    return false;
  }
  if (selection case skir.TypeSelection_pendingWrapper(:final value)
      when value.definition == named.definition) {
    if (value.arguments.length != named.arguments.length) return false;
    for (final (index, argument) in value.arguments.indexed) {
      if (argument case skir.ArgumentSelection_chosenWrapper(:final value)) {
        if (!catalog.isReadableAs(value, named.arguments.elementAt(index))) {
          return false;
        }
      }
    }
  }
  return true;
}

final expressionColorUse = skir.NamedTypeUse(
  definition: skir.TypeDefinitionId(
    typeId: skir.TypeId.createDeclared(
      value: "c15fe94d13fb4317924a0ad2072defe4",
    ),
    revision: 1,
  ),
  arguments: const [],
);

/// Builds the declared Color data value for an unsigned ARGB [argb].
///
/// Expression evaluation and canonical read projection share this shape so
/// a projected protocol color equals the color the Kotlin evaluator produces.
skir.DataValue colorValue(int argb) => skir.DataValue.createNamed(
  actualType: expressionColorUse,
  payload: skir.DataValue.wrapInteger(argb.toString()),
);

skir.NamedTypeUse _declaredUse(String id) => skir.NamedTypeUse(
  definition: skir.TypeDefinitionId(
    typeId: skir.TypeId.createDeclared(value: id),
    revision: 1,
  ),
  arguments: const [],
);

/// The declared Icon type and its Iconify and SVG variants.
final expressionIconUse = _declaredUse("6fffa4398c0b4611bbf3517e047e6a52");
final _iconifyUse = _declaredUse("3845952a4d714e23ad55f07051669930");
final _svgIconUse = _declaredUse("67ed1a5b0e534c05b8d233ef9783971b");

/// Builds the declared Icon data value of [icon], the shape the Kotlin
/// evaluator produces, so a projected type display icon equals an authored one.
skir.DataValue iconValue(skir.Icon icon) => switch (icon) {
  skir.Icon_svgWrapper(:final value) => skir.DataValue.createNamed(
    actualType: _svgIconUse,
    payload: skir.DataValue.createRecord(
      fields: [
        skir.FieldValue(
          name: "source",
          value: skir.DataValue.wrapStringValue(value),
        ),
      ],
    ),
  ),
  skir.Icon_iconifyWrapper(:final value) => _iconifyValue(value),
  _ => _iconifyValue(""),
};

skir.DataValue _iconifyValue(String value) => skir.DataValue.createNamed(
  actualType: _iconifyUse,
  payload: skir.DataValue.createRecord(
    fields: [
      skir.FieldValue(
        name: "value",
        value: skir.DataValue.wrapStringValue(value),
      ),
    ],
  ),
);

/// Reads a declared Icon data value back into its wire form; null when
/// [value] is not an Iconify or SVG icon.
skir.Icon? decodeIconValue(skir.DataValue value) {
  if (value is! skir.DataValue_namedWrapper) return null;
  final payload = value.value.payload;
  if (payload is! skir.DataValue_recordWrapper) return null;
  String? field(String name) => payload.value.fields
      .where((field) => field.name == name)
      .firstOrNull
      ?.value
      .authoredString;
  final type = value.value.actualType;
  if (type == _iconifyUse) {
    return switch (field("value")) {
      final name? => skir.Icon.wrapIconify(name),
      null => null,
    };
  }
  if (type == _svgIconUse) {
    return switch (field("source")) {
      final source? => skir.Icon.wrapSvg(source),
      null => null,
    };
  }
  return null;
}

extension ExpressionTypes on CheckedEditorCatalog {
  skir.ExpressionMappingType? expressionMapping(skir.ExpressionType source) {
    if (source.value case skir.ExpressionValueType_mapWrapper(:final value)) {
      return value;
    }
    if (source.value is! skir.ExpressionValueType_nominalWrapper) return null;
    final named = namedUse(
      (source.value as skir.ExpressionValueType_nominalWrapper).value,
    );
    if (named == null) return null;
    final representation = published(named.definition)
        ?.definition
        .representation;
    if (representation case skir.RepresentationTemplate_mappingWrapper(
      :final value,
    )) {
      final owner = skir.TypeSelection.wrapComplete(named);
      final key = applyTemplate(value.key, owner);
      final item = applyTemplate(value.value, owner);
      return key == null || item == null
          ? null
          : skir.ExpressionMappingType(
              key: nominalType(key),
              value: nominalType(item),
            );
    }
    final id = named.definition.typeId;
    if (id is skir.TypeId_qualifiedWrapper &&
        id.value.namespace == "typewriter" &&
        id.value.name == "Map" &&
        named.definition.revision == 1 &&
        named.arguments.length == 2) {
      return skir.ExpressionMappingType(
        key: nominalType(named.arguments.first),
        value: nominalType(named.arguments.last),
      );
    }
    return null;
  }

  skir.ExpressionType? collectionItem(skir.ExpressionType source) {
    final mapping = expressionMapping(source);
    if (mapping != null) return entryType(mapping.key, mapping.value);
    switch (source.value) {
      case skir.ExpressionValueType_listWrapper(:final value):
        return value;
      case skir.ExpressionValueType_nominalWrapper(:final value):
        final named = namedUse(value);
        if (named == null) return null;
        final representation = published(named.definition)
            ?.definition
            .representation;
        if (representation case skir.RepresentationTemplate_sequenceWrapper(
          :final value,
        )) {
          final item = applyTemplate(
            value.item,
            skir.TypeSelection.wrapComplete(named),
          );
          return item == null ? null : nominalType(item);
        }
        return canonicalBuiltinItem(source);
      default:
        return null;
    }
  }
}

skir.ExpressionType? canonicalBuiltinItem(skir.ExpressionType source) {
  if (source.value is! skir.ExpressionValueType_nominalWrapper) return null;
  final use = (source.value as skir.ExpressionValueType_nominalWrapper).value;
  if (use is! skir.TypeUse_namedWrapper || use.value.definition.revision != 1) {
    return null;
  }
  final id = use.value.definition.typeId;
  if (id is! skir.TypeId_qualifiedWrapper ||
      id.value.namespace != "typewriter") {
    return null;
  }
  final args = use.value.arguments.toList();
  if ({"List", "Set"}.contains(id.value.name) && args.length == 1) {
    return nominalType(args.single);
  }
  if (id.value.name == "Map" && args.length == 2) {
    return entryType(nominalType(args[0]), nominalType(args[1]));
  }
  return null;
}
// Arbitrary extension containers take the checked representation substitution
// branch shown above. This fallback only recognizes canonical v1 constructors.
