package com.typewritermc.presentation

import com.typewritermc.authoring.HierarchyPath
import com.typewritermc.authoring.TypedPath
import com.typewritermc.discovery.GraphDirection
import com.typewritermc.dsl.TypewriterDsl
import com.typewritermc.expression.Expr
import com.typewritermc.expression.Handled
import com.typewritermc.types.Resource
import skirout.editor.v1.presentation.ControlDensity
import skirout.editor.v1.presentation.LinkRejectionDisplay

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

/** Appearance of a graph of resources. */
@TypewriterDsl
interface GraphAppearanceScope {
    fun cellSize(value: Double)

    fun cellSize(value: Expr<Double, Handled>)

    fun edgeColor(value: PresentationColor)

    fun cardPadding(value: PresentationInsets)
}

/** Appearance of a timeline of resources. */
@TypewriterDsl
interface TimelineAppearanceScope {
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

/**
 * Lays out the resources of a link field, such as Page.elements or Library.books. Every member renders through its
 * item presentation, and adding or removing members edits the link. Call one layout function; [order] sorts the
 * members of any layout except graph and timeline, which place members by their placement.
 */
interface ResourcesControl<R : Resource> : ListControl<LinkControl<R>> {
    /** Sorts members by [key], evaluated for each member; without it members keep link order. */
    fun order(key: ResourceItemScope<R>.() -> Expr<*, Handled>)

    /** Places members on a graph by their graph placement, with edges from the relations among them. */
    fun graph(
        direction: GraphDirection,
        configure: GraphAppearanceScope.() -> Unit = {},
    )

    /** Places members on a timeline by their timeline placement. */
    fun timeline(configure: TimelineAppearanceScope.() -> Unit = {})

    /** Shows members as cards at most [itemExtent] wide with the given [aspectRatio], [spacing] apart. */
    fun grid(
        itemExtent: Double = 200.0,
        aspectRatio: Double = 1.0,
        spacing: Double = 12.0,
    )

    /** Shows members as rows. */
    fun list()

    /** Groups members by a hierarchy path field; dropping onto a group rewrites that field. */
    fun tree(
        path: TypedPath<R, HierarchyPath>,
        configure: TreeScope.() -> Unit = {},
    )
}

/** One member of a resources layout. */
@TypewriterDsl
interface ResourceItemScope<R : Resource> {
    val resource: ResourceExpr<R>
}

/** Configures a tree of resources grouped by a hierarchy path. */
@TypewriterDsl
interface TreeScope {
    /** Header of each group; [TreeGroupScope.group] exposes its path, name and members. */
    fun group(body: TreeGroupScope.() -> Unit)

    /** Whether groups start expanded. */
    fun initiallyExpanded(value: Boolean)
}

/** The header of one tree group. */
interface TreeGroupScope : Layout {
    val group: HierarchyGroupExpressions
}

/** The group a tree header renders: its full [path], last path segment as [name], and member resources. */
class HierarchyGroupExpressions internal constructor(
    val path: Expr<HierarchyPath, Handled>,
    val name: Expr<String, Handled>,
    val members: Expr<List<com.typewritermc.types.ResourceId>, Handled>,
)

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
        rejection: LinkRejectionDisplay = LinkRejectionDisplay.HIDDEN,
        configure: LinkInputScope.() -> Unit = {},
    )
}

interface LinkCollectionControl<R : Resource> : Control {
    fun linkInput(
        source: CollectionSource<*, com.typewritermc.types.ResourceId>? = null,
        policy: LinkCandidatePolicyId? = null,
        rejection: LinkRejectionDisplay = LinkRejectionDisplay.HIDDEN,
        configure: LinkInputScope.() -> Unit = {},
    )
}

@JvmInline
value class LinkCandidatePolicyId(
    val value: String,
)

data class AppliedPresentation<V>(
    val type: com.typewritermc.types.TypeUse.Named,
    val reference: PresentationReference,
)
