import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "authored_type_argument_editor.freezed.dart";

typedef AuthoredTypePreview = Future<skir.TypePreviewResult> Function(
  skir.TypeSelection requested,
);
typedef AuthoredTypeCommit =
    Future<skir.CommitTypeArgumentChangeResponse> Function(
      skir.TypeArgumentChangePreview preview,
    );

@freezed
sealed class AuthoredTypeUseCandidate with _$AuthoredTypeUseCandidate {
  const factory AuthoredTypeUseCandidate.selection(
    skir.TypeSelection selection,
  ) = AuthoredTypeSelectionCandidate;

  const factory AuthoredTypeUseCandidate.direct(skir.TypeUse type) =
      AuthoredDirectTypeUseCandidate;
}

const _authoredTypeSearchResultType = SearchResultType(
  id: "authoring.type",
  rowRendererId: "authoring.type",
  label: "Type",
);

Future<T?> showAuthoredTypeSearch<T extends Object>(
  BuildContext context, {
  required String searchHint,
  required Iterable<T> candidates,
  required String Function(T candidate) id,
  required String Function(T candidate) label,
  skir.TypeDisplay? Function(T candidate)? display,
}) {
  final values = List<T>.unmodifiable(candidates);
  final identities = <String>{};
  for (final candidate in values) {
    final identity = id(candidate);
    if (identity.isEmpty) {
      throw ArgumentError.value(
        identity,
        "id",
        "Type identity must not be empty",
      );
    }
    if (!identities.add(identity)) {
      throw ArgumentError.value(
        identity,
        "id",
        "Type identities must be unique",
      );
    }
  }
  return showSearchModal<T>(
    context,
    (_, _) => SearchContribution(
      session: SearchSession(
        source: _AuthoredTypeSearchSource(
          candidates: values,
          id: id,
          label: label,
          display: display,
        ),
        interaction: SearchInteraction(
          activation: SearchActivation.custom(
            dependencies: const [],
            evaluate: (_, _) => const SearchActivationState.enabled(),
            activate: (_, result) async =>
                SearchActivationResult.complete(result.payload as T),
          ),
          selectionMode: SearchSelectionMode.single,
        ),
      ),
    ),
    searchHint: searchHint,
    rowRenderers: {
      _authoredTypeSearchResultType.rowRendererId: (row) {
        final candidate = row.result.payload as T;
        return _AuthoredTypeSearchResultItem(
          label: label(candidate),
          display: display?.call(candidate),
          selected: row.selected,
          focused: row.focused,
          onTap: row.onTap,
          shortcutActivator: row.shortcutActivator,
        );
      },
    },
  );
}

Future<skir.TypeUse?> showAuthoredTypeUsePicker(
  BuildContext context, {
  required String title,
  required CheckedEditorCatalog catalog,
}) async {
  final selectionOperations = SelectionOperationsRoot.of(context);
  final candidates = _typeUseSearchCandidates(catalog);
  final selected = await showAuthoredTypeSearch(
    context,
    searchHint: title,
    candidates: candidates,
    id: (candidate) => switch (candidate) {
      AuthoredTypeSelectionCandidate(:final selection) =>
        "selection:${_selectionSearchId(selection)}",
      AuthoredDirectTypeUseCandidate(:final type) =>
        "use:${_typeUseSearchId(type)}",
    },
    label: (candidate) => switch (candidate) {
      AuthoredTypeSelectionCandidate(:final selection) =>
        catalog.typeSelectionName(selection),
      AuthoredDirectTypeUseCandidate(:final type) => catalog.typeUseName(type),
    },
    display: (candidate) => switch (candidate) {
      AuthoredTypeSelectionCandidate(:final selection) =>
        catalog.selectionDisplay(selection),
      AuthoredDirectTypeUseCandidate(:final type) => _typeUseDisplay(
        catalog,
        type,
      ),
    },
  );
  if (selected == null || !context.mounted) return null;
  return switch (selected) {
    AuthoredDirectTypeUseCandidate(:final type) => type,
    AuthoredTypeSelectionCandidate(:final selection) => switch (selection) {
      skir.TypeSelection_completeWrapper(:final value) =>
        skir.TypeUse.wrapNamed(value),
      skir.TypeSelection_pendingWrapper() => showDialog<skir.TypeUse>(
        context: context,
        barrierDismissible: false,
        builder: (context) => SelectionOperationsRoot(
          operations: selectionOperations,
          child: _TypeUseCompositionPicker(
            title: title,
            selection: selection,
            catalog: catalog,
          ),
        ),
      ),
      _ => null,
    },
  };
}

