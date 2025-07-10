import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

part "cursor_controller.g.dart";

@riverpod
class CursorController extends _$CursorController {
  @override
  SystemMouseCursor build() {
    return SystemMouseCursors.basic;
  }

  // ignore: use_setters_to_change_properties
  void cursor(SystemMouseCursor cursor) {
    state = cursor;
  }

  void reset() {
    state = SystemMouseCursors.basic;
  }
}

/// A widget that provides global cursor control for the entire application.
///
/// This widget should be placed at the root of your widget tree to ensure
/// the cursor is consistent across the entire app, especially during
/// drag operations where the mouse might move outside of specific regions.
class GlobalCursorController extends ConsumerWidget {
  const GlobalCursorController({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cursor = ref.watch(cursorControllerProvider);

    return MouseRegion(
      cursor: cursor,
      child: child,
    );
  }
}
