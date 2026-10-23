/// Hand written runtime of the generated portable operation catalog.
///
/// The generated `skirout/portable_operations.dart` declares one kernel
/// interface per operation group, the dispatch the evaluator's call rule uses,
/// and failure ids. This library supplies what they share: the call rule's
/// argument model, kernel capabilities, and conversions between `DataValue`
/// and kernel types. Decoders raise `ill_typed_argument` for a value of the
/// wrong kind, which only an unchecked tree reaches.
library;

import "dart:math" as math;
import "dart:typed_data";

import "package:typewriter_panel/infrastructure/protocols/operations/skirout/portable_operations.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;

export "package:typewriter_panel/infrastructure/protocols/operations/skirout/portable_operations.dart";
export "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    show ByteString;

/// How the call rule passes one argument; see operations.yaml.
enum PortableParameterKind {
  /// Evaluated; unfilled entries make the call missing at their locations.
  value,

  /// Evaluated; may contain unfilled entries.
  partial,

  /// Evaluated with its location; may contain unfilled entries.
  located,

  /// A lambda evaluated for every item of the first argument.
  each,

  /// A lambda the kernel drives with an accumulator and an item.
  step,

  /// A lambda the kernel drives with two items.
  comparator,

  /// A lambda the kernel runs once with one value.
  apply,
}

/// The call shape of one declared operation, as the evaluator needs it.
final class PortableOperationDeclaration {
  const PortableOperationDeclaration({
    required this.id,
    required this.parameters,
    required this.variadic,
    required this.typeArguments,
  });

  final String id;
  final List<PortableParameterKind> parameters;

  /// Whether the last parameter repeats.
  final bool variadic;

  /// How many type arguments calls carry.
  final int typeArguments;

  /// Whether a call with [count] arguments fits the declared parameters.
  bool accepts(int count) =>
      variadic ? count >= parameters.length - 1 : count == parameters.length;

  /// The kind of the parameter argument [index] binds.
  PortableParameterKind? parameterAt(int index) => index < parameters.length
      ? parameters[index]
      : variadic && parameters.isNotEmpty
      ? parameters.last
      : null;
}

/// A declared failure raised by a kernel or the call rule.
final class PortableOperationFailure implements Exception {
  PortableOperationFailure(this.failure, [String? message])
    : message =
          message ?? PortableFailures.messages[failure.value] ?? failure.value;

  final skir.FailureId failure;
  final String message;

  @override
  String toString() => "PortableOperationFailure(${failure.value}: $message)";
}

/// A decimal number: [unscaled] times ten to the power of minus [scale].
///
/// Arithmetic is exact except [divide] and [sqrt], which round to a number of
/// significant digits half even, as Java's `MathContext.DECIMAL128` does for
/// 34. Results are normalized, so [toString] is the canonical text.
final class PortableDecimal implements Comparable<PortableDecimal> {
  const PortableDecimal(this.unscaled, this.scale);

  /// Parses plain or exponent notation, such as `-1.50` or `2.5e3`.
  factory PortableDecimal.parse(String source) {
    final match = RegExp(
      r"^([+-]?)([0-9]+)(?:\.([0-9]*))?(?:[eE]([+-]?[0-9]+))?$",
    ).firstMatch(source);
    final exponent = int.tryParse(match?.group(4) ?? "0");
    if (match == null || exponent == null) {
      throw FormatException("Not a decimal number", source);
    }
    final fraction = match.group(3) ?? "";
    var magnitude = BigInt.parse("${match.group(2)}$fraction");
    if (match.group(1) == "-") magnitude = -magnitude;
    return PortableDecimal._scaled(magnitude, fraction.length - exponent);
  }

  /// The integer [value].
  PortableDecimal.integer(BigInt value) : this(value, 0);

