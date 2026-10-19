import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

void main() {
  test("matches the shared portable expression corpus", () async {
    final source = await File(
      "../skir-src/editor/v1/fixtures/portable_expression_conformance.json",
    ).readAsString();
    final document = jsonDecode(source) as Map<String, Object?>;
    final cases = (document["cases"]! as List<Object?>)
        .cast<Map<String, Object?>>();
    expect(
      {
        for (final fixture in cases)
          if (fixture["dartBinaryRoundTripKnownIssue"] != null) fixture["id"],
      },
      {"portable_whitespace_bom_and_nel", "portable_whitespace_trim"},
      reason: "Only the two deferred leading U+FEFF decoder cases are exempt",
    );

    for (final fixture in cases) {
      final expression = skir.ExpressionNode.serializer.fromJson(
        fixture["expression"],
      );
      final encoded = skir.ExpressionNode.serializer.toJsonCode(expression);
      expect(
        skir.ExpressionNode.serializer.toJsonCode(
          skir.ExpressionNode.serializer.fromJsonCode(encoded),
        ),
        encoded,
        reason: "${fixture["id"]}: JSON round trip",
      );
      // The pinned Dart decoder drops a leading U+FEFF. Its repair is deferred.
      if (fixture["dartBinaryRoundTripKnownIssue"] == null) {
        expect(
          skir.ExpressionNode.serializer.toJsonCode(
            skir.ExpressionNode.serializer.fromBytes(
              skir.ExpressionNode.serializer.toBytes(expression),
            ),
          ),
          encoded,
          reason: "${fixture["id"]}: binary round trip",
        );
      }
      skir.ExpressionType? inferred;
      final codes = checkPortableExpression(
        expression,
        catalog: _fixtureCatalog(fixture),
        bindings: {
          for (final entry
              in (fixture["bindingTypes"] as Map<String, Object?>? ?? const {})
                  .entries)
            skir.ExpressionBindingId(value: entry.key): skir
                .ExpressionType
                .serializer
                .fromJson(entry.value),
        },
        partialBindings: {
          for (final entry
              in (fixture["partialBindings"] as Map<String, Object?>? ??
                      const {})
                  .entries)
            skir.ExpressionBindingId(value: entry.key): skir
                .TypeSelection
                .serializer
                .fromJson(entry.value),
        },
        expectedOutput: skir.ExpressionType.serializer.fromJson(
          fixture["resultType"],
        ),
        onInferred: (value) => inferred = value,
      );
      expect(codes, fixture["checkCodes"], reason: "${fixture["id"]}: checker");
      expect(fixture.containsKey("inferredType"), isTrue);
      expect(
        inferred,
        fixture["inferredType"] == null
            ? null
            : skir.ExpressionType.serializer.fromJson(fixture["inferredType"]),
        reason: "${fixture["id"]}: inferred type",
      );
      final reads = _reads(fixture["reads"]! as Map<String, Object?>);
      final evaluator = PortableExpressionEvaluator(
        reads,
        budget: _budget(maxSteps: 100, maxCollectionItems: 100),
      );
      final result = evaluator.evaluate(expression);
      final byHost = fixture["expectedByHost"] as Map<String, Object?>?;
      final expected =
          (byHost?["dart"] ?? fixture["expected"])! as Map<String, Object?>;
      final expectedReads = (expected["evaluatedReads"]! as List<Object?>)
          .cast<String>();

      expect(
        result.reads.map((read) => read.key),
        expectedReads,
        reason: fixture["id"]! as String,
      );
      if (expected["available"] case final Map<String, Object?> available) {
        expect(
          result,
          isA<PortableExpressionAvailable>(),
          reason:
              "${fixture["id"]}: ${result is PortableExpressionFailed ? result.code : result.runtimeType}",
        );
        expect(
          _valueKey((result as PortableExpressionAvailable).value),
          _valueKey(_value(available)),
          reason: fixture["id"]! as String,
        );
      } else if (expected["failed"] case final Map<String, Object?> failed) {
        expect(
          result,
          isA<PortableExpressionFailed>(),
          reason: fixture["id"]! as String,
        );
        expect(
          (result as PortableExpressionFailed).code,
          failed["code"],
          reason: fixture["id"]! as String,
        );
      } else {
        expect(
          result,
          isA<PortableExpressionUnavailable>(),
          reason: fixture["id"]! as String,
        );
      }
    }
  });

  test("uses ordered short circuit and missing only fallback", () {
    final missing = skir.ExpressionBindingId(value: "missing");
    final evaluator = PortableExpressionEvaluator(const {}, budget: _budget());
    final unread = skir.ExpressionNode.createInput(
      binding: missing,
      path: skir.ValuePath(segments: const []),
    );

    final shortCircuit = evaluator.evaluate(
      skir.ExpressionNode.createAnd(
        left: skir.ExpressionNode.wrapLiteral(
          skir.DataValue.wrapBoolean(false),
        ),
        right: unread,
      ),
    );
    expect(shortCircuit, isA<PortableExpressionAvailable>());
    expect(shortCircuit.reads, isEmpty);

    final failed = evaluator.evaluate(
      skir.ExpressionNode.createOrElse(
        input: skir.ExpressionNode.unknown,
        fallback: skir.ExpressionNode.wrapLiteral(
          skir.DataValue.wrapStringValue("fallback"),
        ),
      ),
    );
    expect(failed, isA<PortableExpressionFailed>());
  });

  test("configured value reads retain their exact nested location", () {
    final location = skir.ValueLocation(
      resource: skir.ResourceId(value: "element:message"),
      path: skir.ValuePath(
        segments: [skir.PathSegment.createField(name: "style")],
      ),
    );
    final evaluator = PortableExpressionEvaluator.configuredValue(
      value: skir.DataValue.createRecord(
        fields: [
          skir.FieldValue(
            name: "visible",
            value: skir.DataValue.wrapBoolean(true),
          ),
        ],
      ),
      location: location,
      budget: _budget(),
    );

    final result = evaluator.evaluate(
      skir.ExpressionNode.createInput(
        binding: skir.ExpressionBindingId(value: "configured_value"),
        path: skir.ValuePath(
          segments: [skir.PathSegment.createField(name: "visible")],
        ),
      ),
    );

    expect(result, isA<PortableExpressionAvailable>());
    expect(
      result.reads.single.location,
      skir.ValueLocation(
        resource: location.resource,
        path: skir.ValuePath(
          segments: [
            skir.PathSegment.createField(name: "style"),
            skir.PathSegment.createField(name: "visible"),
          ],
        ),
      ),
    );
  });

  test("evaluates generated helper and rule operations", () {
    final evaluator = PortableExpressionEvaluator(const {}, budget: _budget());
    final collection = skir.DataValue.createListValue(
      items: [
        skir.ListItem(
          id: skir.ItemId(value: "first"),
          value: skir.DataValue.wrapStringValue("value"),
        ),
      ],
    );
    final record = skir.DataValue.createRecord(
      fields: [
        skir.FieldValue(
          name: "title",
          value: skir.DataValue.wrapStringValue("Quest"),
        ),
      ],
    );
    final checks = <String, (skir.ExpressionNode, String)>{
      "nonempty": (
        skir.ExpressionNode.createRuleUnary(
          operation: skir.RuleUnaryOperation.nonEmpty,
          source: skir.ExpressionNode.wrapLiteral(
            skir.DataValue.wrapStringValue("value"),
          ),
        ),
        "boolean:true",
      ),
      "single line": (
        skir.ExpressionNode.createRuleUnary(
          operation: skir.RuleUnaryOperation.singleLine,
          source: skir.ExpressionNode.wrapLiteral(
            skir.DataValue.wrapStringValue("one line"),
          ),
        ),
        "boolean:true",
      ),
      "size": (
        skir.ExpressionNode.wrapCollectionSize(
          skir.ExpressionNode.wrapLiteral(collection),
        ),
        "integer:1",
      ),
      "greater": (
        skir.ExpressionNode.createNumberCompare(
          operation: skir.NumberCompareOperation.greater,
          left: skir.ExpressionNode.wrapLiteral(
            skir.DataValue.wrapInteger("9"),
          ),
          right: skir.ExpressionNode.wrapLiteral(
            skir.DataValue.wrapInteger("4"),
          ),
        ),
        "boolean:true",
      ),
      "minimum": (
        skir.ExpressionNode.createRuleNumericBound(
          direction: skir.BoundDirection.minimum,
          source: skir.ExpressionNode.wrapLiteral(
            skir.DataValue.wrapInteger("5"),
          ),
          bound: skir.ExpressionNode.wrapLiteral(
            skir.DataValue.wrapInteger("5"),
          ),
          inclusive: skir.ExpressionNode.wrapLiteral(
            skir.DataValue.wrapBoolean(true),
          ),
        ),
        "boolean:true",
      ),
      "field": (
        skir.ExpressionNode.createField(
          source: skir.ExpressionNode.wrapLiteral(record),
          name: "title",
        ),
        "string:Quest",
      ),
    };
    for (final entry in checks.entries) {
      final result = evaluator.evaluate(entry.value.$1);
      expect(result, isA<PortableExpressionAvailable>(), reason: entry.key);
      expect(
        _valueKey((result as PortableExpressionAvailable).value),
        entry.value.$2,
        reason: entry.key,
      );
    }
  });

  test(
    "canonical equality ignores collection identities and unordered order",
    () {
      final leftRecord = skir.DataValue.createRecord(
        fields: [
          skir.FieldValue(
            name: "second",
            value: skir.DataValue.wrapInteger("2"),
          ),
          skir.FieldValue(
            name: "first",
            value: skir.DataValue.wrapInteger("1"),
          ),
        ],
      );
      final rightRecord = skir.DataValue.createRecord(
        fields: [
          skir.FieldValue(
            name: "first",
            value: skir.DataValue.wrapInteger("1"),
          ),
          skir.FieldValue(
            name: "second",
            value: skir.DataValue.wrapInteger("2"),
          ),
        ],
      );
      final leftList = _list("left", ["1", "2"]);
      final rightList = _list("right", ["1", "2"]);
      final leftSet = _set("left", ["1", "2"]);
      final rightSet = _set("right", ["2", "1"]);
      final leftMap = _map("left", [("a", "1"), ("b", "2")]);
      final rightMap = _map("right", [("b", "2"), ("a", "1")]);

      for (final values in [
        (leftRecord, rightRecord),
        (leftList, rightList),
        (leftSet, rightSet),
        (leftMap, rightMap),
      ]) {
        expect(
          _booleanNode(
            skir.ExpressionNode.createValueCompare(
              operation: skir.ValueCompareOperation.equal,
              left: skir.ExpressionNode.wrapLiteral(values.$1),
              right: skir.ExpressionNode.wrapLiteral(values.$2),
            ),
          ),
          true,
        );
      }

      final keyed = skir.DataValue.createMapValue(
        rows: [
          skir.MapRow(
            id: skir.ItemId(value: "record"),
            key: leftRecord,
            value: skir.DataValue.wrapStringValue("record"),
          ),
          skir.MapRow(
            id: skir.ItemId(value: "list"),
            key: leftList,
            value: skir.DataValue.wrapStringValue("list"),
          ),
          skir.MapRow(
            id: skir.ItemId(value: "set"),
            key: leftSet,
            value: skir.DataValue.wrapStringValue("set"),
          ),
          skir.MapRow(
            id: skir.ItemId(value: "map"),
            key: leftMap,
            value: skir.DataValue.wrapStringValue("map"),
          ),
        ],
      );
      for (final lookup in [
        (rightRecord, "record"),
        (rightList, "list"),
        (rightSet, "set"),
        (rightMap, "map"),
      ]) {
        final value = _availableNode(
          skir.ExpressionNode.createCollectionAccess(
            source: skir.ExpressionNode.wrapLiteral(keyed),
            index: skir.ExpressionNode.wrapLiteral(lookup.$1),
          ),
        );
        expect(_valueKey(value), "string:${lookup.$2}");
      }
    },
  );

  test("link target projection preserves the resource key", () {
    final link = skir.DataValue.createLink(
      endpoint: skir.EndpointId(value: "page.elements"),
      target: skir.LinkTarget(
        resource: skir.ResourceId(value: "page:first"),
        opposite: skir.ValuePath(segments: const []),
      ),
    );
    expect(
      _availableNode(
        skir.ExpressionNode.wrapLinkTarget(
          skir.ExpressionNode.wrapLiteral(link),
        ),
      ),
      skir.ResourceId(value: "page:first").toExpressionValue(),
    );
  });

  test("canonical links preserve their opposite location", () {
    skir.DataValue link(String item) => skir.DataValue.createLink(
      endpoint: skir.EndpointId(value: "page.elements"),
      target: skir.LinkTarget(
        resource: skir.ResourceId(value: "page:first"),
        opposite: skir.ValuePath(
          segments: [
            skir.PathSegment.createField(name: "elements"),
            skir.PathSegment.createItem(id: skir.ItemId(value: item)),
          ],
        ),
      ),
    );

    expect(
      _booleanNode(
        skir.ExpressionNode.createValueCompare(
          operation: skir.ValueCompareOperation.equal,
          left: skir.ExpressionNode.wrapLiteral(link("one")),
          right: skir.ExpressionNode.wrapLiteral(link("one")),
        ),
      ),
      true,
    );
    expect(
      _booleanNode(
        skir.ExpressionNode.createValueCompare(
          operation: skir.ValueCompareOperation.equal,
          left: skir.ExpressionNode.wrapLiteral(link("one")),
          right: skir.ExpressionNode.wrapLiteral(link("two")),
        ),
      ),
      false,
    );
  });

  test("regex replacement preserves escapes and rejects absent captures", () {
    final escaped = _availableNode(
      skir.ExpressionNode.createRegexReplace(
        source: skir.ExpressionNode.wrapLiteral(
          skir.DataValue.wrapStringValue("a"),
        ),
        pattern: skir.ExpressionNode.wrapLiteral(
          skir.DataValue.wrapStringValue("(a)"),
        ),
        replacement: skir.ExpressionNode.wrapLiteral(
          skir.DataValue.wrapStringValue(r"\$1"),
        ),
      ),
    );
    expect(_valueKey(escaped), r"string:$1");

    final failed = _evaluate(
      skir.ExpressionNode.createRegexReplace(
        source: skir.ExpressionNode.wrapLiteral(
          skir.DataValue.wrapStringValue("a"),
        ),
        pattern: skir.ExpressionNode.wrapLiteral(
          skir.DataValue.wrapStringValue("(a)"),
        ),
        replacement: skir.ExpressionNode.wrapLiteral(
          skir.DataValue.wrapStringValue(r"$99"),
        ),
      ),
    );
    expect(failed, isA<PortableExpressionFailed>());
    expect(
      (failed as PortableExpressionFailed).code,
      "invalid_regex_replacement",
    );
  });

  test(
    "portable regex normalization is independent of Dart host semantics",
    () {
      expect(_regexMatches("\u00a0", r"\s"), isTrue);
      expect(_regexMatches("😀", "."), isTrue);
      expect(_regexMatches("\u0085", "."), isTrue);
      expect(_regexMatches("\n", "."), isFalse);
      expect(_regexMatches("\u00a0", r"[\s]"), isTrue);

      for (final pattern in [r"\v", r"[\v]"]) {
        final result = _evaluate(
          skir.ExpressionNode.createRegexTest(
            mode: skir.RegexMatchMode.search,
            source: skir.ExpressionNode.wrapLiteral(
              skir.DataValue.wrapStringValue("\n"),
            ),
            pattern: skir.ExpressionNode.wrapLiteral(
              skir.DataValue.wrapStringValue(pattern),
            ),
          ),
        );
        expect(result, isA<PortableExpressionFailed>());
        expect(
          (result as PortableExpressionFailed).code,
          "unsupported_regex_pattern",
        );
      }
    },
  );

  test("decimal division uses 34 significant digits and half even rounding", () {
    void expectQuotient(String dividend, String divisor, String expected) {
      final value = _availableNode(
        skir.ExpressionNode.createNumberArithmetic(
          operation: skir.NumberArithmeticOperation.divide,
          first: skir.ExpressionNode.wrapLiteral(
            skir.DataValue.wrapDecimal(dividend),
          ),
          second: skir.ExpressionNode.wrapLiteral(
            skir.DataValue.wrapDecimal(divisor),
          ),
          remaining: [],
        ),
      );
      expect(_valueKey(value), "decimal:$expected");
    }

    expectQuotient("10", "3", "3.333333333333333333333333333333333");
    expectQuotient(
      "0.00000000000000000000000000000000001",
      "3",
      "0.000000000000000000000000000000000003333333333333333333333333333333333",
    );
    expectQuotient(
      "10000000000000000000000000000000000",
      "3",
      "3333333333333333333333333333333333",
    );
    expectQuotient("-1", "6", "-0.1666666666666666666666666666666667");
  });

  test("enforces step and depth budgets after ordered short circuit", () {
    final shortCircuit =
        PortableExpressionEvaluator(
          const {},
          budget: _budget(maxSteps: 2),
        ).evaluate(
          skir.ExpressionNode.createAnd(
            left: skir.ExpressionNode.wrapLiteral(
              skir.DataValue.wrapBoolean(false),
            ),
            right: skir.ExpressionNode.wrapLiteral(
              skir.DataValue.wrapBoolean(true),
            ),
          ),
        );
    expect(shortCircuit, isA<PortableExpressionAvailable>());

    final exhausted =
        PortableExpressionEvaluator(
          const {},
          budget: _budget(maxSteps: 2),
        ).evaluate(
          skir.ExpressionNode.createAnd(
            left: skir.ExpressionNode.wrapLiteral(
              skir.DataValue.wrapBoolean(true),
            ),
            right: skir.ExpressionNode.wrapLiteral(
              skir.DataValue.wrapBoolean(true),
            ),
          ),
        );
    expect(exhausted, isA<PortableExpressionFailed>());
    expect(
      (exhausted as PortableExpressionFailed).code,
      "expression_step_limit",
    );

    var nested = skir.ExpressionNode.wrapLiteral(
      skir.DataValue.wrapBoolean(true),
    );
    for (var index = 0; index < 600; index++) {
      nested = skir.ExpressionNode.createAnd(
        left: nested,
        right: skir.ExpressionNode.wrapLiteral(
          skir.DataValue.wrapBoolean(true),
        ),
      );
    }
    final tooDeep = PortableExpressionEvaluator(
      const {},
      budget: _budget(maxSteps: 2000),
    ).evaluate(nested);
    expect(tooDeep, isA<PortableExpressionFailed>());
    expect(
      (tooDeep as PortableExpressionFailed).code,
      "expression_depth_limit",
    );
  });

  test("charges regex search and replacement output to the step budget", () {
    final anchorSearch =
        PortableExpressionEvaluator(
          const {},
          budget: _budget(maxSteps: 50),
        ).evaluate(
          skir.ExpressionNode.createRegexTest(
            mode: skir.RegexMatchMode.search,
            source: skir.ExpressionNode.wrapLiteral(
              skir.DataValue.wrapStringValue(List.filled(200, "x").join()),
            ),
            pattern: skir.ExpressionNode.wrapLiteral(
              skir.DataValue.wrapStringValue(r"^$"),
            ),
          ),
        );
    expect(anchorSearch, isA<PortableExpressionFailed>());
    expect(
      (anchorSearch as PortableExpressionFailed).code,
      "expression_step_limit",
    );

    final replacementOutput =
        PortableExpressionEvaluator(
          const {},
          budget: _budget(maxSteps: 30),
        ).evaluate(
          skir.ExpressionNode.createRegexReplace(
            source: skir.ExpressionNode.wrapLiteral(
              skir.DataValue.wrapStringValue(""),
            ),
            pattern: skir.ExpressionNode.wrapLiteral(
              skir.DataValue.wrapStringValue(""),
            ),
            replacement: skir.ExpressionNode.wrapLiteral(
              skir.DataValue.wrapStringValue(
                List.filled(20, "replacement").join(),
              ),
            ),
          ),
        );
    expect(replacementOutput, isA<PortableExpressionFailed>());
    expect(
      (replacementOutput as PortableExpressionFailed).code,
      "expression_step_limit",
    );
  });

  test("bounds text expansion and uses Unicode character boundaries", () {
    PortableExpressionResult evaluateNode(
      skir.ExpressionNode node, {
      int maxSteps = 100,
      int maxCollectionItems = 100,
    }) => PortableExpressionEvaluator(
      const {},
      budget: _budget(
        maxSteps: maxSteps,
        maxCollectionItems: maxCollectionItems,
      ),
    ).evaluate(node);

    final replaced = evaluateNode(
      skir.ExpressionNode.createTextReplace(
        source: skir.ExpressionNode.wrapLiteral(
          skir.DataValue.wrapStringValue("😀"),
        ),
        target: skir.ExpressionNode.wrapLiteral(
          skir.DataValue.wrapStringValue(""),
        ),
        replacement: skir.ExpressionNode.wrapLiteral(
          skir.DataValue.wrapStringValue("_"),
        ),
      ),
    );
    expect(replaced, isA<PortableExpressionAvailable>());
    expect(
      _valueKey((replaced as PortableExpressionAvailable).value),
      "string:_😀_",
    );

    final split = evaluateNode(
      skir.ExpressionNode.createTextSplit(
        source: skir.ExpressionNode.wrapLiteral(
          skir.DataValue.wrapStringValue("😀x"),
        ),
        separator: skir.ExpressionNode.wrapLiteral(
          skir.DataValue.wrapStringValue(""),
        ),
      ),
    );
    expect(split, isA<PortableExpressionAvailable>());
    final splitItems =
        ((split as PortableExpressionAvailable).value
                as skir.DataValue_listValueWrapper)
            .value
            .items;
    expect(splitItems.map((item) => _valueKey(item.value)), [
      "string:😀",
      "string:x",
    ]);
    final emptySplit = evaluateNode(
      skir.ExpressionNode.createTextSplit(
        source: skir.ExpressionNode.wrapLiteral(
          skir.DataValue.wrapStringValue(""),
        ),
        separator: skir.ExpressionNode.wrapLiteral(
          skir.DataValue.wrapStringValue(""),
        ),
      ),
    );
    expect(emptySplit, isA<PortableExpressionAvailable>());
    expect(
      ((emptySplit as PortableExpressionAvailable).value
              as skir.DataValue_listValueWrapper)
          .value
          .items,
      isEmpty,
    );

    final large = skir.DataValue.wrapStringValue(
      List.filled(20, "value").join(),
    );
    final amplified = [
      evaluateNode(
        skir.ExpressionNode.createTextReplace(
          source: skir.ExpressionNode.wrapLiteral(
            skir.DataValue.wrapStringValue("a"),
          ),
          target: skir.ExpressionNode.wrapLiteral(
            skir.DataValue.wrapStringValue(""),
          ),
          replacement: skir.ExpressionNode.wrapLiteral(large),
        ),
        maxSteps: 30,
      ),
      evaluateNode(
        skir.ExpressionNode.createTextJoin(
          source: skir.ExpressionNode.wrapLiteral(
            skir.DataValue.createListValue(
              items: [
                skir.ListItem(
                  id: skir.ItemId(value: "only"),
                  value: large,
                ),
              ],
            ),
          ),
          separator: skir.ExpressionNode.wrapLiteral(
            skir.DataValue.wrapStringValue(""),
          ),
        ),
        maxSteps: 30,
      ),
      evaluateNode(
        skir.ExpressionNode.createTextInterpolate(
          parts: [skir.ExpressionNode.wrapLiteral(large)],
        ),
        maxSteps: 30,
      ),
    ];
    for (final result in amplified) {
      expect(result, isA<PortableExpressionFailed>());
      expect(
        (result as PortableExpressionFailed).code,
        "expression_step_limit",
      );
    }

    final splitLimit = evaluateNode(
      skir.ExpressionNode.createTextSplit(
        source: skir.ExpressionNode.wrapLiteral(
          skir.DataValue.wrapStringValue("😀x"),
        ),
        separator: skir.ExpressionNode.wrapLiteral(
          skir.DataValue.wrapStringValue(""),
        ),
      ),
      maxCollectionItems: 1,
    );
    expect(splitLimit, isA<PortableExpressionFailed>());
    expect(
      (splitLimit as PortableExpressionFailed).code,
      "expression_collection_limit",
    );
  });

  test(
    "rejects malformed typed nodes and accepts finite scientific notation",
    () {
      final comparison = _availableNode(
        skir.ExpressionNode.createNumberCompare(
          operation: skir.NumberCompareOperation.greater,
          left: skir.ExpressionNode.wrapLiteral(skir.DataValue.wrapFloat(1e-8)),
          right: skir.ExpressionNode.wrapLiteral(skir.DataValue.wrapFloat(0)),
        ),
      );
      expect(_valueKey(comparison), "boolean:true");

      final missing = _evaluate(
        skir.ExpressionNode.serializer.fromJson({
          "kind": "number_compare",
          "value": {
            "operation": "greater",
            "left": {
              "kind": "literal",
              "value": {"kind": "integer", "value": "1"},
            },
          },
        }),
      );
      expect(missing, isA<PortableExpressionFailed>());
      expect((missing as PortableExpressionFailed).code, "unknown_expression");
      final unknownOperation = _evaluate(
        skir.ExpressionNode.createTextUnary(
          operation: skir.TextUnaryOperation.unknown,
          source: skir.ExpressionNode.wrapLiteral(
            skir.DataValue.wrapStringValue("text"),
          ),
        ),
      );
      expect(unknownOperation, isA<PortableExpressionFailed>());
    },
  );

  test("deep authored values return a bounded evaluation failure", () {
    final actualType = skir.NamedTypeUse(
      definition: skir.TypeDefinitionId(
        typeId: skir.TypeId.createQualified(
          namespace: "typewriter",
          name: "Nested",
        ),
        revision: 1,
      ),
      arguments: const [],
    );
    var value = skir.DataValue.wrapBoolean(true);
    for (var depth = 0; depth < 600; depth++) {
      value = skir.DataValue.createNamed(
        actualType: actualType,
        payload: value,
      );
    }

    final result = _evaluate(
      skir.ExpressionNode.createValueCompare(
        operation: skir.ValueCompareOperation.equal,
        left: skir.ExpressionNode.wrapLiteral(value),
        right: skir.ExpressionNode.wrapLiteral(value),
      ),
    );

    expect(result, isA<PortableExpressionFailed>());
    expect((result as PortableExpressionFailed).code, "value_depth_limit");
  });

  test("uses portable whitespace and partial uniqueness semantics", () {
    for (final whitespace in ["\u0085", "\ufeff", "\u001c"]) {
      final nonBlank = _availableNode(
        skir.ExpressionNode.createRuleUnary(
          operation: skir.RuleUnaryOperation.nonBlank,
          source: skir.ExpressionNode.wrapLiteral(
            skir.DataValue.wrapStringValue(whitespace),
          ),
        ),
      );
      expect(
        _valueKey(nonBlank),
        whitespace == "\u001c" ? "boolean:true" : "boolean:false",
      );
    }

    skir.DataValue values(List<skir.DataValue> items) =>
        skir.DataValue.createListValue(
          items: [
            for (final entry in items.indexed)
              skir.ListItem(
                id: skir.ItemId(value: "item.${entry.$1}"),
                value: entry.$2,
              ),
          ],
        );

    final disproved = _evaluate(
      skir.ExpressionNode.createRuleUnary(
        operation: skir.RuleUnaryOperation.unique,
        source: skir.ExpressionNode.wrapLiteral(
          values([
            skir.DataValue.wrapStringValue("same"),
            skir.DataValue.unfilled,
            skir.DataValue.wrapStringValue("same"),
          ]),
        ),
      ),
    );
    expect(disproved, isA<PortableExpressionAvailable>());
    expect(
      _valueKey((disproved as PortableExpressionAvailable).value),
      "boolean:false",
    );

    final unknown = _evaluate(
      skir.ExpressionNode.createRuleUnary(
        operation: skir.RuleUnaryOperation.unique,
        source: skir.ExpressionNode.wrapLiteral(
          values([
            skir.DataValue.wrapStringValue("known"),
            skir.DataValue.unfilled,
          ]),
        ),
      ),
    );
    expect(unknown, isA<PortableExpressionUnavailable>());

    final size = _availableNode(
      skir.ExpressionNode.wrapCollectionSize(
        skir.ExpressionNode.wrapLiteral(values([skir.DataValue.unfilled])),
      ),
    );
    expect(_valueKey(size), "integer:1");
  });

  test("evaluates the complete collection expression vocabulary", () {
    final input = _list("source", ["3", "1", "2", "1"]);
    final itemRead = localExpression(0);
    final accumulatorRead = localExpression(0);
    final leftRead = localExpression(0);
    final rightRead = localExpression(1);
    final one = skir.ExpressionNode.wrapLiteral(
      skir.DataValue.wrapInteger("1"),
    );
    final two = skir.ExpressionNode.wrapLiteral(
      skir.DataValue.wrapInteger("2"),
    );
    final evaluator = PortableExpressionEvaluator(const {}, budget: _budget());

    PortableExpressionAvailable available(skir.ExpressionNode node) {
      final result = evaluator.evaluate(node);
      expect(result, isA<PortableExpressionAvailable>());
      return result as PortableExpressionAvailable;
    }

    expect(
      _valueKey(
        available(
          skir.ExpressionNode.createAny(
            source: skir.ExpressionNode.wrapLiteral(input),
            body: skir.ExpressionNode.createNumberCompare(
              operation: skir.NumberCompareOperation.greater,
              left: itemRead,
              right: two,
            ),
          ),
        ).value,
      ),
      "boolean:true",
    );
    expect(
      _valueKey(
        available(
          skir.ExpressionNode.createAll(
            source: skir.ExpressionNode.wrapLiteral(input),
            body: skir.ExpressionNode.createNumberCompare(
              operation: skir.NumberCompareOperation.greater,
              left: itemRead,
              right: one,
            ),
          ),
        ).value,
      ),
      "boolean:false",
    );
    expect(
      _valueKey(
        available(
          skir.ExpressionNode.createNone(
            source: skir.ExpressionNode.wrapLiteral(input),
            body: skir.ExpressionNode.createNumberCompare(
              operation: skir.NumberCompareOperation.less,
              left: itemRead,
              right: one,
            ),
          ),
        ).value,
      ),
      "boolean:true",
    );
    expect(
      _valueKey(
        available(
          skir.ExpressionNode.createCount(
            source: skir.ExpressionNode.wrapLiteral(input),
            body: skir.ExpressionNode.createValueCompare(
              operation: skir.ValueCompareOperation.equal,
              left: itemRead,
              right: one,
            ),
          ),
        ).value,
      ),
      "integer:2",
    );
    expect(
      _valueKey(
        available(
          skir.ExpressionNode.createFind(
            source: skir.ExpressionNode.wrapLiteral(input),
            body: skir.ExpressionNode.createValueCompare(
              operation: skir.ValueCompareOperation.equal,
              left: itemRead,
              right: one,
            ),
          ),
        ).value,
      ),
      "integer:1",
    );
    expect(
      _valueKey(
        available(
          skir.ExpressionNode.createFindLast(
            source: skir.ExpressionNode.wrapLiteral(input),
            body: skir.ExpressionNode.createValueCompare(
              operation: skir.ValueCompareOperation.equal,
              left: itemRead,
              right: one,
            ),
          ),
        ).value,
      ),
      "integer:1",
    );
    expect(
      _integerItems(
        available(
          skir.ExpressionNode.createFilter(
            source: skir.ExpressionNode.wrapLiteral(input),
            body: skir.ExpressionNode.createNumberCompare(
              operation: skir.NumberCompareOperation.greater,
              left: itemRead,
              right: one,
            ),
          ),
        ).value,
      ),
      [3, 2],
    );
    expect(
      _integerItems(
        available(
          skir.ExpressionNode.createMap(
            source: skir.ExpressionNode.wrapLiteral(input),
            body: skir.ExpressionNode.createNumberArithmetic(
              operation: skir.NumberArithmeticOperation.add,
              first: itemRead,
              second: one,
              remaining: [],
            ),
          ),
        ).value,
      ),
      [4, 2, 3, 2],
    );
    expect(
      _integerItems(
        available(
          skir.ExpressionNode.createDistinctBy(
            source: skir.ExpressionNode.wrapLiteral(input),
            body: itemRead,
          ),
        ).value,
      ),
      [3, 1, 2],
    );
    expect(
      _integerItems(
        available(
          skir.ExpressionNode.createSortBy(
            source: skir.ExpressionNode.wrapLiteral(input),
            descending: null,
            key: itemRead,
          ),
        ).value,
      ),
      [1, 1, 2, 3],
    );
    expect(
      _valueKey(
        available(
          skir.ExpressionNode.createUniqueBy(
            source: skir.ExpressionNode.wrapLiteral(input),
            body: itemRead,
          ),
        ).value,
      ),
      "boolean:false",
    );

    final groups = available(
      skir.ExpressionNode.createGroupBy(
        source: skir.ExpressionNode.wrapLiteral(input),
        body: skir.ExpressionNode.createNumberArithmetic(
          operation: skir.NumberArithmeticOperation.remainder,
          first: itemRead,
          second: two,
          remaining: [],
        ),
      ),
    ).value;
    expect(_groupSizes(groups), {"integer:1": 3, "integer:0": 1});

    final nested = skir.DataValue.createListValue(
      items: [
        skir.ListItem(
          id: skir.ItemId(value: "nested.a"),
          value: skir.DataValue.wrapInteger("7"),
        ),
        skir.ListItem(
          id: skir.ItemId(value: "nested.b"),
          value: skir.DataValue.wrapInteger("8"),
        ),
      ],
    );
    expect(
      _integerItems(
        available(
          skir.ExpressionNode.createFlatMap(
            source: skir.ExpressionNode.wrapLiteral(input),
            body: skir.ExpressionNode.wrapLiteral(nested),
          ),
        ).value,
      ),
      [7, 8, 7, 8, 7, 8, 7, 8],
    );

    expect(
      _integerItems(
        available(
          skir.ExpressionNode.wrapDistinct(
            skir.ExpressionNode.wrapLiteral(input),
          ),
        ).value,
      ),
      [3, 1, 2],
    );
    expect(
      _integerItems(
        available(
          skir.ExpressionNode.wrapReverse(
            skir.ExpressionNode.wrapLiteral(input),
          ),
        ).value,
      ),
      [1, 2, 1, 3],
    );
    expect(
      _integerItems(
        available(
          skir.ExpressionNode.createTake(
            source: skir.ExpressionNode.wrapLiteral(input),
            count: two,
          ),
        ).value,
      ),
      [3, 1],
    );
    expect(
      _integerItems(
        available(
          skir.ExpressionNode.createSkip(
            source: skir.ExpressionNode.wrapLiteral(input),
            count: two,
          ),
        ).value,
      ),
      [2, 1],
    );
    expect(
      _valueKey(
        available(
          skir.ExpressionNode.createReduce(
            source: skir.ExpressionNode.wrapLiteral(input),
            body: skir.ExpressionNode.createNumberArithmetic(
              operation: skir.NumberArithmeticOperation.add,
              first: accumulatorRead,
              second: localExpression(1),
              remaining: [],
            ),
          ),
        ).value,
      ),
      "integer:7",
    );
    expect(
      _valueKey(
        available(
          skir.ExpressionNode.createFold(
            source: skir.ExpressionNode.wrapLiteral(input),
            initial: skir.ExpressionNode.wrapLiteral(
              skir.DataValue.wrapInteger("10"),
            ),
            body: skir.ExpressionNode.createNumberArithmetic(
              operation: skir.NumberArithmeticOperation.add,
              first: accumulatorRead,
              second: localExpression(1),
              remaining: [],
            ),
          ),
        ).value,
      ),
      "integer:17",
    );
    expect(
      _integerItems(
        available(
          skir.ExpressionNode.createSortWith(
            source: skir.ExpressionNode.wrapLiteral(input),
            comparator: skir.ExpressionNode.createNumberArithmetic(
              operation: skir.NumberArithmeticOperation.subtract,
              first: leftRead,
              second: rightRead,
              remaining: [],
            ),
          ),
        ).value,
      ),
      [1, 1, 2, 3],
    );
  });

  test("collection expressions enforce shape and item budgets", () {
    final input = _list("source", ["3", "1", "2"]);
    final predicate = skir.ExpressionNode.createNumberCompare(
      operation: skir.NumberCompareOperation.greater,
      left: localExpression(0),
      right: skir.ExpressionNode.wrapLiteral(skir.DataValue.wrapInteger("2")),
    );
    final shortCircuit =
        PortableExpressionEvaluator(
          const {},
          budget: _budget(maxCollectionItems: 1),
        ).evaluate(
          skir.ExpressionNode.createAny(
            source: skir.ExpressionNode.wrapLiteral(input),
            body: predicate,
          ),
        );
    expect(shortCircuit, isA<PortableExpressionAvailable>());

    final exhausted =
        PortableExpressionEvaluator(
          const {},
          budget: _budget(maxCollectionItems: 2),
        ).evaluate(
          skir.ExpressionNode.createMap(
            source: skir.ExpressionNode.wrapLiteral(input),
            body: localExpression(0),
          ),
        );
    expect(exhausted, isA<PortableExpressionFailed>());
    expect(
      (exhausted as PortableExpressionFailed).code,
      "expression_collection_limit",
    );

    final invalidLocal =
        PortableExpressionEvaluator(const {}, budget: _budget()).evaluate(
          skir.ExpressionNode.createFold(
            source: skir.ExpressionNode.wrapLiteral(input),
            initial: skir.ExpressionNode.wrapLiteral(
              skir.DataValue.wrapInteger("0"),
            ),
            body: localExpression(2),
          ),
        );
    expect(invalidLocal, isA<PortableExpressionFailed>());
    expect(
      (invalidLocal as PortableExpressionFailed).code,
      "invalid_expression_local",
    );
  });
}

