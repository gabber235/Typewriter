import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:iconify_flutter_plus/icons/ic.dart";
import "package:iconify_flutter_plus/icons/material_symbols.dart";
import "package:typewriter_panel/typewriter_panel.dart";

/// Shows the current command outcome for the selected search result.
class SearchCommandInfo extends HookConsumerWidget {
  const SearchCommandInfo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(searchProvider)!;
    final state = controller.commandState;
    final commandId = switch (state) {
      SearchCommandIdle() => null,
      SearchCommandRunning(:final command) => command,
      SearchCommandCompleted(:final command) => command,
      SearchCommandFailed(:final command) => command,
    };
    final command = commandId == null ? null : controller.command(commandId);
    final presentation = command?.presentation;

    final child = switch (state) {
      SearchCommandIdle() => const SizedBox.shrink(key: ValueKey("idle")),
      SearchCommandRunning() => Admonition(
        color: presentation?.color ?? context.colors.info,
        icon: ElasticSwitcher(
          child: Builder(
            builder: (context) {
              final iconTheme = IconTheme.of(context);
              final iconSize = iconTheme.size ?? 24.0;
              return SizedBox(
                width: iconSize,
                height: iconSize,
                child: CircularProgressIndicator(
                  color: iconTheme.color,
                  strokeWidth: 3,
                  padding: EdgeInsets.all(context.spacing.space1),
                ),
              );
            },
          ),
        ),
        child: Text("Running ${presentation?.label ?? "command"}..."),
      ).animate(key: const ValueKey("info")),
      SearchCommandCompleted() =>
        Admonition(
              color: context.colors.success,
              icon: ElasticSwitcher(
                child: Icones(
                  presentation?.icon ?? MaterialSymbols.check_circle_rounded,
                ),
              ),
              child: Text("Completed ${presentation?.label ?? "command"}"),
            )
            .animate(key: const ValueKey("info"))
            .shimmer(
              color: context.colors.success.withValues(alpha: 0.7),
              duration: 750.ms,
              curve: Curves.easeInOutCubic,
            ),
      SearchCommandFailed(:final message) => Admonition(
        color: context.colors.danger,
        icon: ElasticSwitcher(
          child: Icones(presentation?.icon ?? Ic.round_dangerous),
        ),
        child: SelectableText(
          "Failed ${presentation?.label ?? "command"}: $message",
        ),
      ).animate(key: const ValueKey("info")).shakeX(),
    };

    return AnimatedSwitcher(
      duration: 750.ms,
      switchInCurve: Curves.linear,
      switchOutCurve: Curves.linear,
      transitionBuilder: (child, animation) =>
          ElasticTransition(animation: animation, child: child),
      child: child,
    );
  }
}
