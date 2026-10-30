import "package:typewriter_panel/typewriter_panel.dart";

/// Renders the non row states of a search source snapshot.
///
/// Loading uses a placeholder list. Error summaries take precedence over the
/// generic failure message. Idle and ready snapshots show source guidance when
/// present, otherwise the empty result message.
class SearchResultEmptyState extends StatelessWidget {
  const SearchResultEmptyState({required this.snapshot, super.key});

  final SearchSourceSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return switch (snapshot.status) {
      .loading => const _LoadingState(),
      .error => _ErrorState(snapshot: snapshot),
      .idle || .ready => _GuidanceOrEmptyState(snapshot: snapshot),
    };
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: searchLoadingSemanticLabel,
      container: true,
      child: ListView.separated(
        itemCount: 10,
        physics: const NeverScrollableScrollPhysics(),
        separatorBuilder: (context, index) =>
            SizedBox(height: context.spacing.space4),
        itemBuilder: (context, index) {
          final height = (random.nextInt(12) + 8) * 5.0;
          return ShimmerBox.rectangle(height: height);
        },
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.snapshot});

  final SearchSourceSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final summaries = snapshot.errorSummaries;

    final Widget child;
    if (summaries.isEmpty) {
      child = Text(
        "Search failed",
        style: textTheme.bodyMedium?.copyWith(color: colorScheme.error),
        textAlign: TextAlign.center,
      );
    } else {
      child = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final summary in summaries)
            Padding(
              padding: EdgeInsets.symmetric(vertical: context.spacing.space1),
              child: LabeledMessage(
                label: summary.sourceLabel,
                message: summary.message,
              ),
            ),
        ],
      );
    }

    return Padding(
      padding: EdgeInsets.all(context.spacing.space2),
      child: ErrorScreen(title: "", message: "", child: child),
    );
  }
}

class _GuidanceOrEmptyState extends StatelessWidget {
  const _GuidanceOrEmptyState({required this.snapshot});

  final SearchSourceSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final guidance = snapshot.guidance.toList()
      ..sort((a, b) => a.priority.compareTo(b.priority));
    return Padding(
      padding: EdgeInsets.all(context.spacing.space4),
      child: guidance.isEmpty
          ? const EmptyScreen(title: "No results found", small: true)
          : EmptyScreen(
              small: true,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final entry in guidance)
                    Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: context.spacing.space1,
                      ),
                      child: LabeledMessage(
                        label: entry.title,
                        message: entry.description,
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
