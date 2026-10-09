import "dart:js_interop";

import "work_session_unload_protection.dart";

@JS("window")
external _BrowserWindow get _window;

extension type _BrowserWindow._(JSObject _) implements JSObject {
  external void addEventListener(String type, JSFunction listener);
  external void removeEventListener(String type, JSFunction listener);
}

extension type _BeforeUnloadEvent._(JSObject _) implements JSObject {
  external void preventDefault();
  external String get returnValue;
  external set returnValue(String value);
}

final class PlatformWorkSessionUnloadProtection
    implements WorkSessionUnloadProtection {
  PlatformWorkSessionUnloadProtection();

  late final JSFunction _listener = _onBeforeUnload.toJS;
  bool _protected = false;

  void _onBeforeUnload(JSObject value) {
    if (!_protected) return;
    _BeforeUnloadEvent._(value)
      ..preventDefault()
      ..returnValue = "";
  }

  @override
  bool get protected => _protected;

  @override
  set protected(bool value) {
    if (_protected == value) return;
    _protected = value;
    if (value) {
      _window.addEventListener("beforeunload", _listener);
    } else {
      _window.removeEventListener("beforeunload", _listener);
    }
  }

  @override
  void dispose() {
    if (_protected) _window.removeEventListener("beforeunload", _listener);
    _protected = false;
  }
}
