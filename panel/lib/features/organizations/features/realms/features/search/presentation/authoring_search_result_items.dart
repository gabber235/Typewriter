import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

Widget buildAuthoringResourceSearchResultItem(SearchResultRowContext row) {
  final payload = row.result.payload;
  if (payload is! AuthoringSearchResultPayload) {
    return MissingSearchResultRendererRow(result: row.result);
  }
  return AuthoredResourceSearchResult(
    key: ValueKey(row.result.id),
    document: payload.document,
    issues: payload.issues,
    presentationContext: payload.presentationContext,
    resource: payload.id,
    row: row,
    role: skir.PresentationRole.authoringResult,
    fallbackLabel: payload.title,
  );
}

final class AuthoredResourceSearchResult extends HookWidget {
  const AuthoredResourceSearchResult({
    required this.document,
    required this.issues,
    required this.resource,
    required this.row,
    required this.role,
    required this.fallbackLabel,
    this.presentationContext = const {},
    this.footer,
    this.kindLabelOverride,
    super.key,
  });

  final AuthoringDocument document;
  final ResourceIssues issues;
  final Map<skir.ExpressionBindingId, PortableExpressionBinding>
  presentationContext;
  final skir.ResourceId resource;
  final SearchResultRowContext row;
  final skir.PresentationRole role;
  final String fallbackLabel;
  final Widget? footer;
  final String? kindLabelOverride;

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
    final display = record == null
        ? null
        : source.catalog.selectionDisplay(record.configuration);
    final icon = display?.icon.trim();
    final leading = icon == null || icon.isEmpty
        ? const Icon(Icons.link)
        : Icones(icon);
    final label = record == null
        ? "resource"
        : source.catalog.typeSelectionName(record.configuration);
    if (host == null || selected == null) {
      return SearchResultRow(
        row: row,
        density: SearchResultDensity.card,
        accent: display?.searchResultAccent,
        leading: leading,
        kindLabel: kindLabelOverride ?? label,
        footer: footer,
        body: Text(switch (selection) {
          ConflictingEditorPresentation() =>
            "The search result presentation is ambiguous",
          UnavailableEditorPresentation() =>
            "The search result presentation is unavailable",
          _ => fallbackLabel,
        }),
      );
    }
    final body = PortablePresentationRenderer(
      contextBindings: presentationContext,
      key: ObjectKey(host),
      host: host,
      contentBuilder: (node, scope) => PortableResultContent(
        node: node,
        appearance: selected.material.resultAppearance,
        scope: scope.copyWith(resource: resource),
        row: row,
        fallbackStyle: SearchResultDensity.card,
        fallbackKindLabel: label,
        fallbackAccent: display?.searchResultAccent,
        kindLabelOverride: kindLabelOverride,
        fallbackLeading: leading,
        footer: footer,
      ),
      errorBuilder: (message) => SearchResultRow(
        row: row,
        density: SearchResultDensity.card,
        accent: display?.searchResultAccent,
        leading: leading,
        kindLabel: kindLabelOverride ?? label,
        footer: footer,
        body: Text(message),
      ),
    );
    return body;
  }
}

Map<skir.ExpressionBindingId, PortableExpressionBinding> libraryOriginBindings(
  skir.ResourceId? origin,
) => origin == null
    ? const {}
    : {
        skir.ExpressionBindingId(
          value: "context:typewriter.library.active_resource",
        ): origin
            .toExpressionBinding(),
      };
