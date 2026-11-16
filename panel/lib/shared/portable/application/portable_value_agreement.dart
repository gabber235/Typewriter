import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// What the values of several selected items have in common, so one control
/// can edit them together.
extension PortableValueAgreement on List<skir.DataValue> {
  /// What these values agree on: the value when they are all equal; a record
  /// or a named value of one type made of what they agree on in each field;
  /// otherwise unfilled.
  skir.DataValue get agreement {
    final first = this.first;
    if (every((value) => value == first)) return first;
    if (first case skir.DataValue_namedWrapper(value: final named)) {
      final payloads = [
        for (final value in this)
          if (value case skir.DataValue_namedWrapper(:final value)
              when value.actualType == named.actualType)
            value.payload,
      ];
      if (payloads.length == length) {
        return skir.DataValue.createNamed(
          actualType: named.actualType,
          payload: payloads.agreement,
        );
      }
    }
    if (first case skir.DataValue_recordWrapper(value: final record)) {
      final names = [for (final field in record.fields) field.name];
      final records = [
        for (final value in this)
          if (value case skir.DataValue_recordWrapper(:final value)
              when listEquals([
                for (final field in value.fields) field.name,
              ], names))
            value,
      ];
      if (records.length == length) {
        return skir.DataValue.createRecord(
          fields: [
            for (final (index, name) in names.indexed)
              skir.FieldValue(
                name: name,
                value: [
                  for (final record in records)
                    record.fields.elementAt(index).value,
                ].agreement,
              ),
          ],
        );
      }
    }
    return skir.DataValue.unfilled;
  }
}
