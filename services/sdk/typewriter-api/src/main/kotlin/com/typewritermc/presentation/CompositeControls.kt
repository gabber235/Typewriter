package com.typewritermc.presentation

import com.typewritermc.discovery.GraphDirection
import com.typewritermc.dsl.TypewriterDsl
import com.typewritermc.expression.Expr
import com.typewritermc.expression.Handled
import com.typewritermc.types.Resource

/** Settings shared by collection editors without changing item identity or writes. */
@TypewriterDsl
interface CollectionAppearanceScope {
    fun itemSpacing(value: Double)

    fun itemPadding(value: PresentationInsets)

    fun itemSurface(value: ContainerStyle)
}

interface CollectionOperationAppearanceScope {
    fun operationTooltip(value: String)

    fun operationTooltip(value: Expr<String, Handled>)

    fun operationDensity(value: ControlDensity)
}

@TypewriterDsl
interface CollectionEmptyTextScope {
    fun emptyText(value: String)

    fun emptyText(value: Expr<String, Handled>)
}

interface CollectionAddContentScope {
    fun addLabel(value: String)

    fun addLabel(value: Expr<String, Handled>)

    fun addIcon(
        id: String,
        options: IconOptions = IconOptions(),
    )
}

interface ChooseContentScope {
    fun chooseLabel(value: String)

    fun chooseLabel(value: Expr<String, Handled>)

    fun chooseIcon(
        id: String,
        options: IconOptions = IconOptions(),
    )
}

interface CollectionOperationScope :
    CollectionOperationAppearanceScope,
    CollectionEmptyTextScope,
    CollectionAddContentScope {
    fun allowAdd(value: Boolean)

    fun allowRemove(value: Boolean)

    fun empty(body: Layout.() -> Unit)

    fun removeLabel(value: String)

    fun removeLabel(value: Expr<String, Handled>)

    fun removeIcon(
        id: String,
        options: IconOptions = IconOptions(),
    )
}

interface ListInputScope<ItemScope> :
    CollectionAppearanceScope,
    CollectionOperationScope {
    fun allowReorder(value: Boolean)

    fun reorderIcon(
        id: String,
        options: IconOptions = IconOptions(),
    )

    fun items(body: ItemScope.() -> Unit)
}

interface SetInputScope<ItemScope> :
    CollectionAppearanceScope,
    CollectionOperationScope {
    fun items(body: ItemScope.() -> Unit)
}

interface MapInputScope<KeyScope, ValueScope> :
    CollectionAppearanceScope,
    CollectionOperationScope {
    fun keyLabel(value: String)

    fun keyLabel(value: Expr<String, Handled>)

    fun valueLabel(value: String)

    fun valueLabel(value: Expr<String, Handled>)

    fun keys(body: KeyScope.() -> Unit)

    fun values(body: ValueScope.() -> Unit)
}

interface RecordInputScope<Fields : Layout> : CollectionAppearanceScope {
    fun fields(body: Fields.() -> Unit)
}

interface NamedInputScope<PayloadScope> : CollectionAppearanceScope {
    fun payload(body: PayloadScope.() -> Unit)
}

interface NullableInputScope<ValueScope> : CollectionEmptyTextScope {
    fun clearLabel(value: String)

    fun clearLabel(value: Expr<String, Handled>)

    fun value(body: ValueScope.() -> Unit)
}

interface PolymorphicInputScope<V> :
    ConcreteForms<V>,
    InputAppearanceScope,
    InputContentScope,
    CollectionAppearanceScope,
    CollectionOperationAppearanceScope,
    ChooseContentScope {
    fun searchHint(value: String)

    fun searchHint(value: Expr<String, Handled>)
}

interface LinkInputScope :
    InputAppearanceScope,
    InputContentScope,
    PopupAppearanceScope,
    CollectionAppearanceScope,
    CollectionOperationAppearanceScope,
    CollectionEmptyTextScope,
    CollectionAddContentScope,
    ChooseContentScope {
    fun allowReorder(value: Boolean)

    fun unlinkIcon(
        id: String,
        options: IconOptions = IconOptions(),
    )

    fun unlinkLabel(value: String)

    fun unlinkLabel(value: Expr<String, Handled>)
}

interface GraphPageScope {
    fun cellSize(value: Double)

    fun cellSize(value: Expr<Double, Handled>)

    fun edgeColor(value: PresentationColor)

    fun cardPadding(value: PresentationInsets)
}

interface TimelinePageScope {
    fun rulerHeight(value: Double)

    fun trackPadding(value: Double)

    fun laneHeight(value: Double)

    fun laneGap(value: Double)

    fun headerPadding(value: Double)

    fun headerColor(value: PresentationColor)

    fun rulerColor(value: PresentationColor)

    fun trackColor(value: PresentationColor)

    fun alternateTrackColor(value: PresentationColor)

    fun gridMinorColor(value: PresentationColor)

    fun gridMajorColor(value: PresentationColor)

    fun textMutedColor(value: PresentationColor)
}

interface RecordControl<Fields : Layout> : Control {
    fun recordInput(configure: RecordInputScope<Fields>.() -> Unit = {})
}

interface ListControl<ItemScope> : Control {
    fun listInput(configure: ListInputScope<ItemScope>.() -> Unit = {})
}

interface ResourceLinksControl<R : Resource> : ListControl<LinkControl<R>> {
    fun graphPage(
        direction: GraphDirection,
        configure: GraphPageScope.() -> Unit = {},
    )

    fun timelinePage(configure: TimelinePageScope.() -> Unit = {})
}

interface SetControl<ItemScope> : Control {
    fun collectionInput(configure: SetInputScope<ItemScope>.() -> Unit = {})
}

interface MapControl<KeyScope, ValueScope> : Control {
    fun mapInput(configure: MapInputScope<KeyScope, ValueScope>.() -> Unit = {})
}

interface NullableControl<ValueScope> : Control {
    fun nullableInput(configure: NullableInputScope<ValueScope>.() -> Unit = {})
}

interface PolymorphicControl<V> : Control {
    fun polymorphicInput(configure: PolymorphicInputScope<V>.() -> Unit = {})
}

interface ConcreteForms<V> {
    fun <Subtype : V> form(
        type: AppliedPresentation<Subtype>,
        label: Expr<String, Handled>? = null,
    )
}

interface LinkControl<R : Resource> : Control {
    fun linkInput(
        source: CollectionSource<*, com.typewritermc.types.ResourceId>? = null,
        policy: LinkCandidatePolicyId? = null,
        rejection: LinkRejectionDisplay = LinkRejectionDisplay.Hidden,
        configure: LinkInputScope.() -> Unit = {},
    )
}

interface LinkCollectionControl<R : Resource> : Control {
    fun linkInput(
        source: CollectionSource<*, com.typewritermc.types.ResourceId>? = null,
        policy: LinkCandidatePolicyId? = null,
        rejection: LinkRejectionDisplay = LinkRejectionDisplay.Hidden,
        configure: LinkInputScope.() -> Unit = {},
    )
}

enum class LinkRejectionDisplay { Hidden, DisabledWithReason }

@JvmInline
value class LinkCandidatePolicyId(
    val value: String,
)

data class AppliedPresentation<V>(
    val type: com.typewritermc.types.TypeUse.Named,
    val reference: PresentationReference,
)
