import "package:typewriter_panel/typewriter_panel.dart";

/// Owns asynchronous execution state for one [LoadingButton] or
/// [LoadingIconButton].
///
/// The widget that binds the controller is responsible for keeping the bound
/// callback current. The controller serializes execution and never disposes
/// resources owned by that callback.
///
/// The widget binds its current callback during build. While the callback is
/// running, [canTrigger] is false and listeners observe [isLoading]. Exceptions
/// are converted to [lastError] and passed to the bound error callback; the
/// callback is always released from loading afterward.
class LoadingButtonController extends ChangeNotifier {
  bool _isLoading = false;
  String? _lastError;
  FutureOr<void> Function()? _onPressed;
  ValueChanged<String>? _onError;

  /// Whether the button is currently loading.
  bool get isLoading => _isLoading;

  /// The most recent callback error, cleared when a new execution starts.
  String? get lastError => _lastError;

  /// Whether a bound callback can start without overlapping an execution.
  bool get canTrigger => _onPressed != null && !_isLoading;

  /// Binds the action and error handler used by the owning button.
  void bind({
    required FutureOr<void> Function()? onPressed,
    required ValueChanged<String>? onError,
  }) {
    _onPressed = onPressed;
    _onError = onError;
  }

  /// Starts the bound callback when it is not already running.
  ///
  /// Returns false when no callback is bound or an execution is in progress.
  /// Completion and failure are observed through this controller.
  bool trigger() {
    if (!canTrigger) return false;

    _handlePress();
    return true;
  }

  /// Runs the bound callback for a press from the owning widget.
  ///
  /// Calls made while another execution is active complete without starting a
  /// second callback.
  Future<void> handlePress() => _handlePress();

  Future<void> _handlePress() async {
    if (_onPressed == null || _isLoading) return;

    _setLoading(true);
    _setError(null);

    try {
      await _onPressed!();
    } on Exception catch (error) {
      _setError(error.toString());
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    if (_isLoading == loading) return;

    _isLoading = loading;
    if (hasListeners) notifyListeners();
  }

  void _setError(String? error) {
    if (_lastError == error) return;

    _lastError = error;
    if (hasListeners) notifyListeners();
    if (error != null) _onError?.call(error);
  }
}
