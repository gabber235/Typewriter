package com.typewritermc.discovery

import com.typewritermc.authoring.CompletenessResult
import com.typewritermc.authoring.complete
import com.typewritermc.authoring.field
import com.typewritermc.authoring.name
import com.typewritermc.authoring.root
import com.typewritermc.capability.id
import com.typewritermc.configuration.field
import com.typewritermc.configuration.name
import com.typewritermc.presentation.CheckedPresentationTemplate
import com.typewritermc.presentation.NestedPresentationSlot
import com.typewritermc.presentation.PresentationBuildBinding
import com.typewritermc.presentation.PresentationNestedTemplate
import com.typewritermc.presentation.PresentationTyping
import com.typewritermc.presentation.inferInheritableNodes
import com.typewritermc.presentation.selectMostSpecificDescriptors
import com.typewritermc.presentation.validateInheritableNodes
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.catalog.apply
import com.typewritermc.types.catalog.of
import com.typewritermc.types.endpoint
import com.typewritermc.types.entries
import com.typewritermc.types.field
import com.typewritermc.types.fields
import com.typewritermc.types.floatScalar
import com.typewritermc.types.integerScalar
import com.typewritermc.types.isValid
import com.typewritermc.types.namedTemplate
import com.typewritermc.types.parameterKeys
import com.typewritermc.types.portableOrNull
import com.typewritermc.types.substitute
import com.typewritermc.types.template
import com.typewritermc.types.unknownVariant
import com.typewritermc.types.use
import com.typewritermc.types.validOrNull
import kotlinx.coroutines.CancellationException
import skirout.editor.v1.catalog.DeclarationStatus
import skirout.editor.v1.catalog.PresentationMaterial
import skirout.editor.v1.catalog.PresentationTarget
import skirout.editor.v1.catalog.RepresentationKind
import skirout.editor.v1.diagnostic.DeclarationDiagnostic
import skirout.editor.v1.diagnostic.DeclarationOrigin
import skirout.editor.v1.type_catalog.CollectionKind
import skirout.editor.v1.type_catalog.EndpointId
import skirout.editor.v1.type_catalog.FloatWidth
import skirout.editor.v1.type_catalog.IntegerWidth
import skirout.editor.v1.type_catalog.NamedTypeTemplate
import skirout.editor.v1.type_catalog.ParameterKey
import skirout.editor.v1.type_catalog.PathSegment
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeParameter
import skirout.editor.v1.type_catalog.TypeTemplate
import skirout.editor.v1.type_catalog.ValuePath

/** One published material with the subject and target whose readiness in the final catalog decides its publication. */
internal class CollectedPresentationMaterial(
    val subject: TypeTemplate,
    val target: PresentationTarget,
    val material: PresentationMaterial,
)

/**
 * Materials that built, the [failures] that make a type unavailable, and the [rejected] materials whose build
 * failed. A rejected material is dropped on its own: its subject type stays available, so the next applicable
 * material or the default presentation takes its place, and the cause stays in [callbackFailures].
 */
internal data class PresentationMaterialCollection(
    val materials: List<CollectedPresentationMaterial>,
    val failures: List<DeclarationDiagnostic>,
    val rejected: List<DeclarationDiagnostic>,
    val callbackFailures: List<CatalogCallbackFailure>,
)

