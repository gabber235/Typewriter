package com.typewritermc.presentation

internal fun DefaultSearchProviderSpec<*>.wire(
    state: PresentationBuildState,
    result: skirout.editor.v1.presentation.SearchResultMapping,
    selectors: List<skirout.editor.v1.presentation.SearchSelectorDefinition>,
): skirout.editor.v1.presentation.SearchProvider {
    val source = description.wire(state, result, selectors)
    return decorations.fold(source) { child, decoration -> decoration.wire(child) }
}

private fun SearchProviderDescription<*>.wire(
    state: PresentationBuildState,
    result: skirout.editor.v1.presentation.SearchResultMapping,
    selectors: List<skirout.editor.v1.presentation.SearchSelectorDefinition>,
): skirout.editor.v1.presentation.SearchProvider =
    when (this) {
        is SearchProviderDescription.Static<*> -> {
            skirout.editor.v1.presentation.SearchProvider.createStaticValues(
                values = values,
                result = result,
                selectors = selectors,
            )
        }

        is SearchProviderDescription.Collection<*> -> {
            state.collection(source)
            skirout.editor.v1.presentation.SearchProvider.createCollection(
                sourceId = source.id,
                result = result,
                where = predicate?.let { it },
                selectors = selectors,
            )
        }

        is SearchProviderDescription.HttpJson<*> -> {
            skirout.editor.v1.presentation.SearchProvider.createHttpJson(
                uri = uri,
                parameters =
                    parameters.map { parameter ->
                        skirout.editor.v1.presentation.HttpQueryParameter(
                            name = parameter.name,
                            value = parameter.value,
                            omitIfEmpty = parameter.omitIfEmpty,
                        )
                    },
                resultPath = resultPath,
                resultType = resultType,
                result = result,
                contextBindings =
                    contexts.map { context ->
                        skirout.editor.v1.presentation.HttpJsonContextBinding(
                            binding =
                                skirout.editor.v1.presentation
                                    .BindingDeclaration(id = context.binding, type = context.type),
                            path = context.path,
                        )
                    },
                selectors = selectors,
                timeoutMilliseconds = timeout.inWholeMilliseconds,
            )
        }

        is SearchProviderDescription.RealmCallback<*> -> {
            state.capability(capability)
            skirout.editor.v1.presentation.SearchProvider.createRealmCallback(
                capabilityId = capability,
                payload = payload,
                result = result,
                selectors = selectors,
            )
        }

        is SearchProviderDescription.Merge<*> -> {
            skirout.editor.v1.presentation.SearchProvider.createMerge(
                children = children.map { it.wire(state, result, selectors) },
            )
        }
    }

private fun SearchDecoration.wire(child: skirout.editor.v1.presentation.SearchProvider): skirout.editor.v1.presentation.SearchProvider =
    when (this) {
        is SearchDecoration.Gate -> {
            skirout.editor.v1.presentation.SearchProvider.createGate(
                condition = condition,
                guidance = guidance?.let { it },
                child = child,
            )
        }

        is SearchDecoration.Debounce -> {
            skirout.editor.v1.presentation.SearchProvider.createDebounce(
                durationMilliseconds = duration.inWholeMilliseconds,
                child = child,
            )
        }

        is SearchDecoration.Cache -> {
            skirout.editor.v1.presentation.SearchProvider.createCache(
                capacity = capacity,
                retainStaleResults = retainStaleResults,
                child = child,
            )
        }

        is SearchDecoration.Limit -> {
            skirout.editor.v1.presentation.SearchProvider.createLimit(
                maximum = maximum,
                child = child,
            )
        }

        SearchDecoration.Distinct -> {
            skirout.editor.v1.presentation.SearchProvider
                .createDistinct(child = child)
        }

        is SearchDecoration.History -> {
            skirout.editor.v1.presentation.SearchProvider.createHistory(
                historyKey = key,
                label = label,
                capacity = capacity,
                child = child,
            )
        }

        is SearchDecoration.Section -> {
            skirout.editor.v1.presentation.SearchProvider.createSection(
                sectionId = id,
                label = label,
                child = child,
            )
        }

        is SearchDecoration.Rank -> {
            skirout.editor.v1.presentation.SearchProvider.createRank(
                fields =
                    fields.map { field ->
                        skirout.editor.v1.presentation.SearchRankingField(
                            expression = field.expression,
                            weight = field.weight,
                        )
                    },
                child = child,
            )
        }
    }
