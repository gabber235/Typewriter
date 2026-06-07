import "dart:async";

import "package:flutter/cupertino.dart";
import "package:flutter/material.dart" hide FilledButton;
import "package:flutter/services.dart";
import "package:fuzzy/fuzzy.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter/l10n/app_localizations.dart";
import "package:typewriter/l10n/l10n_provider.dart";
import "package:typewriter/models/entry_blueprint.dart";
import "package:typewriter/utils/extensions.dart";
import "package:typewriter/utils/icons.dart";
import "package:typewriter/utils/passing_reference.dart";
import "package:typewriter/widgets/components/app/cinematic_view.dart";
import "package:typewriter/widgets/components/app/search_bar.dart";
import "package:typewriter/widgets/components/general/admonition.dart";
import "package:typewriter/widgets/components/general/dropdown.dart";
import "package:typewriter/widgets/components/general/iconify.dart";
import "package:typewriter/widgets/inspector/editors.dart";
import "package:typewriter/widgets/inspector/editors/field.dart";
import "package:typewriter/widgets/inspector/header.dart";
import "package:typewriter/widgets/inspector/inspector.dart";

class AlgebraicEditorFilter extends EditorFilter {
  @override
  bool canEdit(DataBlueprint dataBlueprint) =>
      dataBlueprint is AlgebraicBlueprint;

  @override
  Widget build(String path, DataBlueprint dataBlueprint) => AlgebraicEditor(
        path: path,
        algebraicBlueprint: dataBlueprint as AlgebraicBlueprint,
      );

  @override
  (HeaderActions, Iterable<(String, HeaderContext, DataBlueprint)>)
      headerActions(
    Ref<Object?> ref,
    String path,
    DataBlueprint dataBlueprint,
    HeaderContext context,
  ) {
    final algebraicBlueprint = dataBlueprint as AlgebraicBlueprint;

    final selectedCase = ref.watch(fieldValueProvider(path.join("case"), ""));

    if (selectedCase is! String ||
        selectedCase.isEmpty ||
        !algebraicBlueprint.cases.containsKey(selectedCase)) {
      return (const HeaderActions(), []);
    }

    final caseBlueprint = algebraicBlueprint.cases[selectedCase];
    if (caseBlueprint == null) return (const HeaderActions(), []);

    final actions = super.headerActions(ref, path, dataBlueprint, context);
    final child = headerActionsFor(
      ref,
      path.join("value"),
      caseBlueprint,
      context.copyWith(parentBlueprint: dataBlueprint),
    );

    return (actions.$1.merge(child.$1), actions.$2.followedBy(child.$2));
  }
}

class AlgebraicEditor extends HookConsumerWidget {
  const AlgebraicEditor({
    required this.path,
    required this.algebraicBlueprint,
    super.key,
  });

  final String path;
  final AlgebraicBlueprint algebraicBlueprint;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(l10nProvider);
    final selectedCase = ref.watch(fieldValueProvider(path.join("case"), ""));

