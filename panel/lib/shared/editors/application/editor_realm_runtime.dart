import "dart:async";

import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

final editorRealmRuntimeProvider = Provider<EditorRealmRuntime?>(
  (ref) => null,
  dependencies: [],
);

final class EditorRealmRuntime {
  const EditorRealmRuntime({
    required this.executeAction,
    required this.searchSourceBuilder,
    this.executePanelInstruction,
  });

  final EditorRealmActionExecutor executeAction;
  final RealmPresentationSearchSourceBuilder searchSourceBuilder;
  final FutureOr<void> Function(PanelInstruction instruction)?
  executePanelInstruction;
}