List<int> _integerItems(skir.DataValue value) {
  final list = value as skir.DataValue_listValueWrapper;
  return [
    for (final item in list.value.items)
      int.parse((item.value as skir.DataValue_integerWrapper).value),
  ];
}

Map<String, int> _groupSizes(skir.DataValue value) {
  final map = value as skir.DataValue_mapValueWrapper;
  return {
    for (final row in map.value.rows)
      _valueKey(row.key):
          (row.value as skir.DataValue_listValueWrapper).value.items.length,
  };
}

PortableExpressionResult _evaluate(skir.ExpressionNode node) =>
    PortableExpressionEvaluator(const {}, budget: _budget()).evaluate(node);

skir.EvaluationBudget _budget({
  int maxSteps = 10000,
  int maxCollectionItems = 10000,
}) => skir.EvaluationBudget(
  maxSteps: maxSteps,
  maxCollectionItems: maxCollectionItems,
);

skir.DataValue _availableNode(skir.ExpressionNode node) {
  final result = _evaluate(node);
  expect(result, isA<PortableExpressionAvailable>());
  return (result as PortableExpressionAvailable).value;
}

bool _booleanNode(skir.ExpressionNode node) {
  final result = _availableNode(node);
  return switch (result) {
    skir.DataValue_booleanWrapper(:final value) => value,
    _ => throw StateError("Expected a Boolean result"),
  };
}

