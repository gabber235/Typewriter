import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:iconify_flutter_plus/icons/ic.dart";
import "package:iconify_flutter_plus/icons/material_symbols.dart";
import "package:typewriter_panel/typewriter_panel.dart";

class SearchActionInfo extends HookConsumerWidget {
  const SearchActionInfo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(searchProvider)!;

    final actionState = controller.actionState;
    final actionType = switch (actionState) {
      SearchActionIdle() => null,
      SearchActionRunning(:final action) => action,
      SearchActionCompleted(:final action) => action,
      SearchActionFailed(:final action) => action,
    };
    final action = actionType != null
        ? controller.snapshot.actions[actionType]
        : null;

    final child = switch (actionState) {
      SearchActionIdle() => const SizedBox.shrink(key: ValueKey("idle")),
      SearchActionRunning() => Admonition(
        color: action!.color ?? Colors.blue,
        icon: ElasticSwitcher(
          child: Builder(
            builder: (context) {
              final iconTheme = IconTheme.of(context);
              final iconSize = iconTheme.size ?? 24.0;
              final color = iconTheme.color;
              return SizedBox(
                width: iconSize,
                height: iconSize,
                child: CircularProgressIndicator(
                  color: color,
                  strokeWidth: 3,
                  padding: const EdgeInsets.all(4),
                ),
              );
            },
          ),
        ),
        child: Text("Running ${action.label}..."),
      ).animate(key: ValueKey("info")),
      SearchActionCompleted() =>
        Admonition(
              color: Colors.green,
              icon: ElasticSwitcher(
                child: Icones(
                  action!.icon ?? MaterialSymbols.check_circle_rounded,
                ),
              ),
              child: Text("Completed ${action.label}"),
            )
            .animate(key: ValueKey("info"))
            .shimmer(
              color: Colors.green.withValues(alpha: 0.7),
              duration: 750.ms,
              curve: Curves.easeInOutCubic,
            ),
      SearchActionFailed(:final message) => Admonition(
        color: Colors.red,
        icon: ElasticSwitcher(
          child: Icones(action!.icon ?? Ic.round_dangerous),
        ),
        child: SelectableText("Failed ${action.label}: $message"),
      ).animate(key: ValueKey("info")).shakeX(),
    };

    return AnimatedSwitcher(
      duration: 750.ms,
      switchInCurve: Curves.linear,
      switchOutCurve: Curves.linear,
      child: child,
      transitionBuilder: (child, animation) {
        return ElasticTransition(animation: animation, child: child);
      },
    );
  }
}