internal fun collectPresentationMaterials(
    presentations: List<OwnedPresentation>,
    declarations: List<OwnedTypeDeclaration>,
    nativeBindings: List<OwnedNativeBinding>,
    definitions: Map<TypeDefinitionId, TypeDefinition>,
    catalog: CheckedCatalog,
    typing: PresentationTyping,
    resourceTypes: Set<TypeDefinitionId>,
    ownershipEndpoints: Set<EndpointId>,
): PresentationMaterialCollection {
    val materials = mutableListOf<CollectedPresentationMaterial>()
    val failures = mutableListOf<DeclarationDiagnostic>()
    val rejected = mutableListOf<DeclarationDiagnostic>()
    val callbackFailures = mutableListOf<CatalogCallbackFailure>()
    val nativeTypes =
        (
            declarations.mapNotNull { owned ->
                val native = owned.nativeClass ?: return@mapNotNull null
                val definition = definitions[owned.definition.id] ?: return@mapNotNull null
                if (catalog.declaration(definition.id) !is Resolution.Ready) return@mapNotNull null
                native to definition.id.namedTemplate(definition.parameters.map { it.key.template })
            } +
                nativeBindings
                    .mapNotNull { owned ->
                        val native = owned.factory.nativeClass ?: return@mapNotNull null
                        val definition = definitions[owned.factory.definition] ?: return@mapNotNull null
                        if (catalog.declaration(definition.id) !is Resolution.Ready) return@mapNotNull null
                        native to definition.id.namedTemplate(definition.parameters.map { it.key.template })
                    }
        ).groupBy(Pair<kotlin.reflect.KClass<*>, NamedTypeTemplate>::first)
            .mapNotNull { (native, declarations) ->
                declarations
                    .map { it.second }
                    .distinct()
                    .singleOrNull()
                    ?.let { native to it }
            }.toMap()
    presentations.forEach { owned ->
        val target = owned.descriptor.target
        val subjects = target.presentationSubjects(definitions)
        if (subjects.isEmpty() && target is PresentationTarget.NamedWrapper) {
            failures +=
                DeclarationDiagnostic.of(
                    affected = target.value.definition,
                    code = "invalid_presentation_target",
                    origins = listOf(DeclarationOrigin(owner = owned.descriptor.owner)),
                )
        }
        subjects.forEach { subject ->
            val template = subject.presentationTemplate(definitions, catalog, typing)
            owned.descriptor.roles.sortedBy { it.kind.ordinal }.forEach { role ->
                try {
                    val result = owned.provider.build(PresentationBuildBinding(template, role, nativeTypes, ownershipEndpoints))
                    val inferred = result.layout.inferInheritableNodes(result.dependencies)
                    result.layout.validateInheritableNodes(
                        inferred,
                        result.dependencies,
                        partOwnerCompatible = { key ->
                            val owner = key.owner
                            val actual = (subject as? TypeTemplate.NamedWrapper)?.value?.definition
                            actual != null && definitions[owner]?.representation is RepresentationTemplate.RecordWrapper &&
                                catalog.isNominalSubtype(actual, owner)
                        },
                    ) { field ->
                        subject.field(field, definitions) !=
                            null
                    }
                    if (result.dependencies.validCollections(subject, definitions, catalog, resourceTypes)) {
                        materials +=
                            CollectedPresentationMaterial(
                                subject = subject,
                                target = owned.descriptor.target,
                                material =
                                    PresentationMaterial(
                                        provider = owned.descriptor.id,
                                        target = owned.descriptor.target,
                                        role = role,
                                        layout = result.layout,
                                        dependencies = result.dependencies,
                                        subject = subject,
                                        inheritableNodes = inferred,
                                    ),
                            )
                    } else {
                        val affected = (subject as? TypeTemplate.NamedWrapper)?.value?.definition
                        if (affected != null) {
                            failures +=
                                DeclarationDiagnostic.of(
                                    affected = affected,
                                    code = "invalid_presentation_collection_dependency",
                                    origins = listOf(DeclarationOrigin(owner = owned.descriptor.owner)),
                                )
                        }
                    }
                } catch (cancellation: CancellationException) {
                    throw cancellation
                } catch (cause: Exception) {
                    callbackFailures +=
                        CatalogCallbackFailure(
                            owned.origin,
                            CatalogCallback.Presentation(subject, role),
                            cause,
                        )
                    val affected = (subject as? TypeTemplate.NamedWrapper)?.value?.definition
                    if (affected != null) {
                        rejected +=
                            DeclarationDiagnostic.of(
                                affected = affected,
                                code = "presentation_material_build_failed",
                                origins = listOf(DeclarationOrigin(owner = owned.descriptor.owner)),
                            )
                    }
                }
            }
        }
    }
    return PresentationMaterialCollection(materials, failures, rejected, callbackFailures)
}

