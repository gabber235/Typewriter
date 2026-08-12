import "package:typewriter_panel/infrastructure/protocols/skir/editor_codec_support.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/editor_value_codec.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/type_catalog.dart"
    as wire;
import "package:typewriter_panel/shared/editors/domain/types/type_diagnostic.dart";
import "package:typewriter_panel/shared/editors/domain/values/data_value.dart";

final class SkirDataValueCollectionCodec {
  const SkirDataValueCollectionCodec(this.codec);

  final SkirDataValueCodec codec;

  TypeResult<wire.TypedValue> encodeList(List<DataValue> values) =>
      _encodeMany(values).mapValue(wire.TypedValue.wrapList);

  TypeResult<wire.TypedValue> encodeMap(List<DataMapEntry> entries) {
    final values = <wire.TypedMapEntry>[];
    final diagnostics = <TypeDiagnostic>[];
    for (final entry in entries) {
      final key = codec.encode(entry.key);
      final item = codec.encode(entry.value);
      diagnostics.addAll([...key.diagnostics, ...item.diagnostics]);
      if (key.valueOrNull case final encodedKey?) {
        if (item.valueOrNull case final encodedValue?) {
          values.add(wire.TypedMapEntry(key: encodedKey, value: encodedValue));
        }
      }
    }
    if (diagnostics.isNotEmpty) return TypeResult.failure(diagnostics);
    return TypeResult.success(wire.TypedValue.createMap(entries: values));
  }

  TypeResult<wire.TypedValue> encodeRecord(Map<String, DataValue> fields) {
    final values = <wire.TypedRecordField>[];
    final diagnostics = <TypeDiagnostic>[];
    for (final entry in fields.entries) {
      if (entry.key.isEmpty) {
        diagnostics.add(wireDiagnostic("Record field name is empty"));
        continue;
      }
      final result = codec.encode(entry.value);
      diagnostics.addAll(result.diagnostics);
      if (result.valueOrNull case final encoded?) {
        values.add(wire.TypedRecordField(name: entry.key, value: encoded));
      }
    }
    if (diagnostics.isNotEmpty) return TypeResult.failure(diagnostics);
    return TypeResult.success(wire.TypedValue.createRecord(fields: values));
  }

  TypeResult<DataValue> decodeList(Iterable<wire.TypedValue> values) =>
      _decodeMany(values).mapValue(ListValue.new);

  TypeResult<DataValue> decodeMap(Iterable<wire.TypedMapEntry> entries) {
    final values = <DataMapEntry>[];
    final diagnostics = <TypeDiagnostic>[];
    for (final entry in entries) {
      final key = codec.decode(entry.key);
      final item = codec.decode(entry.value);
      diagnostics.addAll([...key.diagnostics, ...item.diagnostics]);
      if (key.valueOrNull case final decodedKey?) {
        if (item.valueOrNull case final decodedValue?) {
          values.add(DataMapEntry(key: decodedKey, value: decodedValue));
        }
      }
    }
    if (diagnostics.isNotEmpty) return TypeResult.failure(diagnostics);
    return TypeResult.success(MapValue(values));
  }

  TypeResult<DataValue> decodeRecord(Iterable<wire.TypedRecordField> fields) {
    final values = <String, DataValue>{};
    final diagnostics = <TypeDiagnostic>[];
    for (final field in fields) {
      if (field.name.isEmpty || values.containsKey(field.name)) {
        diagnostics.add(
          wireDiagnostic("Record field name is empty or duplicate"),
        );
        continue;
      }
      final result = codec.decode(field.value);
      diagnostics.addAll(result.diagnostics);
      if (result.valueOrNull case final decoded?) values[field.name] = decoded;
    }
    if (diagnostics.isNotEmpty) return TypeResult.failure(diagnostics);
    return TypeResult.success(RecordValue(values));
  }

  TypeResult<List<wire.TypedValue>> _encodeMany(Iterable<DataValue> values) {
    final encoded = <wire.TypedValue>[];
    final diagnostics = <TypeDiagnostic>[];
    for (final value in values) {
      final result = codec.encode(value);
      diagnostics.addAll(result.diagnostics);
      if (result.valueOrNull case final item?) encoded.add(item);
    }
    return diagnostics.isEmpty
        ? TypeResult.success(encoded)
        : TypeResult.failure(diagnostics);
  }

  TypeResult<List<DataValue>> _decodeMany(Iterable<wire.TypedValue> values) {
    final decoded = <DataValue>[];
    final diagnostics = <TypeDiagnostic>[];
    for (final value in values) {
      final result = codec.decode(value);
      diagnostics.addAll(result.diagnostics);
      if (result.valueOrNull case final item?) decoded.add(item);
    }
    return diagnostics.isEmpty
        ? TypeResult.success(decoded)
        : TypeResult.failure(diagnostics);
  }
}
