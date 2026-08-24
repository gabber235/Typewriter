import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

class TypedEditor extends ConsumerWidget {
  const TypedEditor({
    this.path = DataPath.root,
    this.registry,
    this.readOnly = false,
    super.key,
  });

  final DataPath path;
  final TypeRegistry? registry;
  final bool readOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final source = ref.watch(editorProvider);
    if (source == null) return const SizedBox.shrink();
    final realmRuntime = ref.watch(editorRealmRuntimeProvider);
    return EditorSurface(
      source: source,
      path: path,
      registry: registry,
      readOnly: readOnly,
      realmSearchSourceBuilder: realmRuntime?.searchSourceBuilder,
      executePanelInstruction: realmRuntime == null
          ? null
          : (instruction) =>
                _executePanelInstruction(context, realmRuntime, instruction),
    );
  }
}

Future<void> _executePanelInstruction(
  BuildContext context,
  EditorRealmRuntime runtime,
  PanelInstruction instruction,
) async {
  final executor = runtime.executePanelInstruction;
  if (executor != null) {
    await executor(instruction);
    return;
  }
  switch (instruction) {
    case NotifyInstruction(:final severity, :final message):
      switch (severity) {
        case NotificationSeverity.success:
          showSuccessSnackBar(context, message);
        case NotificationSeverity.error:
          showErrorSnackBar(context, message);
        case NotificationSeverity.info || NotificationSeverity.warning:
          showSnackBar(context, message: message);
      }
    case InvalidateResourceInstruction():
      showErrorSnackBar(
        context,
        "Resource invalidation is not supported by this editor",
      );
    case OpenResourceInstruction():
      showErrorSnackBar(
        context,
        "Opening typed resources is not supported by this editor",
      );
  }
}
