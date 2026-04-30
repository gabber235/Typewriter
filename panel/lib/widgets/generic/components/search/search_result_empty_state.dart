import "package:flutter/material.dart";
import "package:typewriter_panel/logic/search/search.dart";

class SearchResultEmptyState extends StatelessWidget {
  const SearchResultEmptyState({required this.snapshot, super.key});

  final SearchSourceSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: switch (snapshot.status) {
          SearchSourceStatus.loading => const _LoadingState(),
          SearchSourceStatus.error => _ErrorState(snapshot: snapshot),
          SearchSourceStatus.idle => _GuidanceOrEmptyState(snapshot: snapshot),
          SearchSourceStatus.ready => _GuidanceOrEmptyState(snapshot: snapshot),
        },
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        SizedBox(height: 12),
        Text("Searching"),
      ],
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
    if (summaries.isEmpty) {
      return Text(
        "Search failed",
        style: textTheme.bodyMedium?.copyWith(color: colorScheme.error),
        textAlign: TextAlign.center,
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final summary in summaries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (summary.sourceLabel != null)
                  Text(
                    summary.sourceLabel!,
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                Text(
                  summary.message,
                  style: textTheme.bodyMedium?.copyWith(
                    color: summary.severity == SearchErrorSeverity.error
                        ? colorScheme.error
                        : colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
      ],
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
    if (guidance.isEmpty) return const Text("No results found");

    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in guidance)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.title, style: textTheme.titleSmall),
                if (entry.description != null)
                  Text(
                    entry.description!,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
