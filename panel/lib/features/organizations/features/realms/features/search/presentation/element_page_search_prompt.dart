import "package:flutter/widgets.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Opens a nested search and returns the selected compatible page choice.
Future<ElementPageSelection?> promptElementPageSelection({
  required BuildContext context,
  required skir.ResourceId? initialBookId,
  required ElementDefinition elementDefinition,
}) async {
  return showSearchModal<ElementPageSelection>(
    context,
    (ref, promptContext) {
      final organizationId = ref.read(organizationIdProvider);
      final realmId = ref.read(realmIdProvider);
      if (organizationId == null || realmId == null) {
        throw ApiException.badRequest("No realm selected");
      }
      final books = ref.valued(projectedBooksProvider);
      final compatibleFields = ref.valued(
        compatiblePageElementsFieldsProvider(elementDefinition.rootType),
      );
      final initialBook = initialBookId == null
          ? null
          : ref.read(projectedBookProvider(initialBookId)).value;
      final realmSource = RealmAuthoringSearchSource(
        ref: ref,
        organizationId: organizationId,
        realmId: realmId,
      );
      return SearchContribution(
        session: SearchSession(
          source: [
            realmSource.inSection(id: "compatible_pages", title: "Choose Page"),
            PageTypeSearchSource(
              definitions: ref.valued(realmPageDefinitionsProvider),
            ),
          ].merged(),
          scope: elementDestinationScope(
            books: books,
            compatibleFields: compatibleFields,
          ),
          interaction: SearchInteraction(
            activation: elementDestinationActivation(
              ref: ref,
              books: books,
              compatibleFields: compatibleFields,
            ),
            selectionMode: SearchSelectionMode.single,
          ),
          initialQuery: authoringBookInitialQuery(
            initialBook,
            realmSource.selectors,
          ),
        ),
      );
    },
    searchHint: "Choose or create a compatible page",
    rowRenderers: {
      authoringResourceSearchResultType.rowRendererId: (context) =>
          AuthoringSearchResultItem(
            payload: context.result.payload as AuthoringSearchResultPayload,
            focused: context.focused,
            selected: context.selected,
            loading: context.loading,
            onTap: context.onTap,
            shortcutActivator: context.shortcutActivator,
          ),
      pageTypeSearchResultType.rowRendererId: (context) =>
          PageTypeSearchResultItem(
            definition: context.result.payload as RealmPageDefinition,
            focused: context.focused,
            selected: context.selected,
            loading: context.loading,
            onTap: context.onTap,
            shortcutActivator: context.shortcutActivator,
          ),
    },
  );
}
