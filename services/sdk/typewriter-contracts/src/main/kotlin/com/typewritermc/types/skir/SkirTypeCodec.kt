package com.typewritermc.types.skir

import com.typewritermc.capability.RealmCapabilityDescriptor
import com.typewritermc.configuration.name
import com.typewritermc.presentation.PresentationDescriptor
import com.typewritermc.presentation.PresentationTarget
import com.typewritermc.presentation.RoleFallback
import com.typewritermc.types.ResourceTarget
import com.typewritermc.types.catalog.ResourceDisplayFormulas
import com.typewritermc.types.catalog.reasons
import skirout.editor.v1.catalog.ConfigurationRecipe
import skirout.editor.v1.catalog.DeclarationStatus
import skirout.editor.v1.catalog.EndpointBindingTemplate
import skirout.editor.v1.catalog.EndpointCardinality
import skirout.editor.v1.catalog.EndpointDefinition
import skirout.editor.v1.catalog.EndpointSlot
import skirout.editor.v1.catalog.OwnedRule
import skirout.editor.v1.catalog.RelationContract
import skirout.editor.v1.catalog.RelationDeletePolicy
import skirout.editor.v1.catalog.RepresentationKind
import skirout.editor.v1.diagnostic.DeclarationDiagnostic
import skirout.editor.v1.type_catalog.FieldPatternSegment
import skirout.editor.v1.type_catalog.RelativeFieldPattern
import skirout.editor.v1.type_catalog.TypeTemplate
import skirout.editor.v1.capability.CapabilityDefinition as SkirCapabilityDefinition
import skirout.editor.v1.capability.CommandCapabilityDefinition as SkirCommandCapabilityDefinition
import skirout.editor.v1.capability.ComputationCapabilityDefinition as SkirComputationCapabilityDefinition
import skirout.editor.v1.capability.SearchCapabilityDefinition as SkirSearchCapabilityDefinition
import skirout.editor.v1.catalog.ConfigurationRecipe as SkirConfigurationRecipe
import skirout.editor.v1.catalog.DeclarationStatus as SkirDeclarationStatus
import skirout.editor.v1.catalog.EndpointBindingTemplate as SkirEndpointBindingTemplate
import skirout.editor.v1.catalog.EndpointCardinality as SkirEndpointCardinality
import skirout.editor.v1.catalog.EndpointDefinition as SkirEndpointDefinition
import skirout.editor.v1.catalog.EndpointSlot as SkirEndpointSlot
import skirout.editor.v1.catalog.OwnedRule as SkirOwnedRule
import skirout.editor.v1.catalog.PresentationDescriptor as SkirPresentationDescriptor
import skirout.editor.v1.catalog.PresentationTarget as SkirPresentationTarget
import skirout.editor.v1.catalog.RelationContract as SkirRelationContract
import skirout.editor.v1.catalog.RelationDeletePolicy as SkirRelationDeletePolicy
import skirout.editor.v1.catalog.RepresentationKind as SkirRepresentationKind
import skirout.editor.v1.catalog.ResourceDisplayFormulas as SkirResourceDisplayFormulas
import skirout.editor.v1.catalog.RoleFallback as SkirRoleFallback
import skirout.editor.v1.catalog.RuleDescriptor as SkirRuleDescriptor
import skirout.editor.v1.diagnostic.DeclarationDiagnostic as SkirDeclarationDiagnostic
import skirout.editor.v1.diagnostic.DeclarationOrigin as SkirDeclarationOrigin
import skirout.editor.v1.diagnostic.DiagnosticTemplate as SkirDiagnosticTemplate
import skirout.editor.v1.type_catalog.FieldPatternSegment as SkirFieldPatternSegment
import skirout.editor.v1.type_catalog.NamedFieldPatternSegment as SkirNamedFieldPatternSegment
import skirout.editor.v1.type_catalog.RelativeFieldPattern as SkirRelativeFieldPattern
import skirout.editor.v1.type_catalog.ResourceTarget as SkirResourceTarget

/**
 * Encodes the catalog models that are still Kotlin classes (displays, presentation descriptors and targets, resource
 * targets, capabilities and role fallbacks) into the Skir catalog the assembler publishes.
 */
