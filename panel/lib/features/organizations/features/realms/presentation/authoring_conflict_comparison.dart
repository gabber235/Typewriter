import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Compares complete conflict evidence without owning or changing editing work.
final class AuthoringConflictComparison extends HookWidget {
  const AuthoringConflictComparison({
    required this.review,
    required this.onUseSaved,
    this.onKeepMine,
    this.enabled = true,
    this.onResolved,
    super.key,
  });
  final AuthoringConflictReview review;
  final bool enabled;
  final EditStageResult Function()? onKeepMine;
  final EditStageResult Function() onUseSaved;
  final VoidCallback? onResolved;
  @override
  Widget build(BuildContext context) {
    final status = useState<String?>(null);
    void resolve(EditStageResult Function() action) {
      final result = action();
      if (result case EditStageRejected(:final message)) {
        status.value = message;
      } else {
        onResolved?.call();
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          "Compare your complete editing group with the saved values.",
        ),
        for (final fact in review.comparisonFacts) ...[
          SizedBox(height: context.spacing.space3),
          Text(
            fact.label(review.saved),
            style: context.theme.textTheme.titleSmall,
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final cells = [
                _cell(
                  context,
                  "Before your changes",
                  fact.describe(review.original),
                ),
                _cell(
                  context,
                  "Your proposal",
                  review.proposal.facts.observe(fact).describe(review.proposal),
                ),
                _cell(
                  context,
                  "Saved now",
                  review.saved.facts.observe(fact).describe(review.saved),
                ),
              ];
              return constraints.maxWidth < 560
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: cells,
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final cell in cells) Expanded(child: cell),
                      ],
                    );
            },
          ),
        ],
        if (review.evidence.facts.isEmpty)
          const Text("The saved values now match the original expectations."),
        if (review.unavailableReason case final reason?) Text(reason),
        if (status.value case final message?)
          Semantics(liveRegion: true, child: Text(message)),
        SizedBox(height: context.spacing.space3),
        const Text(
          "These actions apply to all unsent changes in this editing group. Other groups keep their changes.",
        ),
        Wrap(
          spacing: context.spacing.space2,
          children: [
            TextButton(
              onPressed: enabled ? () => resolve(onUseSaved) : null,
              child: const Text("Use saved"),
            ),
            FilledButton(
              onPressed: !enabled || onKeepMine == null
                  ? null
                  : () => resolve(onKeepMine!),
              child: const Text("Keep mine"),
            ),
          ],
        ),
      ],
    );
  }

  Widget _cell(BuildContext context, String label, String value) => Padding(
    padding: EdgeInsets.all(context.spacing.space2),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: context.theme.textTheme.labelMedium),
        SelectableText(value),
      ],
    ),
  );
}

extension _ConflictFactDisplay on skir.EditExpectation {
  String label(AuthoringDocument document) => switch (this) {
    skir.EditExpectation_valueWrapper(:final value) =>
      "${value.at.resource.label(document)}${value.at.path.diagnosticLabel.substring(1)}",
    skir.EditExpectation_configurationWrapper(:final value) =>
      "Configuration of ${value.at.resource.label(document)}${value.at.path.diagnosticLabel.substring(1)}",
    skir.EditExpectation_resourceWrapper(:final value) =>
      "Resource ${value.id.label(document)}",
    skir.EditExpectation_resourceExistsWrapper(:final value) =>
      "Resource ${value.id.label(document)}",
    skir.EditExpectation_resourceIdsWrapper() => "Resources",
    skir.EditExpectation_linksWrapper(:final value) =>
      "Connections of ${value.resource.label(document)}",
    _ => "Unavailable fact",
  };
  String describe(AuthoringDocument document) => switch (this) {
    skir.EditExpectation_valueWrapper(:final value) =>
      value.expected?.describe(document) ?? "Missing",
    skir.EditExpectation_configurationWrapper(:final value) =>
      value.expected == null
          ? "Missing"
          : document.catalog.typeSelectionName(value.expected!),
    skir.EditExpectation_resourceWrapper(:final value) =>
      value.expected == null
          ? "Missing"
          : "${document.catalog.typeSelectionName(value.expected!.configuration)}: ${value.expected!.fields.map((field) => '${field.name}: ${field.value.describe(document)}').join(', ')}",
    skir.EditExpectation_resourceExistsWrapper(:final value) =>
      value.expected ? "Exists" : "Missing",
    skir.EditExpectation_resourceIdsWrapper(:final value) =>
      value.isEmpty
          ? "No resources"
          : value.map((id) => id.label(document)).join(", "),
    skir.EditExpectation_linksWrapper(:final value) =>
      value.expected.isEmpty
          ? "No connections"
          : value.expected
                .map(
                  (link) =>
                      "${link.first.label(document)}${link.firstLocation?.diagnosticLabel.substring(1) ?? ""} to ${link.second.label(document)}${link.secondLocation?.diagnosticLabel.substring(1) ?? ""}",
                )
                .join("\n"),
    _ => "Unavailable",
  };
}

extension _ConflictValueDisplay on skir.DataValue {
  String describe(AuthoringDocument document) => switch (this) {
    final value when value == skir.DataValue.unfilled => "Unfilled",
    final value when value == skir.DataValue.null_ => "Null",
    skir.DataValue_stringValueWrapper(:final value) =>
      value.isEmpty ? '""' : value,
    skir.DataValue_integerWrapper(:final value) => value,
    skir.DataValue_floatWrapper(:final value) => value.toString(),
    skir.DataValue_decimalWrapper(:final value) => value,
    skir.DataValue_booleanWrapper(:final value) => value.toString(),
    skir.DataValue_timestampWrapper(:final value) => value.toString(),
    skir.DataValue_namedWrapper(:final value) =>
      "${document.catalog.typeUseName(skir.TypeUse.wrapNamed(value.actualType))}: ${value.payload.describe(document)}",
    skir.DataValue_recordWrapper(:final value) =>
      value.fields
          .map((field) => "${field.name}: ${field.value.describe(document)}")
          .join("\n"),
    skir.DataValue_listValueWrapper(:final value) =>
      value.items
          .map((item) => "${item.id.value}: ${item.value.describe(document)}")
          .join("\n"),
    skir.DataValue_setValueWrapper(:final value) =>
      value.items
          .map((item) => "${item.id.value}: ${item.value.describe(document)}")
          .join("\n"),
    skir.DataValue_linkWrapper(:final value) => value.target.resource.value,
    skir.DataValue_bytesWrapper(:final value) => value.toBase16(),
    skir.DataValue_mapValueWrapper(:final value) =>
      value.rows
          .map(
            (row) =>
                "${row.id.value}: ${row.key.describe(document)} = ${row.value.describe(document)}",
          )
          .join("\n"),
    _ => "Unavailable value",
  };
}

extension _ConflictResourceDisplay on skir.ResourceId {
  String label(AuthoringDocument document) =>
      document.resource(this)?.authoredLabel ?? value;
}
