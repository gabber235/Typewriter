package com.typewritermc.presentation

import com.typewritermc.expression.Expr
import com.typewritermc.expression.Handled
import skirout.editor.v1.binding.BindingRef

internal class RuntimeHeaderScope(
    private val state: PresentationBuildState,
    private val binding: BindingRef,
) : HeaderScope {
    private var title: skirout.editor.v1.presentation.PresentationHeaderTitle? = null
    private var description: skirout.editor.v1.expression.ExpressionNode? = null
    private var initiallyExpanded: Boolean? = null
    private var headerPadding: skirout.editor.v1.presentation.PresentationInsets? = null
    private var contentPadding: skirout.editor.v1.presentation.PresentationInsets? = null
    private val items = mutableListOf<skirout.editor.v1.presentation.HeaderItem>()

    override fun title(text: Expr<String, Handled>) {
        check(title == null) { "Presentation header title may be declared once." }
        title =
            skirout.editor.v1.presentation.PresentationHeaderTitle
                .TextWrapper(expression(text))
    }

    override fun title(body: Layout.() -> Unit) {
        check(title == null) { "Presentation header title may be declared once." }
        title =
            skirout.editor.v1.presentation.PresentationHeaderTitle
                .PresentationWrapper(state.presentation(body))
    }

    override fun description(text: Expr<String, Handled>) {
        description = expression(text)
    }

    override fun expanded(initially: Boolean) {
        initiallyExpanded = initially
    }

    override fun padding(
        header: PresentationInsets,
        content: PresentationInsets,
    ) {
        headerPadding = header.wire()
        contentPadding = content.wire()
    }

    override fun button(
        id: HeaderItemId,
        configure: HeaderButtonScope.() -> Unit,
    ) {
        requireItemId(id)
        items += RuntimeHeaderButtonScope(id).apply(configure).build()
    }

    override fun toggle(
        id: HeaderItemId,
        configure: HeaderToggleScope.() -> Unit,
    ) {
        requireItemId(id)
        items += RuntimeHeaderToggleScope(id).apply(configure).build()
    }

    override fun reorderHandle(
        id: HeaderItemId,
        configure: HeaderReorderScope.() -> Unit,
    ) {
        requireItemId(id)
        items += RuntimeHeaderReorderScope(id).apply(configure).build()
    }

    private fun requireItemId(id: HeaderItemId) {
        require(id.value.isNotBlank()) { "Header item id must not be blank." }
        require(items.none { item -> item.itemName() == id.value }) { "Header item ids must be unique within one node." }
    }

    fun build(): skirout.editor.v1.presentation.PresentationHeader? =
        if (title == null && description == null && initiallyExpanded == null && items.isEmpty() && headerPadding == null &&
            contentPadding == null
        ) {
            null
        } else {
            skirout.editor.v1.presentation.PresentationHeader(
                binding = binding,
                title = title,
                description = description,
                initiallyExpanded = initiallyExpanded,
                items = items,
                headerPadding = headerPadding,
                contentPadding = contentPadding,
            )
        }
}

private abstract class RuntimeHeaderActionScope {
    var tooltip: skirout.editor.v1.expression.ExpressionNode? = null
    var priority: skirout.editor.v1.expression.ExpressionNode? = null
    var visibleIf: skirout.editor.v1.expression.ExpressionNode? = null
    var enabledIf: skirout.editor.v1.expression.ExpressionNode? = null
    var confirmation: skirout.editor.v1.presentation.HeaderActionConfirmation? = null
    var placement = HeaderActionPlacement.End

    fun setTooltip(value: Expr<String, Handled>) {
        tooltip = expression(value)
    }

    fun setPriority(value: Expr<Int, Handled>) {
        priority = expression(value)
    }

    fun setVisibleIf(value: Expr<Boolean, Handled>) {
        visibleIf = expression(value)
    }

    fun setEnabledIf(value: Expr<Boolean, Handled>) {
        enabledIf = expression(value)
    }

    fun setConfirmation(value: HeaderActionConfirmation) {
        confirmation = value.wire()
    }
}

private class RuntimeHeaderButtonScope(
    private val id: HeaderItemId,
) : RuntimeHeaderActionScope(),
    HeaderButtonScope {
    private var icon: skirout.editor.v1.expression.ExpressionNode? = null
    private var label: skirout.editor.v1.expression.ExpressionNode? = null
    private var action: skirout.editor.v1.action.EditorAction? = null
    private var tone = HeaderActionTone.Neutral

    override fun icon(value: Expr<String, Handled>) {
        icon = expression(value)
    }

    override fun label(value: Expr<String, Handled>) {
        label = expression(value)
    }

    override fun tooltip(value: Expr<String, Handled>) = setTooltip(value)

    override fun action(value: skirout.editor.v1.action.EditorAction) {
        action = value
    }

    override fun priority(value: Expr<Int, Handled>) = setPriority(value)

    override fun visibleIf(value: Expr<Boolean, Handled>) = setVisibleIf(value)

    override fun enabledIf(value: Expr<Boolean, Handled>) = setEnabledIf(value)

    override fun tone(value: HeaderActionTone) {
        tone = value
    }

    override fun confirmation(value: HeaderActionConfirmation) = setConfirmation(value)

    override fun placement(value: HeaderActionPlacement) {
        placement = value
    }

    fun build(): skirout.editor.v1.presentation.HeaderItem =
        skirout.editor.v1.presentation.HeaderItem.createButton(
            itemId = id.wire(),
            icon = requireNotNull(icon) { "Header button icon is required." },
            label = requireNotNull(label) { "Header button label is required." },
            tooltip = tooltip,
            action = requireNotNull(action) { "Header button action is required." },
            priority = priority,
            visibleIf = visibleIf,
            enabledIf = enabledIf,
            tone = tone.wire(),
            confirmation = confirmation,
            placement = placement.wire(),
        )
}