    if (selectedCase is! String ||
        selectedCase.isEmpty ||
        !algebraicBlueprint.cases.containsKey(selectedCase)) {
      return Admonition.danger(
        onTap: () {
          ref.read(inspectingEntryDefinitionProvider)?.updateField(
                ref.passing,
                path,
                algebraicBlueprint.defaultValue(),
              );
        },
        child: Text.rich(
          TextSpan(
            text: selectedCase is! String || selectedCase.isEmpty
                ? l10n.algebraicEditorInvalidData
                : l10n.algebraicEditorCaseNotFound(selectedCase),
            children: [
              TextSpan(
                text: l10n.valueReset,
                style: TextStyle(
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final caseBlueprint = algebraicBlueprint.cases[selectedCase];
    if (caseBlueprint == null) return const SizedBox.shrink();

    return FieldHeader(
      path: path,
      canExpand: true,
      child: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            _CaseSelector(
              path: path,
              algebraicBlueprint: algebraicBlueprint,
            ),
            const SizedBox(height: 8),
            Header(
              path: path.join("value"),
              expanded: ValueNotifier(true),
              canExpand: false,
              depth: Header.maybeOf(context)?.depth ?? 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: FieldEditor(
                  path: path.join("value"),
                  dataBlueprint: caseBlueprint,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CaseSelector extends HookConsumerWidget {
  const _CaseSelector({
    required this.path,
    required this.algebraicBlueprint,
  });

  final String path;
  final AlgebraicBlueprint algebraicBlueprint;

  Future<bool> _selectCase(PassingRef ref, String? caseName) async {
    final caseBlueprint = algebraicBlueprint.cases[caseName];
    if (caseBlueprint == null) return false;

    await ref.read(inspectingEntryDefinitionProvider)?.updateField(
      ref,
      path,
      {
        "case": caseName,
        "value": caseBlueprint.defaultValue(),
      },
    );
    return true;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cases = algebraicBlueprint.cases;
    final selectedCase = ref.watch(fieldValueProvider(path.join("case")));
    final caseBlueprint = cases[selectedCase];
    if (caseBlueprint == null) return const SizedBox.shrink();

    if (cases.length == 1) {
      return SizedBox.shrink();
    }

    if (cases.length <= 3) {
      final hexColor = caseBlueprint.get<String?>("color") ?? "#009688";
      final color = colorConverter.fromJson(hexColor) ?? Colors.teal;

      return Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: CupertinoSlidingSegmentedControl<String>(
          groupValue: selectedCase,
          thumbColor: color,
          onValueChanged: (value) => _selectCase(ref.passing, value),
          children: {
            for (final casing in cases.entries)
              casing.key: _buildCase(casing.key, casing.value, centered: true),
          },
        ),
      );
    }

    if (cases.length < 10) {
      return Dropdown<String>(
        value: selectedCase,
        values: cases.keys.toList(),
        onChanged: (value) => _selectCase(ref.passing, value),
        icon: null,
        builder: (context, value) => _buildCase(value, cases[value]!),
      );
    }

    return Material(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      color: Theme.of(context).inputDecorationTheme.fillColor,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          ref.read(searchProvider.notifier).asBuilder()
            ..fetchAlgebraic(
              algebraicBlueprint: algebraicBlueprint,
              onSelect: (caseName, caseBlueprint) =>
                  _selectCase(ref.passing, caseName),
            )
            ..open();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              _buildCase(selectedCase, caseBlueprint),
              const Spacer(),
              const Iconify(
                TWIcons.caretDown,
                size: 16,
                color: Color(0xFFBEBEBE),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCase(
    String caseName,
    DataBlueprint caseBlueprint, {
    bool centered = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment:
          centered ? MainAxisAlignment.center : MainAxisAlignment.start,
      children: [
        if (caseBlueprint.get<String?>("icon") != null) ...[
          Iconify(
            caseBlueprint.get<String>("icon"),
            size: 18,
          ),
          const SizedBox(width: 8),
        ],
        Text(caseName.titleCase()),
      ],
    );
  }
}

class _AlgebraicSearchFetcher extends SearchFetcher {
  _AlgebraicSearchFetcher({
    required this.algebraicBlueprint,
    this.onSelect,
    this.disabled = false,
  }) : _fuzzy = Fuzzy(
          algebraicBlueprint.cases.entries.toList(),
          options: FuzzyOptions(
            keys: [
              WeightedKey(
                name: "name",
                getter: (casing) => casing.key.titleCase(),
                weight: 1,
              ),
            ],
          ),
        );

  final AlgebraicBlueprint algebraicBlueprint;
  final FutureOr<bool?> Function(String, DataBlueprint)? onSelect;

  @override
  final bool disabled;

  final Fuzzy<MapEntry<String, DataBlueprint>> _fuzzy;

  @override
  String title(AppLocalizations l10n) => l10n.selectCase;

  @override
  List<SearchElement> fetch(PassingRef ref, String query) {
    final results = _fuzzy.search(query);

    return results
        .map(
          (result) => _AlgebraicSearchElement(
            caseName: result.item.key,
            caseBlueprint: result.item.value,
            onSelect: onSelect,
          ),
        )
        .toList();
  }

  @override
  SearchFetcher copyWith({bool? disabled}) => _AlgebraicSearchFetcher(
        algebraicBlueprint: algebraicBlueprint,
        onSelect: onSelect,
        disabled: disabled ?? this.disabled,
      );
}

class _AlgebraicSearchElement extends SearchElement {
  _AlgebraicSearchElement({
    required this.caseName,
    required this.caseBlueprint,
    this.onSelect,
  });

  final String caseName;
  final DataBlueprint caseBlueprint;
  final FutureOr<bool?> Function(String, DataBlueprint)? onSelect;

  @override
  String title(AppLocalizations l10n, PassingRef ref) => caseName.titleCase();

  @override
  Color color(BuildContext context) {
    final hexColor = caseBlueprint.get<String?>("color") ?? "#009688";
    return colorConverter.fromJson(hexColor) ?? Colors.teal;
  }

  @override
  String description(BuildContext context, PassingRef ref) {
    final l10n = context.l10n;
    return l10n.setCaseType(caseName.titleCase());
  }

  @override
  Widget icon(BuildContext context) => Iconify(
        caseBlueprint.get<String>("icon"),
        size: 18,
      );

  @override
  Widget suffixIcon(BuildContext context) =>
      const Iconify(TWIcons.externalLink);

  @override
  List<SearchAction> actions(AppLocalizations l10n, PassingRef ref) {
    return [
      SearchAction(
        l10n.select,
        TWIcons.check,
        SingleActivator(LogicalKeyboardKey.enter),
      ),
    ];
  }

  @override
  Future<bool> activate(BuildContext context, PassingRef ref) async {
    return await onSelect?.call(caseName, caseBlueprint) ?? true;
  }
}

extension _AlgebraicSearchBuilderX on SearchBuilder {
  void fetchAlgebraic({
    required AlgebraicBlueprint algebraicBlueprint,
    FutureOr<bool?> Function(String, DataBlueprint)? onSelect,
    bool disabled = false,
  }) =>
      fetch(
        _AlgebraicSearchFetcher(
          onSelect: onSelect,
          disabled: disabled,
          algebraicBlueprint: algebraicBlueprint,
        ),
      );
}
