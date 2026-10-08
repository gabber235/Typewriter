package com.typewritermc.presentation

import com.typewritermc.discovery.GraphDirection
import com.typewritermc.expression.Expr
import com.typewritermc.expression.ExpressionBindingId
import com.typewritermc.expression.Handled
import com.typewritermc.types.CollectionKind
import com.typewritermc.types.TypeTemplate
import com.typewritermc.types.skir.SkirTypeCodec
import com.typewritermc.types.skir.getOrThrow
import skirout.editor.v1.binding.BindingRef
import skirout.editor.v1.presentation.BoundControl
import skirout.editor.v1.presentation.PageGraphDirection
import skirout.editor.v1.presentation.PresentationElement
import skirout.editor.v1.presentation.PresentationNode
import java.lang.reflect.InvocationHandler
import java.lang.reflect.Method
import skirout.editor.v1.presentation.PresentationProperties as WirePresentationProperties
import skirout.editor.v1.type_catalog.ExpressionBindingId as WireExpressionBindingId
import skirout.editor.v1.type_catalog.ValuePath as WireValuePath

internal class PresentationControlHandler(
    private val state: PresentationBuildState,
    private val target: MutableList<PresentationNode>,
    private val field: String,
    private val fieldBinding: BindingRef,
    private val checked: CheckedPresentationTemplate,
    private val nested: Map<NestedPresentationSlot, NestedPresentationScope>,
    private val selectedPresentation: skirout.editor.v1.type_catalog.PresentationId?,
) : InvocationHandler {
    var emitted = false
        private set
    private var label: skirout.editor.v1.expression.ExpressionNode? = null
    private var description: skirout.editor.v1.expression.ExpressionNode? = null
    private var semanticLabel: skirout.editor.v1.expression.ExpressionNode? = null
    private var enabledIf: skirout.editor.v1.expression.ExpressionNode? = null
    private var prefix: PresentationNode? = null
    private var readOnly = false

    override fun invoke(
        proxy: Any,
        method: Method,
        arguments: Array<out Any?>?,
    ): Any? {
        val args = arguments.orEmpty()
        return when (method.presentationOperationName()) {
            "label" -> {
                label = expression(args.single())
            }

            "description" -> {
                description = expression(args.single())
            }

            "semanticLabel" -> {
                semanticLabel = expression(args.single())
            }

            "enabledIf" -> {
                enabledIf = expression(args.single())
            }

            "readOnly" -> {
                readOnly = args.single() as Boolean
            }

            "textInput" -> {
                val multiline = args.getOrNull(0) as? Boolean
                val placeholder = args.getOrNull(1)?.let(::expression)
                val formats =
                    (args.getOrNull(2) as? List<*>).orEmpty().map { format ->
                        when (format) {
                            TextInputFormat.Trim -> {
                                skirout.editor.v1.presentation.TextInputFormat.createReplace(
                                    pattern = "^\\s+|\\s+$",
                                    replacement = "",
                                )
                            }

                            is TextInputFormat.Pattern -> {
                                skirout.editor.v1.presentation.TextInputFormat
                                    .AllowWrapper(format.regex)
                            }

                            else -> {
                                throw IllegalArgumentException("Unknown text input formatter $format.")
                            }
                        }
                    }
                emit(
                    PresentationElement.createTextInput(
                        control = boundControl(),
                        multiline = multiline,
                        placeholder = placeholder,
                        inputFormatters = formats,
                    ),
                )
            }

            "selectInput" -> {
                val options =
                    (args[0] as List<*>).map { option ->
                        option as SelectOption<*>
                        skirout.editor.v1.presentation.SelectOption(
                            optionId = option.id,
                            label = expression(option.label),
                            value = expression(option.value),
                        )
                    }
                emit(
                    PresentationElement.createSelectInput(
                        control = boundControl(),
                        options = options,
                        allowCustomValue = args[1] as Boolean,
                    ),
                )
            }

            "sliderInput" -> {
                emit(
                    PresentationElement.createSliderInput(
                        control = boundControl(),
                        minimum = expression(args[0]),
                        maximum = expression(args[1]),
                        divisions = args.getOrNull(2)?.let(::expression),
                    ),
                )
            }

            "searchInput" -> {
                val search = RuntimeSearchInputScope<Any?, Any?>(state)
                invokeBlock(args.single(), search)
                emit(search.element(boundControl()))
            }

            "namedInput" -> {
                emit(
                    PresentationElement.createNamedInput(
                        control = boundControl(),
                        payloadPresentation = nestedPresentation(args.singleOrNull(), NestedPresentationSlot.Payload),
                    ),
                )
            }

            "recordInput" -> {
                emit(
                    PresentationElement.createRecordInput(
                        control = boundControl(),
                        fieldPresentation = nestedPresentation(args.singleOrNull(), NestedPresentationSlot.Fields),
                    ),
                )
            }

            "graphPage" -> {
                val direction =
                    when (args.single() as GraphDirection) {
                        GraphDirection.LEFT_TO_RIGHT -> PageGraphDirection.LEFT_TO_RIGHT
                        GraphDirection.RIGHT_TO_LEFT -> PageGraphDirection.RIGHT_TO_LEFT
                        GraphDirection.TOP_TO_BOTTOM -> PageGraphDirection.TOP_TO_BOTTOM
                        GraphDirection.BOTTOM_TO_TOP -> PageGraphDirection.BOTTOM_TO_TOP
                    }
                emit(PresentationElement.createPageGraph(control = boundControl(), direction = direction))
            }

            "timelinePage" -> {
                emit(PresentationElement.createPageTimeline(control = boundControl()))
            }

            "listInput" -> {
                emit(
                    PresentationElement.createListInput(
                        control = boundControl(),
                        itemPresentation = nestedPresentation(args[3], NestedPresentationSlot.Items),
                        allowAdd = args[0] as Boolean,
                        allowRemove = args[1] as Boolean,
                        allowReorder = args[2] as Boolean,
                        itemBindingId = WireExpressionBindingId(value = "list_item"),
                        indexBindingId = WireExpressionBindingId(value = "list_index"),
                    ),
                )
            }

            "collectionInput" -> {
                emit(
                    PresentationElement.createSetInput(
                        control = boundControl(),
                        itemPresentation = nestedPresentation(args[2], NestedPresentationSlot.Items),
                        allowAdd = args[0] as Boolean,
                        allowRemove = args[1] as Boolean,
                        itemBindingId = WireExpressionBindingId(value = "set_item"),
                    ),
                )
            }

            "mapInput" -> {
                emit(
                    PresentationElement.createMapInput(
                        control = boundControl(),
                        keyPresentation = nestedPresentation(args[2], NestedPresentationSlot.Keys),
                        valuePresentation = nestedPresentation(args[3], NestedPresentationSlot.Values),
                        allowAdd = args[0] as Boolean,
                        allowRemove = args[1] as Boolean,
                        keyBindingId = WireExpressionBindingId(value = "map_key"),
                        valueBindingId = WireExpressionBindingId(value = "map_value"),
                    ),
                )
            }

            "nullableInput" -> {
                emit(
                    PresentationElement.createNullableInput(
                        control = boundControl(),
                        valuePresentation = nestedPresentation(args.singleOrNull(), NestedPresentationSlot.Values),
                    ),
                )
            }

            "polymorphicInput" -> {
                polymorphicInput(args.singleOrNull())
            }

            "linkInput" -> {
                linkInput(args)
            }

            "numericInput" -> {
                emit(PresentationElement.NumericInputWrapper(boundControl()))
            }

            "toggleInput" -> {
                emit(PresentationElement.ToggleInputWrapper(boundControl()))
            }

            "durationInput" -> {
                emit(PresentationElement.DurationInputWrapper(boundControl()))
            }

            "bytesInput" -> {
                emit(PresentationElement.BytesInputWrapper(boundControl()))
            }

            "enumInput" -> {
                emit(PresentationElement.EnumInputWrapper(boundControl()))
            }

            "colorInput" -> {
                val includeAlpha = args.getOrNull(0) as? Boolean ?: false
                emit(
                    PresentationElement.createColorInput(
                        control = boundControl(),
                        includeAlpha = includeAlpha,
                    ),
                )
            }

            "dateTimeInput" -> {
                emit(
                    PresentationElement.createDateTimeInput(
                        control = boundControl(),
                        includeDate = args.getOrNull(0) as? Boolean,
                        includeTime = args.getOrNull(1) as? Boolean,
                    ),
                )
            }

            "icon" -> {
                prefix =
                    state.node(
                        PresentationElement.createIcon(
                            name = expression(args.single()),
                            semanticLabel = null,
                            color = null,
                            size = null,
                        ),
                    )
            }

            "prefix" -> {
                val nodes = mutableListOf<PresentationNode>()
                state.withTarget(nodes) { invokeBlock(args.single(), state.scope(nodes)) }
                prefix = state.column(nodes)
            }

            "toString" -> {
                "ControlScope($field)"
            }

            "hashCode" -> {
                System.identityHashCode(proxy)
            }

            "equals" -> {
                proxy === args.singleOrNull()
            }

            else -> {
                throw UnsupportedOperationException("Control operation ${method.name} is not implemented.")
            }
        }
    }

    fun defaultPresentation() {
        emit(
            PresentationElement.createDefaultPresentation(
                binding = binding(),
                presentationId = selectedPresentation,
            ),
        )
    }

    private fun nestedPresentation(
        block: Any?,
        slot: NestedPresentationSlot,
    ): PresentationNode? {
        if (block == null) return null
        val descriptor = nested[slot] ?: return null
        val children = mutableListOf<PresentationNode>()
        val child = checked.nested(slot)
        val childBinding = fieldBinding.nested(slot, checked, child)
        val childType = child.type
        val build = state.scope(children, checked = childType, base = childBinding)
        var childControl: PresentationControlHandler? = null
        val receiver =
            descriptor.create?.invoke(build)
                ?: if (Layout::class.java.isAssignableFrom(descriptor.control.java)) {
                    build
                } else {
                    val handler =
                        PresentationControlHandler(
                            state,
                            children,
                            "$field.$slot",
                            childBinding,
                            childType,
                            descriptor.nested,
                            null,
                        )
                    childControl = handler
                    proxy(descriptor.control, handler)
                }
        state.withTarget(children) { invokeBlock(block, receiver) }
        childControl?.takeUnless(PresentationControlHandler::emitted)?.defaultPresentation()
        return children.takeIf(List<PresentationNode>::isNotEmpty)?.let(state::column)
    }

    private fun polymorphicInput(configuration: Any?) {
        val forms = mutableListOf<skirout.editor.v1.presentation.ConcreteTypePresentation>()
        val scope =
            object : ConcreteForms<Any?> {
                override fun <Subtype> form(
                    type: AppliedPresentation<Subtype>,
                    label: Expr<String, Handled>?,
                ) {
                    state.type(type.type)
                    val id =
                        requireNotNull(state.presentationId(type.reference, state.type.rebind(type.type.template()))) {
                            "A concrete form presentation must be registered before use."
                        }
                    forms +=
                        skirout.editor.v1.presentation.ConcreteTypePresentation(
                            concreteType = SkirTypeCodec.encode(type.type).getOrThrow(),
                            label = expression(label ?: type.type.definition.toString()),
                            presentation =
                                state.node(
                                    PresentationElement.createInvocation(
                                        presentationId =
                                            skirout.editor.v1.type_catalog.PresentationId(
                                                namespace = id.namespace,
                                                name = id.name,
                                            ),
                                        arguments = emptyList(),
                                    ),
                                ),
                        )
                }
            }
        invokeBlock(configuration, scope)
        emit(PresentationElement.createPolymorphicInput(control = boundControl(), concreteTypes = forms))
    }

    private fun linkInput(args: Array<out Any?>) {
        val collection = args.size == 4
        val allowReorder = if (collection) args[0] as Boolean else false
        val source = args[if (collection) 1 else 0] as? CollectionSource<*, *>
        val policy =
            when (val value = args[if (collection) 2 else 1]) {
                is LinkCandidatePolicyId -> value.value
                is String -> value
                null -> null
                else -> error("A link candidate policy must be represented by its string value.")
            }
        val rejection = args[if (collection) 3 else 2] as LinkRejectionDisplay
        source?.let(state::collection)
        emit(
            PresentationElement.createLinkInput(
                control = boundControl(),
                allowReorder = allowReorder,
                candidatePolicy =
                    policy?.let {
                        skirout.editor.v1.presentation
                            .LinkCandidatePolicyId(value = it)
                    },
                rejectionDisplay =
                    when (rejection) {
                        LinkRejectionDisplay.Hidden -> skirout.editor.v1.presentation.LinkRejectionDisplay.HIDDEN
                        LinkRejectionDisplay.DisabledWithReason -> skirout.editor.v1.presentation.LinkRejectionDisplay.DISABLED
                    },
                sourceId = source?.id,
            ),
        )
    }

    private fun boundControl(): BoundControl =
        BoundControl(
            binding = binding(),
            label = label,
            description = description,
            prefix = prefix,
            semanticLabel = semanticLabel,
        )

    private fun binding(): BindingRef = fieldBinding

    private fun emit(element: PresentationElement) {
        require(selectedPresentation == null || element is PresentationElement.DefaultPresentationWrapper) {
            "A named presentation reference cannot be combined with an explicit field control."
        }
        check(!emitted) { "A field presentation may emit one control." }
        target +=
            state.node(
                element,
                WirePresentationProperties(enabledIf = enabledIf, readOnly = readOnly),
            )
        emitted = true
    }
}

private fun BindingRef.nested(
    slot: NestedPresentationSlot,
    checked: CheckedPresentationTemplate,
    nested: CheckedPresentationNested,
): BindingRef =
    when (slot) {
        NestedPresentationSlot.Payload, NestedPresentationSlot.Fields -> {
            this
        }

        NestedPresentationSlot.Items -> {
            val bindingId =
                when (requireNotNull(nested.collectionKind)) {
                    CollectionKind.List -> "list_item"
                    CollectionKind.Set -> "set_item"
                }
            BindingRef(
                path = WireValuePath(segments = emptyList()),
                bindingId = ExpressionBindingId(bindingId).wire(),
            )
        }

        NestedPresentationSlot.Keys -> {
            BindingRef(
                path = WireValuePath(segments = emptyList()),
                bindingId = ExpressionBindingId("map_key").wire(),
            )
        }

        NestedPresentationSlot.Values -> {
            if (checked.type is TypeTemplate.Nullable) {
                this
            } else {
                BindingRef(
                    path = WireValuePath(segments = emptyList()),
                    bindingId = ExpressionBindingId("map_value").wire(),
                )
            }
        }
    }
