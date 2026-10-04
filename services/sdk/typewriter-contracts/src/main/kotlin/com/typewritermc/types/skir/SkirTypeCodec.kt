package com.typewritermc.types.skir

import com.typewritermc.authoring.AuthoringResourceDefinition
import com.typewritermc.authoring.InitializationDescriptor
import com.typewritermc.authoring.PathSegment
import com.typewritermc.authoring.ResourceDefinitionId
import com.typewritermc.authoring.ValuePath
import com.typewritermc.capability.RealmCapabilityDescriptor
import com.typewritermc.checking.Diagnostic
import com.typewritermc.checking.DiagnosticSeverity
import com.typewritermc.configuration.ConfigurationRecipe
import com.typewritermc.configuration.FieldPatternSegment
import com.typewritermc.configuration.OwnedRule
import com.typewritermc.configuration.RelativeFieldPattern
import com.typewritermc.configuration.RepresentationKind
import com.typewritermc.configuration.RuleId
import com.typewritermc.configuration.RuleOrigin
import com.typewritermc.discovery.ContributionKey
import com.typewritermc.presentation.ExpressionNode
import com.typewritermc.presentation.PresentationDescriptor
import com.typewritermc.presentation.PresentationMaterial
import com.typewritermc.presentation.PresentationTarget
import com.typewritermc.presentation.RoleFallback
import com.typewritermc.types.CollectionKind
import com.typewritermc.types.DeclarationOwner
import com.typewritermc.types.DeclaredTypeId
import com.typewritermc.types.EndpointCardinality
import com.typewritermc.types.EndpointDefinition
import com.typewritermc.types.EndpointSlot
import com.typewritermc.types.EnumVariant
import com.typewritermc.types.FieldDeclaration
import com.typewritermc.types.FieldOwner
import com.typewritermc.types.FloatWidth
import com.typewritermc.types.IntegerWidth
import com.typewritermc.types.ParameterKey
import com.typewritermc.types.PresentationId
import com.typewritermc.types.PresentationRole
import com.typewritermc.types.RelationContract
import com.typewritermc.types.RelationDeletePolicy
import com.typewritermc.types.RepresentationTemplate
import com.typewritermc.types.ScalarKind
import com.typewritermc.types.TypeDefinition
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.TypeDisplay
import com.typewritermc.types.TypeId
import com.typewritermc.types.TypeParameter
import com.typewritermc.types.TypeTemplate
import com.typewritermc.types.TypeUse
import com.typewritermc.types.catalog.DeclarationDiagnostic
import com.typewritermc.types.catalog.DeclarationStatus
import com.typewritermc.types.catalog.EditorCatalogSnapshot
import com.typewritermc.types.catalog.EffectiveFieldTemplate
import com.typewritermc.types.catalog.PublishedType
import com.typewritermc.types.catalog.TypeRecommendation
import skirout.editor.v1.catalog.EditorCatalogWireSnapshot
import skirout.editor.v1.capability.CapabilityDefinition as SkirCapabilityDefinition
import skirout.editor.v1.capability.CommandCapabilityDefinition as SkirCommandCapabilityDefinition
import skirout.editor.v1.capability.ComputationCapabilityDefinition as SkirComputationCapabilityDefinition
import skirout.editor.v1.capability.SearchCapabilityDefinition as SkirSearchCapabilityDefinition
import skirout.editor.v1.catalog.AuthoringResourceDefinition as SkirAuthoringResourceDefinition
import skirout.editor.v1.catalog.ConfigurationRecipe as SkirConfigurationRecipe
import skirout.editor.v1.catalog.DeclarationStatus as SkirDeclarationStatus
import skirout.editor.v1.catalog.EffectiveFieldTemplate as SkirEffectiveFieldTemplate
import skirout.editor.v1.catalog.EndpointCardinality as SkirEndpointCardinality
import skirout.editor.v1.catalog.EndpointDefinition as SkirEndpointDefinition
import skirout.editor.v1.catalog.EndpointSlot as SkirEndpointSlot
import skirout.editor.v1.catalog.InitializationDescriptor as SkirInitializationDescriptor
import skirout.editor.v1.catalog.InitializationMode as SkirInitializationMode
import skirout.editor.v1.catalog.OwnedRule as SkirOwnedRule
import skirout.editor.v1.catalog.PresentationDescriptor as SkirPresentationDescriptor
import skirout.editor.v1.catalog.PresentationMaterial as SkirPresentationMaterial
import skirout.editor.v1.catalog.PresentationRole as SkirPresentationRole
import skirout.editor.v1.catalog.PresentationTarget as SkirPresentationTarget
import skirout.editor.v1.catalog.PublishedType as SkirPublishedType
import skirout.editor.v1.catalog.RelationContract as SkirRelationContract
import skirout.editor.v1.catalog.RelationDeletePolicy as SkirRelationDeletePolicy
import skirout.editor.v1.catalog.RepresentationKind as SkirRepresentationKind
import skirout.editor.v1.catalog.RoleFallback as SkirRoleFallback
import skirout.editor.v1.catalog.RuleDescriptor as SkirRuleDescriptor
import skirout.editor.v1.catalog.TypeDisplay as SkirTypeDisplay
import skirout.editor.v1.diagnostic.DeclarationDiagnostic as SkirDeclarationDiagnostic
import skirout.editor.v1.diagnostic.DeclarationOrigin as SkirDeclarationOrigin
import skirout.editor.v1.diagnostic.Diagnostic as SkirDiagnostic
import skirout.editor.v1.diagnostic.DiagnosticSeverity as SkirDiagnosticSeverity
import skirout.editor.v1.diagnostic.DiagnosticTemplate as SkirDiagnosticTemplate
import skirout.editor.v1.diagnostic.InitializationDiagnostic as SkirInitializationDiagnostic
import skirout.editor.v1.expression.BinaryExpression as SkirBinaryExpression
import skirout.editor.v1.expression.CollectionExpression as SkirCollectionExpression
import skirout.editor.v1.expression.ConditionalExpression as SkirConditionalExpression
import skirout.editor.v1.expression.ExpressionCall as SkirExpressionCall
import skirout.editor.v1.expression.ExpressionNode as SkirExpressionNode
import skirout.editor.v1.expression.ExpressionRead as SkirExpressionRead
import skirout.editor.v1.expression.OrElseExpression as SkirOrElseExpression
import skirout.editor.v1.type_catalog.CollectionKind as SkirCollectionKind
import skirout.editor.v1.type_catalog.ContributionKey as SkirContributionKey
import skirout.editor.v1.type_catalog.ContributionName as SkirContributionName
import skirout.editor.v1.type_catalog.ContributionSourceId as SkirContributionSourceId
import skirout.editor.v1.type_catalog.DeclarationOwner as SkirDeclarationOwner
import skirout.editor.v1.type_catalog.DeclaredTypeId as SkirDeclaredTypeId
import skirout.editor.v1.type_catalog.EnumVariant as SkirEnumVariant
import skirout.editor.v1.type_catalog.FieldDeclaration as SkirFieldDeclaration
import skirout.editor.v1.type_catalog.FieldOwner as SkirFieldOwner
import skirout.editor.v1.type_catalog.FieldPathSegment as SkirFieldPathSegment
import skirout.editor.v1.type_catalog.FieldPatternSegment as SkirFieldPatternSegment
import skirout.editor.v1.type_catalog.FloatWidth as SkirFloatWidth
import skirout.editor.v1.type_catalog.IntegerWidth as SkirIntegerWidth
import skirout.editor.v1.type_catalog.ItemId as SkirItemId
import skirout.editor.v1.type_catalog.ItemPathSegment as SkirItemPathSegment
import skirout.editor.v1.type_catalog.NamedFieldPatternSegment as SkirNamedFieldPatternSegment
import skirout.editor.v1.type_catalog.NamedTypeTemplate as SkirNamedTypeTemplate
import skirout.editor.v1.type_catalog.NamedTypeUse as SkirNamedTypeUse
import skirout.editor.v1.type_catalog.NullableTypeTemplate as SkirNullableTypeTemplate
import skirout.editor.v1.type_catalog.NullableTypeUse as SkirNullableTypeUse
import skirout.editor.v1.type_catalog.ParameterKey as SkirParameterKey
import skirout.editor.v1.type_catalog.PathSegment as SkirPathSegment
import skirout.editor.v1.type_catalog.PresentationId as SkirPresentationId
import skirout.editor.v1.type_catalog.ProducerId as SkirProducerId
import skirout.editor.v1.type_catalog.QualifiedTypeId as SkirQualifiedTypeId
import skirout.editor.v1.type_catalog.RelativeFieldPattern as SkirRelativeFieldPattern
import skirout.editor.v1.type_catalog.RepresentationTemplate as SkirRepresentationTemplate
import skirout.editor.v1.type_catalog.RuleId as SkirRuleId
import skirout.editor.v1.type_catalog.RuleOrigin as SkirRuleOrigin
import skirout.editor.v1.type_catalog.ScalarKind as SkirScalarKind
import skirout.editor.v1.type_catalog.TypeDefinition as SkirTypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId as SkirTypeDefinitionId
import skirout.editor.v1.type_catalog.TypeId as SkirTypeId
import skirout.editor.v1.type_catalog.TypeParameter as SkirTypeParameter
import skirout.editor.v1.type_catalog.TypeTemplate as SkirTypeTemplate
import skirout.editor.v1.type_catalog.TypeUse as SkirTypeUse
import skirout.editor.v1.type_catalog.ValuePath as SkirValuePath

