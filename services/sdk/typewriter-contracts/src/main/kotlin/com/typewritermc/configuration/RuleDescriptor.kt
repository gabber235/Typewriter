package com.typewritermc.configuration

import com.typewritermc.checking.DiagnosticTemplate
import com.typewritermc.presentation.ExpressionNode
import kotlinx.serialization.Serializable

@Serializable
data class RuleId(
    val origin: RuleOrigin,
    val localIndex: Int,
)

@Serializable
data class RuleDescriptor(
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
