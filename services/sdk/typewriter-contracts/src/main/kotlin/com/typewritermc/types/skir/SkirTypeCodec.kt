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
import com.typewritermc.types.EndpointCardinality
import com.typewritermc.types.EndpointDefinition
import com.typewritermc.types.EndpointSlot
import com.typewritermc.types.RelationContract
import com.typewritermc.types.RelationDeletePolicy
import com.typewritermc.types.ResourceTarget
import com.typewritermc.types.TypeDisplay
import com.typewritermc.types.catalog.DeclarationDiagnostic
import com.typewritermc.types.catalog.DeclarationStatus
import com.typewritermc.types.catalog.EditorCatalogSnapshot
import com.typewritermc.types.catalog.EffectiveFieldTemplate
import com.typewritermc.types.catalog.PublishedType
import com.typewritermc.types.catalog.ResourceDisplayFormulas
import com.typewritermc.types.catalog.TypeRecommendation
import com.typewritermc.types.toWire
import skirout.editor.v1.catalog.EditorCatalog
import skirout.editor.v1.type_catalog.TypeTemplate
import skirout.editor.v1.capability.CapabilityDefinition as SkirCapabilityDefinition
import skirout.editor.v1.capability.CommandCapabilityDefinition as SkirCommandCapabilityDefinition
import skirout.editor.v1.capability.ComputationCapabilityDefinition as SkirComputationCapabilityDefinition
import skirout.editor.v1.capability.SearchCapabilityDefinition as SkirSearchCapabilityDefinition
import skirout.editor.v1.catalog.ConfigurationRecipe as SkirConfigurationRecipe
import skirout.editor.v1.catalog.DeclarationStatus as SkirDeclarationStatus
import skirout.editor.v1.catalog.EffectiveFieldTemplate as SkirEffectiveFieldTemplate
import skirout.editor.v1.catalog.EndpointCardinality as SkirEndpointCardinality
import skirout.editor.v1.catalog.EndpointDefinition as SkirEndpointDefinition
import skirout.editor.v1.catalog.EndpointSlot as SkirEndpointSlot
import skirout.editor.v1.catalog.OwnedRule as SkirOwnedRule
import skirout.editor.v1.catalog.PresentationDescriptor as SkirPresentationDescriptor
import skirout.editor.v1.catalog.PresentationTarget as SkirPresentationTarget
import skirout.editor.v1.catalog.PublishedType as SkirPublishedType
import skirout.editor.v1.catalog.RelationContract as SkirRelationContract
import skirout.editor.v1.catalog.RelationDeletePolicy as SkirRelationDeletePolicy
import skirout.editor.v1.catalog.RepresentationKind as SkirRepresentationKind
import skirout.editor.v1.catalog.ResourceDisplayFormulas as SkirResourceDisplayFormulas
import skirout.editor.v1.catalog.RoleFallback as SkirRoleFallback
import skirout.editor.v1.catalog.RuleDescriptor as SkirRuleDescriptor
import skirout.editor.v1.catalog.TypeDisplay as SkirTypeDisplay
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
import skirout.kernel.v1.color.Color as SkirColor

object SkirTypeCodec {
    fun encode(snapshot: EditorCatalogSnapshot): SkirConversionResult<EditorCatalog> = captureSkirConversion { encodeSnapshot(snapshot) }

    fun encode(type: PublishedType): SkirConversionResult<SkirPublishedType> = captureSkirConversion { this.encode(type) }

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

private fun ConversionScope.encodeSnapshot(snapshot: EditorCatalogSnapshot) =
    EditorCatalog(
        generation =
            skirout.editor.v1.type_catalog
                .CatalogGeneration(value = snapshot.generation.value),
        types = snapshot.types.mapIndexed { index, value -> at("type $index") { encode(value) } },
        relations = snapshot.relations.mapIndexed { index, value -> at("relation $index") { encode(value) } },
        resourceDisplays = snapshot.resourceDisplays.mapIndexed { index, value -> at("resource display $index") { encode(value) } },
        presentations = snapshot.presentations.mapIndexed { index, value -> at("presentation $index") { encode(value) } },
        presentationMaterials = snapshot.presentationMaterials,
        configuration = snapshot.configuration.mapIndexed { index, value -> at("configuration $index") { encode(value) } },
        diagnostics = snapshot.diagnostics.mapIndexed { index, value -> at("diagnostic $index") { encode(value) } },
        endpointBindings = snapshot.endpointBindings.mapIndexed { index, value -> at("endpoint binding $index") { encode(value) } },
        capabilities = snapshot.capabilities.mapIndexed { index, value -> at("capability $index") { encode(value) } },
        recommendations = snapshot.recommendations.mapIndexed { index, value -> at("recommendation $index") { encode(value) } },
        roleFallbacks = snapshot.roleFallbacks.mapIndexed { index, value -> at("role fallback $index") { encode(value) } },
        resourceOperations = snapshot.resourceOperations,
        realmRoot = snapshot.realmRoot,
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

private fun encode(fallback: RoleFallback): SkirRoleFallback = SkirRoleFallback(role = fallback.role, parents = fallback.parents)

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

private fun ConversionScope.encode(recommendation: TypeRecommendation) =
    skirout.editor.v1.catalog.TypeRecommendation(
        type = recommendation.type,
        occurrences = recommendation.occurrences,
    )

private fun ConversionScope.encode(binding: com.typewritermc.types.EndpointBindingTemplate) =
    skirout.editor.v1.catalog.EndpointBindingTemplate(
        endpoint = binding.endpoint,
        containingResource = binding.containingResource,
        valueOwner = binding.valueOwner,
        relativePath = encode(binding.relativePath),
        target = binding.target,
        containsCollection = binding.containsCollection,
    )

private fun ConversionScope.encode(type: PublishedType) =
    SkirPublishedType(
        definition = type.definition,
        status =
            when (val status = type.status) {
                DeclarationStatus.Ready -> SkirDeclarationStatus.READY
                is DeclarationStatus.Unavailable -> SkirDeclarationStatus.UnavailableWrapper(status.reasons.map(::encode))
            },
        effectiveFields = type.effectiveFields.map(::encode),
        ancestorTemplates = type.ancestorTemplates,
        display = encode(type.display),
        searchKey = type.searchKey,
        placementField = type.placementField?.let { encodeValuePath(it) },
    )

private fun ConversionScope.encode(display: TypeDisplay) =
    SkirTypeDisplay(
        name = display.name,
        description = display.description,
        icon = display.icon.toWire(),
        color = SkirColor(argb = display.color.argb.toInt()),
    )

private fun ConversionScope.encode(field: EffectiveFieldTemplate) =
    SkirEffectiveFieldTemplate(
        key = field.key,
        owner = field.owner,
        type = field.type,
        rules = field.rules,
    )

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