bool _regexMatches(String input, String pattern) => _booleanNode(
  skir.ExpressionNode.createRegexTest(
    mode: skir.RegexMatchMode.search,
    source: skir.ExpressionNode.wrapLiteral(
      skir.DataValue.wrapStringValue(input),
    ),
    pattern: skir.ExpressionNode.wrapLiteral(
      skir.DataValue.wrapStringValue(pattern),
    ),
  ),
);

skir.DataValue _list(String prefix, List<String> values) {
  return skir.DataValue.createListValue(
    items: [
      for (var index = 0; index < values.length; index++)
        skir.ListItem(
          id: skir.ItemId(value: "$prefix.$index"),
          value: skir.DataValue.wrapInteger(values[index]),
        ),
    ],
  );
}

skir.DataValue _set(String prefix, List<String> values) {
  return skir.DataValue.createSetValue(
    items: [
      for (var index = 0; index < values.length; index++)
        skir.ListItem(
          id: skir.ItemId(value: "$prefix.$index"),
          value: skir.DataValue.wrapInteger(values[index]),
        ),
    ],
  );
}

skir.DataValue _map(String prefix, List<(String, String)> values) {
  return skir.DataValue.createMapValue(
    rows: [
      for (var index = 0; index < values.length; index++)
        skir.MapRow(
          id: skir.ItemId(value: "$prefix.$index"),
          key: skir.DataValue.wrapStringValue(values[index].$1),
          value: skir.DataValue.wrapInteger(values[index].$2),
        ),
    ],
  );
}

