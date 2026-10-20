package com.typewritermc.presentation

import com.typewritermc.types.PresentationId
import com.typewritermc.types.PresentationRole
import com.typewritermc.types.TypeTemplate
import skirout.editor.v1.binding.BindingRef
import skirout.editor.v1.presentation.AxisChild
import skirout.editor.v1.presentation.BoundControl
import skirout.editor.v1.presentation.ChildrenElement
import skirout.editor.v1.presentation.PresentationConnection
import skirout.editor.v1.presentation.PresentationDependencies
import skirout.editor.v1.presentation.PresentationElement
import skirout.editor.v1.presentation.PresentationHeaderTitle
import skirout.editor.v1.presentation.PresentationNode
import skirout.editor.v1.presentation.SearchProvider
import skirout.editor.v1.presentation.SequencePresentation
import skirout.editor.v1.presentation.StackChild

data class PresentationMaterial(
    val provider: PresentationId,
    val target: PresentationTarget,
    val subject: TypeTemplate,
    val role: PresentationRole,
    val layout: PresentationNode,
    val dependencies: PresentationDependencies,
    val inheritableNodes: List<String> = emptyList(),
)

/**
 * References the reusable view of this canonical layout, retaining neutral groups and their layout settings.
 * Controls keep their own field editors. Named parts form atomic boundaries, including their conditions and actions.
 * Plain default requests supply positions without supplying field behavior.
 */
fun PresentationNode.inferInheritableNodes(dependencies: PresentationDependencies = PresentationDependencies.partial()): List<String> {
    val control = element?.boundControl()
    if (control != null) {
        val field = control.binding.directConfiguredField() ?: return emptyList()
        if (!writesWithinOwner(field, dependencies)) return emptyList()
        return listOf(nodeId)
    }
    if (header != null || properties.enabledIf != null || properties.readOnly) return emptyList()
    return when (val selected = element) {
        is PresentationElement.PartWrapper, is PresentationElement.RemainingFieldsWrapper -> {
            listOf(nodeId)
        }

        is PresentationElement.ChildrenWrapper -> {
            val descendants = buildList { addChildren(selected.value) }.flatMap { it.inferInheritableNodes(dependencies) }
            if (descendants.isEmpty()) emptyList() else listOf(nodeId) + descendants
        }

        else -> {
            emptyList()
        }
    }
}

/**
 * Checks published membership against source inference and validates explicit reusable declarations.
 * Unsupported local layout stays local. Explicit declarations with unsafe ancestry or editor ownership are errors.
 */
fun PresentationNode.validateInheritableNodes(
    references: List<String>,
    dependencies: PresentationDependencies = PresentationDependencies.partial(),
    partOwnerCompatible: (skirout.editor.v1.presentation.PresentationPartId) -> Boolean = { true },
    fieldExists: (String) -> Boolean,
) {
    require(references == inferInheritableNodes(dependencies)) { "Inheritable nodes must match the inferred canonical layout." }
    val nodes = allNodes().toList()
    val occurrences = nodes.groupBy(PresentationNode::nodeId)
    require(occurrences.values.all { values -> values.all { it == values.first() } }) {
        "Presentation node ids must not identify distinct nodes."
    }
    require(references.distinct().size == references.size) { "Inheritable node ids must be unique." }
    val indexed = occurrences.mapValues { it.value.first() }
    val membership = references.toSet()
    val declared = mutableSetOf<skirout.editor.v1.presentation.PresentationPartId>()
    references.forEach { id ->
        val node = requireNotNull(indexed[id]) { "Inheritable node $id must identify one layout node." }
        node.element?.boundControl()?.let { control ->
            val field = control.binding.directConfiguredField()
            require(field != null && fieldExists(field)) { "Inheritable node $id must target an existing direct owner field." }
        }
    }
    nodes.forEach { node ->
        val exclusions = (node.element as? PresentationElement.RemainingFieldsWrapper)?.value?.excludedParts.orEmpty()
        exclusions.forEach { key ->
            require(key.name.isNotBlank()) { "Excluded presentation part names must not be blank." }
            if (node.nodeId in membership) {
                require(partOwnerCompatible(key)) { "Excluded presentation part ${key.name} has an incompatible declaring owner." }
            }
        }
        val part = (node.element as? PresentationElement.PartWrapper)?.value ?: return@forEach
        require(part.key.name.isNotBlank()) { "Presentation part names must not be blank." }
        if (node.nodeId in membership) {
            require(partOwnerCompatible(part.key)) { "Presentation part ${part.key.name} has an incompatible declaring owner." }
        }
        val body = part.body
        if (body != null) {
            require(node.nodeId in membership) { "Presentation part declarations require neutral owner layout groups." }
            require(declared.add(part.key)) { "Presentation part ${part.key.name} has multiple definitions in one material." }
            require(body.writesWithinOwner(null, dependencies, partOwnerCompatible)) {
                "Presentation part ${part.key.name} must have bounded editors within its owner record and no owner remainder."
            }
        }
    }
}

