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

enum CanonicalQueryOperation {
  resourceIdentity("typewriter.resource.id"),
  resourceValue("typewriter.resource.value"),
  resourceConfiguration("typewriter.resource.configuration"),
  valueConfiguration("typewriter.value.configuration"),
  catalogDeclaration("typewriter.catalog.declaration");

  const CanonicalQueryOperation(this.id);
  final String id;
  static CanonicalQueryOperation? fromId(String id) =>
      values.where((value) => value.id == id).firstOrNull;
}

@freezed
abstract class ExpressionOccurrence with _$ExpressionOccurrence {
  const factory ExpressionOccurrence({required List<int> path}) =
      _ExpressionOccurrence;
}

@freezed
abstract class CheckedQueryCall with _$CheckedQueryCall {
  const factory CheckedQueryCall({
    required CanonicalQueryOperation operation,
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

@freezed
abstract class CanonicalLeafProjection with _$CanonicalLeafProjection {
  const factory CanonicalLeafProjection({
    required skir.ExpressionCall root,
    required List<String> fields,
  }) = _CanonicalLeafProjection;
}

extension CanonicalExpressionProjection on skir.ExpressionNode {
  CanonicalLeafProjection? get canonicalLeafProjection {
    final fields = <String>[];
    var current = this;
    while (true) {
      if (current is! skir.ExpressionNode_callWrapper) break;
      final value = current.value;
      if (value.operation.value != "typewriter.record.field" ||
          value.arguments.length != 2) {
        break;
      }
      if (fields.length >= 512) return null;
      if (value.arguments.elementAt(1) case skir.ExpressionNode_literalWrapper(
        value: skir.DataValue_stringValueWrapper(value: final field),
      )) {
        fields.add(field);
        current = value.arguments.elementAt(0);
      } else {
        return null;
      }
    }
    if (current case skir.ExpressionNode_callWrapper(:final value)
        when CanonicalQueryOperation.fromId(value.operation.value) != null) {
      return CanonicalLeafProjection(
        root: value,
        fields: fields.reversed.toList(),
      );
    }
    return null;
  }
}

skir.DataValue _namedColor(int value) => skir.DataValue.createNamed(
  actualType: skir.NamedTypeUse(
    definition: skir.TypeDefinitionId(
      typeId: skir.TypeId.createDeclared(
        value: "c15fe94d13fb4317924a0ad2072defe4",
      ),
      revision: 1,
    ),
    arguments: const [],
  ),
  payload: skir.DataValue.wrapInteger(value.toString()),
);

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

  _Evaluation _query(CanonicalLeafProjection projection) {
    final root = projection.root;
    final rootPath = [
      ..._occurrence,
      for (var i = 0; i < projection.fields.length; i++) 0,
    ];
    final contract = queryContracts[ExpressionOccurrence(path: rootPath)];
    if (contract == null) {
      throw const _ExpressionFailure(
        "unchecked_query",
        "Canonical queries require a checked expression program",
      );
    }
    final environment = queries;
    final operation = contract.operation;
    if (operation != CanonicalQueryOperation.valueConfiguration &&
        environment == null) {
      throw const _ExpressionFailure(
        "unsupported_query",
        "This expression has no canonical query observation",
      );
    }
    final previous = _occurrence;
    _occurrence = rootPath;
    try {
      // Each skipped field call and literal still consumes its normal steps.
      for (var i = 0; i < projection.fields.length; i++) {
        _consumeStep();
        _consumeStep();
      }
      final input = _child(root.arguments.first, 0);
      if (input is _Unavailable) return input;
      final source = (input as _Available).value;
      if (source == skir.DataValue.unfilled || source == skir.DataValue.null_) {
        return const _Unavailable();
      }
      if (root.arguments.length == 2) {
        final witness = _child(root.arguments.elementAt(1), 1);
        if (witness is _Unavailable) return witness;
      }
      Object native;
      skir.ReflectiveTypeDescriptor<dynamic>? descriptor;
      if (operation == CanonicalQueryOperation.valueConfiguration) {
        if (source case skir.DataValue_namedWrapper(:final value)) {
          native = skir.TypeSelection.wrapComplete(value.actualType);
          descriptor = skir.TypeSelection.serializer.typeDescriptor;
        } else {
          return const _Unavailable();
        }
      } else if (operation == CanonicalQueryOperation.catalogDeclaration) {
        final selection = canonicalReadModels.decodeTypeSelection(source);
        final definition = switch (selection) {
          skir.TypeSelection_completeWrapper(:final value) => value.definition,
          skir.TypeSelection_pendingWrapper(:final value) => value.definition,
          _ => throw const _ExpressionFailure(
            "invalid_type_selection",
            "The canonical type selection is unknown",
          ),
        };
        final declaration = environment!.declaration(definition);
        if (declaration == null) {
          return const _Unavailable();
        }
        native = declaration;
        descriptor = skir.PublishedType.serializer.typeDescriptor;
      } else {
        if (environment!.authored == null) {
          throw const _ExpressionFailure(
            "unsupported_query",
            "Resource queries need an authoring observation",
          );
        }
        final id = contract.sourceIsReference
            ? switch (_unwrap(source)) {
                skir.DataValue_linkWrapper(:final value) =>
                  value.target.resource,
                _ => throw const _ExpressionFailure(
                  "expected_link",
                  "The canonical resource query expected a relationship",
                ),
              }
            : skir.ResourceId(value: _text(source));
        final fields = projection.fields;
        final path = skir.ValuePath(
          segments: [
            for (final field in fields)
              skir.PathSegment.createField(name: field),
          ],
        );
        _reads.add(
          PortableExpressionRead(
            skir.ExpressionBindingId(value: "query.resource"),
            path,
            location: skir.ValueLocation(
              resource: id,
              path: operation == CanonicalQueryOperation.resourceValue
                  ? path
                  : editorRootPath,
            ),
          ),
        );
        final record = environment.resource(id);
        if (record == null) return const _Unavailable();
        final expected = contract.targetType;
        if (expected != null &&
            !_querySelectionMatches(
              environment.catalog,
              record.configuration,
              expected,
            )) {
          return const _Unavailable();
        }
        if (operation == CanonicalQueryOperation.resourceIdentity) {
          return _Available(id.toExpressionValue());
        }
        if (operation == CanonicalQueryOperation.resourceValue) {
          final payload = skir.DataValue.createRecord(fields: record.fields);
          final result = fields.isEmpty
              ? PortablePathValue(payload)
              : payload.readAt(path);
          if (result case PortablePathValue(:final value)) {
            if (value == skir.DataValue.unfilled) return const _Unavailable();
            final selection = record.configuration;
            final schema = fields.isEmpty
                ? switch (selection) {
                    skir.TypeSelection_completeWrapper(:final value) =>
                      skir.TypeUse.wrapNamed(value),
                    _ => null,
                  }
                : environment.catalog.valueTypeAt(selection, path);
            if (schema == null && fields.isNotEmpty) {
              return const _Unavailable();
            }
            final actual =
                fields.isEmpty &&
                    selection is skir.TypeSelection_completeWrapper
                ? skir.DataValue.createNamed(
                    actualType: selection.value,
                    payload: payload,
                  )
                : value;
            _chargeCanonicalValue(actual, 0);
            if (schema != null &&
                environment.catalog
                    .inspectPortableValue(schema, actual)
                    .structuralProblems
                    .isNotEmpty) {
              throw const _ExpressionFailure(
                "invalid_resource_value",
                "The resource value does not match its checked schema",
              );
            }
            return actual == skir.DataValue.null_
                ? const _Unavailable()
                : _Available(actual);
          }
          if (record.configuration is skir.TypeSelection_completeWrapper) {
            throw const _ExpressionFailure(
              "invalid_resource_value",
              "The complete resource is missing a declared field",
            );
          }
          return const _Unavailable();
        }
        native = record.configuration;
        descriptor = skir.TypeSelection.serializer.typeDescriptor;
      }
      final value = canonicalReadModels.project(
        native,
        descriptor,
        projection.fields,
        _consumeStep,
        _consumeCollectionItems,
      );
      return value == skir.DataValue.null_ || value == skir.DataValue.unfilled
          ? const _Unavailable()
          : _Available(value);
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
}

@freezed
abstract class _ExpressionProgramKey with _$ExpressionProgramKey {
  const factory _ExpressionProgramKey({
    required skir.ExpressionNode body,
    required Map<skir.ExpressionBindingId, PortablePresentationBindingSchema>
    lexicalTypes,
  }) = __ExpressionProgramKey;
}

/// Compiled query signatures belong to the checked catalog and lexical schema.
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
      bindings: {
        for (final entry in lexicalTypes.entries)
          if (entry.value case CompletePortablePresentationBinding(:final use))
            entry.key: skir.ExpressionType(value: use, mayBeMissing: true),
      },
      resolveBinding: (read) {
        final schema = lexicalTypes[read.binding];
        if (schema case PartialPortablePresentationBinding(:final selection)) {
          final use = catalog.valueTypeAt(selection, read.path);
          return use == null
              ? null
              : skir.ExpressionType(value: use, mayBeMissing: true);
        }
        return null;
      },
      resolvePath: catalog.expressionPathType,
      normalizeType: catalog.expressionPayloadType,
      resolveCollectionItem: catalog.collectionItemType,
      resolveQuery: (call, arguments, scope, occurrence) {
        final contract = catalog.checkCanonicalQuery(call, arguments);
        if (contract != null) {
          contracts[ExpressionOccurrence(path: occurrence)] = contract;
        }
        return contract?.result;
      },
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
    final named = namedUse(source.value);
    if (named == null) return null;
    final use = valueTypeAt(skir.TypeSelection.wrapComplete(named), path);
    return use == null
        ? null
        : skir.ExpressionType(value: use, mayBeMissing: true);
  }

  CheckedQueryCall? checkCanonicalQuery(
    skir.ExpressionCall call,
    List<skir.ExpressionType> arguments,
  ) {
    final operation = CanonicalQueryOperation.fromId(call.operation.value);
    if (operation == null) return null;
    skir.TypeUse? target;
    var reference = false;
    if ({
      CanonicalQueryOperation.resourceIdentity,
      CanonicalQueryOperation.resourceValue,
      CanonicalQueryOperation.resourceConfiguration,
    }.contains(operation)) {
      if (arguments.length == 2) {
        if (arguments.first.value !=
            skir.TypeUse.wrapNamed(frameworkResourceIdUse)) {
          return null;
        }
        final witness = call.arguments.elementAt(1);
        if (witness is! skir.ExpressionNode_literalWrapper) return null;
        final witnessType = namedUse(arguments.elementAt(1).value);
        if (witnessType == null ||
            !isReadyApplication(witnessType) ||
            !isReadableAs(
              arguments.elementAt(1).value,
              canonicalReadModels.typeUseUse,
            )) {
          return null;
        }
        try {
          target = canonicalReadModels.decodeTypeUse(witness.value);
        } on FormatException {
          return null;
        } on _ExpressionFailure {
          return null;
        }
        if (target is! skir.TypeUse_namedWrapper ||
            !isReadyApplication(target.value)) {
          return null;
        }
      } else if (arguments.length == 1) {
        final use = namedUse(arguments.single.value);
        if (use == null) return null;
        final representation = published(use.definition)
            ?.definition
            .representation;
        if (representation is! skir.RepresentationTemplate_linkWrapper) {
          return null;
        }
        target = applyTemplate(
          representation.value.target,
          skir.TypeSelection.wrapComplete(use),
        );
        if (target == null) return null;
        reference = true;
      } else {
        return null;
      }
    } else if (arguments.length != 1) {
      return null;
    } else if (operation == CanonicalQueryOperation.catalogDeclaration &&
        !isReadableAs(
          arguments.single.value,
          canonicalReadModels.typeSelectionUse,
        )) {
      return null;
    }
    final result = switch (operation) {
      CanonicalQueryOperation.resourceIdentity => skir.TypeUse.wrapNamed(
        frameworkResourceIdUse,
      ),
      CanonicalQueryOperation.resourceValue => target!,
      CanonicalQueryOperation.resourceConfiguration ||
      CanonicalQueryOperation.valueConfiguration =>
        canonicalReadModels.typeSelectionUse,
      CanonicalQueryOperation.catalogDeclaration =>
        canonicalReadModels.publishedTypeUse,
    };
    return CheckedQueryCall(
      operation: operation,
      targetType: target,
      result: skir.ExpressionType(value: result, mayBeMissing: true),
      sourceIsReference: reference,
    );
  }
}

extension CanonicalQueryPresence on skir.ExpressionNode {
  bool get hasCanonicalQueries => switch (this) {
    skir.ExpressionNode_callWrapper(:final value) =>
      CanonicalQueryOperation.fromId(value.operation.value) != null ||
          value.arguments.any((node) => node.hasCanonicalQueries),
    skir.ExpressionNode_andWrapper(:final value) =>
      value.left.hasCanonicalQueries || value.right.hasCanonicalQueries,
    skir.ExpressionNode_orWrapper(:final value) =>
      value.left.hasCanonicalQueries || value.right.hasCanonicalQueries,
    skir.ExpressionNode_conditionalWrapper(:final value) =>
      value.test.hasCanonicalQueries ||
          value.yes.hasCanonicalQueries ||
          value.no.hasCanonicalQueries,
    skir.ExpressionNode_orElseWrapper(:final value) =>
      value.input.hasCanonicalQueries || value.fallback.hasCanonicalQueries,
    skir.ExpressionNode_collectionWrapper(:final value) =>
      value.input.hasCanonicalQueries ||
          value.arguments.any((node) => node.hasCanonicalQueries) ||
          (value.body?.hasCanonicalQueries ?? false),
    _ => false,
  };
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
