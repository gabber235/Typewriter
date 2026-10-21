package com.typewritermc.types.skir

import com.typewritermc.authoring.PathSegment
import com.typewritermc.authoring.ValuePath
import com.typewritermc.capability.RealmCapabilityDescriptor
import com.typewritermc.checking.Diagnostic
import com.typewritermc.checking.DiagnosticSeverity
import com.typewritermc.configuration.ConfigurationRecipe
import com.typewritermc.configuration.FieldPatternSegment
import com.typewritermc.configuration.OwnedRule
import com.typewritermc.configuration.RelativeFieldPattern
import com.typewritermc.configuration.RepresentationKind
import com.typewritermc.presentation.PresentationDescriptor
import com.typewritermc.presentation.PresentationTarget
import com.typewritermc.presentation.RoleFallback
import com.typewritermc.types.EndpointBindingTemplate
import com.typewritermc.types.EndpointCardinality
import com.typewritermc.types.EndpointDefinition
import com.typewritermc.types.EndpointSlot
import com.typewritermc.types.RelationContract
import com.typewritermc.types.RelationDeletePolicy
import com.typewritermc.types.ResourceTarget
import com.typewritermc.types.catalog.DeclarationDiagnostic
import com.typewritermc.types.catalog.DeclarationStatus
import com.typewritermc.types.catalog.ResourceDisplayFormulas
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
import skirout.editor.v1.diagnostic.Diagnostic as SkirDiagnostic
import skirout.editor.v1.diagnostic.DiagnosticSeverity as SkirDiagnosticSeverity
import skirout.editor.v1.diagnostic.DiagnosticTemplate as SkirDiagnosticTemplate
import skirout.editor.v1.type_catalog.FieldPathSegment as SkirFieldPathSegment
import skirout.editor.v1.type_catalog.FieldPatternSegment as SkirFieldPatternSegment
import skirout.editor.v1.type_catalog.ItemId as SkirItemId
import skirout.editor.v1.type_catalog.ItemPathSegment as SkirItemPathSegment
import skirout.editor.v1.type_catalog.NamedFieldPatternSegment as SkirNamedFieldPatternSegment
import skirout.editor.v1.type_catalog.PathSegment as SkirPathSegment
import skirout.editor.v1.type_catalog.RelativeFieldPattern as SkirRelativeFieldPattern
import skirout.editor.v1.type_catalog.ResourceTarget as SkirResourceTarget
import skirout.editor.v1.type_catalog.ValuePath as SkirValuePath

/**
 * Encodes the catalog models that are still Kotlin classes (relations, displays, presentation descriptors,
 * configuration, endpoint bindings, capabilities, role fallbacks and declaration diagnostics) into the Skir catalog
 * the assembler publishes. Type values are already Skir values and pass through.
 */
object SkirTypeCodec {
    fun encode(relation: RelationContract): SkirConversionResult<SkirRelationContract> = captureSkirConversion { this.encode(relation) }

    fun encode(display: ResourceDisplayFormulas): SkirConversionResult<SkirResourceDisplayFormulas> =
        captureSkirConversion { this.encode(display) }

    fun encode(presentation: PresentationDescriptor): SkirConversionResult<SkirPresentationDescriptor> =
        captureSkirConversion { this.encode(presentation) }

    fun encode(recipe: ConfigurationRecipe): SkirConversionResult<SkirConfigurationRecipe> = captureSkirConversion { this.encode(recipe) }

    fun encode(binding: EndpointBindingTemplate): SkirConversionResult<SkirEndpointBindingTemplate> =
        captureSkirConversion { this.encode(binding) }

    fun encode(capability: RealmCapabilityDescriptor): SkirConversionResult<SkirCapabilityDefinition> =
        captureSkirConversion { this.encode(capability) }

    fun encode(fallback: RoleFallback): SkirConversionResult<SkirRoleFallback> = captureSkirConversion { encodeFallback(fallback) }

