import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

skir.ValueLocation authoredFieldLocation(
  skir.ResourceId resource,
  Iterable<String> fields,
) => skir.ValueLocation(
  resource: resource,
  path: skir.ValuePath(
    segments: [
      for (final field in fields) skir.PathSegment.createField(name: field),
    ],
  ),
);

void setAuthoredFieldPayload({
  required AuthoredDraft draft,
  required skir.ResourceId resource,
  required Iterable<String> fields,
  required skir.DataValue payload,
}) {
  final result = draft.setPayload(
    authoredFieldLocation(resource, fields),
    payload,
  );
  if (result is PortablePathUnavailable<skir.AuthoringRecord>) {
    throw StateError(result.message);
  }
}
