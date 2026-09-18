import "dart:async";

import "package:freezed_annotation/freezed_annotation.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "editor_realm_runtime.freezed.dart";

/// Optional realm capabilities used by typed editor surfaces.
///
/// The nullable provider keeps shared editor code independent of a realm host.
/// A host installs the runtime when realm actions, presentation searches, and
/// reference authoring are available. Consumers must handle the absent runtime
/// as unavailable rather than constructing a partial substitute.
final editorRealmRuntimeProvider = Provider<EditorRealmRuntime?>(
  (ref) => null,
  dependencies: [],
);

/// Executes realm actions and any panel instructions returned by them.
///
/// These operations form one capability because realm actions may return panel
/// instructions as part of the same command result.
@freezed
abstract class RealmActionCapabilities with _$RealmActionCapabilities {
  const factory RealmActionCapabilities({
    required EditorRealmActionExecutor execute,
    FutureOr<void> Function(PanelInstruction instruction)?
    executePanelInstruction,
  }) = _RealmActionCapabilities;
}

/// Builds realm backed search sources for presentation defined searches.
@freezed
abstract class RealmPresentationSearchCapabilities
    with _$RealmPresentationSearchCapabilities {
  const factory RealmPresentationSearchCapabilities({
    required RealmPresentationSearchSourceBuilder source,
  }) = _RealmPresentationSearchCapabilities;
}

/// Searches and resolves authoring references under one eligibility policy.
///
/// A reference editor needs all three operations to present candidates, retain
/// missing stored values, and reject candidates consistently.
@freezed
abstract class ReferenceAuthoringCapabilities
    with _$ReferenceAuthoringCapabilities {
  const factory ReferenceAuthoringCapabilities({
    required ReferenceSearchSourceBuilder search,
    required ReferenceResourceResolver resolve,
    @Default(ReferenceCandidatePolicyRegistry())
    ReferenceCandidatePolicyRegistry policies,
  }) = _ReferenceAuthoringCapabilities;
}

/// Host operations available to one composed presentation tree.
///
/// Empty groups are valid for local and read only surfaces. Cohesive feature
/// groups prevent hosts from installing only part of a usable capability.
@freezed
abstract class EditorHostCapabilities with _$EditorHostCapabilities {
  const factory EditorHostCapabilities({
    RealmActionCapabilities? realmActions,
    RealmPresentationSearchCapabilities? presentationSearch,
    ReferenceAuthoringCapabilities? references,
  }) = _EditorHostCapabilities;
}

/// Complete host capabilities supplied by an active realm.
///
/// The provider that creates this value owns transport and session lifetimes.
/// Editor surfaces receive only immutable operations through [host].
@freezed
abstract class EditorRealmRuntime with _$EditorRealmRuntime {
  const factory EditorRealmRuntime({
    required RealmActionCapabilities actions,
    required RealmPresentationSearchCapabilities presentationSearch,
    required ReferenceAuthoringCapabilities references,
  }) = _EditorRealmRuntime;

  const EditorRealmRuntime._();

  EditorHostCapabilities host({
    FutureOr<void> Function(PanelInstruction instruction)?
    executePanelInstruction,
  }) => EditorHostCapabilities(
    realmActions: actions.copyWith(
      executePanelInstruction:
          executePanelInstruction ?? actions.executePanelInstruction,
    ),
    presentationSearch: presentationSearch,
    references: references,
  );
}
