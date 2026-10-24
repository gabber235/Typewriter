import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "authored_type_picker.freezed.dart";

@freezed
sealed class AuthoredTypeUseCandidate with _$AuthoredTypeUseCandidate {
  const factory AuthoredTypeUseCandidate.selection(
    skir.TypeSelection selection,
  ) = AuthoredTypeSelectionCandidate;

  const factory AuthoredTypeUseCandidate.direct(skir.TypeUse type) =
      AuthoredDirectTypeUseCandidate;
}

Future<skir.TypeUse?> showAuthoredTypeUsePicker(
  BuildContext context, {
  required String title,
  required CheckedEditorCatalog catalog,
}) async {
  final selectionOperations = SelectionOperationsRoot.of(context);
  final candidates = _typeUseSearchCandidates(catalog);
  final selected = await showTypeSearch(
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
          source: selectionOperations,
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
  String initialQuery = "",
  ValueChanged<String>? onQueryChanged,
  VoidCallback? onBack,
  Future<void>? cancelled,
}) {
  final candidates = catalog.concreteRecordSelections(expected)
    ..sort(
      (left, right) => catalog
          .typeSelectionName(left)
          .compareTo(catalog.typeSelectionName(right)),
    );
  if (candidates.length == 1) return Future.value(candidates.single);
  return showTypeSearch(
    context,
    searchHint: "Search resource types",
    initialQuery: initialQuery,
    onQueryChanged: onQueryChanged,
    onBack: onBack,
    cancelled: cancelled,
    candidates: candidates,
    id: _selectionSearchId,
    label: catalog.typeSelectionName,
    display: catalog.selectionDisplay,
  );
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
    final arguments = argumentSelections(_selection, parameters.length);
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

String _selectionSearchId(skir.TypeSelection selection) => base64Url
    .encode(skir.TypeSelection.serializer.toBytes(selection))
    .replaceAll("=", "");

String _typeUseSearchId(skir.TypeUse type) =>
    base64Url.encode(skir.TypeUse.serializer.toBytes(type)).replaceAll("=", "");