private fun BindingRef.directConfiguredField(): String? {
    if (bindingId.value != "configured_value") return null
    return (path.segments.singleOrNull() as? skirout.editor.v1.type_catalog.PathSegment.FieldWrapper)?.value?.name
}

private enum class FieldWriteScope { Record, Field, Foreign }

private fun PresentationNode.writesWithinOwner(
    field: String?,
    dependencies: PresentationDependencies,
    partOwnerCompatible: (skirout.editor.v1.presentation.PresentationPartId) -> Boolean = { true },
): Boolean {
    val sources = dependencies.collections.associateBy { it.sourceId }

    fun BindingRef.writeScope(bindings: Map<String, FieldWriteScope>): FieldWriteScope =
        when (val scope = bindings[bindingId.value] ?: FieldWriteScope.Foreign) {
            FieldWriteScope.Record -> {
                if (path.segments.isEmpty()) {
                    FieldWriteScope.Record
                } else if ((path.segments.firstOrNull() as? skirout.editor.v1.type_catalog.PathSegment.FieldWrapper)
                        ?.value
                        ?.name
                        ?.let { field == null || it == field } == true
                ) {
                    FieldWriteScope.Field
                } else {
                    FieldWriteScope.Foreign
                }
            }

            else -> {
                scope
            }
        }

    fun visit(
        node: PresentationNode,
        bindings: Map<String, FieldWriteScope>,
    ): Boolean {
        val control = node.element?.boundControl()
        if (control != null && control.binding.writeScope(bindings) != FieldWriteScope.Field) return false
        if (node.header?.items.orEmpty().any { item ->
                item is skirout.editor.v1.presentation.HeaderItem.ReorderHandleWrapper &&
                    item.value.source.writeScope(bindings) != FieldWriteScope.Field
            }
        ) {
            return false
        }
        if (!node.decorations().all { visit(it, bindings) }) return false

        fun child(
            child: PresentationNode?,
            nested: Map<String, FieldWriteScope> = bindings,
        ): Boolean = child == null || visit(child, nested)
        return when (val element = node.element) {
            is PresentationElement.ScopedBindingWrapper -> {
                child(element.value.child, bindings + (element.value.scopeBindingId.value to element.value.binding.writeScope(bindings)))
            }

            is PresentationElement.PolymorphicMatchWrapper -> {
                val value = element.value
                val nested = bindings + (value.scopeBindingId.value to value.binding.writeScope(bindings))
                value.cases.all { child(it.child, nested) } && child(value.fallback)
            }

            is PresentationElement.PolymorphicInputWrapper -> {
                val nested =
                    bindings + (
                        "configured_value" to
                            element.value.control.binding
                                .writeScope(bindings)
                    )
                element.value.concreteTypes.all { child(it.presentation, nested) }
            }

            is PresentationElement.ListInputWrapper -> {
                val value = element.value
                child(
                    value.itemPresentation,
                    bindings +
                        mapOf(
                            value.itemBindingId.value to value.control.binding.writeScope(bindings),
                            value.indexBindingId.value to FieldWriteScope.Foreign,
                        ),
                )
            }

            is PresentationElement.SetInputWrapper -> {
                child(
                    element.value.itemPresentation,
                    bindings + (
                        element.value.itemBindingId.value to
                            element.value.control.binding
                                .writeScope(bindings)
                    ),
                )
            }

            is PresentationElement.MapInputWrapper -> {
                val value = element.value
                val scope = value.control.binding.writeScope(bindings)
                child(value.keyPresentation, bindings + (value.keyBindingId.value to scope)) &&
                    child(value.valuePresentation, bindings + (value.valueBindingId.value to scope))
            }

            is PresentationElement.RepeatedWrapper -> {
                val value = element.value
                val source = (value.source as? skirout.editor.v1.expression.ExpressionNode.InputWrapper)?.value
                val scope =
                    source?.let { BindingRef(bindingId = it.binding, path = it.path).writeScope(bindings) } ?: FieldWriteScope.Foreign
                child(value.presentation.item, bindings + (value.itemBindingId.value to scope)) &&
                    child(value.presentation.empty) && child(value.presentation.separator)
            }

            is PresentationElement.CollectionLookupWrapper -> {
                val value = element.value
                val row = sources[value.sourceId]?.rowBindingId?.value
                val nested =
                    if (row ==
                        null
                    ) {
                        bindings.mapValues { FieldWriteScope.Foreign }
                    } else {
                        bindings + (row to FieldWriteScope.Foreign)
                    }
                child(value.found, nested) && child(value.missing) && child(value.loading)
            }

            is PresentationElement.CollectionGraphWrapper -> {
                val value = element.value
                val row = sources[value.sourceId]?.rowBindingId?.value
                val nested =
                    bindings +
                        buildMap {
                            if (row != null) put(row, FieldWriteScope.Foreign)
                            put(value.childrenBindingId.value, FieldWriteScope.Foreign)
                        }
                child(value.node, nested) && child(value.rootSequence.item, nested) &&
                    child(value.children.item, nested + (value.childBindingId.value to FieldWriteScope.Foreign)) &&
                    listOf(
                        value.rootSequence.empty,
                        value.rootSequence.separator,
                        value.children.empty,
                        value.children.separator,
                    ).all { child(it) }
            }

            is PresentationElement.SearchInputWrapper -> {
                val value = element.value

                fun result(
                    result: skirout.editor.v1.presentation.SearchResultMapping,
                    nested: Map<String, FieldWriteScope>,
                ): Boolean {
                    val scoped = nested + (result.bindingId.value to FieldWriteScope.Foreign)
                    return child(result.presentation, scoped)
                }

                val queryBindings = bindings + (value.queryBindingId.value to FieldWriteScope.Foreign)

                fun provider(source: SearchProvider): Boolean =
                    when (source) {
                        is SearchProvider.StaticValuesWrapper -> {
                            result(source.value.result, queryBindings)
                        }

                        is SearchProvider.CollectionWrapper -> {
                            result(source.value.result, queryBindings)
                        }

                        is SearchProvider.RealmCallbackWrapper -> {
                            result(source.value.result, queryBindings)
                        }

                        is SearchProvider.HttpJsonWrapper -> {
                            result(
                                source.value.result,
                                queryBindings +
                                    source.value.contextBindings.associate {
                                        it.bindingId.value to FieldWriteScope.Foreign
                                    },
                            )
                        }

                        is SearchProvider.GateWrapper -> {
                            provider(source.value.child)
                        }

                        is SearchProvider.DebounceWrapper -> {
                            provider(source.value.child)
                        }

                        is SearchProvider.CacheWrapper -> {
                            provider(source.value.child)
                        }

                        is SearchProvider.RankWrapper -> {
                            provider(source.value.child)
                        }

                        is SearchProvider.LimitWrapper -> {
                            provider(source.value.child)
                        }

                        is SearchProvider.DistinctWrapper -> {
                            provider(source.value.child)
                        }

                        is SearchProvider.HistoryWrapper -> {
                            provider(source.value.child)
                        }

                        is SearchProvider.SectionWrapper -> {
                            provider(source.value.child)
                        }

                        is SearchProvider.MergeWrapper -> {
                            source.value.children.all { provider(it) }
                        }

                        else -> {
                            true
                        }
                    }
                child(value.empty) && child(value.loading) &&
                    child(value.summary, bindings + (value.summaryBindingId.value to FieldWriteScope.Foreign)) && provider(value.provider)
            }

            is PresentationElement.ResourcesWrapper -> {
                val layout = element.value.layout as? skirout.editor.v1.presentation.ResourcesLayout.TreeWrapper
                child(
                    layout?.value?.group,
                    bindings + (
                        layout
                            ?.value
                            ?.groupBindingId
                            ?.value
                            .orEmpty() to FieldWriteScope.Foreign
                    ),
                )
            }

            is PresentationElement.PartWrapper -> {
                val scope = bindings["configured_value"]
                field == null && scope != null && scope != FieldWriteScope.Foreign &&
                    (scope != FieldWriteScope.Record || partOwnerCompatible(element.value.key)) && child(element.value.body)
            }

            is PresentationElement.RemainingFieldsWrapper -> {
                bindings["configured_value"] == FieldWriteScope.Field
            }

            is PresentationElement.InvocationWrapper -> {
                val arguments = element.value.arguments
                if (arguments.isEmpty()) {
                    bindings["configured_value"] == FieldWriteScope.Field
                } else {
                    var nested = bindings
                    val owned =
                        arguments.all { argument ->
                            val scope = argument.binding.writeScope(nested)
                            nested = nested + (argument.input.value to scope)
                            scope == FieldWriteScope.Field
                        }
                    owned && nested["configured_value"] == FieldWriteScope.Field
                }
            }

            else -> {
                node.bodyChildren().all { child(it) }
            }
        }
    }

    return visit(this, mapOf("configured_value" to FieldWriteScope.Record))
}

