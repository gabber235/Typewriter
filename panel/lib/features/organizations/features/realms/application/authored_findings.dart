import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;

final class AuthoredFindingView {
  const AuthoredFindingView({required this.source, required this.diagnostic});

  final skir.FindingSet source;
  final skir.Diagnostic diagnostic;

  bool get isOutdated => source.status == skir.FindingStatus.outdated;
}

extension AuthoredFindingProjection on Iterable<skir.FindingSet> {
  List<AuthoredFindingView> atResource(skir.ResourceId resource) {
    final projected = <AuthoredFindingView>[];
    for (final set in this) {
      final fallback = set.ticket.instance.location.resource;
      final diagnostics = <skir.Diagnostic>[
        ...set.findings,
        if (set.outcome case skir.CheckOutcome_failedWrapper(:final value))
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