    fun encode(status: DeclarationStatus): SkirConversionResult<SkirDeclarationStatus> = captureSkirConversion { this.encode(status) }

    fun encode(diagnostic: DeclarationDiagnostic): SkirConversionResult<SkirDeclarationDiagnostic> =
        captureSkirConversion { this.encode(diagnostic) }

    fun encode(diagnostic: Diagnostic): SkirConversionResult<SkirDiagnostic> = captureSkirConversion { this.encode(diagnostic) }

    fun encode(target: ResourceTarget): SkirConversionResult<SkirResourceTarget> = captureSkirConversion { this.encode(target) }

    fun encode(target: PresentationTarget): SkirConversionResult<SkirPresentationTarget> = captureSkirConversion { this.encode(target) }
}

internal fun ConversionScope.encodeValuePath(path: ValuePath) =
    SkirValuePath(
        segments =
            path.segments.map { segment ->
                when (segment) {
                    is PathSegment.Field -> SkirPathSegment.FieldWrapper(SkirFieldPathSegment(name = segment.name))
                    is PathSegment.Item -> SkirPathSegment.ItemWrapper(SkirItemPathSegment(id = SkirItemId(value = segment.id.value)))
                    PathSegment.MapKey -> SkirPathSegment.MAP_KEY
                    PathSegment.MapValue -> SkirPathSegment.MAP_VALUE
                }
            },
    )

internal fun ConversionScope.decodeValuePath(path: SkirValuePath) =
    ValuePath(
        path.segments.map { segment ->
            when (segment) {
                is SkirPathSegment.FieldWrapper -> PathSegment.Field(segment.value.name)
                is SkirPathSegment.ItemWrapper -> PathSegment.Item(com.typewritermc.authoring.ItemId(segment.value.id.value))
                SkirPathSegment.MAP_KEY -> PathSegment.MapKey
                SkirPathSegment.MAP_VALUE -> PathSegment.MapValue
                else -> fail("Unknown Skir path segment.")
            }
        },
    )

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

private fun ConversionScope.encode(binding: EndpointBindingTemplate) =
    SkirEndpointBindingTemplate(
        endpoint = binding.endpoint,
        containingResource = binding.containingResource,
        valueOwner = binding.valueOwner,
        relativePath = encode(binding.relativePath),
        target = binding.target,
        containsCollection = binding.containsCollection,
    )

private fun ConversionScope.encode(status: DeclarationStatus): SkirDeclarationStatus =
    when (status) {
        DeclarationStatus.Ready -> SkirDeclarationStatus.READY
        is DeclarationStatus.Unavailable -> SkirDeclarationStatus.UnavailableWrapper(status.reasons.map(::encode))
    }

private fun ConversionScope.encode(relation: RelationContract) =
    SkirRelationContract(
        id =
            skirout.editor.v1.type_catalog
                .RelationId(value = relation.id.value),
        first = encode(relation.first),
        second = encode(relation.second),
        families =
            relation.families.sortedBy { it.value }.map {
                skirout.editor.v1.type_catalog
                    .RelationFamilyId(value = it.value)
            },
    )

private fun ConversionScope.encode(endpoint: EndpointDefinition) =
    SkirEndpointDefinition(
        id = endpoint.id,
        slot =
            when (endpoint.slot) {
                EndpointSlot.First -> SkirEndpointSlot.FIRST
                EndpointSlot.Second -> SkirEndpointSlot.SECOND
            },
        resource = endpoint.resource,
        cardinality =
            when (endpoint.cardinality) {
                EndpointCardinality.One -> SkirEndpointCardinality.ONE
                EndpointCardinality.Many -> SkirEndpointCardinality.MANY
            },
        onDelete =
            when (endpoint.onDelete) {
                RelationDeletePolicy.RESTRICT -> SkirRelationDeletePolicy.RESTRICT
                RelationDeletePolicy.CASCADE -> SkirRelationDeletePolicy.CASCADE
                RelationDeletePolicy.CLEAR -> SkirRelationDeletePolicy.CLEAR
            },
    )

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
        is PresentationTarget.Representation -> SkirPresentationTarget.RepresentationWrapper(encode(target.kind))
    }

