import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

typedef AuthoredTypePreview =
    Future<skir.PreviewTypeArgumentChangeResponse> Function(
      skir.TypeSelection requested,
    );
typedef AuthoredTypeCommit = Future<EditStageResult> Function(
  skir.TypeArgumentChangePreview preview,
);

/// Keeps tentative type arguments outside the authored document until the user
/// reviews Realm repair effects. The caller owns preparation and staging of the
/// accepted preview; this widget reports that local admission result, not saved
/// or published state. Catalog checking owns type argument admissibility.
final class AuthoredTypeArgumentEditor extends StatefulWidget {
  const AuthoredTypeArgumentEditor({
    required this.selection,
    required this.catalog,
    required this.preview,
    required this.commit,
    this.enabled = true,
    this.disabledMessage,
    this.onStatus,
    super.key,
  });

  final skir.TypeSelection selection;
  final CheckedEditorCatalog catalog;
  final AuthoredTypePreview preview;
  final AuthoredTypeCommit commit;
  final bool enabled;
  final String? disabledMessage;
  final ValueChanged<String>? onStatus;

  @override
  State<AuthoredTypeArgumentEditor> createState() =>
      _AuthoredTypeArgumentEditorState();
}

final class _AuthoredTypeArgumentEditorState
    extends State<AuthoredTypeArgumentEditor> {
  late skir.TypeSelection _selection = widget.selection;
  String? _error;
  bool _working = false;

  @override
  void didUpdateWidget(covariant AuthoredTypeArgumentEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selection != oldWidget.selection) {
      _selection = widget.selection;
      _error = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final published = widget.catalog.selected(_selection);
    final parameters = published?.definition.parameters.toList() ?? const [];
    if (parameters.isEmpty) return const SizedBox.shrink();
    final arguments = argumentSelections(_selection, parameters.length);
    final changed = _selection != widget.selection;
    final pending = arguments.any(
      (argument) => argument == skir.ArgumentSelection.unfilled,
    );
    return Card(
      margin: EdgeInsets.only(bottom: context.spacing.space3),
      child: Padding(
        padding: EdgeInsets.all(context.spacing.space3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Type arguments",
              style: Theme.of(context).textTheme.titleSmall,
            ),
            SizedBox(height: context.spacing.space2),
            for (final item in parameters.indexed)
              _argumentRow(
                context,
                index: item.$1,
                parameter: item.$2,
                argument: arguments[item.$1],
              ),
            if (pending)
              Padding(
                padding: EdgeInsets.only(top: context.spacing.space2),
                child: Text(
                  "This unfinished selection can be saved. Existing independent fields remain editable.",
                ),
              ),
            if (!widget.enabled && widget.disabledMessage != null)
              Padding(
                padding: EdgeInsets.only(top: context.spacing.space2),
                child: Text(widget.disabledMessage!),
              ),
            if (_error case final error?)
              Padding(
                padding: EdgeInsets.only(top: context.spacing.space2),
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    error,
                    style: context.theme.textTheme.bodyMedium?.copyWith(
                      color: context.colors.danger,
                    ),
                  ),
                ),
              ),
            if (changed) ...[
              SizedBox(height: context.spacing.space2),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: FilledButton(
                  onPressed: _working || !widget.enabled
                      ? null
                      : () => _preview(_selection),
                  child: Text(_working ? "Checking" : "Review type change"),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _argumentRow(
    BuildContext context, {
    required int index,
    required skir.TypeParameter parameter,
    required skir.ArgumentSelection argument,
  }) {
    final chosen = switch (argument) {
      skir.ArgumentSelection_chosenWrapper(:final value) => value,
      _ => null,
    };
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.spacing.space1),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(parameter.name)),
          Expanded(
            child: OutlinedButton(
              onPressed: _working || !widget.enabled
                  ? null
                  : () => _choose(index, parameter.name),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  chosen == null
                      ? "Choose a type"
                      : widget.catalog.typeUseName(chosen),
                ),
              ),
            ),
          ),
          if (chosen != null)
            IconButton(
              tooltip: "Clear ${parameter.name}",
              onPressed: _working || !widget.enabled
                  ? null
                  : () => setState(() {
                      _selection = widget.catalog.clearArgument(
                        _selection,
                        index,
                      );
                      _error = null;
                    }),
              icon: const Icon(Icons.close),
            ),
        ],
      ),
    );
  }

  Future<void> _choose(int index, String name) async {
    final chosen = await showAuthoredTypeUsePicker(
      context,
      title: "Choose $name",
      catalog: widget.catalog,
    );
    if (chosen == null || !mounted) return;
    switch (widget.catalog.chooseArgument(_selection, index, chosen)) {
      case TypeArgumentAccepted(:final selection):
        setState(() {
          _selection = selection;
          _error = null;
        });
      case TypeArgumentRejected(:final message):
        setState(() => _error = message);
    }
  }

  Future<void> _preview(skir.TypeSelection requested) async {
    setState(() {
      _working = true;
      _error = null;
    });
    try {
      final result = await widget.preview(requested);
      if (!mounted) return;
      switch (result) {
        case skir.PreviewTypeArgumentChangeResponse_readyWrapper(:final value):
          final accepted = await showDialog<bool>(
            context: context,
            builder: (context) =>
                _TypeRepairReview(preview: value, catalog: widget.catalog),
          );
          if (accepted == true && mounted) await _commit(value);
        case skir.PreviewTypeArgumentChangeResponse_incompleteWrapper(
          :final value,
        ):
          setState(
            () => _error =
                "${value.length} type arguments still need a selection",
          );
        case skir.PreviewTypeArgumentChangeResponse_invalidArgumentsErrorWrapper(
          :final value,
        ):
          setState(() => _error = value.map((item) => item.code).join("\n"));
        case skir.PreviewTypeArgumentChangeResponse_rejectedErrorWrapper(
          :final value,
        ):
          setState(() => _error = value.map((item) => item.code).join("\n"));
        default:
          setState(() => _error = "The type change preview is unavailable");
      }
    } on Object catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _commit(skir.TypeArgumentChangePreview preview) async {
    final response = await widget.commit(preview);
    if (!mounted) return;
    final message = switch (response) {
      EditStaged() => "Type arguments staged",
      EditUnchanged() => "Type arguments are unchanged",
      EditStageRejected(:final message) => message,
    };
    setState(() => _error = response is EditStageRejected ? message : null);
    widget.onStatus?.call(message);
  }
}