CheckedEditorCatalog _fixtureCatalog(Map<String, Object?> fixture) =>
    CheckedEditorCatalog(
      (skir.EditorCatalogWireSnapshot.defaultInstance.toMutable()
            ..types = [
              for (final encoded
                  in fixture["typeDefinitions"] as List<Object?>? ?? const [])
                _fixturePublished(
                  skir.TypeDefinition.serializer.fromJson(encoded),
                ),
            ])
          .toFrozen(),
    );

skir.PublishedType _fixturePublished(skir.TypeDefinition definition) =>
    skir.PublishedType(
      definition: definition,
      status: skir.DeclarationStatus.ready,
      effectiveFields: [
        if (definition.representation
            case skir.RepresentationTemplate_recordWrapper(:final value))
          for (final field in value.fields)
            skir.EffectiveFieldTemplate(
              key: field.owner.name,
              owner: field.owner,
              type: field.type,
              rules: const [],
            ),
      ],
      ancestorTemplates: definition.parents,
      display: null,
    );

Map<skir.ExpressionBindingId, skir.DataValue> _reads(
  Map<String, Object?> source,
) {
  final fields = <String, List<skir.FieldValue>>{};
  final roots = <skir.ExpressionBindingId, skir.DataValue>{};
  for (final entry in source.entries) {
    final separator = entry.key.indexOf(":");
    final binding = separator < 0
        ? entry.key
        : entry.key.substring(0, separator);
    final field = separator < 0 ? "value" : entry.key.substring(separator + 1);
    final encoded = entry.value! as Map<String, Object?>;
    final value = encoded["unavailable"] == true
        ? skir.DataValue.unfilled
        : _value(encoded);
    if (separator < 0) {
      roots[skir.ExpressionBindingId(value: binding)] = value;
      continue;
    }
    fields
        .putIfAbsent(binding, () => [])
        .add(skir.FieldValue(name: field, value: value));
  }
  return {
    ...roots,
    for (final entry in fields.entries)
      skir.ExpressionBindingId(value: entry.key): skir.DataValue.createRecord(
        fields: entry.value,
      ),
  };
}

