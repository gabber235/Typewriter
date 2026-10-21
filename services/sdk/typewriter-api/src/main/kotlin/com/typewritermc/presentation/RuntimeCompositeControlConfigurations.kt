package com.typewritermc.presentation

import com.typewritermc.authoring.PathSegment
import com.typewritermc.authoring.ValuePath
import com.typewritermc.expression.Expr
import com.typewritermc.expression.ExpressionBindingId
import com.typewritermc.expression.Handled
import com.typewritermc.expression.inputExpression
import com.typewritermc.types.requireValid
import skirout.editor.v1.expression.ExpressionNode
import skirout.editor.v1.presentation.ControlDensity
import skirout.editor.v1.presentation.PresentationNode
import skirout.editor.v1.presentation.CollectionAppearance as WireCollectionAppearance
import skirout.editor.v1.presentation.CollectionContent as WireCollectionContent
import skirout.editor.v1.presentation.ResourceGraphAppearance as WireResourceGraphAppearance
import skirout.editor.v1.presentation.ResourceTimelineAppearance as WireResourceTimelineAppearance

internal class RuntimeCollectionAppearance(
    private val target: WireCollectionAppearance.Mutable,
) : CollectionAppearanceScope {
    override fun itemSpacing(value: Double) {
        nonnegativeSize(value)
        target.itemSpacing = value
    }

    override fun itemPadding(value: PresentationInsets) {
        target.itemPadding = value.wire()
    }

    override fun itemSurface(value: ContainerStyle) {
        target.itemBackground = value.background?.wire()
        target.itemForeground = value.foreground?.wire()
        target.itemBorder = value.border?.wire()
        target.itemRadius = value.radius.wire()
        target.itemTransition = value.transition?.requireValid()
        target.itemShadows = value.shadows.map { it.wire() }
    }
}

internal class CollectionOperationsDraft {
    var allowAdd = true
    var allowRemove = true
    var allowReorder = true
}

internal class RuntimeCollectionOperations(
    private val state: PresentationBuildState,
    private val author: RuntimePresentationBuildScope,
    private val operations: CollectionOperationsDraft,
    private val target: WireCollectionContent.Mutable,
) : CollectionOperationScope,
    CollectionOperationAppearanceScope by RuntimeCollectionOperationAppearance(target),
    CollectionEmptyTextScope by RuntimeCollectionEmptyText({ target.emptyText = it }),
    CollectionAddContentScope by RuntimeCollectionAddContent(state, target) {
    override fun allowAdd(value: Boolean) {
        operations.allowAdd = value
    }

    override fun allowRemove(value: Boolean) {
        operations.allowRemove = value
    }

    override fun empty(body: Layout.() -> Unit) {
        target.empty = author.presentation(body)
    }

    override fun removeLabel(value: String) {
        target.removeLabel = expression(value)
    }

    override fun removeLabel(value: Expr<String, Handled>) {
        target.removeLabel = expression(value)
    }

    override fun removeIcon(
        id: String,
        options: IconOptions,
    ) {
        target.removeIcon = state.iconNode(id, options)
    }
}

internal class CollectionConfigurationDraft {
    val appearance = WireCollectionAppearance.partial().toMutable()
    val content = WireCollectionContent.partial().toMutable()
    val operations = CollectionOperationsDraft()

    fun appearance() = RuntimeCollectionAppearance(appearance)

    fun operations(
        state: PresentationBuildState,
        author: RuntimePresentationBuildScope,
    ) = RuntimeCollectionOperations(state, author, operations, content)
}

internal class RuntimeListInputScope<ItemScope>(
    appearance: CollectionAppearanceScope,
    operations: CollectionOperationScope,
    private val state: PresentationBuildState,
    private val draft: CollectionConfigurationDraft,
) : ListInputScope<ItemScope>,
    CollectionAppearanceScope by appearance,
    CollectionOperationScope by operations {
    var items: (ItemScope.() -> Unit)? = null

    override fun items(body: ItemScope.() -> Unit) {
        items = body
    }

    override fun allowReorder(value: Boolean) {
        draft.operations.allowReorder = value
    }

    override fun reorderIcon(
        id: String,
        options: IconOptions,
    ) {
        draft.content.reorderIcon = state.iconNode(id, options)
    }
}

internal class RuntimeSetInputScope<ItemScope>(
    appearance: CollectionAppearanceScope,
    operations: CollectionOperationScope,
) : SetInputScope<ItemScope>,
    CollectionAppearanceScope by appearance,
    CollectionOperationScope by operations {
    var items: (ItemScope.() -> Unit)? = null

    override fun items(body: ItemScope.() -> Unit) {
        items = body
    }
}

