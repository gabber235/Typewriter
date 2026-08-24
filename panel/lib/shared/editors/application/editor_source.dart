import "package:flutter/foundation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

abstract interface class EditorSource implements Listenable {
  EditorDocument? get document;

  EditorValue value(DataPath path);

  EditorMutationResult update(DataPath path, DataValue value);

  void refreshDocument(EditorDocument document);

  EditorInteractionSession beginInteraction(DataPath path);

  EditorSaveState saveState(DataPath path);

  Future<TypedMutationResult> flush({Set<DataPath>? paths});

  Future<EditorActionResult> executeAction(
    EditorAction action,
    ExpressionContext context,
    Map<BindingId, BindingReference> aliases,
  );

  void acceptRemote({required int revision, required DataValue value});

  void acceptRemoteDeletion();

  void useRemote(DataPath path);

  Future<TypedMutationResult> keepLocal(DataPath path);

  void dispose();
}