  /// The exact decimal value of the finite double [value], so `0.1` becomes
  /// `0.1000000000000000055511151231257827021181583404541015625`.
  factory PortableDecimal.fromDouble(double value) {
    if (!value.isFinite) {
      throw ArgumentError.value(value, "value", "Must be finite");
    }
    final bytes = ByteData(8)..setFloat64(0, value);
    final high = bytes.getUint32(0);
    final low = bytes.getUint32(4);
    final biased = (high >> 20) & 0x7ff;
    var mantissa = (BigInt.from(high & 0xfffff) << 32) | BigInt.from(low);
    var exponent = -1074;
    if (biased != 0) {
      mantissa |= BigInt.one << 52;
      exponent = biased - 1075;
    }
    if ((high >> 31) != 0) mantissa = -mantissa;
    return exponent >= 0
        ? PortableDecimal(mantissa << exponent, 0)
        : PortableDecimal(
            mantissa * BigInt.from(5).pow(-exponent),
            -exponent,
          ).normalized();
  }

  /// [unscaled] times ten to the power of minus [scale], for any [scale].
  factory PortableDecimal._scaled(BigInt unscaled, int scale) =>
      unscaled == BigInt.zero
      ? zero
      : scale < 0
      ? PortableDecimal(unscaled * _ten.pow(-scale), 0)
      : PortableDecimal(unscaled, scale).normalized();

  static final zero = PortableDecimal(BigInt.zero, 0);

  final BigInt unscaled;
  final int scale;

  bool get isZero => unscaled == BigInt.zero;

  bool get isNegative => unscaled.isNegative;

  /// This value without trailing fraction zeros.
  PortableDecimal normalized() {
    var value = unscaled;
    var digits = scale;
    while (digits > 0 && value != BigInt.zero && value % _ten == BigInt.zero) {
      value ~/= _ten;
      digits--;
    }
    return PortableDecimal(value, value == BigInt.zero ? 0 : digits);
  }

  /// This value at [digits] fraction digits; [digits] must not be smaller.
  BigInt unscaledAt(int digits) => unscaled * _ten.pow(digits - scale);

  /// The nearest double, by a correctly rounded parse of the canonical text.
  double toDouble() => double.parse(toString());

  PortableDecimal operator +(PortableDecimal other) {
    final digits = math.max(scale, other.scale);
    return PortableDecimal(
      unscaledAt(digits) + other.unscaledAt(digits),
      digits,
    ).normalized();
  }

  PortableDecimal operator -(PortableDecimal other) => this + (-other);

  PortableDecimal operator -() => PortableDecimal(-unscaled, scale);

  PortableDecimal operator *(PortableDecimal other) => PortableDecimal(
    unscaled * other.unscaled,
    scale + other.scale,
  ).normalized();

  /// The quotient rounded to [precision] significant digits, half even.
  /// [divisor] must not be zero.
  PortableDecimal divide(PortableDecimal divisor, {int precision = 34}) {
    if (divisor.isZero) throw ArgumentError.value(divisor, "divisor");
    if (isZero) return zero;
    final numerator = unscaled.abs() * _ten.pow(divisor.scale);
    final denominator = divisor.unscaled.abs() * _ten.pow(scale);
    var fraction =
        precision -
        (numerator.toString().length - denominator.toString().length);
    while (true) {
      final scaledNumerator = fraction >= 0
          ? numerator * _ten.pow(fraction)
          : numerator;
      final scaledDenominator = fraction >= 0
          ? denominator
          : denominator * _ten.pow(-fraction);
      var quotient = scaledNumerator ~/ scaledDenominator;
      if (quotient >= _ten.pow(precision)) {
        fraction--;
        continue;
      }
      final remainder = scaledNumerator - quotient * scaledDenominator;
      final doubled = remainder * BigInt.two;
      if (doubled > scaledDenominator ||
          (doubled == scaledDenominator && quotient.isOdd)) {
        quotient += BigInt.one;
      }
      final negative = unscaled.isNegative != divisor.unscaled.isNegative;
      return PortableDecimal._scaled(negative ? -quotient : quotient, fraction);
    }
  }

