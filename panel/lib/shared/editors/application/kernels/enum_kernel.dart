import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;

/// The panel's enumeration operations, over the catalog's type facts.
final class PanelEnumKernel implements skir.EnumKernel {
  const PanelEnumKernel();

  @override
  List<skir.ListItem> cases(skir.TypeUse eType, skir.PortableTypes types) =>
      skir.positionalItems([
        for (final name in types.enumCases(eType)) _case(eType, name),
      ]);

  @override
  skir.DataValue fromName(
    String name,
    skir.TypeUse eType,
    skir.PortableTypes types,
  ) => types.enumCases(eType).contains(name)
      ? _case(eType, name)
      : skir.DataValue.null_;
}

skir.DataValue _case(skir.TypeUse type, String name) => switch (type) {
  skir.TypeUse_namedWrapper(:final value) => skir.DataValue.createNamed(
    actualType: value,
    payload: skir.DataValue.wrapEnumCase(name),
  ),
  _ => throw skir.PortableOperationFailure(
    skir.PortableFailures.illTypedArgument,
    "An enumeration is a named type.",
  ),
};
