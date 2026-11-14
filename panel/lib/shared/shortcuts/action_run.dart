import "package:typewriter_panel/typewriter_panel.dart";

part "action_run.freezed.dart";

/// What pressing an action does. An action with no run is disabled.
@freezed
sealed class ActionRun with _$ActionRun {
  /// Runs [invoke] once per press, through CommandRuns.
  const factory ActionRun.press(ActionInvoke invoke) = PressRun;

  /// Runs [plan] only after the hold completes.
  const factory ActionRun.hold(HoldPlan<Object> plan) = HoldRun;
}

/// How heavy a hold is; a heavier action holds longer.
enum HoldWeight {
  /// Loses only the user's own unsent work: Discard, Use saved.
  light(MotionToken.holdLight),

  /// Makes someone else act again: Remove member, Decline, Revoke, Unbind.
  heavy(MotionToken.holdHeavy),

  /// Nothing can recover it: deleting a Realm resource.
  permanent(MotionToken.holdPermanent);

  const HoldWeight(this.token);

  /// The motion token that times and draws a hold of this weight.
  final MotionToken<HoldLanding> token;
}

/// What a hold does to its targets, typed by their identity [K].
///
/// [rows] are explicit: target order, the sending look, refusals and focus
/// come from them, never from where the key was pressed, so a bulk bar
/// outside the list's RowFocusScope holds the same rows as the list. Every
/// function typed by [K] stays private; CommandRuns gets an untyped
/// [HoldTry], so a plan stored as `HoldPlan<Object>` never calls a function
/// through a widened parameter type.
final class HoldPlan<K extends Object> {
  /// Runs [each] once per target, in list order. With [rows], every target
  /// row is sending for the whole run (one call), and the refused ones are
  /// refused on their entries afterwards.
  const HoldPlan({
    required this.weight,
    required this.verb,
    required String this.doneWord,
    required this._targets,
    required this._outcome,
    required FutureOr<void> Function(WidgetRef ref, K target) this._each,
    this.rows,
  }) : _all = null;

  /// Runs [work] once over every target, for an action that cannot fail one
  /// target at a time (a Realm operation). It has no rows; a failure jams
  /// the command's buttons.
  const HoldPlan.all({
    required this.weight,
    required this.verb,
    required this._targets,
    required this._outcome,
    required Future<void> Function(WidgetRef ref, Set<K> targets) work,
    this.doneWord,
  }) : _each = null,
       _all = work,
       rows = null;

  /// How long the hold takes.
  final HoldWeight weight;

  /// The word that types itself first in the outcome line: Remove.
  final String verb;

  /// The word its button types once the hold's work is done: Removed. It
  /// stays `holdDoneShow`, then the label returns. Null types nothing, as
  /// for a Realm operation, which declares no done word.
  final String? doneWord;

  /// The rows the targets are in, or null for a hold that paints on its
  /// button.
  final HoldRows? rows;

  final Set<K> Function(WidgetRef ref) _targets;
  final String Function(Set<K> targets) _outcome;
  final FutureOr<void> Function(WidgetRef ref, K target)? _each;
  final Future<void> Function(WidgetRef ref, Set<K> targets)? _all;

  /// The outcome line for the current targets, read to a screen reader
  /// before a hold starts; null when there is nothing to hold.
  String? preview(WidgetRef ref) {
    final picked = _targets(ref);
    return picked.isEmpty ? null : _outcome(picked);
  }

  /// Captures the targets and the outcome line at the start of a hold;
  /// null when there is nothing to hold.
  HoldTry? begin(WidgetRef ref) {
    final picked = _targets(ref);
    if (picked.isEmpty) return null;
    final order = rows?.order ?? const <Object>[];
    final ids = List<K>.unmodifiable([
      ...order.whereType<K>().where(picked.contains),
      ...picked.where((id) => !order.contains(id)),
    ]);
    final each = _each;
    final all = _all;
    return HoldTry(
      ids: ids,
      weight: weight,
      verb: verb,
      outcome: _outcome(ids.toSet()),
      rows: rows,
      // The ids came from K, so the typed work is called with its own type.
      each: each == null ? null : (ref, id) => each(ref, id as K),
      all: all == null ? null : (ref) => all(ref, ids.toSet()),
    );
  }
}

/// The rows a hold's targets are in, as a hold needs them: their order,
/// their focus, their sending look and their refusals. The animated rows of
/// a list are one.
abstract interface class HoldRows {
  /// The identities of the rows not leaving, in screen order.
  List<Object> get order;

  /// The identity of the row focused last, or null.
  Object? get focusedId;

  /// Moves focus to the row of [id].
  void focusId(Object id);

  /// Runs [command] with the rows of [ids] sending.
  Future<R> sending<R>(Iterable<Object> ids, Future<R> Function() command);

  /// Refuses the rows in [messages], each with its message.
  void refuse(Map<Object, String> messages);
}

/// One started hold: its targets in list order, its line and its work,
/// untyped. Exactly one of [each] and [all] is set.
final class HoldTry {
  const HoldTry({
    required this.ids,
    required this.weight,
    required this.verb,
    required this.outcome,
    required this.rows,
    required this.each,
    required this.all,
  });

  final List<Object> ids;
  final HoldWeight weight;
  final String verb;
  final String outcome;
  final HoldRows? rows;

  /// The work for one target.
  final FutureOr<void> Function(WidgetRef ref, Object target)? each;

  /// The work over every target at once.
  final Future<void> Function(WidgetRef ref)? all;
}

/// A hold refused with no row to show it; the command's buttons jam and
/// show [message].
final class HoldRefused implements ShownFailure {
  const HoldRefused(this.message);

  @override
  final String message;

  @override
  String toString() => message;
}