  /// The remainder of truncating division; it has the sign of this value.
  /// [divisor] must not be zero.
  PortableDecimal remainder(PortableDecimal divisor) {
    final digits = math.max(scale, divisor.scale);
    return PortableDecimal(
      unscaledAt(digits).remainder(divisor.unscaledAt(digits)),
      digits,
    ).normalized();
  }

  /// This value raised to the nonnegative [exponent], exactly.
  PortableDecimal power(int exponent) =>
      PortableDecimal(unscaled.pow(exponent), scale * exponent).normalized();

  /// The square root rounded to [precision] significant digits, half even.
  /// This value must not be negative.
  PortableDecimal sqrt({int precision = 34}) {
    if (isNegative) throw ArgumentError.value(this, "value");
    if (isZero) return zero;
    final integerDigits = unscaled.toString().length - scale;
    var fraction = precision + 2 - (integerDigits / 2).floor();
    while (true) {
      if (2 * fraction < scale) fraction = (scale + 1) ~/ 2;
      final radicand = unscaled * _ten.pow(2 * fraction - scale);
      final root = integerSquareRoot(radicand);
      final dropped = root.toString().length - precision;
      if (dropped <= 0) {
        if (root * root == radicand) {
          return PortableDecimal._scaled(root, fraction);
        }
        fraction += 1 - dropped;
        continue;
      }
      final unit = _ten.pow(dropped);
      var kept = root ~/ unit;
      final rest = root - kept * unit;
      final half = unit ~/ BigInt.two;
      final exact = root * root == radicand;
      if (rest > half || (rest == half && (!exact || kept.isOdd))) {
        kept += BigInt.one;
      }
      return PortableDecimal._scaled(kept, fraction - dropped);
    }
  }

  @override
  int compareTo(PortableDecimal other) {
    final digits = math.max(scale, other.scale);
    return unscaledAt(digits).compareTo(other.unscaledAt(digits));
  }

  @override
  bool operator ==(Object other) =>
      other is PortableDecimal && compareTo(other) == 0;

  @override
  int get hashCode => Object.hash(normalized().unscaled, normalized().scale);

  /// Canonical plain notation without trailing fraction zeros; zero is `0`.
  @override
  String toString() {
    final value = normalized();
    final negative = value.unscaled.isNegative;
    final digits = value.unscaled.abs().toString().padLeft(
      value.scale + 1,
      "0",
    );
    final whole = digits.substring(0, digits.length - value.scale);
    final fraction = digits.substring(digits.length - value.scale);
    return "${negative ? "-" : ""}$whole${fraction.isEmpty ? "" : ".$fraction"}";
  }
}

final _ten = BigInt.from(10);

/// The floor of the square root of the nonnegative [value].
BigInt integerSquareRoot(BigInt value) {
  if (value < BigInt.two) return value;
  var current = BigInt.one << ((value.bitLength + 1) >> 1);
  while (true) {
    final next = (current + value ~/ current) >> 1;
    if (next >= current) return current;
    current = next;
  }
}

/// Rounds the rational [numerator] / [denominator] to an integer by [mode].
/// [denominator] must be positive.
BigInt roundQuotient(BigInt numerator, BigInt denominator, RoundingMode mode) {
  final quotient = numerator ~/ denominator;
  final remainder = numerator - quotient * denominator;
  if (remainder == BigInt.zero) return quotient;
  final away = numerator.isNegative
      ? quotient - BigInt.one
      : quotient + BigInt.one;
  final doubled = remainder.abs() * BigInt.two;
  return switch (mode) {
    RoundingMode.towardZero => quotient,
    RoundingMode.floor => numerator.isNegative ? away : quotient,
    RoundingMode.ceiling => numerator.isNegative ? quotient : away,
    RoundingMode.nearestTiesAway => doubled >= denominator ? away : quotient,
    RoundingMode.nearestTiesToEven =>
      doubled > denominator || (doubled == denominator && quotient.isOdd)
          ? away
          : quotient,
  };
}

