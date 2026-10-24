import "package:typewriter_panel/typewriter_panel.dart";

/// Presents a value using an independently owned timing controller.
///
/// Defaults to fixed 100 ms windows. Equal policies preserve pending work.
/// Changing policy retains the displayed value and starts timing the latest
/// input under the new policy. Removing the hook cancels its pending work.
/// Call unconditionally in a stable hook order, using immutable input values.
T useDeferredValue<T>(T value, {ValueUpdatePolicy<T>? policy}) =>
    use(_DeferredValueHook(value, policy ?? CoalesceUpdates<T>()));

class _DeferredValueHook<T> extends Hook<T> {
  const _DeferredValueHook(this.value, this.policy);
  final T value;
  final ValueUpdatePolicy<T> policy;

  @override
  HookState<T, _DeferredValueHook<T>> createState() =>
      _DeferredValueHookState<T>();
}

class _DeferredValueHookState<T> extends HookState<T, _DeferredValueHook<T>> {
  late ValueUpdateController<T> _controller;

  @override
  void initHook() {
    super.initHook();
    _controller = hook.policy.create(hook.value);
  }

  @override
  void didUpdateHook(_DeferredValueHook<T> oldHook) {
    super.didUpdateHook(oldHook);
    if (hook.policy == oldHook.policy) return;
    final displayed = _controller.value;
    _controller.removeListener(_changed);
    _controller.dispose();
    _controller = hook.policy.create(displayed);
  }

  void _changed() => setState(() {});

  @override
  T build(BuildContext context) {
    // This build will read any synchronous output directly.
    // Subscribe afterward to receive later controller updates.
    _controller.removeListener(_changed);
    try {
      _controller.observe(hook.value);
    } finally {
      _controller.addListener(_changed);
    }
    return _controller.value;
  }

  @override
  void dispose() {
    _controller.removeListener(_changed);
    _controller.dispose();
    super.dispose();
  }
}