private fun encode(kind: RepresentationKind): SkirRepresentationKind =
    when (kind) {
        RepresentationKind.Unit -> SkirRepresentationKind.UNIT
        RepresentationKind.Boolean -> SkirRepresentationKind.BOOLEAN
        RepresentationKind.Text -> SkirRepresentationKind.TEXT
        RepresentationKind.Bytes -> SkirRepresentationKind.BYTES
        RepresentationKind.Integer -> SkirRepresentationKind.INTEGER
        RepresentationKind.Float -> SkirRepresentationKind.FLOAT
        RepresentationKind.Decimal -> SkirRepresentationKind.DECIMAL
        RepresentationKind.Timestamp -> SkirRepresentationKind.TIMESTAMP
        RepresentationKind.Duration -> SkirRepresentationKind.DURATION
        RepresentationKind.Record -> SkirRepresentationKind.RECORD
        RepresentationKind.List -> SkirRepresentationKind.LIST
        RepresentationKind.Set -> SkirRepresentationKind.SET
        RepresentationKind.Map -> SkirRepresentationKind.MAP
        RepresentationKind.Enum -> SkirRepresentationKind.ENUMERATION
        RepresentationKind.Link -> SkirRepresentationKind.LINK
    }

private fun ConversionScope.encode(recipe: ConfigurationRecipe) =
    SkirConfigurationRecipe(
        origin = recipe.origin,
        relativePath = encode(recipe.relativePath),
        representationCondition = recipe.representationCondition?.let(::encode),
        rules = recipe.rules.map(::encode),
    )

private fun ConversionScope.encode(rule: OwnedRule) =
    SkirOwnedRule(
        id = rule.id,
        descriptor = SkirRuleDescriptor(predicate = rule.descriptor.predicate),
        diagnostic =
            SkirDiagnosticTemplate(
                code = rule.diagnostic.code,
                message = rule.diagnostic.message,
                severity = encode(rule.diagnostic.severity),
                targets = rule.diagnostic.targets.map(::encode),
            ),
    )

private fun ConversionScope.encode(diagnostic: DeclarationDiagnostic) =
    SkirDeclarationDiagnostic(
        affected = diagnostic.affected,
        code = diagnostic.code,
        origins = diagnostic.origins.map { SkirDeclarationOrigin(owner = it.owner) },
        field = diagnostic.field?.let(::encode),
    )

private fun ConversionScope.encode(diagnostic: Diagnostic) =
    SkirDiagnostic(
        id =
            skirout.editor.v1.type_catalog
                .DiagnosticId(value = diagnostic.id.value),
        origin = diagnostic.origin,
        code = diagnostic.code,
        message = diagnostic.message,
        severity = encode(diagnostic.severity),
        primary = diagnostic.primary?.let(::encodeValueLocation),
        related = diagnostic.related.map(::encodeValueLocation),
    )

private fun ConversionScope.encode(pattern: RelativeFieldPattern) =
    SkirRelativeFieldPattern(
        segments =
            pattern.segments.map { segment ->
                when (segment) {
                    is FieldPatternSegment.Field -> SkirFieldPatternSegment.FieldWrapper(SkirNamedFieldPatternSegment(name = segment.name))
                    FieldPatternSegment.Items -> SkirFieldPatternSegment.ITEMS
                    FieldPatternSegment.Keys -> SkirFieldPatternSegment.KEYS
                    FieldPatternSegment.Values -> SkirFieldPatternSegment.VALUES
                }
            },
    )

private fun encode(severity: DiagnosticSeverity): SkirDiagnosticSeverity =
    when (severity) {
        DiagnosticSeverity.Info -> SkirDiagnosticSeverity.INFORMATION
        DiagnosticSeverity.Warning -> SkirDiagnosticSeverity.WARNING
        DiagnosticSeverity.Error -> SkirDiagnosticSeverity.ERROR
    }
