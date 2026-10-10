import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "editor_diagnostic.freezed.dart";

enum EditorDiagnosticCode {
  invalidPath,
  invalidRevision,
  invalidValue,
  mutationConflict,
  permissionDenied,
}

enum EditorDiagnosticSeverity { information, warning, error }

@freezed
abstract class EditorDiagnostic with _$EditorDiagnostic {
  const factory EditorDiagnostic({
    required EditorDiagnosticCode code,
    required String message,
    skir.ValuePath? path,
    @Default(EditorDiagnosticSeverity.error) EditorDiagnosticSeverity severity,
    @Default({}) Map<String, String> details,
  }) = _EditorDiagnostic;
  const EditorDiagnostic._();

  EditorDiagnostic at(skir.ValuePath prefix) =>
      copyWith(path: path == null ? prefix : prefix.followedBy(path!));
}

extension EditorValuePathOperations on skir.ValuePath {
  /// Renders a stable path for diagnostic reports without protocol serialization.
  String get diagnosticLabel =>
      r"$" +
      segments
          .map(
            (segment) => switch (segment) {
              skir.PathSegment_fieldWrapper(:final value) => ".${value.name}",
              skir.PathSegment_itemWrapper(:final value) =>
                "[${value.id.value}]",
              final value when value == skir.PathSegment.mapKey => "[key]",
              final value when value == skir.PathSegment.mapValue => "[value]",
              _ => "[?]",
            },
          )
          .join();

  skir.ValuePath field(String name) => skir.ValuePath(
    segments: [
      ...segments,
      skir.PathSegment.createField(name: name),
    ],
  );

  skir.ValuePath followedBy(skir.ValuePath suffix) =>
      skir.ValuePath(segments: [...segments, ...suffix.segments]);

  bool isAtOrBelow(skir.ValuePath ancestor) {
    if (segments.length < ancestor.segments.length) return false;
    for (var index = 0; index < ancestor.segments.length; index++) {
      if (segments.elementAt(index) != ancestor.segments.elementAt(index)) {
        return false;
      }
    }
    return true;
  }
}

extension EditorCanonicalValueOperations on skir.DataValue {
  skir.DataValue? editorValueAt(skir.ValuePath path) => switch (readAt(path)) {
    PortablePathValue(:final value) => value,
    PortablePathUnavailable() => null,
  };

  skir.DataValue? replacingEditorValue(
    skir.ValuePath path,
    skir.DataValue replacement,
  ) => switch (replaceAt(path, replacement)) {
    PortablePathValue(:final value) => value,
    PortablePathUnavailable() => null,
  };
}

skir.ValuePath get editorRootPath => skir.ValuePath(segments: const []);
