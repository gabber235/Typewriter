import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

/// Builds the shared element type row used by contextual Page search.
Widget buildElementTypeSearchResultItem(SearchResultRowContext context) =>
    ElementTypeSearchResultItem(
      definition: context.result.payload as ElementDefinition,
      focused: context.focused,
      selected: context.selected,
      loading: context.loading,
      onTap: context.onTap,
      shortcutActivator: context.shortcutActivator,
    );

Widget buildAuthoringCreationSearchResultItem(SearchResultRowContext context) {
  return AuthoringCreationSearchResultItem(
    option: context.result.payload as AuthoringCreationOption,
    selected: context.selected,
    focused: context.focused,
    onTap: context.onTap,
    shortcutActivator: context.shortcutActivator,
  );
}

class AuthoringCreationSearchResultItem extends StatelessWidget {
  const AuthoringCreationSearchResultItem({
    required this.option,
    required this.selected,
    required this.focused,
    required this.onTap,
    required this.shortcutActivator,
    super.key,
  });

  final AuthoringCreationOption option;
  final bool selected;
  final bool focused;
  final VoidCallback? onTap;
  final ShortcutActivator? shortcutActivator;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return SearchResultCard(
      color: color,
      selected: selected,
      focused: focused,
      onTap: onTap,
      content: ListTile(
        title: Text(option.label),
        subtitle: Text(option.root.id.toString()),
      ),
      suffix: SearchResultSuffix(
        label: "resource",
        shortcutActivator: shortcutActivator,
        selected: selected,
      ),
    );
  }
}

class PageKindSearchResultItem extends ConsumerWidget {
  const PageKindSearchResultItem({
    required this.definition,
    required this.selected,
    required this.focused,
    required this.loading,
    required this.onTap,
    required this.shortcutActivator,
    super.key,
  });

  final RealmPageDefinition definition;
  final bool selected;
  final bool focused;
  final bool loading;
  final VoidCallback? onTap;
  final ShortcutActivator? shortcutActivator;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presentation = _catalogPresentation(
      ref,
      definition.presentationSubject,
    );
    final color = Theme.of(context).colorScheme.primary;
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
        child: ComposedEditor(
          model: presentation,
          readOnly: true,
          historyNamespace: "catalog.page.${definition.kind.id}",
        ),
      ),
      suffix: SearchResultSuffix(
        label: "page kind",
        shortcutActivator: shortcutActivator,
        selected: selected,
      ),
    );
  }
}

class ElementTypeSearchResultItem extends ConsumerWidget {
  const ElementTypeSearchResultItem({
    required this.definition,
    required this.selected,
    required this.focused,
    required this.loading,
    required this.onTap,
    required this.shortcutActivator,
    super.key,
  });

  final ElementDefinition definition;
  final bool selected;
  final bool focused;
  final bool loading;
  final VoidCallback? onTap;
  final ShortcutActivator? shortcutActivator;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presentation = _catalogPresentation(
      ref,
      ref
          .watch(realmEditorCatalogProvider)
          .value
          ?.snapshot
          ?.elements[definition.typeId.uuid]
          ?.presentationSubject,
    );
    final color = Theme.of(context).colorScheme.primary;
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
        child: ComposedEditor(
          model: presentation,
          readOnly: true,
          historyNamespace: "catalog.element.${definition.typeId.uuid}",
        ),
      ),
      suffix: SearchResultSuffix(
        label: "element type",
        shortcutActivator: shortcutActivator,
        selected: selected,
      ),
    );
  }
}

PresentationModel _catalogPresentation(
  WidgetRef ref,
  TypedCatalogPresentationSubject? subject,
) {
  final snapshot = ref.watch(realmEditorCatalogProvider).value?.snapshot;
  if (snapshot != null && subject != null) {
    final result = TypedAuthoringCodec(snapshot).catalogPresentation(subject);
    if (result.valueOrNull case final presentation?) {
      return presentation.model;
    }
    return _catalogDiagnosticModel(snapshot.catalog, result.diagnostics);
  }
  return _catalogDiagnosticModel(const TypeCatalog([]), const [
    TypeDiagnostic(
      code: TypeDiagnosticCode.invalidPresentation,
      message: "Catalog presentation is unavailable",
      pathPresent: false,
    ),
  ]);
}

PresentationModel _catalogDiagnosticModel(
  TypeCatalog catalog,
  List<TypeDiagnostic> diagnostics,
) => PresentationModel(
  catalog: catalog,
  inputs: const {},
  root: PresentationNode(
    id: "catalog.option.diagnostic",
    element: DiagnosticElement(diagnostics),
  ),
  diagnostics: diagnostics,
);
