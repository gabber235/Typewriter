package com.typewritermc.presentation

import com.typewritermc.expression.Expr
import com.typewritermc.expression.Handled
import skirout.editor.v1.binding.BindingRef
import skirout.editor.v1.presentation.PresentationElement
import skirout.editor.v1.presentation.PresentationNode
import java.lang.reflect.InvocationHandler
import java.lang.reflect.Method
import kotlin.reflect.KClass

internal class PresentationLayoutHandler(
    val state: PresentationBuildState,
    val target: MutableList<PresentationNode>,
    val axis: PresentationAxisNodeList? = null,
    val checked: CheckedPresentationTemplate,
    val base: BindingRef,
) : InvocationHandler {
    override fun invoke(
        proxy: Any,
        method: Method,
        arguments: Array<out Any?>?,
    ): Any? {
        val args = arguments.orEmpty()
        return when (method.presentationOperationName()) {
            "getRole" -> {
                state.role
            }

            "value" -> {
                presentedValue(
                    args[0] as KClass<*>,
                    args.getOrNull(1) as? Map<NestedPresentationSlot, NestedPresentationScope> ?: emptyMap(),
                )
            }

            "field" -> {
                presentedField(
                    args[0] as String,
                    args[1] as KClass<*>,
                    args.getOrNull(2) as? Map<NestedPresentationSlot, NestedPresentationScope> ?: emptyMap(),
                )
            }

            "expressions" -> {
                expressions(args.single() as KClass<*>)
            }

            "conditional" -> {
                conditional(args[0] as Expr<Boolean, Handled>, args[1], args[2])
            }

            "resourceCollection" -> {
                resourceCollection(args)
            }

            "repeated" -> {
                repeated(args)
            }

            "scoped" -> {
                scoped(args, typed = false)
            }

            "typedField" -> {
                scoped(args, typed = true)
            }

            "collectionLookup" -> {
                collectionLookup(args)
            }

            "collectionGraph" -> {
                collectionGraph(args)
            }

            "polymorphicMatch" -> {
                polymorphicMatch(args)
            }

            "remainingFields" -> {
                remainingFields(args.single())
            }

            "column" -> {
                axisLayout(false, args)
            }

            "row" -> {
                axisLayout(true, args)
            }

            "wrap" -> {
                wrap(args)
            }

            "grid" -> {
                grid(args)
            }

            "stack" -> {
                stack(args.last())
            }

            "tabs" -> {
                tabs(args)
            }

            "adaptiveLeading" -> {
                adaptiveLeading(args.singleOrNull())
            }

            "anchors" -> {
                anchors(args)
            }

            "connectionLayer" -> {
                connectionLayer(args)
            }

            "node" -> {
                authoredNode(args)
            }

            "section" -> {
                section(args)
            }

            "padding" -> {
                padding(args)
            }

            "container" -> {
                container(args)
            }

            "showIf" -> {
                conditional(args[0] as Expr<Boolean, Handled>, args[1], args[2])
            }

            "tooltip" -> {
                tooltip(args)
            }

            "fixed" -> {
                fixed(args.last())
            }

            "flexible" -> {
                flexible(args)
            }

            "divider" -> {
                target += state.node(PresentationElement.DIVIDER)
            }

            "slot" -> {
                target += state.node(PresentationElement.createSlot(slotId = args.single() as String))
            }

            "spacer" -> {
                target +=
                    state.node(
                        PresentationElement.createSpacer(
                            width = args.getOrNull(0)?.let(::expression),
                            height = args.getOrNull(1)?.let(::expression),
                        ),
                    )
            }

            "text" -> {
                text(args)
            }

            "richText" -> {
                richText(args.singleOrNull())
            }

            "markdown" -> {
                markdown(args)
            }

            "icon" -> {
                icon(args)
            }

            "image" -> {
                target +=
                    state.node(
                        PresentationElement.createImage(
                            source = expression(args[0]),
                            semanticLabel = args.getOrNull(1)?.let(::expression),
                        ),
                    )
            }

            "badge" -> {
                target +=
                    state.node(
                        PresentationElement.createBadge(
                            label = expression(args[0]),
                            tone = args[1] as String,
                        ),
                    )
            }

            "chip" -> {
                target +=
                    state.node(
                        PresentationElement.createChip(
                            label = expression(args[0]),
                            color = args.getOrNull(1)?.let(::expression),
                        ),
                    )
            }

            "progress" -> {
                target +=
                    state.node(
                        PresentationElement.createProgress(
                            value = expression(args[0]),
                            maximum = expression(args[1]),
                            label = args.getOrNull(2)?.let(::expression),
                        ),
                    )
            }

            "status" -> {
                status(args)
            }

            "dateTime" -> {
                dateTime(args)
            }

            "relativeTime" -> {
                relativeTime(args)
            }

            "button" -> {
                target +=
                    state.node(
                        PresentationElement.createButton(
                            label = expression(args[0]),
                            action = args[1] as skirout.editor.v1.action.EditorAction,
                        ),
                    )
            }

            "iconButton" -> {
                target +=
                    state.node(
                        PresentationElement.createIconButton(
                            icon = expression(args[0]),
                            semanticLabel = expression(args[1]),
                            action = args[2] as skirout.editor.v1.action.EditorAction,
                        ),
                    )
            }

            "menu" -> {
                menu(args)
            }

            "commitControls" -> {
                val input = args.single() as PresentationInput<*, *>
                target += state.node(PresentationElement.createCommitControls(binding = input.binding))
            }

            "invoke" -> {
                invokePresentation(args)
            }

            "toString" -> {
                "PresentationBuildScope"
            }

            "hashCode" -> {
                System.identityHashCode(proxy)
            }

            "equals" -> {
                proxy === args.singleOrNull()
            }

            else -> {
                throw UnsupportedOperationException("Presentation operation ${method.name} is not implemented.")
            }
        }
    }
}
