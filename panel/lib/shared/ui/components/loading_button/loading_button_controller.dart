import "dart:async";

import "package:flutter/foundation.dart";

/// Controls the state and actions of a loading button.
class LoadingButtonController extends ChangeNotifier {
  bool _isLoading = false;
  String? _lastError;
  FutureOr<void> Function()? _onPressed;
  ValueChanged<String>? _onError;

  /// Whether the button is currently loading.
  bool get isLoading => _isLoading;

  /// The last error that occurred, if any.
  String? get lastError => _lastError;

  /// Whether the button can be triggered.
  bool get canTrigger => _onPressed != null && !_isLoading;

  /// Binds the action and error handler used by the owning button.
  void bind({
    required FutureOr<void> Function()? onPressed,
    required ValueChanged<String>? onError,
  }) {
    _onPressed = onPressed;
    _onError = onError;
  }

  /// Programmatically triggers the button action.
  ///
  /// Returns whether the action was triggered.
  bool trigger() {
    if (!canTrigger) return false;

    _handlePress();
    return true;
  }

  /// Handles a press from the owning button.
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