/// A number of one family, as numeric kernels receive and return it.
sealed class PortableNumber {
  const PortableNumber();
}

final class PortableInteger extends PortableNumber {
  const PortableInteger(this.value);
  final BigInt value;
}

/// Always finite.
final class PortableFloat extends PortableNumber {
  const PortableFloat(this.value);
  final double value;
}

final class PortableDecimalNumber extends PortableNumber {
  const PortableDecimalNumber(this.value);
  final PortableDecimal value;
}

/// A kernel result that may be missing data at the locations that block it.
sealed class PortableMaybe<T> {
  const PortableMaybe();

  /// This result with [convert] applied to a value.
  PortableMaybe<R> map<R>(R Function(T value) convert) => switch (this) {
    PortableMaybeValue(:final value) => PortableMaybeValue(convert(value)),
    PortableMaybeMissing(:final locations) => PortableMaybeMissing(locations),
  };
}

final class PortableMaybeValue<T> extends PortableMaybe<T> {
  const PortableMaybeValue(this.value);
  final T value;
}

final class PortableMaybeMissing<T> extends PortableMaybe<T> {
  const PortableMaybeMissing(this.locations);

  /// Authored locations whose missing values block the result.
  final List<skir.ValueLocation> locations;
}

/// A value together with the authored location it was read from.
final class Located<T> {
  const Located(this.value, this.location);

  final T value;
  final skir.ValueLocation? location;

  /// The location of collection item [id] below this value.
  skir.ValueLocation? item(skir.ItemId id) => _below(location, [
    skir.PathSegment.wrapItem(skir.ItemPathSegment(id: id)),
  ]);

  /// The location of the key of map row [id] below this value.
  skir.ValueLocation? mapKey(skir.ItemId id) => _below(location, [
    skir.PathSegment.wrapItem(skir.ItemPathSegment(id: id)),
    skir.PathSegment.mapKey,
  ]);

  /// The location of the value of map row [id] below this value.
  skir.ValueLocation? mapValue(skir.ItemId id) => _below(location, [
    skir.PathSegment.wrapItem(skir.ItemPathSegment(id: id)),
    skir.PathSegment.mapValue,
  ]);
}

skir.ValueLocation? _below(
  skir.ValueLocation? location,
  List<skir.PathSegment> segments,
) => location == null
    ? null
    : skir.ValueLocation(
        resource: location.resource,
        path: skir.ValuePath(
          segments: [...location.path.segments, ...segments],
        ),
      );

/// A step lambda the kernel drives with the accumulator and one source item.
typedef PortableStep = skir.DataValue Function(
  skir.DataValue accumulator,
  skir.ListItem item,
);

/// A comparator lambda over two source items: negative, zero or positive.
typedef PortableComparator = int Function(
  skir.ListItem left,
  skir.ListItem right,
);

/// A lambda the kernel runs once with one value.
typedef PortableApply = skir.DataValue Function(skir.DataValue value);

/// The budget for work that grows with an operation's input.
abstract interface class PortableMeter {
  void steps(int count);
  void items(int count);
}

/// The catalog's type facts that typed operations need.
abstract interface class PortableTypes {
  /// Whether [value]'s actual type is [type] or one of its descendants.
  bool isInstance(skir.DataValue value, skir.TypeUse type);

  /// The case names of the enumeration [type], in declaration order.
  List<String> enumCases(skir.TypeUse type);

  /// Whether the catalog admits [value] as a value of [type].
  bool admits(skir.DataValue value, skir.TypeUse type);
}

/// Authored resource access for panel profile operations. Every resource the
/// kernels read through it becomes a read of the evaluation.
abstract interface class PortableResources {
  /// The authored record of resource [id], or null when the observation has
  /// no such resource. Records a read of the resource either way.
  skir.AuthoringRecord? resource(skir.ResourceId id);

