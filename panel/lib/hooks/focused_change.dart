import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";

void useFocusedChange(
  FocusNode focus,
  Function({required bool hasFocus}) onChange, [
  List<Object?>? keys,
]) {
  useEffect(
    () {
      void onFocusChange() {
        onChange(hasFocus: focus.hasFocus);
      }

      focus.addListener(onFocusChange);
      return () => focus.removeListener(onFocusChange);
    },
    keys ?? [],
  );
}
