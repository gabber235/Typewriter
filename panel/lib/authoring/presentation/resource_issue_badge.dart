import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// A compact, accessible indicator sharing the resource's issue projection.
class ResourceIssueBadge extends StatelessWidget {
  const ResourceIssueBadge({
    required this.issues,
    this.checking = false,
    this.unavailable = false,
    super.key,
  });
  final List<ResourceIssue> issues;
  final bool checking;
  final bool unavailable;

  @override
  Widget build(BuildContext context) {
    if (issues.isEmpty && !checking && !unavailable) {
      return const SizedBox.shrink();
    }
    final status = unavailable
        ? "Issue review unavailable"
        : checking
        ? "Checking issues"
        : issues.length == 1
        ? "1 issue"
        : "${issues.length} issues";
    final errors = issues.any(
      (issue) => issue.diagnostic.severity == skir.DiagnosticSeverity.error,
    );
    return Tooltip(
      message: status,
      child: Semantics(
        label: status,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              issues.isEmpty
                  ? (unavailable ? Icons.help_outline : Icons.hourglass_empty)
                  : errors
                  ? Icons.error_outline
                  : Icons.warning_amber_outlined,
              size: 14,
              color: errors ? context.colors.danger : context.colors.warning,
            ),
            const SizedBox(width: 3),
            if (issues.isNotEmpty)
              Text(
                "${issues.length}",
                style: context.theme.textTheme.labelSmall,
              ),
          ],
        ),
      ),
    );
  }
}

extension IssuePathLabel on skir.ValuePath {
  String get issueLabel => segments.isEmpty
      ? "Resource"
      : segments
            .map(
              (segment) => switch (segment) {
                skir.PathSegment_fieldWrapper(:final value) =>
                  value.name.titleCase(),
                skir.PathSegment_itemWrapper(:final value) =>
                  "Item ${value.id.value}",
                skir.PathSegment.mapKey => "Key",
                skir.PathSegment.mapValue => "Value",
                _ => "Value",
              },
            )
            .join(" > ");
}