  /// Whether a resource configured as [configuration] is a value of [type].
  /// A pending configuration matches when its chosen arguments allow [type].
  bool selects(skir.TypeSelection configuration, skir.TypeUse type);

  /// Whether a resource configured as [configuration] belongs to the family
  /// the opposite endpoint of [link]'s relation names, so the link still
  /// targets the kind of resource it was authored for.
  bool linkTargets(skir.LinkValue link, skir.TypeSelection configuration);

  /// The published declaration of [definition], or null when the catalog
  /// lacks it.
  skir.PublishedType? declaration(skir.TypeDefinitionId definition);
}

/// One argument as the call rule hands it to the generated dispatch.
sealed class KernelArgument {
  const KernelArgument();

  /// The evaluated value of a value, partial or located argument.
  skir.DataValue get value => switch (this) {
    KernelValue(:final value) => value,
    _ => throw _illTyped("Expected an evaluated argument."),
  };

  /// The value with its location, decoded by [decode].
  Located<T> located<T>(T Function(skir.DataValue value) decode) =>
      switch (this) {
        KernelValue(:final value, :final location) => Located(
          decode(value),
          location,
        ),
        _ => throw _illTyped("Expected an evaluated argument."),
      };

  /// The each lambda's results in item order, decoded by [decode].
  List<T> each<T>(T Function(skir.DataValue value) decode) => switch (this) {
    KernelEach(:final results) => [
      for (final result in results) decode(result),
    ],
    _ => throw _illTyped("Expected an each lambda."),
  };

  PortableStep get step {
    final lambda = _lambda;
    return (accumulator, item) => lambda.invoke([
      KernelLocal(accumulator),
      KernelLocal(item.value, item.id),
    ]);
  }

  PortableComparator get comparator {
    final lambda = _lambda;
    return (left, right) => lambda.invoke([
      KernelLocal(left.value, left.id),
      KernelLocal(right.value, right.id),
    ]).asInt32();
  }

  PortableApply get apply {
    final lambda = _lambda;
    return (value) => lambda.invoke([KernelLocal(value)]);
  }

  KernelLambda get _lambda => switch (this) {
    final KernelLambda lambda => lambda,
    _ => throw _illTyped("Expected a lambda."),
  };
}

final class KernelValue extends KernelArgument {
  const KernelValue(this.value, this.location);

  @override
  final skir.DataValue value;
  final skir.ValueLocation? location;
}

final class KernelEach extends KernelArgument {
  const KernelEach(this.results);
  final List<skir.DataValue> results;
}

/// A lambda the kernel drives. A local with an item id is an item of the first
/// argument, so it keeps that item's location. Missing or failed bodies abort
/// the whole call.
final class KernelLambda extends KernelArgument {
  const KernelLambda(this.invoke);
  final skir.DataValue Function(List<KernelLocal> locals) invoke;
}

final class KernelLocal {
  const KernelLocal(this.value, [this.item]);
  final skir.DataValue value;
  final skir.ItemId? item;
}

/// The capabilities a kernel may use besides its arguments.
final class KernelContext {
  const KernelContext({
    required this.meter,
    this.typeFacts,
    this.resourceAccess,
  });

  final PortableMeter meter;
  final PortableTypes? typeFacts;
  final PortableResources? resourceAccess;

  PortableTypes get types =>
      typeFacts ??
      (throw PortableOperationFailure(
        PortableFailures.outsideRuleProfile,
        "This host has no catalog type facts.",
      ));

  PortableResources get resources =>
      resourceAccess ??
      (throw PortableOperationFailure(
        PortableFailures.outsideRuleProfile,
        "This host has no authored resources.",
      ));
}

PortableOperationFailure _illTyped(String message) =>
    PortableOperationFailure(PortableFailures.illTypedArgument, message);

/// Decoders from `DataValue` to kernel types.
extension PortableKernelValues on skir.DataValue {
  skir.DataValue get _structural {
    var current = this;
    while (current is skir.DataValue_namedWrapper) {
      current = current.value.payload;
    }
    return current;
  }