object SkirTypeCodec {
    fun encode(display: ResourceDisplayFormulas): SkirConversionResult<SkirResourceDisplayFormulas> =
        captureSkirConversion { this.encode(display) }

    fun encode(presentation: PresentationDescriptor): SkirConversionResult<SkirPresentationDescriptor> =
        captureSkirConversion { this.encode(presentation) }

    fun encode(capability: RealmCapabilityDescriptor): SkirConversionResult<SkirCapabilityDefinition> =
        captureSkirConversion { this.encode(capability) }

    fun encode(fallback: RoleFallback): SkirConversionResult<SkirRoleFallback> = captureSkirConversion { encodeFallback(fallback) }

    fun encode(target: ResourceTarget): SkirConversionResult<SkirResourceTarget> = captureSkirConversion { this.encode(target) }

    fun encode(target: PresentationTarget): SkirConversionResult<SkirPresentationTarget> = captureSkirConversion { this.encode(target) }
}

private fun ConversionScope.encode(display: ResourceDisplayFormulas) =
    SkirResourceDisplayFormulas(
        target = encode(display.target),
        label = display.label,
        accent = display.accent,
        icon = display.icon,
    )

internal fun ConversionScope.encode(target: ResourceTarget): SkirResourceTarget =
    when (target) {
        is ResourceTarget.Type -> SkirResourceTarget.TypeWrapper(TypeTemplate.NamedWrapper(target.template))
        ResourceTarget.AnyResource -> SkirResourceTarget.ANY_RESOURCE
    }

private fun encodeFallback(fallback: RoleFallback): SkirRoleFallback = SkirRoleFallback(role = fallback.role, parents = fallback.parents)

private fun ConversionScope.encode(capability: RealmCapabilityDescriptor): SkirCapabilityDefinition =
    when (capability) {
        is RealmCapabilityDescriptor.Search -> {
            SkirCapabilityDefinition.SearchWrapper(
                SkirSearchCapabilityDefinition(
                    capabilityId =
                        skirout.editor.v1.type_catalog
                            .CapabilityId(value = capability.id.value),
                    requestType = capability.requestType,
                    resultType = capability.resultType,
                ),
            )
        }

        is RealmCapabilityDescriptor.Computation -> {
            SkirCapabilityDefinition.ComputationWrapper(
                SkirComputationCapabilityDefinition(
                    capabilityId =
                        skirout.editor.v1.type_catalog
                            .CapabilityId(value = capability.id.value),
                    requestType = capability.requestType,
                    resultType = capability.resultType,
                ),
            )
        }

        is RealmCapabilityDescriptor.Command -> {
            SkirCapabilityDefinition.CommandWrapper(
                SkirCommandCapabilityDefinition(
                    capabilityId =
                        skirout.editor.v1.type_catalog
                            .CapabilityId(value = capability.id.value),
                    requestType = capability.requestType,
                ),
            )
        }

        is RealmCapabilityDescriptor.Authoring -> {
            SkirCapabilityDefinition.AuthoringWrapper(
                skirout.editor.v1.capability.AuthoringCapabilityDefinition(
                    capabilityId =
                        skirout.editor.v1.type_catalog
                            .CapabilityId(value = capability.id.value),
                    targets = capability.targets,
                    input =
                        capability.requestType?.let { type ->
                            skirout.editor.v1.operation.OperationInputDefinition(
                                type = type,
                                presentation = capability.inputPresentation,
                            )
                        },
                ),
            )
        }
    }

private fun ConversionScope.encode(presentation: PresentationDescriptor) =
    SkirPresentationDescriptor(
        id = presentation.id,
        owner = presentation.owner,
        target = encode(presentation.target),
        roles = presentation.roles.sortedBy { it.kind.ordinal },
        priority = presentation.priority,
    )

private fun ConversionScope.encode(target: PresentationTarget): SkirPresentationTarget =
    when (target) {
        is PresentationTarget.Named -> SkirPresentationTarget.NamedWrapper(target.type)
        is PresentationTarget.Representation -> SkirPresentationTarget.RepresentationWrapper(target.kind)
    }