private fun PresentationNode.allNodes(): List<PresentationNode> =
    listOf(this) + (decorations() + bodyChildren()).flatMap(PresentationNode::allNodes)

private fun PresentationNode.decorations(): List<PresentationNode> =
    buildList {
        (header?.title as? PresentationHeaderTitle.PresentationWrapper)?.value?.let(::add)
        element?.boundControl()?.prefix?.let(::add)
        when (val element = element) {
            is PresentationElement.TextInputWrapper -> {
                addInputContent(element.value.content)
            }

            is PresentationElement.NumericInputWrapper -> {
                addInputContent(element.value.content)
            }

            is PresentationElement.SelectInputWrapper -> {
                addInputContent(element.value.content)
            }

            is PresentationElement.DateTimeInputWrapper -> {
                addInputContent(element.value.content)
            }

            is PresentationElement.DurationInputWrapper -> {
                addInputContent(element.value.content)
            }

            is PresentationElement.ColorInputWrapper -> {
                addInputContent(element.value.content)
            }

            is PresentationElement.BytesInputWrapper -> {
                addInputContent(element.value.content)
            }

            is PresentationElement.EnumInputWrapper -> {
                addInputContent(element.value.content)
            }

            is PresentationElement.SearchInputWrapper -> {
                addInputContent(element.value.content)
            }

            is PresentationElement.NamedInputWrapper -> {
                addCollectionContent(element.value.content)
            }

            is PresentationElement.ListInputWrapper -> {
                addCollectionContent(element.value.content)
            }

            is PresentationElement.SetInputWrapper -> {
                addCollectionContent(element.value.content)
            }

            is PresentationElement.MapInputWrapper -> {
                addCollectionContent(element.value.content)
            }

            is PresentationElement.RecordInputWrapper -> {
                addCollectionContent(element.value.content)
            }

            is PresentationElement.PolymorphicInputWrapper -> {
                addInputContent(element.value.inputContent)
                addCollectionContent(element.value.content)
            }

            is PresentationElement.LinkInputWrapper -> {
                addInputContent(element.value.inputContent)
                addCollectionContent(element.value.content)
            }

            is PresentationElement.TabsWrapper -> {
                element.value.tabs.mapNotNullTo(this) { it.icon }
            }

            is PresentationElement.ButtonWrapper -> {
                element.value.icon?.let(::add)
            }

            is PresentationElement.MenuWrapper -> {
                element.value.items.mapNotNullTo(this) { it.icon }
            }

            is PresentationElement.BadgeWrapper -> {
                addDisplayAppearance(element.value.options)
            }

            is PresentationElement.ChipWrapper -> {
                addDisplayAppearance(element.value.options)
            }

            is PresentationElement.StatusWrapper -> {
                element.value.cases.forEach { addDisplayAppearance(it.appearance.options) }
                addDisplayAppearance(element.value.fallback?.options)
            }

            is PresentationElement.DateTimeWrapper -> {
                addDisplayAppearance(element.value.options)
            }

            is PresentationElement.RelativeTimeWrapper -> {
                addDisplayAppearance(element.value.options)
            }

            else -> {}
        }
    }

