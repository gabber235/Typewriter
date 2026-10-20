import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Checks one expression against one catalog and lexical input environment.
/// Frames and literal coercion evidence belong to this invocation. Invalid
/// expressions return their primary diagnostic; callers aggregate siblings.
/// External schemas are admitted when read. Unused presentation context does
/// not constrain an expression that only reads a selected value.
List<String> checkPortableExpression(
  skir.ExpressionNode body, {
  required CheckedEditorCatalog catalog,
  required Map<skir.ExpressionBindingId, skir.ExpressionType> bindings,
  Map<skir.ExpressionBindingId, skir.TypeSelection> partialBindings = const {},
  skir.ExpressionType? expectedOutput,
  bool allowResultNumericWidth = false,
  void Function(skir.ExpressionType?)? onInferred,
  Map<ExpressionOccurrence, CheckedQueryCall>? queryContracts,
}) {
  final checker = _PortableExpressionChecker(
    catalog,
    Map.unmodifiable(bindings),
    Map.unmodifiable(partialBindings),
    expectedOutput: expectedOutput,
  );
  try {
    if (expectedOutput != null) checker.validateType(expectedOutput);
    final result = expectedOutput == null
        ? checker.infer(body)
        : checker.contextualEmpty(body, expectedOutput) ?? checker.infer(body);
    onInferred?.call(result);
    final errors = <String>[];
    if (expectedOutput != null) {
      if (!checker.compatible(result, expectedOutput) &&
          !(allowResultNumericWidth &&
              checker.sameNumericFamily(result, expectedOutput))) {
        errors.add("incompatible_expression_result_type");
      }
      if (result.mayBeMissing && !expectedOutput.mayBeMissing) {
        errors.add("expression_result_may_be_missing");
      }
    }
    // Invalid programs do not leak partial query contracts into the cache.
    if (errors.isEmpty) queryContracts?.addAll(checker.queryContracts);
    return List.unmodifiable(errors);
  } on ExpressionProblem catch (error) {
    onInferred?.call(null);
    return [error.code];
  } finally {
    checker.frames.clear();
    checker.literalTypes.clear();
    checker.queryContracts.clear();
  }
}

final class _PortableExpressionChecker {
  _PortableExpressionChecker(
    this.catalog,
    this.inputs,
    this.partialInputs, {
    this.expectedOutput,
  });
  final CheckedEditorCatalog catalog;
  final Map<skir.ExpressionBindingId, skir.ExpressionType> inputs;
  final Map<skir.ExpressionBindingId, skir.TypeSelection> partialInputs;
  final skir.ExpressionType? expectedOutput;
  final frames = <List<skir.ExpressionType>>[];
  final literalTypes = HashSet<skir.ExpressionType>.identity();
  final queryContracts = <ExpressionOccurrence, CheckedQueryCall>{};
  int depth = 0;
  List<int> occurrence = <int>[];
  final text = skir.TypeUse.wrapScalar(skir.ScalarKind.text);
  final boolean = skir.TypeUse.wrapScalar(skir.ScalarKind.boolean);
  final integer = skir.TypeUse.wrapScalar(
    skir.ScalarKind.createInteger(width: skir.IntegerWidth.signedSixtyFour),
  );
  final floating = skir.TypeUse.wrapScalar(
    skir.ScalarKind.createFloat(width: skir.FloatWidth.sixtyFour),
  );
  final decimal = skir.TypeUse.wrapScalar(skir.ScalarKind.decimal);

  skir.ExpressionType inferChild(skir.ExpressionNode node, int child) {
    if (++depth > 512) throw const ExpressionProblem("expression_check_limit");
    final previous = occurrence;
    occurrence = [...previous, child];
    try {
      return infer(node);
    } finally {
      occurrence = previous;
      depth--;
    }
  }

  T inFrame<T>(List<skir.ExpressionType> values, T Function() body) {
    frames.add(List.unmodifiable(values));
    try {
      return body();
    } finally {
      frames.removeLast();
    }
  }

  skir.ExpressionType local(skir.ExpressionLocal ref) {
    if (ref.depth < 0 || ref.slot < 0 || ref.depth >= frames.length) {
      throw const ExpressionProblem("invalid_expression_local");
    }
    final frame = frames[frames.length - 1 - ref.depth];
    if (ref.slot >= frame.length) {
      throw const ExpressionProblem("invalid_expression_local");
    }
    return readTypePath(frame[ref.slot], ref.path);
  }

  skir.ExpressionType inferInput(skir.ExpressionInput value) {
    final partial = partialInputs[value.binding];
    if (partial != null) {
      final use = catalog.valueTypeAt(partial, value.path);
      if (use == null) throw const ExpressionProblem("invalid_expression_path");
      return nominalType(use, true);
    }
    final input = inputs[value.binding];
    if (input == null) {
      throw const ExpressionProblem("unknown_expression_binding");
    }
    validateType(input);
    return readTypePath(input, value.path);
  }

  void validateType(skir.ExpressionType type) {
    switch (type.value) {
      case skir.ExpressionValueType_nominalWrapper(:final value):
        if (!catalog.isReadyTypeUse(value)) {
          throw const ExpressionProblem("invalid_expression_type");
        }
      case skir.ExpressionValueType_listWrapper(:final value) ||
          skir.ExpressionValueType_nullableWrapper(:final value):
        validateType(value);
      case skir.ExpressionValueType_mapWrapper(:final value) ||
          skir.ExpressionValueType_entryWrapper(:final value):
        validateType(value.key);
        validateType(value.value);
      case skir.ExpressionValueType.nullValue:
        break;
      default:
        throw const ExpressionProblem("invalid_expression_type");
    }
  }

