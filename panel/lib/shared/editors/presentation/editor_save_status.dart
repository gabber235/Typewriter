import "dart:async";

import "package:flutter/material.dart";
import "package:iconify_flutter_plus/icons/material_symbols.dart";
import "package:typewriter_panel/typewriter_panel.dart";

class EditorSaveStatus extends StatelessWidget {
  const EditorSaveStatus({
    required this.state,
    this.onRetry,
    this.onUseRemote,
    this.onKeepLocal,
    super.key,
  });

  final EditorSaveState state;
  final Future<void> Function()? onRetry;
  final Future<void> Function()? onUseRemote;
  final Future<void> Function()? onKeepLocal;

  @override
  Widget build(BuildContext context) {
    final label = switch (state.phase) {
      EditorSavePhase.idle => null,
      EditorSavePhase.pending => "Pending",
      EditorSavePhase.saving => "Saving",
      EditorSavePhase.saved => "Saved",
      EditorSavePhase.sessionOnly => "Session only",
      EditorSavePhase.failed => "Save failed",
      EditorSavePhase.conflict => "Changed elsewhere",
      EditorSavePhase.repeatedContention => "Changed repeatedly elsewhere",
      EditorSavePhase.deletedElsewhere => "Deleted elsewhere",
    };
    Widget child;
    if (label == null) {
      child = const SizedBox.shrink();
    } else {
      final color = switch (state.phase) {
        EditorSavePhase.failed ||
        EditorSavePhase.conflict ||
        EditorSavePhase.repeatedContention ||
        EditorSavePhase.deletedElsewhere => Theme.of(context).colorScheme.error,
        _ => Theme.of(context).colorScheme.onSurfaceVariant,
      };
      child = Semantics(
        liveRegion: true,
        label: label,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: context.spacing.space2,
          children: [
            if (state.phase == .conflict)
              Row(
                mainAxisSize: MainAxisSize.min,
                spacing: context.spacing.space2,
                children: [
                  LoadingButton.filledIcon(
                    onPressed: onUseRemote,
                    style: TextButton.styleFrom(
                      backgroundColor: context.theme.colorScheme.error,
                    ),
                    icon: const Icones(MaterialSymbols.arrow_upward),
                    label: const Text("Use theirs"),
                  ),
                  LoadingButton.filledIcon(
                    onPressed: onKeepLocal,
                    icon: const Icones(MaterialSymbols.arrow_downward),
                    label: const Text("Keep mine"),
                  ),
                ],
              ),
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: context.spacing.space2,
              children: [
                Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: color),
                ),
                if (state.phase == .failed ||
                    state.phase == .repeatedContention)
                  LoadingIconButton(
                    icon: const Icones(MaterialSymbols.refresh),
                    onPressed: onRetry,
                  ),
              ],
            ),
          ],
        ),
      );
    }

    return ElasticMessageSwitcher(child: child);
  }
}
