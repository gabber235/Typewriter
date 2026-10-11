import "package:typewriter_panel/typewriter_panel.dart";

/// Describes one mutation choice before request data is captured.
///
/// Domain preparation chooses which intents share a real transaction.
/// Independent mutations need no batch protocol or synthetic document.
sealed class MutationIntent {
  const MutationIntent();

  void collect(MutationPreparation preparation);
}

/// Keeps one pending commit independent from all other intents.
final class IndependentMutation<T> extends MutationIntent {
  const IndependentMutation(this.commit);
  final PendingCommit<T> commit;

  @override
  void collect(MutationPreparation preparation) {
    preparation._entries.add(() => commit);
  }
}

/// Explicit transaction identity within one preparation pass.
///
/// Reuse the same combiner for operations that belong to the same domain scope.
/// The combiner prepares one response for the collected operations.
final class MutationCombiner<Operation, ResponseT> {
  const MutationCombiner({required this.prepare});

  final PreparedCommit<ResponseT> Function(List<Operation>) prepare;
}

/// Contributes one operation to the transaction identified by [combiner].
///
/// Resource membership is declared before preparation. This lets the
/// coordinator reserve participants without reading mutable draft state.
final class CombinedMutation<Operation, ResponseT> extends MutationIntent {
  CombinedMutation({
    required this.combiner,
    required Set<Object> resources,
    required this.prepare,
  }) : resources = Set.unmodifiable(resources);

  final MutationCombiner<Operation, ResponseT> combiner;
  final Set<Object> resources;
  final MutationContribution<Operation, ResponseT> Function() prepare;

  @override
  void collect(MutationPreparation preparation) {
    preparation._combine(this);
  }
}

/// Captured operation data and optional local response integration.
final class MutationContribution<Operation, ResponseT> {
  const MutationContribution({required this.operation, this.integrate});

  final Operation operation;
  final Future<void> Function(SubmissionResult<ResponseT>)? integrate;
}

/// Collects an explicit set of mutation intents into pending commits.
///
/// Combines only the intents explicitly passed for this action. Grouping fixes
/// participants without reading their current draft values. The same combiner
/// object identifies one transaction; equal values do not merge.
final class MutationPreparation {
  MutationPreparation._();

  final _entries = <PendingCommit<Object?> Function()>[];
  final _groups = <Object, Object>{};

  /// Returns immutable pending commits in first occurrence order.
  static List<PendingCommit<Object?>> collect(
    Iterable<MutationIntent> intents,
  ) {
    final preparation = MutationPreparation._();
    for (final intent in intents) {
      intent.collect(preparation);
    }
    return List.unmodifiable(preparation._entries.map((collect) => collect()));
  }

  void _combine<Operation, ResponseT>(
    CombinedMutation<Operation, ResponseT> intent,
  ) {
    final existing = _groups[intent.combiner];
    if (existing != null) {
      // The combiner instance fixes both generic types for this group.
      final group = existing as _MutationGroup<Operation, ResponseT>;
      group.intents.add(intent);
      return;
    }
    final group = _MutationGroup<Operation, ResponseT>(intent.combiner);
    group.intents.add(intent);
    _groups[intent.combiner] = group;
    _entries.add(group.collect);
  }
}

final class _MutationGroup<Operation, ResponseT> {
  _MutationGroup(this.combiner);
  final MutationCombiner<Operation, ResponseT> combiner;
  final intents = <CombinedMutation<Operation, ResponseT>>[];

  PendingCommit<ResponseT> collect() {
    final participants =
        List<CombinedMutation<Operation, ResponseT>>.unmodifiable(intents);
    return PendingCommit(
      resources: participants.expand((intent) => intent.resources).toSet(),
      prepare: () {
        final captured = participants
            .map((intent) => intent.prepare())
            .toList();
        final commit = combiner.prepare(
          List.unmodifiable(captured.map((intent) => intent.operation)),
        );
        return commit.copyWith(
          integrate: (result) async {
            await commit.integrate?.call(result);
            for (final intent in captured) {
              await intent.integrate?.call(result);
            }
          },
        );
      },
    );
  }
}
