import "package:flutter/widgets.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Opens a nested search and returns the selected compatible page choice.
Future<ElementPageSelection?> promptElementPageSelection({
  required BuildContext context,
  required skir.RecordId? initialBookId,
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
      final compatibleKinds = ref.valued(
        compatiblePageEntryKindsProvider(elementDefinition.rootType),
      );
      final initialBook = initialBookId == null
          ? null
          : ref.read(projectedBookProvider(initialBookId)).value;
      return SearchContribution(
        session: SearchSession(
          source: [
            RealmAuthoringSearchSource(
              ref: ref,
              organizationId: organizationId,
              realmId: realmId,
            ).inSection(id: "compatible_pages", title: "Choose Page"),
            PageKindSearchSource(
              definitions: ref.valued(realmPageDefinitionsProvider),
            ),
          ].merged(),
          scope: elementDestinationScope(
            books: books,
            compatibleKinds: compatibleKinds,
          ),
          interaction: SearchInteraction(
            activation: elementDestinationActivation(
              books: books,
              compatibleKinds: compatibleKinds,
            ),
            selectionMode: SearchSelectionMode.single,
          ),
          initialQuery: authoringBookInitialQuery(initialBook),
        ),
      );
    },
    searchHint: "Choose or create a compatible page",
    rowRenderers: {
      authoringPageSearchResultType.id: (context) =>
          AuthoringPageSearchResultItem(
            page: context.result.payload as skir.AuthoringSearchPage,
            focused: context.focused,
            selected: context.selected,
            loading: context.loading,
            onTap: context.onTap,
            shortcutActivator: context.shortcutActivator,
          ),
      pageKindSearchResultType.id: (context) => PageKindSearchResultItem(
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
