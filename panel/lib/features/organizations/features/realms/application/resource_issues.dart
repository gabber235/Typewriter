import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "resource_issues.freezed.dart";
part "resource_issues.g.dart";

/// One semantic cause can explain both the working draft and a saved candidate.
@freezed
abstract class ResourceIssue with _$ResourceIssue {
  const factory ResourceIssue({
    required PortablePresentationDiagnostic diagnostic,
    @Default(false) bool current,
    @Default(false) bool saved,
    @Default(false) bool blocksPublication,
    @Default(false) bool outdated,
  }) = _ResourceIssue;
  const ResourceIssue._();

  Object get identity => diagnostic.id ?? diagnostic;
  skir.ValueLocation? get primary => locations.firstOrNull;
  List<skir.ValueLocation> get locations => diagnostic.targets
      .whereType<PortableValueDiagnosticTarget>()
      .map((target) => target.location)
      .toList();
  String get provenance {
    if (!saved) return "Local draft. Does not block saved publication";
    final origin = blocksPublication
        ? "Saved content. Blocks publication"
        : "Saved content";
    if (current) return "$origin. Also present in current draft";
    return outdated
        ? "$origin. Previous state, checking again"
        : "$origin. Changed locally or awaiting evaluation";
  }
}

/// Combines local structural and portable rule feedback with saved publication
/// findings. Evidence determines whether a saved finding also applies to the
/// working draft; severity alone never makes a local issue block publication.
/// Reloading retains saved provenance without claiming it describes new edits.
@freezed
abstract class ResourceIssues with _$ResourceIssues {
  const factory ResourceIssues({
    @Default([]) List<ResourceIssue> findings,
    @Default(false) bool checking,
    @Default(false) bool unavailable,
  }) = _ResourceIssues;
  const ResourceIssues._();

