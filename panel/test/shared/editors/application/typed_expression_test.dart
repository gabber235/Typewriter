import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../../../support/catalog_fixture.dart";

final _catalog = CheckedEditorCatalog(
  skir.EditorCatalogWireSnapshot.defaultInstance,
);
final _rows = skir.ExpressionBindingId(value: "rows");
final _text = skir.TypeUse.wrapScalar(skir.ScalarKind.text);
final _i32 = skir.TypeUse.wrapScalar(
  skir.ScalarKind.createInteger(width: skir.IntegerWidth.signedThirtyTwo),
);
final _i64 = skir.TypeUse.wrapScalar(
  skir.ScalarKind.createInteger(width: skir.IntegerWidth.signedSixtyFour),
);
final _budget = skir.EvaluationBudget(maxSteps: 1000, maxCollectionItems: 1000);
skir.DataValue _list(List<String> values) => skir.DataValue.createListValue(
  items: [
    for (final (index, value) in values.indexed)
      skir.ListItem(
        id: skir.ItemId(value: "$index"),
        value: skir.DataValue.wrapStringValue(value),
      ),
  ],
);
List<String> _check(
  skir.ExpressionNode expression, {
  Map<skir.ExpressionBindingId, skir.ExpressionType> inputs = const {},
  skir.ExpressionType? expected,
}) => checkPortableExpression(
  expression,
  catalog: _catalog,
  bindings: inputs,
  expectedOutput: expected,
);
PortableExpressionResult _evaluate(
  skir.ExpressionNode expression, [
  Map<skir.ExpressionBindingId, skir.DataValue> inputs = const {},
]) => PortableExpressionEvaluator(inputs, budget: _budget).evaluate(expression);

