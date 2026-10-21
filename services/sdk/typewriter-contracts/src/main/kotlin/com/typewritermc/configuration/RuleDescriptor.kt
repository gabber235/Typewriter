package com.typewritermc.configuration

import com.typewritermc.checking.DiagnosticTemplate
import com.typewritermc.expression.ExpressionNodeSerializer
import kotlinx.serialization.Serializable
import skirout.editor.v1.expression.ExpressionNode
import skirout.editor.v1.type_catalog.RuleId

@Serializable
data class RuleDescriptor(
    @Serializable(with = ExpressionNodeSerializer::class)
    val predicate: ExpressionNode,
)

data class OwnedRule(
    val id: RuleId,
    val descriptor: RuleDescriptor,
    val diagnostic: DiagnosticTemplate,
)

data class EffectiveFieldConfiguration(
    val guarantees: List<OwnedRule>,
)
