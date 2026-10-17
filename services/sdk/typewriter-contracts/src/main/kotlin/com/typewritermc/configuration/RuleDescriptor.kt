package com.typewritermc.configuration

import com.typewritermc.checking.DiagnosticTemplate
import com.typewritermc.expression.ExpressionNodeSerializer
import kotlinx.serialization.Serializable
import skirout.editor.v1.expression.ExpressionNode

@Serializable
data class RuleId(
    val origin: RuleOrigin,
    val localIndex: Int,
)

@Serializable
data class RuleDescriptor(
    @Serializable(with = ExpressionNodeSerializer::class)
    val predicate: ExpressionNode,
)

@Serializable
data class OwnedRule(
    val id: RuleId,
    val descriptor: RuleDescriptor,
    val diagnostic: DiagnosticTemplate,
)

@Serializable
data class EffectiveFieldConfiguration(
    val guarantees: List<OwnedRule>,
)