object SkirTypeCodec {
    fun encode(definition: TypeDefinition): SkirConversionResult<SkirTypeDefinition> =
        captureSkirConversion { encodeTypeDefinition(definition) }

    fun decode(definition: SkirTypeDefinition): SkirConversionResult<TypeDefinition> =
        captureSkirConversion { decodeTypeDefinition(definition) }

    fun encode(template: TypeTemplate): SkirConversionResult<SkirTypeTemplate> = captureSkirConversion { encodeTypeTemplate(template) }

    fun decode(template: SkirTypeTemplate): SkirConversionResult<TypeTemplate> = captureSkirConversion { decodeTypeTemplate(template) }

    fun encode(use: TypeUse): SkirConversionResult<SkirTypeUse> = captureSkirConversion { encodeTypeUse(use) }

    fun decode(use: SkirTypeUse): SkirConversionResult<TypeUse> = captureSkirConversion { decodeTypeUse(use) }

    fun encode(snapshot: EditorCatalogSnapshot): SkirConversionResult<EditorCatalogWireSnapshot> =
        captureSkirConversion { encodeSnapshot(snapshot) }

    fun encode(diagnostic: DeclarationDiagnostic): SkirConversionResult<SkirDeclarationDiagnostic> =
        captureSkirConversion { this.encode(diagnostic) }