  factory ResourceIssues.evaluate({
    required AuthoringDocument document,
    RealmPublicationView? publication,
    bool reloading = false,
  }) {
    final findings = <ResourceIssue>[];
    void add(ResourceIssue issue) {
      final index = findings.indexWhere(
        (existing) =>
            (issue.diagnostic.id != null &&
                existing.diagnostic.id == issue.diagnostic.id) ||
            ((existing.saved != issue.saved ||
                    (!existing.saved && !issue.saved)) &&
                existing.diagnostic.code == issue.diagnostic.code &&
                (existing.diagnostic.message == issue.diagnostic.message ||
                    (issue.current &&
                        !issue.saved &&
                        issue.diagnostic.origin ==
                            _publicationDiagnosticOrigin)) &&
                existing.diagnostic.severity == issue.diagnostic.severity &&
                const DeepCollectionEquality().equals(
                  existing.diagnostic.targets,
                  issue.diagnostic.targets,
                ) &&
                existing.diagnostic.origin == issue.diagnostic.origin),
      );
      if (index < 0) {
        findings.add(issue);
        return;
      }
      final previous = findings[index];
      findings[index] = previous.copyWith(
        diagnostic: issue.current
            ? issue.diagnostic.copyWith(
                id: previous.diagnostic.id ?? issue.diagnostic.id,
                origin: issue.diagnostic.origin ?? previous.diagnostic.origin,
              )
            : previous.diagnostic,
        current: previous.current || issue.current,
        saved: previous.saved || issue.saved,
        blocksPublication:
            previous.blocksPublication || issue.blocksPublication,
        outdated: previous.outdated || issue.outdated,
      );
    }

    if (publication != null) {
      for (final issue in publication.projectSavedIssues(document)) {
        add(issue);
      }
    }
    for (final entry in document.entries.values) {
      final id = entry.id;
      final record = entry.content;
      void local(String code, String message, skir.ValuePath path) => add(
        ResourceIssue(
          current: true,
          diagnostic: PortablePresentationDiagnostic(
            origin: _publicationDiagnosticOrigin,
            code: code,
            message: message,
            severity: skir.DiagnosticSeverity.error,
            targets: [
              PortableDiagnosticTarget.value(
                skir.ValueLocation(resource: id, path: path),
              ),
            ],
          ),
        ),
      );
      switch (record.configuration) {
        case skir.TypeSelection_completeWrapper(:final value):
          if (!document.catalog.isReadyApplication(value)) {
            local(
              "unresolved_type",
              "Resource ${id.value} uses an unavailable type.",
              skir.ValuePath(segments: const []),
            );
            break;
          }
          final inspected = document.catalog.inspectPortableValue(
            skir.TypeUse.wrapNamed(value),
            skir.DataValue.createNamed(
              actualType: value,
              payload: skir.DataValue.createRecord(fields: record.fields),
            ),
          );
          for (final path in inspected.unfinished) {
            local("unfinished_value", "A required value is unfinished.", path);
          }
          for (final problem in inspected.structuralProblems) {
            local(
              problem.code,
              "The authored value is structurally invalid.",
              problem.path,
            );
          }
        default:
          local(
            "pending_type",
            "Resource ${id.value} has incomplete type arguments.",
            skir.ValuePath(segments: const []),
          );
      }
      for (final diagnostic in AuthoredRuleProjection.evaluate(
        draft: document,
        catalog: document.catalog,
        resource: id,
        budget: skir.EvaluationBudget(
          maxSteps: 10000,
          maxCollectionItems: 10000,
        ),
      ).diagnostics) {
        add(ResourceIssue(diagnostic: diagnostic, current: true));
      }
    }
    for (final finding in document.initializationFindings) {
      if (!finding.evidence.appliesTo(document)) {
        continue;
      }
      add(
        ResourceIssue(
          current: true,
          diagnostic: PortablePresentationDiagnostic(
            code: finding.diagnostic.code,
            message: finding.diagnostic.message,
            severity: skir.DiagnosticSeverity.warning,
            targets: [PortableDiagnosticTarget.value(finding.location)],
          ),
        ),
      );
    }
    return ResourceIssues(
      findings: findings,
      checking:
          reloading ||
          publication is CheckingRealmPublication ||
          publication is RequestActiveRealmPublication,
      unavailable: publication is UnavailableRealmPublication,
    );
  }
  List<ResourceIssue> currentFor(skir.ResourceId resource) => findings
      .where(
        (finding) =>
            finding.current &&
            finding.locations.any((at) => at.resource == resource),
      )
      .toList();
  List<ResourceIssue> savedFor(skir.ResourceId resource) => findings
      .where(
        (finding) =>
            finding.saved &&
            finding.locations.any((at) => at.resource == resource),
      )
      .toList();
}

extension DiagnosticEvidenceApplicability on skir.DiagnosticEvidence {
  bool appliesTo(AuthoringDocument working) =>
      catalog == working.generation &&
      working.facts.conflicts(expectations).isEmpty;
}

