package com.typewritermc.authoring

import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeCatalog

/** Stable identity for one graph validation rule. */
@JvmInline
value class AuthoringValidationRuleId(
    val value: String,
) {
    init {
        require(value.isNotBlank()) { "Validation rule ids must not be blank." }
    }
}

/** One machine readable authoring diagnostic returned by a policy. */
data class AuthoringDiagnostic(
    val code: String,
    val message: String,
    val resources: Set<ResourceId> = emptySet(),
    val edges: Set<String> = emptySet(),
) {
    init {
        require(code.isNotBlank()) { "Authoring diagnostic codes must not be blank." }
        require(message.isNotBlank()) { "Authoring diagnostic messages must not be blank." }
    }
}

/** Pure graph rule executed against one bounded before and proposed graph. */
interface AuthoringValidationRule {
    val id: AuthoringValidationRuleId
    val graphRequirement: GraphReadRequirement

    fun validate(context: AuthoringValidationContext): List<AuthoringDiagnostic>
}

data class AuthoringValidationContext(
    val catalog: TypeCatalog,
    val before: AuthoringWorkingGraph,
    val proposed: AuthoringWorkingGraph,
    val change: AuthoringChangeSummary,
)
