import "package:typewriter_panel/typewriter_panel.dart";

part "value_update_policy.freezed.dart";

/// Immutable timing configuration. Equal policies preserve a hook's controller.
/// Each creation owns independent work and synchronously exposes [initialValue].
abstract interface class ValueUpdatePolicy<T> {
  ValueUpdateController<T> create(T initialValue);
}

/// Owns the presented value and pending work for one consumer.
///
/// Inputs must have value equality and remain immutable after observation.
/// Notify only when [value] changes, and cancel pending work on [dispose].
/// Scheduling belongs to the controller lifetime, independently of listeners.
abstract interface class ValueUpdateController<T>
    implements ValueListenable<T> {
  void observe(T next);
  void dispose();
}

/// Collects distinct inputs in fixed windows without extending the deadline.
/// The initial value is immediate. The latest input wins at each deadline.
@freezed
abstract class CoalesceUpdates<T>
    with _$CoalesceUpdates<T>
    implements ValueUpdatePolicy<T> {
  const factory CoalesceUpdates({
    @Default(Duration(milliseconds: 100)) Duration duration,
  }) = _CoalesceUpdates<T>;
  const CoalesceUpdates._();

  @override
  ValueUpdateController<T> create(T initialValue) =>
      _CoalescedValueController(initialValue, duration);
}

/// Waits for a quiet period after each distinct input.
/// The initial value is immediate; continuous changes can postpone updates.
@freezed
abstract class DebounceUpdates<T>
    with _$DebounceUpdates<T>
    implements ValueUpdatePolicy<T> {
  const factory DebounceUpdates({
    @Default(Duration(milliseconds: 100)) Duration duration,
  }) = _DebounceUpdates<T>;
  const DebounceUpdates._();

  @override
  ValueUpdateController<T> create(T initialValue) =>
      _DebouncedValueController(initialValue, duration);
}

class _CoalescedValueController<T> extends ValueNotifier<T>
    implements ValueUpdateController<T> {
  _CoalescedValueController(super.initialValue, this.duration)
    : _latest = initialValue {
    if (duration.isNegative) {
      throw ArgumentError.value(duration, "duration", "Must be nonnegative");
    }
  }

  final Duration duration;
  T _latest;
  Timer? _window;

  @override
  void observe(T next) {
    if (next == _latest) return;
    _latest = next;
    if (_window != null || next == value) return;
    _window = Timer(duration, () {
      _window = null;
      value = _latest;
    });
  }

  @override
  void dispose() {
    _window?.cancel();
    super.dispose();
  }
}

class _DebouncedValueController<T> extends ValueNotifier<T>
    implements ValueUpdateController<T> {
  _DebouncedValueController(super.initialValue, this.duration)
    : _latest = initialValue {
    if (duration.isNegative) {
      throw ArgumentError.value(duration, "duration", "Must be nonnegative");
    }
  }

  final Duration duration;
  T _latest;
  Timer? _quietPeriod;

  @override
  void observe(T next) {
    if (next == _latest) return;
    _latest = next;
    _quietPeriod?.cancel();
    _quietPeriod = null;
    if (next == value) return;
    _quietPeriod = Timer(duration, () {
      _quietPeriod = null;
      value = _latest;
    });
  }

  @override
  void dispose() {
    _quietPeriod?.cancel();
    super.dispose();
  }
}
