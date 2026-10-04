import "dart:convert";
import "dart:io";

import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/expression.dart"
    as expression;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/type_catalog.dart"
    as types;
import "package:typewriter_panel/shared/editors/application/portable_expression.dart";

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
    final missing = types.ExpressionBindingId(value: "missing");
    final evaluator = PortableExpressionEvaluator(const {}, budget: _budget());
    final unread = expression.ExpressionNode.createRead(
      binding: missing,
      path: types.ValuePath(segments: const []),
    );

    final shortCircuit = evaluator.evaluate(
      expression.ExpressionNode.createAnd(
        left: expression.ExpressionNode.wrapLiteral(
          types.DataValue.wrapBoolean(false),
        ),
        right: unread,
      ),
    );
    expect(shortCircuit, isA<PortableExpressionAvailable>());
    expect(shortCircuit.reads, isEmpty);

    final failed = evaluator.evaluate(
      expression.ExpressionNode.createOrElse(
        input: expression.ExpressionNode.createCall(
          operation: types.OperationId(value: "unknown"),
          arguments: const [],
        ),
        fallback: expression.ExpressionNode.wrapLiteral(
          types.DataValue.wrapStringValue("fallback"),
        ),
      ),
    );
    expect(failed, isA<PortableExpressionFailed>());
  });

  test("configured value reads retain their exact nested location", () {
    final location = types.ValueLocation(
      resource: types.ResourceId(value: "element:message"),
      path: types.ValuePath(
        segments: [types.PathSegment.createField(name: "style")],
      ),
    );
    final evaluator = PortableExpressionEvaluator.configuredValue(
      value: types.DataValue.createRecord(
        fields: [
          types.FieldValue(
            name: "visible",
            value: types.DataValue.wrapBoolean(true),
          ),
        ],
      ),
      location: location,
      budget: _budget(),
    );

    final result = evaluator.evaluate(
      expression.ExpressionNode.createRead(
        binding: types.ExpressionBindingId(value: "configured_value"),
        path: types.ValuePath(
          segments: [types.PathSegment.createField(name: "visible")],
        ),
      ),
    );

    expect(result, isA<PortableExpressionAvailable>());
    expect(
      result.reads.single.location,
      types.ValueLocation(
        resource: location.resource,
        path: types.ValuePath(
          segments: [
            types.PathSegment.createField(name: "style"),
            types.PathSegment.createField(name: "visible"),
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
    final collection = types.DataValue.createListValue(
      items: [
        types.ListItem(
          id: types.ItemId(value: "first"),
          value: types.DataValue.wrapStringValue("value"),
        ),
      ],
    );
    final record = types.DataValue.createRecord(
      fields: [
        types.FieldValue(
          name: "title",
          value: types.DataValue.wrapStringValue("Quest"),
        ),
      ],
    );
    final checks = <String, ({List<types.DataValue> arguments, String value})>{
      "typewriter.rule.nonEmpty": (
        arguments: [types.DataValue.wrapStringValue("value")],
        value: "boolean:true",
      ),
      "typewriter.rule.singleLine": (
        arguments: [types.DataValue.wrapStringValue("one line")],
        value: "boolean:true",
      ),
      "typewriter.collection.size": (
        arguments: [collection],
        value: "integer:1",
      ),
      "typewriter.number.gt": (
        arguments: [
          types.DataValue.wrapInteger("9"),
          types.DataValue.wrapInteger("4"),
        ],
        value: "boolean:true",
      ),
      "typewriter.rule.minimum": (
        arguments: [
          types.DataValue.wrapInteger("5"),
          types.DataValue.wrapInteger("5"),
          types.DataValue.wrapBoolean(true),
        ],
        value: "boolean:true",
      ),
      "typewriter.record.field": (
        arguments: [record, types.DataValue.wrapStringValue("title")],
        value: "string:Quest",
      ),
    };

    for (final entry in checks.entries) {
      final result = evaluator.evaluate(
        expression.ExpressionNode.createCall(
          operation: types.OperationId(value: entry.key),
          arguments: entry.value.arguments.map(
            expression.ExpressionNode.wrapLiteral,
          ),
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
      final leftRecord = types.DataValue.createRecord(
        fields: [
          types.FieldValue(
            name: "second",
            value: types.DataValue.wrapInteger("2"),
          ),
          types.FieldValue(
            name: "first",
            value: types.DataValue.wrapInteger("1"),
          ),
        ],
      );
      final rightRecord = types.DataValue.createRecord(
        fields: [
          types.FieldValue(
            name: "first",
            value: types.DataValue.wrapInteger("1"),
          ),
          types.FieldValue(
            name: "second",
            value: types.DataValue.wrapInteger("2"),
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

      final keyed = types.DataValue.createMapValue(
        rows: [
          types.MapRow(
            id: types.ItemId(value: "record"),
            key: leftRecord,
            value: types.DataValue.wrapStringValue("record"),
          ),
          types.MapRow(
            id: types.ItemId(value: "list"),
            key: leftList,
            value: types.DataValue.wrapStringValue("list"),
          ),
          types.MapRow(
            id: types.ItemId(value: "set"),
            key: leftSet,
            value: types.DataValue.wrapStringValue("set"),
          ),
          types.MapRow(
            id: types.ItemId(value: "map"),
            key: leftMap,
            value: types.DataValue.wrapStringValue("map"),
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
    final link = types.DataValue.createLink(
      endpoint: types.EndpointId(value: "page.elements"),
      target: types.LinkTarget(
        resource: types.ResourceId(value: "page:first"),
        opposite: types.ValuePath(segments: const []),
      ),
    );
    expect(
      _availableCall("typewriter.link.target", [link]),
      types.DataValue.wrapStringValue("page:first"),
    );
  });

  test("canonical links preserve their opposite location", () {
    types.DataValue link(String item) => types.DataValue.createLink(
      endpoint: types.EndpointId(value: "page.elements"),
      target: types.LinkTarget(
        resource: types.ResourceId(value: "page:first"),
        opposite: types.ValuePath(
          segments: [
            types.PathSegment.createField(name: "elements"),
            types.PathSegment.createItem(id: types.ItemId(value: item)),
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
      types.DataValue.wrapStringValue("a"),
      types.DataValue.wrapStringValue("(a)"),
      types.DataValue.wrapStringValue(r"\$1"),
    ]);
    expect(_valueKey(escaped), r"string:$1");

    final failed = _call("typewriter.regex.replace", [
      types.DataValue.wrapStringValue("a"),
      types.DataValue.wrapStringValue("(a)"),
      types.DataValue.wrapStringValue(r"$99"),
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
          types.DataValue.wrapStringValue("\n"),
          types.DataValue.wrapStringValue(pattern),
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
        types.DataValue.wrapDecimal(dividend),
        types.DataValue.wrapDecimal(divisor),
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
          expression.ExpressionNode.createAnd(
            left: expression.ExpressionNode.wrapLiteral(
              types.DataValue.wrapBoolean(false),
            ),
            right: expression.ExpressionNode.wrapLiteral(
              types.DataValue.wrapBoolean(true),
            ),
          ),
        );
    expect(shortCircuit, isA<PortableExpressionAvailable>());

    final exhausted =
        PortableExpressionEvaluator(
          const {},
          budget: _budget(maxSteps: 2),
        ).evaluate(
          expression.ExpressionNode.createAnd(
            left: expression.ExpressionNode.wrapLiteral(
              types.DataValue.wrapBoolean(true),
            ),
            right: expression.ExpressionNode.wrapLiteral(
              types.DataValue.wrapBoolean(true),
            ),
          ),
        );
    expect(exhausted, isA<PortableExpressionFailed>());
    expect(
      (exhausted as PortableExpressionFailed).code,
      "expression_step_limit",
    );

    var nested = expression.ExpressionNode.wrapLiteral(
      types.DataValue.wrapBoolean(true),
    );
    for (var index = 0; index < 600; index++) {
      nested = expression.ExpressionNode.createAnd(
        left: nested,
        right: expression.ExpressionNode.wrapLiteral(
          types.DataValue.wrapBoolean(true),
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
    expression.ExpressionNode call(String operation, List<String> values) =>
        expression.ExpressionNode.createCall(
          operation: types.OperationId(value: operation),
          arguments: values
              .map(
                (value) => expression.ExpressionNode.wrapLiteral(
                  types.DataValue.wrapStringValue(value),
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
    expression.ExpressionNode call(
      String operation,
      List<types.DataValue> values,
    ) => expression.ExpressionNode.createCall(
      operation: types.OperationId(value: operation),
      arguments: values.map(expression.ExpressionNode.wrapLiteral),
    );

    PortableExpressionResult evaluate(
      String operation,
      List<types.DataValue> values, {
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
      types.DataValue.wrapStringValue("😀"),
      types.DataValue.wrapStringValue(""),
      types.DataValue.wrapStringValue("_"),
    ]);
    expect(replaced, isA<PortableExpressionAvailable>());
    expect(
      _valueKey((replaced as PortableExpressionAvailable).value),
      "string:_😀_",
    );

    final split = evaluate("typewriter.text.split", [
      types.DataValue.wrapStringValue("😀x"),
      types.DataValue.wrapStringValue(""),
    ]);
    expect(split, isA<PortableExpressionAvailable>());
    final splitItems =
        ((split as PortableExpressionAvailable).value
                as types.DataValue_listValueWrapper)
            .value
            .items;
    expect(splitItems.map((item) => _valueKey(item.value)), [
      "string:😀",
      "string:x",
    ]);
    final emptySplit = evaluate("typewriter.text.split", [
      types.DataValue.wrapStringValue(""),
      types.DataValue.wrapStringValue(""),
    ]);
    expect(emptySplit, isA<PortableExpressionAvailable>());
    expect(
      ((emptySplit as PortableExpressionAvailable).value
              as types.DataValue_listValueWrapper)
          .value
          .items,
      isEmpty,
    );

    final large = types.DataValue.wrapStringValue(
      List.filled(20, "value").join(),
    );
    final amplified = [
      evaluate("typewriter.text.replace", [
        types.DataValue.wrapStringValue("a"),
        types.DataValue.wrapStringValue(""),
        large,
      ], maxSteps: 30),
      evaluate("typewriter.text.join", [
        types.DataValue.createListValue(
          items: [
            types.ListItem(
              id: types.ItemId(value: "only"),
              value: large,
            ),
          ],
        ),
        types.DataValue.wrapStringValue(""),
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
      types.DataValue.wrapStringValue("😀x"),
      types.DataValue.wrapStringValue(""),
    ], maxCollectionItems: 1);
    expect(splitLimit, isA<PortableExpressionFailed>());
    expect(
      (splitLimit as PortableExpressionFailed).code,
      "expression_collection_limit",
    );
  });

  test("validates operation arity and finite scientific notation", () {
    final comparison = _availableCall("typewriter.number.gt", [
      types.DataValue.wrapFloat(1e-8),
      types.DataValue.wrapFloat(0),
    ]);
    expect(_valueKey(comparison), "boolean:true");

    final missing = _call("typewriter.number.gt", [
      types.DataValue.wrapInteger("1"),
    ]);
    expect(missing, isA<PortableExpressionFailed>());
    expect((missing as PortableExpressionFailed).code, "operation_arity");

    final extra = _call("typewriter.boolean.not", [
      types.DataValue.wrapBoolean(true),
      types.DataValue.wrapBoolean(false),
    ]);
    expect(extra, isA<PortableExpressionFailed>());
    expect((extra as PortableExpressionFailed).code, "operation_arity");
  });

  test("deep authored values return a bounded evaluation failure", () {
    final actualType = types.NamedTypeUse(
      definition: types.TypeDefinitionId(
        typeId: types.TypeId.createQualified(
          namespace: "typewriter",
          name: "Nested",
        ),
        revision: 1,
      ),
      arguments: const [],
    );
    var value = types.DataValue.wrapBoolean(true);
    for (var depth = 0; depth < 600; depth++) {
      value = types.DataValue.createNamed(
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
        types.DataValue.wrapStringValue(whitespace),
      ]);
      expect(
        _valueKey(nonBlank),
        whitespace == "\u001c" ? "boolean:true" : "boolean:false",
      );
    }

    types.DataValue values(List<types.DataValue> items) =>
        types.DataValue.createListValue(
          items: [
            for (final entry in items.indexed)
              types.ListItem(
                id: types.ItemId(value: "item.${entry.$1}"),
                value: entry.$2,
              ),
          ],
        );

    final disproved = _call("typewriter.rule.unique", [
      values([
        types.DataValue.wrapStringValue("same"),
        types.DataValue.unfilled,
        types.DataValue.wrapStringValue("same"),
      ]),
    ]);
    expect(disproved, isA<PortableExpressionAvailable>());
    expect(
      _valueKey((disproved as PortableExpressionAvailable).value),
      "boolean:false",
    );

    final unknown = _call("typewriter.rule.unique", [
      values([
        types.DataValue.wrapStringValue("known"),
        types.DataValue.unfilled,
      ]),
    ]);
    expect(unknown, isA<PortableExpressionUnavailable>());

    final size = _availableCall("typewriter.collection.size", [
      values([types.DataValue.unfilled]),
    ]);
    expect(_valueKey(size), "integer:1");
  });

  test("evaluates the complete collection expression vocabulary", () {
    final item = types.ExpressionBindingId(value: "item");
    final accumulator = types.ExpressionBindingId(value: "accumulator");
    final left = types.ExpressionBindingId(value: "left");
    final right = types.ExpressionBindingId(value: "right");
    final input = _list("source", ["3", "1", "2", "1"]);
    final itemRead = _bindingRead(item);
    final accumulatorRead = _bindingRead(accumulator);
    final leftRead = _bindingRead(left);
    final rightRead = _bindingRead(right);
    final one = expression.ExpressionNode.wrapLiteral(
      types.DataValue.wrapInteger("1"),
    );
    final two = expression.ExpressionNode.wrapLiteral(
      types.DataValue.wrapInteger("2"),
    );
    final evaluator = PortableExpressionEvaluator(const {}, budget: _budget());

    PortableExpressionAvailable available(expression.ExpressionNode node) {
      final result = evaluator.evaluate(node);
      expect(result, isA<PortableExpressionAvailable>());
      return result as PortableExpressionAvailable;
    }

    expression.ExpressionNode unary(
      String operation,
      expression.ExpressionNode body, {
      List<expression.ExpressionNode> arguments = const [],
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

    final nested = types.DataValue.createListValue(
      items: [
        types.ListItem(
          id: types.ItemId(value: "nested.a"),
          value: types.DataValue.wrapInteger("7"),
        ),
        types.ListItem(
          id: types.ItemId(value: "nested.b"),
          value: types.DataValue.wrapInteger("8"),
        ),
      ],
    );
    expect(
      _integerItems(
        available(
          unary("flat_map", expression.ExpressionNode.wrapLiteral(nested)),
        ).value,
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
              expression.ExpressionNode.wrapLiteral(
                types.DataValue.wrapInteger("10"),
              ),
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
    final item = types.ExpressionBindingId(value: "item");
    final input = _list("source", ["3", "1", "2"]);
    final predicate = _callNode("typewriter.number.gt", [
      _bindingRead(item),
      expression.ExpressionNode.wrapLiteral(types.DataValue.wrapInteger("2")),
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
              expression.ExpressionNode.wrapLiteral(
                types.DataValue.wrapInteger("0"),
              ),
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

expression.ExpressionNode _collectionNode(
  String operation,
  types.DataValue input, {
  List<types.ExpressionBindingId> bindings = const [],
  List<expression.ExpressionNode> arguments = const [],
  expression.ExpressionNode? body,
}) => expression.ExpressionNode.createCollection(
  operation: types.OperationId(value: "typewriter.collection.$operation"),
  input: expression.ExpressionNode.wrapLiteral(input),
  bindings: bindings,
  arguments: arguments,
  body: body,
);

expression.ExpressionNode _bindingRead(types.ExpressionBindingId binding) =>
    expression.ExpressionNode.createRead(
      binding: binding,
      path: types.ValuePath(segments: const []),
    );

expression.ExpressionNode _callNode(
  String operation,
  List<expression.ExpressionNode> arguments,
) => expression.ExpressionNode.createCall(
  operation: types.OperationId(value: operation),
  arguments: arguments,
);

List<int> _integerItems(types.DataValue value) {
  final list = value as types.DataValue_listValueWrapper;
  return [
    for (final item in list.value.items)
      int.parse((item.value as types.DataValue_integerWrapper).value),
  ];
}

Map<String, int> _groupSizes(types.DataValue value) {
  final map = value as types.DataValue_mapValueWrapper;
  return {
    for (final row in map.value.rows)
      _valueKey(row.key):
          (row.value as types.DataValue_listValueWrapper).value.items.length,
  };
}

PortableExpressionResult _call(String operation, List<types.DataValue> values) {
  return PortableExpressionEvaluator(const {}, budget: _budget()).evaluate(
    expression.ExpressionNode.createCall(
      operation: types.OperationId(value: operation),
      arguments: values.map(expression.ExpressionNode.wrapLiteral),
    ),
  );
}

expression.EvaluationBudget _budget({
  int maxSteps = 10000,
  int maxCollectionItems = 10000,
}) => expression.EvaluationBudget(
  maxSteps: maxSteps,
  maxCollectionItems: maxCollectionItems,
);

types.DataValue _availableCall(String operation, List<types.DataValue> values) {
  final result = _call(operation, values);
  expect(result, isA<PortableExpressionAvailable>());
  return (result as PortableExpressionAvailable).value;
}

bool _booleanCall(String operation, List<types.DataValue> values) {
  final result = _availableCall(operation, values);
  return switch (result) {
    types.DataValue_booleanWrapper(:final value) => value,
    _ => throw StateError("Expected a Boolean result"),
  };
}

bool _regexMatches(String input, String pattern) =>
    _booleanCall("typewriter.regex.matches", [
      types.DataValue.wrapStringValue(input),
      types.DataValue.wrapStringValue(pattern),
    ]);

types.DataValue _list(String prefix, List<String> values) {
  return types.DataValue.createListValue(
    items: [
      for (var index = 0; index < values.length; index++)
        types.ListItem(
          id: types.ItemId(value: "$prefix.$index"),
          value: types.DataValue.wrapInteger(values[index]),
        ),
    ],
  );
}

types.DataValue _set(String prefix, List<String> values) {
  return types.DataValue.createSetValue(
    items: [
      for (var index = 0; index < values.length; index++)
        types.ListItem(
          id: types.ItemId(value: "$prefix.$index"),
          value: types.DataValue.wrapInteger(values[index]),
        ),
    ],
  );
}

types.DataValue _map(String prefix, List<(String, String)> values) {
  return types.DataValue.createMapValue(
    rows: [
      for (var index = 0; index < values.length; index++)
        types.MapRow(
          id: types.ItemId(value: "$prefix.$index"),
          key: types.DataValue.wrapStringValue(values[index].$1),
          value: types.DataValue.wrapInteger(values[index].$2),
        ),
    ],
  );
}

Map<types.ExpressionBindingId, types.DataValue> _reads(
  Map<String, Object?> source,
) {
  final fields = <String, List<types.FieldValue>>{};
  for (final entry in source.entries) {
    final separator = entry.key.indexOf(":");
    final binding = separator < 0
        ? entry.key
        : entry.key.substring(0, separator);
    final field = separator < 0 ? "value" : entry.key.substring(separator + 1);
    final encoded = entry.value! as Map<String, Object?>;
    final value = encoded["unavailable"] == true
        ? types.DataValue.unfilled
        : _value(encoded);
    fields
        .putIfAbsent(binding, () => [])
        .add(types.FieldValue(name: field, value: value));
  }
  return {
    for (final entry in fields.entries)
      types.ExpressionBindingId(value: entry.key): types.DataValue.createRecord(
        fields: entry.value,
      ),
  };
}

expression.ExpressionNode _expression(Map<String, Object?> source) {
  if (source["call"] case final String operation) {
    return expression.ExpressionNode.createCall(
      operation: types.OperationId(value: operation),
      arguments: (source["arguments"]! as List<Object?>)
          .cast<Map<String, Object?>>()
          .map(_expression),
    );
  }
  if (source["read"] case final String binding) {
    return expression.ExpressionNode.createRead(
      binding: types.ExpressionBindingId(value: binding),
      path: types.ValuePath(
        segments: [
          for (final field in (source["path"]! as List<Object?>).cast<String>())
            types.PathSegment.createField(name: field),
        ],
      ),
    );
  }
  if (source["and"] case final List<Object?> operands) {
    return expression.ExpressionNode.createAnd(
      left: _expression(operands[0]! as Map<String, Object?>),
      right: _expression(operands[1]! as Map<String, Object?>),
    );
  }
  if (source["orElse"] case final List<Object?> operands) {
    return expression.ExpressionNode.createOrElse(
      input: _expression(operands[0]! as Map<String, Object?>),
      fallback: _expression(operands[1]! as Map<String, Object?>),
    );
  }
  return expression.ExpressionNode.wrapLiteral(_value(source));
}

types.DataValue _value(Map<String, Object?> source) {
  if (source["unfilled"] == true) {
    return types.DataValue.unfilled;
  }
  if (source["integer"] case final String value) {
    return types.DataValue.wrapInteger(value);
  }
  if (source["decimal"] case final String value) {
    return types.DataValue.wrapDecimal(value);
  }
  if (source["string"] case final String value) {
    return types.DataValue.wrapStringValue(value);
  }
  if (source["boolean"] case final bool value) {
    return types.DataValue.wrapBoolean(value);
  }
  if (source["named"] case final Map<String, Object?> named) {
    return types.DataValue.createNamed(
      actualType: types.NamedTypeUse(
        definition: types.TypeDefinitionId(
          typeId: types.TypeId.wrapQualified(
            types.QualifiedTypeId(
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
    return types.DataValue.createRecord(
      fields: [
        for (final entry in record.entries)
          types.FieldValue(
            name: entry.key,
            value: _value(entry.value! as Map<String, Object?>),
          ),
      ],
    );
  }
  if (source["list"] case final List<Object?> items) {
    return types.DataValue.createListValue(
      items: items.cast<Map<String, Object?>>().map(_listItem),
    );
  }
  if (source["set"] case final List<Object?> items) {
    return types.DataValue.createSetValue(
      items: items.cast<Map<String, Object?>>().map(_listItem),
    );
  }
  if (source["map"] case final List<Object?> rows) {
    return types.DataValue.createMapValue(
      rows: [
        for (final row in rows.cast<Map<String, Object?>>())
          types.MapRow(
            id: types.ItemId(value: row["id"]! as String),
            key: _value(row["key"]! as Map<String, Object?>),
            value: _value(row["value"]! as Map<String, Object?>),
          ),
      ],
    );
  }
  throw StateError("Unsupported fixture value $source");
}

types.ListItem _listItem(Map<String, Object?> item) => types.ListItem(
  id: types.ItemId(value: item["id"]! as String),
  value: _value(item["value"]! as Map<String, Object?>),
);

String _valueKey(types.DataValue value) => switch (value) {
  types.DataValue_integerWrapper(:final value) => "integer:$value",
  types.DataValue_decimalWrapper(:final value) =>
    "decimal:${_canonicalDecimal(value)}",
  types.DataValue_stringValueWrapper(:final value) => "string:$value",
  types.DataValue_booleanWrapper(:final value) => "boolean:$value",
  types.DataValue_namedWrapper(:final value) =>
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