private fun skirout.editor.v1.presentation.PresentationDependencies.validCollections(
    subject: TypeTemplate,
    definitions: Map<TypeDefinitionId, TypeDefinition>,
    catalog: CheckedCatalog,
    resourceTypes: Set<TypeDefinitionId>,
): Boolean {
    val parameters = subject.parameterKeys()
    val parameterBounds =
        parameters.associateWith { key ->
            definitions[key.owner]
                ?.parameters
                ?.singleOrNull { it.key == key }
                ?.bounds
                ?: return false
        }
    return collections.all { collection ->
        val rowType = collection.rowBinding.type.takeIf { it.isValid } ?: return@all false
        if (!rowType.isValidMaterialTemplate(definitions, parameterBounds, catalog)) return@all false
        collection.projection?.isValid(rowType, definitions, parameterBounds, catalog, resourceTypes) ?: true
    }
}

private fun skirout.editor.v1.presentation.PresentationCollectionProjection.isValid(
    rowType: TypeTemplate,
    definitions: Map<TypeDefinitionId, TypeDefinition>,
    parameterBounds: Map<ParameterKey, List<TypeTemplate>>,
    catalog: CheckedCatalog,
    resourceTypes: Set<TypeDefinitionId>,
): Boolean {
    val root = this.root.takeIf { it.isValid } ?: return false
    if (!root.template.isValidMaterialTemplate(definitions, parameterBounds, catalog)) return false
    if (root.definition !in resourceTypes) return false
    return fields.all { field ->
        val targetPath = field.target.validOrNull() ?: return@all false
        val targetType = rowType.templateAt(targetPath, definitions) ?: return@all false
        when (val source = field.source) {
            is skirout.editor.v1.presentation.PresentationCollectionProjectionValue.ContentWrapper -> {
                val sourcePath = source.value.validOrNull() ?: return@all false
                val sourceType = root.template.templateAt(sourcePath, definitions) ?: return@all false
                catalog.isTemplateReadableAs(sourceType, targetType, parameterBounds)
            }

            is skirout.editor.v1.presentation.PresentationCollectionProjectionValue.LiteralWrapper -> {
                val value = source.value.portableOrNull() ?: return@all false
                targetType.acceptsLiteral(value, parameterBounds.keys, catalog)
            }

            is skirout.editor.v1.presentation.PresentationCollectionProjectionValue.Unknown -> {
                false
            }
        }
    }
}

private fun TypeTemplate.isValidMaterialTemplate(
    definitions: Map<TypeDefinitionId, TypeDefinition>,
    parameterBounds: Map<ParameterKey, List<TypeTemplate>>,
    catalog: CheckedCatalog,
): Boolean =
    when (this) {
        is TypeTemplate.ParameterWrapper -> {
            value in parameterBounds
        }

        is TypeTemplate.NamedWrapper -> {
            val definition = definitions[value.definition]
            definition != null &&
                catalog.definition(this.value.definition) == DeclarationStatus.READY &&
                value.arguments.size == definition.parameters.size &&
                value.arguments.all { it.isValidMaterialTemplate(definitions, parameterBounds, catalog) } &&
                definition.parameters.zip(value.arguments).all { (parameter, argument) ->
                    val bindings =
                        definition.parameters
                            .map(TypeParameter::key)
                            .zip(value.arguments)
                            .toMap()
                    parameter.bounds.all { bound ->
                        val expected = bound.substitute(bindings)
                        catalog.isTemplateReadableAs(argument, expected, parameterBounds)
                    }
                }
        }

        is TypeTemplate.NullableWrapper -> {
            value.value.isValidMaterialTemplate(definitions, parameterBounds, catalog)
        }

        is TypeTemplate.ScalarWrapper -> {
            true
        }

        else -> {
            unknownVariant(this)
        }
    }

private fun TypeTemplate.acceptsLiteral(
    value: skirout.editor.v1.type_catalog.DataValue,
    parameters: Set<ParameterKey>,
    catalog: CheckedCatalog,
): Boolean {
    if (value == skirout.editor.v1.type_catalog.DataValue.UNFILLED) return true
    if (parameterKeys().any(parameters::contains)) return false
    val use = (apply(emptyMap()) as? Resolution.Ready)?.value ?: return false
    val checked = (catalog.resolve(use) as? Resolution.Ready)?.value ?: return false
    return checked.complete(value) !is CompletenessResult.Invalid
}

