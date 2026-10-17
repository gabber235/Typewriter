part of "route.dart";

Future<void> createPage({
  required BuildContext context,
  required WidgetRef ref,
  String chapter = "",
}) async {
  final bookId = ref.read(bookIdProvider);
  if (bookId == null) throw ApiException.badRequest("No book selected");
  final organizationId = ref.read(organizationIdProvider);
  final realmId = ref.read(realmIdProvider);
  if (organizationId == null || realmId == null) {
    throw ApiException.badRequest("No Realm selected");
  }
  final draft = ref
      .read(
        workingAuthoringDocumentProvider(
          AuthoringScope(organizationId: organizationId, realmId: realmId),
        ),
      )
      .value;
  final checked = draft?.catalog;
  final template = checked.resourceCreationTemplate(
    corePageResourceDefinition.value,
  );
  if (checked == null || template == null || draft?.resource(bookId) == null) {
    throw ApiException.badRequest("Page creation is unavailable");
  }
  final chapterValue = checked.admitPortablePayloadAt(
    template.configuration,
    skir.ValuePath(segments: [skir.PathSegment.createField(name: "chapter")]),
    skir.DataValue.wrapStringValue(chapter),
  );
  final priorityValue = checked.admitPortablePayloadAt(
    template.configuration,
    skir.ValuePath(segments: [skir.PathSegment.createField(name: "priority")]),
    skir.DataValue.wrapInteger("0"),
  );
  if (chapterValue == null || priorityValue == null) {
    throw ApiException.badRequest("Page creation fields are unavailable");
  }
  await ref
      .read(
        resourceCreationProvider(
          AuthoringScope(organizationId: organizationId, realmId: realmId),
        ),
      )
      .createAndReveal(
        context: context,
        creationContext: CreationContext(
          constraints: [
            CreationReferenceConstraint(
              route: [libraryPageBookEndpoint],
              target: bookId,
            ),
          ],
        ),
        request: ResourceCreationRequest(
          definition: template.definition,
          configuration: template.configuration,
          supplied: [
            skir.FieldValue(name: "chapter", value: chapterValue),
            skir.FieldValue(name: "priority", value: priorityValue),
          ],
        ),
      );
}