  skir.ExpressionType infer(skir.ExpressionNode node) {
    final projection = node.readProjection(remainingDepth: 512 - depth);
    if (projection != null) return inferProjection(projection);
    switch (node) {
      case skir.ExpressionNode_literalWrapper(:final value):
        return inferLiteral(value);
      case skir.ExpressionNode_fieldWrapper(:final value):
        return readTypePath(
          inferChild(value.source, 0),
          editorRootPath.field(value.name),
        );
      case skir.ExpressionNode_entryProjectionWrapper(:final value):
        final segment = switch (value.branch) {
          skir.EntryBranch.key => skir.PathSegment.mapKey,
          skir.EntryBranch.value => skir.PathSegment.mapValue,
          _ => throw const ExpressionProblem("invalid_entry_projection"),
        };
        return readTypePath(
          inferChild(value.source, 0),
          skir.ValuePath(segments: [segment]),
        );
      case skir.ExpressionNode_andWrapper(:final value) ||
          skir.ExpressionNode_orWrapper(:final value):
        final left = inferChild(value.left, 0);
        final right = inferChild(value.right, 1);
        requireScalar(left, boolean);
        requireScalar(right, boolean);
        return nominalType(boolean, left.mayBeMissing || right.mayBeMissing);
      case skir.ExpressionNode_conditionalWrapper(:final value):
        final test = inferChild(value.test, 0);
        requireScalar(test, boolean);
        var yes = isEmptyLiteral(value.yes) ? null : inferChild(value.yes, 1);
        var no = isEmptyLiteral(value.no) ? null : inferChild(value.no, 2);
        if (yes == null && no != null) yes = contextualEmpty(value.yes, no);
        if (no == null && yes != null) no = contextualEmpty(value.no, yes);
        if (yes == null || no == null) {
          throw const ExpressionProblem("expression_type_inference_failed");
        }
        return withMissing(
          join(yes, no),
          test.mayBeMissing || yes.mayBeMissing || no.mayBeMissing,
        );
      case skir.ExpressionNode_orElseWrapper(:final value):
        final input = inferChild(value.input, 0);
        final fallback =
            contextualEmpty(value.fallback, input) ??
            inferChild(value.fallback, 1);
        final shape = canonicalShape(input);
        if (shape.value == skir.ExpressionValueType.nullValue) return fallback;
        final nonnull = shape.value is skir.ExpressionValueType_nullableWrapper
            ? (shape.value as skir.ExpressionValueType_nullableWrapper).value
            : shape;
        final joined = join(withMissing(nonnull, false), fallback);
        return input.mayBeMissing ||
                shape.value is skir.ExpressionValueType_nullableWrapper
            ? withMissing(joined, fallback.mayBeMissing)
            : withMissing(input, false);
      case skir.ExpressionNode_mapWrapper(:final value):
        return inferUnary(value, (_, body, missing) => listType(body, missing));
      case skir.ExpressionNode_flatMapWrapper(:final value):
        return inferUnary(
          value,
          (_, body, missing) => listType(requireItem(body), missing),
        );
      case skir.ExpressionNode_groupByWrapper(:final value):
        return inferUnary(
          value,
          (item, key, missing) => mapType(key, listType(item), missing),
        );
      case skir.ExpressionNode_foldWrapper(:final value):
        final source = inferChild(value.source, 0);
        final initial = inferChild(value.initial, 1);
        final body = inFrame([
          initial,
          requireItem(source),
        ], () => inferChild(value.body, 2));
        if (!compatible(body, initial)) {
          throw const ExpressionProblem("incompatible_expression_accumulator");
        }
        return withMissing(
          join(initial, body),
          source.mayBeMissing || initial.mayBeMissing || body.mayBeMissing,
        );
      case skir.ExpressionNode_reduceWrapper(:final value):
        final source = inferChild(value.source, 0);
        final item = requireItem(source);
        final body = inFrame([item, item], () => inferChild(value.body, 1));
        if (!compatible(body, item)) {
          throw const ExpressionProblem("incompatible_expression_accumulator");
        }
        return nullableType(join(item, body))
            .withMissing(source.mayBeMissing || body.mayBeMissing);
      case skir.ExpressionNode_sortWithWrapper(:final value):
        final source = inferChild(value.source, 0);
        final item = requireItem(source);
        final result = inFrame([
          item,
          item,
        ], () => inferChild(value.comparator, 1));
        requireNumber(result);
        return withMissing(source, source.mayBeMissing || result.mayBeMissing);
      case skir.ExpressionNode_sortByWrapper(:final value):
        final source = inferChild(value.source, 0);
        final item = requireItem(source);
        var missing = source.mayBeMissing;
        if (value.descending case final direction?) {
          final type = inferChild(direction, 1);
          requireScalar(type, boolean);
          missing |= type.mayBeMissing;
        }
        final key = inFrame([item], () => inferChild(value.key, 2));
        final use = nominalUse(key);
        if (use == null ||
            !(family(use) != null ||
                {
                  text,
                  boolean,
                  skir.TypeUse.wrapScalar(skir.ScalarKind.timestamp),
                  skir.TypeUse.wrapScalar(skir.ScalarKind.duration),
                }.contains(catalog.expressionPayloadType(use)))) {
          throw const ExpressionProblem("invalid_expression_operand_type");
        }
        return withMissing(source, missing || key.mayBeMissing);
      case skir.ExpressionNode_anyWrapper(:final value) ||
          skir.ExpressionNode_allWrapper(:final value) ||
          skir.ExpressionNode_noneWrapper(:final value) ||
          skir.ExpressionNode_filterWrapper(:final value) ||
          skir.ExpressionNode_findWrapper(:final value) ||
          skir.ExpressionNode_findLastWrapper(:final value) ||
          skir.ExpressionNode_countWrapper(:final value) ||
          skir.ExpressionNode_distinctByWrapper(:final value) ||
          skir.ExpressionNode_uniqueByWrapper(:final value):
        final source = inferChild(value.source, 0);
        final item = requireItem(source);
        final body = inFrame([item], () => inferChild(value.body, 1));
        final missing = source.mayBeMissing || body.mayBeMissing;
        if (node is! skir.ExpressionNode_distinctByWrapper &&
            node is! skir.ExpressionNode_uniqueByWrapper) {
          requireScalar(body, boolean);
        }
        if (node is skir.ExpressionNode_anyWrapper ||
            node is skir.ExpressionNode_allWrapper ||
            node is skir.ExpressionNode_noneWrapper ||
            node is skir.ExpressionNode_uniqueByWrapper) {
          return nominalType(boolean, missing);
        }
        if (node is skir.ExpressionNode_countWrapper) {
          return nominalType(integer, missing);
        }
        if (node is skir.ExpressionNode_findWrapper ||
            node is skir.ExpressionNode_findLastWrapper) {
          return withMissing(nullableType(item), missing);
        }
        return withMissing(source, missing);
      case skir.ExpressionNode_takeWrapper(:final value) ||
          skir.ExpressionNode_skipWrapper(:final value):
        final source = inferChild(value.source, 0);
        final count = inferChild(value.count, 1);
        requireItem(source);
        requireInteger(count);
        return withMissing(source, source.mayBeMissing || count.mayBeMissing);
      case skir.ExpressionNode_reverseWrapper(:final value) ||
          skir.ExpressionNode_distinctWrapper(:final value):
        final source = inferChild(value, 0);
        requireItem(source);
        return source;
      case skir.ExpressionNode_unknown():
        throw const ExpressionProblem("unknown_expression");
      default:
        return inferScalar(node);
    }
  }

