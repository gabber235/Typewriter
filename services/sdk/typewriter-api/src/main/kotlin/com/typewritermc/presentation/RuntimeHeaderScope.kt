package com.typewritermc.presentation

import com.typewritermc.expression.Expr
import com.typewritermc.expression.Handled
import com.typewritermc.expression.literal
import skirout.editor.v1.binding.BindingRef
import skirout.editor.v1.expression.ExpressionNode
import skirout.editor.v1.presentation.HeaderActionPlacement
import skirout.editor.v1.presentation.HeaderActionTone

internal class RuntimeHeaderScope(
    private val state: PresentationBuildState,
) : HeaderScope {
    private var diagnosticBinding: BindingRef? = null
    private var title: skirout.editor.v1.presentation.PresentationHeaderTitle? = null
    private var description: skirout.editor.v1.expression.ExpressionNode? = null
    private var initiallyExpanded: Boolean? = null
    private var headerPadding: skirout.editor.v1.presentation.PresentationInsets? = null
    private var contentPadding: skirout.editor.v1.presentation.PresentationInsets? = null
    private val items = mutableListOf<skirout.editor.v1.presentation.HeaderItem>()

    override fun diagnostics(input: PresentationInput<*, *>) {
        check(diagnosticBinding == null) { "Presentation header diagnostic scope may be declared once." }
        diagnosticBinding = input.binding
    }

    override fun title(text: Expr<String, Handled>) {
        check(title == null) { "Presentation header title may be declared once." }
        title =
            skirout.editor.v1.presentation.PresentationHeaderTitle
                .TextWrapper(state.lower(text, TEXT_SLOT))
    }

    override fun title(body: Layout.() -> Unit) {
        check(title == null) { "Presentation header title may be declared once." }
        title =
            skirout.editor.v1.presentation.PresentationHeaderTitle
                .PresentationWrapper(state.presentation(body))
    }

    override fun description(text: Expr<String, Handled>) {
        description = state.lower(text, TEXT_SLOT)
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
        items += RuntimeHeaderButtonScope(id, state).apply(configure).build()
    }

    override fun toggle(
        id: HeaderItemId,
        configure: HeaderToggleScope.() -> Unit,
    ) {
        requireItemId(id)
        items += RuntimeHeaderToggleScope(id, state).apply(configure).build()
    }

    override fun reorderHandle(
        id: HeaderItemId,
        configure: HeaderReorderScope.() -> Unit,
    ) {
        requireItemId(id)
        items += RuntimeHeaderReorderScope(state, id).apply(configure).build()
    }

    private fun requireItemId(id: HeaderItemId) {
        require(id.value.isNotBlank()) { "Header item id must not be blank." }
        require(items.none { item -> item.itemName() == id.value }) { "Header item ids must be unique within one node." }
    }

    fun build(): skirout.editor.v1.presentation.PresentationHeader? =
        if (diagnosticBinding == null && title == null && description == null && initiallyExpanded == null &&
            items.isEmpty() && headerPadding == null && contentPadding == null
        ) {
            null
        } else {
            skirout.editor.v1.presentation.PresentationHeader(
                binding = diagnosticBinding,
                title = title,
                description = description,
                initiallyExpanded = initiallyExpanded,
                items = items,
                headerPadding = headerPadding,
                contentPadding = contentPadding,
            )
        }
}

private abstract class RuntimeHeaderActionScope(
    protected val state: PresentationBuildState,
) {
    var tooltip: skirout.editor.v1.expression.ExpressionNode? = null
    var priority: skirout.editor.v1.expression.ExpressionNode? = null
    var visibleIf: skirout.editor.v1.expression.ExpressionNode? = null
    var enabledIf: skirout.editor.v1.expression.ExpressionNode? = null
    var confirmation: skirout.editor.v1.presentation.HeaderActionConfirmation? = null
    var placement: HeaderActionPlacement = HeaderActionPlacement.END

    fun setTooltip(value: Expr<String, Handled>) {
        tooltip = state.lower(value, TEXT_SLOT)
    }

    fun setPriority(value: Expr<Int, Handled>) {
        priority = state.lower(value, INT_SLOT)
    }

    fun setVisibleIf(value: Expr<Boolean, Handled>) {
        visibleIf = state.lower(value, BOOLEAN_SLOT)
    }

    fun setEnabledIf(value: Expr<Boolean, Handled>) {
        enabledIf = state.lower(value, BOOLEAN_SLOT)
    }

    fun setConfirmation(value: HeaderActionConfirmation) {
        confirmation = value.wire(state)
    }
}

