part of "portable_expression.dart";

/// Canonical expression structures and input identities are separate from
/// catalog identities. Local sources describe a frame, not a global name.
@freezed
sealed class PortableExpressionReadSource with _$PortableExpressionReadSource {
  const factory PortableExpressionReadSource.input(
    skir.ExpressionBindingId binding,
  ) = InputReadSource;
  const factory PortableExpressionReadSource.local(int depth, int slot) =
      LocalReadSource;
  const factory PortableExpressionReadSource.query(
    ExpressionOccurrence occurrence,
  ) = QueryReadSource;
}

@freezed
abstract class PortableExpressionRead with _$PortableExpressionRead {
  const factory PortableExpressionRead({
    required PortableExpressionReadSource source,
    required skir.ValuePath path,
    skir.ValueLocation? location,
  }) = _PortableExpressionRead;
  const PortableExpressionRead._();

  String get key {
    final root = switch (source) {
      InputReadSource(:final binding) => binding.value,
      LocalReadSource(:final depth, :final slot) => "local:$depth:$slot",
      QueryReadSource(:final occurrence) =>
        "query:${occurrence.path.join('.')}",
    };
    final suffix = path.segments
        .map(
          (segment) => switch (segment) {
            skir.PathSegment_fieldWrapper(:final value) => value.name,
            skir.PathSegment_itemWrapper(:final value) => value.id.value,
            skir.PathSegment.mapKey => "key",
            skir.PathSegment.mapValue => "value",
            _ => "?",
          },
        )
        .join(":");
    return suffix.isEmpty ? root : "$root:$suffix";
  }
}

@freezed
abstract class ExpressionProblem with _$ExpressionProblem implements Exception {
  const factory ExpressionProblem(String code) = _ExpressionProblem;
}

@freezed
abstract class ExpressionProjection with _$ExpressionProjection {
  const factory ExpressionProjection({
    required skir.ExpressionNode root,
    required skir.ValuePath suffix,
    required int descents,
  }) = _ExpressionProjection;
}

extension ExpressionStructure on skir.ExpressionNode {
  /// Eager operands in their schema order. Lambda bodies have their own frames.
  List<skir.ExpressionNode>? get scalarOperands => switch (this) {
    skir.ExpressionNode_textUnaryWrapper(:final value) => [value.source],
    skir.ExpressionNode_textCompareWrapper(:final value) => [
      value.source,
      value.other,
    ],
    skir.ExpressionNode_textLengthWrapper(:final value) => [value],
    skir.ExpressionNode_textHasLineBreakWrapper(:final value) => [value],
    skir.ExpressionNode_textReplaceWrapper(:final value) => [
      value.source,
      value.target,
      value.replacement,
    ],
    skir.ExpressionNode_textSplitWrapper(:final value) => [
      value.source,
      value.separator,
    ],
    skir.ExpressionNode_textJoinWrapper(:final value) => [
      value.source,
      value.separator,
    ],
    skir.ExpressionNode_textSubstringWrapper(:final value) => [
      value.source,
      value.start,
      ?value.end,
    ],
    skir.ExpressionNode_textInterpolateWrapper(:final value) => [
      ...value.parts,
    ],
    skir.ExpressionNode_regexTestWrapper(:final value) => [
      value.source,
      value.pattern,
    ],
    skir.ExpressionNode_regexCaptureWrapper(:final value) => [
      value.source,
      value.pattern,
      value.group,
    ],
    skir.ExpressionNode_regexReplaceWrapper(:final value) => [
      value.source,
      value.pattern,
      value.replacement,
    ],
    skir.ExpressionNode_valueCompareWrapper(:final value) => [
      value.left,
      value.right,
    ],
    skir.ExpressionNode_isNullWrapper(:final value) => [value],
    skir.ExpressionNode_linkTargetWrapper(:final value) => [value],
    skir.ExpressionNode_booleanNotWrapper(:final value) => [value],
    skir.ExpressionNode_numberArithmeticWrapper(:final value) => [
      value.first,
      value.second,
      ...value.remaining,
    ],
    skir.ExpressionNode_numberCompareWrapper(:final value) => [
      value.left,
      value.right,
    ],
    skir.ExpressionNode_numberNegateWrapper(:final value) => [value],
    skir.ExpressionNode_numberRoundWrapper(:final value) => [
      value.source,
      value.increment,
      value.rounding,
    ],
    skir.ExpressionNode_numberFormatWrapper(:final value) => [
      value.source,
      value.fractionDigits,
      value.locale,
    ],
    skir.ExpressionNode_durationFormatWrapper(:final value) => [
      value.source,
      value.units,
      value.fractionDigits,
    ],
    skir.ExpressionNode_timestampFormatWrapper(:final value) => [
      value.source,
      value.pattern,
      value.zone,
      value.locale,
    ],
    skir.ExpressionNode_collectionSizeWrapper(:final value) => [value],
    skir.ExpressionNode_collectionAccessWrapper(:final value) => [
      value.source,
      value.index,
    ],
    skir.ExpressionNode_collectionContainsWrapper(:final value) => [
      value.source,
      value.value,
    ],
    skir.ExpressionNode_colorWithAlphaWrapper(:final value) => [
      value.source,
      value.alpha,
    ],
    skir.ExpressionNode_ruleUnaryWrapper(:final value) => [value.source],
    skir.ExpressionNode_ruleOneOfWrapper(:final value) => [
      value.source,
      value.firstCandidate,
      ...value.remainingCandidates,
    ],
    skir.ExpressionNode_ruleSizeBoundWrapper(:final value) => [
      value.source,
      value.bound,
    ],
    skir.ExpressionNode_ruleSizeRangeWrapper(:final value) => [
      value.source,
      value.minimum,
      value.maximum,
    ],
    skir.ExpressionNode_ruleNumericBoundWrapper(:final value) => [
      value.source,
      value.bound,
      value.inclusive,
    ],
    skir.ExpressionNode_ruleNumericRangeWrapper(:final value) => [
      value.source,
      value.minimum,
      value.maximum,
    ],
    skir.ExpressionNode_ruleMultipleOfWrapper(:final value) => [
      value.source,
      value.divisor,
    ],
    skir.ExpressionNode_ruleMaximumScaleWrapper(:final value) => [
      value.source,
      value.scale,
    ],
    skir.ExpressionNode_ruleTimestampBoundWrapper(:final value) => [
      value.source,
      value.bound,
    ],
    _ => null,
  };