  String asText() => switch (_structural) {
    skir.DataValue_stringValueWrapper(:final value) => value,
    _ => throw _illTyped("Expected text."),
  };

  bool asBoolean() => switch (_structural) {
    skir.DataValue_booleanWrapper(:final value) => value,
    _ => throw _illTyped("Expected a boolean."),
  };

  BigInt asInteger() => switch (_structural) {
    skir.DataValue_integerWrapper(:final value) => BigInt.parse(value),
    _ => throw _illTyped("Expected an integer."),
  };

  /// An integer of an int32 parameter; outside 32 bits raises
  /// integer_out_of_range.
  int asInt32() {
    final value = asInteger();
    if (value.bitLength > 31) {
      throw PortableOperationFailure(
        PortableFailures.integerOutOfRange,
        "The integer $value is outside 32 bits.",
      );
    }
    return value.toInt();
  }

  double asFloat() => switch (_structural) {
    skir.DataValue_floatWrapper(:final value) => value,
    _ => throw _illTyped("Expected a float."),
  };

  PortableDecimal asDecimal() => switch (_structural) {
    skir.DataValue_decimalWrapper(:final value) => PortableDecimal.parse(value),
    _ => throw _illTyped("Expected a decimal."),
  };

  skir.ByteString asBytes() => switch (_structural) {
    skir.DataValue_bytesWrapper(:final value) => value,
    _ => throw _illTyped("Expected bytes."),
  };

  Duration asDuration() => switch (_structural) {
    skir.DataValue_durationWrapper(:final value) => Duration(
      milliseconds: value.value.milliseconds,
    ),
    _ => throw _illTyped("Expected a duration."),
  };

  DateTime asTimestamp() => switch (_structural) {
    skir.DataValue_timestampWrapper(:final value) => value.toUtc(),
    _ => throw _illTyped("Expected a timestamp."),
  };

  /// A resource identity: the named ResourceId value over its text payload.
  skir.ResourceId asResourceId() => skir.ResourceId(value: asText());

  skir.LinkValue asLink() => switch (_structural) {
    skir.DataValue_linkWrapper(:final value) => value,
    _ => throw _illTyped("Expected a link."),
  };

  String asEnumCase() => switch (_structural) {
    skir.DataValue_enumCaseWrapper(:final value) => value,
    _ => throw _illTyped("Expected an enum case."),
  };

  PortableNumber asNumber() => switch (_structural) {
    skir.DataValue_integerWrapper(:final value) => PortableInteger(
      BigInt.parse(value),
    ),
    skir.DataValue_floatWrapper(:final value) => PortableFloat(value),
    skir.DataValue_decimalWrapper(:final value) => PortableDecimalNumber(
      PortableDecimal.parse(value),
    ),
    _ => throw _illTyped("Expected a number."),
  };

  /// The items of a list or set, or a map's entries as records of key and
  /// value with the row identities.
  List<skir.ListItem> asItems() => switch (_structural) {
    skir.DataValue_listValueWrapper(:final value) => value.items.toList(),
    skir.DataValue_setValueWrapper(:final value) => value.items.toList(),
    skir.DataValue_mapValueWrapper(:final value) => [
      for (final row in value.rows)
        skir.ListItem(id: row.id, value: entryValue(row.key, row.value)),
    ],
    _ => throw _illTyped("Expected a collection."),
  };

  List<skir.MapRow> asRows() => switch (_structural) {
    skir.DataValue_mapValueWrapper(:final value) => value.rows.toList(),
    _ => throw _illTyped("Expected a map."),
  };

  /// The fields of a record by name.
  Map<String, skir.DataValue> asRecordFields() => switch (_structural) {
    skir.DataValue_recordWrapper(:final value) => {
      for (final field in value.fields) field.name: field.value,
    },
    _ => throw _illTyped("Expected a record."),
  };

