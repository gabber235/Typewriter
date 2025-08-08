import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";

/// Creates an [GlobalKey].
///
/// See also:
/// - [GlobalKey]
GlobalKey useGlobalKey({String? debugLabel}) {
  return useMemoized(
    () => GlobalKey(debugLabel: debugLabel),
    [],
  );
}
