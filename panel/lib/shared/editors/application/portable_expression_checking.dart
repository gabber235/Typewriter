import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Checks portable expressions under declared source and temporary candidate types.
/// Failures of a valid expression at evaluation remain separate runtime feedback.
List<String> checkPortableExpression(
  skir.ExpressionNode body, {
  required Map<skir.ExpressionBindingId, skir.ExpressionType> bindings,
  required skir.ExpressionType expectedOutput,
  skir.ExpressionType? Function(skir.ExpressionType, skir.ValuePath)?
  resolvePath,
  skir.TypeUse Function(skir.TypeUse)? normalizeType,
  skir.TypeUse? Function(skir.TypeUse)? resolveCollectionItem,
  void Function(skir.ExpressionType?)? onInferred,
  bool allowResultNumericWidth = false,
}) {
  final errors = <String>[];
  final text = skir.TypeUse.wrapScalar(skir.ScalarKind.text);
  final boolean = skir.TypeUse.wrapScalar(skir.ScalarKind.boolean);
  final integer = skir.TypeUse.wrapScalar(
    skir.ScalarKind.createInteger(width: skir.IntegerWidth.signedSixtyFour),
  );
  final floating = skir.TypeUse.wrapScalar(
    skir.ScalarKind.createFloat(width: skir.FloatWidth.sixtyFour),
  );
  final decimal = skir.TypeUse.wrapScalar(skir.ScalarKind.decimal);

  final literalTypes = HashSet<skir.ExpressionType>.identity();
  skir.ExpressionType type(
    skir.TypeUse use, [
    bool missing = false,
    bool literal = false,
  ]) {
    final result = skir.ExpressionType(value: use, mayBeMissing: missing);
    if (literal) literalTypes.add(result);
    return result;
  }

  String? family(skir.TypeUse use) => switch (use) {
    skir.TypeUse_scalarWrapper(value: skir.ScalarKind_integerWrapper()) =>
      "integer",
    skir.TypeUse_scalarWrapper(value: skir.ScalarKind_floatWrapper()) =>
      "float",
    skir.TypeUse_scalarWrapper(value: final scalar)
        when scalar == skir.ScalarKind.decimal =>
      "decimal",
    _ => null,
  };
  bool matches(skir.ExpressionType actual, skir.ExpressionType expected) =>
      actual.value == expected.value ||
      ((literalTypes.contains(actual) || literalTypes.contains(expected)) &&
          family(actual.value) != null &&
          family(actual.value) == family(expected.value));
  skir.TypeUse listOf(skir.TypeUse item) => skir.TypeUse.createNamed(
    definition: skir.TypeDefinitionId(
      typeId: skir.TypeId.createQualified(
        namespace: "typewriter",
        name: "List",
      ),
      revision: 1,
    ),
    arguments: [item],
  );
  skir.ExpressionType? itemType(skir.ExpressionType source) {
    if (resolveCollectionItem != null) {
      final item = resolveCollectionItem(source.value);
      if (item != null) return type(item, source.mayBeMissing);
      if (source.value case skir.TypeUse_namedWrapper(:final value)
          when value.definition.typeId is skir.TypeId_qualifiedWrapper &&
              (value.definition.typeId as skir.TypeId_qualifiedWrapper)
                      .value
                      .namespace ==
                  "typewriter" &&
              {"List", "Set"}.contains(
                (value.definition.typeId as skir.TypeId_qualifiedWrapper)
                    .value
                    .name,
              ) &&
              value.arguments.length == 1) {
        return type(value.arguments.first, source.mayBeMissing);
      }
      return null;
    }
    if (source.value case skir.TypeUse_namedWrapper(:final value)
        when value.arguments.isNotEmpty) {
      return type(value.arguments.first, source.mayBeMissing);
    }
    return null;
  }

  late skir.ExpressionType? Function(
    skir.ExpressionNode,
    Map<skir.ExpressionBindingId, skir.ExpressionType>,
  )
  infer;
  infer = (node, scope) {
    switch (node) {
      case skir.ExpressionNode_literalWrapper(:final value):
        if (value case skir.DataValue_namedWrapper(:final value)) {
          return type(
            normalizeType?.call(skir.TypeUse.wrapNamed(value.actualType)) ??
                skir.TypeUse.wrapNamed(value.actualType),
            false,
            true,
          );
        }
        final items = switch (value) {
          skir.DataValue_listValueWrapper(:final value) => value.items.map(
            (item) => item.value,
          ),
          skir.DataValue_setValueWrapper(:final value) => value.items.map(
            (item) => item.value,
          ),
          _ => null,
        };
        if (items != null) {
          final actual = items
              .map(
                (item) => infer(skir.ExpressionNode.wrapLiteral(item), scope),
              )
              .toList();
          if (actual.isEmpty || actual.any((item) => item == null)) return null;
          if (actual.skip(1).any((item) => !matches(actual.first!, item!))) {
            errors.add("incompatible_expression_collection_items");
          }
          return type(listOf(actual.first!.value));
        }
        return switch (value.authoredPayload) {
          skir.DataValue_integerWrapper() => type(integer, false, true),
          skir.DataValue_floatWrapper() => type(floating, false, true),
          skir.DataValue_decimalWrapper() => type(decimal, false, true),
          skir.DataValue_stringValueWrapper() => type(text),
          skir.DataValue_booleanWrapper() => type(boolean),
          skir.DataValue_durationWrapper() => type(
            skir.TypeUse.wrapScalar(skir.ScalarKind.duration),
          ),
          skir.DataValue_timestampWrapper() => type(
            skir.TypeUse.wrapScalar(skir.ScalarKind.timestamp),
          ),
          skir.DataValue_bytesWrapper() => type(
            skir.TypeUse.wrapScalar(skir.ScalarKind.bytes),
          ),
          final value when value == skir.DataValue.unfilled => type(
            expectedOutput.value,
            true,
          ),
          _ => null,
        };
      case skir.ExpressionNode_readWrapper(:final value):
        final source = scope[value.binding];
        if (source == null) {
          errors.add("unknown_expression_binding");
          return null;
        }
        if (value.path.segments.isEmpty) {
          return type(
            normalizeType?.call(source.value) ?? source.value,
            source.mayBeMissing,
          );
        }
        final resolved = resolvePath?.call(source, value.path);
        if (resolved == null) errors.add("invalid_expression_path");
        return resolved == null
            ? null
            : type(
                normalizeType?.call(resolved.value) ?? resolved.value,
                resolved.mayBeMissing,
              );
      case skir.ExpressionNode_callWrapper(:final value):
        final id = value.operation.value;
        if (!portableOperationAcceptsArity(id, value.arguments.length)) {
          errors.add(
            authoredPortableOperationIds.contains(id)
                ? "invalid_expression_operation_arity"
                : "unknown_expression_operation",
          );
          return null;
        }
        final arguments = value.arguments
            .map((node) => infer(node, scope))
            .toList();
        if (arguments.any((argument) => argument == null)) return null;
        final actual = arguments.cast<skir.ExpressionType>();
        final missing = actual.any((argument) => argument.mayBeMissing);
        bool inputs(List<skir.TypeUse?> expected) {
          if (actual.length != expected.length) {
            errors.add("invalid_expression_operation_arity");
            return false;
          }
          for (var index = 0; index < expected.length; index++) {
            if (expected[index] != null &&
                actual[index].value != expected[index]) {
              errors.add("invalid_expression_operand_type");
            }
          }
          return true;
        }
        if (!authoredPortableOperationIds.contains(id)) {
          errors.add("unknown_expression_operation");
          return null;
        }
        if (id == "typewriter.number.round_to" ||
            id == "typewriter.number.negate" ||
            {
              "typewriter.number.add",
              "typewriter.number.subtract",
              "typewriter.number.multiply",
              "typewriter.number.divide",
              "typewriter.number.remainder",
            }.contains(id)) {
          final numeric = id == "typewriter.number.round_to"
              ? actual.take(2).toList()
              : actual;
          final minimum = id == "typewriter.number.negate" ? 1 : 2;
          if (actual.length < minimum ||
              (id == "typewriter.number.round_to" && actual.length != 3) ||
              (id == "typewriter.number.negate" && actual.length != 1)) {
            errors.add("invalid_expression_operation_arity");
            return null;
          }
          if (numeric.any((input) => family(input.value) == null) ||
              numeric.any(
                (input) => family(input.value) != family(numeric.first.value),
              )) {
            errors.add("numeric_family_mismatch");
          }
          if (id == "typewriter.number.round_to" && actual[2].value != text) {
            errors.add("invalid_expression_operand_type");
          }
          for (final operand in numeric.skip(1)) {
            if (!matches(numeric.first, operand)) {
              errors.add("incompatible_expression_types");
            }
          }
          var result = numeric.first.value;
          for (var index = 0; index < numeric.length; index++) {
            if (value.arguments.elementAt(index)
                is! skir.ExpressionNode_literalWrapper) {
              result = numeric[index].value;
              break;
            }
          }
          return type(result, missing, numeric.every(literalTypes.contains));
        }
        if (id == "typewriter.number.format") {
          if (inputs([null, null, text]) &&
              (family(actual[0].value) == null ||
                  family(actual[1].value) != "integer")) {
            errors.add("invalid_expression_operand_type");
          }
          return type(text, missing);
        }
        if (id == "typewriter.duration.format") {
          if (inputs([
                skir.TypeUse.wrapScalar(skir.ScalarKind.duration),
                text,
                null,
              ]) &&
              family(actual[2].value) != "integer") {
            errors.add("invalid_expression_operand_type");
          }
          return type(text, missing);
        }
        if (id == "typewriter.timestamp.format") {
          inputs([
            skir.TypeUse.wrapScalar(skir.ScalarKind.timestamp),
            text,
            text,
            text,
          ]);
          return type(text, missing);
        }
        if ({
          "typewriter.text.trim",
          "typewriter.text.lower",
          "typewriter.text.upper",
          "typewriter.text.title",
        }.contains(id)) {
          inputs([text]);
          return type(text, missing);
        }
        if ({
          "typewriter.text.replace",
          "typewriter.regex.replace",
        }.contains(id)) {
          inputs([text, text, text]);
          return type(text, missing);
        }
        if (id == "typewriter.text.interpolate") return type(text, missing);
        if (id == "typewriter.text.length") {
          inputs([text]);
          return type(integer, missing);
        }
        if (id == "typewriter.text.has_line_break") {
          inputs([text]);
          return type(boolean, missing);
        }
        if ({
          "typewriter.text.contains",
          "typewriter.text.starts_with",
          "typewriter.text.ends_with",
          "typewriter.regex.matches",
        }.contains(id)) {
          inputs([text, text]);
          return type(boolean, missing);
        }
        if (id == "typewriter.regex.capture") {
          if (inputs([text, text, null]) &&
              family(actual[2].value) != "integer") {
            errors.add("invalid_expression_operand_type");
          }
          return type(text, missing);
        }
        if (id == "typewriter.text.substring") {
          if (actual.length < 2 || actual.length > 3) {
            errors.add("invalid_expression_operation_arity");
          }
          if (actual.isNotEmpty && actual.first.value != text ||
              actual.skip(1).any((input) => family(input.value) != "integer")) {
            errors.add("invalid_expression_operand_type");
          }
          return type(text, missing);
        }
        if (id == "typewriter.text.split") {
          inputs([text, text]);
          return type(listOf(text), missing);
        }
        if (id == "typewriter.text.join") {
          if (inputs([null, text]) && itemType(actual[0])?.value != text) {
            errors.add("invalid_expression_operand_type");
          }
          return type(text, missing);
        }
        if (id == "typewriter.boolean.not") {
          inputs([boolean]);
          return type(boolean, missing);
        }
        if ({
          "typewriter.number.gt",
          "typewriter.number.gte",
          "typewriter.number.lt",
          "typewriter.number.lte",
        }.contains(id)) {
          if (inputs([null, null]) &&
              actual.any((input) => family(input.value) == null)) {
            errors.add("invalid_expression_operand_type");
          }
          return type(boolean, missing);
        }
        if ({"typewriter.value.eq", "typewriter.value.neq"}.contains(id)) {
          if (inputs([null, null]) && !matches(actual[0], actual[1])) {
            errors.add("incompatible_expression_types");
          }
          return type(boolean, missing);
        }
        if (id == "typewriter.value.is_null") {
          inputs([null]);
          return type(boolean, missing);
        }
        if (id == "typewriter.record.field") {
          if (!inputs([null, text])) return null;
          final name = value.arguments.elementAt(1);
          if (name case skir.ExpressionNode_literalWrapper(
            value: skir.DataValue_stringValueWrapper(:final value),
          )) {
            return resolvePath?.call(
              actual[0],
              skir.ValuePath(
                segments: [skir.PathSegment.createField(name: value)],
              ),
            );
          }
          errors.add("dynamic_expression_field_type");
          return null;
        }
        if (id == "typewriter.link.target") {
          inputs([null]);
          return type(text, missing);
        }
        if (id == "typewriter.collection.size") {
          inputs([null]);
          if (actual.isNotEmpty && itemType(actual.first) == null) {
            errors.add("expression_collection_expected");
          }
          return type(integer, missing);
        }
        if (id == "typewriter.collection.access") {
          inputs([null, null]);
          final item = itemType(actual[0]);
          if (item == null) errors.add("expression_collection_expected");
          return item;
        }
        if (id == "typewriter.collection.contains") {
          inputs([null, null]);
          final item = itemType(actual[0]);
          if (item == null) {
            errors.add("expression_collection_expected");
          } else if (!matches(actual[1], item)) {
            errors.add("incompatible_expression_types");
          }
          return type(boolean, missing);
        }
        if (id == "typewriter.color.with_alpha") {
          if (actual.any((argument) => family(argument.value) != "integer")) {
            errors.add("invalid_expression_operand_type");
          }
          return type(
            actual.first.value,
            missing,
            actual.every(literalTypes.contains),
          );
        }
        if (id.startsWith("typewriter.rule.")) {
          final kinds = _ruleExpressionInputKinds[id];
          if (kinds == null) {
            errors.add("unsupported_expression_operation_type");
            return null;
          }
          for (var index = 0; index < actual.length; index++) {
            final kind = index < kinds.length ? kinds[index] : "Any";
            final use = actual[index].value;
            final accepted = switch (kind) {
              "Any" => true,
              "Boolean" => use == boolean,
              "Text" => use == text,
              "Integer" => family(use) == "integer",
              "Number" => family(use) != null,
              "Timestamp" =>
                use == skir.TypeUse.wrapScalar(skir.ScalarKind.timestamp),
              "Sized" =>
                use == text ||
                    use == skir.TypeUse.wrapScalar(skir.ScalarKind.bytes) ||
                    itemType(actual[index]) != null,
              "Collection" => itemType(actual[index]) != null,
              _ => false,
            };
            if (!accepted) errors.add("invalid_expression_operand_type");
          }
          return type(boolean, missing);
        }
        errors.add("unsupported_expression_operation_type");
        return null;
      case skir.ExpressionNode_andWrapper(:final value):
      case skir.ExpressionNode_orWrapper(:final value):
        final left = infer(value.left, scope);
        final right = infer(value.right, scope);
        if (left?.value != boolean || right?.value != boolean) {
          errors.add("invalid_boolean_operand");
        }
        return type(
          boolean,
          (left?.mayBeMissing ?? true) || (right?.mayBeMissing ?? true),
        );
      case skir.ExpressionNode_conditionalWrapper(:final value):
        final test = infer(value.test, scope);
        if (test?.value != boolean) {
          errors.add("invalid_boolean_operand");
        }
        final yes = infer(value.yes, scope);
        final no = infer(value.no, scope);
        if (yes == null || no == null) return null;
        if (!matches(yes, no)) errors.add("incompatible_expression_types");
        return type(
          literalTypes.contains(yes) && !literalTypes.contains(no)
              ? no.value
              : yes.value,
          yes.mayBeMissing || no.mayBeMissing,
          literalTypes.contains(yes) && literalTypes.contains(no),
        );
      case skir.ExpressionNode_orElseWrapper(:final value):
        final input = infer(value.input, scope);
        final fallback = infer(value.fallback, scope);
        if (input == null || fallback == null) return null;
        if (!matches(input, fallback)) {
          errors.add("incompatible_expression_types");
        }
        return type(
          literalTypes.contains(input) && !literalTypes.contains(fallback)
              ? fallback.value
              : input.value,
          input.mayBeMissing && fallback.mayBeMissing,
          literalTypes.contains(input) && literalTypes.contains(fallback),
        );
      case skir.ExpressionNode_collectionWrapper(:final value):
        final input = infer(value.input, scope);
        if (input == null) return null;
        final item = itemType(input);
        if (item == null) {
          errors.add("expression_collection_expected");
          return null;
        }
        final local = Map<skir.ExpressionBindingId, skir.ExpressionType>.of(
          scope,
        );
        for (final binding in value.bindings) {
          if (local.containsKey(binding)) {
            errors.add("duplicate_expression_binding");
          }
          local[binding] = item;
        }
        final id = value.operation.value;
        final shape = _portableCollectionShapes[id];
        if (shape == null) {
          errors.add("unknown_expression_operation");
          return null;
        }
        if (value.bindings.length != shape.$1 ||
            value.arguments.length < shape.$2 ||
            value.arguments.length > shape.$3 ||
            (value.body != null) != shape.$4) {
          errors.add("invalid_expression_collection_shape");
          return null;
        }
        final body = value.body == null ? null : infer(value.body!, local);
        final arguments = value.arguments
            .map((argument) => infer(argument, scope))
            .toList();
        if ({
              "typewriter.collection.any",
              "typewriter.collection.all",
              "typewriter.collection.none",
              "typewriter.collection.filter",
              "typewriter.collection.find",
              "typewriter.collection.find_last",
              "typewriter.collection.count",
            }.contains(id) &&
            body?.value != boolean) {
          errors.add("invalid_expression_collection_predicate");
        }
        if ({
              "typewriter.collection.take",
              "typewriter.collection.skip",
            }.contains(id) &&
            (arguments.isEmpty ||
                arguments.first == null ||
                family(arguments.first!.value) != "integer")) {
          errors.add("invalid_expression_operand_type");
        }
        if ({
          "typewriter.collection.any",
          "typewriter.collection.all",
          "typewriter.collection.none",
          "typewriter.collection.unique_by",
        }.contains(id)) {
          return type(
            boolean,
            input.mayBeMissing || (body?.mayBeMissing ?? false),
          );
        }
        if (id == "typewriter.collection.count") {
          return type(integer, input.mayBeMissing);
        }
        if (id == "typewriter.collection.map") {
          return body == null
              ? null
              : type(
                  listOf(body.value),
                  input.mayBeMissing || body.mayBeMissing,
                );
        }
        if (id == "typewriter.collection.find" ||
            id == "typewriter.collection.find_last" ||
            id == "typewriter.collection.reduce") {
          return type(item.value, true);
        }
        if (id == "typewriter.collection.fold") {
          return value.arguments.isEmpty
              ? null
              : infer(value.arguments.first, scope);
        }
        return input;
      default:
        errors.add("unknown_expression_node");
        return null;
    }
  };
  final result = infer(body, Map.of(bindings));
  onInferred?.call(result);
  if (result == null) {
    errors.add("expression_type_inference_failed");
  } else {
    if (!matches(result, expectedOutput) &&
        !(allowResultNumericWidth &&
            family(result.value) != null &&
            family(result.value) == family(expectedOutput.value))) {
      errors.add("incompatible_expression_result_type");
    }
    if (result.mayBeMissing && !expectedOutput.mayBeMissing) {
      errors.add("expression_result_may_be_missing");
    }
  }
  return List.unmodifiable(errors.toSet());
}

