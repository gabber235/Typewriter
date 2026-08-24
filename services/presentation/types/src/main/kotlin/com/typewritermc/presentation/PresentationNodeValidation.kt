package com.typewritermc.presentation

import skirout.editor.v1.presentation.BoundControl
import skirout.editor.v1.presentation.PresentationConnection
import skirout.editor.v1.presentation.PresentationElement
import skirout.editor.v1.presentation.PresentationHeaderTitle
import skirout.editor.v1.presentation.PresentationNode
import skirout.editor.v1.presentation.SearchProvider
import skirout.editor.v1.presentation.SequencePresentation

internal fun assertUniqueNodeIds(root: PresentationNode) {
    val duplicates =
        root
            .nodes()
            .map(PresentationNode::nodeId)
            .groupingBy { it }
            .eachCount()
            .filterValues { it > 1 }
            .keys
    require(duplicates.isEmpty()) { "Presentation node ids must be unique: ${duplicates.sorted()}." }
}

private fun PresentationNode.nodes(): Sequence<PresentationNode> =
    sequence {
        yield(this@nodes)
        children().forEach { child -> yieldAll(child.nodes()) }
    }

private fun PresentationNode.children(): List<PresentationNode> =
    buildList {
        (header?.title as? PresentationHeaderTitle.PresentationWrapper)?.value?.let(::add)
        when (val element = element) {
            is PresentationElement.ChildrenWrapper -> {
                addAll(element.value.children)
            }

            is PresentationElement.SectionWrapper -> {
                add(element.value.child)
            }

            is PresentationElement.PaddingWrapper -> {
                add(element.value.child)
            }

            is PresentationElement.TabsWrapper -> {
                element.value.tabs.forEach { add(it.child) }
            }

            is PresentationElement.TypedFieldWrapper -> {
                element.value.presentation?.let(::add)
            }

            is PresentationElement.ConditionalWrapper -> {
                add(element.value.whenTrue)
                element.value.whenFalse?.let(::add)
            }

            is PresentationElement.RepeatedWrapper -> {
                addAll(element.value.presentation.nodes())
            }

            is PresentationElement.ScopedBindingWrapper -> {
                add(element.value.child)
            }

            is PresentationElement.CollectionLookupWrapper -> {
                add(element.value.found)
                add(element.value.missing)
                element.value.loading?.let(::add)
            }

            is PresentationElement.CollectionGraphWrapper -> {
                add(element.value.node)
                addAll(element.value.rootSequence.nodes())
                addAll(element.value.children.nodes())
            }

            is PresentationElement.TextInputWrapper -> {
                addPrefix(element.value.control)
            }

            is PresentationElement.NumericInputWrapper -> {
                addPrefix(element.value)
            }

            is PresentationElement.ToggleInputWrapper -> {
                addPrefix(element.value)
            }

            is PresentationElement.SelectInputWrapper -> {
                addPrefix(element.value.control)
            }

            is PresentationElement.SliderInputWrapper -> {
                addPrefix(element.value.control)
            }

            is PresentationElement.DateTimeInputWrapper -> {
                addPrefix(element.value.control)
            }

            is PresentationElement.DurationInputWrapper -> {
                addPrefix(element.value)
            }

            is PresentationElement.ColorInputWrapper -> {
                addPrefix(element.value.control)
            }

            is PresentationElement.BytesInputWrapper -> {
                addPrefix(element.value)
            }

            is PresentationElement.NamedInputWrapper -> {
                addPrefix(element.value)
            }

            is PresentationElement.ListInputWrapper -> {
                addPrefix(element.value.control)
                element.value.itemPresentation?.let(::add)
            }

            is PresentationElement.MapInputWrapper -> {
                addPrefix(element.value.control)
                element.value.keyPresentation?.let(::add)
                element.value.valuePresentation?.let(::add)
            }

            is PresentationElement.RecordInputWrapper -> {
                addPrefix(element.value.control)
                element.value.fieldPresentation?.let(::add)
            }

            is PresentationElement.EnumInputWrapper -> {
                addPrefix(element.value)
            }

            is PresentationElement.PolymorphicInputWrapper -> {
                addPrefix(element.value.control)
                element.value.concreteTypes.mapNotNullTo(this) { it.presentation }
            }

            is PresentationElement.SearchInputWrapper -> {
                addPrefix(element.value.control)
                element.value.summary?.let(::add)
                addAll(element.value.provider.nodes())
            }

            is PresentationElement.TooltipWrapper -> {
                add(element.value.child)
            }

            is PresentationElement.ContainerWrapper -> {
                add(element.value.child)
            }

            is PresentationElement.AnchorWrapper -> {
                add(element.value.child)
            }

            is PresentationElement.ConnectionLayerWrapper -> {
                add(element.value.child)
                element.value.connections.flatMapTo(this) { it.nodes() }
            }

            is PresentationElement.PolymorphicMatchWrapper -> {
                element.value.cases.mapTo(this) { it.child }
                element.value.fallback?.let(::add)
            }

            null -> {
                return@buildList
            }

            else -> {
                return@buildList
            }
        }
    }

private fun MutableList<PresentationNode>.addPrefix(control: BoundControl) {
    control.prefix?.let(::add)
}

private fun SequencePresentation.nodes(): List<PresentationNode> = listOfNotNull(item, empty, separator)

private fun PresentationConnection.nodes(): List<PresentationNode> =
    when (this) {
        is PresentationConnection.ConnectionWrapper -> value.markers.map { it.node }

        is PresentationConnection.BundleWrapper -> (value.trunkMarkers + value.branchMarkers).map { it.node }

        PresentationConnection.UNKNOWN,
        is PresentationConnection.Unknown,
        -> emptyList()
    }

private fun SearchProvider.nodes(): List<PresentationNode> =
    when (this) {
        is SearchProvider.StaticValuesWrapper -> listOf(value.result.presentation)

        is SearchProvider.HttpJsonWrapper -> listOf(value.result.presentation)

        is SearchProvider.RealmCallbackWrapper -> listOf(value.result.presentation)

        is SearchProvider.CollectionWrapper -> listOf(value.result.presentation)

        is SearchProvider.GateWrapper -> value.child.nodes()

        is SearchProvider.DebounceWrapper -> value.child.nodes()

        is SearchProvider.CacheWrapper -> value.child.nodes()

        is SearchProvider.RankWrapper -> value.child.nodes()

        is SearchProvider.LimitWrapper -> value.child.nodes()

        is SearchProvider.DistinctWrapper -> value.child.nodes()

        is SearchProvider.HistoryWrapper -> value.child.nodes()

        is SearchProvider.SectionWrapper -> value.child.nodes()

        is SearchProvider.MergeWrapper -> value.children.flatMap(SearchProvider::nodes)

        SearchProvider.UNKNOWN,
        is SearchProvider.Unknown,
        -> emptyList()
    }
