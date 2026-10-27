package com.typewritermc.presentation

import com.typewritermc.authoring.field
import com.typewritermc.authoring.root
import com.typewritermc.types.qualified
import skirout.editor.v1.binding.BindingRef
import skirout.editor.v1.presentation.AxisChild
import skirout.editor.v1.presentation.AxisChildrenElement
import skirout.editor.v1.presentation.BoundControl
import skirout.editor.v1.presentation.ChildrenElement
import skirout.editor.v1.presentation.PresentationElement
import skirout.editor.v1.presentation.PresentationNode
import skirout.editor.v1.presentation.TextControl
import skirout.editor.v1.type_catalog.ExpressionBindingId
import skirout.editor.v1.type_catalog.PresentationId
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeTemplate
import skirout.editor.v1.type_catalog.ValuePath

/** The field node whose prefix is a scoped alias of [source] over [child], as the alias editor declares it. */
fun scopedNameNode(
    source: BindingRef,
    child: PresentationNode,
): PresentationNode =
    fieldNode("name").copy(
        element =
            PresentationElement.TextInputWrapper(
                TextControl.partial(
                    control =
                        fieldControl("name").copy(
                            prefix =
                                PresentationNode.partial(
                                    nodeId = "scope",
                                    element =
                                        PresentationElement.createScopedBinding(
                                            binding = source,
                                            scopeBinding = declared("alias"),
                                            child = child,
                                        ),
                                ),
                        ),
                ),
            ),
    )

/** A name field whose prefix is a custom invocation that reads [input] as its argument. */
fun invocationNameNode(input: String): PresentationNode {
    val invocation =
        PresentationNode.partial(
            nodeId = "invoked",
            element =
                PresentationElement.createInvocation(
                    presentationId =
                        skirout.editor.v1.type_catalog
                            .PresentationId(namespace = "test", name = "input"),
                    arguments =
                        listOf(
                            skirout.editor.v1.presentation.PresentationArgument(
                                input = ExpressionBindingId(value = input),
                                binding = fieldControl("name").binding,
                            ),
                        ),
                ),
        )
    return fieldNode("name").copy(
        element =
            PresentationElement.TextInputWrapper(
                TextControl.partial(
                    control = fieldControl("name").copy(prefix = invocation),
                ),
            ),
    )
}

fun fieldControl(field: String): BoundControl =
    BoundControl.partial(
        binding =
            BindingRef(
                bindingId = ExpressionBindingId(value = "configured_value"),
                path = ValuePath.root.field(field),
            ),
    )

fun fieldNode(field: String): PresentationNode =
    PresentationNode.partial(
        nodeId = field,
        element = PresentationElement.TextInputWrapper(TextControl.partial(control = fieldControl(field))),
    )

fun column(
    id: String,
    vararg children: PresentationNode,
): PresentationNode =
    PresentationNode.partial(
        nodeId = id,
        element =
            PresentationElement.ChildrenWrapper(
                ChildrenElement.ColumnWrapper(AxisChildrenElement.partial(children = children.map { AxisChild.FixedWrapper(it) })),
            ),
    )

fun partNode(
    name: String,
    body: PresentationNode?,
): PresentationNode =
    PresentationNode.partial(
        nodeId = name,
        element =
            PresentationElement.createPart(
                key =
                    skirout.editor.v1.presentation.PresentationPartId(
                        owner = TypeDefinitionId.qualified("test", "PartOwner"),
                        name = name,
                    ),
                body = body,
            ),
    )

fun remainder(id: String): PresentationNode =
    PresentationNode.partial(
        nodeId = id,
        element = PresentationElement.createRemainingFields(excluded = emptyList(), excludedParts = emptyList()),
    )

/** A binding declaration whose type does not matter to write scope inference. */
fun declared(id: String): skirout.editor.v1.presentation.BindingDeclaration =
    skirout.editor.v1.presentation.BindingDeclaration
        .partial(id = ExpressionBindingId(value = id))