skir.DataValue _value(Map<String, Object?> source) {
  if (source["null"] == true) return skir.DataValue.null_;
  if (source["unfilled"] == true) {
    return skir.DataValue.unfilled;
  }
  if (source["integer"] case final String value) {
    return skir.DataValue.wrapInteger(value);
  }
  if (source["decimal"] case final String value) {
    return skir.DataValue.wrapDecimal(value);
  }
  if (source["duration"] case final String value) {
    return skir.DataValue.createDuration(
      value: skir.Duration(milliseconds: int.parse(value)),
    );
  }
  if (source["timestamp"] case final String value) {
    return skir.DataValue.wrapTimestamp(DateTime.parse(value));
  }
  if (source["float"] case final String value) {
    return skir.DataValue.wrapFloat(double.parse(value));
  }
  if (source["string"] case final String value) {
    return skir.DataValue.wrapStringValue(value);
  }
  if (source["boolean"] case final bool value) {
    return skir.DataValue.wrapBoolean(value);
  }
  if (source["named"] case final Map<String, Object?> named) {
    return skir.DataValue.createNamed(
      actualType: skir.NamedTypeUse(
        definition: skir.TypeDefinitionId(
          typeId: skir.TypeId.wrapQualified(
            skir.QualifiedTypeId(
              namespace: named["namespace"]! as String,
              name: named["name"]! as String,
            ),
          ),
          revision: named["revision"]! as int,
        ),
        arguments: [
          for (final argument
              in named["arguments"] as List<Object?>? ?? const [])
            skir.TypeUse.serializer.fromJson(argument),
        ],
      ),
      payload: _value(named["payload"]! as Map<String, Object?>),
    );
  }
  if (source["record"] case final Map<String, Object?> record) {
    return skir.DataValue.createRecord(
      fields: [
        for (final entry in record.entries)
          skir.FieldValue(
            name: entry.key,
            value: _value(entry.value! as Map<String, Object?>),
          ),
      ],
    );
  }
  if (source["list"] case final List<Object?> items) {
    return skir.DataValue.createListValue(
      items: items.cast<Map<String, Object?>>().map(_listItem),
    );
  }
  if (source["set"] case final List<Object?> items) {
    return skir.DataValue.createSetValue(
      items: items.cast<Map<String, Object?>>().map(_listItem),
    );
  }
  if (source["map"] case final List<Object?> rows) {
    return skir.DataValue.createMapValue(
      rows: [
        for (final row in rows.cast<Map<String, Object?>>())
          skir.MapRow(
            id: skir.ItemId(value: row["id"]! as String),
            key: _value(row["key"]! as Map<String, Object?>),
            value: _value(row["value"]! as Map<String, Object?>),
          ),
      ],
    );
  }
  throw StateError("Unsupported fixture value $source");
}

skir.ListItem _listItem(Map<String, Object?> item) => skir.ListItem(
  id: skir.ItemId(value: item["id"]! as String),
  value: _value(item["value"]! as Map<String, Object?>),
);

String _valueKey(skir.DataValue value) => switch (value) {
  skir.DataValue_integerWrapper(:final value) => "integer:$value",
  skir.DataValue_decimalWrapper(:final value) =>
    "decimal:${_canonicalDecimal(value)}",
  skir.DataValue_stringValueWrapper(:final value) => "string:$value",
  skir.DataValue_booleanWrapper(:final value) => "boolean:$value",
  skir.DataValue_namedWrapper(:final value) =>
    "named:${value.actualType}:${_valueKey(value.payload)}",
  _ => value.toString(),
};

String _canonicalDecimal(String source) {
  var value = source;
  if (value.contains(".")) {
    value = value.replaceFirst(RegExp(r"0+$"), "");
    value = value.replaceFirst(RegExp(r"\.$"), "");
  }
  return value == "-0" ? "0" : value;
}
