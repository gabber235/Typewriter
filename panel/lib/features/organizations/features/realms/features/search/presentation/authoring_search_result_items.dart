import "package:flutter/material.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Keeps search selection, activation, and keyboard behavior in Flutter while
/// the Realm supplied authoring role owns the visual body.
class AuthoringSearchResultItem extends StatelessWidget {
  const AuthoringSearchResultItem({
    required this.payload,
    required this.selected,
    required this.focused,
    required this.loading,
    required this.onTap,
    required this.shortcutActivator,
    super.key,
  });

  final AuthoringSearchResultPayload payload;
  final bool selected;
  final bool focused;
  final bool loading;
  final VoidCallback? onTap;
  final ShortcutActivator? shortcutActivator;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final presentation = payload.catalog.selectPresentation(
      payload.configuration,
      skir.PresentationRole.authoringResult,
    );
    return SearchResultCard(
      color: color,
      prefix: loading
          ? SearchResultIconTile(
              color: color,
              onColor: color.on(context),
              icon: const SizedBox.shrink(),
              focused: focused,
              loading: true,
            )
          : null,
      selected: selected,
      focused: focused,
      onTap: onTap,
      content: IgnorePointer(
        child: _AuthoringResultPresentation(
          payload: payload,
          selection: presentation,
        ),
      ),
      suffix: SearchResultSuffix(
        label: payload.catalog.typeSelectionName(payload.configuration),
        shortcutActivator: shortcutActivator,
        selected: selected,
      ),
    );
  }
}

final class _AuthoringResultPresentation extends StatelessWidget {
  const _AuthoringResultPresentation({
    required this.payload,
    required this.selection,
  });

  final AuthoringSearchResultPayload payload;
  final EditorPresentationSelection selection;

  @override
  Widget build(BuildContext context) => switch (selection) {
    SelectedEditorPresentation(:final material) =>
      PortablePresentationNodeRenderer(
        node: material.layout,
        scope: PortablePresentationScope(
          bindings: {
            configuredValueBindingId: PortableExpressionBinding(
              value: skir.DataValue.createRecord(
                fields: payload.subject.content.fields,
              ),
              location: skir.ValueLocation(
                resource: payload.id,
                path: skir.ValuePath(segments: const []),
              ),
            ),
          },
          budget: skir.EvaluationBudget(
            maxSteps: 10000,
            maxCollectionItems: 10000,
          ),
          readOnly: true,
          enabled: false,
          catalog: payload.catalog,
          resource: payload.id,
          role: material.role,
          activePresentations: {material.provider},
          setBinding: (_, _) {},
        ),
      ),
    MissingEditorPresentation() => Text(payload.title),
    ConflictingEditorPresentation() => const Text(
      "The search result presentation is ambiguous",
    ),
    UnavailableEditorPresentation() => const Text(
      "The search result presentation is unavailable",
    ),
  };
}
