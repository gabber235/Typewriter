package com.typewritermc.presentation

import com.typewritermc.configuration.FieldPatternSegment
import com.typewritermc.configuration.RelativeFieldPattern
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

data class PresentationMaterial(
    val provider: PresentationId,
    val target: PresentationTarget,
    val subject: TypeTemplate,
    val role: PresentationRole,
    val layout: PresentationNode,
    val dependencies: PresentationDependencies,
)

data class OwnedFieldPresentation(
    val provider: PresentationId,
    val target: PresentationTarget,
    val role: PresentationRole,
    val field: RelativeFieldPattern,
    val selected: PresentationId,
)

fun PresentationMaterial.explicitFieldSelections(): List<OwnedFieldPresentation> =
    layout
        .explicitSelections(
            bindings = mapOf("configured_value" to RelativeFieldPattern()),
        ).map { selection ->
            OwnedFieldPresentation(
                provider = provider,
                target = target,
                role = role,
                field = selection.first,
                selected = selection.second,
            )
        }

private fun PresentationNode.explicitSelections(
    bindings: Map<String, RelativeFieldPattern>,
    field: RelativeFieldPattern? = null,
): List<Pair<RelativeFieldPattern, PresentationId>> =
    buildList {
        when (val element = element) {
            is PresentationElement.DefaultPresentationWrapper -> {
                val selected = element.value.presentationId ?: return@buildList
                val ownField =
                    element.value.binding.resolve(bindings)
                val selectedField = ownField?.takeIf { it.segments.isNotEmpty() } ?: field ?: return@buildList
                add(selectedField to PresentationId(selected.namespace, selected.name))
            }

            is PresentationElement.TypedFieldWrapper -> {
                val selectedField = element.value.binding.resolve(bindings) ?: field
                element.value.presentation?.let { addAll(it.explicitSelections(bindings, selectedField)) }
            }

            is PresentationElement.ScopedBindingWrapper -> {
                val selectedField = element.value.binding.resolve(bindings) ?: field
                val scoped = bindings.withBinding(element.value.scopeBindingId.value, selectedField)
                addAll(element.value.child.explicitSelections(scoped, selectedField))
            }

            is PresentationElement.NamedInputWrapper -> {
                val selectedField =
                    element.value.control.binding
                        .resolve(bindings) ?: field
                element.value.payloadPresentation?.let { addAll(it.explicitSelections(bindings, selectedField)) }
            }

            is PresentationElement.RecordInputWrapper -> {
                val selectedField =
                    element.value.control.binding
                        .resolve(bindings) ?: field
                element.value.fieldPresentation?.let { addAll(it.explicitSelections(bindings, selectedField)) }
            }

            is PresentationElement.ListInputWrapper -> {
                val selectedField =
                    element.value.control.binding
                        .resolve(bindings) ?: field
                val itemField = selectedField?.append(FieldPatternSegment.Items)
                val itemBindings = bindings.withBinding("list_item", itemField)
                element.value.itemPresentation?.let { addAll(it.explicitSelections(itemBindings, itemField)) }
            }

            is PresentationElement.SetInputWrapper -> {
                val selectedField =
                    element.value.control.binding
                        .resolve(bindings) ?: field
                val itemField = selectedField?.append(FieldPatternSegment.Items)
                val itemBindings = bindings.withBinding("set_item", itemField)
                element.value.itemPresentation?.let { addAll(it.explicitSelections(itemBindings, itemField)) }
            }

            is PresentationElement.MapInputWrapper -> {
                val selectedField =
                    element.value.control.binding
                        .resolve(bindings) ?: field
                val keyField = selectedField?.append(FieldPatternSegment.Keys)
                val valueField = selectedField?.append(FieldPatternSegment.Values)
                element.value.keyPresentation?.let {
                    addAll(it.explicitSelections(bindings.withBinding("map_key", keyField), keyField))
                }
                element.value.valuePresentation?.let {
                    addAll(it.explicitSelections(bindings.withBinding("map_value", valueField), valueField))
                }
            }

            is PresentationElement.NullableInputWrapper -> {
                val selectedField =
                    element.value.control.binding
                        .resolve(bindings) ?: field
                element.value.valuePresentation?.let { addAll(it.explicitSelections(bindings, selectedField)) }
            }

            is PresentationElement.PolymorphicMatchWrapper -> {
                val selectedField = element.value.binding.resolve(bindings) ?: field
                val scoped = bindings.withBinding(element.value.scopeBindingId.value, selectedField)
                element.value.cases.forEach { case -> addAll(case.child.explicitSelections(scoped, selectedField)) }
                element.value.fallback?.let { addAll(it.explicitSelections(bindings, field)) }
            }

            is PresentationElement.RepeatedWrapper -> {
                val sourceField = element.value.source.resolveRead(bindings)
                val itemField = sourceField?.append(FieldPatternSegment.Items)
                val itemBindings = bindings.withBinding(element.value.itemBindingId.value, itemField)
                addAll(
                    element.value.presentation.item
                        .explicitSelections(itemBindings, itemField),
                )
                element.value.presentation.empty
                    ?.let { addAll(it.explicitSelections(bindings, field)) }
                element.value.presentation.separator
                    ?.let { addAll(it.explicitSelections(bindings, field)) }
            }

            else -> {
                children().forEach { child -> addAll(child.explicitSelections(bindings, field)) }
            }
        }
    }

