package com.typewritermc.configuration

import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.types.catalog.CheckedType
import com.typewritermc.types.catalog.DeclarationDiagnostic
import com.typewritermc.types.catalog.Resolution

class CheckedRule internal constructor(
    val catalog: CatalogGeneration,
    val rule: OwnedRule,
    val subject: CheckedType,
)

interface PortableRuleCompiler {
    fun compile(
        rule: OwnedRule,
        subject: CheckedType,
    ): Resolution<CheckedRule>
}

interface PredicateReasoner {
    fun contradictions(rules: List<CheckedRule>): List<DeclarationDiagnostic>
}