  T? asNullable<T>(T Function(skir.DataValue value) decode) =>
      _structural == skir.DataValue.null_ ? null : decode(this);
}

skir.DataValue textValue(String value) => skir.DataValue.wrapStringValue(value);

skir.DataValue booleanValue(bool value) => skir.DataValue.wrapBoolean(value);

skir.DataValue integerValue(BigInt value) =>
    skir.DataValue.wrapInteger(value.toString());

skir.DataValue int32Value(int value) =>
    skir.DataValue.wrapInteger(value.toString());

/// A finite float; kernels raise non_finite_number instead of returning one.
skir.DataValue floatValue(double value) {
  if (!value.isFinite) {
    throw StateError("Kernels raise non_finite_number instead of $value.");
  }
  return skir.DataValue.wrapFloat(value);
}

skir.DataValue decimalValue(PortableDecimal value) =>
    skir.DataValue.wrapDecimal(value.toString());

skir.DataValue bytesValue(skir.ByteString value) =>
    skir.DataValue.wrapBytes(value);

skir.DataValue durationValue(Duration value) => skir.DataValue.wrapDuration(
  skir.DurationValue(value: skir.Duration(milliseconds: value.inMilliseconds)),
);

skir.DataValue timestampValue(DateTime value) =>
    skir.DataValue.wrapTimestamp(value.toUtc());

skir.DataValue resourceIdValue(skir.ResourceId value) =>
    skir.DataValue.wrapNamed(
      skir.NamedValue(
        actualType: resourceIdType,
        payload: skir.DataValue.wrapStringValue(value.value),
      ),
    );

/// The catalog type of resource identities, the framework's Kotlin ResourceId.
final resourceIdType = skir.NamedTypeUse(
  definition: skir.TypeDefinitionId(
    typeId: skir.TypeId.createQualified(
      namespace: "kotlin",
      name: "com.typewritermc.types.ResourceId",
    ),
    revision: 1,
  ),
  arguments: const [],
);

skir.DataValue numberValue(PortableNumber value) => switch (value) {
  PortableInteger(:final value) => integerValue(value),
  PortableFloat(:final value) => floatValue(value),
  PortableDecimalNumber(:final value) => decimalValue(value),
};

skir.DataValue nullableValue<T>(
  T? value,
  skir.DataValue Function(T value) encode,
) => value == null ? skir.DataValue.null_ : encode(value);

skir.DataValue itemsList(List<skir.ListItem> items) =>
    skir.DataValue.createListValue(items: items);

skir.DataValue itemsSet(List<skir.ListItem> items) =>
    skir.DataValue.createSetValue(items: items);

skir.DataValue rowsMap(List<skir.MapRow> rows) =>
    skir.DataValue.createMapValue(rows: rows);

/// A record with its fields in name order.
skir.DataValue recordValue(Map<String, skir.DataValue> fields) =>
    skir.DataValue.createRecord(
      fields: [
        for (final name in fields.keys.toList()..sort())
          skir.FieldValue(name: name, value: fields[name]!),
      ],
    );

/// A list of computed values whose items are named by position.
skir.DataValue positionalList(List<skir.DataValue> values) =>
    itemsList(positionalItems(values));

/// Items named by position: 0, 1, 2, ...
List<skir.ListItem> positionalItems(List<skir.DataValue> values) => [
  for (final (index, value) in values.indexed)
    skir.ListItem(
      id: skir.ItemId(value: "$index"),
      value: value,
    ),
];

/// A map entry as items and lambdas see it: a record of key and value.
skir.DataValue entryValue(skir.DataValue key, skir.DataValue value) =>
    recordValue({"key": key, "value": value});

/// The identity of an inner item below an outer item.
skir.ItemId nestedItemId(skir.ItemId outer, skir.ItemId inner) => skir.ItemId(
  value:
      "${outer.value.length}:${outer.value}${inner.value.length}:${inner.value}",
);