fun neutralPlacements(): Map<String, ChildrenElement> {
    val child = fieldNode("name")
    return mapOf(
        "row" to ChildrenElement.RowWrapper(AxisChildrenElement.partial(children = listOf(AxisChild.FixedWrapper(child)))),
        "wrap" to
            ChildrenElement.WrapWrapper(
                skirout.editor.v1.presentation.WrapChildrenElement
                    .partial(children = listOf(child)),
            ),
        "grid" to
            ChildrenElement.GridWrapper(
                skirout.editor.v1.presentation.GridChildrenElement
                    .partial(children = listOf(child)),
            ),
        "stack flow" to
            ChildrenElement.StackWrapper(
                skirout.editor.v1.presentation.StackChildrenElement
                    .partial(
                        children =
                            listOf(
                                skirout.editor.v1.presentation.StackChild
                                    .FlowWrapper(child),
                            ),
                    ),
            ),
        "stack positioned" to
            ChildrenElement.StackWrapper(
                skirout.editor.v1.presentation.StackChildrenElement.partial(
                    children =
                        listOf(
                            skirout.editor.v1.presentation.StackChild.createPositioned(
                                child = child,
                                top = null,
                                start = null,
                                end = null,
                                bottom = null,
                                width = null,
                                height = null,
                                transition = null,
                            ),
                        ),
                ),
            ),
    )
}

fun behavioralBoundaries(): Map<String, PresentationElement> {
    val child = fieldNode("name")
    return mapOf(
        "repeated element" to
            PresentationElement.RepeatedWrapper(
                skirout.editor.v1.presentation.RepeatedElement.partial(
                    presentation =
                        skirout.editor.v1.presentation.SequencePresentation
                            .partial(item = child),
                ),
            ),
        "appearance default" to
            PresentationElement.AppearanceDefaultsWrapper(
                skirout.editor.v1.presentation.AppearanceDefaultsElement
                    .partial(child = child),
            ),
        "polymorphic match" to
            PresentationElement.PolymorphicMatchWrapper(
                skirout.editor.v1.presentation.PolymorphicMatchElement
                    .partial(fallback = child),
            ),
        "collection lookup" to
            PresentationElement.CollectionLookupWrapper(
                skirout.editor.v1.presentation.CollectionLookupElement
                    .partial(found = child, missing = child),
            ),
        "conditional" to
            PresentationElement.createConditional(
                condition =
                    skirout.editor.v1.expression.ExpressionNode.LiteralWrapper(
                        skirout.editor.v1.type_catalog.DataValue
                            .BooleanWrapper(true),
                    ),
                whenTrue = child,
                whenFalse = null,
            ),
        "scoped binding" to
            PresentationElement.createScopedBinding(
                binding = fieldControl("name").binding,
                scopeBinding = declared("scope"),
                child = child,
            ),
        "typed field" to
            PresentationElement.createTypedField(
                binding = fieldControl("name").binding,
                expectedType =
                    skirout.editor.v1.type_catalog.TypeTemplate
                        .ScalarWrapper(skirout.editor.v1.type_catalog.ScalarKind.TEXT),
                presentation = child,
            ),
        "padding" to
            PresentationElement.createPadding(
                child = child,
                top = 0.0,
                start = 0.0,
                end = 0.0,
                bottom = 0.0,
            ),
    )
}

fun writesOutsideOwner(): Map<String, PresentationNode> =
    mapOf(
        "an owner remainder" to remainder("owner remainder"),
        "an editor bound to a foreign binding" to
            fieldNode("name").copy(
                element =
                    PresentationElement.TextInputWrapper(
                        TextControl.partial(
                            control =
                                fieldControl(
                                    "name",
                                ).copy(binding = BindingRef.partial(bindingId = ExpressionBindingId(value = "foreign"))),
                        ),
                    ),
            ),
        "an editor writing the whole owner" to
            fieldNode("name").copy(
                element =
                    PresentationElement.TextInputWrapper(
                        TextControl.partial(
                            control = fieldControl("name").copy(binding = fieldControl("name").binding.copy(path = ValuePath.partial())),
                        ),
                    ),
            ),
    )
