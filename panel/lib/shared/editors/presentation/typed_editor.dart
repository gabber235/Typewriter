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
    return EditorSurface(
      source: source,
      path: path,
      registry: registry,
      readOnly: readOnly,
    );
  }
}