const _ruleExpressionInputKinds = <String, List<String>>{
  "typewriter.rule.one_of": ["Any"],
  "typewriter.rule.nonEmpty": ["Sized"],
  "typewriter.rule.nonBlank": ["Text"],
  "typewriter.rule.minimumLength": ["Sized", "Integer"],
  "typewriter.rule.maximumLength": ["Sized", "Integer"],
  "typewriter.rule.lengthBetween": ["Sized", "Integer", "Integer"],
  "typewriter.rule.minimumLines": ["Text", "Integer"],
  "typewriter.rule.maximumLines": ["Text", "Integer"],
  "typewriter.rule.singleLine": ["Text"],
  "typewriter.rule.regex": ["Text", "Text"],
  "typewriter.rule.startsWith": ["Text", "Text"],
  "typewriter.rule.endsWith": ["Text", "Text"],
  "typewriter.rule.minimum": ["Number", "Number", "Boolean"],
  "typewriter.rule.maximum": ["Number", "Number", "Boolean"],
  "typewriter.rule.between": ["Number", "Number", "Number"],
  "typewriter.rule.positive": ["Number"],
  "typewriter.rule.nonNegative": ["Number"],
  "typewriter.rule.multipleOf": ["Number", "Number"],
  "typewriter.rule.maximumScale": ["Number", "Integer"],
  "typewriter.rule.minimumItems": ["Collection", "Integer"],
  "typewriter.rule.maximumItems": ["Collection", "Integer"],
  "typewriter.rule.itemsBetween": ["Collection", "Integer", "Integer"],
  "typewriter.rule.unique": ["Collection"],
  "typewriter.rule.notNull": ["Any"],
  "typewriter.rule.notBefore": ["Timestamp", "Timestamp"],
  "typewriter.rule.notAfter": ["Timestamp", "Timestamp"],
  "typewriter.rule.opaque": ["Integer"],
};

