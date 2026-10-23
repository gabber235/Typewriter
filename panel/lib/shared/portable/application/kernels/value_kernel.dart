import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// The panel's operations on values of any type.
final class PanelValueKernel implements skir.ValueKernel {
  const PanelValueKernel();

  @override
  skir.DataValue cast(
    skir.DataValue value,
    skir.TypeUse xType,
    skir.PortableTypes types,
  ) => types.isInstance(value, xType) ? value : skir.DataValue.null_;

  @override
  int compare(skir.DataValue first, skir.DataValue second) =>
      portableCompare(first, second);

  @override
  skir.PortableMaybe<skir.DataValue> configuration(skir.DataValue value) =>
      switch (value) {
        skir.DataValue_namedWrapper(:final value) => skir.PortableMaybeValue(
          typeSelectionReadValue(
            skir.TypeSelection.wrapComplete(value.actualType),
          ),
        ),
        _ => const skir.PortableMaybeMissing([]),
      };

  @override
  bool equals(skir.DataValue first, skir.DataValue second) =>
      portableEquals(first, second);

  /// Accepts readable or dense JSON. The decoded value must already be
  /// portable and canonical, as literal admission defines it (canonical
  /// integers, unique fields in name order, finite floats, canonical
  /// decimals, nonblank item ids), else `invalid_json`; and it must be
  /// admitted as [xType], else `incompatible_value`.
  @override
  skir.DataValue fromJson(
    String json,
    skir.TypeUse xType,
    skir.PortableTypes types,
  ) {
    final skir.DataValue decoded;
    try {
      decoded = skir.DataValue.serializer.fromJson(jsonDecode(json));
    } on Object catch (error) {
      if (error is! FormatException &&
          error is! ArgumentError &&
          error is! TypeError &&
          error is! StateError) {
        rethrow;
      }
      throw skir.PortableOperationFailure(
        skir.PortableFailures.invalidJson,
        "The text is not value JSON: $error",
      );
    }
    final value = admitPortableValue(
      decoded,
      skir.PortableFailures.invalidJson,
    );
    if (!identical(value, decoded)) {
      throw skir.PortableOperationFailure(
        skir.PortableFailures.invalidJson,
        "The value JSON is not canonical.",
      );
    }
    if (!types.admits(value, xType)) {
      throw skir.PortableOperationFailure(
        skir.PortableFailures.incompatibleValue,
      );
    }
    return value;
  }

  @override
  bool instanceOf(
    skir.DataValue value,
    skir.TypeUse xType,
    skir.PortableTypes types,
  ) => types.isInstance(value, xType);

  @override
  bool isNull(skir.DataValue value) =>
      value.authoredPayload == skir.DataValue.null_;

  @override
  skir.DataValue let(skir.DataValue value, skir.PortableApply body) =>
      body(value);

  @override
  String toJson(skir.DataValue value) => portableJsonText(value);

  @override
  String toText(skir.DataValue value) => portableText(value);

  @override
  skir.DataValue unwrap(skir.DataValue value) => switch (value) {
    skir.DataValue_namedWrapper(:final value) => value.payload,
    _ => throw skir.PortableOperationFailure(
      skir.PortableFailures.illTypedArgument,
      "Expected a named value.",
    ),
  };

  @override
  skir.DataValue wrap(skir.DataValue payload, skir.TypeUse xType) =>
      switch (xType) {
        skir.TypeUse_namedWrapper(:final value) => skir.DataValue.createNamed(
          actualType: value,
          payload: payload,
        ),
        _ => throw skir.PortableOperationFailure(
          skir.PortableFailures.illTypedArgument,
          "Only a named type wraps a representation.",
        ),
      };
}

/// Structural equality of portable values: collection item identities are
/// ignored, floats compare by bits, decimals by value, and named values by
/// type and payload, exactly as Kotlin's `canonicalValueKey`.
bool portableEquals(skir.DataValue first, skir.DataValue second) =>
    canonicalAuthoredValue(first) == canonicalAuthoredValue(second);

