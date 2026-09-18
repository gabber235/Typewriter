import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/kernel/v1/record_id.dart";
import "package:typewriter_panel/typewriter_panel.dart";

Future<DataValue?> promptElementCreationEditor({
  required BuildContext context,
  required String title,
  required CreationDraft draft,
  required List<PresentationDefinition> presentations,
  required List<RecordId> origins,
}) => showAdvancedDialog<DataValue>(
  context: context,
  fullscreenDialog: context.isMobile,
  builder: (dialogContext) => ElementCreationDialog(
    title: title,
    draft: draft,
    presentations: presentations,
    origins: origins,
    onCancel: () => Navigator.of(dialogContext).pop(),
    onCreate: (value) => Navigator.of(dialogContext).pop(value),
  ),
);

/// Places an element creation editor in the panel's adaptive modal surface.
///
/// Compact screens use the complete safe area. Larger screens use a bounded
/// modal whose child receives finite constraints without intrinsic sizing.
final class ElementCreationDialog extends StatelessWidget {
  const ElementCreationDialog({
    required this.title,
    required this.draft,
    required this.presentations,
    required this.origins,
    required this.onCancel,
    required this.onCreate,
    super.key,
  });

  final String title;
  final CreationDraft draft;
  final List<PresentationDefinition> presentations;
  final List<RecordId> origins;
  final VoidCallback onCancel;
  final ValueChanged<DataValue> onCreate;

  @override
  Widget build(BuildContext context) {
    final editor = ElementCreationEditor(
      title: title,
      draft: draft,
      presentations: presentations,
      origins: origins,
      onCancel: onCancel,
      onCreate: onCreate,
    );
    if (context.isMobile) {
      return Dialog.fullscreen(child: SafeArea(child: editor));
    }
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      constraints: const BoxConstraints(maxWidth: 840, maxHeight: 900),
      clipBehavior: Clip.antiAlias,
      child: SizedBox.expand(child: editor),
    );
  }
}

/// Renders the ordinary element editor over one incomplete local draft.
///
/// The draft owns all temporary state. Creation becomes available only after
/// finalization produces one valid canonical value.
final class ElementCreationEditor extends ConsumerStatefulWidget {
  const ElementCreationEditor({
    required this.title,
    required this.draft,
    required this.presentations,
    required this.origins,
    required this.onCancel,
    required this.onCreate,
    super.key,
  });

  final String title;
  final CreationDraft draft;
  final List<PresentationDefinition> presentations;
  final List<RecordId> origins;
  final VoidCallback onCancel;
  final ValueChanged<DataValue> onCreate;

  @override
  ConsumerState<ElementCreationEditor> createState() =>
      _ElementCreationEditorState();
}

final class _ElementCreationEditorState
    extends ConsumerState<ElementCreationEditor> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.draft.addListener(_changed);
  }

  @override
  void didUpdateWidget(ElementCreationEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.draft == widget.draft) return;
    oldWidget.draft.removeListener(_changed);
    widget.draft.addListener(_changed);
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final runtime = ref.watch(editorRealmRuntimeProvider);
    final result = widget.draft.finalize();
    final value = result.valueOrNull;
    final model = PresentationModel.editor(
      owner: widget.draft,
      presentations: widget.presentations,
      diagnostics: result.diagnostics,
    ).withEntryIdentityEditor();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: Text(
            widget.title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        Expanded(
          child: Scrollbar(
            controller: _scrollController,
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(24),
              child: ComposedEditor(
                model: model,
                host: runtime?.host() ?? const EditorHostCapabilities(),
                referenceOrigins: widget.origins,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: OverflowBar(
            alignment: MainAxisAlignment.end,
            spacing: 8,
            overflowAlignment: OverflowBarAlignment.end,
            children: [
              TextButton(
                onPressed: widget.onCancel,
                child: const Text("Cancel"),
              ),
              FilledButton(
                onPressed: value == null ? null : () => widget.onCreate(value),
                child: const Text("Create"),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    widget.draft.removeListener(_changed);
    _scrollController.dispose();
    super.dispose();
  }
}