  bool isEmptyLiteral(skir.ExpressionNode node) => switch (node) {
    skir.ExpressionNode_literalWrapper(
      value: skir.DataValue_listValueWrapper(:final value),
    ) =>
      value.items.isEmpty,
    skir.ExpressionNode_literalWrapper(
      value: skir.DataValue_setValueWrapper(:final value),
    ) =>
      value.items.isEmpty,
    skir.ExpressionNode_literalWrapper(
      value: skir.DataValue_mapValueWrapper(:final value),
    ) =>
      value.rows.isEmpty,
    _ => false,
  };

  skir.ExpressionType? contextualEmpty(
    skir.ExpressionNode node,
    skir.ExpressionType context,
  ) {
    if (!isEmptyLiteral(node)) return null;
    if (depth >= 512) throw const ExpressionProblem("expression_check_limit");
    var shape = canonicalShape(context);
    if (shape.value case skir.ExpressionValueType_nullableWrapper(
      :final value,
    )) {
      shape = canonicalShape(value);
    }
    final literal = (node as skir.ExpressionNode_literalWrapper).value;
    if (literal is skir.DataValue_listValueWrapper &&
        shape.value is skir.ExpressionValueType_listWrapper) {
      return listType(
        (shape.value as skir.ExpressionValueType_listWrapper).value,
      );
    }
    if (literal is skir.DataValue_mapValueWrapper) {
      final mapping = catalog.expressionMapping(shape);
      if (mapping != null) return mapType(mapping.key, mapping.value);
    }
    if (literal is skir.DataValue_setValueWrapper &&
        shape.value is skir.ExpressionValueType_nominalWrapper) {
      final use =
          (shape.value as skir.ExpressionValueType_nominalWrapper).value;
      if (use is skir.TypeUse_namedWrapper &&
          use.value.definition ==
              (standardUse(
                "Set",
                const [],
              ) as skir.TypeUse_namedWrapper).value.definition) {
        return withMissing(shape, false);
      }
    }
    return null;
  }

  skir.ExpressionType inferLiteral(skir.DataValue value) {
    if (++depth > 512) throw const ExpressionProblem("expression_check_limit");
    try {
      return _inferLiteral(value);
    } finally {
      depth--;
    }
  }