internal class RuntimeMapInputScope<KeyScope, ValueScope>(
    appearance: CollectionAppearanceScope,
    operations: CollectionOperationScope,
    private val content: WireCollectionContent.Mutable,
) : MapInputScope<KeyScope, ValueScope>,
    CollectionAppearanceScope by appearance,
    CollectionOperationScope by operations {
    var keys: (KeyScope.() -> Unit)? = null
    var values: (ValueScope.() -> Unit)? = null

    override fun keys(body: KeyScope.() -> Unit) {
        keys = body
    }

    override fun values(body: ValueScope.() -> Unit) {
        values = body
    }

    override fun keyLabel(value: String) {
        content.keyLabel = expression(value)
    }

    override fun keyLabel(value: Expr<String, Handled>) {
        content.keyLabel = expression(value)
    }

    override fun valueLabel(value: String) {
        content.valueLabel = expression(value)
    }

    override fun valueLabel(value: Expr<String, Handled>) {
        content.valueLabel = expression(value)
    }
}

internal class RuntimeRecordInputScope<Fields : Layout>(
    appearance: CollectionAppearanceScope,
) : RecordInputScope<Fields>,
    CollectionAppearanceScope by appearance {
    var fields: (Fields.() -> Unit)? = null

    override fun fields(body: Fields.() -> Unit) {
        fields = body
    }
}

internal class RuntimeNamedInputScope<PayloadScope>(
    appearance: CollectionAppearanceScope,
) : NamedInputScope<PayloadScope>,
    CollectionAppearanceScope by appearance {
    var payload: (PayloadScope.() -> Unit)? = null

    override fun payload(body: PayloadScope.() -> Unit) {
        payload = body
    }
}

internal class RuntimeNullableInputScope<ValueScope>(
    private val draft: NullableContentDraft = NullableContentDraft(),
) : NullableInputScope<ValueScope>,
    CollectionEmptyTextScope by RuntimeCollectionEmptyText({ draft.emptyText = it }) {
    var value: (ValueScope.() -> Unit)? = null
    val emptyText: skirout.editor.v1.expression.ExpressionNode? get() = draft.emptyText
    var clearLabel: skirout.editor.v1.expression.ExpressionNode? = null

    override fun value(body: ValueScope.() -> Unit) {
        value = body
    }

    override fun clearLabel(value: String) {
        clearLabel = expression(value)
    }

    override fun clearLabel(value: Expr<String, Handled>) {
        clearLabel = expression(value)
    }
}

internal class RuntimePolymorphicInputScope<V>(
    forms: ConcreteForms<V>,
    appearance: InputAppearanceScope,
    content: InputContentScope,
    collection: CollectionAppearanceScope,
    private val operations: WireCollectionContent.Mutable,
    private val state: PresentationBuildState,
) : PolymorphicInputScope<V>,
    ConcreteForms<V> by forms,
    InputAppearanceScope by appearance,
    InputContentScope by content,
    CollectionAppearanceScope by collection,
    CollectionOperationAppearanceScope by RuntimeCollectionOperationAppearance(operations),
    ChooseContentScope by RuntimeChooseContent(state, operations) {
    var searchHint: skirout.editor.v1.expression.ExpressionNode? = null

    override fun searchHint(value: String) {
        searchHint = expression(value)
    }

    override fun searchHint(value: Expr<String, Handled>) {
        searchHint = expression(value)
    }
}

internal class RuntimeLinkInputScope(
    appearance: InputAppearanceScope,
    content: InputContentScope,
    popup: PopupAppearanceScope,
    collection: CollectionAppearanceScope,
    private val operations: WireCollectionContent.Mutable,
    private val state: PresentationBuildState,
) : LinkInputScope,
    InputAppearanceScope by appearance,
    InputContentScope by content,
    PopupAppearanceScope by popup,
    CollectionAppearanceScope by collection,
    CollectionOperationAppearanceScope by RuntimeCollectionOperationAppearance(operations),
    CollectionEmptyTextScope by RuntimeCollectionEmptyText({ operations.emptyText = it }),
    CollectionAddContentScope by RuntimeCollectionAddContent(state, operations),
    ChooseContentScope by RuntimeChooseContent(state, operations) {
    override fun unlinkIcon(
        id: String,
        options: IconOptions,
    ) {
        operations.unlinkIcon = state.iconNode(id, options)
    }

    var allowReorder = false

    override fun allowReorder(value: Boolean) {
        allowReorder = value
    }

    override fun unlinkLabel(value: String) {
        operations.unlinkLabel = expression(value)
    }

    override fun unlinkLabel(value: Expr<String, Handled>) {
        operations.unlinkLabel = expression(value)
    }
}

