import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Renders one resource role from a generation pinned subject projection.
class AuthoringSubjectRole extends ConsumerWidget {
  const AuthoringSubjectRole({
    required this.resourceId,
    required this.resourceType,
    required this.role,
    required this.historyNamespace,
    super.key,
  });

  final skir.ResourceId resourceId;
  final ResolvedTypeRef resourceType;
  final PresentationRole role;
  final String historyNamespace;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final organizationId = ref.watch(organizationIdProvider);
    final realmId = ref.watch(realmIdProvider);
    if (organizationId == null || realmId == null) {
      return _diagnostic(const [
        TypeDiagnostic(
          code: TypeDiagnosticCode.invalidPresentation,
          message: "Authoring presentation scope is unavailable",
          pathPresent: false,
        ),
      ]);
    }
    final projection = ref.watch(
      authoringSubjectsProvider(
        AuthoringSubjectScope(
          organizationId: organizationId,
          realmId: realmId,
          resources: {resourceId: resourceType},
        ),
      ),
    );
    return switch (projection) {
      AsyncLoading() => ShimmerBox.rectangle(
        width: double.infinity,
        height: 36,
      ),
      AsyncError(:final error) => _diagnostic([
        TypeDiagnostic(
          code: TypeDiagnosticCode.invalidPresentation,
          message: "Authoring presentation is unavailable: $error",
          pathPresent: false,
        ),
      ]),
      AsyncData(:final value) => _resolved(value),
    };
  }

  Widget _resolved(AuthoringSubjectProjection projection) {
    final subject = projection.subjects[resourceId];
    final result = subject == null
        ? null
        : TypedAuthoringCodec(projection.catalog).subjectPresentation(
            subject,
            role,
            collections: projection.collections,
          );
    final resolved = result?.valueOrNull;
    if (resolved == null) {
      final diagnostics = result?.diagnostics.isNotEmpty == true
          ? result!.diagnostics
          : projection.diagnostics.isNotEmpty
          ? projection.diagnostics
          : const [
              TypeDiagnostic(
                code: TypeDiagnosticCode.invalidPresentation,
                message: "Authoring presentation subject is unavailable",
                pathPresent: false,
              ),
            ];
      return _diagnostic(diagnostics);
    }
    return ComposedEditor(
      model: resolved.model,
      readOnly: true,
      historyNamespace: historyNamespace,
    );
  }

  Widget _diagnostic(List<TypeDiagnostic> diagnostics) => Builder(
    builder: (context) => presentationDiagnostic(context, diagnostics),
  );
}
