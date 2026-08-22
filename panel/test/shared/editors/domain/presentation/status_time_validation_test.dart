import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  const context = ExpressionContext(bindings: BindingEnvironment({}));

  test("validates status case types, uniqueness, and label types", () {
    final presentation = PresentationNode(
      id: "status",
      element: StatusElement(
        value: "active".asStringLiteral,
        cases: [
          const StatusCase(
            match: BooleanValue(true),
            appearance: StatusAppearance(tone: StatusTone.active),
          ),
          StatusCase(
            match: const StringValue("active"),
            appearance: StatusAppearance(
              tone: StatusTone.active,
              label: true.asBooleanLiteral,
            ),
          ),
          const StatusCase(
            match: StringValue("active"),
            appearance: StatusAppearance(tone: StatusTone.success),
          ),
        ],
      ),
    );

    final messages = presentation
        .validatePresentation(context, registry: null)
        .map((item) => item.message);
    expect(messages, contains(contains("not valid for StringType")));
    expect(messages, contains("Status cases must have unique values"));
    expect(messages, contains("Status label must declare a string result"));
  });

  test("accepts unmatched status values without a fallback", () {
    final presentation = PresentationNode(
      id: "status",
      element: StatusElement(
        value: "unknown".asStringLiteral,
        cases: const [
          StatusCase(
            match: StringValue("active"),
            appearance: StatusAppearance(tone: StatusTone.active),
          ),
        ],
      ),
    );

    expect(presentation.validatePresentation(context, registry: null), isEmpty);
  });

  test("validates date time and relative time expression types", () {
    final presentations = [
      PresentationNode(
        id: "dateTime",
        element: DateTimeElement(
          value: "not a timestamp".asStringLiteral,
          format: true.asBooleanLiteral,
        ),
      ),
      PresentationNode(
        id: "relativeTime",
        element: RelativeTimeElement(value: "invalid".asStringLiteral),
      ),
    ];

    final messages = presentations
        .expand((item) => item.validatePresentation(context, registry: null))
        .map((item) => item.message);
    expect(
      messages,
      contains("Date time value must declare a timestamp result"),
    );
    expect(messages, contains("Date time format must declare a string result"));
    expect(
      messages,
      contains("Relative time value must declare a timestamp result"),
    );
  });

  test("diagnoses malformed dynamic date time formats", () {
    final presentation = PresentationNode(
      id: "dateTime",
      element: DateTimeElement(
        value: TypedExpression(
          resultType: const TimestampType(),
          expression: LiteralExpression(TimestampValue(DateTime.utc(2026))),
        ),
        format: "'".asStringLiteral,
      ),
    );

    expect(
      presentation
          .validatePresentation(context, registry: null)
          .map((item) => item.message),
      contains("Date time format is malformed"),
    );
  });
}