const _portableCollectionShapes = <String, (int, int, int, bool)>{
  "typewriter.collection.any": (1, 0, 0, true),
  "typewriter.collection.all": (1, 0, 0, true),
  "typewriter.collection.none": (1, 0, 0, true),
  "typewriter.collection.map": (1, 0, 0, true),
  "typewriter.collection.filter": (1, 0, 0, true),
  "typewriter.collection.find": (1, 0, 0, true),
  "typewriter.collection.find_last": (1, 0, 0, true),
  "typewriter.collection.count": (1, 0, 0, true),
  "typewriter.collection.distinct_by": (1, 0, 0, true),
  "typewriter.collection.group_by": (1, 0, 0, true),
  "typewriter.collection.flat_map": (1, 0, 0, true),
  "typewriter.collection.unique_by": (1, 0, 0, true),
  "typewriter.collection.sort_by": (1, 0, 1, true),
  "typewriter.collection.sort_with": (2, 0, 0, true),
  "typewriter.collection.reduce": (2, 0, 0, true),
  "typewriter.collection.fold": (2, 1, 1, true),
  "typewriter.collection.take": (0, 1, 1, false),
  "typewriter.collection.skip": (0, 1, 1, false),
  "typewriter.collection.reverse": (0, 0, 0, false),
  "typewriter.collection.distinct": (0, 0, 0, false),
};