private class RuntimeHeaderToggleScope(
    private val id: HeaderItemId,
) : RuntimeHeaderActionScope(),
    HeaderToggleScope {
    private var label: skirout.editor.v1.expression.ExpressionNode? = null
    private var checked: skirout.editor.v1.expression.ExpressionNode? = null
    private var action: skirout.editor.v1.action.EditorAction? = null

    override fun label(value: Expr<String, Handled>) {
        label = expression(value)
    }

    override fun checked(value: Expr<Boolean, Handled>) {
        checked = expression(value)
    }

    override fun action(value: skirout.editor.v1.action.EditorAction) {
        action = value
    }

    override fun tooltip(value: Expr<String, Handled>) = setTooltip(value)

    override fun priority(value: Expr<Int, Handled>) = setPriority(value)

    override fun visibleIf(value: Expr<Boolean, Handled>) = setVisibleIf(value)

    override fun enabledIf(value: Expr<Boolean, Handled>) = setEnabledIf(value)

    override fun confirmation(value: HeaderActionConfirmation) = setConfirmation(value)

    override fun placement(value: HeaderActionPlacement) {
        placement = value
    }

    fun build(): skirout.editor.v1.presentation.HeaderItem =
        skirout.editor.v1.presentation.HeaderItem.createBooleanToggle(
            itemId = id.wire(),
            label = requireNotNull(label) { "Header toggle label is required." },
            checked = requireNotNull(checked) { "Header toggle checked expression is required." },
            action = requireNotNull(action) { "Header toggle action is required." },
            tooltip = tooltip,
            priority = priority,
            visibleIf = visibleIf,
            enabledIf = enabledIf,
            confirmation = confirmation,
            placement = placement.wire(),
        )
}

private class RuntimeHeaderReorderScope(
    private val id: HeaderItemId,
) : HeaderReorderScope {
    private var label: skirout.editor.v1.expression.ExpressionNode? = null
    private var source: BindingRef? = null
    private var tooltip: skirout.editor.v1.expression.ExpressionNode? = null
    private var visibleIf: skirout.editor.v1.expression.ExpressionNode? = null
    private var enabledIf: skirout.editor.v1.expression.ExpressionNode? = null

    override fun label(value: Expr<String, Handled>) {
        label = expression(value)
    }

    override fun source(value: PresentationInput<*, *>) {
        source = value.binding
    }

    override fun tooltip(value: Expr<String, Handled>) {
        tooltip = expression(value)
    }

    override fun visibleIf(value: Expr<Boolean, Handled>) {
        visibleIf = expression(value)
    }

    override fun enabledIf(value: Expr<Boolean, Handled>) {
        enabledIf = expression(value)
    }

    fun build(): skirout.editor.v1.presentation.HeaderItem =
        skirout.editor.v1.presentation.HeaderItem.createReorderHandle(
            itemId = id.wire(),
            label = requireNotNull(label) { "Header reorder label is required." },
            source = requireNotNull(source) { "Header reorder source is required." },
            tooltip = tooltip,
            visibleIf = visibleIf,
            enabledIf = enabledIf,
        )
}

private fun HeaderItemId.wire(): skirout.editor.v1.presentation.HeaderItemId =
    skirout.editor.v1.presentation
        .HeaderItemId(namespace = "generated", name = value)

private fun HeaderActionTone.wire(): skirout.editor.v1.presentation.HeaderActionTone =
    when (this) {
        HeaderActionTone.Neutral -> skirout.editor.v1.presentation.HeaderActionTone.NEUTRAL
        HeaderActionTone.Destructive -> skirout.editor.v1.presentation.HeaderActionTone.DESTRUCTIVE
    }

private fun HeaderActionPlacement.wire(): skirout.editor.v1.presentation.HeaderActionPlacement =
    when (this) {
        HeaderActionPlacement.BeforeTitle -> skirout.editor.v1.presentation.HeaderActionPlacement.BEFORE_TITLE
        HeaderActionPlacement.AfterTitle -> skirout.editor.v1.presentation.HeaderActionPlacement.AFTER_TITLE
        HeaderActionPlacement.End -> skirout.editor.v1.presentation.HeaderActionPlacement.END
    }

private fun HeaderActionConfirmation.wire(): skirout.editor.v1.presentation.HeaderActionConfirmation =
    skirout.editor.v1.presentation.HeaderActionConfirmation(
        title = expression(title),
        message = expression(message),
        confirmationLabel = expression(confirmationLabel),
    )

private fun skirout.editor.v1.presentation.HeaderItem.itemName(): String =
    when (this) {
        is skirout.editor.v1.presentation.HeaderItem.ButtonWrapper -> value.itemId.name
        is skirout.editor.v1.presentation.HeaderItem.BooleanToggleWrapper -> value.itemId.name
        is skirout.editor.v1.presentation.HeaderItem.ReorderHandleWrapper -> value.itemId.name
        else -> ""
    }