    fun encode(diagnostic: Diagnostic): SkirConversionResult<SkirDiagnostic> = captureSkirConversion { this.encode(diagnostic) }

    fun encode(rule: RuleId): SkirConversionResult<SkirRuleId> = captureSkirConversion { this.encode(rule) }

    fun encode(expression: ExpressionNode): SkirConversionResult<SkirExpressionNode> = captureSkirConversion { this.encode(expression) }
}

internal fun ConversionScope.encodeTypeId(id: TypeId): SkirTypeId =
    when (id) {
        is TypeId.Declared -> SkirTypeId.DeclaredWrapper(SkirDeclaredTypeId(value = id.id.toString()))
        is TypeId.Qualified -> SkirTypeId.QualifiedWrapper(SkirQualifiedTypeId(namespace = id.namespace, name = id.name))
    }

internal fun ConversionScope.decodeTypeId(id: SkirTypeId): TypeId =
    when (id) {
        is SkirTypeId.DeclaredWrapper -> {
            TypeId.Declared(
                runCatching {
                    DeclaredTypeId.parse(id.value.value)
                }.getOrElse { fail("Declared type identity is invalid.") },
            )
        }

        is SkirTypeId.QualifiedWrapper -> {
            TypeId.Qualified(id.value.namespace, id.value.name)
        }

        else -> {
            fail("Unknown Skir type identity variant.")
        }
    }

internal fun ConversionScope.encodeDefinitionId(id: TypeDefinitionId) =
    SkirTypeDefinitionId(typeId = encodeTypeId(id.type), revision = id.revision)

internal fun ConversionScope.decodeDefinitionId(id: SkirTypeDefinitionId) =
    TypeDefinitionId(type = decodeTypeId(id.typeId), revision = id.revision)

private fun ConversionScope.encodeParameterKey(key: ParameterKey) =
    SkirParameterKey(owner = encodeDefinitionId(key.owner), index = key.index)

private fun ConversionScope.decodeParameterKey(key: SkirParameterKey) =
    ParameterKey(owner = decodeDefinitionId(key.owner), index = key.index)

internal fun ConversionScope.encodeTypeTemplate(template: TypeTemplate): SkirTypeTemplate =
    withinTypeDepth {
        when (template) {
            is TypeTemplate.Parameter -> {
                SkirTypeTemplate.ParameterWrapper(encodeParameterKey(template.key))
            }

            is TypeTemplate.Named -> {
                SkirTypeTemplate.NamedWrapper(encodeNamedTypeTemplateBody(template))
            }

            is TypeTemplate.Nullable -> {
                SkirTypeTemplate.NullableWrapper(
                    SkirNullableTypeTemplate(value = encodeTypeTemplate(template.value)),
                )
            }

            is TypeTemplate.Scalar -> {
                SkirTypeTemplate.ScalarWrapper(encodeScalar(template.kind))
            }
        }
    }

internal fun ConversionScope.decodeTypeTemplate(template: SkirTypeTemplate): TypeTemplate =
    withinTypeDepth {
        when (template) {
            is SkirTypeTemplate.ParameterWrapper -> TypeTemplate.Parameter(decodeParameterKey(template.value))
            is SkirTypeTemplate.NamedWrapper -> decodeNamedTypeTemplateBody(template.value)
            is SkirTypeTemplate.NullableWrapper -> TypeTemplate.Nullable(decodeTypeTemplate(template.value.value))
            is SkirTypeTemplate.ScalarWrapper -> TypeTemplate.Scalar(decodeScalar(template.value))
            else -> fail("Unknown Skir type template variant.")
        }
    }

internal fun ConversionScope.encodeNamedTypeTemplate(template: TypeTemplate.Named) =
    withinTypeDepth { encodeNamedTypeTemplateBody(template) }

private fun ConversionScope.encodeNamedTypeTemplateBody(template: TypeTemplate.Named) =
    SkirNamedTypeTemplate(
        definition = encodeDefinitionId(template.definition),
        arguments = template.arguments.mapIndexed { index, value -> at("argument $index") { encodeTypeTemplate(value) } },
    )

private fun ConversionScope.decodeNamedTypeTemplateBody(template: SkirNamedTypeTemplate) =
    TypeTemplate.Named(
        definition = decodeDefinitionId(template.definition),
        arguments = template.arguments.mapIndexed { index, value -> at("argument $index") { decodeTypeTemplate(value) } },
    )

private fun ConversionScope.decodeNamedTypeTemplate(template: SkirNamedTypeTemplate) =
    withinTypeDepth { decodeNamedTypeTemplateBody(template) }

