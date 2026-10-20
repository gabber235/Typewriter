import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// A resource in the command palette: a card row, as the palette is a modal.
Widget buildAuthoringResourceSearchResultItem(SearchResultRowContext row) {
  final payload = row.result.payload;
  if (payload is! AuthoringSearchResultPayload) {
    return MissingSearchResultRendererRow(result: row.result);
  }
  return AuthoredResourceSearchResult(
    key: ValueKey(row.result.id),
    document: payload.document,
    issues: payload.issues,
    hostContext: payload.hostContext,
    resource: payload.id,
    row: row,
    role: skir.PresentationRole.resourceSearchResult,
    density: SearchResultDensity.card,
    fallbackLabel: payload.title,
  );
}

/// A resource result in the uniform host chrome: its display's name, accent
/// and icon, its type name as the kind, and the details its [role]
/// presentation declares. The surface picks [density].
final class AuthoredResourceSearchResult extends HookWidget {
  const AuthoredResourceSearchResult({
    required this.document,
    required this.issues,
    required this.resource,
    required this.row,
    required this.role,
    required this.density,
    required this.fallbackLabel,
    this.hostContext = HostContext.empty,
    this.footer,
    this.kindLabel,
    super.key,
  });

  final AuthoringDocument document;
  final ResourceIssues issues;

  /// Host values the result's presentation may read, such as the resource
  /// routed when the palette opened.
  final HostContext hostContext;
  final skir.ResourceId resource;
  final SearchResultRowContext row;
  final skir.PresentationRole role;
  final SearchResultDensity density;

  /// The name shown while the resource is absent from [document].
  final String fallbackLabel;
  final Widget? footer;

  /// Replaces the type name, such as an action a picker row performs.
  final String? kindLabel;

  @override
  Widget build(BuildContext context) {
    final source = document;
    final record = source.resource(resource);
    final selection = record == null
        ? null
        : source.catalog.selectPresentation(record.configuration, role);
    final selected = switch (selection) {
      final SelectedEditorPresentation value => value,
      _ => null,
    };
    final budget = useMemoized(
      () => skir.EvaluationBudget(maxSteps: 10000, maxCollectionItems: 10000),
    );
    final capabilities = const PortablePresentationCapabilities();
    final host = useMemoized(
      () => selected == null
          ? null
          : AuthoredPresentationHost(
              resource: resource,
              source: source,
              material: selected.material,
              role: selected.resolvedRole,
              budget: budget,
              capabilities: capabilities,
              readOnly: true,
              issues: issues,
            ),
      [resource, source.generation, selected?.material, selected?.resolvedRole],
    );
    useEffect(() => host?.dispose, [host]);
    host?.update(
      source: source,
      capabilities: capabilities,
      available: true,
      readOnly: true,
      issues: issues,
    );
    if (record == null) {
      return SearchResultRow(
        row: row,
        density: density,
        title: fallbackLabel,
        leading: const Icon(Icons.link_off),
        kindLabel: kindLabel ?? "unavailable",
        footer: footer,
      );
    }
    final appearance = source.catalog.appearanceOf(record);
    final kind =
        kindLabel ?? source.catalog.typeSelectionName(record.configuration);
    Widget chrome([Widget? body]) => SearchResultRow(
      row: row,
      density: density,
      title: appearance.label,
      accent: appearance.accent,
      leading: ResourceIcon(icon: appearance.icon),
      kindLabel: kind,
      footer: footer,
      body: body,
    );
    return switch (selection) {
      ConflictingEditorPresentation() => chrome(
        const Text("The search result presentation is ambiguous"),
      ),
      UnavailableEditorPresentation() => chrome(
        const Text("The search result presentation is unavailable"),
      ),
      _ when host == null || selected == null => chrome(),
      _ => PortablePresentationRenderer(
        hostContext: hostContext,
        key: ObjectKey(host),
        host: host,
        contentBuilder: (node, scope) => PortableResultContent(
          node: node,
          appearance: appearance,
          scope: scope.copyWith(resource: resource),
          row: row,
          density: density,
          kindLabel: kind,
          footer: footer,
        ),
        errorBuilder: (message) => chrome(Text(message)),
      ),
    };
  }
}
