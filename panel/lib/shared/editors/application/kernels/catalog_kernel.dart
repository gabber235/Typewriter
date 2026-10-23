import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// The panel's catalog operations, reading published declarations as their
/// framework read models.
final class PanelCatalogKernel implements skir.CatalogKernel {
  const PanelCatalogKernel();

  @override
  skir.PortableMaybe<skir.DataValue> declaration(
    skir.DataValue selection,
    skir.PortableResources resources,
  ) {
    final skir.TypeSelection decoded;
    try {
      decoded = canonicalReadModels.decodeTypeSelection(selection);
    } on FormatException catch (error) {
      throw skir.PortableOperationFailure(
        skir.PortableFailures.illTypedArgument,
        error.message,
      );
    }
    final definition = decoded.definition;
    final published = definition == null
        ? null
        : resources.declaration(definition);
    if (published == null) return const skir.PortableMaybeMissing([]);
    return skir.PortableMaybeValue(
      canonicalReadModels.project(
        published,
        skir.PublishedType.serializer.typeDescriptor,
        const [],
        () {},
        (_) {},
      ),
    );
  }
}
