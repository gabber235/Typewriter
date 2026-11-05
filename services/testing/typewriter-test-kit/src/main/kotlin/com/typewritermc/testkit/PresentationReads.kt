package com.typewritermc.testkit

import com.typewritermc.presentation.allNodes
import com.typewritermc.types.requirePortable
import skirout.editor.v1.action.EditorAction
import skirout.editor.v1.expression.ExpressionNode
import skirout.editor.v1.presentation.BoundControl
import skirout.editor.v1.presentation.PresentationElement
import skirout.editor.v1.presentation.PresentationNode
import skirout.editor.v1.presentation.PresentationNumber
import skirout.editor.v1.presentation.ResourcesElement
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.PathSegment
import skirout.editor.v1.presentation.PresentationColor as WireColor

/** The portable value of this literal expression; fails when the expression is not a literal. */
fun ExpressionNode?.literalValue(): DataValue = (this as ExpressionNode.LiteralWrapper).value.requirePortable()

/** The number of this literal expression; fails when it is not a float literal. */
fun ExpressionNode.literalFloat(): Double = (literalValue() as DataValue.FloatWrapper).value

/** The number of this literal presentation number; fails when it is not a literal value. */
fun PresentationNumber.literalFloat(): Double = (this as PresentationNumber.ValueWrapper).value.literalFloat()

/** The literal string of the only text element in this layout. */
fun PresentationNode?.literalText(): String =
    (
        requireNotNull(
            this,
        ).elementsOf<PresentationElement.TextWrapper>().single().value.value.literalValue() as DataValue.StringValueWrapper
    ).value

/** The literal icon name of the only icon element in this layout. */
fun PresentationNode?.iconName(): String =
    (
        requireNotNull(
            this,
        ).elementsOf<PresentationElement.IconWrapper>().single().value.name.literalValue() as DataValue.StringValueWrapper
    ).value

/** The control of this scalar input node; fails when the node is not a scalar input. */
fun PresentationNode.boundControl(): BoundControl =
    when (val value = element) {
        is PresentationElement.TextInputWrapper -> value.value.control
        is PresentationElement.NumericInputWrapper -> value.value.control
        else -> error("Expected a scalar input, found $value.")
    }

/** The first resources element of this layout, in tree order. */
fun PresentationNode.resourcesElement(): ResourcesElement =
    allNodes().firstNotNullOf {
        (it.element as? PresentationElement.ResourcesWrapper)?.value
    }

/** The action of every button in this layout, in tree order. */
fun PresentationNode.actions(): List<EditorAction> =
    allNodes().mapNotNull {
        (it.element as? PresentationElement.ButtonWrapper)?.value?.action
    }

/** The fields of the presented resource's appearance that this node's text, icon and background color read. */
fun PresentationNode.appearanceReads(): List<String> {
    val expressions =
        when (val element = element) {
            is PresentationElement.TextWrapper -> listOf(element.value.value)
            is PresentationElement.IconWrapper -> listOf(element.value.name)
            is PresentationElement.ContainerWrapper -> listOfNotNull((element.value.backgroundColor as? WireColor.ValueWrapper)?.value)
            else -> emptyList()
        }
    return expressions.mapNotNull { expression ->
        val input = (expression as? ExpressionNode.InputWrapper)?.value ?: return@mapNotNull null
        if (input.binding.value != "presentation.subject.appearance") return@mapNotNull null
        (input.path.segments.single() as PathSegment.FieldWrapper).value.name
    }
}
