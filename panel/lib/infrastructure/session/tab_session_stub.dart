import "package:typewriter_panel/typewriter_panel.dart";

final _sessionId = const Uuid().v4();

/// One session id for the app's lifetime.
String platformTabSessionId() => _sessionId;
