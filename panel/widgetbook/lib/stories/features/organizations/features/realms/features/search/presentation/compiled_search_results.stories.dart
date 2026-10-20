import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/stories/features/organizations/features/realms/features/search/presentation/compiled_search_fixture.dart";

@widgetbook.UseCase(
  name: "Compiled live resources",
  type: AuthoredResourceSearchResult,
)
Widget compiledLiveResourcesUseCase(BuildContext context) =>
    const CompiledLiveResourceResults();

/// A small local workspace. Every displayed resource uses its actual SDK recipe.
final class CompiledLiveResourceResults extends HookWidget {
  const CompiledLiveResourceResults({super.key});

  @override
  Widget build(BuildContext context) {
    final fixture = useMemoized(CompiledSearchFixture.new);
    final document = useState(fixture.document);
    final selected = useState<String?>("page");
    final origin = useState("all");
    final bookTitle = useTextEditingController(text: fixture.labels["book"]);
    final tagName = useTextEditingController(text: fixture.labels["tag"]);
    final pageName = useTextEditingController(text: fixture.labels["page"]);
    final issues = useMemoized(
      () => ResourceIssues.evaluate(document: document.value),
      [document.value],
    );
    void rename(String kind, String field, String value) {
      final edit = AuthoringEdit.fromDocument(document.value)
        ..set(
          skir.ValueLocation(
            resource: fixture.ids[kind]!,
            path: skir.ValuePath(
              segments: [skir.PathSegment.createField(name: field)],
            ),
          ),
          skir.DataValue.wrapStringValue(value),
        );
      document.value = edit.toDocument(revision: document.value.revision + 1);
    }

    final presentationContext = libraryOriginBindings(
      fixture.ids[origin.value],
    );
    final page = document.value.entry(fixture.ids["page"]!)!;
    final creation = AuthoringCreationOption(
      type: page.content.configuration.definition!,
      configuration: page.content.configuration,
      label: document.value.catalog.typeSelectionName(
        page.content.configuration,
      ),
      display: document.value.catalog.selectionDisplay(
        page.content.configuration,
      ),
    );
    SearchResultRowContext row(
      String kind,
      Object payload,
      SearchResultType type,
    ) => SearchResultRowContext(
      result: SearchResult(id: kind, type: type, payload: payload),
      selected: selected.value == kind,
      focused: selected.value == kind,
      loading: false,
      onTap: () => selected.value = kind,
    );
    Widget field(
      String label,
      TextEditingController controller,
      ValueChanged<String> onChanged,
    ) => SizedBox(
      width: 270,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(labelText: label),
      ),
    );
    return FakeApp(
      child: Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 940),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 12,
                children: [
                  const Text(
                    "Live resource search",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                  ),
                  const Text(
                    "Rename a linked resource. Its search rows update together.",
                  ),
                  Wrap(
                    spacing: 16,
                    runSpacing: 12,
                    children: [
                      field(
                        "Book title",
                        bookTitle,
                        (value) => rename("book", "title", value),
                      ),
                      field(
                        "Tag name",
                        tagName,
                        (value) => rename("tag", "name", value),
                      ),
                      field(
                        "Page name",
                        pageName,
                        (value) => rename("page", "name", value),
                      ),
                    ],
                  ),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: "all", label: Text("Full location")),
                      ButtonSegment(
                        value: "book",
                        label: Text("From this Book"),
                      ),
                      ButtonSegment(
                        value: "page",
                        label: Text("From this Page"),
                      ),
                    ],
                    selected: {origin.value},
                    onSelectionChanged: (value) => origin.value = value.single,
                  ),
                  for (final kind in ["book", "tag", "page", "element"])
                    AuthoredResourceSearchResult(
                      document: document.value,
                      issues: issues,
                      presentationContext: presentationContext,
                      resource: fixture.ids[kind]!,
                      row: row(
                        kind,
                        fixture.ids[kind]!,
                        authoringResourceSearchResultType,
                      ),
                      role: skir.PresentationRole.resourceSearchResult,
                      fallbackLabel: "Resource unavailable",
                    ),
                  const Text(
                    "Creation choice",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  buildAuthoringCreationSearchResultItem(
                    row("create", creation, authoringCreationSearchResultType),
                  ),
                  Text(
                    selected.value == "create"
                        ? "Selected creation choice. No resource has been created."
                        : "Selected resource: ${selected.value ?? 'none'}",
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