  List<skir.ExpressionNode> get children => switch (this) {
    skir.ExpressionNode_literalWrapper() ||
    skir.ExpressionNode_inputWrapper() ||
    skir.ExpressionNode_localWrapper() => const [],
    skir.ExpressionNode_fieldWrapper(:final value) => [value.source],
    skir.ExpressionNode_entryProjectionWrapper(:final value) => [value.source],
    skir.ExpressionNode_andWrapper(:final value) ||
    skir.ExpressionNode_orWrapper(:final value) => [value.left, value.right],
    skir.ExpressionNode_conditionalWrapper(:final value) => [
      value.test,
      value.yes,
      value.no,
    ],
    skir.ExpressionNode_orElseWrapper(:final value) => [
      value.input,
      value.fallback,
    ],
    skir.ExpressionNode_anyWrapper(:final value) => [value.source, value.body],
    skir.ExpressionNode_allWrapper(:final value) => [value.source, value.body],
    skir.ExpressionNode_noneWrapper(:final value) => [value.source, value.body],
    skir.ExpressionNode_mapWrapper(:final value) => [value.source, value.body],
    skir.ExpressionNode_filterWrapper(:final value) => [
      value.source,
      value.body,
    ],
    skir.ExpressionNode_findWrapper(:final value) => [value.source, value.body],
    skir.ExpressionNode_findLastWrapper(:final value) => [
      value.source,
      value.body,
    ],
    skir.ExpressionNode_countWrapper(:final value) => [
      value.source,
      value.body,
    ],
    skir.ExpressionNode_distinctByWrapper(:final value) => [
      value.source,
      value.body,
    ],
    skir.ExpressionNode_groupByWrapper(:final value) => [
      value.source,
      value.body,
    ],
    skir.ExpressionNode_flatMapWrapper(:final value) => [
      value.source,
      value.body,
    ],
    skir.ExpressionNode_uniqueByWrapper(:final value) => [
      value.source,
      value.body,
    ],
    skir.ExpressionNode_reduceWrapper(:final value) => [
      value.source,
      value.body,
    ],
    skir.ExpressionNode_foldWrapper(:final value) => [
      value.source,
      value.initial,
      value.body,
    ],
    skir.ExpressionNode_sortByWrapper(:final value) => [
      value.source,
      ?value.descending,
      value.key,
    ],
    skir.ExpressionNode_sortWithWrapper(:final value) => [
      value.source,
      value.comparator,
    ],
    skir.ExpressionNode_takeWrapper(:final value) ||
    skir.ExpressionNode_skipWrapper(
      :final value,
    ) => [value.source, value.count],
    skir.ExpressionNode_reverseWrapper(:final value) ||
    skir.ExpressionNode_distinctWrapper(:final value) => [value],
    skir.ExpressionNode_queryWrapper(:final value) => [value.sourceExpression],
    skir.ExpressionNode_unknown() => throw const ExpressionProblem(
      "unknown_expression",
    ),
    _ =>
      scalarOperands ?? (throw const ExpressionProblem("unknown_expression")),
  };

