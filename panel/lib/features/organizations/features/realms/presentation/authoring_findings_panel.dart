import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

class AuthoringFindingsPanel extends StatelessWidget {
  const AuthoringFindingsPanel({required this.findings, super.key});

  final List<AuthoredFindingView> findings;

  @override
  Widget build(BuildContext context) {
    if (findings.isEmpty) return const SizedBox.shrink();
    return Semantics(
      container: true,
      label: "Authoring findings",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final finding in findings)
            _FindingRow(key: ValueKey(finding.diagnostic.id), finding: finding),
        ],
      ),
    );
  }
}

class _FindingRow extends StatelessWidget {
  const _FindingRow({required this.finding, super.key});

  final AuthoredFindingView finding;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = switch (finding.diagnostic.severity) {
      skir.DiagnosticSeverity.error => colors.error,
      skir.DiagnosticSeverity.warning => colors.tertiary,
      _ => colors.primary,
    };
    final icon = switch (finding.diagnostic.severity) {
      skir.DiagnosticSeverity.error => Icons.error_outline,
      skir.DiagnosticSeverity.warning => Icons.warning_amber_outlined,
      _ => Icons.info_outline,
    };
    return Opacity(
      opacity: finding.isOutdated ? 0.64 : 1,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: context.spacing.space1),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color),
            SizedBox(width: context.spacing.space2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    finding.diagnostic.message,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (finding.isOutdated)
                    Text(
                      "From a previous authored state",
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