  skir.ExpressionType _inferLiteral(skir.DataValue value) {
    final validScalar = switch (value) {
      skir.DataValue_integerWrapper(:final value) =>
        RegExp(r"^[+-]?[0-9]+$").hasMatch(value) &&
            BigInt.tryParse(value) != null,
      skir.DataValue_floatWrapper(:final value) => value.isFinite,
      skir.DataValue_decimalWrapper() => admitsPortableScalarValue(
        skir.ScalarKind.decimal,
        value,
      ),
      _ => true,
    };
    if (!validScalar) {
      throw const ExpressionProblem("invalid_expression_literal");
    }
    if (value case skir.DataValue_namedWrapper(:final value)) {
      final type = nominalType(skir.TypeUse.wrapNamed(value.actualType));
      validateType(type);
      return type;
    }
    if (value == skir.DataValue.null_) {
      return skir.ExpressionType(
        value: skir.ExpressionValueType.nullValue,
        mayBeMissing: false,
      );
    }
    if (value == skir.DataValue.unfilled) {
      if (expectedOutput case final expected?) {
        return withMissing(expected, true);
      }
      throw const ExpressionProblem("expression_type_inference_failed");
    }
    return switch (value) {
      skir.DataValue_integerWrapper() => numericLiteral(integer),
      skir.DataValue_floatWrapper() => numericLiteral(floating),
      skir.DataValue_decimalWrapper() => numericLiteral(decimal),
      skir.DataValue_stringValueWrapper() => nominalType(text),
      skir.DataValue_booleanWrapper() => nominalType(boolean),
      skir.DataValue_durationWrapper() => nominalType(
        skir.TypeUse.wrapScalar(skir.ScalarKind.duration),
      ),
      skir.DataValue_timestampWrapper() => nominalType(
        skir.TypeUse.wrapScalar(skir.ScalarKind.timestamp),
      ),
      skir.DataValue_bytesWrapper() => nominalType(
        skir.TypeUse.wrapScalar(skir.ScalarKind.bytes),
      ),
      skir.DataValue_listValueWrapper(:final value) => inferLiteralItems(
        value.items.map((v) => v.value).toList(),
      ),
      skir.DataValue_setValueWrapper(:final value) => inferSetItems(
        value.items.map((v) => v.value).toList(),
      ),
      skir.DataValue_mapValueWrapper(:final value) => inferMapRows(
        value.rows.toList(),
      ),
      _ => throw const ExpressionProblem("expression_type_inference_failed"),
    };
  }

  skir.ExpressionType inferLiteralItems(List<skir.DataValue> values) {
    final populated = values
        .where((value) => value != skir.DataValue.unfilled)
        .toList();
    if (populated.isEmpty) {
      throw const ExpressionProblem("expression_type_inference_failed");
    }
    var item = inferLiteral(populated.first);
    for (final next in populated.skip(1)) {
      item = join(item, inferLiteral(next));
    }
    if (populated.length != values.length) item = withMissing(item, true);
    return listType(item);
  }

  skir.ExpressionType inferSetItems(List<skir.DataValue> values) {
    final list = inferLiteralItems(values);
    final item = (list.value as skir.ExpressionValueType_listWrapper).value
        .declaredUse();
    if (item == null) {
      throw const ExpressionProblem("expression_type_inference_failed");
    }
    return nominalType(standardUse("Set", [item]));
  }

  skir.ExpressionType inferMapRows(List<skir.MapRow> rows) {
    if (rows.isEmpty) {
      throw const ExpressionProblem("expression_type_inference_failed");
    }
    var key = inferLiteral(rows.first.key);
    var value = inferLiteral(rows.first.value);
    for (final row in rows.skip(1)) {
      key = join(key, inferLiteral(row.key));
      value = join(value, inferLiteral(row.value));
    }
    return mapType(key, value);
  }

  skir.ExpressionType numericLiteral(skir.TypeUse type) {
    final result = nominalType(type);
    literalTypes.add(result);
    return result;
  }

  skir.ExpressionType inferUnary(
    skir.UnaryCollectionExpression value,
    skir.ExpressionType Function(skir.ExpressionType, skir.ExpressionType, bool)
    result,
  ) {
    final source = inferChild(value.source, 0);
    final item = requireItem(source);
    final body = inFrame([item], () => inferChild(value.body, 1));
    return result(item, body, source.mayBeMissing || body.mayBeMissing);
  }

  skir.ExpressionType requireItem(skir.ExpressionType source) =>
      catalog.collectionItem(source) ??
      (throw const ExpressionProblem("expression_collection_expected"));
  skir.TypeUse? nominalUse(skir.ExpressionType type) => switch (type.value) {
    skir.ExpressionValueType_nominalWrapper(:final value) => value,
    _ => null,
  };
  void requireScalar(skir.ExpressionType actual, skir.TypeUse expected) {
    final use = nominalUse(actual);
    if (use == null ||
        catalog.expressionPayloadType(use) !=
            catalog.expressionPayloadType(expected)) {
      throw const ExpressionProblem("invalid_expression_operand_type");
    }
  }

  void requireNumber(skir.ExpressionType type) {
    if (family(nominalUse(type)) == null) {
      throw const ExpressionProblem("invalid_expression_operand_type");
    }
  }

  void requireInteger(skir.ExpressionType type) {
    if (family(nominalUse(type)) != "integer") {
      throw const ExpressionProblem("invalid_expression_operand_type");
    }
  }

  String? family(skir.TypeUse? use) => use == null
      ? null
      : switch (catalog.expressionPayloadType(use)) {
          skir.TypeUse_scalarWrapper(value: skir.ScalarKind_integerWrapper()) =>
            "integer",
          skir.TypeUse_scalarWrapper(value: skir.ScalarKind_floatWrapper()) =>
            "float",
          skir.TypeUse_scalarWrapper(value: final kind)
              when kind == skir.ScalarKind.decimal =>
            "decimal",
          _ => null,
        };
  bool sameNumericFamily(skir.ExpressionType a, skir.ExpressionType b) =>
      family(nominalUse(a)) != null &&
      family(nominalUse(a)) == family(nominalUse(b));
  skir.ExpressionType withMissing(skir.ExpressionType type, bool missing) {
    if (type.mayBeMissing == missing) return type;
    final result = type.withMissing(missing);
    if (literalTypes.contains(type)) literalTypes.add(result);
    return result;
  }

