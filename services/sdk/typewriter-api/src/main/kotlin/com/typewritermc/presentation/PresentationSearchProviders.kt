package com.typewritermc.presentation

import com.typewritermc.expression.Expr
import com.typewritermc.expression.Handled
import com.typewritermc.types.skir.SkirTypeCodec
import com.typewritermc.types.skir.getOrThrow

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
                values = SkirTypeCodec.encode(values).getOrThrow(),
                result = result,
                selectors = selectors,
            )
        }

        is SearchProviderDescription.Collection<*> -> {
            state.collection(source)
            skirout.editor.v1.presentation.SearchProvider.createCollection(
                sourceId = source.id,
                result = result,
                where = predicate?.let { expression(Expr<Any?, Handled>(it)) },
                selectors = selectors,
            )
        }

        is SearchProviderDescription.HttpJson<*> -> {
            skirout.editor.v1.presentation.SearchProvider.createHttpJson(
                uri = expression(Expr<String, Handled>(uri)),
                parameters =
                    parameters.map { parameter ->
                        skirout.editor.v1.presentation.HttpQueryParameter(
                            name = parameter.name,
                            value = expression(Expr<String, Handled>(parameter.value)),
                            omitIfEmpty = parameter.omitIfEmpty,
                        )
                    },
                resultPath = resultPath,
                resultType = SkirTypeCodec.encode(resultType).getOrThrow(),
                result = result,
                contextBindings =
                    contexts.map { context ->
                        skirout.editor.v1.presentation.HttpJsonContextBinding(
                            bindingId = context.binding.wire(),
                            path = context.path,
                            valueType = SkirTypeCodec.encode(context.type).getOrThrow(),
                        )
                    },
                selectors = selectors,
                timeoutMilliseconds = timeout.inWholeMilliseconds,
            )
        }

        is SearchProviderDescription.RealmCallback<*> -> {
            state.capability(capability)
            skirout.editor.v1.presentation.SearchProvider.createRealmCallback(
                capabilityId =
                    skirout.editor.v1.type_catalog
                        .CapabilityId(value = capability.value),
                payload = expression(Expr<Any?, Handled>(payload)),
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
                condition = expression(Expr<Boolean, Handled>(condition)),
                guidance = guidance?.let { expression(Expr<String, Handled>(it)) },
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
                maximum = expression(Expr<Int, Handled>(maximum)),
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
                label = expression(Expr<String, Handled>(label)),
                capacity = capacity,
                child = child,
            )
        }

        is SearchDecoration.Section -> {
            skirout.editor.v1.presentation.SearchProvider.createSection(
                sectionId = id,
                label = expression(Expr<String, Handled>(label)),
                child = child,
            )
        }

        is SearchDecoration.Rank -> {
            skirout.editor.v1.presentation.SearchProvider.createRank(
                fields =
                    fields.map { field ->
                        skirout.editor.v1.presentation.SearchRankingField(
                            expression = expression(Expr<Any?, Handled>(field.expression)),
                            weight = field.weight,
                        )
                    },
                child = child,
            )
        }
    }
