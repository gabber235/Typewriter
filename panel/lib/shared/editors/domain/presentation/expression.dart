import "package:freezed_annotation/freezed_annotation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "expression.freezed.dart";

enum ComparisonOperator {
  equal,
  notEqual,
  lessThan,
  lessThanOrEqual,
  greaterThan,
  greaterThanOrEqual,
}

enum BooleanOperator { and, or, not }

enum ArithmeticOperator { add, subtract, multiply, divide, remainder, negate }

enum StringOperation {
  trim,
  lowerCase,
  upperCase,
  titleCase,
  replace,
  split,
  join,
  substring,
  contains,
  startsWith,
  endsWith,
}

enum CollectionOperation { access, length, contains }

enum RegexOperation { matches, capture, replace }

@freezed
abstract class TypedExpression with _$TypedExpression {
  const factory TypedExpression({
    required TypeExpression resultType,
    required Expression expression,
  }) = _TypedExpression;
}

@freezed
sealed class Expression with _$Expression {
  const factory Expression.literal(DataValue value) = LiteralExpression;
  const factory Expression.binding(BindingReference binding) =
      BindingExpression;

  @Assert("fieldName != \"\"", "Field name must not be empty.")
  const factory Expression.fieldAccess({
    required TypedExpression target,
    required String fieldName,
  }) = FieldAccessExpression;

  const factory Expression.interpolation(List<InterpolationPart> parts) =
      InterpolationExpression;

  const factory Expression.comparison({
    required ComparisonOperator operator,
    required TypedExpression left,
    required TypedExpression right,
  }) = ComparisonExpression;

  const factory Expression.boolean({
    required BooleanOperator operator,
    required List<TypedExpression> operands,
  }) = BooleanExpression;

  const factory Expression.arithmetic({
    required ArithmeticOperator operator,
    required List<TypedExpression> operands,
  }) = ArithmeticExpression;

  const factory Expression.conditional({
    required TypedExpression condition,
    required TypedExpression whenTrue,
    required TypedExpression whenFalse,
  }) = ConditionalExpression;

  const factory Expression.collectionProjection({
    required TypedExpression source,
    required BindingId itemBindingId,
    required TypedExpression projection,
  }) = CollectionProjectionExpression;

  const factory Expression.conversion({
    required ConversionId conversionId,
    required TypedExpression input,
  }) = ConversionExpression;

  const factory Expression.stringOperation({
    required StringOperation operation,
    required List<TypedExpression> operands,
  }) = StringOperationExpression;

  const factory Expression.collectionOperation({
    required CollectionOperation operation,
    required List<TypedExpression> operands,
  }) = CollectionOperationExpression;

  const factory Expression.regex({
    required RegexOperation operation,
    required TypedExpression source,
    required String pattern,
    int? group,
    String? replacement,
  }) = RegexExpression;

  const factory Expression.coalesce(List<TypedExpression> operands) =
      CoalesceExpression;
}

@freezed
sealed class InterpolationPart with _$InterpolationPart {
  const factory InterpolationPart.text(String value) = InterpolationText;
  const factory InterpolationPart.value(TypedExpression value) =
      InterpolationValue;
}

@freezed
abstract class ExpressionBudget with _$ExpressionBudget {
  @Assert("maximumDepth > 0", "Maximum depth must be positive.")
  @Assert("maximumNodes > 0", "Maximum node count must be positive.")
  @Assert("maximumEvaluations > 0", "Maximum evaluations must be positive.")
  const factory ExpressionBudget({
    @Default(32) int maximumDepth,
    @Default(512) int maximumNodes,
    @Default(4096) int maximumEvaluations,
  }) = _ExpressionBudget;
}

extension StringExpressionLiteral on String {
  TypedExpression get asStringLiteral =>
      StringValue(this).asLiteral(const StringType());

  TypedExpression get asIconLiteral => IconValue.from(this).asIconLiteral;
}

extension IntegerExpressionLiteral on int {
  TypedExpression get asSigned64Literal => IntegerValue(
    BigInt.from(this),
  ).asLiteral(const IntegerType(width: IntegerWidth.signed64));

  TypedExpression get asIntegerLiteral => asSigned64Literal;
}

extension FloatExpressionLiteral on num {
  TypedExpression get asFloatLiteral => FloatValue(
    toDouble(),
  ).asLiteral(const FloatType(width: FloatWidth.float64));
}

extension BooleanExpressionLiteral on bool {
  TypedExpression get asBooleanLiteral =>
      BooleanValue(this).asLiteral(const BooleanType());
}

extension IconExpressionLiteral on IconValue {
  TypedExpression get asIconLiteral =>
      typedValue.asLiteral(NamedType(standardTypeRefs.icon));
}

extension DataValueExpressionLiteral on DataValue {
  TypedExpression asLiteral(TypeExpression resultType) => TypedExpression(
    resultType: resultType,
    expression: LiteralExpression(this),
  );
}
