import "package:flutter/widgets.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

final editorProvider = Provider<EditorSource?>((ref) => null, dependencies: []);

class EditorRoot extends ConsumerWidget {
  const EditorRoot({required this.create, required this.child, super.key});

  final EditorSource Function(Ref ref) create;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ProviderScope(
      overrides: [
        editorProvider.overrideWith((ref) {
          final source = create(ref);
          ref.onDispose(source.dispose);
          return source;
        }),
      ],
      child: child,
    );
  }
}