private fun BindingRef.resolve(bindings: Map<String, RelativeFieldPattern>): RelativeFieldPattern? =
    bindings[bindingId.value]?.append(path.toRelativePattern())

private fun skirout.editor.v1.expression.ExpressionNode.resolveRead(bindings: Map<String, RelativeFieldPattern>): RelativeFieldPattern? {
    val read = (this as? skirout.editor.v1.expression.ExpressionNode.ReadWrapper)?.value ?: return null
    return bindings[read.binding.value]?.append(read.path.toRelativePattern())
}

private fun Map<String, RelativeFieldPattern>.withBinding(
    bindingId: String,
    field: RelativeFieldPattern?,
): Map<String, RelativeFieldPattern> =
    if (field == null) {
        this
    } else {
        this + (bindingId to field)
    }

private fun RelativeFieldPattern.append(other: RelativeFieldPattern): RelativeFieldPattern = RelativeFieldPattern(segments + other.segments)

private fun RelativeFieldPattern.append(segment: FieldPatternSegment): RelativeFieldPattern = RelativeFieldPattern(segments + segment)

private fun skirout.editor.v1.type_catalog.ValuePath.toRelativePattern() =
    RelativeFieldPattern(
        segments.map { segment ->
            when (segment) {
                is skirout.editor.v1.type_catalog.PathSegment.FieldWrapper -> FieldPatternSegment.Field(segment.value.name)
                is skirout.editor.v1.type_catalog.PathSegment.ItemWrapper -> FieldPatternSegment.Items
                skirout.editor.v1.type_catalog.PathSegment.MAP_KEY -> FieldPatternSegment.Keys
                skirout.editor.v1.type_catalog.PathSegment.MAP_VALUE -> FieldPatternSegment.Values
                else -> error("Unknown Skir path segment.")
            }
        },
    )

private fun PresentationNode.children(): List<PresentationNode> =
    buildList {
        (header?.title as? PresentationHeaderTitle.PresentationWrapper)?.value?.let(::add)
        when (val element = element) {
            is PresentationElement.ChildrenWrapper -> {
                addChildren(element.value)
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

            is PresentationElement.TextInputWrapper -> {
                addControl(element.value.control)
            }

            is PresentationElement.NumericInputWrapper -> {
                addControl(element.value)
            }

            is PresentationElement.ToggleInputWrapper -> {
                addControl(element.value)
            }

            is PresentationElement.SelectInputWrapper -> {
                addControl(element.value.control)
            }

            is PresentationElement.SliderInputWrapper -> {
                addControl(element.value.control)
            }

            is PresentationElement.DateTimeInputWrapper -> {
                addControl(element.value.control)
            }

            is PresentationElement.DurationInputWrapper -> {
                addControl(element.value)
            }

            is PresentationElement.ColorInputWrapper -> {
                addControl(element.value.control)
            }

            is PresentationElement.BytesInputWrapper -> {
                addControl(element.value)
            }

            is PresentationElement.NamedInputWrapper -> {
                addControl(element.value.control)
                element.value.payloadPresentation?.let(::add)
            }

            is PresentationElement.ListInputWrapper -> {
                addControl(element.value.control)
                element.value.itemPresentation?.let(::add)
            }

            is PresentationElement.MapInputWrapper -> {
                addControl(element.value.control)
                element.value.keyPresentation?.let(::add)
                element.value.valuePresentation?.let(::add)
            }

            is PresentationElement.RecordInputWrapper -> {
                addControl(element.value.control)
                element.value.fieldPresentation?.let(::add)
            }

            is PresentationElement.EnumInputWrapper -> {
                addControl(element.value)
            }

            is PresentationElement.PolymorphicInputWrapper -> {
                addControl(element.value.control)
                element.value.concreteTypes.mapNotNullTo(this) { it.presentation }
            }

            is PresentationElement.SearchInputWrapper -> {
                addControl(element.value.control)
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

            is PresentationElement.AdaptiveLeadingWrapper -> {
                add(element.value.leading)
                element.value.center?.let(::add)
                element.value.suffix?.let(::add)
            }

            is PresentationElement.NullableInputWrapper -> {
                addControl(element.value.control)
                element.value.valuePresentation?.let(::add)
            }

            is PresentationElement.SetInputWrapper -> {
                addControl(element.value.control)
                element.value.itemPresentation?.let(::add)
            }

            is PresentationElement.LinkInputWrapper -> {
                addControl(element.value.control)
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
        is ChildrenElement.StackWrapper -> addAll(children.value.children)
        else -> Unit
    }
}

private fun MutableList<PresentationNode>.addControl(control: BoundControl) {
    control.prefix?.let(::add)
}

private fun AxisChild.node(): PresentationNode =
    when (this) {
        is AxisChild.FixedWrapper -> value
        is AxisChild.FlexibleWrapper -> value.child
        else -> error("Unknown Skir axis child variant.")
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