internal fun ConversionScope.encodeTypeUse(use: TypeUse): SkirTypeUse =
    withinTypeDepth {
        when (use) {
            is TypeUse.Named -> SkirTypeUse.NamedWrapper(encodeNamedTypeUseBody(use))
            is TypeUse.Nullable -> SkirTypeUse.NullableWrapper(SkirNullableTypeUse(value = encodeTypeUse(use.value)))
            is TypeUse.Scalar -> SkirTypeUse.ScalarWrapper(encodeScalar(use.kind))
        }
    }

internal fun ConversionScope.decodeTypeUse(use: SkirTypeUse): TypeUse =
    withinTypeDepth {
        when (use) {
            is SkirTypeUse.NamedWrapper -> decodeNamedTypeUseBody(use.value)
            is SkirTypeUse.NullableWrapper -> TypeUse.Nullable(decodeTypeUse(use.value.value))
            is SkirTypeUse.ScalarWrapper -> TypeUse.Scalar(decodeScalar(use.value))
            else -> fail("Unknown Skir type use variant.")
        }
    }

internal fun ConversionScope.encodeNamedTypeUse(use: TypeUse.Named) = withinTypeDepth { encodeNamedTypeUseBody(use) }

private fun ConversionScope.encodeNamedTypeUseBody(use: TypeUse.Named) =
    SkirNamedTypeUse(
        definition = encodeDefinitionId(use.definition),
        arguments = use.arguments.mapIndexed { index, value -> at("argument $index") { encodeTypeUse(value) } },
    )

internal fun ConversionScope.decodeNamedTypeUse(use: SkirNamedTypeUse) = withinTypeDepth { decodeNamedTypeUseBody(use) }

private fun ConversionScope.decodeNamedTypeUseBody(use: SkirNamedTypeUse) =
    TypeUse.Named(
        definition = decodeDefinitionId(use.definition),
        arguments = use.arguments.mapIndexed { index, value -> at("argument $index") { decodeTypeUse(value) } },
    )

private fun ConversionScope.encodeScalar(kind: ScalarKind): SkirScalarKind =
    when (kind) {
        ScalarKind.Unit -> SkirScalarKind.UNIT
        ScalarKind.Boolean -> SkirScalarKind.BOOLEAN
        ScalarKind.Text -> SkirScalarKind.TEXT
        ScalarKind.Bytes -> SkirScalarKind.BYTES
        is ScalarKind.Integer -> SkirScalarKind.createInteger(width = encode(kind.width))
        is ScalarKind.Float -> SkirScalarKind.createFloat(width = encode(kind.width))
        ScalarKind.Decimal -> SkirScalarKind.DECIMAL
        ScalarKind.Timestamp -> SkirScalarKind.TIMESTAMP
        ScalarKind.Duration -> SkirScalarKind.DURATION
    }

private fun ConversionScope.decodeScalar(kind: SkirScalarKind): ScalarKind =
    when (kind) {
        SkirScalarKind.UNIT -> ScalarKind.Unit
        SkirScalarKind.BOOLEAN -> ScalarKind.Boolean
        SkirScalarKind.TEXT -> ScalarKind.Text
        SkirScalarKind.BYTES -> ScalarKind.Bytes
        is SkirScalarKind.IntegerWrapper -> ScalarKind.Integer(decode(kind.value.width))
        is SkirScalarKind.FloatWrapper -> ScalarKind.Float(decode(kind.value.width))
        SkirScalarKind.DECIMAL -> ScalarKind.Decimal
        SkirScalarKind.TIMESTAMP -> ScalarKind.Timestamp
        SkirScalarKind.DURATION -> ScalarKind.Duration
        else -> fail("Unknown Skir scalar kind.")
    }

private fun encode(width: IntegerWidth): SkirIntegerWidth =
    when (width) {
        IntegerWidth.SIGNED_8 -> SkirIntegerWidth.SIGNED_EIGHT
        IntegerWidth.SIGNED_16 -> SkirIntegerWidth.SIGNED_SIXTEEN
        IntegerWidth.SIGNED_32 -> SkirIntegerWidth.SIGNED_THIRTY_TWO
        IntegerWidth.SIGNED_64 -> SkirIntegerWidth.SIGNED_SIXTY_FOUR
        IntegerWidth.UNSIGNED_8 -> SkirIntegerWidth.UNSIGNED_EIGHT
        IntegerWidth.UNSIGNED_16 -> SkirIntegerWidth.UNSIGNED_SIXTEEN
        IntegerWidth.UNSIGNED_32 -> SkirIntegerWidth.UNSIGNED_THIRTY_TWO
        IntegerWidth.UNSIGNED_64 -> SkirIntegerWidth.UNSIGNED_SIXTY_FOUR
    }

