package com.typewritermc.discovery

import com.typewritermc.authoring.immutableCopy
import com.typewritermc.checking.DiagnosticTemplate
import com.typewritermc.configuration.ConfigurationRecipe
import com.typewritermc.configuration.OwnedRule
import com.typewritermc.configuration.RelativeFieldPattern
import com.typewritermc.presentation.PresentationDescriptor
import com.typewritermc.types.EndpointBindingTemplate
import com.typewritermc.types.RelationContract
import com.typewritermc.types.catalog.DeclarationDiagnostic
import com.typewritermc.types.catalog.DeclarationStatus
import com.typewritermc.types.catalog.EditorCatalogSnapshot
import com.typewritermc.types.catalog.EffectiveFieldTemplate
import com.typewritermc.types.catalog.PublishedType
import com.typewritermc.types.immutableCopy
import com.typewritermc.types.immutableListCopy
import com.typewritermc.types.immutableSetCopy

internal fun EditorCatalogSnapshot.immutableCopy(): EditorCatalogSnapshot =
    copy(
        resourceOperations = resourceOperations.immutableListCopy(),
        types = types.immutableListCopy(PublishedType::immutableCopy),
        relations = relations.immutableListCopy(RelationContract::immutableCopy),
        presentations = presentations.immutableListCopy(PresentationDescriptor::immutableCopy),
        presentationMaterials = presentationMaterials.immutableListCopy(),
        configuration = configuration.immutableListCopy(ConfigurationRecipe::immutableCopy),
        diagnostics = diagnostics.immutableListCopy(DeclarationDiagnostic::immutableCopy),
        endpointBindings = endpointBindings.immutableListCopy(EndpointBindingTemplate::immutableCopy),
        capabilities = capabilities.immutableListCopy(),
        recommendations = recommendations.immutableListCopy(),
        roleFallbacks =
            roleFallbacks.immutableListCopy { fallback ->
                fallback.copy(parents = fallback.parents.immutableListCopy())
            },
        resourceDisplays = resourceDisplays.immutableListCopy(),
    )

private fun PublishedType.immutableCopy(): PublishedType =
    copy(
        status = status.immutableCopy(),
        effectiveFields = effectiveFields.immutableListCopy(EffectiveFieldTemplate::immutableCopy),
        ancestorTemplates = ancestorTemplates.immutableListCopy(),
    )

private fun DeclarationStatus.immutableCopy(): DeclarationStatus =
    when (this) {
        DeclarationStatus.Ready -> this
        is DeclarationStatus.Unavailable -> copy(reasons = reasons.immutableListCopy(DeclarationDiagnostic::immutableCopy))
    }

private fun EffectiveFieldTemplate.immutableCopy(): EffectiveFieldTemplate = copy(rules = rules.immutableListCopy())

private fun RelationContract.immutableCopy(): RelationContract =
    copy(
        families = families.immutableSetCopy(),
    )

private fun PresentationDescriptor.immutableCopy(): PresentationDescriptor = copy(roles = roles.immutableSetCopy())

private fun ConfigurationRecipe.immutableCopy(): ConfigurationRecipe =
    copy(
        relativePath = relativePath.immutableCopy(),
        rules = rules.immutableListCopy(OwnedRule::immutableCopy),
    )

private fun OwnedRule.immutableCopy(): OwnedRule =
    copy(
        diagnostic = diagnostic.immutableCopy(),
    )

private fun DiagnosticTemplate.immutableCopy(): DiagnosticTemplate =
    copy(targets = targets.immutableListCopy(RelativeFieldPattern::immutableCopy))

private fun EndpointBindingTemplate.immutableCopy(): EndpointBindingTemplate = copy(relativePath = relativePath.immutableCopy())

private fun DeclarationDiagnostic.immutableCopy(): DeclarationDiagnostic =
    copy(
        origins = origins.immutableListCopy(),
        field = field?.immutableCopy(),
    )

private fun RelativeFieldPattern.immutableCopy(): RelativeFieldPattern = copy(segments = segments.immutableListCopy())