List<AuthoredTypeUseCandidate> _typeUseSearchCandidates(
  CheckedEditorCatalog catalog,
) {
  final candidates = <AuthoredTypeUseCandidate>[];
  for (final published in catalog.snapshot.types) {
    if (published.status != skir.DeclarationStatus.ready) continue;
    final selection = catalog.beginSelection(published.definition.id);
    if (selection == skir.TypeSelection.unknown) continue;
    candidates.add(AuthoredTypeUseCandidate.selection(selection));
    if (selection case skir.TypeSelection_completeWrapper(:final value)) {
      final nullable = skir.TypeUse.createNullable(
        value: skir.TypeUse.wrapNamed(value),
      );
      candidates.add(AuthoredTypeUseCandidate.direct(nullable));
    }
  }
  for (final scalar in _authoredScalarTypes) {
    for (final type in [
      skir.TypeUse.wrapScalar(scalar),
      skir.TypeUse.createNullable(value: skir.TypeUse.wrapScalar(scalar)),
    ]) {
      candidates.add(AuthoredTypeUseCandidate.direct(type));
    }
  }
  return List.unmodifiable(candidates);
}

skir.TypeDisplay? _typeUseDisplay(
  CheckedEditorCatalog catalog,
  skir.TypeUse type,
) => switch (type) {
  skir.TypeUse_namedWrapper(:final value) => catalog.typeDisplay(
    value.definition,
  ),
  skir.TypeUse_nullableWrapper(:final value) => _typeUseDisplay(
    catalog,
    value.value,
  ),
  _ => null,
};

final _authoredScalarTypes = <skir.ScalarKind>[
  skir.ScalarKind.unit,
  skir.ScalarKind.boolean,
  skir.ScalarKind.text,
  skir.ScalarKind.bytes,
  skir.ScalarKind.decimal,
  skir.ScalarKind.timestamp,
  skir.ScalarKind.duration,
  for (final width in [
    skir.IntegerWidth.signedEight,
    skir.IntegerWidth.signedSixteen,
    skir.IntegerWidth.signedThirtyTwo,
    skir.IntegerWidth.signedSixtyFour,
    skir.IntegerWidth.unsignedEight,
    skir.IntegerWidth.unsignedSixteen,
    skir.IntegerWidth.unsignedThirtyTwo,
    skir.IntegerWidth.unsignedSixtyFour,
  ])
    skir.ScalarKind.createInteger(width: width),
  skir.ScalarKind.createFloat(width: skir.FloatWidth.thirtyTwo),
  skir.ScalarKind.createFloat(width: skir.FloatWidth.sixtyFour),
];

Future<skir.TypeSelection?> showCreationConcreteTypePicker(
  BuildContext context, {
  required skir.TypeSelection expected,
  required CheckedEditorCatalog catalog,
}) {
  final candidates = catalog.concreteRecordSelections(expected)
    ..sort(
      (left, right) => catalog
          .typeSelectionName(left)
          .compareTo(catalog.typeSelectionName(right)),
    );
  if (candidates.length == 1) return Future.value(candidates.single);
  return showAuthoredTypeSearch(
    context,
    searchHint: "Search resource types",
    candidates: candidates,
    id: _selectionSearchId,
    label: catalog.typeSelectionName,
    display: catalog.selectionDisplay,
  );
}

