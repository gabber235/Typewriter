part of "route.dart";

Future<Page?> createPage({
  required BuildContext context,
  required WidgetRef ref,
  String chapter = "",
  bool navigate = true,
}) async {
  final bookId = ref.read(bookIdProvider);
  if (bookId == null) throw ApiException.badRequest("No book selected");
  final organizationId = ref.read(organizationIdProvider);
  final realmId = ref.read(realmIdProvider);
  if (organizationId == null || realmId == null) {
    throw ApiException.badRequest("No Realm selected");
  }
  final state = ref.read(authoringSessionProvider(organizationId, realmId));
  final checked = state.catalog;
  final draft = state.draft;
  final template = resourceCreationTemplate(
    checked,
    corePageResourceDefinition.value,
  );
  final book = draft?.resource(bookId);
  final binding = book == null
      ? null
      : checked
            ?.endpointBindings(book.configuration)
            .where(
              (candidate) =>
                  _isDirectPagesCollection(candidate.template.relativePath),
            )
            .singleOrNull;
  if (checked == null || template == null || binding == null) {
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
  final item = skir.ItemId(value: "panel:${uuid.v4()}");
  final created = await ref
      .read(resourceCreationProvider)
      .create(
        context: context,
        request: ResourceCreationRequest(
          definition: template.definition,
          configuration: template.configuration,
          supplied: [
            skir.FieldValue(name: "chapter", value: chapterValue),
            skir.FieldValue(name: "priority", value: priorityValue),
          ],
          connections: [
            ResourceCreationConnection.collection(
              source: bookId,
              endpoint: binding.template.endpoint,
              containing: skir.ValuePath(
                segments: [skir.PathSegment.createField(name: "pages")],
              ),
              item: item,
            ),
          ],
        ),
      );
  if (created == null) return null;
  final page = Page.fromAuthoring(
    skir.AuthoringResource(
      id: created.id,
      definition: created.definition,
      content: created.content,
    ),
  );
  if (navigate && context.mounted) {
    unawaited(
      ref.read(appRouterProvider).push(RouteRoute(pageId: page.pageId.id)),
    );
  }
  return page;
}

bool _isDirectPagesCollection(skir.RelativeFieldPattern pattern) {
  final segments = pattern.segments.toList();
  if (segments.length != 2 || segments[1] != skir.FieldPatternSegment.items) {
    return false;
  }
  return switch (segments.first) {
    skir.FieldPatternSegment_fieldWrapper(:final value) =>
      value.name == "pages",
    _ => false,
  };
}
