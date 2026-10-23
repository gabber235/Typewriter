/// Hand written runtime of the generated portable operation catalog.
///
/// The generated `skirout/portable_operations.dart` declares one kernel
/// interface per operation group, the dispatch the evaluator's call rule uses,
/// and failure ids. This library supplies what they share: the call rule's
/// argument model, kernel capabilities, and conversions between `DataValue`
/// and kernel types. Decoders raise `ill_typed_argument` for a value of the
/// wrong kind, which only an unchecked tree reaches.
library;

import "package:typewriter_panel/infrastructure/protocols/operations/skirout/portable_operations.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;

export "package:typewriter_panel/infrastructure/protocols/operations/skirout/portable_operations.dart";
export "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    show ByteString;

/// Where an operation runs. Realm implements only [rule]; the panel both.
enum PortableProfile { rule, panel }

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
    required this.profile,
    required this.parameters,
    required this.variadic,
    required this.typeArguments,
  });

  final String id;
  final PortableProfile profile;
  final List<PortableParameterKind> parameters;

  /// Whether the last parameter repeats.
  final bool variadic;

  /// How many type arguments calls carry.
  final int typeArguments;

  /// Whether a call with [count] arguments fits the declared parameters.
  bool accepts(int count) => variadic
      ? count >= parameters.length - 1
      : count == parameters.length;

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
    final scale = fraction.length - exponent;
    return scale < 0
        ? PortableDecimal(magnitude * BigInt.from(10).pow(-scale), 0)
        : PortableDecimal(magnitude, scale).normalized();
  }

  final BigInt unscaled;
  final int scale;

  /// This value without trailing fraction zeros.
  PortableDecimal normalized() {
    var value = unscaled;
    var digits = scale;
    final ten = BigInt.from(10);
    while (digits > 0 && value != BigInt.zero && value % ten == BigInt.zero) {
      value ~/= ten;
      digits--;
    }
    return PortableDecimal(value, value == BigInt.zero ? 0 : digits);
  }

  /// This value at [digits] fraction digits; [digits] must not be smaller.
  BigInt unscaledAt(int digits) =>
      unscaled * BigInt.from(10).pow(digits - scale);

  @override
  int compareTo(PortableDecimal other) {
    final digits = scale > other.scale ? scale : other.scale;
    return unscaledAt(digits).compareTo(other.unscaledAt(digits));
  }

  @override
  bool operator ==(Object other) =>
      other is PortableDecimal && compareTo(other) == 0;

  @override
  int get hashCode => Object.hash(
    normalized().unscaled,
    normalized().scale,
  );

  /// Canonical plain notation without trailing fraction zeros.
  @override
  String toString() {
    final value = normalized();
    final negative = value.unscaled.isNegative;
    final digits = value.unscaled.abs().toString().padLeft(value.scale + 1, "0");
    final whole = digits.substring(0, digits.length - value.scale);
    final fraction = digits.substring(digits.length - value.scale);
    return "${negative ? "-" : ""}$whole${fraction.isEmpty ? "" : ".$fraction"}";
  }
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
    PortableValue(:final value) => PortableValue(convert(value)),
    PortableMissing(:final locations) => PortableMissing(locations),
  };
}

final class PortableValue<T> extends PortableMaybe<T> {
  const PortableValue(this.value);
  final T value;
}

final class PortableMissing<T> extends PortableMaybe<T> {
  const PortableMissing(this.locations);

  /// Authored locations whose missing values block the result.
  final List<skir.ValueLocation> locations;
}

/// A value together with the authored location it was read from.
final class Located<T> {
  const Located(this.value, this.location);

  final T value;
  final skir.ValueLocation? location;

  /// The location of collection item [id] below this value.
  skir.ValueLocation? item(skir.ItemId id) =>
      _below(location, [skir.PathSegment.wrapItem(skir.ItemPathSegment(id: id))]);

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
        path: skir.ValuePath(segments: [...location.path.segments, ...segments]),
      );

/// A step lambda the kernel drives with the accumulator and one source item.
typedef PortableStep =
    skir.DataValue Function(skir.DataValue accumulator, skir.ListItem item);

/// A comparator lambda over two source items: negative, zero or positive.
typedef PortableComparator =
    int Function(skir.ListItem left, skir.ListItem right);

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
abstract interface class PortableResources {}

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
    KernelEach(:final results) => [for (final result in results) decode(result)],
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
    return (left, right) => lambda
        .invoke([KernelLocal(left.value, left.id), KernelLocal(right.value, right.id)])
        .asInt32();
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
  const KernelContext({required this.meter, this.typeFacts, this.resourceAccess});

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

skir.DataValue linkValue(skir.LinkValue value) => skir.DataValue.wrapLink(value);

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
    skir.ListItem(id: skir.ItemId(value: "$index"), value: value),
];

/// A map entry as items and lambdas see it: a record of key and value.
skir.DataValue entryValue(skir.DataValue key, skir.DataValue value) =>
    recordValue({"key": key, "value": value});

/// The identity of an inner item below an outer item.
skir.ItemId nestedItemId(skir.ItemId outer, skir.ItemId inner) => skir.ItemId(
  value:
      "${outer.value.length}:${outer.value}${inner.value.length}:${inner.value}",
);