  skir.ExpressionType canonicalShape(skir.ExpressionType source) {
    if (source.value is! skir.ExpressionValueType_nominalWrapper) return source;
    final use = (source.value as skir.ExpressionValueType_nominalWrapper).value;
    if (use case skir.TypeUse_nullableWrapper(:final value)) {
      return skir.ExpressionType(
        value: skir.ExpressionValueType.wrapNullable(nominalType(value.value)),
        mayBeMissing: source.mayBeMissing,
      );
    }
    if (use is! skir.TypeUse_namedWrapper ||
        use.value.definition.revision != 1) {
      return source;
    }
    final id = use.value.definition.typeId;
    if (id is! skir.TypeId_qualifiedWrapper ||
        id.value.namespace != "typewriter") {
      return source;
    }
    final args = use.value.arguments.toList();
    if (id.value.name == "List" && args.length == 1) {
      return listType(nominalType(args[0]), source.mayBeMissing);
    }
    if (id.value.name == "Map" && args.length == 2) {
      return mapType(
        nominalType(args[0]),
        nominalType(args[1]),
        source.mayBeMissing,
      );
    }
    return source;
  }

  bool compatible(skir.ExpressionType actual, skir.ExpressionType expected) {
    final a = canonicalShape(actual);
    final e = canonicalShape(expected);
    switch ((a.value, e.value)) {
      case (final av, final ev)
          when av == skir.ExpressionValueType.nullValue &&
              ev == skir.ExpressionValueType.nullValue:
        return true;
      case (final av, skir.ExpressionValueType_nullableWrapper())
          when av == skir.ExpressionValueType.nullValue:
        return true;
      case (final av, _) when av == skir.ExpressionValueType.nullValue:
        return false;
      case (
        skir.ExpressionValueType_nullableWrapper(value: final av),
        skir.ExpressionValueType_nullableWrapper(value: final ev),
      ):
        return compatible(av, ev);
      case (skir.ExpressionValueType_nullableWrapper(), _):
        return false;
      case (_, skir.ExpressionValueType_nullableWrapper(value: final ev)):
        return compatible(a, ev);
      case (
        skir.ExpressionValueType_listWrapper(value: final av),
        skir.ExpressionValueType_listWrapper(value: final ev),
      ):
        return compatible(av, ev);
      case (
        skir.ExpressionValueType_mapWrapper(value: final av),
        skir.ExpressionValueType_mapWrapper(value: final ev),
      ):
      case (
        skir.ExpressionValueType_entryWrapper(value: final av),
        skir.ExpressionValueType_entryWrapper(value: final ev),
      ):
        return compatible(av.key, ev.key) && compatible(av.value, ev.value);
      case (
        skir.ExpressionValueType_nominalWrapper(value: final av),
        skir.ExpressionValueType_nominalWrapper(value: final ev),
      ):
        final an = catalog.expressionPayloadType(av);
        final en = catalog.expressionPayloadType(ev);
        return av == ev ||
            an == en ||
            ((literalTypes.contains(actual) ||
                    literalTypes.contains(expected)) &&
                family(an) != null &&
                family(an) == family(en)) ||
            isNominalSubtype(av, ev);
      default:
        return false;
    }
  }

  /// Whether [actual] is a proper nominal subtype of [expected], such as an
  /// Iconify icon where an icon is expected. Matches the Kotlin checker.
  bool isNominalSubtype(skir.TypeUse actual, skir.TypeUse expected) =>
      actual != expected &&
      actual is skir.TypeUse_namedWrapper &&
      expected is skir.TypeUse_namedWrapper &&
      catalog.isReadableAs(actual, expected);

  skir.ExpressionType nullableType(skir.ExpressionType type) =>
      type.value == skir.ExpressionValueType.nullValue ||
          type.value is skir.ExpressionValueType_nullableWrapper
      ? type
      : skir.ExpressionType(
          value: skir.ExpressionValueType.wrapNullable(
            withMissing(type, false),
          ),
          mayBeMissing: type.mayBeMissing,
        );
  skir.ExpressionType join(
    skir.ExpressionType left,
    skir.ExpressionType right,
  ) {
    final a = canonicalShape(left);
    final b = canonicalShape(right);
    final missing = left.mayBeMissing || right.mayBeMissing;
    if (a.value == skir.ExpressionValueType.nullValue) {
      return withMissing(nullableType(b), missing);
    }
    if (b.value == skir.ExpressionValueType.nullValue) {
      return withMissing(nullableType(a), missing);
    }
    final ac = a.value is skir.ExpressionValueType_nullableWrapper
        ? (a.value as skir.ExpressionValueType_nullableWrapper).value
        : a;
    final bc = b.value is skir.ExpressionValueType_nullableWrapper
        ? (b.value as skir.ExpressionValueType_nullableWrapper).value
        : b;
    if (!compatible(ac, bc) && !compatible(bc, ac)) {
      throw const ExpressionProblem("incompatible_expression_types");
    }
    var result = switch ((ac.value, bc.value)) {
      (
        skir.ExpressionValueType_listWrapper(value: final av),
        skir.ExpressionValueType_listWrapper(value: final bv),
      ) =>
        listType(join(av, bv)),
      (
        skir.ExpressionValueType_mapWrapper(value: final av),
        skir.ExpressionValueType_mapWrapper(value: final bv),
      ) =>
        mapType(join(av.key, bv.key), join(av.value, bv.value)),
      (
        skir.ExpressionValueType_entryWrapper(value: final av),
        skir.ExpressionValueType_entryWrapper(value: final bv),
      ) =>
        entryType(join(av.key, bv.key), join(av.value, bv.value)),
      (
        skir.ExpressionValueType_nominalWrapper(value: final av),
        skir.ExpressionValueType_nominalWrapper(value: final bv),
      )
          when isNominalSubtype(av, bv) =>
        bc,
      _ => literalTypes.contains(ac) && !literalTypes.contains(bc) ? bc : ac,
    };
    if (a.value is skir.ExpressionValueType_nullableWrapper ||
        b.value is skir.ExpressionValueType_nullableWrapper) {
      result = nullableType(result);
    }
    return withMissing(result, missing);
  }

