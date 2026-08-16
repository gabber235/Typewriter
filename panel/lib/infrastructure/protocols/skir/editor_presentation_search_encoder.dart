part of "editor_presentation_encoder.dart";

extension SkirPresentationSearchEncoder on SkirPresentationEncoder {
  TypeResult<wire.PresentationElement> _searchInput(SearchInputElement value) {
    final control = _bound(value.control);
    final maximumExtent = expressions.encode(value.maximumExtent);
    final provider = _searchProvider(value.provider);
    final summary = value.summary == null
        ? const TypeResult<wire.PresentationNode?>.success(null)
        : encodeNode(value.summary!).mapValue((value) => value);
    final placeholder = _optional(value.placeholder);
    final customValue = _optional(value.customValue);
    final diagnostics = [
      ...control.diagnostics,
      ...maximumExtent.diagnostics,
      ...provider.diagnostics,
      ...summary.diagnostics,
      ...placeholder.diagnostics,
      ...customValue.diagnostics,
    ];
    return diagnostics.isEmpty
        ? TypeResult.success(
            wire.PresentationElement.createSearchInput(
              control: control.valueOrNull!,
              selectionMode: _searchSelectionMode(value.selectionMode),
              queryBindingId: wire_binding.BindingId(
                value: value.queryBindingId.value,
              ),
              summaryBindingId: wire_binding.BindingId(
                value: value.summaryBindingId.value,
              ),
              maximumExtent: maximumExtent.valueOrNull!,
              provider: provider.valueOrNull!,
              summary: summary.valueOrNull,
              placeholder: placeholder.valueOrNull,
              customValue: customValue.valueOrNull,
            ),
          )
        : TypeResult.failure(diagnostics);
  }

  wire.SearchSelectionMode _searchSelectionMode(SearchSelectionMode value) =>
      switch (value) {
        SearchSelectionMode.single => wire.SearchSelectionMode.single,
        SearchSelectionMode.multiple => wire.SearchSelectionMode.multiple,
      };

  wire.SearchSelectorDefinition _searchSelector(
    SearchSelectorDefinition value,
  ) => wire.SearchSelectorDefinition(
    selectorId: value.id,
    key: value.key,
    valueBindingId: wire_binding.BindingId(value: value.valueBindingId.value),
    values: switch (value.values) {
      FreeTextSearchSelectorValues() => wire.SearchSelectorValues.freeText,
      EnumeratedSearchSelectorValues(:final values) =>
        wire.SearchSelectorValues.createEnumeration(values: values),
    },
    caseSensitive: value.caseSensitive,
    multiplicity: switch (value.multiplicity) {
      SearchSelectorMultiplicity.single =>
        wire.SearchSelectorMultiplicity.single,
      SearchSelectorMultiplicity.multiple =>
        wire.SearchSelectorMultiplicity.multiple,
    },
    color: value.colorValue,
  );

  TypeResult<wire.SearchResultMapping> _searchResultMapping(
    SearchResultMapping value,
  ) {
    final key = expressions.encode(value.key);
    final selectedValue = expressions.encode(value.selectedValue);
    final presentation = encodeNode(value.presentation);
    final label = _optional(value.label);
    final diagnostics = [
      ...key.diagnostics,
      ...selectedValue.diagnostics,
      ...presentation.diagnostics,
      ...label.diagnostics,
    ];
    return diagnostics.isEmpty
        ? TypeResult.success(
            wire.SearchResultMapping(
              bindingId: wire_binding.BindingId(value: value.bindingId.value),
              key: key.valueOrNull!,
              selectedValue: selectedValue.valueOrNull!,
              presentation: presentation.valueOrNull!,
              label: label.valueOrNull,
            ),
          )
        : TypeResult.failure(diagnostics);
  }

  TypeResult<wire.HttpQueryParameter> _httpQueryParameter(
    HttpQueryParameter value,
  ) => expressions
      .encode(value.value)
      .mapValue(
        (expression) => wire.HttpQueryParameter(
          name: value.name,
          value: expression,
          omitIfEmpty: value.omitIfEmpty,
        ),
      );

  TypeResult<wire.HttpJsonContextBinding> _httpContextBinding(
    HttpJsonContextBinding value,
  ) => types
      .encodeExpression(value.type)
      .mapValue(
        (type) => wire.HttpJsonContextBinding(
          bindingId: wire_binding.BindingId(value: value.bindingId.value),
          path: value.path,
          valueType: type,
        ),
      );

  TypeResult<wire.SearchRankingField> _searchRankingField(
    SearchRankingField value,
  ) => expressions
      .encode(value.expression)
      .mapValue(
        (expression) => wire.SearchRankingField(
          expression: expression,
          weight: value.weight,
        ),
      );

  TypeResult<List<T>> _encodeSearchList<W, T>(
    Iterable<W> values,
    TypeResult<T> Function(W value) encode,
  ) {
    final encoded = <T>[];
    final diagnostics = <TypeDiagnostic>[];
    for (final value in values) {
      final result = encode(value);
      diagnostics.addAll(result.diagnostics);
      if (result.valueOrNull case final item?) encoded.add(item);
    }
    return diagnostics.isEmpty
        ? TypeResult.success(encoded)
        : TypeResult.failure(diagnostics);
  }
}