void main() {
  test("fold gives its accumulator the initial type and retains a bound body width", () {
    final expression = skir.ExpressionNode.createFold(
      source: inputExpression(_rows),
      initial: integerLiteral(0),
      body: skir.ExpressionNode.createNumberArithmetic(
        operation: skir.NumberArithmeticOperation.add,
        first: localExpression(0),
        second: localExpression(1),
        remaining: const [],
      ),
    );
    final inputs = {_rows: listType(nominalType(_i32))};
    expect(
      _check(expression, inputs: inputs, expected: nominalType(_i32)),
      isEmpty,
    );
    expect(
      _check(
        expression,
        inputs: inputs,
        expected: nominalType(
          skir.TypeUse.wrapScalar(
            skir.ScalarKind.createInteger(
              width: skir.IntegerWidth.signedSixteen,
            ),
          ),
        ),
      ),
      contains("incompatible_expression_result_type"),
    );
    final values = skir.DataValue.createListValue(
      items: [
        for (final value in [2, 3])
          skir.ListItem(
            id: skir.ItemId(value: "$value"),
            value: skir.DataValue.wrapInteger("$value"),
          ),
      ],
    );
    final result =
        _evaluate(expression, {_rows: values}) as PortableExpressionAvailable;
    expect(result.value.authoredInteger, BigInt.from(5));
  });

  test(
    "nested lambda reads the outer accumulator without using the outer item",
    () {
      final expression = skir.ExpressionNode.createFold(
        source: inputExpression(_rows),
        initial: integerLiteral(0),
        body: skir.ExpressionNode.createCollectionAccess(
          source: skir.ExpressionNode.createMap(
            source: skir.ExpressionNode.wrapLiteral(_list(["unused"])),
            body: skir.ExpressionNode.createNumberArithmetic(
              operation: skir.NumberArithmeticOperation.add,
              first: localExpression(0, depth: 1),
              second: integerLiteral(1),
              remaining: const [],
            ),
          ),
          index: integerLiteral(0),
        ),
      );
      expect(
        _check(
          expression,
          inputs: {_rows: listType(nominalType(_text))},
          expected: nominalType(_i64, true),
        ),
        isEmpty,
      );
      final result = _evaluate(expression, {
        _rows: _list(["a", "b"]),
      }) as PortableExpressionAvailable;
      expect(result.value.authoredInteger, BigInt.from(2));
    },
  );

  test("map flatMap and groupBy expose their actual structural output", () {
    final source = skir.ExpressionNode.wrapLiteral(_list(["aa", "b", "aa"]));
    final mapped = skir.ExpressionNode.createMap(
      source: source,
      body: skir.ExpressionNode.wrapTextLength(localExpression(0)),
    );
    expect(_check(mapped, expected: listType(nominalType(_i64))), isEmpty);
    final flattened = skir.ExpressionNode.createFlatMap(
      source: source,
      body: skir.ExpressionNode.createTextSplit(
        source: localExpression(0),
        separator: skir.ExpressionNode.wrapLiteral(
          skir.DataValue.wrapStringValue(""),
        ),
      ),
    );
    expect(_check(flattened, expected: listType(nominalType(_text))), isEmpty);
    expect(
      ((_evaluate(flattened) as PortableExpressionAvailable).value
              as skir.DataValue_listValueWrapper)
          .value
          .items,
      hasLength(5),
    );
    final grouped = skir.ExpressionNode.createGroupBy(
      source: source,
      body: localExpression(0),
    );
    expect(
      _check(
        grouped,
        expected: mapType(nominalType(_text), listType(nominalType(_text))),
      ),
      isEmpty,
    );
    final groups =
        ((_evaluate(grouped) as PortableExpressionAvailable).value
                as skir.DataValue_mapValueWrapper)
            .value
            .rows;
    expect(groups, hasLength(2));
    expect(groups.first.id.value, "0");
    expect(
      (groups.first.value as skir.DataValue_listValueWrapper).value.items,
      hasLength(2),
    );
  });

  test(
    "nested literal width flexibility does not erase bound branch width",
    () {
      final literal = skir.ExpressionNode.wrapLiteral(
        skir.DataValue.createListValue(
          items: [
            skir.ListItem(
              id: skir.ItemId(value: "one"),
              value: skir.DataValue.wrapInteger("1"),
            ),
          ],
        ),
      );
      expect(_check(literal, expected: listType(nominalType(_i32))), isEmpty);
      final branch = skir.ExpressionNode.createConditional(
        test: skir.ExpressionNode.wrapLiteral(skir.DataValue.wrapBoolean(true)),
        yes: literal,
        no: inputExpression(_rows),
      );
      final narrower = nominalType(
        skir.TypeUse.wrapScalar(
          skir.ScalarKind.createInteger(width: skir.IntegerWidth.signedSixteen),
        ),
      );
      expect(
        _check(
          branch,
          inputs: {_rows: listType(nominalType(_i32))},
          expected: listType(narrower),
        ),
        contains("incompatible_expression_result_type"),
      );
      final setUse = standardUse("Set", [_i32]) as skir.TypeUse_namedWrapper;
      final setItem = skir.ParameterKey(
        owner: setUse.value.definition,
        index: 0,
      );
      final setCatalog = testCheckedCatalog(
        types: [
          _published(
            setUse.value.definition,
            skir.RepresentationTemplate.createSequence(
              kind: skir.CollectionKind.set_,
              item: skir.TypeTemplate.wrapParameter(setItem),
            ),
            parameters: [setItem],
          ),
        ],
      );
      expect(setCatalog.isReadyTypeUse(setUse), isTrue);
      expect(
        checkPortableExpression(
          literal,
          catalog: setCatalog,
          bindings: const {},
          expectedOutput: nominalType(setUse),
        ),
        contains("incompatible_expression_result_type"),
      );
    },
  );

  test(
    "null fallback removes nullability while unavailable remains separate",
    () {
      final list = listType(nominalType(_text));
      final nullable = skir.ExpressionType(
        value: skir.ExpressionValueType.wrapNullable(list),
        mayBeMissing: false,
      );
      expect(
        _check(
          inputExpression(_rows),
          inputs: {_rows: nullable},
          expected: list,
        ),
        contains("incompatible_expression_result_type"),
      );
      expect(
        _check(
          inputExpression(_rows),
          inputs: {_rows: list},
          expected: nullable,
        ),
        isEmpty,
      );
      final fallback = skir.ExpressionNode.createOrElse(
        input: inputExpression(_rows),
        fallback: skir.ExpressionNode.wrapLiteral(_list(["fallback"])),
      );
      expect(
        _check(fallback, inputs: {_rows: nullable}, expected: list),
        isEmpty,
      );
      expect(
        (_evaluate(fallback, {
          _rows: skir.DataValue.null_,
        }) as PortableExpressionAvailable).value,
        _list(["fallback"]),
      );
      expect(
        (_evaluate(inputExpression(_rows), {
          _rows: skir.DataValue.null_,
        }) as PortableExpressionAvailable).value,
        skir.DataValue.null_,
      );
      expect(
        _evaluate(inputExpression(_rows)),
        isA<PortableExpressionUnavailable>(),
      );
      expect(
        _check(
          skir.ExpressionNode.createOrElse(
            input: skir.ExpressionNode.wrapLiteral(skir.DataValue.null_),
            fallback: skir.ExpressionNode.wrapLiteral(_list(["fallback"])),
          ),
          expected: list,
        ),
        isEmpty,
      );
    },
  );

  test("only consumed external input schemas require admission", () {
    final unrelated = skir.ExpressionBindingId(value: "unrelated");
    final unresolved = nominalType(
      skir.TypeUse.createNamed(
        definition: _definition("UnavailableContext"),
        arguments: const [],
      ),
    );
    final inputs = {unrelated: unresolved};
    expect(
      _check(integerLiteral(1), inputs: inputs, expected: nominalType(_i32)),
      isEmpty,
    );
    expect(
      _check(
        skir.ExpressionNode.createInput(
          binding: unrelated,
          path: editorRootPath,
        ),
        inputs: inputs,
      ),
      ["invalid_expression_type"],
    );
  });

  test("custom generic collections retain nominal identity while derived results are structural", () {
    final box = _definition("Box");
    final dictionary = _definition("Dictionary");
    final caption = _definition("Caption");
    final boxItem = skir.ParameterKey(owner: box, index: 0);
    final key = skir.ParameterKey(owner: dictionary, index: 0);
    final value = skir.ParameterKey(owner: dictionary, index: 1);
    final catalog = testCheckedCatalog(
      types: [
        _published(
          box,
          skir.RepresentationTemplate.createSequence(
            kind: skir.CollectionKind.list,
            item: skir.TypeTemplate.wrapParameter(boxItem),
          ),
          parameters: [boxItem],
        ),
        _published(
          dictionary,
          skir.RepresentationTemplate.createMapping(
            key: skir.TypeTemplate.wrapParameter(key),
            value: skir.TypeTemplate.wrapParameter(value),
          ),
          parameters: [key, value],
        ),
        _published(
          caption,
          skir.RepresentationTemplate.createScalar(kind: skir.ScalarKind.text),
        ),
      ],
    );
    final boxUse = skir.TypeUse.createNamed(
      definition: box,
      arguments: [_text],
    );
    final mapped = skir.ExpressionNode.createMap(
      source: inputExpression(_rows),
      body: localExpression(0),
    );
    expect(
      checkPortableExpression(
        mapped,
        catalog: catalog,
        bindings: {_rows: nominalType(boxUse)},
        expectedOutput: listType(nominalType(_text)),
      ),
      isEmpty,
    );
    final filtered = skir.ExpressionNode.createFilter(
      source: inputExpression(_rows),
      body: skir.ExpressionNode.wrapLiteral(skir.DataValue.wrapBoolean(true)),
    );
    expect(
      checkPortableExpression(
        filtered,
        catalog: catalog,
        bindings: {_rows: nominalType(boxUse)},
        expectedOutput: nominalType(boxUse),
      ),
      isEmpty,
    );
    expect(
      checkPortableExpression(
        filtered,
        catalog: catalog,
        bindings: {_rows: nominalType(boxUse)},
        expectedOutput: listType(nominalType(_text)),
      ),
      contains("incompatible_expression_result_type"),
    );
    final dictionaryUse = skir.TypeUse.createNamed(
      definition: dictionary,
      arguments: [_text, _i32],
    );
    final mappedValues = skir.ExpressionNode.createMap(
      source: inputExpression(_rows),
      body: skir.ExpressionNode.createEntryProjection(
        source: localExpression(0),
        branch: skir.EntryBranch.value,
      ),
    );
    expect(
      checkPortableExpression(
        mappedValues,
        catalog: catalog,
        bindings: {_rows: nominalType(dictionaryUse)},
        expectedOutput: listType(nominalType(_i32)),
      ),
      isEmpty,
    );
    final keyExpression = skir.ExpressionNode.wrapLiteral(
      skir.DataValue.wrapStringValue("item"),
    );
    final access = skir.ExpressionNode.createCollectionAccess(
      source: inputExpression(_rows),
      index: keyExpression,
    );
    expect(
      checkPortableExpression(
        access,
        catalog: catalog,
        bindings: {_rows: nominalType(dictionaryUse)},
        expectedOutput: nominalType(_i32, true),
      ),
      isEmpty,
    );
    final membership = skir.ExpressionNode.createCollectionContains(
      source: inputExpression(_rows),
      value: keyExpression,
    );
    expect(
      checkPortableExpression(
        membership,
        catalog: catalog,
        bindings: {_rows: nominalType(dictionaryUse)},
        expectedOutput: nominalType(
          skir.TypeUse.wrapScalar(skir.ScalarKind.boolean),
        ),
      ),
      isEmpty,
    );
    final dictionaryValue = skir.DataValue.createNamed(
      actualType: (dictionaryUse as skir.TypeUse_namedWrapper).value,
      payload: skir.DataValue.createMapValue(
        rows: [
          skir.MapRow(
            id: skir.ItemId(value: "row"),
            key: skir.DataValue.wrapStringValue("item"),
            value: skir.DataValue.wrapInteger("7"),
          ),
        ],
      ),
    );
    expect(
      (_evaluate(access, {
        _rows: dictionaryValue,
      }) as PortableExpressionAvailable).value.authoredInteger,
      BigInt.from(7),
    );
    expect(
      (_evaluate(membership, {
        _rows: dictionaryValue,
      }) as PortableExpressionAvailable).value,
      skir.DataValue.wrapBoolean(true),
    );
    final captionUse = skir.TypeUse.createNamed(
      definition: caption,
      arguments: const [],
    );
    final upper = skir.ExpressionNode.createMap(
      source: inputExpression(_rows),
      body: skir.ExpressionNode.createTextUnary(
        operation: skir.TextUnaryOperation.upper,
        source: localExpression(0),
      ),
    );
    expect(
      checkPortableExpression(
        upper,
        catalog: catalog,
        bindings: {_rows: listType(nominalType(captionUse))},
        expectedOutput: listType(nominalType(_text)),
      ),
      isEmpty,
    );
  });

  test("field projection of partial input resolves the selected field without a complete root", () {
    final root = _definition("PendingRecord");
    final key = skir.ParameterKey(owner: root, index: 0);
    final owner = skir.FieldOwner(definition: root, name: "title");
    final text = skir.TypeTemplate.wrapScalar(skir.ScalarKind.text);
    final field = skir.FieldDeclaration(
      owner: owner,
      type: text,
      overrides: const [],
      hasConstructorDefault: false,
    );
    final published = _published(
      root,
      skir.RepresentationTemplate.createRecord(
        abstract_: false,
        fields: [field],
      ),
      parameters: [key],
    );
    final catalog = testCheckedCatalog(
      types: [
        (published.toMutable()
              ..effectiveFields = [
                skir.EffectiveFieldTemplate(
                  key: "title",
                  owner: owner,
                  type: text,
                  rules: const [],
                ),
              ])
            .toFrozen(),
      ],
    );
    final selection = skir.TypeSelection.createPending(
      definition: root,
      arguments: [skir.ArgumentSelection.unfilled],
    );
    final expression = skir.ExpressionNode.createField(
      source: inputExpression(_rows),
      name: "title",
    );
    expect(
      checkPortableExpression(
        expression,
        catalog: catalog,
        bindings: const {},
        partialBindings: {_rows: selection},
        expectedOutput: nominalType(_text, true),
      ),
      isEmpty,
    );
    final value = skir.DataValue.createRecord(
      fields: [
        skir.FieldValue(
          name: "title",
          value: skir.DataValue.wrapStringValue("Selected"),
        ),
      ],
    );
    expect(
      (_evaluate(expression, {
        _rows: value,
      }) as PortableExpressionAvailable).value.authoredString,
      "Selected",
    );
  });

  test("invalid frame addresses and unknown operations fail admission and evaluation", () {
    expect(_check(localExpression(0)), ["invalid_expression_local"]);
    expect(
      (_evaluate(localExpression(0)) as PortableExpressionFailed).code,
      "invalid_expression_local",
    );
    final expression = skir.ExpressionNode.createNumberArithmetic(
      operation: skir.NumberArithmeticOperation.unknown,
      first: integerLiteral(1),
      second: integerLiteral(2),
      remaining: const [],
    );
    expect(_check(expression), ["unknown_expression_operation"]);
    expect(
      (_evaluate(expression) as PortableExpressionFailed).code,
      "unknown_expression_operation",
    );
    expect(_check(skir.ExpressionNode.unknown), ["unknown_expression"]);
  });

  test(
    "nested real map rows retain their cursor and authored entry witness",
    () {
      final outer = skir.ItemId(value: "outer");
      final inner = skir.ItemId(value: "inner");
      final data = skir.DataValue.createMapValue(
        rows: [
          skir.MapRow(
            id: outer,
            key: skir.DataValue.wrapStringValue("outer"),
            value: skir.DataValue.createMapValue(
              rows: [
                skir.MapRow(
                  id: inner,
                  key: skir.DataValue.wrapStringValue("inner"),
                  value: skir.DataValue.wrapStringValue("answer"),
                ),
              ],
            ),
          ),
        ],
      );
      final path = skir.ValuePath(
        segments: [
          skir.PathSegment.mapValue,
          skir.PathSegment.createItem(id: inner),
          skir.PathSegment.mapValue,
        ],
      );
      final expression = skir.ExpressionNode.createMap(
        source: inputExpression(_rows),
        body: skir.ExpressionNode.createLocal(depth: 0, slot: 0, path: path),
      );
      final type = mapType(
        nominalType(_text),
        mapType(nominalType(_text), nominalType(_text)),
      );
      expect(
        _check(
          expression,
          inputs: {_rows: type},
          expected: listType(nominalType(_text), true),
        ),
        isEmpty,
      );
      final origin = skir.ValueLocation(
        resource: skir.ResourceId(value: "resource"),
        path: editorRootPath.field("rows"),
      );
      final result = PortableExpressionEvaluator.located({
        _rows: PortableExpressionBinding(value: data, location: origin),
      }, budget: _budget).evaluate(expression) as PortableExpressionAvailable;
      final items =
          (result.value as skir.DataValue_listValueWrapper).value.items;
      expect(items.single.id, outer);
      expect(items.single.value.authoredString, "answer");
      expect(
        result.reads.any(
          (read) =>
              read.location ==
              skir.ValueLocation(
                resource: origin.resource,
                path: skir.ValuePath(
                  segments: [
                    ...origin.path.segments,
                    skir.PathSegment.createItem(id: outer),
                    ...path.segments,
                  ],
                ),
              ),
        ),
        isTrue,
      );
      final record = skir.DataValue.createRecord(
        fields: [
          skir.FieldValue(
            name: "key",
            value: skir.DataValue.wrapStringValue("ordinary"),
          ),
        ],
      );
      expect(
        (record.readExpressionAt(
          editorRootPath.field("key"),
        ) as PortablePathValue<skir.DataValue>).value.authoredString,
        "ordinary",
      );
    },
  );
}

skir.TypeDefinitionId _definition(String name) => skir.TypeDefinitionId(
  typeId: skir.TypeId.createQualified(
    namespace: "typed-expression-test",
    name: name,
  ),
  revision: 1,
);
skir.PublishedType _published(
  skir.TypeDefinitionId id,
  skir.RepresentationTemplate representation, {
  List<skir.ParameterKey> parameters = const [],
}) => skir.PublishedType(
  placementField: null,
  definition: skir.TypeDefinition(
    id: id,
    parameters: [
      for (final (index, key) in parameters.indexed)
        skir.TypeParameter(key: key, name: "T$index", bounds: const []),
    ],
    representation: representation,
    parents: const [],
  ),
  status: skir.DeclarationStatus.ready,
  display: null,
  effectiveFields: const [],
  ancestorTemplates: const [],
);
