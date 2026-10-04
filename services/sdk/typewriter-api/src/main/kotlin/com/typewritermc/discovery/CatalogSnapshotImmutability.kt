package com.typewritermc.discovery

import com.typewritermc.authoring.InitializationDescriptor
import com.typewritermc.capability.RealmCapabilityDescriptor
import com.typewritermc.checking.DiagnosticTemplate
import com.typewritermc.configuration.ConfigurationRecipe
import com.typewritermc.configuration.OwnedRule
import com.typewritermc.configuration.RelativeFieldPattern
import com.typewritermc.presentation.ExpressionNode
import com.typewritermc.presentation.PresentationDescriptor
import com.typewritermc.presentation.PresentationMaterial
import com.typewritermc.presentation.PresentationTarget
import com.typewritermc.types.EndpointBindingTemplate
import com.typewritermc.types.EndpointDefinition
import com.typewritermc.types.RelationContract
import com.typewritermc.types.TypeTemplate
import com.typewritermc.types.TypeUse
import com.typewritermc.types.catalog.DeclarationDiagnostic
import com.typewritermc.types.catalog.DeclarationStatus
import com.typewritermc.types.catalog.EditorCatalogSnapshot
import com.typewritermc.types.catalog.EffectiveFieldTemplate
import com.typewritermc.types.catalog.PublishedType
import com.typewritermc.types.catalog.TypeRecommendation
import com.typewritermc.types.immutableCopy

internal fun EditorCatalogSnapshot.immutableCopy(): EditorCatalogSnapshot =
    copy(
        types = types.map(PublishedType::immutableCopy),
        relations = relations.map(RelationContract::immutableCopy),
        resourceDefinitions = resourceDefinitions.toList(),
        presentations = presentations.map(PresentationDescriptor::immutableCopy),
        presentationMaterials = presentationMaterials.map(PresentationMaterial::immutableCopy),
        configuration = configuration.map(ConfigurationRecipe::immutableCopy),
        diagnostics = diagnostics.map(DeclarationDiagnostic::immutableCopy),
        initialization = initialization.map(InitializationDescriptor::immutableCopy),
        endpointBindings = endpointBindings.map(EndpointBindingTemplate::immutableCopy),
        capabilities = capabilities.map(RealmCapabilityDescriptor::immutableCopy),
        recommendations = recommendations.map(TypeRecommendation::immutableCopy),
        roleFallbacks = roleFallbacks.map { fallback -> fallback.copy(parents = fallback.parents.toList()) },
    )

private fun PublishedType.immutableCopy(): PublishedType =
    copy(
        definition = definition.immutableCopy(),
        status = status.immutableCopy(),
        effectiveFields = effectiveFields.map(EffectiveFieldTemplate::immutableCopy),
        ancestorTemplates = ancestorTemplates.map { it.immutableCopy() as TypeTemplate.Named },
    )

private fun DeclarationStatus.immutableCopy(): DeclarationStatus =
    when (this) {
        DeclarationStatus.Ready -> this
        is DeclarationStatus.Unavailable -> copy(reasons = reasons.map(DeclarationDiagnostic::immutableCopy))
    }

private fun EffectiveFieldTemplate.immutableCopy(): EffectiveFieldTemplate =
    copy(
        type = type.immutableCopy(),
        rules = rules.toList(),
    )

private fun RelationContract.immutableCopy(): RelationContract =
    copy(
        first = first.immutableCopy(),
        second = second.immutableCopy(),
        families = families.toSet(),
    )

private fun EndpointDefinition.immutableCopy(): EndpointDefinition = copy(resource = resource.immutableCopy() as TypeTemplate.Named)

private fun PresentationDescriptor.immutableCopy(): PresentationDescriptor =
    copy(
        target = target.immutableCopy(),
        roles = roles.toSet(),
    )

private fun PresentationMaterial.immutableCopy(): PresentationMaterial = copy(target = target.immutableCopy())

private fun PresentationTarget.immutableCopy(): PresentationTarget =
    when (this) {
        is PresentationTarget.Named -> copy(type = type.immutableCopy() as TypeTemplate.Named)
        is PresentationTarget.Representation -> this
    }

private fun ConfigurationRecipe.immutableCopy(): ConfigurationRecipe =
    copy(
        relativePath = relativePath.immutableCopy(),
        rules = rules.map(OwnedRule::immutableCopy),
    )

private fun OwnedRule.immutableCopy(): OwnedRule =
    copy(
        descriptor = descriptor.copy(predicate = descriptor.predicate.immutableCopy()),
        diagnostic = diagnostic.immutableCopy(),
    )

private fun DiagnosticTemplate.immutableCopy(): DiagnosticTemplate = copy(targets = targets.map(RelativeFieldPattern::immutableCopy))

private fun ExpressionNode.immutableCopy(): ExpressionNode =
    when (this) {
        is ExpressionNode.Literal -> {
            copy(value = value.immutableCopy())
        }

        is ExpressionNode.Read -> {
            copy(path = path.copy(segments = path.segments.toList()))
        }

        is ExpressionNode.Call -> {
            copy(arguments = arguments.map(ExpressionNode::immutableCopy))
        }

        is ExpressionNode.And -> {
            copy(left = left.immutableCopy(), right = right.immutableCopy())
        }

        is ExpressionNode.Or -> {
            copy(left = left.immutableCopy(), right = right.immutableCopy())
        }

        is ExpressionNode.Conditional -> {
            copy(
                test = test.immutableCopy(),
                yes = yes.immutableCopy(),
                no = no.immutableCopy(),
            )
        }

        is ExpressionNode.OrElse -> {
            copy(input = input.immutableCopy(), fallback = fallback.immutableCopy())
        }

        is ExpressionNode.Collection -> {
            copy(
                input = input.immutableCopy(),
                bindings = bindings.toList(),
                arguments = arguments.map(ExpressionNode::immutableCopy),
                body = body?.immutableCopy(),
            )
        }
    }

private fun InitializationDescriptor.immutableCopy(): InitializationDescriptor =
    copy(
        captured = captured.map { captured -> captured.copy(value = captured.value.immutableCopy()) },
        diagnostics = diagnostics.toList(),
    )

private fun EndpointBindingTemplate.immutableCopy(): EndpointBindingTemplate =
    copy(
        containingResource = containingResource.immutableCopy() as TypeTemplate.Named,
        relativePath = relativePath.immutableCopy(),
        target = target.immutableCopy(),
    )

private fun RealmCapabilityDescriptor.immutableCopy(): RealmCapabilityDescriptor =
    when (this) {
        is RealmCapabilityDescriptor.Search -> {
            copy(
                requestType = requestType.immutableCopy(),
                resultType = resultType.immutableCopy(),
            )
        }

        is RealmCapabilityDescriptor.Computation -> {
            copy(
                requestType = requestType.immutableCopy(),
                resultType = resultType.immutableCopy(),
            )
        }

        is RealmCapabilityDescriptor.Command -> {
            copy(requestType = requestType.immutableCopy())
        }
    }

private fun TypeRecommendation.immutableCopy(): TypeRecommendation = copy(type = type.immutableCopy() as TypeUse.Named)

private fun DeclarationDiagnostic.immutableCopy(): DeclarationDiagnostic =
    copy(
        origins = origins.toList(),
        field = field?.immutableCopy(),
    )

private fun RelativeFieldPattern.immutableCopy(): RelativeFieldPattern = copy(segments = segments.toList())
