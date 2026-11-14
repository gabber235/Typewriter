part of "mutation_activity_button.dart";

class _ActivityCard extends StatefulWidget {
  const _ActivityCard({
    required this.title,
    required this.message,
    required this.phase,
    required this.actions,
    this.details = const [],
    this.copyText,
    super.key,
  });
  final String title;
  final String message;
  final MutationActivityPhase phase;
  final List<Widget> actions;
  final List<_ActivityDetail> details;
  final String? copyText;

  @override
  State<_ActivityCard> createState() => _ActivityCardState();
}

class _ActivityCardState extends State<_ActivityCard> {
  late final ExpansibleController _expansibleController;

  @override
  void initState() {
    super.initState();
    _expansibleController = ExpansibleController();
  }

  @override
  void didUpdateWidget(covariant _ActivityCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.details.isEmpty && _expansibleController.isExpanded) {
      _expansibleController.toggle();
      setState(() {});
    }
  }

  @override
  void dispose() {
    _expansibleController.dispose();
    super.dispose();
  }

  void _toggleDetails() {
    if (widget.details.isEmpty) return;
    _expansibleController.toggle();
    setState(() {});
  }

  Future<void> _copyReport() async {
    final report = widget.copyText;
    if (report == null) return;
    await Clipboard.setData(ClipboardData(text: report));
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.phase.color(context);
    final isExpandable = widget.details.isNotEmpty;
    final isExpanded = _expansibleController.isExpanded;
    // The chevron turns with the card's grow and shrink.
    final chevron = motionTimeline(
      context,
      isExpanded ? MotionToken.surfaceIn : MotionToken.panelOut,
    );
    return Padding(
      padding: EdgeInsets.only(top: context.spacing.space2),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: .05),
          borderRadius: context.shapes.mediumBorderRadius,
          border: Border.all(color: color.withValues(alpha: .2)),
        ),
        child: Padding(
          padding: EdgeInsets.all(context.spacing.space3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              GrowingCard(
                controller: _expansibleController,
                maintainState: true,
                header: (context, animation) => Semantics(
                  container: true,
                  button: isExpandable,
                  expanded: isExpandable ? isExpanded : null,
                  label: isExpandable
                      ? "${widget.title}. ${widget.message}"
                      : null,
                  hint: isExpandable
                      ? isExpanded
                            ? "Double tap to collapse"
                            : "Double tap to expand"
                      : null,
                  child: Button(
                    face: ButtonFace.bare,
                    label: "",
                    onPressed: isExpandable ? _toggleDetails : null,
                    child: Padding(
                      padding: EdgeInsets.all(context.spacing.space1),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: .12),
                              borderRadius: context.shapes.smallBorderRadius,
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(context.spacing.space2),
                              child: Icon(
                                widget.phase.icon,
                                color: color,
                                size: 18,
                              ),
                            ),
                          ),
                          SizedBox(width: context.spacing.space3),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.title,
                                  style: context.theme.textTheme.titleSmall,
                                ),
                                SizedBox(height: context.spacing.space1),
                                Text(
                                  widget.message,
                                  maxLines: isExpanded ? null : 1,
                                  overflow: isExpanded
                                      ? TextOverflow.visible
                                      : TextOverflow.ellipsis,
                                  style: context.text.sentenceSmall.copyWith(
                                    color: context.colors.contentSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isExpandable) ...[
                            SizedBox(width: context.spacing.space2),
                            Padding(
                              padding: EdgeInsets.only(
                                top: context.spacing.space1,
                              ),
                              child: AnimatedRotation(
                                turns: isExpanded ? .25 : 0,
                                duration: chevron.duration,
                                curve: chevron.curve,
                                child: Icon(
                                  Icons.chevron_right,
                                  color: context.colors.contentSecondary,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                body: (context) => Padding(
                  padding: EdgeInsets.only(
                    left: context.spacing.space2,
                    top: context.spacing.space3,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final detail in widget.details) ...[
                        Text(
                          detail.label,
                          style: context.theme.textTheme.labelMedium,
                        ),
                        SelectableText(detail.value),
                        SizedBox(height: context.spacing.space2),
                      ],
                    ],
                  ),
                ),
              ),
              if (widget.actions.isNotEmpty || widget.copyText != null) ...[
                SizedBox(height: context.spacing.space2),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: .end,
                  runSpacing: context.spacing.space2,
                  spacing: context.spacing.space2,
                  children: [
                    if (widget.copyText != null)
                      Wrap(
                        spacing: context.spacing.space2,
                        runSpacing: context.spacing.space2,
                        children: [
                          Button(
                            face: ButtonFace.icon,
                            icon: const Icon(Icons.copy_outlined, size: 16),
                            label: "Copy problem report",
                            tooltip: "Copy problem report",
                            doneLabel: "Copied",
                            color: context.colors.contentSecondary,
                            onPressed: _copyReport,
                          ),
                        ],
                      ),
                    if (widget.actions.isNotEmpty)
                      Wrap(
                        alignment: WrapAlignment.end,
                        spacing: context.spacing.space2,
                        runSpacing: context.spacing.space2,
                        children: widget.actions,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

final class _ActivityDetail {
  const _ActivityDetail(this.label, this.value);

  final String label;
  final String value;
}

String _formatActivityProblemReport({
  required String title,
  required String message,
  required List<_ActivityDetail> details,
}) {
  const maxReportLength = 4096;
  final report = StringBuffer()
    ..writeln("Typewriter problem report")
    ..writeln()
    ..writeln("Resource: ${_boundedReportValue(title)}")
    ..writeln("Summary: ${_boundedReportValue(message)}");
  if (details.isEmpty) return report.toString().trimRight();

  report
    ..writeln()
    ..writeln("Details:");
  for (final detail in details) {
    final line =
        "${_boundedReportValue(detail.label)}: ${_boundedReportValue(detail.value)}";
    if (report.length + line.length + 1 > maxReportLength) break;
    report.writeln(line);
  }
  return report.toString().trimRight();
}

String _boundedReportValue(String value) {
  final normalized = value.replaceAll(RegExp(r"\s+"), " ").trim();
  if (normalized.length <= 512) return normalized;
  return "${normalized.substring(0, 512)}…";
}
