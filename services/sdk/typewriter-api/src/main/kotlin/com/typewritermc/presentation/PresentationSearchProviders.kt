package com.typewritermc.presentation

import skirout.editor.v1.presentation.BindingDeclaration
import skirout.editor.v1.presentation.SearchProvider
import skirout.editor.v1.presentation.SearchResultMapping
import skirout.editor.v1.presentation.SearchSelectorDefinition
import skirout.editor.v1.type_catalog.TypeTemplate

/** The type of the rows this provider yields, which the result mapping binds. */
internal fun DefaultSearchProviderSpec<*>.rowType(state: PresentationBuildState): TypeTemplate = description.rowType(state)

private fun SearchProviderDescription<*>.rowType(state: PresentationBuildState): TypeTemplate =
    when (this) {
        is SearchProviderDescription.Static<*> -> {
            requireNotNull(state.itemType(state.lowerInferred(values).second)) { "Static search values must be a list." }
        }

        is SearchProviderDescription.Collection<*> -> {
            source.rowType
        }

        is SearchProviderDescription.HttpJson<*> -> {
            resultType
        }

        is SearchProviderDescription.RealmCallback<*> -> {
            capability.row
        }

        is SearchProviderDescription.Merge<*> -> {
            children.first().rowType(state)
        }
    }

/**
 * Lowers this provider for rows of [rowType]: its sources, then its decorations. Ranking reads the result row, so it
 * is lowered with the row bound.
 */
internal fun DefaultSearchProviderSpec<*>.wire(
    state: PresentationBuildState,
    result: SearchResultMapping,
    selectors: List<SearchSelectorDefinition>,
    rowType: TypeTemplate,
): SearchProvider {
    val source = description.wire(state, result, selectors, rowType)
    return decorations.fold(source) { child, decoration -> decoration.wire(state, child, rowType) }
}

private fun SearchProviderDescription<*>.wire(
    state: PresentationBuildState,
    result: SearchResultMapping,
    selectors: List<SearchSelectorDefinition>,
    rowType: TypeTemplate,
): SearchProvider =
    when (this) {
        is SearchProviderDescription.Static<*> -> {
            SearchProvider.createStaticValues(
                values = state.lower(values, listSlot(rowType)),
                result = result,
                selectors = selectors,
            )
        }

        is SearchProviderDescription.Collection<*> -> {
            state.collection(source)
            require(source.rowType == rowType) { "Merged search providers must yield rows of one type." }
            SearchProvider.createCollection(
                sourceId = source.id,
                result = result,
                where = predicate?.let { where -> state.declareRow(source) { state.lower(where, BOOLEAN_SLOT) } },
                selectors = selectors,
            )
        }

        is SearchProviderDescription.HttpJson<*> -> {
            require(resultType == rowType) { "Merged search providers must yield rows of one type." }
            state.declareContexts(contexts) { bindings ->
                SearchProvider.createHttpJson(
                    uri = state.lower(uri, TEXT_SLOT),
                    parameters =
                        parameters.map { parameter ->
                            skirout.editor.v1.presentation.HttpQueryParameter(
                                name = parameter.name,
                                value = state.lower(parameter.value, TEXT_SLOT),
                                omitIfEmpty = parameter.omitIfEmpty,
                            )
                        },
                    resultPath = resultPath,
                    resultType = resultType,
                    result = result,
                    contextBindings =
                        contexts.zip(bindings) { context, binding ->
                            skirout.editor.v1.presentation
                                .HttpJsonContextBinding(binding = binding, path = context.path)
                        },
                    selectors = selectors,
                    timeoutMilliseconds = timeout.inWholeMilliseconds,
                )
            }
        }

        is SearchProviderDescription.RealmCallback<*> -> {
            require(capability.row == rowType) { "Merged search providers must yield rows of one type." }
            state.capability(capability.id)
            SearchProvider.createRealmCallback(
                capabilityId = capability.id,
                payload = state.lower(payload, capability.payload),
                result = result,
                selectors = selectors,
            )
        }

        is SearchProviderDescription.Merge<*> -> {
            SearchProvider.createMerge(children = children.map { it.wire(state, result, selectors, rowType) })
        }
    }

/** Declares the HTTP context bindings, typed as their declared value types, while [body] lowers the request. */
private fun <R> PresentationBuildState.declareContexts(
    contexts: List<HttpContext>,
    declared: List<BindingDeclaration> = emptyList(),
    body: (List<BindingDeclaration>) -> R,
): R {
    val context = contexts.getOrNull(declared.size) ?: return body(declared)
    return declare(context.binding, context.type, mayBeMissing = false) { binding ->
        declareContexts(contexts, declared + binding, body)
    }
}

private fun SearchDecoration.wire(
    state: PresentationBuildState,
    child: SearchProvider,
    rowType: TypeTemplate,
): SearchProvider =
    when (this) {
        is SearchDecoration.Gate -> {
            SearchProvider.createGate(
                condition = state.lower(condition, BOOLEAN_SLOT),
                guidance = guidance?.let { state.lower(it, TEXT_SLOT) },
                child = child,
            )
        }

        is SearchDecoration.Debounce -> {
            SearchProvider.createDebounce(
                durationMilliseconds = duration.inWholeMilliseconds,
                child = child,
            )
        }

        is SearchDecoration.Cache -> {
            SearchProvider.createCache(
                capacity = capacity,
                retainStaleResults = retainStaleResults,
                child = child,
            )
        }

        is SearchDecoration.Limit -> {
            SearchProvider.createLimit(
                maximum = state.lower(maximum, INT_SLOT),
                child = child,
            )
        }

        SearchDecoration.Distinct -> {
            SearchProvider.createDistinct(child = child)
        }

        is SearchDecoration.History -> {
            SearchProvider.createHistory(
                historyKey = key,
                label = state.lower(label, TEXT_SLOT),
                capacity = capacity,
                child = child,
            )
        }

        is SearchDecoration.Section -> {
            SearchProvider.createSection(
                sectionId = id,
                label = state.lower(label, TEXT_SLOT),
                child = child,
            )
        }

        is SearchDecoration.Rank -> {
            SearchProvider.createRank(
                fields =
                    state.declare(SEARCH_RESULT_ROW, rowType, mayBeMissing = false) {
                        fields.map { field ->
                            skirout.editor.v1.presentation.SearchRankingField(
                                expression = state.lowerInferred(field.expression).first,
                                weight = field.weight,
                            )
                        }
                    },
                child = child,
            )
        }
    }
