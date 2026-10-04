import "package:typewriter_panel/features/organizations/features/realms/application/authored_draft.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/type_catalog.dart"
    as types;
import "package:typewriter_panel/shared/editors/application/portable_value_tree.dart";

types.ValueLocation authoredFieldLocation(
  types.ResourceId resource,
  Iterable<String> fields,
) => types.ValueLocation(
  resource: resource,
  path: types.ValuePath(
    segments: [
      for (final field in fields) types.PathSegment.createField(name: field),
    ],
  ),
);

void setAuthoredFieldPayload({
  required AuthoredDraft draft,
  required types.ResourceId resource,
  required Iterable<String> fields,
  required types.DataValue payload,
}) {
  final result = draft.setPayload(
    authoredFieldLocation(resource, fields),
    payload,
  );
  if (result is PortablePathUnavailable<types.AuthoringRecord>) {
    throw StateError(result.message);
  }
}
