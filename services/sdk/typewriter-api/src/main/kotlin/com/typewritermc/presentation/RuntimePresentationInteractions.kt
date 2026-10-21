package com.typewritermc.presentation

import com.typewritermc.expression.Expr
import com.typewritermc.expression.Handled
import skirout.editor.v1.action.EditorAction
import skirout.editor.v1.presentation.ButtonVariant
import skirout.editor.v1.presentation.PresentationElement
import skirout.editor.v1.presentation.PresentationNode

internal class RuntimePresentationInteractions(
    private val state: PresentationBuildState,
    private val target: MutableList<PresentationNode>,
) : PresentationInteractions {
    override fun button(
        label: Expr<String, Handled>,
        action: EditorAction,
        configure: ButtonScope.() -> Unit,
    ) {
        state.action(action)
        val visual =
            skirout.editor.v1.presentation.InputAppearance
                .partial()
                .toMutable()
        val draft =
            skirout.editor.v1.presentation.ActionAppearance
                .partial()
                .toMutable()
        var icon: PresentationNode? = null
        RuntimeButtonScope(
            RuntimeActionAppearance(RuntimeTextEntryAppearance(visual), draft),
            RuntimeGlyphContent(state) {
                icon =
                    (it as? skirout.editor.v1.presentation.InputAdornment.ContentWrapper)?.value
            },
        ).configure()
        draft.appearance = visual.toFrozen()
        target +=
            state.node(
                PresentationElement.createButton(label = expression(label), action = action, appearance = draft.toFrozen(), icon = icon),
            )
    }

    override fun iconButton(
        icon: Expr<String, Handled>,
        semanticLabel: Expr<String, Handled>,
        action: EditorAction,
        configure: IconButtonScope.() -> Unit,
    ) {
        state.action(action)
        val visual =
            skirout.editor.v1.presentation.InputAppearance
                .partial()
                .toMutable()
        val draft =
            skirout.editor.v1.presentation.ActionAppearance
                .partial()
                .toMutable()
        RuntimeIconButtonScope(RuntimeActionAppearance(RuntimeTextEntryAppearance(visual), draft)).configure()
        draft.appearance = visual.toFrozen()
        target +=
            state.node(
                PresentationElement.createIconButton(
                    icon = expression(icon),
                    semanticLabel = expression(semanticLabel),
                    action = action,
                    appearance = draft.toFrozen(),
                ),
            )
    }

    override fun tooltip(
        message: Expr<String, Handled>,
        configure: TooltipAppearanceScope.() -> Unit,
        body: Layout.() -> Unit,
    ) {
        val visual =
            skirout.editor.v1.presentation.InputAppearance
                .partial()
                .toMutable()
        val draft =
            skirout.editor.v1.presentation.TooltipAppearance
                .partial()
                .toMutable()
        RuntimeTooltipAppearanceScope(RuntimeTextEntryAppearance(visual), draft).configure()
        draft.appearance = visual.toFrozen()
        target +=
            state.node(
                PresentationElement.createTooltip(
                    message = expression(message),
                    child = state.presentation(body),
                    appearance = draft.toFrozen(),
                ),
            )
    }

    override fun commitControls(binding: PresentationInput<*, *>) {
        target += state.node(PresentationElement.createCommitControls(binding = binding.binding))
    }

    override fun menu(
        label: Expr<String, Handled>?,
        body: MenuScope.() -> Unit,
    ) {
        val visual =
            skirout.editor.v1.presentation.InputAppearance
                .partial()
                .toMutable()
        val draft =
            skirout.editor.v1.presentation.ActionAppearance
                .partial()
                .toMutable()
        val popup =
            skirout.editor.v1.presentation.PopupAppearance
                .partial()
                .toMutable()
        val scope =
            RuntimeMenuScope(RuntimeActionAppearance(RuntimeTextEntryAppearance(visual), draft), RuntimePopupAppearance(popup), state)
        scope.body()
        draft.appearance = visual.toFrozen()
        target +=
            state.node(
                PresentationElement.createMenu(
                    label = label?.let(::expression),
                    items = scope.items.toList(),
                    appearance = draft.toFrozen(),
                    popup = popup.toFrozen(),
                ),
            )
    }
}

internal class RuntimeActionAppearance(
    appearance: InputAppearanceScope,
    private val target: skirout.editor.v1.presentation.ActionAppearance.Mutable,
) : ActionAppearanceScope,
    InputAppearanceScope by appearance {
    override fun variant(value: ButtonVariant) {
        target.variant = value
    }

    override fun tooltip(value: String) {
        target.tooltip = expression(value)
    }

    override fun tooltip(value: Expr<String, Handled>) {
        target.tooltip = expression(value)
    }
}

internal class RuntimeButtonScope(
    appearance: ActionAppearanceScope,
    glyph: GlyphContentScope,
) : ButtonScope,
    ActionAppearanceScope by appearance,
    GlyphContentScope by glyph

internal class RuntimeIconButtonScope(
    appearance: ActionAppearanceScope,
) : IconButtonScope,
    ActionAppearanceScope by appearance

internal class RuntimeMenuItemScope(
    glyph: GlyphContentScope,
    private val target: skirout.editor.v1.presentation.MenuItem.Mutable,
) : MenuItemScope,
    GlyphContentScope by glyph {
    override fun description(value: String) {
        target.description = expression(value)
    }

    override fun description(value: Expr<String, Handled>) {
        target.description = expression(value)
    }

    override fun enabledIf(value: Expr<Boolean, Handled>) {
        target.enabledIf = expression(value)
    }

    override fun disabledReason(value: String) {
        target.disabledReason = expression(value)
    }

    override fun disabledReason(value: Expr<String, Handled>) {
        target.disabledReason = expression(value)
    }
}

internal class RuntimeMenuScope(
    appearance: ActionAppearanceScope,
    popup: PopupAppearanceScope,
    private val state: PresentationBuildState,
) : MenuScope,
    ActionAppearanceScope by appearance,
    PopupAppearanceScope by popup {
    val items = mutableListOf<skirout.editor.v1.presentation.MenuItem>()

    override fun item(
        id: String,
        label: Expr<String, Handled>,
        action: EditorAction,
        configure: MenuItemScope.() -> Unit,
    ) {
        require(id.isNotBlank() && items.none { it.itemId == id }) { "Menu item identifiers must be nonempty and unique." }
        state.action(action)
        val draft =
            skirout.editor.v1.presentation
                .MenuItem(
                    itemId = id,
                    label = expression(label),
                    action = action,
                    icon = null,
                    description = null,
                    enabledIf = null,
                    disabledReason = null,
                    separator = false,
                ).toMutable()
        val glyph = RuntimeGlyphContent(state) { draft.icon = (it as? skirout.editor.v1.presentation.InputAdornment.ContentWrapper)?.value }
        RuntimeMenuItemScope(glyph, draft).configure()
        items += draft.toFrozen()
    }

    override fun separator(id: String) {
        require(id.isNotBlank() && items.none { it.itemId == id }) { "Menu item identifiers must be nonempty and unique." }
        items +=
            skirout.editor.v1.presentation.MenuItem(
                itemId = id,
                label = expression(""),
                action = null,
                icon = null,
                description = null,
                enabledIf = null,
                disabledReason = null,
                separator = true,
            )
    }
}
