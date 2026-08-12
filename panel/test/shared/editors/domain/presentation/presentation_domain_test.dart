import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  group("default presentation", () {
    test("generates dedicated controls for structural types", () {
      final cases = <TypeExpression, Matcher>{
        const UnitType(): isA<EnumInputElement>(),
        const BooleanType(): isA<ToggleInputElement>(),
        const StringType(): isA<TextInputElement>(),
        const BytesType(): isA<BytesInputElement>(),
        const IntegerType(width: IntegerWidth.signed32):
            isA<NumericInputElement>(),
        const FloatType(width: FloatWidth.float64): isA<NumericInputElement>(),
        const DecimalType(): isA<NumericInputElement>(),
        const TimestampType(): isA<DateTimeInputElement>(),
        const DurationType(): isA<DurationInputElement>(),
        EnumType(
          valueType: const StringType(),
          values: const [StringValue("fixed")],
        ): isA<EnumInputElement>(),
        const ListType(element: StringType()): isA<ListInputElement>(),
        const MapType(key: StringType(), value: BooleanType()):
            isA<MapInputElement>(),
        RecordType(fields: const {}): isA<RecordInputElement>(),
      };

      for (final entry in cases.entries) {
        expect(entry.key.generateDefaultPresentation().element, entry.value);
      }
    });

    test("makes the builtin string control multiline", () {
      final element = (const StringType())
          .generateDefaultPresentation()
          .element;

      expect(element, isA<TextInputElement>());
      expect((element as TextInputElement).multiline, isTrue);
    });

    test("localizes unresolved parameters", () {
      expect(
        (const AnyType()).generateDefaultPresentation().element,
        isA<DiagnosticElement>(),
      );
      expect(
        (const ParameterType("T")).generateDefaultPresentation().element,
        isA<DiagnosticElement>(),
      );
    });

    test("provides dedicated semantic color and icon presentations", () {
      final definitions = {
        for (final definition in builtinPresentationDefinitions())
          definition.id: definition.root.element,
      };

      expect(
        definitions[standardColorPresentationId],
        isA<ColorInputElement>(),
      );
      expect(
        definitions[standardIconifyPresentationId],
        isA<IconInputElement>(),
      );
      expect(
        definitions[standardSvgIconPresentationId],
        isA<IconInputElement>(),
      );
    });
  });

  group("expressions", () {
    test("reads structured bindings and field access", () {
      final context = _context(
        RecordType(
          fields: const {"title": TypeField(name: "title", type: StringType())},
        ),
        RecordValue(const {"title": StringValue("Quest")}),
      );
      final expression = TypedExpression(
        resultType: const StringType(),
        expression: FieldAccessExpression(
          target: const TypedExpression(
            resultType: AnyType(),
            expression: BindingExpression(_rootBinding),
          ),
          fieldName: "title",
        ),
      );

      expect(
        expression.evaluate(context, registry: null).valueOrNull,
        const StringValue("Quest"),
      );
    });

    test("stops when the depth budget is exhausted", () {
      const literal = TypedExpression(
        resultType: BooleanType(),
        expression: LiteralExpression(BooleanValue(true)),
      );
      final expression = TypedExpression(
        resultType: const BooleanType(),
        expression: BooleanExpression(
          operator: BooleanOperator.and,
          operands: const [literal, literal],
        ),
      );

      final result = expression.evaluate(
        _context(const BooleanType(), const BooleanValue(true)),
        registry: null,
        budget: const ExpressionBudget(maximumDepth: 1),
      );

      expect(result, isA<TypeFailure<DataValue>>());
    });
  });

  group("local actions", () {
    test("executes a typed edit", () {
      final result =
          LocalEditorAction(
            SetValueAction(
              target: _rootBinding,
              value: "after".asStringLiteral,
            ),
          ).execute(
            _context(
              const StringType(),
              const StringValue("before"),
              revision: 4,
            ),
            registry: null,
          );

      expect(result, isA<MutationSuccess>());
      expect((result as MutationSuccess).value, const StringValue("after"));
    });

    test("captures the current revision when invoked", () {
      final result =
          LocalEditorAction(
            SetValueAction(
              target: _rootBinding,
              value: "after".asStringLiteral,
            ),
          ).execute(
            _context(
              const StringType(),
              const StringValue("before"),
              revision: 4,
            ),
            registry: null,
          );

      expect(result, isA<MutationSuccess>());
      expect((result as MutationSuccess).revision, 5);
    });
  });

  test("replaces only an invalid presentation sibling", () {
    final context = _context(
      RecordType(
        fields: const {"title": TypeField(name: "title", type: StringType())},
      ),
      RecordValue(const {"title": StringValue("Quest")}),
    );
    final binding = BindingReference(
      bindingId: const BindingId(0),
      path: DataPath.root.field("title"),
    );
    final localized = PresentationNode(
      id: "root",
      element: ColumnElement(
        children: [
          PresentationNode(
            id: "valid",
            element: TextInputElement(control: BoundControl(binding: binding)),
          ),
          PresentationNode(
            id: "invalid",
            element: NumericInputElement(BoundControl(binding: binding)),
          ),
        ],
      ),
    ).localizeFailures(context, registry: null);
    final children = (localized.element as ColumnElement).children;

    expect(children.first.element, isA<TextInputElement>());
    expect(children.last.element, isA<DiagnosticElement>());
  });
}

const _rootBinding = BindingReference(bindingId: BindingId(0));

ExpressionContext _context(
  TypeExpression type,
  DataValue value, {
  int revision = 0,
}) => ExpressionContext(
  bindings: BindingEnvironment({
    const BindingId(0): BindingSnapshot(
      type: type,
      value: value,
      revision: revision,
    ),
  }),
);