final class _TypeRepairReview extends StatelessWidget {
  const _TypeRepairReview({required this.preview, required this.catalog});

  final skir.TypeArgumentChangePreview preview;
  final CheckedEditorCatalog catalog;

  @override
  Widget build(BuildContext context) {
    final clears = preview.clearedLocations.toList(growable: false);
    final linkRepairs = preview.linkRepairs.toList(growable: false);
    return AlertDialog(
      title: const Text("Review type change"),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("New type: ${catalog.typeSelectionName(preview.next)}"),
            SizedBox(height: context.spacing.space2),
            Text("Values cleared: ${clears.length}"),
            for (final location in clears)
              Text(
                "${location.resource.value} ${_valuePathLabel(location.path)}",
              ),
            SizedBox(height: context.spacing.space2),
            Text("Links repaired: ${linkRepairs.length}"),
            Text("Value repairs: ${preview.edit.intents.length}"),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text("Cancel"),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text("Apply type change"),
        ),
      ],
    );
  }
}

String _valuePathLabel(skir.ValuePath path) => path.segments
    .map(
      (segment) => switch (segment) {
        skir.PathSegment_fieldWrapper(:final value) => value.name,
        skir.PathSegment_itemWrapper(:final value) => value.id.value,
        _ => "?",
      },
    )
    .join(".");
