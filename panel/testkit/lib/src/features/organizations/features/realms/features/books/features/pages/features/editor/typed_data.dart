import "dart:typed_data";

import "package:faker/faker.dart";
import "package:iconify_flutter_plus/icons/fa6_solid.dart";
import "package:typewriter_panel/typewriter_panel.dart" hide random;

const defaultElementIcons = <String>[
  "fa-solid:star",
  "fa-solid:bookmark",
  "fa-solid:bolt",
  "fa-solid:dragon",
  "fa-solid:ghost",
  "fa-solid:scroll",
  "fa7-solid:magic-wand-sparkles",
  "fa-solid:gem",
  "fa-solid:heart",
  "fa-solid:chess-knight",
];

typedef GeneratedTypedData = ({TypeExpression type, DataValue value});

String generateRandomIconName() => Fa6Solid.iconsList.randomOrNull()!;

GeneratedTypedData generateRandomTypedData({int depth = 0, int maxDepth = 2}) {
  final terminal = depth >= maxDepth;
  final choices = terminal ? 8 : 11;
  return switch (faker.randomGenerator.integer(choices)) {
    0 => const (type: UnitType(), value: UnitValue()),
    1 => (
      type: const BooleanType(),
      value: BooleanValue(faker.randomGenerator.boolean()),
    ),
    2 => _stringData(),
    3 => _integerData(),
    4 => _decimalData(),
    5 => _bytesData(),
    6 => _timestampData(),
    7 => _enumData(),
    8 => _listData(depth + 1, maxDepth),
    9 => _mapData(depth + 1, maxDepth),
    10 => _recordData(depth + 1, maxDepth),
    _ => _recordData(depth + 1, maxDepth),
  };
}

({RecordType type, RecordValue value}) generateRandomRecordData({
  int depth = 0,
  int maxDepth = 2,
}) {
  final generated = _recordData(depth, maxDepth);
  return (
    type: generated.type as RecordType,
    value: generated.value as RecordValue,
  );
}

GeneratedTypedData _stringData() {
  final value = faker.lorem
      .words(faker.randomGenerator.integer(3, min: 1))
      .join(" ");
  return (
    type: StringType(minimumLength: 0, maximumLength: value.length + 12),
    value: StringValue(value),
  );
}

GeneratedTypedData _integerData() {
  final value = faker.randomGenerator.integer(1000, min: -100);
  return (
    type: IntegerType(
      width: IntegerWidth.signed32,
      minimum: BigInt.from(-100),
      maximum: BigInt.from(1000),
    ),
    value: IntegerValue(BigInt.from(value)),
  );
}

GeneratedTypedData _decimalData() {
  final value = faker.randomGenerator.decimal(scale: 100).toStringAsFixed(2);
  return (type: const DecimalType(scale: 2), value: DecimalValue(value));
}

GeneratedTypedData _bytesData() {
  final bytes = Uint8List.fromList(
    List.generate(4, (_) => faker.randomGenerator.integer(256)),
  );
  return (type: const BytesType(maximumLength: 16), value: BytesValue(bytes));
}

GeneratedTypedData _timestampData() {
  final value = DateTime.utc(
    2020 + faker.randomGenerator.integer(8),
    faker.randomGenerator.integer(12, min: 1),
    faker.randomGenerator.integer(28, min: 1),
  );
  return (type: const TimestampType(), value: TimestampValue(value));
}

GeneratedTypedData _enumData() {
  final value = StringValue(faker.lorem.word().toLowerCase());
  return (
    type: EnumType(valueType: const StringType(), values: [value]),
    value: value,
  );
}

GeneratedTypedData _listData(int depth, int maxDepth) {
  final values = List.generate(
    faker.randomGenerator.integer(4, min: 1),
    (_) => generateRandomTypedData(depth: depth, maxDepth: maxDepth),
  );
  final first = values.first;
  final matching = values
      .where((item) => typeExpressionsEqual(item.type, first.type))
      .map((item) => item.value)
      .toList();
  return (
    type: ListType(element: first.type, maximumLength: 6),
    value: ListValue(matching),
  );
}

GeneratedTypedData _mapData(int depth, int maxDepth) {
  final item = generateRandomTypedData(depth: depth, maxDepth: maxDepth);
  final key = faker.lorem.word().toLowerCase();
  return (
    type: MapType(key: const StringType(), value: item.type, maximumLength: 6),
    value: MapValue([DataMapEntry(key: StringValue(key), value: item.value)]),
  );
}

GeneratedTypedData _recordData(int depth, int maxDepth) {
  final fields = <String, TypeField>{};
  final values = <String, DataValue>{};
  final count = faker.randomGenerator.integer(5, min: 1);
  while (fields.length < count) {
    final name = fields.keys._randomName();
    final generated = generateRandomTypedData(depth: depth, maxDepth: maxDepth);
    fields[name] = TypeField(name: name, type: generated.type);
    values[name] = generated.value;
  }
  return (type: RecordType(fields: fields), value: RecordValue(values));
}

extension on Iterable<String> {
  String _randomName() {
    var candidate = "";
    do {
      candidate = faker.lorem
          .words(faker.randomGenerator.integer(3, min: 1))
          .join("_")
          .toLowerCase()
          .replaceAll(RegExp(r"[^a-z0-9_]+"), "_");
    } while (candidate.isEmpty || contains(candidate));
    return candidate;
  }
}