private class RuntimeHeaderButtonScope(
    private val id: HeaderItemId,
    state: PresentationBuildState,
) : RuntimeHeaderActionScope(state),
    HeaderButtonScope {
    private var icon: skirout.editor.v1.expression.ExpressionNode? = null
    private var label: skirout.editor.v1.expression.ExpressionNode? = null
    private var action: skirout.editor.v1.action.EditorAction? = null
    private var tone: HeaderActionTone = HeaderActionTone.NEUTRAL

    override fun icon(value: Expr<String, Handled>) {
        icon = state.lower(value, TEXT_SLOT)
    }

    override fun label(value: Expr<String, Handled>) {
        label = state.lower(value, TEXT_SLOT)
    }

    override fun tooltip(value: Expr<String, Handled>) = setTooltip(value)

    override fun action(value: PresentationAction) {
        action = state.action(value)
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
            tone = tone,
            confirmation = confirmation,
            placement = placement,
        )
}

private class RuntimeHeaderToggleScope(
    private val id: HeaderItemId,
    state: PresentationBuildState,
) : RuntimeHeaderActionScope(state),
    HeaderToggleScope {
    private var label: skirout.editor.v1.expression.ExpressionNode? = null
    private var checked: skirout.editor.v1.expression.ExpressionNode? = null
    private var action: skirout.editor.v1.action.EditorAction? = null

    override fun label(value: Expr<String, Handled>) {
        label = state.lower(value, TEXT_SLOT)
    }

    override fun checked(value: Expr<Boolean, Handled>) {
        checked = state.lower(value, BOOLEAN_SLOT)
    }

    override fun action(value: PresentationAction) {
        action = state.action(value)
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
            placement = placement,
        )
}

private class RuntimeHeaderReorderScope(
    private val state: PresentationBuildState,
    private val id: HeaderItemId,
) : HeaderReorderScope {
    private var label: skirout.editor.v1.expression.ExpressionNode? = null
    private var source: BindingRef? = null
    private var tooltip: skirout.editor.v1.expression.ExpressionNode? = null
    private var visibleIf: skirout.editor.v1.expression.ExpressionNode? = null
    private var enabledIf: skirout.editor.v1.expression.ExpressionNode? = null

    override fun label(value: Expr<String, Handled>) {
        label = state.lower(value, TEXT_SLOT)
    }

    override fun source(value: PresentationInput<*, *>) {
        source = value.binding
    }

    override fun tooltip(value: Expr<String, Handled>) {
        tooltip = state.lower(value, TEXT_SLOT)
    }

    override fun visibleIf(value: Expr<Boolean, Handled>) {
        visibleIf = state.lower(value, BOOLEAN_SLOT)
    }

    override fun enabledIf(value: Expr<Boolean, Handled>) {
        enabledIf = state.lower(value, BOOLEAN_SLOT)
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

private fun HeaderActionConfirmation.wire(state: PresentationBuildState): skirout.editor.v1.presentation.HeaderActionConfirmation =
    skirout.editor.v1.presentation.HeaderActionConfirmation(
        title = state.lower(title, TEXT_SLOT),
        message = state.lower(message, TEXT_SLOT),
        confirmationLabel = state.lower(confirmationLabel, TEXT_SLOT),
    )

private fun skirout.editor.v1.presentation.HeaderItem.itemName(): String =
    when (this) {
        is skirout.editor.v1.presentation.HeaderItem.ButtonWrapper -> value.itemId.name
        is skirout.editor.v1.presentation.HeaderItem.BooleanToggleWrapper -> value.itemId.name
        is skirout.editor.v1.presentation.HeaderItem.ReorderHandleWrapper -> value.itemId.name
        else -> ""
    }
