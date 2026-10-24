import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "host_context.freezed.dart";

/// The values an editor host supplies for the [skir.HostContextInput]s that
/// presentations declare. A missing value leaves the input unfilled.
@freezed
abstract class HostContext with _$HostContext {
  const factory HostContext({
    /// The resource routed in the workspace.
    skir.ResourceId? activeResource,

    /// How many resources the current selection holds.
    int? selectionCount,
  }) = _HostContext;

  const HostContext._();

  static const empty = HostContext();

  /// This context with the values it lacks taken from [outer], so a nested
  /// host adds to what an enclosing host supplies.
  HostContext within(HostContext outer) => HostContext(
    activeResource: activeResource ?? outer.activeResource,
    selectionCount: selectionCount ?? outer.selectionCount,
  );

  /// The value type the host contract fixes for [input], or null for an
  /// input this panel does not know.
  static skir.TypeUse? valueType(
    skir.HostContextInput input,
  ) => switch (input.kind) {
    skir.HostContextInput_kind.activeResourceConst => skir.TypeUse.wrapNamed(
      skir.resourceIdType,
    ),
    skir.HostContextInput_kind.selectionCountConst => skir.TypeUse.wrapScalar(
      skir.ScalarKind.createInteger(width: skir.IntegerWidth.signedThirtyTwo),
    ),
    skir.HostContextInput_kind.unknown => null,
  };

  /// The read only binding for [input], or null when this host has no value.
  PortableExpressionBinding? bindingFor(skir.HostContextInput input) =>
      switch (input.kind) {
        skir.HostContextInput_kind.activeResourceConst =>
          activeResource?.toExpressionBinding(),
        skir.HostContextInput_kind.selectionCountConst =>
          selectionCount == null
              ? null
              : PortableExpressionBinding(
                  value: skir.DataValue.wrapInteger(selectionCount.toString()),
                  schema: CompletePortablePresentationBinding(
                    valueType(input)!,
                  ),
                ),
        skir.HostContextInput_kind.unknown => null,
      };
}