final class _AuthoredTypeSearchSource<T extends Object>
    implements SearchSource {
  _AuthoredTypeSearchSource({
    required Iterable<T> candidates,
    required this.id,
    required this.label,
    required this.display,
  }) : candidates = List<T>.unmodifiable(candidates);

  final List<T> candidates;
  final String Function(T candidate) id;
  final String Function(T candidate) label;
  final skir.TypeDisplay? Function(T candidate)? display;
  final _snapshots = StreamController<SearchSourceSnapshot>.broadcast(
    sync: true,
  );
  bool _disposed = false;

  @override
  Stream<SearchSourceSnapshot> get snapshots => _snapshots.stream;

  @override
  List<QuerySelectorDefinition> get selectors => const [];

  @override
  void initialize(SearchQueryContext context) => search(context);

  @override
  void search(SearchQueryContext context) {
    if (_disposed) return;
    final term = context.normalizedQuery.trim().toLowerCase();
    final matches =
        candidates
            .where((candidate) {
              if (term.isEmpty) return true;
              final metadata = display?.call(candidate);
              return label(candidate).toLowerCase().contains(term) ||
                  (metadata?.description.toLowerCase().contains(term) ?? false);
            })
            .toList(growable: false)
          ..sort((left, right) => label(left).compareTo(label(right)));
    _snapshots.add(
      SearchSourceSnapshot.ready(
        nodes: [
          for (final candidate in matches)
            SearchNode.result(
              result: SearchResult(
                id: id(candidate),
                type: _authoredTypeSearchResultType,
                payload: candidate,
                title: label(candidate),
                subtitle: display?.call(candidate)?.description,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Future<SearchPreviewRequestResult> preview(
    SearchPreviewRequest request,
  ) async => const SearchPreviewRequestResult.error(
    message: "Type choices do not provide a separate preview",
  );

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    unawaited(_snapshots.close());
  }
}

final class _AuthoredTypeSearchResultItem extends StatelessWidget {
  const _AuthoredTypeSearchResultItem({
    required this.label,
    required this.display,
    required this.selected,
    required this.focused,
    required this.onTap,
    required this.shortcutActivator,
  });

  final String label;
  final skir.TypeDisplay? display;
  final bool selected;
  final bool focused;
  final VoidCallback onTap;
  final ShortcutActivator? shortcutActivator;

  @override
  Widget build(BuildContext context) {
    final color =
        display?.color._parsedColor ?? Theme.of(context).colorScheme.primary;
    final icon = display?.icon.trim();
    final description = display?.description.trim();
    return SearchResultCard(
      color: color,
      prefix: SearchResultIconTile(
        color: color,
        onColor: color.on(context),
        icon: icon == null || icon.isEmpty
            ? const Icon(Icons.category_outlined)
            : Icones(icon),
        focused: focused,
      ),
      selected: selected,
      focused: focused,
      onTap: onTap,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: context.spacing.space1,
        children: [
          SearchResultTitle(title: label),
          if (description != null && description.isNotEmpty)
            SearchResultDescription(description: description),
        ],
      ),
      suffix: SearchResultSuffix(
        label: "type",
        shortcutActivator: shortcutActivator,
        selected: selected,
      ),
    );
  }
}

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
    final arguments = _argumentSelections(_selection, parameters.length);
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
        case skir.TypePreviewResult_readyWrapper(:final value):
          final accepted = await showDialog<bool>(
            context: context,
            builder: (context) =>
                _TypeRepairReview(preview: value, catalog: widget.catalog),
          );
          if (accepted == true && mounted) await _commit(value);
        case skir.TypePreviewResult_incompleteWrapper(:final value):
          setState(
            () => _error =
                "${value.length} type arguments still need a selection",
          );
        case skir.TypePreviewResult_invalidArgumentsWrapper(:final value):
          setState(() => _error = value.map((item) => item.code).join("\n"));
        case skir.TypePreviewResult_rejectedWrapper(:final value):
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
      skir.CommitTypeArgumentChangeResponse_resultWrapper(
        value: skir.CommitResult.committed,
      ) =>
        "Type arguments updated",
      skir.CommitTypeArgumentChangeResponse_resultWrapper(
        value: skir.CommitResult_conflictWrapper(),
      ) =>
        "The resource changed before the type update was saved",
      skir.CommitTypeArgumentChangeResponse_resultWrapper(
        value: skir.CommitResult_catalogChangedWrapper(),
      ) =>
        "The editor catalog changed before the type update was saved",
      skir.CommitTypeArgumentChangeResponse_resultWrapper(
        value: skir.CommitResult_rejectedWrapper(),
      ) =>
        "The Realm rejected the type update",
      _ => "The type update result is unavailable",
    };
    setState(
      () => _error = message == "Type arguments updated" ? null : message,
    );
    widget.onStatus?.call(message);
  }
}

final class _TypeUseCompositionPicker extends StatefulWidget {
  const _TypeUseCompositionPicker({
    required this.title,
    required this.selection,
    required this.catalog,
  });

  final String title;
  final skir.TypeSelection selection;
  final CheckedEditorCatalog catalog;

  @override
  State<_TypeUseCompositionPicker> createState() =>
      _TypeUseCompositionPickerState();
}

final class _TypeUseCompositionPickerState
    extends State<_TypeUseCompositionPicker> {
  late skir.TypeSelection _selection = widget.selection;
  bool _nullable = false;

  @override
  Widget build(BuildContext context) {
    final selectedDefinition = widget.catalog.selected(_selection);
    final parameters =
        selectedDefinition?.definition.parameters.toList() ?? const [];
    final arguments = _argumentSelections(_selection, parameters.length);
    final complete = switch (_selection) {
      skir.TypeSelection_completeWrapper(:final value) =>
        _nullable
            ? skir.TypeUse.createNullable(value: skir.TypeUse.wrapNamed(value))
            : skir.TypeUse.wrapNamed(value),
      _ => null,
    };
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.catalog.typeSelectionName(_selection),
                style: context.theme.textTheme.titleSmall,
              ),
              for (final item in parameters.indexed)
                Padding(
                  padding: EdgeInsets.only(top: context.spacing.space2),
                  child: OutlinedButton(
                    onPressed: () => _chooseNested(item.$1, item.$2.name),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(switch (arguments[item.$1]) {
                        skir.ArgumentSelection_chosenWrapper(:final value) =>
                          "${item.$2.name}: ${widget.catalog.typeUseName(value)}",
                        _ => "${item.$2.name}: Choose a type",
                      }),
                    ),
                  ),
                ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text("Allow no value"),
                value: _nullable,
                onChanged: (value) => setState(() => _nullable = value),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Cancel"),
        ),
        FilledButton(
          onPressed: complete == null
              ? null
              : () => Navigator.of(context).pop(complete),
          child: const Text("Choose"),
        ),
      ],
    );
  }

  Future<void> _chooseNested(int index, String name) async {
    final chosen = await showAuthoredTypeUsePicker(
      context,
      title: "Choose $name",
      catalog: widget.catalog,
    );
    if (chosen == null || !mounted) return;
    switch (widget.catalog.chooseArgument(_selection, index, chosen)) {
      case TypeArgumentAccepted(:final selection):
        setState(() => _selection = selection);
      case TypeArgumentRejected(:final message):
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
    }
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
            Text("Value repairs: ${preview.intents.length}"),
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

List<skir.ArgumentSelection> _argumentSelections(
  skir.TypeSelection selection,
  int count,
) {
  final values = switch (selection) {
    skir.TypeSelection_completeWrapper(:final value) => [
      for (final argument in value.arguments)
        skir.ArgumentSelection.wrapChosen(argument),
    ],
    skir.TypeSelection_pendingWrapper(:final value) => value.arguments.toList(),
    _ => <skir.ArgumentSelection>[],
  };
  return List.generate(
    count,
    (index) =>
        index < values.length ? values[index] : skir.ArgumentSelection.unfilled,
  );
}

String _selectionSearchId(skir.TypeSelection selection) => base64Url
    .encode(skir.TypeSelection.serializer.toBytes(selection))
    .replaceAll("=", "");

String _typeUseSearchId(skir.TypeUse type) =>
    base64Url.encode(skir.TypeUse.serializer.toBytes(type)).replaceAll("=", "");

extension on String {
  Color? get _parsedColor {
    if (trim().isEmpty) return null;
    try {
      return parseColorHex(this, includeAlpha: true);
    } on FormatException {
      return null;
    }
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
