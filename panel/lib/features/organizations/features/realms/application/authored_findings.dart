import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/checking.dart"
    as checking;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/diagnostic.dart"
    as wire_diagnostic;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/type_catalog.dart"
    as types;

final class AuthoredFindingView {
  const AuthoredFindingView({required this.source, required this.diagnostic});

  final checking.FindingSet source;
  final wire_diagnostic.Diagnostic diagnostic;

  bool get isOutdated => source.status == checking.FindingStatus.outdated;
}

extension AuthoredFindingProjection on Iterable<checking.FindingSet> {
  List<AuthoredFindingView> atResource(types.ResourceId resource) {
    final projected = <AuthoredFindingView>[];
    for (final set in this) {
      final fallback = set.ticket.instance.location.resource;
      final diagnostics = <wire_diagnostic.Diagnostic>[
        ...set.findings,
        if (set.outcome case checking.CheckOutcome_failedWrapper(:final value))
          ...value,
      ];
      for (final finding in diagnostics) {
        final primary = finding.primary?.resource ?? fallback;
        final related = finding.related.any(
          (location) => location.resource == resource,
        );
        if (primary == resource || related) {
          projected.add(AuthoredFindingView(source: set, diagnostic: finding));
        }
      }
    }
    return List.unmodifiable(projected);
  }
}
