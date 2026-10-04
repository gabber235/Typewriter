import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/diagnostic.dart"
    as diagnostic;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/type_catalog.dart"
    as types;

String formatPortableInitializationDiagnostic(
  diagnostic.InitializationDiagnostic finding,
) {
  final path = finding.relativePath;
  if (path == null || path.segments.isEmpty) return finding.message;
  final buffer = StringBuffer();
  for (final segment in path.segments) {
    switch (segment) {
      case types.PathSegment_fieldWrapper(:final value):
        if (buffer.isNotEmpty) buffer.write(".");
        buffer.write(value.name);
      case types.PathSegment_itemWrapper(:final value):
        buffer.write("[${value.id.value}]");
      case types.PathSegment.mapKey:
        buffer.write(".key");
      case types.PathSegment.mapValue:
        buffer.write(".value");
      case types.PathSegment_unknown():
        buffer.write(".unknown");
    }
  }
  return "$buffer: ${finding.message}";
}