/// The portable order of two values after unwrapping named wrappers: text by
/// code point, numbers by value within one family, false before true, and
/// timestamps and durations chronologically. Returns -1, 0 or 1.
int portableCompare(skir.DataValue first, skir.DataValue second) {
  final result = switch ((first.authoredPayload, second.authoredPayload)) {
    (
      skir.DataValue_stringValueWrapper(value: final left),
      skir.DataValue_stringValueWrapper(value: final right),
    ) =>
      _compareCodePoints(left, right),
    (
      skir.DataValue_integerWrapper(value: final left),
      skir.DataValue_integerWrapper(value: final right),
    ) =>
      BigInt.parse(left).compareTo(BigInt.parse(right)),
    (
      skir.DataValue_decimalWrapper(value: final left),
      skir.DataValue_decimalWrapper(value: final right),
    ) =>
      skir.PortableDecimal.parse(left)
          .compareTo(skir.PortableDecimal.parse(right)),
    (
      skir.DataValue_floatWrapper(value: final left),
      skir.DataValue_floatWrapper(value: final right),
    ) =>
      left < right
          ? -1
          : left > right
          ? 1
          : 0,
    (
      skir.DataValue_booleanWrapper(value: final left),
      skir.DataValue_booleanWrapper(value: final right),
    ) =>
      left == right
          ? 0
          : left
          ? 1
          : -1,
    (
      skir.DataValue_timestampWrapper(value: final left),
      skir.DataValue_timestampWrapper(value: final right),
    ) =>
      left.millisecondsSinceEpoch.compareTo(right.millisecondsSinceEpoch),
    (
      skir.DataValue_durationWrapper(value: final left),
      skir.DataValue_durationWrapper(value: final right),
    ) =>
      left.value.milliseconds.compareTo(right.value.milliseconds),
    _ => throw skir.PortableOperationFailure(
      skir.PortableFailures.illTypedArgument,
      "The values have no common portable order.",
    ),
  };
  return result.sign;
}

int _compareCodePoints(String left, String right) {
  final first = left.runes.iterator;
  final second = right.runes.iterator;
  while (true) {
    final hasFirst = first.moveNext();
    final hasSecond = second.moveNext();
    if (!hasFirst || !hasSecond) {
      return hasFirst == hasSecond
          ? 0
          : hasFirst
          ? 1
          : -1;
    }
    final comparison = first.current.compareTo(second.current);
    if (comparison != 0) return comparison;
  }
}

/// The canonical text of a value, as `value.to_text` defines it.
String portableText(skir.DataValue value) {
  final payload = value.authoredPayload;
  if (payload == skir.DataValue.null_) return "null";
  if (payload == skir.DataValue.unit) return "unit";
  return switch (payload) {
    skir.DataValue_integerWrapper(:final value) => BigInt.parse(
      value,
    ).toString(),
    skir.DataValue_decimalWrapper(:final value) => skir.PortableDecimal.parse(
      value,
    ).toString(),
    skir.DataValue_floatWrapper(:final value) => portableFloatText(value),
    skir.DataValue_booleanWrapper(:final value) => "$value",
    skir.DataValue_stringValueWrapper(:final value) => value,
    skir.DataValue_timestampWrapper(:final value) => portableTimestampText(
      value,
    ),
    skir.DataValue_durationWrapper(:final value) => portableDurationText(
      Duration(milliseconds: value.value.milliseconds),
    ),
    skir.DataValue_enumCaseWrapper(:final value) => value,
    _ => portableJsonText(payload),
  };
}

/// The Skir readable JSON of [value] without insignificant white space.
String portableJsonText(skir.DataValue value) =>
    jsonEncode(skir.DataValue.serializer.toJson(value, readableFlavor: true));

/// [value] as ECMAScript's Number::toString prints it: the shortest digits
/// that read back as [value], in plain notation for magnitudes from 1e-6
/// below 1e21 and as `d.ddde+21` otherwise. Negative zero prints `0`.
String portableFloatText(double value) {
  if (value == 0) return "0";
  final exponential = value.abs().toStringAsExponential();
  final marker = exponential.indexOf("e");
  final digits = exponential.substring(0, marker).replaceFirst(".", "");
  final exponent = int.parse(exponential.substring(marker + 1));
  final sign = value < 0 ? "-" : "";
  final count = digits.length;
  final point = exponent + 1;
  if (count <= point && point <= 21) {
    return "$sign$digits${"0" * (point - count)}";
  }
  if (0 < point && point <= 21) {
    return "$sign${digits.substring(0, point)}.${digits.substring(point)}";
  }
  if (-6 < point && point <= 0) return "${sign}0.${"0" * -point}$digits";
  final mantissa = count == 1
      ? digits
      : "${digits.substring(0, 1)}.${digits.substring(1)}";
  return "$sign${mantissa}e${exponent < 0 ? "-" : "+"}${exponent.abs()}";
}

/// The read model value of a type selection.
skir.DataValue typeSelectionReadValue(skir.TypeSelection selection) =>
    canonicalReadModels.project(
      selection,
      skir.TypeSelection.serializer.typeDescriptor,
      const [],
      () {},
      (_) {},
    );
