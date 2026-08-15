part of "editor_presentation_codec.dart";

extension SkirPresentationSearchDecoder on SkirPresentationDecoder {
  TypeResult<PresentationElement> _searchInput(wire.SearchControl value) {
    final control = _bound(value.control);
    final selectionMode = _searchSelectionMode(value.selectionMode);
    final queryBindingId = _searchBindingId(value.queryBindingId.value);
    final summaryBindingId = _searchBindingId(value.summaryBindingId.value);
    final maximumExtent = expressions.decode(value.maximumExtent);
    final provider = _searchProvider(value.provider);
    final placeholder = _optionalExpression(value.placeholder);
    final customValue = _optionalExpression(value.customValue);
    final diagnostics = [
      ...control.diagnostics,
      ...selectionMode.diagnostics,
      ...queryBindingId.diagnostics,
      ...summaryBindingId.diagnostics,
      ...maximumExtent.diagnostics,
      ...provider.diagnostics,
      ...placeholder.diagnostics,
      ...customValue.diagnostics,
    ];
    return diagnostics.isEmpty
        ? TypeResult.success(
            SearchInputElement(
              control: control.valueOrNull!,
              selectionMode: selectionMode.valueOrNull!,
              queryBindingId: queryBindingId.valueOrNull!,
              summaryBindingId: summaryBindingId.valueOrNull!,
              maximumExtent: maximumExtent.valueOrNull!,
              provider: provider.valueOrNull!,
              summary: value.summary == null
                  ? null
                  : decodeNode(value.summary!),
              placeholder: placeholder.valueOrNull,
              customValue: customValue.valueOrNull,
            ),
          )
        : TypeResult.failure(diagnostics);
  }

  TypeResult<SearchSelectionMode> _searchSelectionMode(
    wire.SearchSelectionMode value,
  ) => switch (value) {
    wire.SearchSelectionMode.single => const TypeResult.success(
      SearchSelectionMode.single,
    ),
    wire.SearchSelectionMode.multiple => const TypeResult.success(
      SearchSelectionMode.multiple,
    ),
    wire.SearchSelectionMode_unknown() => invalidWire(
      "Unknown search selection mode",
    ),
  };

  TypeResult<BindingId> _searchBindingId(int value) => value < 0
      ? invalidWire("Search binding ID must not be negative")
      : TypeResult.success(BindingId(value));

  TypeResult<SearchSelectorDefinition> _searchSelector(
    wire.SearchSelectorDefinition value,
  ) {
    final bindingId = _searchBindingId(value.valueBindingId.value);
    final values = _searchSelectorValues(value.values);
    final multiplicity = _searchSelectorMultiplicity(value.multiplicity);
    final diagnostics = [
      ...bindingId.diagnostics,
      ...values.diagnostics,
      ...multiplicity.diagnostics,
    ];
    if (value.selectorId.isEmpty) {
      diagnostics.add(wireDiagnostic("Search selector ID is empty"));
    }
    if (value.key.isEmpty) {
      diagnostics.add(wireDiagnostic("Search selector key is empty"));
    }
    return diagnostics.isEmpty
        ? TypeResult.success(
            SearchSelectorDefinition.keyValue(
              id: value.selectorId,
              key: value.key,
              valueBindingId: bindingId.valueOrNull!,
              values: values.valueOrNull!,
              caseSensitive: value.caseSensitive,
              multiplicity: multiplicity.valueOrNull!,
              colorValue: value.color,
            ),
          )
        : TypeResult.failure(diagnostics);
  }

  TypeResult<SearchSelectorValues> _searchSelectorValues(
    wire.SearchSelectorValues value,
  ) => switch (value) {
    wire.SearchSelectorValues.freeText => const TypeResult.success(
      SearchSelectorValues.freeText(),
    ),
    wire.SearchSelectorValues_enumerationWrapper(:final value) =>
      value.values.isEmpty
          ? invalidWire("Search selector values are empty")
          : TypeResult.success(
              SearchSelectorValues.enumeration(value.values.toList()),
            ),
    wire.SearchSelectorValues_unknown() => invalidWire(
      "Unknown search selector values",
    ),
  };

  TypeResult<SearchSelectorMultiplicity> _searchSelectorMultiplicity(
    wire.SearchSelectorMultiplicity value,
  ) => switch (value) {
    wire.SearchSelectorMultiplicity.single => const TypeResult.success(
      SearchSelectorMultiplicity.single,
    ),
    wire.SearchSelectorMultiplicity.multiple => const TypeResult.success(
      SearchSelectorMultiplicity.multiple,
    ),
    wire.SearchSelectorMultiplicity_unknown() => invalidWire(
      "Unknown search selector multiplicity",
    ),
  };

  TypeResult<SearchResultMapping> _searchResultMapping(
    wire.SearchResultMapping value,
  ) {
    final bindingId = _searchBindingId(value.bindingId.value);
    final key = expressions.decode(value.key);
    final selectedValue = expressions.decode(value.selectedValue);
    final diagnostics = [
      ...bindingId.diagnostics,
      ...key.diagnostics,
      ...selectedValue.diagnostics,
    ];
    return diagnostics.isEmpty
        ? TypeResult.success(
            SearchResultMapping(
              bindingId: bindingId.valueOrNull!,
              key: key.valueOrNull!,
              selectedValue: selectedValue.valueOrNull!,
              presentation: decodeNode(value.presentation),
            ),
          )
        : TypeResult.failure(diagnostics);
  }

  TypeResult<HttpQueryParameter> _httpQueryParameter(
    wire.HttpQueryParameter value,
  ) {
    if (value.name.isEmpty) return invalidWire("Query parameter name is empty");
    return expressions
        .decode(value.value)
        .mapValue(
          (expression) => HttpQueryParameter(
            name: value.name,
            value: expression,
            omitIfEmpty: value.omitIfEmpty,
          ),
        );
  }

  TypeResult<HttpJsonContextBinding> _httpContextBinding(
    wire.HttpJsonContextBinding value,
  ) {
    final bindingId = _searchBindingId(value.bindingId.value);
    final type = types.decodeExpression(value.valueType);
    final diagnostics = [...bindingId.diagnostics, ...type.diagnostics];
    if (value.path.isEmpty) {
      diagnostics.add(wireDiagnostic("Context binding path is empty"));
    }
    return diagnostics.isEmpty
        ? TypeResult.success(
            HttpJsonContextBinding(
              bindingId: bindingId.valueOrNull!,
              path: value.path,
              type: type.valueOrNull!,
            ),
          )
        : TypeResult.failure(diagnostics);
  }

  TypeResult<SearchRankingField> _searchRankingField(
    wire.SearchRankingField value,
  ) {
    if (value.weight <= 0) return invalidWire("Ranking weight is not positive");
    return expressions
        .decode(value.expression)
        .mapValue(
          (expression) =>
              SearchRankingField(expression: expression, weight: value.weight),
        );
  }

  TypeResult<List<T>> _decodeSearchList<W, T>(
    Iterable<W> values,
    TypeResult<T> Function(W value) decode,
  ) {
    final decoded = <T>[];
    final diagnostics = <TypeDiagnostic>[];
    for (final value in values) {
      final result = decode(value);
      diagnostics.addAll(result.diagnostics);
      if (result.valueOrNull case final item?) decoded.add(item);
    }
    return diagnostics.isEmpty
        ? TypeResult.success(decoded)
        : TypeResult.failure(diagnostics);
  }
}
