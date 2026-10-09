package com.typewritermc.presentation

import com.typewritermc.expression.Expr
import com.typewritermc.expression.Handled
import skirout.editor.v1.action.EditorAction
import skirout.editor.v1.presentation.PresentationElement
import skirout.editor.v1.presentation.PresentationNode

internal class RuntimePresentationInteractions(
    private val state: PresentationBuildState,
    private val target: MutableList<PresentationNode>,
) : PresentationInteractions {
    override fun button(
        label: Expr<String, Handled>,
        action: EditorAction,
    ) {
        target += state.node(PresentationElement.createButton(label = expression(label), action = action))
    }

    override fun iconButton(
        icon: Expr<String, Handled>,
        semanticLabel: Expr<String, Handled>,
        action: EditorAction,
    ) {
        target +=
            state.node(
                PresentationElement.createIconButton(
                    icon = expression(icon),
                    semanticLabel = expression(semanticLabel),
                    action = action,
                ),
            )
    }

    override fun tooltip(
        message: Expr<String, Handled>,
        body: Layout.() -> Unit,
    ) {
        target += state.node(PresentationElement.createTooltip(message = expression(message), child = state.presentation(body)))
    }

    override fun commitControls(binding: PresentationInput<*, *>) {
        target += state.node(PresentationElement.createCommitControls(binding = binding.binding))
    }

    override fun menu(
        label: Expr<String, Handled>?,
        body: MenuScope.() -> Unit,
    ) {
        val items = mutableListOf<skirout.editor.v1.presentation.MenuItem>()
        val scope =
            object : MenuScope {
                override fun item(
                    id: String,
                    label: Expr<String, Handled>,
                    action: skirout.editor.v1.action.EditorAction,
                ) {
                    items +=
                        skirout.editor.v1.presentation.MenuItem(
                            itemId = id,
                            label = expression(label),
                            action = action,
                        )
                }
            }
        scope.body()
        target +=
            state.node(
                PresentationElement.createMenu(
                    label = label?.let(::expression),
                    items = items,
                ),
            )
    }
}