  /// Selects addressable paths without evaluating unrelated parent fields.
  ExpressionProjection? readProjection({int remainingDepth = 512}) {
    var node = this;
    final reversed = <skir.PathSegment>[];
    var descents = 0;
    while (true) {
      if (descents > remainingDepth) {
        throw const ExpressionProblem("expression_depth_limit");
      }
      if (node case skir.ExpressionNode_fieldWrapper(:final value)) {
        reversed.add(skir.PathSegment.createField(name: value.name));
        node = value.source;
      } else if (node case skir.ExpressionNode_entryProjectionWrapper(
        :final value,
      )) {
        reversed.add(switch (value.branch) {
          skir.EntryBranch.key => skir.PathSegment.mapKey,
          skir.EntryBranch.value => skir.PathSegment.mapValue,
          _ => throw const ExpressionProblem("invalid_entry_projection"),
        });
        node = value.source;
      } else {
        break;
      }
      descents++;
    }
    if (node is! skir.ExpressionNode_inputWrapper &&
        node is! skir.ExpressionNode_localWrapper &&
        node is! skir.ExpressionNode_queryWrapper) {
      return null;
    }
    return ExpressionProjection(
      root: node,
      suffix: skir.ValuePath(segments: reversed.reversed),
      descents: descents,
    );
  }
}

extension TypedQuerySource on skir.ExpressionQuery {
  skir.ExpressionNode get sourceExpression => switch (this) {
    skir.ExpressionQuery_resourceIdentityWrapper(:final value) ||
    skir.ExpressionQuery_resourceValueWrapper(:final value) ||
    skir.ExpressionQuery_resourceConfigurationWrapper(
      :final value,
    ) => switch (value) {
      skir.ResourceQuerySource_referenceWrapper(:final value) => value,
      skir.ResourceQuerySource_identityWrapper(:final value) => value.identity,
      _ => throw const ExpressionProblem("invalid_canonical_query"),
    },
    skir.ExpressionQuery_valueConfigurationWrapper(:final value) ||
    skir.ExpressionQuery_catalogDeclarationWrapper(:final value) => value,
    _ => throw const ExpressionProblem("unknown_query"),
  };
}

skir.ExpressionType nominalType(skir.TypeUse use, [bool missing = false]) =>
    skir.ExpressionType(
      value: skir.ExpressionValueType.wrapNominal(use),
      mayBeMissing: missing,
    );
skir.ExpressionType listType(
  skir.ExpressionType item, [
  bool missing = false,
]) => skir.ExpressionType(
  value: skir.ExpressionValueType.wrapList(item),
  mayBeMissing: missing,
);
skir.ExpressionType mapType(
  skir.ExpressionType key,
  skir.ExpressionType value, [
  bool missing = false,
]) => skir.ExpressionType(
  value: skir.ExpressionValueType.createMap(key: key, value: value),
  mayBeMissing: missing,
);
skir.ExpressionType entryType(
  skir.ExpressionType key,
  skir.ExpressionType value,
) => skir.ExpressionType(
  value: skir.ExpressionValueType.createEntry(key: key, value: value),
  mayBeMissing: false,
);
skir.TypeUse standardUse(String name, List<skir.TypeUse> arguments) =>
    skir.TypeUse.createNamed(
      definition: skir.TypeDefinitionId(
        typeId: skir.TypeId.createQualified(
          namespace: "typewriter",
          name: name,
        ),
        revision: 1,
      ),
      arguments: arguments,
    );

extension ExpressionDeclaredType on skir.ExpressionType {
  skir.ExpressionType withMissing(bool missing) =>
      skir.ExpressionType(value: value, mayBeMissing: missing);
  skir.TypeUse? declaredUse() => switch (value) {
    skir.ExpressionValueType_nominalWrapper(:final value) => value,
    skir.ExpressionValueType_listWrapper(:final value) => switch (value
        .declaredUse()) {
      final item? => standardUse("List", [item]),
      _ => null,
    },
    skir.ExpressionValueType_mapWrapper(:final value) => switch ((
      value.key.declaredUse(),
      value.value.declaredUse(),
    )) {
      (final key?, final item?) => standardUse("Map", [key, item]),
      _ => null,
    },
    skir.ExpressionValueType_nullableWrapper(:final value) => switch (value
        .declaredUse()) {
      final item? => skir.TypeUse.createNullable(value: item),
      _ => null,
    },
    _ => null,
  };
}
