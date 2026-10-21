package com.typewritermc.types.catalog

import com.typewritermc.types.ResourceTarget
import skirout.editor.v1.expression.ExpressionNode

/**
 * Compiled name, accent and icon formulas of one declared resource display. Each formula reads only the subject
 * resource through the configured value binding; editors evaluate the most specific formulas for a resource.
 */
data class ResourceDisplayFormulas(
    val target: ResourceTarget,
    val label: ExpressionNode,
    val accent: ExpressionNode,
    val icon: ExpressionNode,
)
