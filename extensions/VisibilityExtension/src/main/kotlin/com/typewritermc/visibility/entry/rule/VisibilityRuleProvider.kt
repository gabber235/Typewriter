package com.typewritermc.visibility.entry.rule

import com.typewritermc.core.extension.annotations.Tags
import com.typewritermc.engine.paper.entry.ManifestEntry
import com.typewritermc.visibility.rule.VisibilityRuler

/**
 * An entry that contributes visibility rules to the system.
 *
 * The [com.typewritermc.visibility.VisibilityEngine] queries all providers when it initializes
 * and creates one ruler per provider. Implement this to add new ways of deciding which viewer
 * and target pairs a visibility effect applies to.
 */
@Tags("visibility_rule_provider")
interface VisibilityRuleProvider : ManifestEntry {
    /**
     * Creates the stateful ruler that manages this entry's rules.
     */
    fun createRuler(): VisibilityRuler
}
