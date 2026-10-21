package com.typewritermc.types.codegen.emit

import com.squareup.kotlinpoet.AnnotationSpec
import com.squareup.kotlinpoet.ClassName
import com.squareup.kotlinpoet.CodeBlock
import com.squareup.kotlinpoet.FileSpec
import com.squareup.kotlinpoet.KModifier
import com.squareup.kotlinpoet.MemberName
import com.squareup.kotlinpoet.ParameterizedTypeName.Companion.parameterizedBy
import com.squareup.kotlinpoet.PropertySpec
import com.squareup.kotlinpoet.TypeName
import com.squareup.kotlinpoet.TypeSpec
import com.squareup.kotlinpoet.asClassName
import com.typewritermc.codegen.DefinitionReferences
import com.typewritermc.codegen.GeneratedFile
import com.typewritermc.codegen.declarationCode
import com.typewritermc.codegen.kotlinCode
import com.typewritermc.codegen.namedArguments
import com.typewritermc.codegen.setCode
import com.typewritermc.types.EndpointCardinality
import com.typewritermc.types.EndpointDefinition
import com.typewritermc.types.EndpointSlot
import com.typewritermc.types.RelationContract
import com.typewritermc.types.RelationDeletePolicy
import com.typewritermc.types.RelationFamilyId
import com.typewritermc.types.RelationId
import com.typewritermc.types.RelationshipEndpoint
import com.typewritermc.types.TypewriterGeneratedEndpoint
import com.typewritermc.types.ksp.relationLinkDefinition
import com.typewritermc.types.ksp.relationLinkId
import skirout.editor.v1.type_catalog.EndpointId
import skirout.editor.v1.type_catalog.NamedTypeTemplate
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import com.typewritermc.codegen.TypewriterApi as Api

/** One endpoint of a reference contract, resolved for emission. */
internal class SdkEndpoint(
    val name: String,
    val slot: EndpointSlot,
    val resource: TypeName,
    val resourceTemplate: NamedTypeTemplate,
    val cardinality: EndpointCardinality,
    val onDelete: RelationDeletePolicy,
)

/** A reference contract resolved for emission: the relation object and its two generated endpoint interfaces. */
internal class SdkRelation(
    val name: ClassName,
    val id: String,
    val first: SdkEndpoint,
    val second: SdkEndpoint,
    val families: List<String>,
    val references: DefinitionReferences,
) {
    val endpoints: List<SdkEndpoint> get() = listOf(first, second)

    fun opposite(endpoint: SdkEndpoint): SdkEndpoint = if (endpoint === first) second else first

    /** The generated interface of [endpoint]; its nested `Definition` owns the endpoint's link definition. */
    fun endpointClass(endpoint: SdkEndpoint): ClassName = name.nestedClass(endpoint.name)

    fun linkDefinitionClass(endpoint: SdkEndpoint): ClassName = endpointClass(endpoint).nestedClass(LINK_DEFINITION)

    /** The link type a `Ref<Endpoint, Target>` field resolves to, named after its endpoint interface. */
    fun linkId(endpoint: SdkEndpoint): TypeDefinitionId = relationLinkId(endpointClass(endpoint).canonicalName)

    fun linkDefinition(endpoint: SdkEndpoint): TypeDefinition =
        relationLinkDefinition(endpointClass(endpoint).canonicalName, EndpointId(value = "$id:${endpoint.slot.name.lowercase()}"))

    companion object {
        /** Name of the object nested in each endpoint interface that owns its link definition. */
        const val LINK_DEFINITION = "Definition"
    }
}

/** The relation object of a reference contract with its endpoint interfaces and their link definitions. */
internal fun SdkRelation.file(): FileSpec {
    val relation =
        TypeSpec
            .objectBuilder(name)
            .addSuperinterface(Api.GeneratedRelationProvider)
            .addProperty(PropertySpec.builder("id", RelationId::class).initializer("%T(%S)", RelationId::class, id).build())
            .addTypes(endpoints.map(::endpointType))
            .addProperty(
                PropertySpec
                    .builder("contract", RelationContract::class, KModifier.OVERRIDE)
                    .initializer(
                        "%T%L",
                        RelationContract::class,
                        namedArguments(
                            "id" to CodeBlock.of("id"),
                            "first" to endpointDefinition(first),
                            "second" to endpointDefinition(second),
                            "families" to families.map { CodeBlock.of("%T(%S)", RelationFamilyId::class, it) }.setCode(),
                        ),
                    ).build(),
            ).build()
    return GeneratedFile.builder(name.packageName, name.simpleName).addType(relation).build()
}

private fun SdkRelation.endpointType(endpoint: SdkEndpoint): TypeSpec {
    val link = linkId(endpoint)
    return TypeSpec
        .interfaceBuilder(endpoint.name)
        .addAnnotation(
            AnnotationSpec
                .builder(TypewriterGeneratedEndpoint::class)
                .addMember("%S", id)
                .addMember("%T.%L", EndpointSlot::class, endpoint.slot.name)
                .addMember("%L", opposite(endpoint).cardinality == EndpointCardinality.Many)
                .build(),
        ).addSuperinterface(RelationshipEndpoint::class.asClassName().parameterizedBy(endpoint.resource, opposite(endpoint).resource))
        .addType(
            TypeSpec
                .objectBuilder(SdkRelation.LINK_DEFINITION)
                .addSuperinterface(Api.GeneratedTypeProvider)
                .addProperty(PropertySpec.builder("id", TypeDefinitionId::class).initializer(link.declarationCode()).build())
                .addProperty(
                    PropertySpec
                        .builder("definition", TypeDefinition::class, KModifier.OVERRIDE)
                        .initializer(context(references.inside(link)) { linkDefinition(endpoint).kotlinCode() })
                        .build(),
                ).build(),
        ).build()
}

private fun SdkRelation.endpointDefinition(endpoint: SdkEndpoint): CodeBlock =
    CodeBlock.of(
        "%T%L",
        EndpointDefinition::class,
        namedArguments(
            "id" to CodeBlock.of("id.%M(%T.%L)", ENDPOINT_ID, EndpointSlot::class, endpoint.slot.name),
            "slot" to CodeBlock.of("%T.%L", EndpointSlot::class, endpoint.slot.name),
            "resource" to context(references) { endpoint.resourceTemplate.kotlinCode() },
            "cardinality" to CodeBlock.of("%T.%L", EndpointCardinality::class, endpoint.cardinality.name),
            "onDelete" to CodeBlock.of("%T.%L", RelationDeletePolicy::class, endpoint.onDelete.name),
        ),
    )

private val ENDPOINT_ID = MemberName(RelationId::class.asClassName().packageName, "endpointId", isExtension = true)
