import "package:flutter/widgets.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:hooks_riverpod/legacy.dart";
import "package:typewriter_panel/typewriter_panel.dart";

final editorProvider = ChangeNotifierProvider<EditorController?>(
  (ref) => null,
  dependencies: [],
);

class EditorRoot extends ConsumerWidget {
  const EditorRoot({required this.create, required this.child, super.key});

  final EditorController Function(Ref ref) create;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ProviderScope(
      overrides: [editorProvider.overrideWith(create)],
      child: child,
    );
  }
}
