part of "editor_expression_encoder.dart";

extension on ComparisonOperator {
  wire.ComparisonOperator get _encodeWire => switch (this) {
    ComparisonOperator.equal => wire.ComparisonOperator.equal,
    ComparisonOperator.notEqual => wire.ComparisonOperator.notEqual,
    ComparisonOperator.lessThan => wire.ComparisonOperator.lessThan,
    ComparisonOperator.lessThanOrEqual =>
      wire.ComparisonOperator.lessThanOrEqual,
    ComparisonOperator.greaterThan => wire.ComparisonOperator.greaterThan,
    ComparisonOperator.greaterThanOrEqual =>
      wire.ComparisonOperator.greaterThanOrEqual,
  };
}

extension on BooleanOperator {
  wire.BooleanOperator get _encodeWire => switch (this) {
    BooleanOperator.and => wire.BooleanOperator.and,
    BooleanOperator.or => wire.BooleanOperator.or,
    BooleanOperator.not => wire.BooleanOperator.not,
  };
}

extension on ArithmeticOperator {
  wire.ArithmeticOperator get _encodeWire => switch (this) {
    ArithmeticOperator.add => wire.ArithmeticOperator.add,
    ArithmeticOperator.subtract => wire.ArithmeticOperator.subtract,
    ArithmeticOperator.multiply => wire.ArithmeticOperator.multiply,
    ArithmeticOperator.divide => wire.ArithmeticOperator.divide,
    ArithmeticOperator.remainder => wire.ArithmeticOperator.remainder,
    ArithmeticOperator.negate => wire.ArithmeticOperator.negate,
  };
}

extension on StringOperation {
  wire.StringOperation get _encodeWire => switch (this) {
    StringOperation.trim => wire.StringOperation.trim,
    StringOperation.lowerCase => wire.StringOperation.lowerCase,
    StringOperation.upperCase => wire.StringOperation.upperCase,
    StringOperation.titleCase => wire.StringOperation.titleCase,
    StringOperation.replace => wire.StringOperation.replace,
    StringOperation.split => wire.StringOperation.split,
    StringOperation.join => wire.StringOperation.join,
    StringOperation.substring => wire.StringOperation.substring,
    StringOperation.contains => wire.StringOperation.contains,
    StringOperation.startsWith => wire.StringOperation.startsWith,
    StringOperation.endsWith => wire.StringOperation.endsWith,
  };
}

extension on CollectionOperation {
  wire.CollectionOperation get _encodeWire => switch (this) {
    CollectionOperation.access => wire.CollectionOperation.access,
    CollectionOperation.length => wire.CollectionOperation.length,
    CollectionOperation.contains => wire.CollectionOperation.contains,
  };
}

extension on RegexOperation {
  wire.RegexOperation get _encodeWire => switch (this) {
    RegexOperation.matches => wire.RegexOperation.matches,
    RegexOperation.capture => wire.RegexOperation.capture,
    RegexOperation.replace => wire.RegexOperation.replace,
  };
}