internal class RuntimeGraphAppearanceScope(
    private val target: WireResourceGraphAppearance.Mutable,
) : GraphAppearanceScope {
    override fun cellSize(value: Double) {
        positiveSize(value)
        target.cellSize = expression(value)
    }

    override fun cellSize(value: Expr<Double, Handled>) {
        target.cellSize = expression(value)
    }

    override fun edgeColor(value: PresentationColor) {
        target.edgeColor = value.wire()
    }

    override fun cardPadding(value: PresentationInsets) {
        target.cardPadding = value.wire()
    }
}

internal class RuntimeTimelineAppearanceScope(
    private val target: WireResourceTimelineAppearance.Mutable,
) : TimelineAppearanceScope {
    override fun rulerHeight(value: Double) {
        nonnegativeSize(value)
        target.rulerHeight = value
    }

    override fun trackPadding(value: Double) {
        nonnegativeSize(value)
        target.trackPadding = value
    }

    override fun laneHeight(value: Double) {
        nonnegativeSize(value)
        target.laneHeight = value
    }

    override fun laneGap(value: Double) {
        nonnegativeSize(value)
        target.laneGap = value
    }

    override fun headerPadding(value: Double) {
        nonnegativeSize(value)
        target.headerPadding = value
    }

    override fun headerColor(value: PresentationColor) {
        target.headerColor = value.wire()
    }

    override fun rulerColor(value: PresentationColor) {
        target.rulerColor = value.wire()
    }

    override fun trackColor(value: PresentationColor) {
        target.trackColor = value.wire()
    }

    override fun alternateTrackColor(value: PresentationColor) {
        target.alternateTrackColor = value.wire()
    }

    override fun gridMinorColor(value: PresentationColor) {
        target.gridMinorColor = value.wire()
    }

    override fun gridMajorColor(value: PresentationColor) {
        target.gridMajorColor = value.wire()
    }

    override fun textMutedColor(value: PresentationColor) {
        target.textMutedColor = value.wire()
    }
}

internal class RuntimeCollectionOperationAppearance(
    private val target: WireCollectionContent.Mutable,
) : CollectionOperationAppearanceScope {
    override fun operationTooltip(value: String) {
        target.operationTooltip = expression(value)
    }

    override fun operationTooltip(value: Expr<String, Handled>) {
        target.operationTooltip = expression(value)
    }

    override fun operationDensity(value: ControlDensity) {
        target.operationDensity = value
    }
}

internal class RuntimeCollectionEmptyText(
    private val set: (skirout.editor.v1.expression.ExpressionNode) -> Unit,
) : CollectionEmptyTextScope {
    override fun emptyText(value: String) {
        set(expression(value))
    }

    override fun emptyText(value: Expr<String, Handled>) {
        set(expression(value))
    }
}

internal class RuntimeCollectionAddContent(
    private val state: PresentationBuildState,
    private val target: WireCollectionContent.Mutable,
) : CollectionAddContentScope {
    override fun addLabel(value: String) {
        target.addLabel = expression(value)
    }

    override fun addLabel(value: Expr<String, Handled>) {
        target.addLabel = expression(value)
    }

    override fun addIcon(
        id: String,
        options: IconOptions,
    ) {
        target.addIcon = state.iconNode(id, options)
    }
}

internal class RuntimeChooseContent(
    private val state: PresentationBuildState,
    private val target: WireCollectionContent.Mutable,
) : ChooseContentScope {
    override fun chooseLabel(value: String) {
        target.chooseLabel = expression(value)
    }

    override fun chooseLabel(value: Expr<String, Handled>) {
        target.chooseLabel = expression(value)
    }

    override fun chooseIcon(
        id: String,
        options: IconOptions,
    ) {
        target.chooseIcon = state.iconNode(id, options)
    }
}

internal class NullableContentDraft {
    var emptyText: skirout.editor.v1.expression.ExpressionNode? = null
}

/** Captures the group header of a tree layout, with the group bound to [groupBinding]. */
internal class RuntimeTreeScope(
    private val state: PresentationBuildState,
    private val groupBinding: ExpressionBindingId,
) : TreeScope {
    var group: PresentationNode? = null
        private set
    var initiallyExpanded = true
        private set

    override fun group(body: TreeGroupScope.() -> Unit) {
        check(group == null) { "A tree layout may declare one group header." }
        state.groupBinding(groupBinding)
        val expressions =
            HierarchyGroupExpressions(
                path = inputExpression(groupBinding, groupField("path")),
                name = inputExpression(groupBinding, groupField("name")),
                members = inputExpression(groupBinding, groupField("members")),
            )
        group =
            state.presentation {
                object : TreeGroupScope, Layout by this {
                    override val group = expressions
                }.body()
            }
    }

    override fun initiallyExpanded(value: Boolean) {
        initiallyExpanded = value
    }

    private fun groupField(name: String) = ValuePath(listOf(PathSegment.Field(name)))
}