extension PublicationIssueProjection on RealmPublicationView {
  Iterable<ResourceIssue> projectSavedIssues(
    AuthoringDocument? document,
  ) sync* {
    final status = review;
    final retained =
        this is CheckingRealmPublication ||
        this is UnavailableRealmPublication ||
        this is RequestActiveRealmPublication ||
        this is UncertainRealmPublication;
    final reviewedDocument = retained ? null : document;
    final findings = switch (status) {
      skir.PublicationStatus_checkingWrapper(:final value) => value.findings,
      skir.PublicationStatus_unavailableWrapper(:final value) => value.findings,
      _ => const <skir.FindingSet>[],
    };
    for (final set in findings) {
      for (final diagnostic in [
        ...set.findings,
        if (set.outcome case skir.CheckOutcome_failedWrapper(:final value))
          ...value,
      ]) {
        yield ResourceIssue(
          diagnostic: diagnostic.asPresentation(
            fallback: set.ticket.instance.location,
          ),
          saved: true,
          outdated: set.status == skir.FindingStatus.outdated,
          current:
              document != null &&
              set.status == skir.FindingStatus.current &&
              set.ticket.catalog == document.generation &&
              document.facts.conflicts(set.expectations).isEmpty,
        );
      }
    }
    final notices = switch (status) {
      skir.PublicationStatus_emptyWrapper(:final value) => value.notices,
      skir.PublicationStatus_currentWrapper(:final value) => value.notices,
      skir.PublicationStatus_readyWrapper(:final value) => value.notices,
      skir.PublicationStatus_blockedWrapper(:final value) => value.notices,
      skir.PublicationStatus_publishingWrapper(:final value) =>
        value.next.notices,
      _ => const <skir.PublicationNotice>[],
    };
    for (final notice in notices) {
      switch (notice) {
        case skir.PublicationNotice_informationWrapper(:final value):
          yield value.asResourceIssue(
            skir.DiagnosticSeverity.information,
            reviewedDocument,
            outdated: retained,
          );
        case skir.PublicationNotice_warningWrapper(:final value):
          yield value.asResourceIssue(
            skir.DiagnosticSeverity.warning,
            reviewedDocument,
            outdated: retained,
          );
        default:
          break;
      }
    }
    final blockers = switch (status) {
      skir.PublicationStatus_blockedWrapper(:final value) => [
        value.blockers.first,
        ...value.blockers.additional,
      ],
      skir.PublicationStatus_publishingWrapper(:final value) =>
        value.next.blockers,
      _ => const <skir.PublicationBlocker>[],
    };
    for (final blocker in blockers) {
      yield blocker.details.asResourceIssue(
        skir.DiagnosticSeverity.error,
        reviewedDocument,
        outdated: retained,
        blocksPublication: true,
      );
    }
  }
}

extension PublicationDiagnosticProjection on skir.PublicationDiagnosticDetails {
  ResourceIssue asResourceIssue(
    skir.DiagnosticSeverity severity,
    AuthoringDocument? document, {
    bool blocksPublication = false,
    bool outdated = false,
  }) => ResourceIssue(
    diagnostic: PortablePresentationDiagnostic(
      id: id,
      origin: origin,
      code: code,
      message: message,
      severity: severity,
      targets: [
        if (primary != null) PortableDiagnosticTarget.value(primary!),
        ...related.map(PortableDiagnosticTarget.value),
      ],
    ),
    saved: true,
    current: document != null && evidence?.appliesTo(document) == true,
    blocksPublication: blocksPublication,
    outdated: outdated,
  );
}

extension CheckedDiagnosticProjection on skir.Diagnostic {
  PortablePresentationDiagnostic asPresentation({
    skir.ValueLocation? fallback,
  }) => PortablePresentationDiagnostic(
    id: id,
    origin: origin,
    code: code,
    message: message,
    severity: severity,
    targets: [
      if (primary ?? fallback case final at?)
        PortableDiagnosticTarget.value(at),
      ...related.map(PortableDiagnosticTarget.value),
    ],
  );
}

@riverpod
AsyncValue<ResourceIssues> resourceIssues(Ref ref, AuthoringScope scope) {
  final source = ref.watch(workingAuthoringDocumentProvider(scope));
  if (source.mapUnready<ResourceIssues>() case final pending?) return pending;
  final publication = ref.watch(
    realmPublicationProvider(scope.organizationId, scope.realmId),
  );
  return AsyncData(
    ResourceIssues.evaluate(
      document: source.requireValue,
      publication:
          publication.value ??
          (publication.hasError
              ? RealmPublicationView.unavailable(publication.error.toString())
              : const RealmPublicationView.checking()),
      reloading: source.isLoading || publication.isLoading,
    ),
  );
}

// Matches the server's intrinsic publication findings, separate from configured rules.
final _publicationDiagnosticOrigin = skir.RuleOrigin(
  owner: skir.TypeDefinitionId(
    typeId: skir.TypeId.createQualified(
      namespace: "typewriter",
      name: "publication",
    ),
    revision: 1,
  ),
  ordinal: 0,
);