  skir.ExpressionType readTypePath(
    skir.ExpressionType source,
    skir.ValuePath path,
  ) {
    var current = source;
    var missing = source.mayBeMissing;
    for (final segment in path.segments) {
      current = canonicalShape(current);
      while (current.value is skir.ExpressionValueType_nullableWrapper) {
        current =
            (current.value as skir.ExpressionValueType_nullableWrapper).value;
        missing = true; // Reading through an actual null is unavailable, not a null field.
      }
      if (current.value case skir.ExpressionValueType_entryWrapper(
        :final value,
      )) {
        current = switch (segment) {
          final s when s == skir.PathSegment.mapKey => value.key,
          final s when s == skir.PathSegment.mapValue => value.value,
          _ => throw const ExpressionProblem("invalid_expression_path"),
        };
      } else if (segment is skir.PathSegment_itemWrapper) {
        current = requireItem(current);
        // A selected item ID can be absent even in a present collection.
        missing = true;
      } else if (current.value is skir.ExpressionValueType_nominalWrapper) {
        final resolved = catalog.expressionPathType(
          current,
          skir.ValuePath(segments: [segment]),
        );
        if (resolved == null) {
          throw const ExpressionProblem("invalid_expression_path");
        }
        current = resolved;
      } else {
        throw const ExpressionProblem("invalid_expression_path");
      }
      missing = missing || current.mayBeMissing;
    }
    return withMissing(current, missing);
  }

  skir.ExpressionType inferProjection(ExpressionProjection p) {
    switch (p.root) {
      case skir.ExpressionNode_inputWrapper(:final value):
        return inferInput(
          skir.ExpressionInput(
            binding: value.binding,
            path: skir.ValuePath(
              segments: [...value.path.segments, ...p.suffix.segments],
            ),
          ),
        );
      case skir.ExpressionNode_localWrapper(:final value):
        return local(
          skir.ExpressionLocal(
            depth: value.depth,
            slot: value.slot,
            path: skir.ValuePath(
              segments: [...value.path.segments, ...p.suffix.segments],
            ),
          ),
        );
      case skir.ExpressionNode_queryWrapper(:final value):
        final previous = occurrence;
        occurrence = [...previous, for (var i = 0; i < p.descents; i++) 0];
        try {
          return readTypePath(inferQuery(value), p.suffix);
        } finally {
          occurrence = previous;
        }
      default:
        throw const ExpressionProblem("invalid_projection");
    }
  }

  CheckedQueryCall checkResourceQuery(
    skir.ExpressionQuery query,
    skir.ResourceQuerySource source,
    ExpressionOccurrence occurrence,
  ) {
    late skir.TypeUse target;
    late bool reference;
    switch (source) {
      case skir.ResourceQuerySource_referenceWrapper(:final value):
        final input = inferChild(value, 0);
        if (input.value is! skir.ExpressionValueType_nominalWrapper) {
          throw const ExpressionProblem("invalid_canonical_query");
        }
        final use =
            (input.value as skir.ExpressionValueType_nominalWrapper).value;
        final named = catalog.namedUse(use);
        final repr = named == null
            ? null
            : catalog.published(named.definition)?.definition.representation;
        if (repr is! skir.RepresentationTemplate_linkWrapper) {
          throw const ExpressionProblem("invalid_canonical_query");
        }
        final resolved = catalog.applyTemplate(
          repr.value.target,
          skir.TypeSelection.wrapComplete(named!),
        );
        if (resolved == null) {
          throw const ExpressionProblem("invalid_canonical_query");
        }
        target = resolved;
        reference = true;
      case skir.ResourceQuerySource_identityWrapper(:final value):
        final input = inferChild(value.identity, 0);
        if (input.value !=
                skir.ExpressionValueType.wrapNominal(
                  skir.TypeUse.wrapNamed(frameworkResourceIdUse),
                ) ||
            value.target is! skir.TypeUse_namedWrapper ||
            !catalog.isReadyApplication(
              (value.target as skir.TypeUse_namedWrapper).value,
            )) {
          throw const ExpressionProblem("invalid_canonical_query");
        }
        target = value.target;
        reference = false;
      default:
        throw const ExpressionProblem("invalid_canonical_query");
    }
    final result = switch (query) {
      skir.ExpressionQuery_resourceIdentityWrapper() => nominalType(
        skir.TypeUse.wrapNamed(frameworkResourceIdUse),
        true,
      ),
      skir.ExpressionQuery_resourceValueWrapper() => nominalType(target, true),
      skir.ExpressionQuery_resourceConfigurationWrapper() => nominalType(
        canonicalReadModels.typeSelectionUse,
        true,
      ),
      _ => throw const ExpressionProblem("invalid_canonical_query"),
    };
    final contract = CheckedQueryCall(
      query: query,
      targetType: target,
      result: result,
      sourceIsReference: reference,
    );
    queryContracts[occurrence] = contract;
    return contract;
  }