private fun ConversionScope.decode(width: SkirIntegerWidth): IntegerWidth =
    when (width) {
        SkirIntegerWidth.SIGNED_EIGHT -> IntegerWidth.SIGNED_8
        SkirIntegerWidth.SIGNED_SIXTEEN -> IntegerWidth.SIGNED_16
        SkirIntegerWidth.SIGNED_THIRTY_TWO -> IntegerWidth.SIGNED_32
        SkirIntegerWidth.SIGNED_SIXTY_FOUR -> IntegerWidth.SIGNED_64
        SkirIntegerWidth.UNSIGNED_EIGHT -> IntegerWidth.UNSIGNED_8
        SkirIntegerWidth.UNSIGNED_SIXTEEN -> IntegerWidth.UNSIGNED_16
        SkirIntegerWidth.UNSIGNED_THIRTY_TWO -> IntegerWidth.UNSIGNED_32
        SkirIntegerWidth.UNSIGNED_SIXTY_FOUR -> IntegerWidth.UNSIGNED_64
        else -> fail("Unknown Skir integer width.")
    }

private fun encode(width: FloatWidth): SkirFloatWidth =
    when (width) {
        FloatWidth.FLOAT_32 -> SkirFloatWidth.THIRTY_TWO
        FloatWidth.FLOAT_64 -> SkirFloatWidth.SIXTY_FOUR
    }

private fun ConversionScope.decode(width: SkirFloatWidth): FloatWidth =
    when (width) {
        SkirFloatWidth.THIRTY_TWO -> FloatWidth.FLOAT_32
        SkirFloatWidth.SIXTY_FOUR -> FloatWidth.FLOAT_64
        else -> fail("Unknown Skir float width.")
    }

private fun ConversionScope.encodeTypeDefinition(definition: TypeDefinition) =
    SkirTypeDefinition(
        id = encodeDefinitionId(definition.id),
        parameters = definition.parameters.mapIndexed { index, value -> at("parameter $index") { encode(value) } },
        representation = at("representation") { encode(definition.representation) },
        parents = definition.parents.mapIndexed { index, value -> at("parent $index") { encodeNamedTypeTemplate(value) } },
    )

private fun ConversionScope.decodeTypeDefinition(definition: SkirTypeDefinition) =
    TypeDefinition(
        id = decodeDefinitionId(definition.id),
        parameters = definition.parameters.mapIndexed { index, value -> at("parameter $index") { decode(value) } },
        representation = at("representation") { decode(definition.representation) },
        parents = definition.parents.mapIndexed { index, value -> at("parent $index") { decodeNamedTypeTemplate(value) } },
    )

private fun ConversionScope.encode(parameter: TypeParameter) =
    SkirTypeParameter(
        key = encodeParameterKey(parameter.key),
        name = parameter.name,
        bounds = parameter.bounds.mapIndexed { index, value -> at("bound $index") { encodeTypeTemplate(value) } },
    )

private fun ConversionScope.decode(parameter: SkirTypeParameter) =
    TypeParameter(
        key = decodeParameterKey(parameter.key),
        name = parameter.name,
        bounds = parameter.bounds.mapIndexed { index, value -> at("bound $index") { decodeTypeTemplate(value) } },
    )

private fun ConversionScope.encode(owner: FieldOwner) = SkirFieldOwner(definition = encodeDefinitionId(owner.definition), name = owner.name)

private fun ConversionScope.decode(owner: SkirFieldOwner) = FieldOwner(definition = decodeDefinitionId(owner.definition), name = owner.name)

private fun ConversionScope.encode(field: FieldDeclaration) =
    SkirFieldDeclaration(
        owner = encode(field.owner),
        type = encodeTypeTemplate(field.type),
        overrides = field.overrides.map(::encode),
        hasConstructorDefault = field.hasConstructorDefault,
    )

private fun ConversionScope.decode(field: SkirFieldDeclaration) =
    FieldDeclaration(
        owner = decode(field.owner),
        type = decodeTypeTemplate(field.type),
        overrides = field.overrides.map(::decode),
        hasConstructorDefault = field.hasConstructorDefault,
    )

private fun ConversionScope.encode(representation: RepresentationTemplate): SkirRepresentationTemplate =
    when (representation) {
        is RepresentationTemplate.Scalar -> {
            SkirRepresentationTemplate.createScalar(kind = encodeScalar(representation.kind))
        }

        is RepresentationTemplate.Record -> {
            SkirRepresentationTemplate.createRecord(fields = representation.fields.map(::encode), abstract_ = representation.abstract)
        }

        is RepresentationTemplate.Sequence -> {
            SkirRepresentationTemplate.createSequence(item = encodeTypeTemplate(representation.item), kind = encode(representation.kind))
        }

        is RepresentationTemplate.Mapping -> {
            SkirRepresentationTemplate.createMapping(
                key = encodeTypeTemplate(representation.key),
                value = encodeTypeTemplate(representation.value),
            )
        }

        is RepresentationTemplate.Enumeration -> {
            SkirRepresentationTemplate.createEnumeration(cases = representation.cases.map { SkirEnumVariant(key = it.key) })
        }

        is RepresentationTemplate.Link -> {
            SkirRepresentationTemplate.createLink(
                endpoint =
                    skirout.editor.v1.type_catalog
                        .EndpointId(value = representation.endpoint.value),
                target = encodeTypeTemplate(representation.target),
            )
        }
    }

