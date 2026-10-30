import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/stories/authoring/presentation/realm_story.dart";
import "package:widgetbook_workspace/stories/authoring/search/presentation/compiled_search_fixture.dart";
import "package:widgetbook_workspace/support/story.dart";

/// The ways a resource result can stand in the Realm, by knob label.
enum _ResultState {
  ready("Ready"),
  removed("Removed"),
  missingTag("Missing tag"),
  ambiguous("Ambiguous presentation"),
  unavailable("Unavailable presentation");

  const _ResultState(this.label);
  final String label;
}

@widgetbook.UseCase(name: "Resource result", type: AuthoredResourceSearchResult)
Widget authoringSearchResultUseCase(BuildContext context) {
  final kind = context.knobs.object.dropdown(
    label: "Kind",
    options: const ["Book", "Tag", "Page", "Element"],
    initialOption: "Page",
  );
  final state = context.knobs.object.dropdown(
    label: "State",
    options: _ResultState.values,
    labelBuilder: (state) => state.label,
  );
  final origin = context.knobs.object.dropdown(
    label: "Opened from",
    options: const ["Anywhere", "The Book", "The Page"],
  );
  final bookTitle = context.knobs.string(
    label: "Book title",
    initialValue: "Main Quest",
  );
  final density = context.knobs.object.segmented(
    label: "Density",
    options: SearchResultDensity.values,
    initialOption: SearchResultDensity.card,
    labelBuilder: (density) => density.name,
  );
  final focused = context.knobs.boolean(label: "Focused");
  final width = context.knobs.double.slider(
    label: "Width",
    initialValue: 520,
    min: 240,
    max: 900,
  );
  final fixture = CompiledSearchFixture();
  final resource = state == _ResultState.removed
      ? skir.ResourceId(value: "rich:removed")
      : fixture.ids[kind.toLowerCase()]!;
  return Story(
    [
      signedIn(ada, organization: acme),
      realmServing(
        _resultDocument(fixture, resource, state, bookTitle: bookTitle),
      ),
    ],
    at: PanelLocation.component(
      SizedBox(
        width: width,
        child: RealmEditingScene(
          builder: (context, workspace, _) => _Result(
            document: workspace.document,
            resource: resource,
            origin: switch (origin) {
              "The Book" => fixture.ids["book"],
              "The Page" => fixture.ids["page"],
              _ => null,
            },
            density: density,
            focused: focused,
          ),
        ),
      ),
    ),
  );
}

@widgetbook.UseCase(name: "Creation result", type: AuthoredResourceSearchResult)
Widget authoringCreationResultUseCase(BuildContext context) {
  final unavailable = context.knobs.boolean(label: "Unavailable");
  final focused = context.knobs.boolean(label: "Focused");
  final document = CompiledSearchFixture().document;
  final page = document.entry(skir.ResourceId(value: "rich:page"))!;
  final configuration = page.content.configuration;
  final option = AuthoringCreationOption(
    type: configuration.definition!,
    configuration: configuration,
    label: document.catalog.typeSelectionName(configuration),
    display: document.catalog.selectionDisplay(configuration),
    disabledReason: unavailable ? "The Realm is read only" : null,
  );
  return Story(
    const [],
    at: PanelLocation.component(
      SizedBox(
        width: 520,
        child: _Selectable(
          focused: focused,
          builder: (row) => buildAuthoringCreationSearchResultItem(
            row(
              SearchResult(
                id: "create",
                type: authoringCreationSearchResultType,
                payload: option,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// The resource result as the search palette shows it: clicking selects it.
final class _Result extends StatelessWidget {
  const _Result({
    required this.document,
    required this.resource,
    required this.origin,
    required this.density,
    required this.focused,
  });

  final AuthoringDocument document;
  final skir.ResourceId resource;
  final skir.ResourceId? origin;
  final SearchResultDensity density;
  final bool focused;

  @override
  Widget build(BuildContext context) {
    return _Selectable(
      focused: focused,
      builder: (row) => AuthoredResourceSearchResult(
        document: document,
        issues: ResourceIssues.evaluate(document: document),
        hostContext: HostContext(activeResource: origin),
        resource: resource,
        row: row(
          SearchResult(
            id: resource.value,
            type: authoringResourceSearchResultType,
            payload: resource,
          ),
        ),
        role: skir.PresentationRole.resourceSearchResult,
        density: density,
        fallbackLabel: "Removed resource",
      ),
    );
  }
}

/// A search row that becomes selected when clicked, as in the palette.
final class _Selectable extends HookWidget {
  const _Selectable({required this.focused, required this.builder});

  final bool focused;
  final Widget Function(SearchResultRowContext Function(SearchResult) row)
  builder;

  @override
  Widget build(BuildContext context) {
    final selected = useState(false);
    return builder(
      (result) => SearchResultRowContext(
        result: result,
        selected: selected.value,
        focused: focused,
        loading: false,
        onTap: () => selected.value = true,
        shortcutActivator: focused
            ? const SingleActivator(LogicalKeyboardKey.enter)
            : null,
      ),
    );
  }
}

/// The fixture's linked resources with the Book titled [bookTitle], changed
/// so [resource] stands in [state].
AuthoringDocument _resultDocument(
  CompiledSearchFixture fixture,
  skir.ResourceId resource,
  _ResultState state, {
  required String bookTitle,
}) {
  final edit = AuthoringEdit.fromDocument(fixture.document)
    ..set(
      skir.ValueLocation(
        resource: fixture.ids["book"]!,
        path: skir.ValuePath(
          segments: [skir.PathSegment.createField(name: "title")],
        ),
      ),
      skir.DataValue.wrapStringValue(bookTitle),
    );
  final document = edit.toDocument();
  return switch (state) {
    _ResultState.ready || _ResultState.removed => document,
    _ResultState.missingTag => document.copyWith(
      entries: {...document.entries}..remove(fixture.ids["tag"]),
    ),
    _ResultState.ambiguous || _ResultState.unavailable => document.copyWith(
      catalog: CheckedEditorCatalog(
        _withSearchPresentation(document, resource, state),
      ),
    ),
  };
}

/// The catalog with the search result presentation of [resource] doubled by
/// a second, equally specific provider, or without its material.
skir.EditorCatalog _withSearchPresentation(
  AuthoringDocument document,
  skir.ResourceId resource,
  _ResultState state,
) {
  final selected = document.catalog.selectPresentation(
    document.resource(resource)!.configuration,
    skir.PresentationRole.resourceSearchResult,
  ) as SelectedEditorPresentation;
  final snapshot = document.catalog.snapshot.toMutable();
  if (state == _ResultState.unavailable) {
    snapshot.presentationMaterials = [
      for (final material in snapshot.presentationMaterials)
        if (material != selected.material) material,
    ];
  } else {
    snapshot.presentations = [
      ...snapshot.presentations,
      (selected.descriptor.toMutable()
            ..id = skir.PresentationId(
              namespace: "widgetbook",
              name: "rival_result",
            ))
          .toFrozen(),
    ];
  }
  return snapshot.toFrozen();
}
