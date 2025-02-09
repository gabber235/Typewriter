import "package:flutter/foundation.dart";
import "package:flutter/scheduler.dart";
import "package:flutter/widgets.dart";
import "package:flutter_hooks/flutter_hooks.dart";

/// Create a multi usage [TickerProvider].
///
/// See also:
///  * [TickerProviderStateMixin]
TickerProvider useTickerProvider({List<Object?>? keys}) {
  return use(
    keys != null ? _TickerProviderHook(keys) : const _TickerProviderHook(),
  );
}

class _TickerProviderHook extends Hook<TickerProvider> {
  const _TickerProviderHook([List<Object?>? keys]) : super(keys: keys);

  @override
  _TickerProviderHookState createState() => _TickerProviderHookState();
}

class _TickerProviderHookState
    extends HookState<TickerProvider, _TickerProviderHook>
    implements TickerProvider {
  Set<Ticker>? _tickers;
  ValueListenable<bool>? _tickerModeNotifier;

  @override
  Ticker createTicker(TickerCallback onTick) {
    if (_tickerModeNotifier == null) {
      // Setup TickerMode notifier before we vend the first ticker.
      _updateTickerModeNotifier();
    }
    assert(_tickerModeNotifier != null, "TickerMode was not initialized");
    _tickers ??= <Ticker>{};
    final result = Ticker(onTick, debugLabel: "created by $context")
      ..muted = !_tickerModeNotifier!.value;
    _tickers!.add(result);
    return result;
  }

  @override
  void dispose() {
    assert(
      () {
        if (_tickers != null) {
          for (final ticker in _tickers!) {
            if (ticker.isActive) {
              throw FlutterError.fromParts(<DiagnosticsNode>[
                ErrorSummary("$this was disposed with an active Ticker."),
                ErrorDescription(
                  "$runtimeType created a Ticker via its TickerProviderStateMixin, but at the time "
                  "dispose() was called on the mixin, that Ticker was still active. All Tickers must "
                  "be disposed before calling super.dispose().",
                ),
                ErrorHint(
                  "Tickers used by AnimationControllers "
                  "should be disposed by calling dispose() on the AnimationController itself. "
                  "Otherwise, the ticker will leak.",
                ),
                ticker.describeForError("The offending ticker was"),
              ]);
            }
          }
        }
        return true;
      }(),
      "Ticker was not disposed",
    );
    _tickerModeNotifier?.removeListener(_updateTickers);
    _tickerModeNotifier = null;
    super.dispose();
  }

  @override
  TickerProvider build(BuildContext context) {
    _updateTickerModeNotifier();
    _updateTickers();
    return this;
  }

  void _updateTickers() {
    if (_tickers != null) {
      final muted = !_tickerModeNotifier!.value;
      for (final ticker in _tickers!) {
        ticker.muted = muted;
      }
    }
  }

  void _updateTickerModeNotifier() {
    final newNotifier = TickerMode.getNotifier(context);
    if (newNotifier == _tickerModeNotifier) {
      return;
    }
    _tickerModeNotifier?.removeListener(_updateTickers);
    newNotifier.addListener(_updateTickers);
    _tickerModeNotifier = newNotifier;
  }

  @override
  String get debugLabel => "useTickerProvider";

  @override
  bool get debugSkipValue => true;
}