private fun ConversionScope.decode(representation: SkirRepresentationTemplate): RepresentationTemplate =
    when (representation) {
        is SkirRepresentationTemplate.ScalarWrapper -> {
            RepresentationTemplate.Scalar(decodeScalar(representation.value.kind))
        }

        is SkirRepresentationTemplate.RecordWrapper -> {
            RepresentationTemplate.Record(representation.value.fields.map(::decode), representation.value.abstract_)
        }

        is SkirRepresentationTemplate.SequenceWrapper -> {
            RepresentationTemplate.Sequence(decodeTypeTemplate(representation.value.item), decode(representation.value.kind))
        }

        is SkirRepresentationTemplate.MappingWrapper -> {
            RepresentationTemplate.Mapping(decodeTypeTemplate(representation.value.key), decodeTypeTemplate(representation.value.value))
        }

        is SkirRepresentationTemplate.EnumerationWrapper -> {
            RepresentationTemplate.Enumeration(representation.value.cases.map { EnumVariant(it.key) })
        }

        is SkirRepresentationTemplate.LinkWrapper -> {
            RepresentationTemplate.Link(
                endpoint = com.typewritermc.types.EndpointId(representation.value.endpoint.value),
                target = decodeTypeTemplate(representation.value.target),
            )
        }

        else -> {
            fail("Unknown Skir representation template.")
        }
    }

private fun encode(kind: CollectionKind): SkirCollectionKind =
    when (kind) {
        CollectionKind.List -> SkirCollectionKind.LIST
        CollectionKind.Set -> SkirCollectionKind.SET
    }