private fun PresentationNode.bodyChildren(): List<PresentationNode> =
    buildList {
        when (val element = element) {
            is PresentationElement.ChildrenWrapper -> {
                addChildren(element.value)
            }

            is PresentationElement.PartWrapper -> {
                element.value.body?.let(::add)
            }

            is PresentationElement.TypedFieldWrapper -> {
                element.value.presentation?.let(::add)
            }

            is PresentationElement.SectionWrapper -> {
                add(element.value.child)
            }

            is PresentationElement.PaddingWrapper -> {
                add(element.value.child)
            }

            is PresentationElement.TabsWrapper -> {
                element.value.tabs.mapTo(this) { it.child }
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

            is PresentationElement.SelectInputWrapper -> {
                element.value.options.mapNotNullTo(this) { it.content }
                element.value.optionsConfig
                    ?.optionOverrides
                    ?.mapNotNullTo(this) { it.content }
            }

            is PresentationElement.NamedInputWrapper -> {
                element.value.payloadPresentation?.let(::add)
            }

            is PresentationElement.ListInputWrapper -> {
                element.value.itemPresentation?.let(::add)
            }

            is PresentationElement.MapInputWrapper -> {
                element.value.keyPresentation?.let(::add)
                element.value.valuePresentation?.let(::add)
            }

            is PresentationElement.RecordInputWrapper -> {
                element.value.fieldPresentation?.let(::add)
            }

            is PresentationElement.EnumInputWrapper -> {
                element.value.options
                    ?.optionOverrides
                    ?.mapNotNullTo(this) { it.content }
            }

            is PresentationElement.PolymorphicInputWrapper -> {
                element.value.concreteTypes.mapNotNullTo(this) { it.presentation }
            }

            is PresentationElement.SearchInputWrapper -> {
                element.value.empty?.let(::add)
                element.value.loading?.let(::add)
                element.value.summary?.let(::add)
                addAll(element.value.provider.nodes())
            }

            is PresentationElement.TooltipWrapper -> {
                add(element.value.child)
            }

            is PresentationElement.AppearanceDefaultsWrapper -> {
                add(element.value.child)
            }

            is PresentationElement.AlignWrapper -> {
                add(element.value.child)
            }

            is PresentationElement.ContainerWrapper -> {
                add(element.value.child)
            }

            is PresentationElement.SizeWrapper -> {
                add(element.value.child)
            }

            is PresentationElement.TransformWrapper -> {
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

            is PresentationElement.AdaptiveLeadingWrapper -> {
                add(element.value.leading)
                element.value.center?.let(::add)
                element.value.suffix?.let(::add)
            }

            is PresentationElement.NullableInputWrapper -> {
                element.value.valuePresentation?.let(::add)
            }

            is PresentationElement.SetInputWrapper -> {
                element.value.itemPresentation?.let(::add)
            }

            is PresentationElement.ResourcesWrapper -> {
                (element.value.layout as? skirout.editor.v1.presentation.ResourcesLayout.TreeWrapper)?.value?.group?.let(::add)
            }

            else -> {}
        }
    }

private fun MutableList<PresentationNode>.addChildren(children: ChildrenElement) {
    when (children) {
        is ChildrenElement.ColumnWrapper -> children.value.children.mapTo(this) { it.node() }
        is ChildrenElement.RowWrapper -> children.value.children.mapTo(this) { it.node() }
        is ChildrenElement.WrapWrapper -> addAll(children.value.children)
        is ChildrenElement.GridWrapper -> addAll(children.value.children)
        is ChildrenElement.StackWrapper -> children.value.children.mapTo(this) { it.node() }
        else -> Unit
    }
}

private fun MutableList<PresentationNode>.addInputContent(content: skirout.editor.v1.presentation.InputContent?) {
    (content?.leading as? skirout.editor.v1.presentation.InputAdornment.ContentWrapper)?.value?.let(::add)
    content?.suffix?.let(::add)
}

private fun MutableList<PresentationNode>.addDisplayAppearance(appearance: skirout.editor.v1.presentation.DisplayAppearance?) {
    (appearance?.icon as? skirout.editor.v1.presentation.InputAdornment.ContentWrapper)?.value?.let(::add)
}

private fun MutableList<PresentationNode>.addCollectionContent(content: skirout.editor.v1.presentation.CollectionContent?) {
    content ?: return
    listOfNotNull(content.empty, content.addIcon, content.removeIcon, content.reorderIcon, content.chooseIcon, content.unlinkIcon)
        .forEach(::add)
}

private fun PresentationElement.boundControl(): BoundControl? =
    when (this) {
        is PresentationElement.DefaultPresentationWrapper -> value.control
        is PresentationElement.TextInputWrapper -> value.control
        is PresentationElement.NumericInputWrapper -> value.control
        is PresentationElement.ToggleInputWrapper -> value.control
        is PresentationElement.SelectInputWrapper -> value.control
        is PresentationElement.SliderInputWrapper -> value.control
        is PresentationElement.DateTimeInputWrapper -> value.control
        is PresentationElement.DurationInputWrapper -> value.control
        is PresentationElement.ColorInputWrapper -> value.control
        is PresentationElement.BytesInputWrapper -> value.control
        is PresentationElement.NamedInputWrapper -> value.control
        is PresentationElement.ListInputWrapper -> value.control
        is PresentationElement.SetInputWrapper -> value.control
        is PresentationElement.MapInputWrapper -> value.control
        is PresentationElement.RecordInputWrapper -> value.control
        is PresentationElement.EnumInputWrapper -> value.control
        is PresentationElement.PolymorphicInputWrapper -> value.control
        is PresentationElement.SearchInputWrapper -> value.control
        is PresentationElement.NullableInputWrapper -> value.control
        is PresentationElement.LinkInputWrapper -> value.control
        is PresentationElement.ResourcesWrapper -> value.control
        else -> null
    }

private fun AxisChild.node(): PresentationNode =
    when (this) {
        is AxisChild.FixedWrapper -> value
        is AxisChild.FlexibleWrapper -> value.child
        else -> error("Unknown Skir axis child variant.")
    }

private fun StackChild.node(): PresentationNode =
    when (this) {
        is StackChild.FlowWrapper -> value
        is StackChild.PositionedWrapper -> value.child
        else -> error("Unknown Skir stack child variant.")
    }

private fun SequencePresentation.nodes(): List<PresentationNode> = listOfNotNull(item, empty, separator)

private fun PresentationConnection.nodes(): List<PresentationNode> =
    when (this) {
        is PresentationConnection.ConnectionWrapper -> value.markers.map { it.node }
        is PresentationConnection.BundleWrapper -> (value.trunkMarkers + value.branchMarkers).map { it.node }
        else -> emptyList()
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
        else -> emptyList()
    }
