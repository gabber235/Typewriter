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

internal data class AuthoredBindingUse(
    val field: RelativeFieldPattern,
    val selected: PresentationId?,
)

fun PresentationMaterial.explicitFieldSelections(): List<OwnedFieldPresentation> =
    layout
        .authoredBindingUses(
            bindings = mapOf("configured_value" to RelativeFieldPattern()),
        ).mapNotNull { use ->
            val selected = use.selected ?: return@mapNotNull null
            OwnedFieldPresentation(
                provider = provider,
                target = target,
                role = role,
                field = use.field,
                selected = selected,
            )
        }

private fun PresentationNode.authoredBindingUses(
    bindings: Map<String, RelativeFieldPattern>,
    field: RelativeFieldPattern? = null,
): List<AuthoredBindingUse> =
    buildList {
        val control = element?.boundControl()
        control?.binding?.resolve(bindings)?.let { address ->
            val selected =
                (element as? PresentationElement.DefaultPresentationWrapper)
                    ?.value
                    ?.presentationId
                    ?.let { PresentationId(it.namespace, it.name) }
            val authoredField = address.takeIf { it.segments.isNotEmpty() } ?: field
            if (authoredField != null) add(AuthoredBindingUse(authoredField, selected))
        }
        decorations().forEach { child -> addAll(child.authoredBindingUses(bindings, field)) }
        when (val element = element) {
            is PresentationElement.DefaultPresentationWrapper -> {
                bodyChildren().forEach { addAll(it.authoredBindingUses(bindings, field)) }
            }

            is PresentationElement.TypedFieldWrapper -> {
                val selectedField = element.value.binding.resolve(bindings) ?: field
                element.value.presentation?.let { addAll(it.authoredBindingUses(bindings, selectedField)) }
            }

            is PresentationElement.ScopedBindingWrapper -> {
                val selectedField = element.value.binding.resolve(bindings) ?: field
                val scoped = bindings.withBinding(element.value.scopeBindingId.value, selectedField)
                addAll(element.value.child.authoredBindingUses(scoped, selectedField))
            }

            is PresentationElement.NamedInputWrapper -> {
                val selectedField =
                    element.value.control.binding
                        .resolve(bindings) ?: field
                element.value.payloadPresentation?.let { addAll(it.authoredBindingUses(bindings, selectedField)) }
            }

            is PresentationElement.RecordInputWrapper -> {
                val selectedField =
                    element.value.control.binding
                        .resolve(bindings) ?: field
                element.value.fieldPresentation?.let { addAll(it.authoredBindingUses(bindings, selectedField)) }
            }

            is PresentationElement.ListInputWrapper -> {
                val selectedField =
                    element.value.control.binding
                        .resolve(bindings) ?: field
                val itemField = selectedField?.append(FieldPatternSegment.Items)
                val itemBindings = bindings.withBinding(element.value.itemBindingId.value, itemField)
                element.value.itemPresentation?.let { addAll(it.authoredBindingUses(itemBindings, itemField)) }
            }

            is PresentationElement.SetInputWrapper -> {
                val selectedField =
                    element.value.control.binding
                        .resolve(bindings) ?: field
                val itemField = selectedField?.append(FieldPatternSegment.Items)
                val itemBindings = bindings.withBinding(element.value.itemBindingId.value, itemField)
                element.value.itemPresentation?.let { addAll(it.authoredBindingUses(itemBindings, itemField)) }
            }

            is PresentationElement.MapInputWrapper -> {
                val selectedField =
                    element.value.control.binding
                        .resolve(bindings) ?: field
                val keyField = selectedField?.append(FieldPatternSegment.Keys)
                val valueField = selectedField?.append(FieldPatternSegment.Values)
                element.value.keyPresentation?.let {
                    addAll(it.authoredBindingUses(bindings.withBinding(element.value.keyBindingId.value, keyField), keyField))
                }
                element.value.valuePresentation?.let {
                    addAll(it.authoredBindingUses(bindings.withBinding(element.value.valueBindingId.value, valueField), valueField))
                }
            }

            is PresentationElement.NullableInputWrapper -> {
                val selectedField =
                    element.value.control.binding
                        .resolve(bindings) ?: field
                element.value.valuePresentation?.let { addAll(it.authoredBindingUses(bindings, selectedField)) }
            }

            is PresentationElement.PolymorphicMatchWrapper -> {
                val selectedField = element.value.binding.resolve(bindings) ?: field
                val scoped = bindings.withBinding(element.value.scopeBindingId.value, selectedField)
                element.value.cases.forEach { case -> addAll(case.child.authoredBindingUses(scoped, selectedField)) }
                element.value.fallback?.let { addAll(it.authoredBindingUses(bindings, field)) }
            }

            is PresentationElement.RepeatedWrapper -> {
                val sourceField = element.value.source.resolveRead(bindings)
                val itemField = sourceField?.append(FieldPatternSegment.Items)
                val itemBindings = bindings.withBinding(element.value.itemBindingId.value, itemField)
                addAll(
                    element.value.presentation.item
                        .authoredBindingUses(itemBindings, itemField),
                )
                element.value.presentation.empty
                    ?.let { addAll(it.authoredBindingUses(bindings, field)) }
                element.value.presentation.separator
                    ?.let { addAll(it.authoredBindingUses(bindings, field)) }
            }

            else -> {
                bodyChildren().forEach { child -> addAll(child.authoredBindingUses(bindings, field)) }
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
        this - bindingId
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

            else -> {
                Unit
            }
        }
    }

private fun PresentationNode.bodyChildren(): List<PresentationNode> =
    buildList {
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
        is PresentationElement.PageGraphWrapper -> value.control
        is PresentationElement.PageTimelineWrapper -> value.control
        else -> null
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
