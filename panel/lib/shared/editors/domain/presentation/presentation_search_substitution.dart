part of "presentation_substitution.dart";

extension on SearchInputElement {
  SearchInputElement _substituteTypes(
    Map<String, TypeExpression> substitutions,
  ) => SearchInputElement(
    control: control._substituteTypes(substitutions),
    selectionMode: selectionMode,
    queryBindingId: queryBindingId,
    summaryBindingId: summaryBindingId,
    maximumExtent: maximumExtent._substituteTypes(substitutions),
    provider: provider._substituteTypes(substitutions),
    summary: summary._substituteTypes(substitutions),
    placeholder: placeholder._substituteTypes(substitutions),
    customValue: customValue._substituteTypes(substitutions),
  );
}

extension on SearchProvider {
  SearchProvider _substituteTypes(Map<String, TypeExpression> substitutions) =>
      switch (this) {
        CollectionSearchProvider(
          :final sourceId,
          :final result,
          :final where,
          :final selectors,
        ) =>
          CollectionSearchProvider(
            sourceId: sourceId,
            result: result._substituteTypes(substitutions),
            where: where._substituteTypes(substitutions),
            selectors: selectors,
          ),
        StaticSearchProvider(:final values, :final result, :final selectors) =>
          StaticSearchProvider(
            values: values._substituteTypes(substitutions),
            result: result._substituteTypes(substitutions),
            selectors: selectors,
          ),
        HttpJsonSearchProvider(
          :final uri,
          :final parameters,
          :final resultPath,
          :final resultType,
          :final result,
          :final contextBindings,
          :final selectors,
          :final timeout,
        ) =>
          HttpJsonSearchProvider(
            uri: uri._substituteTypes(substitutions),
            parameters: parameters
                .map(
                  (item) => item.copyWith(
                    value: item.value._substituteTypes(substitutions),
                  ),
                )
                .toList(),
            resultPath: resultPath,
            resultType: resultType.substitute(substitutions),
            result: result._substituteTypes(substitutions),
            contextBindings: contextBindings
                .map(
                  (item) =>
                      item.copyWith(type: item.type.substitute(substitutions)),
                )
                .toList(),
            selectors: selectors,
            timeout: timeout,
          ),
        RealmCallbackSearchProvider(
          :final actionId,
          :final payload,
          :final result,
          :final selectors,
        ) =>
          RealmCallbackSearchProvider(
            actionId: actionId,
            payload: payload._substituteTypes(substitutions),
            result: result._substituteTypes(substitutions),
            selectors: selectors,
          ),
        GatedSearchProvider(:final condition, :final guidance, :final child) =>
          GatedSearchProvider(
            condition: condition._substituteTypes(substitutions),
            guidance: guidance._substituteTypes(substitutions),
            child: child._substituteTypes(substitutions),
          ),
        DebouncedSearchProvider(:final duration, :final child) =>
          DebouncedSearchProvider(
            duration: duration,
            child: child._substituteTypes(substitutions),
          ),
        CachedSearchProvider(
          :final capacity,
          :final retainStaleResults,
          :final child,
        ) =>
          CachedSearchProvider(
            capacity: capacity,
            retainStaleResults: retainStaleResults,
            child: child._substituteTypes(substitutions),
          ),
        RankedSearchProvider(:final fields, :final child) =>
          RankedSearchProvider(
            fields: fields
                .map(
                  (item) => item.copyWith(
                    expression: item.expression._substituteTypes(substitutions),
                  ),
                )
                .toList(),
            child: child._substituteTypes(substitutions),
          ),
        LimitedSearchProvider(:final maximum, :final child) =>
          LimitedSearchProvider(
            maximum: maximum._substituteTypes(substitutions),
            child: child._substituteTypes(substitutions),
          ),
        DistinctSearchProvider(:final child) => DistinctSearchProvider(
          child: child._substituteTypes(substitutions),
        ),
        HistoricalSearchProvider(
          :final key,
          :final label,
          :final capacity,
          :final child,
        ) =>
          HistoricalSearchProvider(
            key: key,
            label: label._substituteTypes(substitutions),
            capacity: capacity,
            child: child._substituteTypes(substitutions),
          ),
        SectionSearchProvider(:final id, :final label, :final child) =>
          SectionSearchProvider(
            id: id,
            label: label._substituteTypes(substitutions),
            child: child._substituteTypes(substitutions),
          ),
        MergedSearchProvider(:final children) => MergedSearchProvider(
          children: children
              .map((child) => child._substituteTypes(substitutions))
              .toList(),
        ),
      };
}

extension on SearchResultMapping {
  SearchResultMapping _substituteTypes(
    Map<String, TypeExpression> substitutions,
  ) => copyWith(
    key: key._substituteTypes(substitutions),
    selectedValue: selectedValue._substituteTypes(substitutions),
    presentation: presentation.substitute(substitutions),
    label: label._substituteTypes(substitutions),
  );
}
