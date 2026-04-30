import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:rive/rive.dart";
import "package:typewriter_panel/hooks/rive.dart";
import "package:typewriter_panel/logic/search/search.dart";
import "package:typewriter_panel/main.dart";
import "package:typewriter_panel/utils/rive.dart";
import "package:typewriter_panel/widgets/generic/components/labeled_message.dart";
import "package:typewriter_panel/widgets/generic/components/shimmer.dart";
import "package:typewriter_panel/widgets/generic/screens/error_screen.dart";

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
    return ListView.separated(
      itemCount: 10,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final height = (random.nextInt(12) + 8) * 5.0;
        return ShimmerBox.rectangle(height: height);
      },
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
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: LabeledMessage(
                label: summary.sourceLabel,
                message: summary.message,
              ),
            ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ErrorScreen(title: "", message: "", child: child),
    );
  }
}

class _GuidanceOrEmptyState extends HookWidget {
  const _GuidanceOrEmptyState({required this.snapshot});

  final SearchSourceSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final guidance = snapshot.guidance.toList()
      ..sort((a, b) => a.priority.compareTo(b.priority));
    final Widget child;
    if (guidance.isEmpty) {
      child = const Text("No results found");
    } else {
      child = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final entry in guidance)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: LabeledMessage(
                label: entry.title,
                message: entry.description,
              ),
            ),
        ],
      );
    }

    final fileLoader = useRiveFileLoader.fromAsset("assets/cute_robot.riv");

    return Padding(
      padding: const EdgeInsets.all(18.0),
      child: Column(
        mainAxisAlignment: .center,
        children: [
          Expanded(
            flex: 5,
            child: RiveWidgetBuilder(
              fileLoader: fileLoader,
              stateMachineSelector: StateMachineSelector.byName("Motion"),
              builder: (context, state) => state(),
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 500),
            child: child,
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
