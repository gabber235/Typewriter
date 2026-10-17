import "package:typewriter_panel/typewriter_panel.dart";

part "cursor_controller.g.dart";

/// Owns the application cursor override used by pointer driven interactions.
///
/// The provider state is the cursor applied by [GlobalCursorController]. Call
/// [cursor] while an interaction is active and [reset] when it releases the
/// pointer.
@riverpod
class CursorController extends _$CursorController {
  @override
  MouseCursor build() {
    return SystemMouseCursors.basic;
  }

  /// Sets the cursor shown across the application.
  // ignore: use_setters_to_change_properties
  void cursor(MouseCursor cursor) {
    state = cursor;
  }

  /// Restores the default basic cursor.
  void reset() {
    state = SystemMouseCursors.basic;
  }
}

/// Applies the cursor from [CursorController] to the entire child subtree.
///
/// Place this near the application root so a drag keeps its cursor even when
/// the pointer leaves the widget that started the interaction.
class GlobalCursorController extends ConsumerWidget {
  const GlobalCursorController({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cursor = ref.watch(cursorControllerProvider);

    return MouseRegion(cursor: cursor, child: child);
  }
}