private fun ConversionScope.decode(kind: SkirCollectionKind): CollectionKind =
    when (kind) {
        SkirCollectionKind.LIST -> CollectionKind.List
        SkirCollectionKind.SET -> CollectionKind.Set
        else -> fail("Unknown Skir collection kind.")
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
    EditorCatalogWireSnapshot(
        generation =
            skirout.editor.v1.type_catalog
                .CatalogGeneration(value = snapshot.generation.value),
        types = snapshot.types.mapIndexed { index, value -> at("type $index") { encode(value) } },
        relations = snapshot.relations.mapIndexed { index, value -> at("relation $index") { encode(value) } },
        resourceDefinitions =
            snapshot.resourceDefinitions.mapIndexed {
                index,
                value,
                ->
                at("resource definition $index") { encode(value) }
            },
        presentations = snapshot.presentations.mapIndexed { index, value -> at("presentation $index") { encode(value) } },
        presentationMaterials =
            snapshot.presentationMaterials.mapIndexed {
                index,
                value,
                ->
                at("presentation material $index") { encode(value) }
            },
        configuration = snapshot.configuration.mapIndexed { index, value -> at("configuration $index") { encode(value) } },
        diagnostics = snapshot.diagnostics.mapIndexed { index, value -> at("diagnostic $index") { encode(value) } },
        initialization = snapshot.initialization.mapIndexed { index, value -> at("initialization $index") { encode(value) } },
        endpointBindings = snapshot.endpointBindings.mapIndexed { index, value -> at("endpoint binding $index") { encode(value) } },
        capabilities = snapshot.capabilities.mapIndexed { index, value -> at("capability $index") { encode(value) } },
        recommendations = snapshot.recommendations.mapIndexed { index, value -> at("recommendation $index") { encode(value) } },
        roleFallbacks = snapshot.roleFallbacks.mapIndexed { index, value -> at("role fallback $index") { encode(value) } },
    )

private fun encode(fallback: RoleFallback): SkirRoleFallback =
    SkirRoleFallback(
        role = encode(fallback.role),
        parents = fallback.parents.map(::encode),
    )

private fun ConversionScope.encode(capability: RealmCapabilityDescriptor): SkirCapabilityDefinition =
    when (capability) {
        is RealmCapabilityDescriptor.Search -> {
            SkirCapabilityDefinition.SearchWrapper(
                SkirSearchCapabilityDefinition(
                    capabilityId =
                        skirout.editor.v1.type_catalog
                            .CapabilityId(value = capability.id.value),
                    requestType = encodeTypeUse(capability.requestType),
                    resultType = encodeTypeUse(capability.resultType),
                ),
            )
        }

        is RealmCapabilityDescriptor.Computation -> {
            SkirCapabilityDefinition.ComputationWrapper(
                SkirComputationCapabilityDefinition(
                    capabilityId =
                        skirout.editor.v1.type_catalog
                            .CapabilityId(value = capability.id.value),
                    requestType = encodeTypeUse(capability.requestType),
                    resultType = encodeTypeUse(capability.resultType),
                ),
            )
        }

        is RealmCapabilityDescriptor.Command -> {
            SkirCapabilityDefinition.CommandWrapper(
                SkirCommandCapabilityDefinition(
                    capabilityId =
                        skirout.editor.v1.type_catalog
                            .CapabilityId(value = capability.id.value),
                    requestType = encodeTypeUse(capability.requestType),
                ),
            )
        }
    }

private fun ConversionScope.encode(recommendation: TypeRecommendation) =
    skirout.editor.v1.catalog.TypeRecommendation(
        type = encodeNamedTypeUse(recommendation.type),
        occurrences = recommendation.occurrences,
    )

private fun ConversionScope.encode(binding: com.typewritermc.types.EndpointBindingTemplate) =
    skirout.editor.v1.catalog.EndpointBindingTemplate(
        endpoint =
            skirout.editor.v1.type_catalog
                .EndpointId(value = binding.endpoint.value),
        containingResource = encodeNamedTypeTemplate(binding.containingResource),
        valueOwner = encodeDefinitionId(binding.valueOwner),
        relativePath = encode(binding.relativePath),
        target = encodeTypeTemplate(binding.target),
        containsCollection = binding.containsCollection,
    )

private fun ConversionScope.encode(type: PublishedType) =
    SkirPublishedType(
        definition = encodeTypeDefinition(type.definition),
        status =
            when (val status = type.status) {
                DeclarationStatus.Ready -> SkirDeclarationStatus.READY
                is DeclarationStatus.Unavailable -> SkirDeclarationStatus.UnavailableWrapper(status.reasons.map(::encode))
            },
        effectiveFields = type.effectiveFields.map(::encode),
        ancestorTemplates = type.ancestorTemplates.map(::encodeNamedTypeTemplate),
        display = type.display?.let(::encode),
    )

private fun ConversionScope.encode(display: TypeDisplay) =
    SkirTypeDisplay(
        name = display.name,
        description = display.description,
        icon = display.icon,
        color = display.color,
    )

private fun ConversionScope.encode(field: EffectiveFieldTemplate) =
    SkirEffectiveFieldTemplate(
        key = field.key,
        owner = encode(field.owner),
        type = encodeTypeTemplate(field.type),
        rules = field.rules.map(::encode),
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
        id =
            skirout.editor.v1.type_catalog
                .EndpointId(value = endpoint.id.value),
        slot =
            when (endpoint.slot) {
                EndpointSlot.First -> SkirEndpointSlot.FIRST
                EndpointSlot.Second -> SkirEndpointSlot.SECOND
            },
        resource = encodeNamedTypeTemplate(endpoint.resource),
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

private fun ConversionScope.encode(resource: AuthoringResourceDefinition) =
    SkirAuthoringResourceDefinition(
        id =
            skirout.editor.v1.catalog
                .ResourceDefinitionId(value = resource.id.value),
        root = encodeDefinitionId(resource.root),
        navigationHandler = resource.navigationHandler,
    )

private fun ConversionScope.encode(presentation: PresentationDescriptor) =
    SkirPresentationDescriptor(
        id = encode(presentation.id),
        owner = encode(presentation.owner),
        target = encode(presentation.target),
        roles = presentation.roles.sortedBy { it.ordinal }.map(::encode),
        priority = presentation.priority,
    )

private fun ConversionScope.encode(material: PresentationMaterial) =
    SkirPresentationMaterial(
        provider = encode(material.provider),
        target = encode(material.target),
        role = encode(material.role),
        layout = material.layout,
        dependencies = material.dependencies,
        subject = encodeTypeTemplate(material.subject),
    )

private fun encode(id: PresentationId) = SkirPresentationId(namespace = id.namespace, name = id.name)

private fun ConversionScope.encode(owner: DeclarationOwner) =
    SkirDeclarationOwner(source = encode(owner.source), localIdentity = owner.localIdentity)

private fun encode(key: ContributionKey) =
    SkirContributionKey(
        source = SkirContributionSourceId(value = key.source.value),
        sourcePart = key.sourcePart,
        producer = SkirProducerId(value = key.producer.value),
        name = SkirContributionName(value = key.name.value),
    )

private fun ConversionScope.encode(target: PresentationTarget): SkirPresentationTarget =
    when (target) {
        is PresentationTarget.Named -> SkirPresentationTarget.NamedWrapper(encodeNamedTypeTemplate(target.type))
        is PresentationTarget.Representation -> SkirPresentationTarget.RepresentationWrapper(encode(target.kind))
    }

private fun encode(role: PresentationRole): SkirPresentationRole =
    when (role) {
        PresentationRole.EDITOR -> SkirPresentationRole.EDITOR
        PresentationRole.INSPECTOR -> SkirPresentationRole.INSPECTOR
        PresentationRole.REFERENCE_SUMMARY -> SkirPresentationRole.REFERENCE_SUMMARY
        PresentationRole.REFERENCE_OPTION -> SkirPresentationRole.REFERENCE_OPTION
        PresentationRole.COLLECTION_ITEM -> SkirPresentationRole.COLLECTION_ITEM
        PresentationRole.CATALOG_OPTION -> SkirPresentationRole.CATALOG_OPTION
        PresentationRole.AUTHORING_RESULT -> SkirPresentationRole.AUTHORING_RESULT
        PresentationRole.PAGE_TILE -> SkirPresentationRole.PAGE_TILE
        PresentationRole.GRAPH_NODE -> SkirPresentationRole.GRAPH_NODE
        PresentationRole.INSPECTOR_HEADER -> SkirPresentationRole.INSPECTOR_HEADER
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
        origin = encode(recipe.origin),
        relativePath = encode(recipe.relativePath),
        representationCondition = recipe.representationCondition?.let(::encode),
        rules = recipe.rules.map(::encode),
    )

private fun ConversionScope.encode(rule: OwnedRule) =
    SkirOwnedRule(
        id = encode(rule.id),
        descriptor = SkirRuleDescriptor(predicate = encode(rule.descriptor.predicate)),
        diagnostic =
            SkirDiagnosticTemplate(
                code = rule.diagnostic.code,
                message = rule.diagnostic.message,
                severity = encode(rule.diagnostic.severity),
                targets = rule.diagnostic.targets.map(::encode),
            ),
    )

private fun ConversionScope.encode(expression: ExpressionNode): SkirExpressionNode =
    when (expression) {
        is ExpressionNode.Literal -> {
            SkirExpressionNode.LiteralWrapper(encodeDataValue(expression.value))
        }

        is ExpressionNode.Read -> {
            SkirExpressionNode.ReadWrapper(
                SkirExpressionRead(
                    binding =
                        skirout.editor.v1.type_catalog
                            .ExpressionBindingId(value = expression.binding.value),
                    path = encodeValuePath(expression.path),
                ),
            )
        }

        is ExpressionNode.Call -> {
            SkirExpressionNode.CallWrapper(
                SkirExpressionCall(
                    operation =
                        skirout.editor.v1.type_catalog
                            .OperationId(value = expression.operation.value),
                    arguments = expression.arguments.map(::encode),
                ),
            )
        }

        is ExpressionNode.And -> {
            SkirExpressionNode.AndWrapper(SkirBinaryExpression(left = encode(expression.left), right = encode(expression.right)))
        }

        is ExpressionNode.Or -> {
            SkirExpressionNode.OrWrapper(SkirBinaryExpression(left = encode(expression.left), right = encode(expression.right)))
        }

        is ExpressionNode.Conditional -> {
            SkirExpressionNode.ConditionalWrapper(
                SkirConditionalExpression(test = encode(expression.test), yes = encode(expression.yes), no = encode(expression.no)),
            )
        }

        is ExpressionNode.OrElse -> {
            SkirExpressionNode.OrElseWrapper(SkirOrElseExpression(input = encode(expression.input), fallback = encode(expression.fallback)))
        }

        is ExpressionNode.Collection -> {
            SkirExpressionNode.CollectionWrapper(
                SkirCollectionExpression(
                    operation =
                        skirout.editor.v1.type_catalog
                            .OperationId(value = expression.operation.value),
                    input = encode(expression.input),
                    bindings =
                        expression.bindings.map {
                            skirout.editor.v1.type_catalog
                                .ExpressionBindingId(value = it.value)
                        },
                    arguments = expression.arguments.map(::encode),
                    body = expression.body?.let(::encode),
                ),
            )
        }
    }

private fun ConversionScope.encode(diagnostic: DeclarationDiagnostic) =
    SkirDeclarationDiagnostic(
        affected = encodeDefinitionId(diagnostic.affected),
        code = diagnostic.code,
        origins = diagnostic.origins.map { SkirDeclarationOrigin(owner = encode(it.owner)) },
        field = diagnostic.field?.let(::encode),
    )

private fun ConversionScope.encode(diagnostic: Diagnostic) =
    SkirDiagnostic(
        id =
            skirout.editor.v1.type_catalog
                .DiagnosticId(value = diagnostic.id.value),
        origin = encode(diagnostic.origin),
        code = diagnostic.code,
        message = diagnostic.message,
        severity = encode(diagnostic.severity),
        primary = diagnostic.primary?.let(::encodeValueLocation),
        related = diagnostic.related.map(::encodeValueLocation),
    )

private fun ConversionScope.encode(initialization: InitializationDescriptor) =
    SkirInitializationDescriptor(
        definition = encodeDefinitionId(initialization.definition),
        mode =
            when (initialization.mode) {
                com.typewritermc.authoring.InitializationMode.Startup -> SkirInitializationMode.STARTUP
                com.typewritermc.authoring.InitializationMode.Creation -> SkirInitializationMode.CREATION
            },
        captured =
            initialization.captured.map {
                skirout.editor.v1.catalog
                    .CapturedDefault(field = encode(it.field), value = encodeDataValue(it.value))
            },
        diagnostics =
            initialization.diagnostics.map {
                SkirInitializationDiagnostic(
                    field = it.field?.let(::encode),
                    code = it.code,
                    message = it.message,
                    relativePath = it.relativePath?.let(::encodeValuePath),
                )
            },
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

private fun ConversionScope.encode(origin: RuleOrigin) = SkirRuleOrigin(owner = encodeDefinitionId(origin.owner), ordinal = origin.ordinal)

private fun ConversionScope.encode(id: RuleId) = SkirRuleId(origin = encode(id.origin), localIndex = id.localIndex)

private fun encode(severity: DiagnosticSeverity): SkirDiagnosticSeverity =
    when (severity) {
        DiagnosticSeverity.Info -> SkirDiagnosticSeverity.INFORMATION
        DiagnosticSeverity.Warning -> SkirDiagnosticSeverity.WARNING
        DiagnosticSeverity.Error -> SkirDiagnosticSeverity.ERROR
    }