  skir.ExpressionType inferQuery(skir.ExpressionQuery query) {
    switch (query) {
      case skir.ExpressionQuery_resourceIdentityWrapper(:final value):
      case skir.ExpressionQuery_resourceValueWrapper(:final value):
      case skir.ExpressionQuery_resourceConfigurationWrapper(:final value):
        return checkResourceQuery(
          query,
          value,
          ExpressionOccurrence(path: occurrence),
        ).result;
      case skir.ExpressionQuery_valueConfigurationWrapper(:final value):
        inferChild(value, 0); // Preserve current admission; runtime named value may be unavailable.
        final result = nominalType(canonicalReadModels.typeSelectionUse, true);
        queryContracts[ExpressionOccurrence(
          path: occurrence,
        )] = CheckedQueryCall(
          query: query,
          targetType: null,
          result: result,
          sourceIsReference: false,
        );
        return result;
      case skir.ExpressionQuery_catalogDeclarationWrapper(:final value):
        final input = inferChild(value, 0);
        if (input.value is! skir.ExpressionValueType_nominalWrapper ||
            !catalog.isReadableAs(
              (input.value as skir.ExpressionValueType_nominalWrapper).value,
              canonicalReadModels.typeSelectionUse,
            )) {
          throw const ExpressionProblem("invalid_canonical_query");
        }
        final result = nominalType(canonicalReadModels.publishedTypeUse, true);
        queryContracts[ExpressionOccurrence(
          path: occurrence,
        )] = CheckedQueryCall(
          query: query,
          targetType: null,
          result: result,
          sourceIsReference: false,
        );
        return result;
      default:
        throw const ExpressionProblem("unknown_query");
    }
  }

