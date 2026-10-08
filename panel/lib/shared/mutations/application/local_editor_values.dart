import "package:typewriter_panel/typewriter_panel.dart";

part "local_editor_values.freezed.dart";

/// Projects the paths edited in one resource onto a newer canonical value.
///
/// The value is a local snapshot, while [editedPaths] is the authority for
/// which parts may replace canonical content. Unedited canonical paths remain
/// untouched, allowing route projections to combine server observations with
/// local draft state without copying the complete document.
@freezed
abstract class LocalEditorValue with _$LocalEditorValue {
  const factory LocalEditorValue({
    required DataValue value,
    required Set<DataPath> editedPaths,
  }) = _LocalEditorValue;

  const LocalEditorValue._();

  /// Returns [canonical] with only the locally edited paths replaced.
  ///
  /// A path that cannot be read or replaced is ignored. This keeps a stale
  /// local projection from hiding otherwise valid canonical content.
  DataValue projectOnto(DataValue canonical) {
    var projected = canonical;
    for (final path in editedPaths) {
      final local = path.read(value).valueOrNull;
      if (local == null) continue;
      projected = path.replace(projected, local).valueOrNull ?? projected;
    }
    return projected;
  }
}
