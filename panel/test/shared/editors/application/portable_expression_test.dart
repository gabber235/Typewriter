import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test("matches the shared portable expression corpus", () async {
    final source = await File(
      "../skir-src/editor/v1/fixtures/portable_expression_conformance.json",
    ).readAsString();
    final document = jsonDecode(source) as Map<String, Object?>;
    final cases = (document["cases"]! as List<Object?>)
        .cast<Map<String, Object?>>();

    for (final fixture in cases) {
      final reads = _reads(fixture["reads"]! as Map<String, Object?>);
      final evaluator = PortableExpressionEvaluator(
        reads,
        budget: _budget(maxSteps: 100, maxCollectionItems: 100),
      );
      final result = evaluator.evaluate(
        _expression(fixture["expression"]! as Map<String, Object?>),
      );
      final expected = fixture["expected"]! as Map<String, Object?>;
      final expectedReads = (expected["evaluatedReads"]! as List<Object?>)
          .cast<String>();

      expect(
        result.reads.map((read) => read.key),
        expectedReads,
        reason: fixture["id"]! as String,
      );
      if (expected["available"] case final Map<String, Object?> available) {
        expect(result, isA<PortableExpressionAvailable>());
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
    final unread = skir.ExpressionNode.createRead(
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
        input: skir.ExpressionNode.createCall(
          operation: skir.OperationId(value: "unknown"),
          arguments: const [],
        ),
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
      skir.ExpressionNode.createRead(
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

  test("publishes the complete portable operation registry", () {
    expect(authoredPortableOperationIds, hasLength(64));
    expect(
      authoredPortableOperationIds,
      containsAll(const {
        "typewriter.rule.minimum",
        "typewriter.rule.nonEmpty",
        "typewriter.rule.singleLine",
        "typewriter.collection.size",
        "typewriter.number.gt",
        "typewriter.record.field",
        "typewriter.link.target",
        "typewriter.text.interpolate",
      }),
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
    final checks = <String, ({List<skir.DataValue> arguments, String value})>{
      "typewriter.rule.nonEmpty": (
        arguments: [skir.DataValue.wrapStringValue("value")],
        value: "boolean:true",
      ),
      "typewriter.rule.singleLine": (
        arguments: [skir.DataValue.wrapStringValue("one line")],
        value: "boolean:true",
      ),
      "typewriter.collection.size": (
        arguments: [collection],
        value: "integer:1",
      ),
      "typewriter.number.gt": (
        arguments: [
          skir.DataValue.wrapInteger("9"),
          skir.DataValue.wrapInteger("4"),
        ],
        value: "boolean:true",
      ),
      "typewriter.rule.minimum": (
        arguments: [
          skir.DataValue.wrapInteger("5"),
          skir.DataValue.wrapInteger("5"),
          skir.DataValue.wrapBoolean(true),
        ],
        value: "boolean:true",
      ),
      "typewriter.record.field": (
        arguments: [record, skir.DataValue.wrapStringValue("title")],
        value: "string:Quest",
      ),
    };

    for (final entry in checks.entries) {
      final result = evaluator.evaluate(
        skir.ExpressionNode.createCall(
          operation: skir.OperationId(value: entry.key),
          arguments: entry.value.arguments.map(skir.ExpressionNode.wrapLiteral),
        ),
      );
      expect(result, isA<PortableExpressionAvailable>(), reason: entry.key);
      expect(
        _valueKey((result as PortableExpressionAvailable).value),
        entry.value.value,
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
          _booleanCall("typewriter.value.eq", [values.$1, values.$2]),
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
        final value = _availableCall("typewriter.collection.access", [
          keyed,
          lookup.$1,
        ]);
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
      _availableCall("typewriter.link.target", [link]),
      skir.DataValue.wrapStringValue("page:first"),
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
      _booleanCall("typewriter.value.eq", [link("one"), link("one")]),
      true,
    );
    expect(
      _booleanCall("typewriter.value.eq", [link("one"), link("two")]),
      false,
    );
  });

  test("regex replacement preserves escapes and rejects absent captures", () {
    final escaped = _availableCall("typewriter.regex.replace", [
      skir.DataValue.wrapStringValue("a"),
      skir.DataValue.wrapStringValue("(a)"),
      skir.DataValue.wrapStringValue(r"\$1"),
    ]);
    expect(_valueKey(escaped), r"string:$1");

    final failed = _call("typewriter.regex.replace", [
      skir.DataValue.wrapStringValue("a"),
      skir.DataValue.wrapStringValue("(a)"),
      skir.DataValue.wrapStringValue(r"$99"),
    ]);
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
        final result = _call("typewriter.regex.matches", [
          skir.DataValue.wrapStringValue("\n"),
          skir.DataValue.wrapStringValue(pattern),
        ]);
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
      final value = _availableCall("typewriter.number.divide", [
        skir.DataValue.wrapDecimal(dividend),
        skir.DataValue.wrapDecimal(divisor),
      ]);
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
    skir.ExpressionNode call(String operation, List<String> values) =>
        skir.ExpressionNode.createCall(
          operation: skir.OperationId(value: operation),
          arguments: values
              .map(
                (value) => skir.ExpressionNode.wrapLiteral(
                  skir.DataValue.wrapStringValue(value),
                ),
              )
              .toList(),
        );

    final anchorSearch =
        PortableExpressionEvaluator(
          const {},
          budget: _budget(maxSteps: 50),
        ).evaluate(
          call("typewriter.regex.matches", [
            List.filled(200, "x").join(),
            r"^$",
          ]),
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
          call("typewriter.regex.replace", [
            "",
            "",
            List.filled(20, "replacement").join(),
          ]),
        );
    expect(replacementOutput, isA<PortableExpressionFailed>());
    expect(
      (replacementOutput as PortableExpressionFailed).code,
      "expression_step_limit",
    );
  });

  test("bounds text expansion and uses Unicode character boundaries", () {
    skir.ExpressionNode call(String operation, List<skir.DataValue> values) =>
        skir.ExpressionNode.createCall(
          operation: skir.OperationId(value: operation),
          arguments: values.map(skir.ExpressionNode.wrapLiteral),
        );

    PortableExpressionResult evaluate(
      String operation,
      List<skir.DataValue> values, {
      int maxSteps = 100,
      int maxCollectionItems = 100,
    }) => PortableExpressionEvaluator(
      const {},
      budget: _budget(
        maxSteps: maxSteps,
        maxCollectionItems: maxCollectionItems,
      ),
    ).evaluate(call(operation, values));

    final replaced = evaluate("typewriter.text.replace", [
      skir.DataValue.wrapStringValue("😀"),
      skir.DataValue.wrapStringValue(""),
      skir.DataValue.wrapStringValue("_"),
    ]);
    expect(replaced, isA<PortableExpressionAvailable>());
    expect(
      _valueKey((replaced as PortableExpressionAvailable).value),
      "string:_😀_",
    );

    final split = evaluate("typewriter.text.split", [
      skir.DataValue.wrapStringValue("😀x"),
      skir.DataValue.wrapStringValue(""),
    ]);
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
    final emptySplit = evaluate("typewriter.text.split", [
      skir.DataValue.wrapStringValue(""),
      skir.DataValue.wrapStringValue(""),
    ]);
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
      evaluate("typewriter.text.replace", [
        skir.DataValue.wrapStringValue("a"),
        skir.DataValue.wrapStringValue(""),
        large,
      ], maxSteps: 30),
      evaluate("typewriter.text.join", [
        skir.DataValue.createListValue(
          items: [
            skir.ListItem(
              id: skir.ItemId(value: "only"),
              value: large,
            ),
          ],
        ),
        skir.DataValue.wrapStringValue(""),
      ], maxSteps: 30),
      evaluate("typewriter.text.interpolate", [large], maxSteps: 30),
    ];
    for (final result in amplified) {
      expect(result, isA<PortableExpressionFailed>());
      expect(
        (result as PortableExpressionFailed).code,
        "expression_step_limit",
      );
    }

    final splitLimit = evaluate("typewriter.text.split", [
      skir.DataValue.wrapStringValue("😀x"),
      skir.DataValue.wrapStringValue(""),
    ], maxCollectionItems: 1);
    expect(splitLimit, isA<PortableExpressionFailed>());
    expect(
      (splitLimit as PortableExpressionFailed).code,
      "expression_collection_limit",
    );
  });

  test("validates operation arity and finite scientific notation", () {
    final comparison = _availableCall("typewriter.number.gt", [
      skir.DataValue.wrapFloat(1e-8),
      skir.DataValue.wrapFloat(0),
    ]);
    expect(_valueKey(comparison), "boolean:true");

    final missing = _call("typewriter.number.gt", [
      skir.DataValue.wrapInteger("1"),
    ]);
    expect(missing, isA<PortableExpressionFailed>());
    expect((missing as PortableExpressionFailed).code, "operation_arity");

    final extra = _call("typewriter.boolean.not", [
      skir.DataValue.wrapBoolean(true),
      skir.DataValue.wrapBoolean(false),
    ]);
    expect(extra, isA<PortableExpressionFailed>());
    expect((extra as PortableExpressionFailed).code, "operation_arity");
  });

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

    final result = _call("typewriter.value.eq", [value, value]);

    expect(result, isA<PortableExpressionFailed>());
    expect((result as PortableExpressionFailed).code, "value_depth_limit");
  });

  test("uses portable whitespace and partial uniqueness semantics", () {
    for (final whitespace in ["\u0085", "\ufeff", "\u001c"]) {
      final nonBlank = _availableCall("typewriter.rule.nonBlank", [
        skir.DataValue.wrapStringValue(whitespace),
      ]);
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

    final disproved = _call("typewriter.rule.unique", [
      values([
        skir.DataValue.wrapStringValue("same"),
        skir.DataValue.unfilled,
        skir.DataValue.wrapStringValue("same"),
      ]),
    ]);
    expect(disproved, isA<PortableExpressionAvailable>());
    expect(
      _valueKey((disproved as PortableExpressionAvailable).value),
      "boolean:false",
    );

    final unknown = _call("typewriter.rule.unique", [
      values([
        skir.DataValue.wrapStringValue("known"),
        skir.DataValue.unfilled,
      ]),
    ]);
    expect(unknown, isA<PortableExpressionUnavailable>());

    final size = _availableCall("typewriter.collection.size", [
      values([skir.DataValue.unfilled]),
    ]);
    expect(_valueKey(size), "integer:1");
  });

  test("evaluates the complete collection expression vocabulary", () {
    final item = skir.ExpressionBindingId(value: "item");
    final accumulator = skir.ExpressionBindingId(value: "accumulator");
    final left = skir.ExpressionBindingId(value: "left");
    final right = skir.ExpressionBindingId(value: "right");
    final input = _list("source", ["3", "1", "2", "1"]);
    final itemRead = _bindingRead(item);
    final accumulatorRead = _bindingRead(accumulator);
    final leftRead = _bindingRead(left);
    final rightRead = _bindingRead(right);
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

    skir.ExpressionNode unary(
      String operation,
      skir.ExpressionNode body, {
      List<skir.ExpressionNode> arguments = const [],
    }) => _collectionNode(
      operation,
      input,
      bindings: [item],
      arguments: arguments,
      body: body,
    );

    expect(
      _valueKey(
        available(
          unary("any", _callNode("typewriter.number.gt", [itemRead, two])),
        ).value,
      ),
      "boolean:true",
    );
    expect(
      _valueKey(
        available(
          unary("all", _callNode("typewriter.number.gt", [itemRead, one])),
        ).value,
      ),
      "boolean:false",
    );
    expect(
      _valueKey(
        available(
          unary("none", _callNode("typewriter.number.lt", [itemRead, one])),
        ).value,
      ),
      "boolean:true",
    );
    expect(
      _valueKey(
        available(
          unary("count", _callNode("typewriter.value.eq", [itemRead, one])),
        ).value,
      ),
      "integer:2",
    );
    expect(
      _valueKey(
        available(
          unary("find", _callNode("typewriter.value.eq", [itemRead, one])),
        ).value,
      ),
      "integer:1",
    );
    expect(
      _valueKey(
        available(
          unary("find_last", _callNode("typewriter.value.eq", [itemRead, one])),
        ).value,
      ),
      "integer:1",
    );
    expect(
      _integerItems(
        available(
          unary("filter", _callNode("typewriter.number.gt", [itemRead, one])),
        ).value,
      ),
      [3, 2],
    );
    expect(
      _integerItems(
        available(
          unary("map", _callNode("typewriter.number.add", [itemRead, one])),
        ).value,
      ),
      [4, 2, 3, 2],
    );
    expect(_integerItems(available(unary("distinct_by", itemRead)).value), [
      3,
      1,
      2,
    ]);
    expect(_integerItems(available(unary("sort_by", itemRead)).value), [
      1,
      1,
      2,
      3,
    ]);
    expect(
      _valueKey(available(unary("unique_by", itemRead)).value),
      "boolean:false",
    );

    final groups = available(
      unary(
        "group_by",
        _callNode("typewriter.number.remainder", [itemRead, two]),
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
        available(unary("flat_map", skir.ExpressionNode.wrapLiteral(nested)))
            .value,
      ),
      [7, 8, 7, 8, 7, 8, 7, 8],
    );

    expect(_integerItems(available(_collectionNode("distinct", input)).value), [
      3,
      1,
      2,
    ]);
    expect(_integerItems(available(_collectionNode("reverse", input)).value), [
      1,
      2,
      1,
      3,
    ]);
    expect(
      _integerItems(
        available(_collectionNode("take", input, arguments: [two])).value,
      ),
      [3, 1],
    );
    expect(
      _integerItems(
        available(_collectionNode("skip", input, arguments: [two])).value,
      ),
      [2, 1],
    );
    expect(
      _valueKey(
        available(
          _collectionNode(
            "reduce",
            input,
            bindings: [accumulator, item],
            body: _callNode("typewriter.number.add", [
              accumulatorRead,
              itemRead,
            ]),
          ),
        ).value,
      ),
      "integer:7",
    );
    expect(
      _valueKey(
        available(
          _collectionNode(
            "fold",
            input,
            bindings: [accumulator, item],
            arguments: [
              skir.ExpressionNode.wrapLiteral(skir.DataValue.wrapInteger("10")),
            ],
            body: _callNode("typewriter.number.add", [
              accumulatorRead,
              itemRead,
            ]),
          ),
        ).value,
      ),
      "integer:17",
    );
    expect(
      _integerItems(
        available(
          _collectionNode(
            "sort_with",
            input,
            bindings: [left, right],
            body: _callNode("typewriter.number.subtract", [
              leftRead,
              rightRead,
            ]),
          ),
        ).value,
      ),
      [1, 1, 2, 3],
    );
  });

  test("collection expressions enforce shape and item budgets", () {
    final item = skir.ExpressionBindingId(value: "item");
    final input = _list("source", ["3", "1", "2"]);
    final predicate = _callNode("typewriter.number.gt", [
      _bindingRead(item),
      skir.ExpressionNode.wrapLiteral(skir.DataValue.wrapInteger("2")),
    ]);
    final shortCircuit =
        PortableExpressionEvaluator(
          const {},
          budget: _budget(maxCollectionItems: 1),
        ).evaluate(
          _collectionNode("any", input, bindings: [item], body: predicate),
        );
    expect(shortCircuit, isA<PortableExpressionAvailable>());

    final exhausted =
        PortableExpressionEvaluator(
          const {},
          budget: _budget(maxCollectionItems: 2),
        ).evaluate(
          _collectionNode(
            "map",
            input,
            bindings: [item],
            body: _bindingRead(item),
          ),
        );
    expect(exhausted, isA<PortableExpressionFailed>());
    expect(
      (exhausted as PortableExpressionFailed).code,
      "expression_collection_limit",
    );

    final duplicate = PortableExpressionEvaluator(const {}, budget: _budget())
        .evaluate(
          _collectionNode(
            "fold",
            input,
            bindings: [item, item],
            arguments: [
              skir.ExpressionNode.wrapLiteral(skir.DataValue.wrapInteger("0")),
            ],
            body: _bindingRead(item),
          ),
        );
    expect(duplicate, isA<PortableExpressionFailed>());
    expect(
      (duplicate as PortableExpressionFailed).code,
      "duplicate_collection_binding",
    );
  });
}

skir.ExpressionNode _collectionNode(
  String operation,
  skir.DataValue input, {
  List<skir.ExpressionBindingId> bindings = const [],
  List<skir.ExpressionNode> arguments = const [],
  skir.ExpressionNode? body,
}) => skir.ExpressionNode.createCollection(
  operation: skir.OperationId(value: "typewriter.collection.$operation"),
  input: skir.ExpressionNode.wrapLiteral(input),
  bindings: bindings,
  arguments: arguments,
  body: body,
);

skir.ExpressionNode _bindingRead(skir.ExpressionBindingId binding) =>
    skir.ExpressionNode.createRead(
      binding: binding,
      path: skir.ValuePath(segments: const []),
    );

skir.ExpressionNode _callNode(
  String operation,
  List<skir.ExpressionNode> arguments,
) => skir.ExpressionNode.createCall(
  operation: skir.OperationId(value: operation),
  arguments: arguments,
);

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

PortableExpressionResult _call(String operation, List<skir.DataValue> values) {
  return PortableExpressionEvaluator(const {}, budget: _budget()).evaluate(
    skir.ExpressionNode.createCall(
      operation: skir.OperationId(value: operation),
      arguments: values.map(skir.ExpressionNode.wrapLiteral),
    ),
  );
}

skir.EvaluationBudget _budget({
  int maxSteps = 10000,
  int maxCollectionItems = 10000,
}) => skir.EvaluationBudget(
  maxSteps: maxSteps,
  maxCollectionItems: maxCollectionItems,
);

skir.DataValue _availableCall(String operation, List<skir.DataValue> values) {
  final result = _call(operation, values);
  expect(result, isA<PortableExpressionAvailable>());
  return (result as PortableExpressionAvailable).value;
}

bool _booleanCall(String operation, List<skir.DataValue> values) {
  final result = _availableCall(operation, values);
  return switch (result) {
    skir.DataValue_booleanWrapper(:final value) => value,
    _ => throw StateError("Expected a Boolean result"),
  };
}

bool _regexMatches(String input, String pattern) =>
    _booleanCall("typewriter.regex.matches", [
      skir.DataValue.wrapStringValue(input),
      skir.DataValue.wrapStringValue(pattern),
    ]);

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

Map<skir.ExpressionBindingId, skir.DataValue> _reads(
  Map<String, Object?> source,
) {
  final fields = <String, List<skir.FieldValue>>{};
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
    fields
        .putIfAbsent(binding, () => [])
        .add(skir.FieldValue(name: field, value: value));
  }
  return {
    for (final entry in fields.entries)
      skir.ExpressionBindingId(value: entry.key): skir.DataValue.createRecord(
        fields: entry.value,
      ),
  };
}

skir.ExpressionNode _expression(Map<String, Object?> source) {
  if (source["call"] case final String operation) {
    return skir.ExpressionNode.createCall(
      operation: skir.OperationId(value: operation),
      arguments: (source["arguments"]! as List<Object?>)
          .cast<Map<String, Object?>>()
          .map(_expression),
    );
  }
  if (source["read"] case final String binding) {
    return skir.ExpressionNode.createRead(
      binding: skir.ExpressionBindingId(value: binding),
      path: skir.ValuePath(
        segments: [
          for (final field in (source["path"]! as List<Object?>).cast<String>())
            skir.PathSegment.createField(name: field),
        ],
      ),
    );
  }
  if (source["and"] case final List<Object?> operands) {
    return skir.ExpressionNode.createAnd(
      left: _expression(operands[0]! as Map<String, Object?>),
      right: _expression(operands[1]! as Map<String, Object?>),
    );
  }
  if (source["orElse"] case final List<Object?> operands) {
    return skir.ExpressionNode.createOrElse(
      input: _expression(operands[0]! as Map<String, Object?>),
      fallback: _expression(operands[1]! as Map<String, Object?>),
    );
  }
  return skir.ExpressionNode.wrapLiteral(_value(source));
}

skir.DataValue _value(Map<String, Object?> source) {
  if (source["unfilled"] == true) {
    return skir.DataValue.unfilled;
  }
  if (source["integer"] case final String value) {
    return skir.DataValue.wrapInteger(value);
  }
  if (source["decimal"] case final String value) {
    return skir.DataValue.wrapDecimal(value);
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
        arguments: const [],
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