  skir.ExpressionType inferScalar(skir.ExpressionNode node) {
    final operands = node.scalarOperands;
    if (operands == null) throw const ExpressionProblem("unknown_expression");
    final values = [
      for (final (index, value) in operands.indexed) inferChild(value, index),
    ];
    final missing = values.any((value) => value.mayBeMissing);
    void allScalar(skir.TypeUse type) {
      for (final value in values) {
        requireScalar(value, type);
      }
    }

    void allNumeric() {
      for (final value in values) {
        requireNumber(value);
      }
      if (values
          .skip(1)
          .any(
            (v) => family(nominalUse(v)) != family(nominalUse(values.first)),
          )) {
        throw const ExpressionProblem("numeric_family_mismatch");
      }
    }

    skir.ExpressionType boolResult() => nominalType(boolean, missing);
    skir.ExpressionType textResult() => nominalType(text, missing);
    switch (node) {
      case skir.ExpressionNode_textUnaryWrapper(:final value):
        if (value.operation == skir.TextUnaryOperation.unknown) {
          throw const ExpressionProblem("unknown_expression_operation");
        }
        allScalar(text);
        return textResult();
      case skir.ExpressionNode_textCompareWrapper(:final value):
        if (value.operation == skir.TextCompareOperation.unknown) {
          throw const ExpressionProblem("unknown_expression_operation");
        }
        allScalar(text);
        return boolResult();
      case skir.ExpressionNode_textLengthWrapper():
        allScalar(text);
        return nominalType(integer, missing);
      case skir.ExpressionNode_textHasLineBreakWrapper():
        allScalar(text);
        return boolResult();
      case skir.ExpressionNode_textReplaceWrapper() ||
          skir.ExpressionNode_regexReplaceWrapper():
        allScalar(text);
        return textResult();
      case skir.ExpressionNode_textSplitWrapper():
        allScalar(text);
        return listType(nominalType(text), missing);
      case skir.ExpressionNode_textJoinWrapper():
        requireScalar(requireItem(values[0]), text);
        requireScalar(values[1], text);
        return textResult();
      case skir.ExpressionNode_textSubstringWrapper():
        requireScalar(values[0], text);
        for (final v in values.skip(1)) {
          requireInteger(v);
        }
        return textResult();
      case skir.ExpressionNode_textInterpolateWrapper():
        return textResult();
      case skir.ExpressionNode_regexTestWrapper(:final value):
        if (value.mode == skir.RegexMatchMode.unknown) {
          throw const ExpressionProblem("unknown_expression_operation");
        }
        allScalar(text);
        return boolResult();
      case skir.ExpressionNode_regexCaptureWrapper():
        requireScalar(values[0], text);
        requireScalar(values[1], text);
        requireInteger(values[2]);
        return textResult();
      case skir.ExpressionNode_valueCompareWrapper(:final value):
        if (value.operation == skir.ValueCompareOperation.unknown) {
          throw const ExpressionProblem("unknown_expression_operation");
        }
        if (!compatible(values[0], values[1])) {
          throw const ExpressionProblem("incompatible_expression_types");
        }
        return boolResult();
      case skir.ExpressionNode_isNullWrapper():
        return boolResult();
      case skir.ExpressionNode_linkTargetWrapper():
        return nominalType(
          skir.TypeUse.wrapNamed(frameworkResourceIdUse),
          missing,
        );
      case skir.ExpressionNode_booleanNotWrapper():
        allScalar(boolean);
        return boolResult();
      case skir.ExpressionNode_numberArithmeticWrapper(:final value):
        if (value.operation == skir.NumberArithmeticOperation.unknown) {
          throw const ExpressionProblem("unknown_expression_operation");
        }
        allNumeric();
        var result = values.first;
        for (final value in values.skip(1)) {
          result = join(result, value);
        }
        return withMissing(result, missing);
      case skir.ExpressionNode_numberNegateWrapper():
        allNumeric();
        return withMissing(values.single, missing);
      case skir.ExpressionNode_numberCompareWrapper(:final value):
        if (value.operation == skir.NumberCompareOperation.unknown) {
          throw const ExpressionProblem("unknown_expression_operation");
        }
        allNumeric();
        return boolResult();
      case skir.ExpressionNode_numberRoundWrapper():
        requireNumber(values[0]);
        requireNumber(values[1]);
        requireScalar(values[2], text);
        if (family(nominalUse(values[0])) != family(nominalUse(values[1]))) {
          throw const ExpressionProblem("numeric_family_mismatch");
        }
        if (!compatible(values[0], values[1])) {
          throw const ExpressionProblem("incompatible_expression_types");
        }
        return withMissing(join(values[0], values[1]), missing);
      case skir.ExpressionNode_numberFormatWrapper():
        requireNumber(values[0]);
        requireInteger(values[1]);
        requireScalar(values[2], text);
        return textResult();
      case skir.ExpressionNode_durationFormatWrapper():
        requireScalar(
          values[0],
          skir.TypeUse.wrapScalar(skir.ScalarKind.duration),
        );
        requireScalar(values[1], text);
        requireInteger(values[2]);
        return textResult();
      case skir.ExpressionNode_timestampFormatWrapper():
        requireScalar(
          values[0],
          skir.TypeUse.wrapScalar(skir.ScalarKind.timestamp),
        );
        for (final v in values.skip(1)) {
          requireScalar(v, text);
        }
        return textResult();
      case skir.ExpressionNode_collectionSizeWrapper():
        requireItem(values[0]);
        return nominalType(integer, missing);
      case skir.ExpressionNode_collectionAccessWrapper():
        final mapping = catalog.expressionMapping(values[0]);
        if (mapping != null) {
          if (!compatible(values[1], mapping.key)) {
            throw const ExpressionProblem("invalid_expression_operand_type");
          }
          return withMissing(mapping.value, true);
        }
        requireInteger(values[1]);
        return withMissing(requireItem(values[0]), true);
      case skir.ExpressionNode_collectionContainsWrapper():
        final mapping = catalog.expressionMapping(values[0]);
        final expected = mapping?.key ?? requireItem(values[0]);
        if (!compatible(values[1], expected)) {
          throw const ExpressionProblem("incompatible_expression_types");
        }
        return boolResult();
      case skir.ExpressionNode_colorWithAlphaWrapper():
        for (final v in values) {
          requireInteger(v);
        }
        return withMissing(values.first, missing);
      case skir.ExpressionNode_ruleUnaryWrapper(:final value):
        switch (value.operation) {
          case skir.RuleUnaryOperation.nonEmpty:
            requireSized(values.single);
          case skir.RuleUnaryOperation.nonBlank ||
              skir.RuleUnaryOperation.singleLine:
            allScalar(text);
          case skir.RuleUnaryOperation.positive ||
              skir.RuleUnaryOperation.nonNegative:
            allNumeric();
          case skir.RuleUnaryOperation.unique:
            requireItem(values.single);
          case skir.RuleUnaryOperation.notNull:
            break;
          case skir.RuleUnaryOperation.opaque:
            requireInteger(values.single);
          default:
            throw const ExpressionProblem("unknown_expression_operation");
        }
        return boolResult();
      case skir.ExpressionNode_ruleOneOfWrapper():
        return boolResult();
      case skir.ExpressionNode_ruleSizeBoundWrapper(:final value):
        if (value.direction == skir.BoundDirection.unknown) {
          throw const ExpressionProblem("unknown_expression_operation");
        }
        switch (value.metric) {
          case skir.SizeBoundMetric.textLength ||
              skir.SizeBoundMetric.textLines:
            requireScalar(values[0], text);
          case skir.SizeBoundMetric.collectionItems:
            requireItem(values[0]);
          default:
            throw const ExpressionProblem("unknown_expression_operation");
        }
        requireInteger(values[1]);
        return boolResult();
      case skir.ExpressionNode_ruleSizeRangeWrapper(:final value):
        switch (value.metric) {
          case skir.SizeRangeMetric.textLength:
            requireScalar(values[0], text);
          case skir.SizeRangeMetric.collectionItems:
            requireItem(values[0]);
          default:
            throw const ExpressionProblem("unknown_expression_operation");
        }
        requireInteger(values[1]);
        requireInteger(values[2]);
        return boolResult();
      case skir.ExpressionNode_ruleNumericBoundWrapper(:final value):
        if (value.direction == skir.BoundDirection.unknown) {
          throw const ExpressionProblem("unknown_expression_operation");
        }
        requireNumber(values[0]);
        requireNumber(values[1]);
        requireScalar(values[2], boolean);
        return boolResult();
      case skir.ExpressionNode_ruleNumericRangeWrapper():
        allNumeric();
        return boolResult();
      case skir.ExpressionNode_ruleMultipleOfWrapper():
        allNumeric();
        return boolResult();
      case skir.ExpressionNode_ruleMaximumScaleWrapper():
        requireNumber(values[0]);
        requireInteger(values[1]);
        return boolResult();
      case skir.ExpressionNode_ruleTimestampBoundWrapper(:final value):
        if (value.direction == skir.TimestampBoundDirection.unknown) {
          throw const ExpressionProblem("unknown_expression_operation");
        }
        allScalar(skir.TypeUse.wrapScalar(skir.ScalarKind.timestamp));
        return boolResult();
      default:
        throw const ExpressionProblem("unknown_expression");
    }
  }

  void requireSized(skir.ExpressionType type) {
    final use = nominalUse(type);
    if (use == text || use == skir.TypeUse.wrapScalar(skir.ScalarKind.bytes)) {
      return;
    }
    requireItem(type);
  }
}