internal fun TypeTemplate.templateAt(
    path: ValuePath,
    definitions: Map<TypeDefinitionId, TypeDefinition>,
): TypeTemplate? {
    var current = this
    path.segments.forEach { segment ->
        current = current.unwrapNullable()
        current =
            when (segment) {
                is PathSegment.FieldWrapper -> {
                    current.field(segment.name, definitions)
                }

                is PathSegment.ItemWrapper -> {
                    current.representation(definitions)?.let { (representation, arguments) ->
                        (representation as? RepresentationTemplate.SequenceWrapper)?.value?.item?.substitute(arguments)
                    }
                }

                PathSegment.MAP_KEY -> {
                    current.representation(definitions)?.let { (representation, arguments) ->
                        (representation as? RepresentationTemplate.MappingWrapper)?.value?.key?.substitute(arguments)
                    }
                }

                PathSegment.MAP_VALUE -> {
                    current.representation(definitions)?.let { (representation, arguments) ->
                        (representation as? RepresentationTemplate.MappingWrapper)?.value?.value?.substitute(arguments)
                    }
                }

                else -> {
                    unknownVariant(segment)
                }
            } ?: return null
    }
    return current
}

private fun PresentationTarget.presentationSubjects(definitions: Map<TypeDefinitionId, TypeDefinition>): List<TypeTemplate> =
    when (this) {
        is PresentationTarget.NamedWrapper -> {
            val definition = definitions[value.definition]
            if (definition == null || definition.parameters.size != value.arguments.size) emptyList() else listOf(value.template)
        }

        is PresentationTarget.RepresentationWrapper -> {
            val named =
                definitions.values
                    .filter { it.representation.presentationKind() == value }
                    .map { definition ->
                        definition.id.template(definition.parameters.map { it.key.template })
                    }
            (named + value.scalarSubjects()).distinct()
        }

        else -> {
            unknownVariant(this)
        }
    }

private fun RepresentationKind.scalarSubjects(): List<TypeTemplate> =
    when (this) {
        RepresentationKind.UNIT -> {
            listOf(ScalarKind.UNIT.template)
        }

        RepresentationKind.BOOLEAN -> {
            listOf(ScalarKind.BOOLEAN.template)
        }

        RepresentationKind.TEXT -> {
            listOf(ScalarKind.TEXT.template)
        }

        RepresentationKind.BYTES -> {
            listOf(ScalarKind.BYTES.template)
        }

        RepresentationKind.INTEGER -> {
            IntegerWidth.entries.map { width ->
                integerScalar(width).template
            }
        }

        RepresentationKind.FLOAT -> {
            FloatWidth.entries.map { width ->
                floatScalar(width).template
            }
        }

        RepresentationKind.DECIMAL -> {
            listOf(ScalarKind.DECIMAL.template)
        }

        RepresentationKind.TIMESTAMP -> {
            listOf(ScalarKind.TIMESTAMP.template)
        }

        RepresentationKind.DURATION -> {
            listOf(ScalarKind.DURATION.template)
        }

        else -> {
            emptyList()
        }
    }

private fun RepresentationTemplate.presentationKind(): RepresentationKind =
    when (this) {
        is RepresentationTemplate.ScalarWrapper -> {
            when (val kind = value.kind) {
                ScalarKind.UNIT -> RepresentationKind.UNIT
                ScalarKind.BOOLEAN -> RepresentationKind.BOOLEAN
                ScalarKind.TEXT -> RepresentationKind.TEXT
                ScalarKind.BYTES -> RepresentationKind.BYTES
                is ScalarKind.IntegerWrapper -> RepresentationKind.INTEGER
                is ScalarKind.FloatWrapper -> RepresentationKind.FLOAT
                ScalarKind.DECIMAL -> RepresentationKind.DECIMAL
                ScalarKind.TIMESTAMP -> RepresentationKind.TIMESTAMP
                ScalarKind.DURATION -> RepresentationKind.DURATION
                else -> unknownVariant(kind)
            }
        }

        is RepresentationTemplate.RecordWrapper -> {
            RepresentationKind.RECORD
        }

        is RepresentationTemplate.SequenceWrapper -> {
            when (val kind = value.kind) {
                CollectionKind.LIST -> RepresentationKind.LIST
                CollectionKind.SET -> RepresentationKind.SET
                else -> unknownVariant(kind)
            }
        }

        is RepresentationTemplate.MappingWrapper -> {
            RepresentationKind.MAP
        }

        is RepresentationTemplate.EnumerationWrapper -> {
            RepresentationKind.ENUMERATION
        }

        is RepresentationTemplate.LinkWrapper -> {
            RepresentationKind.LINK
        }

        else -> {
            unknownVariant(this)
        }
    }

