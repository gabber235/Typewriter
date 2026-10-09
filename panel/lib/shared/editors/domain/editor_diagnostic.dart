import "package:flutter/foundation.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;

import "../application/portable_value_tree.dart";

enum EditorDiagnosticCode {
  invalidPath,
  invalidRevision,
  invalidValue,
  mutationConflict,
  permissionDenied,
}

enum EditorDiagnosticSeverity { information, warning, error }

final class EditorDiagnostic {
  const EditorDiagnostic({
    required this.code,
    required this.message,
    this.path,
    this.severity = EditorDiagnosticSeverity.error,
    this.details = const {},
  });

  final EditorDiagnosticCode code;
  final String message;
  final skir.ValuePath? path;
  final EditorDiagnosticSeverity severity;
  final Map<String, String> details;

  EditorDiagnostic at(skir.ValuePath prefix) => EditorDiagnostic(
    code: code,
    message: message,
    path: path == null ? prefix : prefix.followedBy(path!),
    severity: severity,
    details: details,
  );

  @override
  bool operator ==(Object other) =>
      other is EditorDiagnostic &&
      other.code == code &&
      other.message == message &&
      other.path == path &&
      other.severity == severity &&
      mapEquals(other.details, details);

  @override
  int get hashCode => Object.hash(code, message, path, severity, details);
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
