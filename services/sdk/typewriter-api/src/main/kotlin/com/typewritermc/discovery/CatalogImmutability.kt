package com.typewritermc.discovery

import com.typewritermc.checking.DiagnosticTemplate
import com.typewritermc.configuration.ConfigurationRecipe
import com.typewritermc.configuration.OwnedRule
import com.typewritermc.configuration.RelativeFieldPattern
import com.typewritermc.types.EndpointBindingTemplate
import com.typewritermc.types.RelationContract
import com.typewritermc.types.immutableListCopy
import com.typewritermc.types.immutableSetCopy

/*
 * Copies of the catalog models the Realm and engines still read as Kotlin classes, so an assembly retains no caller
 * supplied collection. The published editor catalog is Skir and deeply immutable by construction.
 */

internal fun RelationContract.immutableCopy(): RelationContract = copy(families = families.immutableSetCopy())

internal fun EndpointBindingTemplate.immutableCopy(): EndpointBindingTemplate = copy(relativePath = relativePath.immutableCopy())

internal fun ConfigurationRecipe.immutableCopy(): ConfigurationRecipe =
    copy(
        relativePath = relativePath.immutableCopy(),
        rules = rules.immutableListCopy(OwnedRule::immutableCopy),
    )

private fun OwnedRule.immutableCopy(): OwnedRule = copy(diagnostic = diagnostic.immutableCopy())

private fun DiagnosticTemplate.immutableCopy(): DiagnosticTemplate =
    copy(targets = targets.immutableListCopy(RelativeFieldPattern::immutableCopy))

private fun RelativeFieldPattern.immutableCopy(): RelativeFieldPattern = copy(segments = segments.immutableListCopy())