private fun TypeTemplate.matchesTemplate(
    actual: TypeTemplate,
    parameters: MutableMap<ParameterKey, TypeTemplate>,
): Boolean =
    when (this) {
        is TypeTemplate.ParameterWrapper -> {
            parameters[value]?.let { it == actual } ?: run {
                parameters[value] = actual
                true
            }
        }

        is TypeTemplate.ScalarWrapper -> {
            actual == this
        }

        is TypeTemplate.NullableWrapper -> {
            actual is TypeTemplate.NullableWrapper && value.value.matchesTemplate(actual.value.value, parameters)
        }

        is TypeTemplate.NamedWrapper -> {
            if (actual !is TypeTemplate.NamedWrapper || value.definition != actual.value.definition ||
                value.arguments.size != actual.value.arguments.size
            ) {
                false
            } else {
                val candidateParameters = LinkedHashMap(parameters)
                val matches =
                    value.arguments.zip(actual.value.arguments).all { (expected, supplied) ->
                        expected.matchesTemplate(supplied, candidateParameters)
                    }
                if (matches) {
                    parameters.clear()
                    parameters.putAll(candidateParameters)
                }
                matches
            }
        }

        else -> {
            unknownVariant(this)
        }
    }

private fun TypeTemplate.presentationTemplate(
    definitions: Map<TypeDefinitionId, TypeDefinition>,
    catalog: CheckedCatalog,
    typing: PresentationTyping,
): CheckedPresentationTemplate =
    CheckedPresentationTemplate(
        type = this,
        fieldResolver = { parent, name -> parent.unwrapNullable().field(name, definitions) },
        nestedResolver = { parent, slot -> parent.presentationNested(slot, definitions) },
        typing = typing,
        payloadResolver = { parent ->
            val scalar = (parent.unwrapNullable().representation(definitions)?.first as? RepresentationTemplate.ScalarWrapper)?.value?.kind
            if (scalar == null) parent.unwrapNullable() else scalar.template
        },
        linkResolver = { parent ->
            parent.unwrapNullable().representation(definitions)?.let { (representation, arguments) ->
                (representation as? RepresentationTemplate.LinkWrapper)?.let { link ->
                    com.typewritermc.presentation.PresentationLinkTemplate(link.value.endpoint, link.value.target.substitute(arguments))
                }
            }
        },
        subtypeChecker = catalog::isNominalSubtype,
        descriptorSelector = { actual, descriptors ->
            val bounds = definitions.parameterBounds()
            selectMostSpecificDescriptors(
                descriptors.filter { descriptor -> descriptor.target.appliesTo(actual, definitions, bounds) },
                catalog,
            )
        },
    )

private fun Map<TypeDefinitionId, TypeDefinition>.parameterBounds(): Map<ParameterKey, List<TypeTemplate>> =
    values
        .flatMap { definition -> definition.parameters.map { parameter -> parameter.key to parameter.bounds } }
        .toMap()

private fun PresentationTarget.appliesTo(
    actual: TypeTemplate,
    definitions: Map<TypeDefinitionId, TypeDefinition>,
    bounds: Map<ParameterKey, List<TypeTemplate>>,
): Boolean =
    when (this) {
        is PresentationTarget.RepresentationWrapper -> {
            value in actual.presentationKinds(definitions, bounds, linkedSetOf())
        }

        is PresentationTarget.NamedWrapper -> {
            actual.presentationApplications(definitions, bounds, linkedSetOf()).any { application ->
                value.template.matchesTemplate(application.template, linkedMapOf())
            }
        }

        else -> {
            unknownVariant(this)
        }
    }

