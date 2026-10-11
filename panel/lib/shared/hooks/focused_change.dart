import "package:typewriter_panel/typewriter_panel.dart";

/// Calls [onChange] whenever [focus] changes focus state.
///
/// The listener is attached for the lifetime of this hook and removed during
/// cleanup. It does not invoke [onChange] for the initial state; call the
/// callback separately when an initial notification is required. [keys]
/// controls when the listener is rebound, so include dependencies captured by
/// [onChange] when they can change.
void useFocusedChange(
  FocusNode focus,
  Function({required bool hasFocus}) onChange, [
  List<Object?>? keys,
]) {
  useEffect(() {
    void onFocusChange() {
      onChange(hasFocus: focus.hasFocus);
    }

    focus.addListener(onFocusChange);
    return () => focus.removeListener(onFocusChange);
  }, keys ?? []);
}
