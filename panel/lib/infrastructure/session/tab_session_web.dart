import "dart:js_interop";

import "package:typewriter_panel/typewriter_panel.dart";

@JS("sessionStorage")
external _Storage get _sessionStorage;

extension type _Storage._(JSObject _) implements JSObject {
  external String? getItem(String key);
  external void setItem(String key, String value);
}

const _key = "typewriter.session";

/// The session id this browser tab stored, or a new one it stores now.
String platformTabSessionId() {
  final stored = _sessionStorage.getItem(_key);
  if (stored != null) return stored;
  final created = const Uuid().v4();
  _sessionStorage.setItem(_key, created);
  return created;
}