private fun TypeTemplate.presentationKinds(
    definitions: Map<TypeDefinitionId, TypeDefinition>,
    bounds: Map<ParameterKey, List<TypeTemplate>>,
    visiting: MutableSet<TypeTemplate>,
): Set<RepresentationKind> {
    if (!visiting.add(this)) return emptySet()
    return try {
        when (this) {
            is TypeTemplate.ScalarWrapper -> {
                setOf(value.presentationKind())
            }

            is TypeTemplate.NullableWrapper -> {
                value.value.presentationKinds(definitions, bounds, visiting)
            }

            is TypeTemplate.ParameterWrapper -> {
                bounds[value].orEmpty().flatMapTo(
                    linkedSetOf(),
                ) { it.presentationKinds(definitions, bounds, visiting) }
            }

            is TypeTemplate.NamedWrapper -> {
                definitions[value.definition]
                    ?.representation
                    ?.presentationKind()
                    ?.let(::setOf)
                    .orEmpty()
            }

            else -> {
                unknownVariant(this)
            }
        }
    } finally {
        visiting.remove(this)
    }
}

private fun ScalarKind.presentationKind(): RepresentationKind = RepresentationTemplate.createScalar(kind = this).presentationKind()

private fun TypeTemplate.presentationApplications(
    definitions: Map<TypeDefinitionId, TypeDefinition>,
    bounds: Map<ParameterKey, List<TypeTemplate>>,
    visiting: MutableSet<TypeTemplate>,
): List<NamedTypeTemplate> {
    if (!visiting.add(this)) return emptyList()
    return try {
        when (this) {
            is TypeTemplate.ScalarWrapper -> {
                emptyList()
            }

            is TypeTemplate.NullableWrapper -> {
                value.value.presentationApplications(definitions, bounds, visiting)
            }

            is TypeTemplate.ParameterWrapper -> {
                bounds[value].orEmpty().flatMap { it.presentationApplications(definitions, bounds, visiting) }.distinct()
            }

            is TypeTemplate.NamedWrapper -> {
                val declaration = definitions[value.definition] ?: return listOf(value)
                val substitutions =
                    declaration.parameters
                        .map(TypeParameter::key)
                        .zip(value.arguments)
                        .toMap()
                listOf(value) +
                    declaration.parents.flatMap { parent ->
                        parent.substitute(substitutions).template.presentationApplications(definitions, bounds, visiting)
                    }
            }

            else -> {
                unknownVariant(this)
            }
        }
    } finally {
        visiting.remove(this)
    }
}

private fun TypeTemplate.presentationNested(
    slot: NestedPresentationSlot,
    definitions: Map<TypeDefinitionId, TypeDefinition>,
): PresentationNestedTemplate? {
    return when (slot) {
        NestedPresentationSlot.Payload, NestedPresentationSlot.Fields -> {
            PresentationNestedTemplate(this)
        }

        NestedPresentationSlot.Items -> {
            val (representation, arguments) = unwrapNullable().representation(definitions) ?: return null
            val sequence = representation as? RepresentationTemplate.SequenceWrapper ?: return null
            PresentationNestedTemplate(sequence.value.item.substitute(arguments), sequence.value.kind)
        }

        NestedPresentationSlot.Keys -> {
            val (representation, arguments) = unwrapNullable().representation(definitions) ?: return null
            val mapping = representation as? RepresentationTemplate.MappingWrapper ?: return null
            PresentationNestedTemplate(mapping.value.key.substitute(arguments))
        }

        NestedPresentationSlot.Values -> {
            if (this is TypeTemplate.NullableWrapper) {
                PresentationNestedTemplate(value.value)
            } else {
                val (representation, arguments) = representation(definitions) ?: return null
                val mapping = representation as? RepresentationTemplate.MappingWrapper ?: return null
                PresentationNestedTemplate(mapping.value.value.substitute(arguments))
            }
        }
    }
}
