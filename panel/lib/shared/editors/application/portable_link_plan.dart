import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "portable_link_plan.freezed.dart";

/// The link targets a [PortableLinkHost] offers for one link occurrence, or
/// why it cannot offer any.
@freezed
sealed class PortableLinkPlanResult with _$PortableLinkPlanResult {
  const factory PortableLinkPlanResult.ready(List<PortableLinkPlan> plans) =
      PortableLinkPlanReady;
  const factory PortableLinkPlanResult.unavailable(String message) =
      PortableLinkPlanUnavailable;
}

@freezed
abstract class PortableLinkPlan with _$PortableLinkPlan {
  const factory PortableLinkPlan({
    required skir.LinkOccurrence source,
    required skir.RelationContract relation,
    required skir.EndpointDefinition opposite,
    required skir.TypeUse targetType,
    required List<PortableLinkTargetChoice> targets,
  }) = _PortableLinkPlan;
}

@freezed
abstract class PortableLinkTargetChoice with _$PortableLinkTargetChoice {
  const factory PortableLinkTargetChoice({
    required skir.ResourceId resource,
    required bool automaticCounterpart,
    required List<skir.LinkOccurrence> existing,
    required List<PortableNewCounterpartChoice> creatable,
    @Default([]) List<skir.ValueLocation> collections,
    String? disabledReason,
  }) = _PortableLinkTargetChoice;
}

@freezed
abstract class PortableNewCounterpartChoice
    with _$PortableNewCounterpartChoice {
  const factory PortableNewCounterpartChoice({
    required skir.ValueLocation containing,
    required skir.TypeSelection selection,
  }) = _PortableNewCounterpartChoice;
}
