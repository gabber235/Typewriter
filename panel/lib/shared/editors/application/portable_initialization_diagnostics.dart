import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;

String formatPortableInitializationDiagnostic(
  skir.InitializationDiagnostic finding,
) {
  final path = finding.relativePath;
  if (path == null || path.segments.isEmpty) return finding.message;
  final buffer = StringBuffer();
  for (final segment in path.segments) {
    switch (segment) {
      case skir.PathSegment_fieldWrapper(:final value):
        if (buffer.isNotEmpty) buffer.write(".");
        buffer.write(value.name);
      case skir.PathSegment_itemWrapper(:final value):
        buffer.write("[${value.id.value}]");
      case skir.PathSegment.mapKey:
        buffer.write(".key");
      case skir.PathSegment.mapValue:
        buffer.write(".value");
      case skir.PathSegment_unknown():
        buffer.write(".unknown");
    }
  }
  return "$buffer: ${finding.message}";
}
