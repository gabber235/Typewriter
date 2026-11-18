import "tab_session_stub.dart"
    if (dart.library.js_interop) "tab_session_web.dart";

/// The id of this panel's presence session, which the panel engine reports as
/// a session of the signed in user.
///
/// A browser tab keeps it in `sessionStorage`, so a reload continues the
/// session while a new tab starts its own. Other platforms keep one id for the
/// app's lifetime.
String tabSessionId() => platformTabSessionId();
