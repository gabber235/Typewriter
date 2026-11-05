import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// One authored value shown in the presentation its catalog selects for its
/// type, with every edit written back to [value].
class ValueInspector {
  ValueInspector(
    this.value, {
    required this.catalog,
    this.role = skir.PresentationRole.inspector,
  });

  /// The value as the presentation last wrote it.
  skir.DataValue value;
  final CheckedEditorCatalog catalog;
  final skir.PresentationRole role;

  /// A host for the presentation the catalog selects for [value]'s type.
  ///
  /// The caller disposes the host.
  BoundPresentationHost host() {
    final actual = value.authoredActualType!;
    final selected = catalog.selectPresentation(
      skir.TypeSelection.wrapComplete(actual),
      role,
    ) as SelectedEditorPresentation;
    return BoundPresentationHost(
      catalog: catalog,
      root: () => selected.material.layout,
      role: selected.resolvedRole,
      material: selected.material,
      bindings: [
        BoundPresentationBinding(
          id: configuredValueBindingId,
          use: skir.TypeUse.wrapNamed(actual),
          read: (path) => value.editorValueAt(path),
          write: (path, replacement) {
            final result = value.replaceAt(
              path,
              replacement,
            ) as PortablePathValue<skir.DataValue>;
            value = result.value;
            return const PortablePresentationWriteResult.applied();
          },
        ),
      ],
      budget: skir.EvaluationBudget(maxSteps: 1000, maxCollectionItems: 1000),
    );
  }
}
