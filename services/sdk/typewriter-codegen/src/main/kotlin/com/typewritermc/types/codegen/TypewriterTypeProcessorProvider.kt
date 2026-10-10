package com.typewritermc.types.codegen

import com.google.devtools.ksp.getAllSuperTypes
import com.google.devtools.ksp.processing.CodeGenerator
import com.google.devtools.ksp.processing.Dependencies
import com.google.devtools.ksp.processing.KSPLogger
import com.google.devtools.ksp.processing.Resolver
import com.google.devtools.ksp.processing.SymbolProcessor
import com.google.devtools.ksp.processing.SymbolProcessorEnvironment
import com.google.devtools.ksp.processing.SymbolProcessorProvider
import com.google.devtools.ksp.symbol.ClassKind
import com.google.devtools.ksp.symbol.KSAnnotated
import com.google.devtools.ksp.symbol.KSAnnotation
import com.google.devtools.ksp.symbol.KSClassDeclaration
import com.google.devtools.ksp.symbol.KSDeclaration
import com.google.devtools.ksp.symbol.KSPropertyDeclaration
import com.google.devtools.ksp.symbol.KSType
import com.google.devtools.ksp.symbol.Modifier
import com.google.devtools.ksp.validate
import com.squareup.kotlinpoet.CodeBlock
import com.squareup.kotlinpoet.ksp.toTypeName
import com.typewritermc.capability.codegen.CapabilityProviderProcessor
import com.typewritermc.codegen.TypeParameterBindings
import com.typewritermc.codegen.appliedUseCode
import com.typewritermc.codegen.completeUseCode
import com.typewritermc.codegen.kotlinCode
import com.typewritermc.codegen.kotlinLiteral
import com.typewritermc.codegen.parameterKeys
import com.typewritermc.codegen.portableScalarKind
import com.typewritermc.configuration.FieldPatternSegment
import com.typewritermc.configuration.RelativeFieldPattern
import com.typewritermc.configuration.RepresentationKind
import com.typewritermc.discovery.codegen.RegistrarProviderProcessor
import com.typewritermc.presentation.codegen.CollectionProjectionProviderProcessor
import com.typewritermc.types.DeclaredTypeId
import com.typewritermc.types.EndpointBindingTemplate
import com.typewritermc.types.EndpointId
import com.typewritermc.types.FieldDeclaration
import com.typewritermc.types.ParameterKey
import com.typewritermc.types.RepresentationTemplate
import com.typewritermc.types.ScalarKind
import com.typewritermc.types.TypeDefinition
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.TypeId
import com.typewritermc.types.TypeParameter
import com.typewritermc.types.TypeTemplate
import com.typewritermc.types.TypeUse
import com.typewritermc.types.ksp.EndpointUsageValidator
import com.typewritermc.types.ksp.KspTypeConversionResult
import com.typewritermc.types.ksp.KspTypeGraphConverter
import com.typewritermc.types.ksp.OwnedFieldDeclaration

class TypewriterTypeProcessorProvider : SymbolProcessorProvider {
    override fun create(environment: SymbolProcessorEnvironment): SymbolProcessor =
        TypewriterTypeProcessor(environment.codeGenerator, environment.logger, environment.options)
}

private class TypewriterTypeProcessor(
    private val codeGenerator: CodeGenerator,
    private val logger: KSPLogger,
    private val options: Map<String, String>,
) : SymbolProcessor {
    private val generatedTypes = mutableSetOf<String>()
    private val processedTypeRoots = mutableSetOf<String>()
    private val generatedSupportTypes = mutableSetOf<TypeDefinitionId>()
    private val generatedRelations = mutableSetOf<String>()
    private val generatedEndpointBindingRoots = mutableSetOf<String>()
    private val generatedAdapters = mutableSetOf<String>()
    private val providerIndex = sortedSetOf<String>()
    private val endpointRequiresCollection = mutableMapOf<String, Boolean>()
    private val registeredResourceRoots = mutableSetOf<String>()
    private val explicitlyImportedTypes = mutableSetOf<String>()
    private val registrarProviders = RegistrarProviderProcessor(codeGenerator, logger)
    private val collectionProjectionProviders = CollectionProjectionProviderProcessor(codeGenerator, logger)
    private val capabilityProviders = CapabilityProviderProcessor(codeGenerator, logger, options[SOURCE_PART_OPTION].orEmpty())
    private val claimDependencyClosure = options[CLAIM_DEPENDENCY_CLOSURE_OPTION]?.toBooleanStrictOrNull() == true
    private var optionsValidated = false

    override fun process(resolver: Resolver): List<KSAnnotated> {
        if (!optionsValidated) {
            optionsValidated = true
            if (!validateOptions()) return emptyList()
        }
        val deferred = mutableListOf<KSAnnotated>()
        listOf(
            registrarProviders.process(resolver),
            collectionProjectionProviders.process(resolver),
            capabilityProviders.process(resolver),
        ).forEach { result ->
            deferred += result.deferred
            result.providers.forEach { contribution -> index(contribution.kind, contribution.providerClass) }
        }
        resolver
            .getSymbolsWithAnnotation(TYPEWRITER_TYPE_IMPORTS_ANNOTATION)
            .filterIsInstance<KSClassDeclaration>()
            .forEach { carrier ->
                if (!carrier.validate()) {
                    deferred += carrier
                    return@forEach
                }
                val imported = carrier.annotation(TYPEWRITER_TYPE_IMPORTS_ANNOTATION)?.argument("types") as? List<*> ?: emptyList<Any>()
                imported
                    .filterIsInstance<KSType>()
                    .mapNotNull { type -> type.declaration as? KSClassDeclaration }
                    .forEach { declaration ->
                        declaration.qualifiedName?.asString()?.let(explicitlyImportedTypes::add)
                        generateType(declaration)
                    }
            }
        val resourceProperties =
            resolver
                .getSymbolsWithAnnotation(RESOURCE_DEFINITION_ANNOTATION)
                .filterIsInstance<KSPropertyDeclaration>()
                .toList()
        resourceProperties.filterNot(KSAnnotated::validate).forEach(deferred::add)
        val resourceRoots = resourceProperties.mapNotNull(KSPropertyDeclaration::resourceRoot)
        registeredResourceRoots += resourceRoots.mapNotNull { it.qualifiedName?.asString() }
        resolver
            .getSymbolsWithAnnotation(REFERENCE_CONTRACT_ANNOTATION)
            .filterIsInstance<KSClassDeclaration>()
            .forEach { relation ->
                if (relation.validate()) generateRelation(relation) else deferred += relation
            }
        val directlyAnnotated =
            resolver.getSymbolsWithAnnotation(TYPEWRITER_TYPE_ANNOTATION).filterIsInstance<KSClassDeclaration>().toList()
        val nestedAnnotated =
            directlyAnnotated
                .asSequence()
                .flatMap { declaration ->
                    classes(declaration.declarations) + declaration.getSealedSubclasses()
                }.filter { declaration -> declaration.annotation(TYPEWRITER_TYPE_ANNOTATION) != null }
        val declarations =
            (directlyAnnotated.asSequence() + nestedAnnotated + resourceRoots.asSequence())
                .distinctBy { it.qualifiedName?.asString() }
                .toList()
        val readyDeclarations = declarations.filter(KSClassDeclaration::isTypeGraphReady)
        declarations.filterNot(KSClassDeclaration::isTypeGraphReady).forEach(deferred::add)
        readyDeclarations
            .sortedBy { it.qualifiedName?.asString() }
            .forEach(::generateType)
        resourceProperties.filter(KSAnnotated::validate).forEach { property ->
            val root = property.resourceRoot() ?: return@forEach
            if (root.validate()) generateResourceRegistration(property, root) else deferred += property
        }

        resolver.getAllFiles().forEach { file ->
            classes(file.declarations).filter { it.classKind == ClassKind.OBJECT }.forEach { declaration ->
                val unresolved = declaration.superTypes.any { it.resolve().isError }
                if (unresolved) {
                    if (declaration.origin.name == "KOTLIN") deferred += declaration
                    return@forEach
                }
                generateAdapters(declaration)
            }
        }
        return deferred.distinct()
    }

    private fun generateResourceRegistration(
        property: KSPropertyDeclaration,
        root: KSClassDeclaration,
    ) {
        val annotation = property.annotation(RESOURCE_DEFINITION_ANNOTATION) ?: return
        val id = annotation.argument("id") as? String
        val navigation = annotation.argument("navigationHandler") as? String ?: "generic"
        if (id.isNullOrBlank()) {
            logger.error("Resource definitions require a stable id.", property)
            return
        }
        if (!root.isResourceDeclaration()) {
            logger.error("Resource definition roots must implement Resource.", property)
            return
        }
        val owner = property.qualifiedName?.asString() ?: return
        val objectName = owner.replace('.', '_').replace('$', '_') + "ResourceRegistration"
        if (!generatedAdapters.add("resource:$owner")) return
        val packageName = property.packageName.asString()
        val source =
            """
package $packageName

object $objectName : com.typewritermc.discovery.GeneratedResourceProvider {
    override val definition: com.typewritermc.authoring.AuthoringResourceDefinition =
        com.typewritermc.authoring.AuthoringResourceDefinition(
            id = com.typewritermc.authoring.ResourceDefinitionId(${id.kotlinLiteral()}),
            root = ${root.typeDefinitionIdentity().kotlinCode()},
            navigationHandler = ${navigation.kotlinLiteral()},
        )
}
""".trimStart()
        codeGenerator
            .createNewFile(
                Dependencies(false, *listOfNotNull(property.containingFile).toTypedArray()),
                packageName,
                objectName,
            ).bufferedWriter()
            .use { it.write(source) }
        index("resource", "$packageName.$objectName")
    }

    private fun generateRelation(declaration: KSClassDeclaration) {
        val qualified = declaration.qualifiedName?.asString() ?: return
        if (!generatedRelations.add(qualified)) return
        val id = declaration.annotation(REFERENCE_CONTRACT_ANNOTATION)?.argument("id") as? String
        if (id.isNullOrBlank()) {
            logger.error("Reference contracts require a stable id.", declaration)
            return
        }
        val endpoints =
            declaration.declarations
                .filterIsInstance<KSClassDeclaration>()
                .mapNotNull { endpoint ->
                    val marker =
                        endpoint.superTypes.map { it.resolve() }.firstOrNull { type ->
                            type.declaration.qualifiedName?.asString() in setOf(ONE_ENDPOINT, MANY_ENDPOINT)
                        } ?: return@mapNotNull null
                    val resource =
                        marker.arguments
                            .singleOrNull()
                            ?.type
                            ?.resolve()
                    val resourceDeclaration = resource?.declaration as? KSClassDeclaration
                    if (resourceDeclaration == null ||
                        (
                            resourceDeclaration.qualifiedName?.asString() != RESOURCE_TYPE &&
                                resourceDeclaration.getAllSuperTypes().none {
                                    it.declaration.qualifiedName?.asString() == RESOURCE_TYPE
                                }
                        )
                    ) {
                        logger.error("Relation endpoints must name a registered resource declaration.", endpoint)
                        return@mapNotNull null
                    }
                    val resourceNames =
                        (
                            sequenceOf(resourceDeclaration) +
                                resourceDeclaration.getAllSuperTypes().mapNotNull { it.declaration as? KSClassDeclaration }
                        ).mapNotNull { it.qualifiedName?.asString() }
                            .toSet()
                    val abstract =
                        resourceDeclaration.classKind == ClassKind.INTERFACE || Modifier.ABSTRACT in resourceDeclaration.modifiers
                    if (!abstract && resourceNames.none { it in registeredResourceRoots }) {
                        logger.error("Concrete relation endpoints must belong to a registered resource root.", endpoint)
                        return@mapNotNull null
                    }
                    RelationEndpointSource(
                        name = endpoint.simpleName.asString(),
                        resource = resourceDeclaration,
                        resourceType = resource,
                        cardinality = if (marker.declaration.qualifiedName?.asString() == ONE_ENDPOINT) "One" else "Many",
                        deletion =
                            endpoint
                                .annotation(DELETION_POLICY_ANNOTATION)
                                ?.argument("onDelete")
                                ?.toString()
                                ?.substringAfterLast('.') ?: "CLEAR",
                    )
                }.toList()
        if (endpoints.size != 2) {
            logger.error("Reference contracts require exactly two One or Many endpoint declarations.", declaration)
            return
        }
        val generatedName = declaration.simpleName.asString().removeSuffix("Contract")
        val families =
            (sequenceOf(declaration) + declaration.getAllSuperTypes().mapNotNull { it.declaration as? KSClassDeclaration })
                .mapNotNull { it.annotation(RELATION_FAMILY_ANNOTATION)?.argument("id") as? String }
                .distinct()
                .sorted()
                .toList()
        val first = endpoints[0]
        val second = endpoints[1]
        val firstResource = first.resourceType.sourceType()
        val secondResource = second.resourceType.sourceType()
        endpointRequiresCollection["$id:first"] = second.cardinality == "Many"
        endpointRequiresCollection["$id:second"] = first.cardinality == "Many"
        val packageName = declaration.packageName.asString()
        val source =
            """
package $packageName

import com.typewritermc.types.endpointId

object $generatedName : com.typewritermc.discovery.GeneratedRelationProvider {
    val id: com.typewritermc.types.RelationId = com.typewritermc.types.RelationId("$id")
    @com.typewritermc.types.TypewriterGeneratedEndpoint(
        "$id",
        com.typewritermc.types.EndpointSlot.First,
        ${second.cardinality == "Many"},
    )
    interface ${first.name} : com.typewritermc.types.RelationshipEndpoint<$firstResource, $secondResource>
    @com.typewritermc.types.TypewriterGeneratedEndpoint(
        "$id",
        com.typewritermc.types.EndpointSlot.Second,
        ${first.cardinality == "Many"},
    )
    interface ${second.name} : com.typewritermc.types.RelationshipEndpoint<$secondResource, $firstResource>
    override val contract: com.typewritermc.types.RelationContract = com.typewritermc.types.RelationContract(
        id = id,
        first = com.typewritermc.types.EndpointDefinition(
            id = id.endpointId(com.typewritermc.types.EndpointSlot.First),
            slot = com.typewritermc.types.EndpointSlot.First,
            resource = ${first.resourceType.endpointResourceTemplate().kotlinCode()},
            cardinality = com.typewritermc.types.EndpointCardinality.${first.cardinality},
            onDelete = com.typewritermc.types.RelationDeletePolicy.${first.deletion},
        ),
        second = com.typewritermc.types.EndpointDefinition(
            id = id.endpointId(com.typewritermc.types.EndpointSlot.Second),
            slot = com.typewritermc.types.EndpointSlot.Second,
            resource = ${second.resourceType.endpointResourceTemplate().kotlinCode()},
            cardinality = com.typewritermc.types.EndpointCardinality.${second.cardinality},
            onDelete = com.typewritermc.types.RelationDeletePolicy.${second.deletion},
        ),
        families = setOf(${families.joinToString { "com.typewritermc.types.RelationFamilyId(\"$it\")" }}),
    )
}
""".trimStart()
        codeGenerator
            .createNewFile(
                Dependencies(false, *listOfNotNull(declaration.containingFile).toTypedArray()),
                packageName,
                generatedName,
            ).bufferedWriter()
            .use { it.write(source) }
        index("relation", "$packageName.$generatedName")
        emitSupportType(linkDefinition("$packageName.$generatedName.${first.name}", EndpointId("$id:first")))
        emitSupportType(linkDefinition("$packageName.$generatedName.${second.name}", EndpointId("$id:second")))
    }

    override fun finish() {
        if (providerIndex.isEmpty()) return
        codeGenerator
            .createNewFileByPath(
                Dependencies.ALL_FILES,
                PROVIDER_INDEX,
                "",
            ).bufferedWriter()
            .use { writer -> providerIndex.forEach(writer::appendLine) }
    }

    private fun generateType(declaration: KSClassDeclaration) {
        val qualified = declaration.qualifiedName?.asString()
        if (qualified == null) return
        if (!processedTypeRoots.add(qualified)) return
        if (Modifier.PRIVATE in declaration.modifiers) {
            logger.error("Typewriter types must be visible qualified declarations.", declaration)
            return
        }
        val conversion = KspTypeGraphConverter().convertDeclaration(declaration)
        if (conversion is KspTypeConversionResult.Failure) {
            conversion.diagnostics.forEach { logger.error(it.toString(), declaration) }
            return
        }
        conversion as KspTypeConversionResult.Success
        if (declaration.isResourceDeclaration()) {
            val diagnostics = EndpointUsageValidator().validate(declaration)
            diagnostics.forEach { diagnostic -> logger.error(diagnostic.message, diagnostic.symbol) }
            if (diagnostics.isNotEmpty()) return
        }
        val definitions = conversion.definitions.associateBy(TypeDefinition::id)
        conversion.declarations.forEach { (definition, sourceDeclaration) ->
            val sourceQualified = sourceDeclaration.qualifiedName?.asString()
            if (
                sourceDeclaration.origin.name != "KOTLIN" &&
                !claimDependencyClosure &&
                sourceQualified !in explicitlyImportedTypes
            ) {
                return@forEach
            }
            emitSdk(sourceDeclaration, definitions.getValue(definition), conversion.ownedFields[definition].orEmpty())
        }
        if (claimDependencyClosure) {
            conversion.declarations.values
                .asSequence()
                .flatMap(KSClassDeclaration::getSealedSubclasses)
                .filter { subclass -> subclass.annotation(TYPEWRITER_TYPE_ANNOTATION) != null }
                .forEach(::generateType)
        }
        if (declaration.isResourceDeclaration() && generatedEndpointBindingRoots.add(qualified)) {
            emitEndpointBindings(declaration, definitions)
        }
    }

    private fun emitSdk(
        declaration: KSClassDeclaration,
        typeDefinition: TypeDefinition,
        fields: List<OwnedFieldDeclaration>,
    ) {
        val qualified = declaration.qualifiedName?.asString() ?: return
        if (!generatedTypes.add(qualified)) return
        val properties =
            declaration.declarations
                .filterIsInstance<KSPropertyDeclaration>()
                .associateBy { property -> property.simpleName.asString() }
        val source = sdkSource(declaration, typeDefinition, fields, properties)
        val name = declaration.generatedTypeName()
        val fileName = "${name}TypewriterSdk"
        codeGenerator
            .createNewFile(
                Dependencies(false, *listOfNotNull(declaration.containingFile).toTypedArray()),
                declaration.packageName.asString(),
                fileName,
            ).bufferedWriter()
            .use { it.write(source) }
        index("type", "${declaration.packageName.asString()}.${name}Definition")
        if (declaration.supportsNativeBinding()) {
            index(
                "nativeBinding",
                "${declaration.packageName.asString()}.${name}NativeBindingFactory",
            )
        }
    }

    private fun emitSupportType(definition: TypeDefinition) {
        if (!generatedSupportTypes.add(definition.id)) return
        val identity =
            java.security.MessageDigest
                .getInstance("SHA-256")
                .digest(definition.id.toString().toByteArray())
                .joinToString("") { "%02x".format(it) }
        val packageName = "com.typewritermc.generated.types"
        val objectName = "GeneratedSupportType_$identity"
        val source =
            """
package $packageName

object $objectName : com.typewritermc.discovery.GeneratedTypeProvider {
    override val definition: com.typewritermc.types.TypeDefinition = ${definition.kotlinCode()}
}
""".trimStart()
        codeGenerator
            .createNewFile(Dependencies.ALL_FILES, packageName, objectName)
            .bufferedWriter()
            .use { it.write(source) }
        index("type", "$packageName.$objectName")
    }

    private fun emitEndpointBindings(
        declaration: KSClassDeclaration,
        definitions: Map<TypeDefinitionId, TypeDefinition>,
    ) {
        val root = definitions[declaration.typeDefinitionIdentity()] ?: return
        val rootTemplate =
            TypeTemplate.Named(
                root.id,
                root.parameters.map { TypeTemplate.Parameter(it.key) },
            )
        val bindings = discoverEndpointBindings(rootTemplate, definitions)
        if (bindings.isEmpty()) return
        val invalid =
            bindings.filter { binding ->
                val required = endpointRequiresCollection[binding.endpoint.value] ?: return@filter false
                required != binding.containsCollection
            }
        invalid.forEach { binding ->
            val requirement = if (endpointRequiresCollection.getValue(binding.endpoint.value)) "requires" else "forbids"
            logger.error(
                "Relation endpoint ${binding.endpoint.value} $requirement a collection on its containing field path.",
                declaration,
            )
        }
        if (invalid.isNotEmpty()) return
        val packageName = declaration.packageName.asString()
        val objectName = "${declaration.generatedTypeName()}EndpointBindings"
        val source =
            """
package $packageName

object $objectName : com.typewritermc.discovery.GeneratedEndpointBindingsProvider {
    override val bindings: kotlin.collections.List<com.typewritermc.types.EndpointBindingTemplate> =
        listOf(${bindings.joinToString { it.code() }})
}
""".trimStart()
        codeGenerator
            .createNewFile(
                Dependencies(false, *listOfNotNull(declaration.containingFile).toTypedArray()),
                packageName,
                objectName,
            ).bufferedWriter()
            .use { it.write(source) }
        index("endpointBindings", "$packageName.$objectName")
    }

    private fun sdkSource(
        declaration: KSClassDeclaration,
        typeDefinition: TypeDefinition,
        fields: List<OwnedFieldDeclaration>,
        properties: Map<String, KSPropertyDeclaration>,
    ): String {
        val definitionId = typeDefinition.id
        val packageName = declaration.packageName.asString()
        val name = declaration.generatedTypeName()
        val display = declaration.typeDisplayCode()
        val qualifiedNativeName = declaration.qualifiedName?.asString().orEmpty()
        val nativeAlias =
            if (declaration.parentDeclaration is KSClassDeclaration) {
                "typealias $name = $qualifiedNativeName\n"
            } else {
                ""
            }
        val typeParameters = declaration.typeParameters.map { it.name.asString() }
        val sourceArguments =
            typeParameters.joinToString(
                prefix = if (typeParameters.isEmpty()) "" else "<",
                postfix = if (typeParameters.isEmpty()) "" else ">",
            )
        val sourceWhere =
            declaration.typeParameters
                .flatMap { parameter ->
                    parameter.bounds
                        .map { it.resolve() }
                        .filter { it.declaration.qualifiedName?.asString() != "kotlin.Any" }
                        .map { bound -> "${parameter.name.asString()} : ${bound.sourceType()}" }
                }.joinToString(prefix = " where ")
                .takeIf { it != " where " }
                .orEmpty()
        val sourceClassWhere =
            sourceWhere
                .takeIf(String::isNotEmpty)
                ?.trim()
                ?.let { "\n    $it" }
                .orEmpty()
        val appliedTypeArguments =
            typeParameters.joinToString(
                prefix = if (typeParameters.isEmpty()) "" else "<",
                postfix = if (typeParameters.isEmpty()) "" else ">",
            )
        val expressionFunctionArguments =
            listOfNotNull(
                sourceArguments.removeSurrounding("<", ">").takeIf { it.isNotEmpty() },
                "M : com.typewritermc.expression.MissingPolicy",
            ).joinToString(prefix = "<", postfix = ">")
        val starArguments =
            typeParameters.joinToString(
                prefix = if (typeParameters.isEmpty()) "" else "<",
                postfix = if (typeParameters.isEmpty()) "" else ">",
            ) {
                "*"
            }
        val draftParameters =
            typeParameters.indices.joinToString(
                prefix = if (typeParameters.isEmpty()) "" else "<",
                postfix = if (typeParameters.isEmpty()) "" else ">",
            ) {
                "D$it"
            }
        val exactDraftParameters =
            (
                sourceArguments
                    .removeSurrounding("<", ">")
                    .takeIf(String::isNotEmpty)
                    ?.let(::listOf)
                    .orEmpty() +
                    typeParameters.indices.map { "D$it" }
            ).joinToString(prefix = "<", postfix = ">")
        val exactDraftArguments =
            (typeParameters + typeParameters.indices.map { "D$it" })
                .joinToString(prefix = "<", postfix = ">")
        val ownerType = "$name$starArguments"
        val definition = definitionId.kotlinCode()
        val rootTemplate =
            TypeTemplate
                .Named(
                    definitionId,
                    typeDefinition.parameters.map { TypeTemplate.Parameter(it.key) },
                ).kotlinCode()
        val rootConfigurationExpected =
            when (val representation = typeDefinition.representation) {
                is RepresentationTemplate.Scalar -> TypeTemplate.Scalar(representation.kind).kotlinCode()
                else -> rootTemplate
            }
        val resource = declaration.getAllSuperTypes().any { it.declaration.qualifiedName?.asString() == RESOURCE_TYPE }
        val rootConfigurationScope =
            when (val representation = typeDefinition.representation) {
                is RepresentationTemplate.Scalar -> {
                    declaration.nominalScalarConfigurationScope(representation.kind)
                }

                is RepresentationTemplate.Enumeration -> {
                    "com.typewritermc.configuration.EnumField<$ownerType>"
                }

                else -> {
                    "com.typewritermc.configuration.RecordField<$ownerType, " +
                        "${name}Expressions$starArguments>"
                }
            }
        val rootConfigurationClass =
            when (val representation = typeDefinition.representation) {
                is RepresentationTemplate.Scalar -> declaration.nominalScalarConfigurationScopeClass(representation.kind)
                is RepresentationTemplate.Enumeration -> "com.typewritermc.configuration.EnumField"
                else -> "com.typewritermc.configuration.RecordField"
            }
        val rootRepresentationKind =
            when (val representation = typeDefinition.representation) {
                is RepresentationTemplate.Scalar -> {
                    representationKind(TypeTemplate.Scalar(representation.kind))
                }

                is RepresentationTemplate.Enumeration -> {
                    RepresentationKind.Enum
                }

                is RepresentationTemplate.Sequence -> {
                    if (representation.kind ==
                        com.typewritermc.types.CollectionKind.List
                    ) {
                        RepresentationKind.List
                    } else {
                        RepresentationKind.Set
                    }
                }

                is RepresentationTemplate.Mapping -> {
                    RepresentationKind.Map
                }

                is RepresentationTemplate.Link -> {
                    RepresentationKind.Link
                }

                is RepresentationTemplate.Record -> {
                    RepresentationKind.Record
                }
            }
        val exposedFields = if (typeDefinition.representation is RepresentationTemplate.Record) fields else emptyList()
        val configurationFields =
            exposedFields.joinToString("\n") { field ->
                val property = properties[field.sourceName]
                val scope = configurationScope(field.template, property?.type?.resolve())
                "    fun ${field.sourceName}(configure: com.typewritermc.configuration.Configuration<$scope>)"
            }
        val expressionFields =
            exposedFields.joinToString("\n") { field ->
                val property = properties[field.sourceName]
                val valueType = property?.type?.resolve()?.sourceType(property.type.explicitNullable) ?: "kotlin.Any?"
                "    val ${field.sourceName}: com.typewritermc.expression.Expr<$valueType, com.typewritermc.expression.MayBeMissing>"
            }
        val expressionReceiverName =
            generateSequence("receiverExpression") { "_$it" }
                .first { candidate -> exposedFields.none { it.sourceName == candidate } }
        val expressionImplementation =
            exposedFields.joinToString("\n") { field ->
                val property = properties[field.sourceName]
                val valueType = property?.type?.resolve()?.sourceType(property.type.explicitNullable) ?: "kotlin.Any?"
                "    override val ${field.sourceName}: " +
                    "com.typewritermc.expression.Expr<$valueType, com.typewritermc.expression.MayBeMissing> " +
                    "get() = $expressionReceiverName.field(\"${field.name}\")"
            }
        val nothingArguments =
            typeParameters.joinToString(
                prefix = if (typeParameters.isEmpty()) "" else "<",
                postfix = if (typeParameters.isEmpty()) "" else ">",
            ) { "kotlin.Nothing" }
        val rootExpressionFactory =
            when (val representation = typeDefinition.representation) {
                is RepresentationTemplate.Scalar -> {
                    if (declaration.qualifiedName?.asString() == COLOR_TYPE) {
                        "com.typewritermc.configuration.ColorExpressionsFactory"
                    } else {
                        expressionScopeClass(TypeTemplate.Scalar(representation.kind), declaration.valueClassRepresentationType()) +
                            "Factory"
                    }
                }

                is RepresentationTemplate.Enumeration -> {
                    "com.typewritermc.configuration.EnumExpressionsFactory"
                }

                else -> {
                    "${name}ExpressionsFactory"
                }
            }
        val configurationImplementation =
            exposedFields.joinToString("\n") { field ->
                val property = properties[field.sourceName]
                val scope = configurationScope(field.template, property?.type?.resolve())
                val kind = representationKind(field.template, property?.type?.resolve())
                val pattern = fieldPattern(field.name)
                val expected = configurationExpectedTemplate(field.template, property?.type?.resolve()).kotlinCode()
                val scopeClass = configurationScopeClass(field.template, property?.type?.resolve())
                val nested = configurationNestedScopes(field.template, property?.type?.resolve())
                val expressions = expressionScopeClass(field.template, property?.type?.resolve())
                val fieldType = property?.type?.resolve()
                if (field.template is TypeTemplate.Named && fieldType != null && fieldType.hasGeneratedConfigurationImplementation()) {
                    "    override fun ${field.sourceName}(configure: com.typewritermc.configuration.Configuration<$scope>) { " +
                        "${fieldType.generatedConfigurationScopeImplementation()}(collection.nested($pattern)).configure() }"
                } else {
                    "    @Suppress(\"UNCHECKED_CAST\") override fun ${field.sourceName}(" +
                        "configure: com.typewritermc.configuration.Configuration<$scope>) { " +
                        "collection.field($pattern, com.typewritermc.configuration.RepresentationKind.$kind, " +
                        "$expected, $scopeClass::class as kotlin.reflect.KClass<$scope>, $nested, " +
                        "${expressions}Factory).configure() }"
                }
            }
        val presentationFields =
            exposedFields.joinToString("\n") { field ->
                val property = properties[field.sourceName]
                val valueType = property?.type?.resolve()?.sourceType(property.type.explicitNullable) ?: "kotlin.Any?"
                "    val ${field.sourceName}: com.typewritermc.presentation.PresentedField<$valueType, ${presentationScope(
                    field.template,
                    property?.type?.resolve(),
                )}>"
            }
        val presentationImplementation =
            exposedFields.joinToString("\n") { field ->
                val scope = presentationScope(field.template, properties[field.sourceName]?.type?.resolve())
                val scopeClass = presentationScopeClass(field.template, properties[field.sourceName]?.type?.resolve())
                val nested = presentationNestedScopes(field.template, properties[field.sourceName]?.type?.resolve())
                val property = properties[field.sourceName]
                val valueType = property?.type?.resolve()?.sourceType(property.type.explicitNullable) ?: "kotlin.Any?"
                "    @Suppress(\"UNCHECKED_CAST\") override val ${field.sourceName}: " +
                    "com.typewritermc.presentation.PresentedField<$valueType, $scope> get() = " +
                    "build.field(\"${field.name}\", $scopeClass::class as kotlin.reflect.KClass<$scope>, $nested)"
            }
        val rootPresentation =
            declaration.classKind == ClassKind.INTERFACE ||
                Modifier.ABSTRACT in declaration.modifiers ||
                typeDefinition.representation !is RepresentationTemplate.Record
        val rootPresentationScope = presentationScope(TypeTemplate.Named(definitionId), declaration.asStarProjectedType())
        val rootPresentationScopeClass = presentationScopeClass(TypeTemplate.Named(definitionId), declaration.asStarProjectedType())
        val rootPresentationNested = presentationNestedScopes(TypeTemplate.Named(definitionId), declaration.asStarProjectedType())
        val presentationValue =
            if (rootPresentation) {
                "    val value: com.typewritermc.presentation.PresentedField<$qualifiedNativeName$sourceArguments, " +
                    "$rootPresentationScope>\n"
            } else {
                ""
            }
        val presentationValueImplementation =
            if (rootPresentation) {
                "    @Suppress(\"UNCHECKED_CAST\") override val value: " +
                    "com.typewritermc.presentation.PresentedField<$qualifiedNativeName$sourceArguments, " +
                    "$rootPresentationScope> get() = " +
                    "build.value($rootPresentationScopeClass::class as kotlin.reflect.KClass<$rootPresentationScope>, " +
                    "$rootPresentationNested)\n"
            } else {
                ""
            }
        val draftArguments =
            typeParameters.indices.joinToString {
                "private val argument$it: com.typewritermc.authoring.ReadProjection<D$it>"
            }
        val draftProjectionArguments = typeParameters.indices.joinToString { "argument$it" }
        val draftApplicationArguments = typeParameters.indices.joinToString { "argument$it.expected" }
        val draftFields =
            exposedFields.joinToString("\n") { field ->
                val property = properties[field.sourceName]
                val result =
                    property?.type?.let { draftType(it.resolve(), declaration, it.explicitNullable) }
                        ?: "com.typewritermc.authoring.PortableValue"
                val projection =
                    draftProjectionCode(
                        field.template,
                        property?.type?.resolve(),
                        definitionId,
                        declaration,
                        typeParameters,
                    )
                "    context(reads: com.typewritermc.authoring.AuthoredReads)\n" +
                    "    val ${field.sourceName}: com.typewritermc.authoring.Availability<$result> get() = " +
                    "binding.read(${fieldPath(field.name)}, $projection)"
            }
        val independentDraftEdits =
            exposedFields
                .filterNot { it.template.containsParameter() }
                .joinToString("\n") { field ->
                    draftEditMethods(field, properties[field.sourceName], definitionId, typeParameters)
                }
        val dependentDraftEdits =
            exposedFields
                .filter { it.template.containsParameter() }
                .joinToString("\n") { field ->
                    draftEditMethods(field, properties[field.sourceName], definitionId, typeParameters)
                }
        val actualType =
            "when (val selected = binding.actual) { " +
                "is com.typewritermc.authoring.TypeSelection.Complete -> " +
                "com.typewritermc.authoring.Availability.Available(selected.use); " +
                "is com.typewritermc.authoring.TypeSelection.Pending -> " +
                "com.typewritermc.authoring.Availability.Unavailable(listOf(binding.location)) }"
        val nativeFactory = nativeFactorySource(declaration, typeDefinition, fields, properties)
        val draftProjection = draftProjectionDeclaration(name, typeDefinition, draftParameters, draftProjectionArguments)
        return """
package $packageName

import com.typewritermc.authoring.append
import com.typewritermc.authoring.exactEditablePath
import com.typewritermc.authoring.read
import com.typewritermc.authoring.requireOpaqueCompatibility
import com.typewritermc.types.encodeGeneratedDefault
import com.typewritermc.expression.field

$nativeAlias

object ${name}Fields {
${exposedFields.joinToString("\n") { field ->
            if (field.template.containsParameter()) {
                "    val ${field.sourceName} = com.typewritermc.authoring.GenericField<$ownerType>($definition, ${fieldPath(
                    field.name,
                )}, ${field.template.kotlinCode()})"
            } else {
                val property = properties[field.sourceName]
                val valueType =
                    property?.type?.let { it.resolve().sourceType(it.explicitNullable) } ?: "com.typewritermc.authoring.PortableValue"
                "    val ${field.sourceName} = com.typewritermc.authoring.typedPath<$ownerType, $valueType>($definition, ${fieldPath(
                    field.name,
                )}, ${field.template.completeUseCode()})"
            }
        }}
}

interface ${name}Expressions$sourceArguments$sourceWhere {
$expressionFields
}

internal class ${name}ExpressionsImpl$sourceArguments(
    private val $expressionReceiverName: com.typewritermc.expression.Expr<*, out com.typewritermc.expression.MissingPolicy>,
) : ${name}Expressions$appliedTypeArguments$sourceClassWhere {
$expressionImplementation
}

object ${name}ExpressionsFactory : com.typewritermc.expression.ExpressionFactory<${name}Expressions$starArguments> {
    @Suppress("UNCHECKED_CAST")
    override val scope = ${name}Expressions::class as kotlin.reflect.KClass<${name}Expressions$starArguments>

    override fun create(value: com.typewritermc.expression.Expr<*, out com.typewritermc.expression.MissingPolicy>): ${name}Expressions$starArguments =
        ${name}ExpressionsImpl$nothingArguments(value)
}

@kotlin.jvm.JvmName("${name}ExpressionAny")
@Suppress("UNCHECKED_CAST")
fun $expressionFunctionArguments com.typewritermc.expression.Expr<kotlin.collections.List<$name$appliedTypeArguments>, M>.any(
    predicate: ${name}Expressions$appliedTypeArguments.() -> com.typewritermc.expression.Expr<kotlin.Boolean, out com.typewritermc.expression.MissingPolicy>,
): com.typewritermc.expression.Expr<kotlin.Boolean, com.typewritermc.expression.MayBeMissing>$sourceWhere =
    com.typewritermc.expression.collectionAny(
        this,
        ${name}ExpressionsFactory as com.typewritermc.expression.ExpressionFactory<${name}Expressions$appliedTypeArguments>,
        predicate,
    )

@kotlin.jvm.JvmName("${name}ExpressionFilter")
@Suppress("UNCHECKED_CAST")
fun $expressionFunctionArguments com.typewritermc.expression.Expr<kotlin.collections.List<$name$appliedTypeArguments>, M>.filter(
    predicate: ${name}Expressions$appliedTypeArguments.() -> com.typewritermc.expression.Expr<kotlin.Boolean, out com.typewritermc.expression.MissingPolicy>,
): com.typewritermc.expression.Expr<kotlin.collections.List<$name$appliedTypeArguments>, com.typewritermc.expression.MayBeMissing>$sourceWhere =
    com.typewritermc.expression.collectionFilter(
        this,
        ${name}ExpressionsFactory as com.typewritermc.expression.ExpressionFactory<${name}Expressions$appliedTypeArguments>,
        predicate,
    )

interface ${name}Configuration$sourceArguments$sourceWhere {
    fun ${name}ConfigurationScope$appliedTypeArguments.configure()
}

interface ${name}ConfigurationScope$sourceArguments : com.typewritermc.configuration.TypeConfigurationScope, $rootConfigurationScope$sourceWhere {
$configurationFields
}

@Suppress("UNCHECKED_CAST")
class ${name}ConfigurationScopeImpl$sourceArguments(
    private val collection: com.typewritermc.configuration.ConfigurationCollectionScope,
) : ${name}ConfigurationScope$appliedTypeArguments,
    $rootConfigurationScope by (
        collection.field(
            com.typewritermc.configuration.RelativeFieldPattern(),
            com.typewritermc.configuration.RepresentationKind.$rootRepresentationKind,
            $rootConfigurationExpected,
            $rootConfigurationClass::class as kotlin.reflect.KClass<$rootConfigurationScope>,
            emptyMap(),
            $rootExpressionFactory,
        )
    )$sourceClassWhere {
    override fun initialization(preference: com.typewritermc.configuration.InitializationPreference) =
        collection.initialization(preference)
$configurationImplementation
}

interface ${name}Presentation$sourceArguments : com.typewritermc.presentation.PresentationReference$sourceWhere {
    val roles: Set<com.typewritermc.types.PresentationRole> get() = setOf(com.typewritermc.types.PresentationRole.INSPECTOR)
    val priority: Int get() = 0
    fun ${name}PresentationScope$appliedTypeArguments.present()
}

interface ${name}PresentationScope$sourceArguments : com.typewritermc.presentation.Layout$sourceWhere {
    val expressions: ${name}Expressions$appliedTypeArguments
$presentationValue$presentationFields
    fun showIf(
        condition: ${name}Expressions$appliedTypeArguments.() -> com.typewritermc.expression.Expr<kotlin.Boolean, com.typewritermc.expression.Handled>,
        whenFalse: (${name}PresentationScope$appliedTypeArguments.() -> kotlin.Unit)? = null,
        body: ${name}PresentationScope$appliedTypeArguments.() -> kotlin.Unit,
    )
}

class ${name}PresentationScopeImpl$sourceArguments(
    private val build: com.typewritermc.presentation.PresentationBuildScope,
) : ${name}PresentationScope$appliedTypeArguments, com.typewritermc.presentation.Layout by build$sourceClassWhere {
    init {
        build.registerExpressions(${name}ExpressionsFactory)
    }

    @Suppress("UNCHECKED_CAST") override val expressions: ${name}Expressions$appliedTypeArguments
        get() = build.expressions(${name}Expressions::class as kotlin.reflect.KClass<${name}Expressions$appliedTypeArguments>)
$presentationValueImplementation$presentationImplementation
    @Suppress("UNCHECKED_CAST")
    override fun showIf(
        condition: ${name}Expressions$appliedTypeArguments.() -> com.typewritermc.expression.Expr<kotlin.Boolean, com.typewritermc.expression.Handled>,
        whenFalse: (${name}PresentationScope$appliedTypeArguments.() -> kotlin.Unit)?,
        body: ${name}PresentationScope$appliedTypeArguments.() -> kotlin.Unit,
    ) {
        val expressions = build.expressions(
            ${name}Expressions::class as kotlin.reflect.KClass<${name}Expressions$appliedTypeArguments>,
        )
        val falseContent = whenFalse?.let { content ->
            { nested: com.typewritermc.presentation.PresentationBuildScope ->
                with(${name}PresentationScopeImpl$appliedTypeArguments(nested)) { content() }
            }
        }
        build.conditional(
            condition = expressions.condition(),
            whenFalse = falseContent,
        ) { nested ->
            with(${name}PresentationScopeImpl$appliedTypeArguments(nested)) { body() }
        }
    }
}

interface ${name}Check : com.typewritermc.checking.RealmCheckProvider

open class ${name}Draft$draftParameters internal constructor(
    internal val binding: com.typewritermc.authoring.DraftBinding${if (draftArguments.isEmpty()) "" else ", $draftArguments"},
)${if (resource) " : com.typewritermc.authoring.ResourceDraft" else " : com.typewritermc.authoring.DraftView"} {
    override val catalog get() = binding.catalog
    override val readContext get() = binding.readContext
    override val location get() = binding.location
    override val actualType = $actualType
    ${if (resource) "override val id get() = binding.location.resource" else ""}
$draftFields
$independentDraftEdits
}

$draftProjection

${if (typeParameters.isNotEmpty()) {
            """
class ${name}ExactDraft$exactDraftParameters internal constructor(
    binding: com.typewritermc.authoring.DraftBinding,
    $draftArguments,
) : ${name}Draft$draftParameters(binding, $draftProjectionArguments)$sourceClassWhere {
$dependentDraftEdits
}
"""
        } else {
            ""
        }}

${if (resource && typeParameters.isEmpty()) {
            """
object ${name}DraftType : com.typewritermc.checking.DraftType<${name}Draft> {
    override val match: com.typewritermc.checking.ResourceTypeMatch =
        com.typewritermc.checking.ResourceTypeMatch.Definition($definition)
    override fun bind(binding: com.typewritermc.authoring.DraftBinding): ${name}Draft = ${name}Draft(binding)
    fun where(
        predicate: ${name}Expressions.() -> com.typewritermc.expression.Expr<kotlin.Boolean, out com.typewritermc.expression.MissingPolicy>,
    ): com.typewritermc.checking.TypedSelection<${name}Draft> =
        com.typewritermc.checking.compileSelection(this, ${name}ExpressionsFactory, predicate)
}
"""
        } else if (resource) {
            """
class ${name}DraftType$draftParameters(
    $draftArguments,
) : com.typewritermc.checking.DraftType<${name}Draft$draftParameters> {
    override val match: com.typewritermc.checking.ResourceTypeMatch =
        com.typewritermc.checking.ResourceTypeMatch.Definition($definition)
    override fun bind(binding: com.typewritermc.authoring.DraftBinding): ${name}Draft$draftParameters =
        ${name}Draft(binding, $draftProjectionArguments)
}

class ${name}ExactDraftType$exactDraftParameters(
    $draftArguments,
) : com.typewritermc.checking.DraftType<${name}ExactDraft$exactDraftArguments>$sourceClassWhere {
    private val application = ${name}Definition.applied(listOf($draftApplicationArguments))
    override val match: com.typewritermc.checking.ResourceTypeMatch =
        com.typewritermc.checking.ResourceTypeMatch.Application(application)
    override fun bind(binding: com.typewritermc.authoring.DraftBinding): ${name}ExactDraft$exactDraftArguments =
        ${name}ExactDraft(binding, $draftProjectionArguments)
    @Suppress("UNCHECKED_CAST")
    fun where(
        predicate: ${name}Expressions$appliedTypeArguments.() -> com.typewritermc.expression.Expr<kotlin.Boolean, out com.typewritermc.expression.MissingPolicy>,
    ): com.typewritermc.checking.TypedSelection<${name}ExactDraft$exactDraftArguments> =
        com.typewritermc.checking.compileSelection(
            this,
            ${name}ExpressionsFactory as com.typewritermc.expression.ExpressionFactory<${name}Expressions$appliedTypeArguments>,
            predicate,
        )
}
"""
        } else {
            ""
        }}

object ${name}Definition : com.typewritermc.discovery.GeneratedTypeProvider {
    val id: com.typewritermc.types.TypeDefinitionId = $definition
    val declaration: com.typewritermc.types.TypeDefinition = ${typeDefinition.kotlinCode()}
    override val definition: com.typewritermc.types.TypeDefinition get() = declaration
    override val display: com.typewritermc.types.TypeDisplay? = $display
    fun applied(arguments: List<com.typewritermc.types.TypeUse> = emptyList()): com.typewritermc.types.TypeUse.Named {
        require(arguments.size == ${typeParameters.size}) { "$name requires ${typeParameters.size} type arguments." }
        return com.typewritermc.types.TypeUse.Named(id, arguments)
    }
    ${if (typeParameters.isEmpty()) "val use: com.typewritermc.types.TypeUse.Named = applied()" else ""}
}

$nativeFactory
""".trimStart()
    }

    private fun nativeFactorySource(
        declaration: KSClassDeclaration,
        definition: TypeDefinition,
        fields: List<OwnedFieldDeclaration>,
        properties: Map<String, KSPropertyDeclaration>,
    ): String {
        if (!declaration.supportsNativeBinding()) return ""
        val name = declaration.generatedTypeName()
        val nativeType = declaration.nativeAppliedType()
        val provider = "com.typewritermc.authoring.NativeBindingId(${(declaration.qualifiedName?.asString() ?: name).kotlinLiteral()})"
        val signature = (declaration.qualifiedName?.asString() ?: name).kotlinLiteral()
        val opaqueArguments =
            declaration.typeParameters
                .mapIndexedNotNull { index, parameter ->
                    val hasCompiledBound =
                        parameter.bounds
                            .map {
                                it.resolve()
                            }.any { it.declaration.qualifiedName?.asString() != "kotlin.Any" }
                    index.takeUnless { hasCompiledBound }
                }.joinToString()
        val binding =
            when {
                declaration.annotation(TYPEWRITER_STRING_ANNOTATION) != null -> {
                    val property =
                        declaration.primaryConstructor
                            ?.parameters
                            ?.firstOrNull()
                            ?.name
                            ?.asString()
                            ?: fields.firstOrNull()?.name
                            ?: return ""
                    """com.typewritermc.types.GeneratedScalarNativeBinding<$nativeType>(
            checked = actual,
            provider = provider,
            signature = $signature,
            nativeClass = $name::class,
            representation = arguments.resolver.bind(com.typewritermc.types.TypeUse.Scalar(com.typewritermc.types.ScalarKind.Text)),
            unwrap = { value -> value.$property },
            construct = { value -> $name(value as kotlin.String) },
        )"""
                }

                declaration.classKind == ClassKind.ENUM_CLASS -> {
                    val cases =
                        declaration.declarations
                            .filterIsInstance<KSClassDeclaration>()
                            .filter { it.classKind == ClassKind.ENUM_ENTRY }
                            .toList()
                    val encodeCases =
                        cases.joinToString("\n") { case ->
                            val key = case.serialName ?: case.simpleName.asString()
                            "                $name.${case.simpleName.asString()} -> ${key.kotlinLiteral()}"
                        }
                    val decodeCases =
                        cases.joinToString("\n") { case ->
                            val key = case.serialName ?: case.simpleName.asString()
                            "                ${key.kotlinLiteral()} -> $name.${case.simpleName.asString()}"
                        }
                    """com.typewritermc.types.GeneratedEnumNativeBinding<$name>(
            checked = actual,
            provider = provider,
            signature = $signature,
            nativeClass = $name::class,
            key = { value ->
                when (value) {
$encodeCases
                }
            },
            construct = { key ->
                when (key) {
$decodeCases
                    else -> throw com.typewritermc.types.NativeBindingException("unknown_enum_case", "Unknown enum case ${'$'}key.")
                }
            },
        )"""
                }

                declaration.classKind == ClassKind.OBJECT -> {
                    """com.typewritermc.types.GeneratedRecordNativeBinding<$name>(
            checked = actual,
            provider = provider,
            signature = $signature,
            nativeClass = $name::class,
            fields = emptyList(),
            construct = { $name },
        )"""
                }

                declaration.valueClassScalarKind() != null -> {
                    val field = fields.singleOrNull() ?: return ""
                    val property = properties[field.sourceName] ?: return ""
                    val nativeRepresentation = property.type.resolve().sourceType()
                    val kind = requireNotNull(declaration.valueClassScalarKind())
                    """com.typewritermc.types.GeneratedScalarNativeBinding<$nativeType>(
            checked = actual,
            provider = provider,
            signature = $signature,
            nativeClass = $name::class,
            representation = arguments.resolver.bind(com.typewritermc.types.TypeUse.Scalar(${kind.kotlinCode()})),
            unwrap = { value -> value.${field.sourceName} },
            construct = { value -> $name(value as $nativeRepresentation) },
        )"""
                }

                else -> {
                    val nativeFields =
                        fields.mapNotNull { field ->
                            val property = properties[field.sourceName] ?: return@mapNotNull null
                            val fieldType = property.type.resolve().nativeType(declaration)
                            val use = field.template.generatedNativeAppliedCode(definition.id).toString()
                            NativeFactoryField(
                                field.name,
                                field.sourceName,
                                fieldType,
                                use,
                                field.hasConstructorDefault,
                            )
                        }
                    val fieldBindings =
                        nativeFields.joinToString(",\n") { field ->
                            "                com.typewritermc.types.GeneratedNativeField(" +
                                "${field.name.kotlinLiteral()}, arguments.resolver.bind(${field.use}), " +
                                "{ value -> value.${field.propertyName} })"
                        }
                    val constructor =
                        nativeFields.joinToString(",\n") { field ->
                            "                ${field.propertyName} = values.getValue(${field.name.kotlinLiteral()}) as ${field.nativeType}"
                        }
                    """com.typewritermc.types.GeneratedRecordNativeBinding<$nativeType>(
            checked = actual,
            provider = provider,
            signature = $signature,
            nativeClass = $name::class,
            fields = listOf(
$fieldBindings,
            ),
            construct = { values ->
                $name(
$constructor,
                )
            },
        )"""
                }
            }
        val constructionPlan =
            if (declaration.classKind == ClassKind.CLASS && fields.any(OwnedFieldDeclaration::hasConstructorDefault) &&
                declaration.annotation(TYPEWRITER_STRING_ANNOTATION) == null
            ) {
                nativeConstructionPlanSource(declaration, definition, fields, properties)
            } else {
                ""
            }
        val constructionPlanProperty =
            if (constructionPlan.isEmpty()) {
                ""
            } else {
                "override val constructionPlan: com.typewritermc.authoring.NativeConstructionPlan = " +
                    "${name}NativeConstructionPlan"
            }
        return """
$constructionPlan

object ${name}NativeBindingFactory : com.typewritermc.types.NativeBindingFactory {
    override val definition: com.typewritermc.types.TypeDefinitionId = ${definition.id.kotlinCode()}
    override val provider: com.typewritermc.authoring.NativeBindingId = $provider
    override val nativeClass: kotlin.reflect.KClass<*> = $name::class
    $constructionPlanProperty

    override fun bind(
        actual: com.typewritermc.types.catalog.CheckedType,
        arguments: com.typewritermc.authoring.AppliedNativeArguments,
    ): com.typewritermc.types.NativeBinding<*> {
        arguments.requireOpaqueCompatibility(setOf($opaqueArguments))
        return $binding
    }
}
""".trimStart()
    }

    private fun nativeConstructionPlanSource(
        declaration: KSClassDeclaration,
        definition: TypeDefinition,
        fields: List<OwnedFieldDeclaration>,
        properties: Map<String, KSPropertyDeclaration>,
    ): String {
        val name = declaration.generatedTypeName()
        val defaulted = fields.filter(OwnedFieldDeclaration::hasConstructorDefault)
        val required = fields.filterNot(OwnedFieldDeclaration::hasConstructorDefault)
        val ownerCode = { field: OwnedFieldDeclaration ->
            "com.typewritermc.types.FieldOwner(${field.owner.kotlinCode()}, ${field.name.kotlinLiteral()})"
        }
        val missingOwners = required.joinToString { ownerCode(it) }
        val requiredConstructor =
            required.joinToString(",\n") { field ->
                val property = properties.getValue(field.sourceName)
                val nativeType = property.type.resolve().nativeType(declaration)
                val use = field.template.generatedNativeAppliedCode(definition.id)
                "                ${field.sourceName} = arguments.resolver.bind($use).decode(requiredInputs.required.getValue(${ownerCode(
                    field,
                )})) as $nativeType"
            }
        val captured =
            defaulted.joinToString(",\n") { field ->
                val use = field.template.generatedNativeAppliedCode(definition.id)
                "                ${ownerCode(field)} to arguments.resolver.bind($use).encodeGeneratedDefault(sampled.${field.sourceName})"
            }
        val constructorType = declaration.nativeAppliedType()
        val constructorInvocation =
            if (required.isEmpty()) {
                "$constructorType()"
            } else {
                """$constructorType(
$requiredConstructor,
            )"""
            }
        return """
object ${name}NativeConstructionPlan : com.typewritermc.authoring.NativeConstructionPlan {
    override val defaultedFields: kotlin.collections.Set<com.typewritermc.types.FieldOwner> =
        setOf(${defaulted.joinToString { ownerCode(it) }})

    override fun sample(
        arguments: com.typewritermc.authoring.AppliedNativeArguments,
        requiredInputs: com.typewritermc.authoring.SamplingInputs,
    ): com.typewritermc.authoring.CaptureResult {
        arguments.requireOpaqueCompatibility(setOf(${declaration.typeParameters.mapIndexedNotNull {
            index,
            parameter,
            ->
            index.takeUnless {
                parameter.bounds.map { it.resolve() }.any { bound ->
                    bound.declaration.qualifiedName?.asString() != "kotlin.Any"
                }
            }
        }.joinToString()}))
        val missing = listOf<com.typewritermc.types.FieldOwner>($missingOwners).filterNot(requiredInputs.required::containsKey)
        if (missing.isNotEmpty()) {
            return com.typewritermc.authoring.CaptureResult.Unavailable(
                listOf(
                    com.typewritermc.authoring.InitializationDiagnostic(
                        field = missing.first(),
                        code = "missing_sampling_input",
                        message = "A required constructor input is unavailable for default sampling.",
                    ),
                ),
            )
        }
        return try {
            val sampled = $constructorInvocation
            com.typewritermc.authoring.CaptureResult.Captured(
                mapOf(
$captured,
                ),
            )
        } catch (failure: kotlinx.coroutines.CancellationException) {
            throw failure
        } catch (failure: com.typewritermc.types.NativeBindingException) {
            com.typewritermc.authoring.CaptureResult.Unavailable(
                listOf(
                    com.typewritermc.authoring.InitializationDiagnostic(
                        field = null,
                        code = failure.code,
                        message = failure.message ?: failure.code,
                    ),
                ),
            )
        } catch (failure: kotlin.Exception) {
            com.typewritermc.authoring.CaptureResult.Unavailable(
                listOf(
                    com.typewritermc.authoring.InitializationDiagnostic(
                        field = null,
                        code = "native_default_capture_failed",
                        message = failure.message ?: "Native default capture failed.",
                    ),
                ),
            )
        }
    }
}
""".trimStart()
    }

    private fun generateAdapters(declaration: KSClassDeclaration) {
        val owner = declaration.qualifiedName?.asString() ?: return
        declaration.getAllSuperTypes().forEach { superType ->
            val interfaceDeclaration = superType.declaration as? KSClassDeclaration ?: return@forEach
            val interfaceName = interfaceDeclaration.simpleName.asString()
            val kind =
                when {
                    interfaceName.endsWith("Configuration") -> ProviderKind.Configuration
                    interfaceName.endsWith("Presentation") -> ProviderKind.Presentation
                    interfaceName.endsWith("Check") -> ProviderKind.Check
                    else -> return@forEach
                }
            val key = "$owner:${interfaceDeclaration.qualifiedName?.asString()}:$kind"
            if (!generatedAdapters.add(key)) return@forEach
            val targetName = interfaceName.removeSuffix(kind.suffix)
            val packageName = declaration.packageName.asString()
            val adapterName =
                owner.replace('.', '_').replace('$', '_') + "_" + targetName + kind.suffix + "Provider"
            val reference = if (declaration.isCompanionObject) owner.removeSuffix(".Companion") + ".Companion" else owner
            val source =
                adapterSource(
                    packageName,
                    adapterName,
                    reference,
                    targetName,
                    interfaceDeclaration.typeParameters.size,
                    kind,
                )
            codeGenerator
                .createNewFile(
                    Dependencies(false, *listOfNotNull(declaration.containingFile).toTypedArray()),
                    packageName,
                    adapterName,
                ).bufferedWriter()
                .use { it.write(source) }
            index(kind.name.lowercase(), "$packageName.$adapterName")
        }
    }

    private fun adapterSource(
        packageName: String,
        adapterName: String,
        declaration: String,
        target: String,
        targetParameterCount: Int,
        kind: ProviderKind,
    ): String =
        when (kind) {
            ProviderKind.Configuration -> {
                """
package $packageName
class $adapterName : com.typewritermc.discovery.GeneratedConfigurationProvider {
    override val target: com.typewritermc.types.TypeDefinitionId = ${target}Definition.id

    override fun collect(
        scope: com.typewritermc.configuration.ConfigurationCollectionScope,
    ): com.typewritermc.configuration.CollectedConfiguration {
        with($declaration) { ${target}ConfigurationScopeImpl(scope).configure() }
        return scope.collected()
    }
}
""".trimStart()
            }

            ProviderKind.Presentation -> {
                """
package $packageName
class $adapterName(
    private val runtime: com.typewritermc.presentation.PresentationRuntime,
) : com.typewritermc.discovery.GeneratedPresentationProvider {
    override fun descriptor(origin: com.typewritermc.discovery.ProviderOrigin): com.typewritermc.presentation.PresentationDescriptor =
        with($declaration) {
            val descriptor = com.typewritermc.presentation.PresentationDescriptor(
                id = com.typewritermc.types.PresentationId(origin.artifact.value, "$adapterName"),
                owner = origin.owner,
                target = com.typewritermc.presentation.PresentationTarget.Named(
                    com.typewritermc.types.TypeTemplate.Named(
                        ${target}Definition.id,
                        ${symbolicTargetArguments(target, targetParameterCount)},
                    ),
                ),
                roles = roles,
                priority = priority,
            )
            runtime.register(this, descriptor)
            descriptor
        }

    override fun build(binding: com.typewritermc.presentation.PresentationBuildBinding): com.typewritermc.presentation.PresentationBuildResult {
        return runtime.build(binding) { build -> with($declaration) { ${target}PresentationScopeImpl(build).present() } }
    }
}
""".trimStart()
            }

            ProviderKind.Check -> {
                """
package $packageName
class $adapterName : com.typewritermc.discovery.GeneratedCheckProvider {
    override val target: com.typewritermc.types.TypeDefinitionId = ${target}Definition.id

    override fun com.typewritermc.checking.RealmChecks.register() {
        with($declaration) { this@register.register() }
    }
}
""".trimStart()
            }
        }

    private fun symbolicTargetArguments(
        target: String,
        count: Int,
    ): String =
        (0 until count).joinToString(
            prefix = "listOf(",
            postfix = ")",
        ) { index ->
            "com.typewritermc.types.TypeTemplate.Parameter(" +
                "com.typewritermc.types.ParameterKey(${target}Definition.id, $index))"
        }

    private fun validateOptions(): Boolean {
        val missing = listOf(ARTIFACT_OPTION, SOURCE_PART_OPTION).filter { options[it].isNullOrBlank() }
        missing.forEach { logger.error("Missing KSP option $it.") }
        return missing.isEmpty()
    }

    private fun index(
        kind: String,
        providerClass: String,
    ) {
        val sourcePart = requireNotNull(options[SOURCE_PART_OPTION])
        require('\t' !in sourcePart && '\n' !in sourcePart) { "A source part cannot contain index separators." }
        providerIndex += "$kind\t$providerClass\t$sourcePart"
    }
}

private fun discoverEndpointBindings(
    root: TypeTemplate.Named,
    definitions: Map<TypeDefinitionId, TypeDefinition>,
): List<EndpointBindingTemplate> {
    val bindings = mutableListOf<EndpointBindingTemplate>()

    fun visit(
        template: TypeTemplate,
        path: List<FieldPatternSegment>,
        containsCollection: Boolean,
        valueOwner: TypeDefinitionId,
        stack: Set<Pair<TypeDefinitionId, Boolean>>,
    ) {
        when (template) {
            is TypeTemplate.Nullable -> {
                visit(template.value, path, containsCollection, valueOwner, stack)
            }

            is TypeTemplate.Parameter, is TypeTemplate.Scalar -> {}

            is TypeTemplate.Named -> {
                val definition = definitions[template.definition] ?: return
                val substitutions =
                    definition.parameters
                        .map(TypeParameter::key)
                        .zip(template.arguments)
                        .toMap()
                when (val representation = definition.representation) {
                    is RepresentationTemplate.Link -> {
                        bindings +=
                            EndpointBindingTemplate(
                                endpoint = representation.endpoint,
                                containingResource = root,
                                valueOwner = valueOwner,
                                relativePath = RelativeFieldPattern(path),
                                target = representation.target.substitute(substitutions),
                                containsCollection = containsCollection,
                            )
                    }

                    is RepresentationTemplate.Record -> {
                        val key = template.definition to containsCollection
                        if (key in stack) return
                        val nestedStack = stack + key
                        representation.fields.forEach { field ->
                            visit(
                                field.type.substitute(substitutions),
                                path + FieldPatternSegment.Field(field.owner.name),
                                containsCollection,
                                field.owner.definition,
                                nestedStack,
                            )
                        }
                    }

                    is RepresentationTemplate.Sequence -> {
                        visit(
                            representation.item.substitute(substitutions),
                            path + FieldPatternSegment.Items,
                            true,
                            valueOwner,
                            stack,
                        )
                    }

                    is RepresentationTemplate.Mapping -> {
                        visit(
                            representation.key.substitute(substitutions),
                            path + FieldPatternSegment.Keys,
                            true,
                            valueOwner,
                            stack,
                        )
                        visit(
                            representation.value.substitute(substitutions),
                            path + FieldPatternSegment.Values,
                            true,
                            valueOwner,
                            stack,
                        )
                    }

                    is RepresentationTemplate.Enumeration, is RepresentationTemplate.Scalar -> {}
                }
            }
        }
    }

    visit(root, emptyList(), false, root.definition, emptySet())
    return bindings.distinct()
}

private fun TypeTemplate.substitute(arguments: Map<ParameterKey, TypeTemplate>): TypeTemplate =
    when (this) {
        is TypeTemplate.Parameter -> arguments[key] ?: this
        is TypeTemplate.Named -> copy(arguments = this.arguments.map { it.substitute(arguments) })
        is TypeTemplate.Nullable -> copy(value = value.substitute(arguments))
        is TypeTemplate.Scalar -> this
    }

private enum class ProviderKind(
    val suffix: String,
) {
    Configuration("Configuration"),
    Presentation("Presentation"),
    Check("Check"),
}

private data class RelationEndpointSource(
    val name: String,
    val resource: KSClassDeclaration,
    val resourceType: KSType,
    val cardinality: String,
    val deletion: String,
)

private data class NativeFactoryField(
    val name: String,
    val propertyName: String,
    val nativeType: String,
    val use: String,
    val hasDefault: Boolean,
)

private fun linkDefinition(
    endpointName: String,
    endpoint: EndpointId,
): TypeDefinition {
    val id = TypeDefinitionId(TypeId.Qualified("relation", endpointName), 1)
    val target = ParameterKey(id, 0)
    return TypeDefinition(
        id,
        parameters = listOf(TypeParameter(target, "Target")),
        representation = RepresentationTemplate.Link(endpoint, TypeTemplate.Parameter(target)),
    )
}

private fun classes(declarations: Sequence<com.google.devtools.ksp.symbol.KSDeclaration>): Sequence<KSClassDeclaration> =
    declarations.filterIsInstance<KSClassDeclaration>().flatMap { sequenceOf(it) + classes(it.declarations) }

private fun KSClassDeclaration.generatedTypeName(): String =
    generateSequence(this as KSDeclaration?) { declaration -> declaration.parentDeclaration }
        .takeWhile { declaration -> declaration is KSClassDeclaration }
        .map { declaration -> declaration.simpleName.asString() }
        .toList()
        .asReversed()
        .joinToString("")

private fun KSClassDeclaration.identityCode(): String {
    val definition = typeDefinitionIdentity()
    return "com.typewritermc.types.TypeTemplate.Named(${definition.kotlinCode()})"
}

private fun KSType.endpointResourceTemplate(): TypeTemplate.Named =
    endpointTemplate() as? TypeTemplate.Named
        ?: error("Relation endpoint resources must use named types.")

private fun KSType.endpointTemplate(): TypeTemplate {
    val parameter = declaration as? com.google.devtools.ksp.symbol.KSTypeParameter
    if (parameter != null) {
        val owner =
            parameter.parentDeclaration as? KSClassDeclaration
                ?: error("Relation endpoint parameters require a declaration owner.")
        val index = owner.typeParameters.indexOf(parameter)
        require(index >= 0) { "Relation endpoint parameters must belong to their declaration." }
        return TypeTemplate.Parameter(ParameterKey(owner.typeDefinitionIdentity(), index))
    }

    val declaration =
        declaration as? KSClassDeclaration
            ?: error("Relation endpoint arguments must use class or parameter types.")
    portableScalarKind()?.let { scalar ->
        return TypeTemplate.Scalar(scalar).withNullability(this)
    }
    val qualified = declaration.qualifiedName?.asString()
    val identity =
        when (qualified) {
            in LIST_TYPES -> TypeDefinitionId(TypeId.Qualified("typewriter", "List"), 1)
            in SET_TYPES -> TypeDefinitionId(TypeId.Qualified("typewriter", "Set"), 1)
            in MAP_TYPES -> TypeDefinitionId(TypeId.Qualified("typewriter", "Map"), 1)
            else -> declaration.typeDefinitionIdentity()
        }
    val arguments =
        arguments.mapIndexed { index, argument ->
            argument.type?.resolve()?.endpointTemplate()
                ?: TypeTemplate.Parameter(ParameterKey(identity, index))
        }
    return TypeTemplate.Named(identity, arguments).withNullability(this)
}

private fun TypeTemplate.withNullability(type: KSType): TypeTemplate =
    if (type.nullability.name == "NULLABLE") TypeTemplate.Nullable(this) else this

private fun KSClassDeclaration.typeDefinitionIdentity(): TypeDefinitionId {
    val annotation = annotation(TYPEWRITER_TYPE_ANNOTATION)
    val id = annotation?.argument("id") as? String
    val revision = annotation?.argument("revision") as? Int ?: 1
    val definition =
        if (id != null) {
            TypeDefinitionId(TypeId.Declared(DeclaredTypeId.parse(id)), revision)
        } else {
            val qualified = qualifiedName?.asString() ?: simpleName.asString()
            TypeDefinitionId(TypeId.Qualified("kotlin", qualified), revision)
        }
    return definition
}

private fun KSClassDeclaration.isResourceDeclaration(): Boolean =
    getAllSuperTypes().any { it.declaration.qualifiedName?.asString() == RESOURCE_TYPE }

private fun KSClassDeclaration.supportsNativeBinding(): Boolean =
    classKind != ClassKind.INTERFACE &&
        Modifier.ABSTRACT !in modifiers &&
        Modifier.PRIVATE !in modifiers &&
        typeParameters.none { parameter ->
            parameter.bounds
                .map { it.resolve() }
                .count { it.declaration.qualifiedName?.asString() != "kotlin.Any" } > 1
        }

private fun KSClassDeclaration.valueClassScalarKind(): ScalarKind? {
    if (Modifier.VALUE !in modifiers && annotation(JVM_INLINE_ANNOTATION) == null) return null
    val parameter = primaryConstructor?.parameters?.singleOrNull() ?: return null
    return parameter.type.resolve().portableScalarKind()
}

private fun KSClassDeclaration.valueClassRepresentationType(): KSType? =
    primaryConstructor
        ?.parameters
        ?.singleOrNull()
        ?.type
        ?.resolve()

private fun KSClassDeclaration.nominalScalarConfigurationScope(kind: ScalarKind): String =
    if (qualifiedName?.asString() == COLOR_TYPE) {
        "com.typewritermc.configuration.ColorField"
    } else {
        configurationScope(TypeTemplate.Scalar(kind), valueClassRepresentationType())
    }

private fun KSClassDeclaration.nominalScalarConfigurationScopeClass(kind: ScalarKind): String =
    if (qualifiedName?.asString() == COLOR_TYPE) {
        "com.typewritermc.configuration.ColorField"
    } else {
        configurationScopeClass(TypeTemplate.Scalar(kind), valueClassRepresentationType())
    }

private fun KSClassDeclaration.nativeAppliedType(): String {
    val name = qualifiedName?.asString() ?: simpleName.asString()
    if (typeParameters.isEmpty()) return name
    return typeParameters.joinToString(prefix = "$name<", postfix = ">") { parameter ->
        parameter.bounds
            .map { it.resolve() }
            .firstOrNull { it.declaration.qualifiedName?.asString() != "kotlin.Any" }
            ?.nativeType(this)
            ?: "kotlin.Any?"
    }
}

private fun KSType.nativeType(owner: KSClassDeclaration): String {
    val declaration = declaration
    val rendered =
        if (declaration is com.google.devtools.ksp.symbol.KSTypeParameter) {
            declaration.bounds
                .map { it.resolve() }
                .firstOrNull { it.declaration.qualifiedName?.asString() != "kotlin.Any" }
                ?.nativeType(owner)
                ?: "kotlin.Any?"
        } else {
            val base = declaration.qualifiedName?.asString() ?: declaration.simpleName.asString()
            arguments.joinToString(
                prefix = base + if (arguments.isEmpty()) "" else "<",
                postfix = if (arguments.isEmpty()) "" else ">",
            ) { argument ->
                argument.type?.resolve()?.nativeType(owner) ?: "kotlin.Any?"
            }
        }
    return rendered + if (nullability.name == "NULLABLE" && !rendered.endsWith("?")) "?" else ""
}

private fun KSAnnotated.annotation(qualifiedName: String): KSAnnotation? =
    annotations.firstOrNull {
        it.annotationType
            .resolve()
            .declaration.qualifiedName
            ?.asString() == qualifiedName
    }

private fun KSClassDeclaration.typeDisplayCode(): String {
    val annotation = annotation(TYPEWRITER_DISPLAY_ANNOTATION) ?: return "null"
    val name = annotation.argument("name") as? String ?: return "null"
    val description = annotation.argument("description") as? String ?: ""
    val icon = annotation.argument("icon") as? String ?: return "null"
    val color = annotation.argument("color") as? String ?: return "null"
    return "com.typewritermc.types.TypeDisplay(" +
        "name = ${name.kotlinLiteral()}, " +
        "description = ${description.kotlinLiteral()}, " +
        "icon = ${icon.kotlinLiteral()}, " +
        "color = ${color.kotlinLiteral()}" +
        ")"
}

private fun KSPropertyDeclaration.resourceRoot(): KSClassDeclaration? =
    (annotation(RESOURCE_DEFINITION_ANNOTATION)?.argument("root") as? KSType)?.declaration as? KSClassDeclaration

private fun KSAnnotation.argument(name: String): Any? = arguments.firstOrNull { it.name?.asString() == name }?.value

private val KSDeclaration.serialName: String?
    get() =
        annotations
            .firstOrNull {
                it.annotationType
                    .resolve()
                    .declaration.qualifiedName
                    ?.asString() == "kotlinx.serialization.SerialName"
            }?.arguments
            ?.firstOrNull()
            ?.value as? String

private fun configurationScope(
    template: TypeTemplate,
    type: KSType?,
): String =
    when (template) {
        is TypeTemplate.Nullable -> {
            val valueType = type?.makeNotNullable()
            val native = configurationValueType(template.value, valueType)
            "com.typewritermc.configuration.NullableField<$native, ${configurationScope(template.value, valueType)}>"
        }

        is TypeTemplate.Scalar -> {
            when (template.kind) {
                ScalarKind.Text -> {
                    "com.typewritermc.configuration.Text"
                }

                is ScalarKind.Integer -> {
                    "com.typewritermc.configuration.Integer<${type?.toTypeName() ?: "kotlin.Long"}>"
                }

                is ScalarKind.Float -> {
                    "com.typewritermc.configuration.Real<${type?.toTypeName() ?: "kotlin.Double"}>"
                }

                ScalarKind.Decimal -> {
                    "com.typewritermc.configuration.Decimal"
                }

                ScalarKind.Boolean -> {
                    "com.typewritermc.configuration.BooleanField"
                }

                ScalarKind.Bytes -> {
                    "com.typewritermc.configuration.Bytes"
                }

                ScalarKind.Timestamp -> {
                    "com.typewritermc.configuration.TimestampField"
                }

                ScalarKind.Duration -> {
                    "com.typewritermc.configuration.DurationField"
                }

                ScalarKind.Unit -> {
                    "com.typewritermc.configuration.RecordField<kotlin.Unit, " +
                        "com.typewritermc.configuration.GenericValueExpressions<kotlin.Unit>>"
                }
            }
        }

        is TypeTemplate.Parameter -> {
            val native = configurationValueType(template, type)
            "com.typewritermc.configuration.GenericValueConfigurationScope<$native>"
        }

        is TypeTemplate.Named -> {
            val qualified = type?.declaration?.qualifiedName?.asString()
            val scalar = (type?.declaration as? KSClassDeclaration)?.valueClassScalarKind()
            when {
                qualified == COLOR_TYPE -> {
                    "com.typewritermc.configuration.ColorField"
                }

                type?.declaration?.annotation(TYPEWRITER_STRING_ANNOTATION) != null -> {
                    "com.typewritermc.configuration.Text"
                }

                scalar != null -> {
                    configurationScope(TypeTemplate.Scalar(scalar), (type.declaration as KSClassDeclaration).valueClassRepresentationType())
                }

                qualified == REFERENCE_TYPE -> {
                    val target =
                        type.arguments
                            .getOrNull(1)
                            ?.type
                            ?.resolve()
                            ?.sourceType() ?: "com.typewritermc.types.Resource"
                    "com.typewritermc.configuration.LinkField<$target>"
                }

                qualified in LIST_TYPES -> {
                    val itemType =
                        type!!
                            .arguments
                            .single()
                            .type
                            ?.resolve()
                    val itemTemplate = template.arguments.single()
                    val itemNative = configurationValueType(itemTemplate, itemType)
                    "com.typewritermc.configuration.ListField<$itemNative, ${configurationScope(
                        itemTemplate,
                        itemType,
                    )}, ${expressionScopeType(itemTemplate, itemType)}>"
                }

                qualified in SET_TYPES -> {
                    val itemType =
                        type!!
                            .arguments
                            .single()
                            .type
                            ?.resolve()
                    val itemTemplate = template.arguments.single()
                    val itemNative = configurationValueType(itemTemplate, itemType)
                    "com.typewritermc.configuration.SetField<$itemNative, ${configurationScope(itemTemplate, itemType)}>"
                }

                qualified in MAP_TYPES -> {
                    val keyType = type!!.arguments[0].type?.resolve()
                    val valueType = type.arguments[1].type?.resolve()
                    val keyTemplate = template.arguments[0]
                    val valueTemplate = template.arguments[1]
                    val keyNative = configurationValueType(keyTemplate, keyType)
                    val valueNative = configurationValueType(valueTemplate, valueType)
                    "com.typewritermc.configuration.MapField<$keyNative, $valueNative, ${configurationScope(
                        keyTemplate,
                        keyType,
                    )}, ${configurationScope(valueTemplate, valueType)}>"
                }

                (type?.declaration as? KSClassDeclaration)?.classKind == ClassKind.ENUM_CLASS -> {
                    val native = configurationValueType(template, type)
                    "com.typewritermc.configuration.EnumField<$native>"
                }

                type != null -> {
                    type.generatedConfigurationScope()
                }

                else -> {
                    "com.typewritermc.configuration.RecordField<Any, com.typewritermc.configuration.GenericValueExpressions<Any>>"
                }
            }
        }
    }

private fun configurationScopeClass(
    template: TypeTemplate,
    type: KSType? = null,
): String =
    when (template) {
        is TypeTemplate.Nullable -> {
            "com.typewritermc.configuration.NullableField"
        }

        is TypeTemplate.Scalar -> {
            when (template.kind) {
                ScalarKind.Text -> "com.typewritermc.configuration.Text"
                is ScalarKind.Integer -> "com.typewritermc.configuration.Integer"
                is ScalarKind.Float -> "com.typewritermc.configuration.Real"
                ScalarKind.Decimal -> "com.typewritermc.configuration.Decimal"
                ScalarKind.Boolean -> "com.typewritermc.configuration.BooleanField"
                ScalarKind.Bytes -> "com.typewritermc.configuration.Bytes"
                ScalarKind.Timestamp -> "com.typewritermc.configuration.TimestampField"
                ScalarKind.Duration -> "com.typewritermc.configuration.DurationField"
                ScalarKind.Unit -> "com.typewritermc.configuration.RecordField"
            }
        }

        is TypeTemplate.Parameter -> {
            "com.typewritermc.configuration.GenericValueConfigurationScope"
        }

        is TypeTemplate.Named -> {
            val qualified = type?.declaration?.qualifiedName?.asString()
            val scalar = (type?.declaration as? KSClassDeclaration)?.valueClassScalarKind()
            when {
                qualified == COLOR_TYPE -> {
                    "com.typewritermc.configuration.ColorField"
                }

                type?.declaration?.annotation(TYPEWRITER_STRING_ANNOTATION) != null -> {
                    "com.typewritermc.configuration.Text"
                }

                scalar != null -> {
                    configurationScopeClass(
                        TypeTemplate.Scalar(scalar),
                        (type.declaration as KSClassDeclaration).valueClassRepresentationType(),
                    )
                }

                qualified == REFERENCE_TYPE -> {
                    "com.typewritermc.configuration.LinkField"
                }

                qualified in LIST_TYPES -> {
                    "com.typewritermc.configuration.ListField"
                }

                qualified in SET_TYPES -> {
                    "com.typewritermc.configuration.SetField"
                }

                qualified in MAP_TYPES -> {
                    "com.typewritermc.configuration.MapField"
                }

                (type?.declaration as? KSClassDeclaration)?.classKind == ClassKind.ENUM_CLASS -> {
                    "com.typewritermc.configuration.EnumField"
                }

                type != null -> {
                    type.generatedConfigurationScopeClass()
                }

                else -> {
                    "com.typewritermc.configuration.RecordField"
                }
            }
        }
    }

private fun expressionScopeType(
    template: TypeTemplate,
    type: KSType?,
): String =
    when (template) {
        is TypeTemplate.Nullable -> {
            val native = configurationValueType(template.value, type?.makeNotNullable())
            "com.typewritermc.configuration.NullableExpressions<$native>"
        }

        is TypeTemplate.Scalar -> {
            when (template.kind) {
                ScalarKind.Text -> {
                    "com.typewritermc.configuration.TextExpressions"
                }

                is ScalarKind.Integer, is ScalarKind.Float -> {
                    "com.typewritermc.configuration.NumberExpressions<${configurationValueType(template, type)}>"
                }

                ScalarKind.Decimal -> {
                    "com.typewritermc.configuration.NumberExpressions<java.math.BigDecimal>"
                }

                ScalarKind.Boolean -> {
                    "com.typewritermc.configuration.BooleanExpressions"
                }

                ScalarKind.Bytes -> {
                    "com.typewritermc.configuration.BytesExpressions"
                }

                ScalarKind.Timestamp -> {
                    "com.typewritermc.configuration.TimestampExpressions"
                }

                ScalarKind.Duration -> {
                    "com.typewritermc.configuration.DurationExpressions"
                }

                ScalarKind.Unit -> {
                    "com.typewritermc.configuration.GenericValueExpressions<kotlin.Unit>"
                }
            }
        }

        is TypeTemplate.Parameter -> {
            "com.typewritermc.configuration.GenericValueExpressions<${configurationValueType(template, type)}>"
        }

        is TypeTemplate.Named -> {
            val qualified = type?.declaration?.qualifiedName?.asString()
            val scalar = (type?.declaration as? KSClassDeclaration)?.valueClassScalarKind()
            when {
                qualified == COLOR_TYPE -> {
                    "com.typewritermc.configuration.ColorExpressions"
                }

                type?.declaration?.annotation(TYPEWRITER_STRING_ANNOTATION) != null -> {
                    "com.typewritermc.configuration.TextExpressions"
                }

                scalar != null -> {
                    expressionScopeType(
                        TypeTemplate.Scalar(scalar),
                        (type.declaration as KSClassDeclaration).valueClassRepresentationType(),
                    )
                }

                qualified == REFERENCE_TYPE -> {
                    val target =
                        type.arguments
                            .getOrNull(1)
                            ?.type
                            ?.resolve()
                            ?.sourceType() ?: "com.typewritermc.types.Resource"
                    "com.typewritermc.configuration.LinkExpressions<$target>"
                }

                qualified in LIST_TYPES -> {
                    val item =
                        type!!
                            .arguments
                            .single()
                            .type
                            ?.resolve()
                            ?.sourceType() ?: "kotlin.Any?"
                    "com.typewritermc.configuration.ListExpressions<$item>"
                }

                qualified in SET_TYPES -> {
                    val item =
                        type!!
                            .arguments
                            .single()
                            .type
                            ?.resolve()
                            ?.sourceType() ?: "kotlin.Any?"
                    "com.typewritermc.configuration.SetExpressions<$item>"
                }

                qualified in MAP_TYPES -> {
                    val key =
                        type!!
                            .arguments[0]
                            .type
                            ?.resolve()
                            ?.sourceType() ?: "kotlin.Any?"
                    val value =
                        type.arguments[1]
                            .type
                            ?.resolve()
                            ?.sourceType() ?: "kotlin.Any?"
                    "com.typewritermc.configuration.MapExpressions<$key, $value>"
                }

                (type?.declaration as? KSClassDeclaration)?.classKind == ClassKind.ENUM_CLASS -> {
                    "com.typewritermc.configuration.EnumExpressions<${configurationValueType(template, type)}>"
                }

                type != null -> {
                    type.generatedExpressionScope()
                }

                else -> {
                    "com.typewritermc.configuration.GenericValueExpressions<kotlin.Any?>"
                }
            }
        }
    }

private fun expressionScopeClass(
    template: TypeTemplate,
    type: KSType?,
): String = expressionScopeType(template, type).substringBefore('<')

private fun KSType.generatedExpressionScope(): String {
    val qualified =
        declaration.qualifiedName?.asString()
            ?: return "com.typewritermc.configuration.GenericValueExpressions<kotlin.Any?>"
    val packageName = qualified.substringBeforeLast('.', "")
    val base = declaration.simpleName.asString() + "Expressions"
    val scope = if (packageName.isEmpty()) base else "$packageName.$base"
    return arguments.joinToString(
        prefix = scope + if (arguments.isEmpty()) "" else "<",
        postfix = if (arguments.isEmpty()) "" else ">",
    ) { argument ->
        argument.type?.resolve()?.sourceType(argument.type?.explicitNullable == true) ?: "*"
    }
}

private fun configurationValueType(
    template: TypeTemplate,
    type: KSType?,
): String =
    when {
        type?.declaration?.annotation(TYPEWRITER_STRING_ANNOTATION) != null -> {
            "kotlin.String"
        }

        (type?.declaration as? KSClassDeclaration)?.valueClassScalarKind() != null -> {
            (type.declaration as KSClassDeclaration).valueClassRepresentationType()?.sourceType() ?: "kotlin.Any"
        }

        template is TypeTemplate.Nullable -> {
            configurationValueType(template.value, type?.makeNotNullable()) + "?"
        }

        type != null -> {
            type.makeNotNullable().sourceType()
        }

        else -> {
            "kotlin.Any"
        }
    }

private fun KSType.generatedConfigurationScope(): String {
    val qualified =
        declaration.qualifiedName?.asString()
            ?: return "com.typewritermc.configuration.RecordField<Any, com.typewritermc.configuration.GenericValueExpressions<Any>>"
    val scope =
        qualified.substringBeforeLast('.', "").let { packageName ->
            val simple = declaration.simpleName.asString() + "ConfigurationScope"
            if (packageName.isEmpty()) simple else "$packageName.$simple"
        }
    return arguments.joinToString(
        prefix = scope + if (arguments.isEmpty()) "" else "<",
        postfix = if (arguments.isEmpty()) "" else ">",
    ) { argument ->
        argument.type?.resolve()?.sourceType() ?: "kotlin.Any?"
    }
}

private fun KSType.sourceType(explicitParameterNullable: Boolean = false): String {
    val base =
        if (declaration is com.google.devtools.ksp.symbol.KSTypeParameter) {
            declaration.simpleName.asString()
        } else {
            declaration.qualifiedName?.asString() ?: declaration.simpleName.asString()
        }
    val rendered =
        arguments.joinToString(
            prefix = base + if (arguments.isEmpty()) "" else "<",
            postfix = if (arguments.isEmpty()) "" else ">",
        ) { argument ->
            argument.type?.let { it.resolve().sourceType(it.explicitNullable) } ?: "*"
        }
    val nullable =
        if (declaration is com.google.devtools.ksp.symbol.KSTypeParameter) {
            explicitParameterNullable
        } else {
            nullability.name ==
                "NULLABLE"
        }
    return rendered + if (nullable) "?" else ""
}

private val com.google.devtools.ksp.symbol.KSTypeReference.explicitNullable: Boolean
    get() = element?.toString()?.trim()?.endsWith("?") == true

private fun KSType.generatedConfigurationScopeClass(): String {
    val qualified = declaration.qualifiedName?.asString() ?: return "com.typewritermc.configuration.RecordField"
    val packageName = qualified.substringBeforeLast('.', "")
    val simple = declaration.simpleName.asString() + "ConfigurationScope"
    return if (packageName.isEmpty()) simple else "$packageName.$simple"
}

private fun configurationNestedScopes(
    template: TypeTemplate,
    type: KSType?,
): String {
    val entries =
        when (template) {
            is TypeTemplate.Nullable -> {
                listOf(
                    "com.typewritermc.configuration.FieldPatternSegment.Values to " +
                        nestedConfigurationDescriptor(template.value, type?.makeNotNullable()),
                )
            }

            is TypeTemplate.Named -> {
                when (type?.declaration?.qualifiedName?.asString()) {
                    in LIST_TYPES, in SET_TYPES -> {
                        listOf(
                            "com.typewritermc.configuration.FieldPatternSegment.Items to " +
                                nestedConfigurationDescriptor(
                                    template.arguments.single(),
                                    type!!
                                        .arguments
                                        .single()
                                        .type
                                        ?.resolve(),
                                ),
                        )
                    }

                    in MAP_TYPES -> {
                        listOf(
                            "com.typewritermc.configuration.FieldPatternSegment.Keys to " +
                                nestedConfigurationDescriptor(template.arguments[0], type!!.arguments[0].type?.resolve()),
                            "com.typewritermc.configuration.FieldPatternSegment.Values to " +
                                nestedConfigurationDescriptor(template.arguments[1], type.arguments[1].type?.resolve()),
                        )
                    }

                    else -> {
                        emptyList()
                    }
                }
            }

            is TypeTemplate.Parameter, is TypeTemplate.Scalar -> {
                emptyList()
            }
        }
    return entries.joinToString(prefix = "mapOf(", postfix = ")")
}

private fun nestedConfigurationDescriptor(
    template: TypeTemplate,
    type: KSType?,
): String {
    val kind = representationKind(template, type)
    val expected = configurationExpectedTemplate(template, type).kotlinCode()
    val expressions = expressionScopeClass(template, type)
    val scope =
        if (template is TypeTemplate.Named && type != null &&
            type.hasGeneratedConfigurationImplementation()
        ) {
            type.generatedConfigurationScopeClass()
        } else {
            configurationScopeClass(template, type)
        }
    return "com.typewritermc.configuration.NestedConfigurationScope(" +
        "com.typewritermc.configuration.RepresentationKind.$kind, $expected, $scope::class, ${expressions}Factory" +
        ") { nested -> ${configurationScopeCreation(template, type, "nested")} }"
}

private fun configurationScopeCreation(
    template: TypeTemplate,
    type: KSType?,
    collection: String,
): String {
    if (template is TypeTemplate.Named && type != null && type.hasGeneratedConfigurationImplementation()) {
        return "${type.generatedConfigurationScopeImplementation()}($collection)"
    }
    val scope = configurationScope(template, type)
    val scopeClass = configurationScopeClass(template, type)
    val kind = representationKind(template, type)
    val nested = configurationNestedScopes(template, type)
    val expected = configurationExpectedTemplate(template, type).kotlinCode()
    val expressions = expressionScopeClass(template, type)
    return "$collection.field(com.typewritermc.configuration.RelativeFieldPattern(), " +
        "com.typewritermc.configuration.RepresentationKind.$kind, " +
        "$expected, " +
        "$scopeClass::class as kotlin.reflect.KClass<$scope>, $nested, ${expressions}Factory)"
}

private fun configurationExpectedTemplate(
    template: TypeTemplate,
    type: KSType?,
): TypeTemplate =
    when {
        template is TypeTemplate.Nullable -> {
            TypeTemplate.Nullable(configurationExpectedTemplate(template.value, type?.makeNotNullable()))
        }

        type?.declaration?.annotation(TYPEWRITER_STRING_ANNOTATION) != null -> {
            TypeTemplate.Scalar(ScalarKind.Text)
        }

        type?.declaration?.qualifiedName?.asString() == COLOR_TYPE -> {
            template
        }

        (type?.declaration as? KSClassDeclaration)?.valueClassScalarKind() != null -> {
            TypeTemplate.Scalar(requireNotNull((type.declaration as KSClassDeclaration).valueClassScalarKind()))
        }

        else -> {
            template
        }
    }

private fun readExpectedTemplate(
    template: TypeTemplate,
    type: KSType?,
): TypeTemplate =
    when {
        template is TypeTemplate.Nullable -> {
            TypeTemplate.Nullable(readExpectedTemplate(template.value, type?.makeNotNullable()))
        }

        type?.declaration?.annotation(TYPEWRITER_STRING_ANNOTATION) != null -> {
            TypeTemplate.Scalar(ScalarKind.Text)
        }

        (type?.declaration as? KSClassDeclaration)?.valueClassScalarKind() != null -> {
            TypeTemplate.Scalar(requireNotNull((type.declaration as KSClassDeclaration).valueClassScalarKind()))
        }

        else -> {
            template
        }
    }

private fun KSType.hasGeneratedConfigurationImplementation(): Boolean {
    val qualified = declaration.qualifiedName?.asString()
    val declarationClass = declaration as? KSClassDeclaration ?: return false
    return declaration.annotation(TYPEWRITER_STRING_ANNOTATION) == null &&
        declarationClass.valueClassScalarKind() == null &&
        qualified != REFERENCE_TYPE &&
        qualified !in LIST_TYPES &&
        qualified !in SET_TYPES &&
        qualified !in MAP_TYPES &&
        declarationClass.classKind != ClassKind.ENUM_CLASS
}

private fun KSType.generatedConfigurationScopeImplementation(): String {
    val scope = generatedConfigurationScopeClass() + "Impl"
    return arguments.joinToString(
        prefix = scope + if (arguments.isEmpty()) "" else "<",
        postfix = if (arguments.isEmpty()) "" else ">",
    ) { argument ->
        argument.type?.resolve()?.sourceType() ?: "kotlin.Any?"
    }
}

private fun presentationScope(
    template: TypeTemplate,
    type: KSType?,
): String =
    when (template) {
        is TypeTemplate.Nullable -> {
            "com.typewritermc.presentation.NullableControl<${presentationNestedScope(template.value, type?.makeNotNullable())}>"
        }

        is TypeTemplate.Scalar -> {
            when (template.kind) {
                ScalarKind.Text -> {
                    "com.typewritermc.presentation.TextControl"
                }

                is ScalarKind.Integer, is ScalarKind.Float, ScalarKind.Decimal -> {
                    "com.typewritermc.presentation.NumberControl<" +
                        "${type?.toTypeName() ?: "kotlin.Number"}>"
                }

                ScalarKind.Boolean -> {
                    "com.typewritermc.presentation.BooleanControl"
                }

                ScalarKind.Bytes -> {
                    "com.typewritermc.presentation.BytesControl"
                }

                ScalarKind.Timestamp -> {
                    "com.typewritermc.presentation.DateTimeControl"
                }

                ScalarKind.Duration -> {
                    "com.typewritermc.presentation.DurationControl"
                }

                ScalarKind.Unit -> {
                    "com.typewritermc.presentation.Control"
                }
            }
        }

        is TypeTemplate.Parameter -> {
            "com.typewritermc.presentation.Control"
        }

        is TypeTemplate.Named -> {
            val qualified = type?.declaration?.qualifiedName?.asString()
            val declaration = type?.declaration as? KSClassDeclaration
            val scalar = (type?.declaration as? KSClassDeclaration)?.valueClassScalarKind()
            when {
                qualified == COLOR_TYPE -> {
                    "com.typewritermc.presentation.ColorControl"
                }

                type?.declaration?.annotation(TYPEWRITER_STRING_ANNOTATION) != null -> {
                    "com.typewritermc.presentation.TextControl"
                }

                scalar != null -> {
                    presentationScope(
                        TypeTemplate.Scalar(scalar),
                        (type.declaration as KSClassDeclaration).valueClassRepresentationType(),
                    )
                }

                qualified == REFERENCE_TYPE -> {
                    "com.typewritermc.presentation.LinkControl<com.typewritermc.types.Resource>"
                }

                qualified in LIST_TYPES && type?.resourceLinksTargetType() != null -> {
                    "com.typewritermc.presentation.ResourceLinksControl<${type.resourceLinksTargetType()!!.sourceType()}>"
                }

                qualified in LIST_TYPES -> {
                    "com.typewritermc.presentation.ListControl<${presentationNestedScope(
                        template.arguments.single(),
                        type!!
                            .arguments
                            .single()
                            .type
                            ?.resolve(),
                    )}>"
                }

                qualified in SET_TYPES -> {
                    "com.typewritermc.presentation.SetControl<${presentationNestedScope(
                        template.arguments.single(),
                        type!!
                            .arguments
                            .single()
                            .type
                            ?.resolve(),
                    )}>"
                }

                qualified in MAP_TYPES -> {
                    "com.typewritermc.presentation.MapControl<" +
                        "${presentationNestedScope(template.arguments[0], type!!.arguments[0].type?.resolve())}, " +
                        "${presentationNestedScope(template.arguments[1], type.arguments[1].type?.resolve())}>"
                }

                declaration?.classKind == ClassKind.ENUM_CLASS -> {
                    "com.typewritermc.presentation.EnumControl<${type.sourceType()}>"
                }

                declaration != null &&
                    (declaration.classKind == ClassKind.INTERFACE || Modifier.ABSTRACT in declaration.modifiers) -> {
                    "com.typewritermc.presentation.PolymorphicControl<${type.sourceType()}>"
                }

                type != null && type.hasGeneratedPresentationImplementation() -> {
                    "com.typewritermc.presentation.RecordControl<${type.generatedPresentationScope()}>"
                }

                else -> {
                    "com.typewritermc.presentation.Control"
                }
            }
        }
    }

private fun presentationScopeClass(
    template: TypeTemplate,
    type: KSType? = null,
): String =
    when (template) {
        is TypeTemplate.Nullable -> {
            "com.typewritermc.presentation.NullableControl"
        }

        is TypeTemplate.Scalar -> {
            when (template.kind) {
                ScalarKind.Text -> "com.typewritermc.presentation.TextControl"
                is ScalarKind.Integer, is ScalarKind.Float, ScalarKind.Decimal -> "com.typewritermc.presentation.NumberControl"
                ScalarKind.Boolean -> "com.typewritermc.presentation.BooleanControl"
                ScalarKind.Bytes -> "com.typewritermc.presentation.BytesControl"
                ScalarKind.Timestamp -> "com.typewritermc.presentation.DateTimeControl"
                ScalarKind.Duration -> "com.typewritermc.presentation.DurationControl"
                ScalarKind.Unit -> "com.typewritermc.presentation.Control"
            }
        }

        is TypeTemplate.Parameter -> {
            "com.typewritermc.presentation.Control"
        }

        is TypeTemplate.Named -> {
            val qualified = type?.declaration?.qualifiedName?.asString()
            val declaration = type?.declaration as? KSClassDeclaration
            val scalar = (type?.declaration as? KSClassDeclaration)?.valueClassScalarKind()
            when {
                qualified == COLOR_TYPE -> {
                    "com.typewritermc.presentation.ColorControl"
                }

                type?.declaration?.annotation(TYPEWRITER_STRING_ANNOTATION) != null -> {
                    "com.typewritermc.presentation.TextControl"
                }

                scalar != null -> {
                    presentationScopeClass(
                        TypeTemplate.Scalar(scalar),
                        (type.declaration as KSClassDeclaration).valueClassRepresentationType(),
                    )
                }

                qualified == REFERENCE_TYPE -> {
                    "com.typewritermc.presentation.LinkControl"
                }

                qualified in LIST_TYPES && type?.resourceLinksTargetType() != null -> {
                    "com.typewritermc.presentation.ResourceLinksControl"
                }

                qualified in LIST_TYPES -> {
                    "com.typewritermc.presentation.ListControl"
                }

                qualified in SET_TYPES -> {
                    "com.typewritermc.presentation.SetControl"
                }

                qualified in MAP_TYPES -> {
                    "com.typewritermc.presentation.MapControl"
                }

                declaration?.classKind == ClassKind.ENUM_CLASS -> {
                    "com.typewritermc.presentation.EnumControl"
                }

                declaration != null &&
                    (declaration.classKind == ClassKind.INTERFACE || Modifier.ABSTRACT in declaration.modifiers) -> {
                    "com.typewritermc.presentation.PolymorphicControl"
                }

                type != null && type.hasGeneratedPresentationImplementation() -> {
                    "com.typewritermc.presentation.RecordControl"
                }

                else -> {
                    "com.typewritermc.presentation.Control"
                }
            }
        }
    }

private fun presentationNestedScope(
    template: TypeTemplate,
    type: KSType?,
): String =
    if (template is TypeTemplate.Named && type != null && type.hasGeneratedPresentationImplementation()) {
        type.generatedPresentationScope()
    } else {
        presentationScope(template, type)
    }

private fun KSType.resourceLinksTargetType(): KSType? {
    if (declaration.qualifiedName?.asString() !in LIST_TYPES) return null
    val item = arguments.singleOrNull()?.type?.resolve() ?: return null
    if (item.declaration.qualifiedName?.asString() != REFERENCE_TYPE) return null
    return item.arguments
        .getOrNull(1)
        ?.type
        ?.resolve()
}

private fun KSType.hasGeneratedPresentationImplementation(): Boolean {
    val qualified = declaration.qualifiedName?.asString()
    val declarationClass = declaration as? KSClassDeclaration ?: return false
    return declaration.annotation(TYPEWRITER_STRING_ANNOTATION) == null &&
        declarationClass.valueClassScalarKind() == null &&
        qualified != REFERENCE_TYPE &&
        qualified !in LIST_TYPES &&
        qualified !in SET_TYPES &&
        qualified !in MAP_TYPES &&
        declarationClass.classKind != ClassKind.ENUM_CLASS &&
        declarationClass.classKind != ClassKind.INTERFACE &&
        Modifier.ABSTRACT !in declarationClass.modifiers
}

private fun KSType.generatedPresentationScope(): String {
    val classDeclaration = declaration as KSClassDeclaration
    val packageName = classDeclaration.packageName.asString()
    val scope = classDeclaration.generatedTypeName() + "PresentationScope"
    val base = if (packageName.isEmpty()) scope else "$packageName.$scope"
    return arguments.joinToString(
        prefix = base + if (arguments.isEmpty()) "" else "<",
        postfix = if (arguments.isEmpty()) "" else ">",
    ) { argument ->
        argument.type?.resolve()?.sourceType() ?: "kotlin.Any?"
    }
}

private fun KSType.generatedPresentationScopeImplementation(): String {
    val classDeclaration = declaration as KSClassDeclaration
    val packageName = classDeclaration.packageName.asString()
    val implementation = classDeclaration.generatedTypeName() + "PresentationScopeImpl"
    val base = if (packageName.isEmpty()) implementation else "$packageName.$implementation"
    return arguments.joinToString(
        prefix = base + if (arguments.isEmpty()) "" else "<",
        postfix = if (arguments.isEmpty()) "" else ">",
    ) { argument ->
        argument.type?.resolve()?.sourceType() ?: "kotlin.Any?"
    }
}

private fun presentationNestedScopes(
    template: TypeTemplate,
    type: KSType?,
): String {
    val entries =
        when (template) {
            is TypeTemplate.Nullable -> {
                listOf(
                    "com.typewritermc.presentation.NestedPresentationSlot.Values to " +
                        nestedPresentationDescriptor(template.value, type?.makeNotNullable()),
                )
            }

            is TypeTemplate.Named -> {
                val qualified = type?.declaration?.qualifiedName?.asString()
                when {
                    qualified in LIST_TYPES || qualified in SET_TYPES -> {
                        listOf(
                            "com.typewritermc.presentation.NestedPresentationSlot.Items to " +
                                nestedPresentationDescriptor(
                                    template.arguments.single(),
                                    type!!
                                        .arguments
                                        .single()
                                        .type
                                        ?.resolve(),
                                ),
                        )
                    }

                    qualified in MAP_TYPES -> {
                        listOf(
                            "com.typewritermc.presentation.NestedPresentationSlot.Keys to " +
                                nestedPresentationDescriptor(template.arguments[0], type!!.arguments[0].type?.resolve()),
                            "com.typewritermc.presentation.NestedPresentationSlot.Values to " +
                                nestedPresentationDescriptor(template.arguments[1], type.arguments[1].type?.resolve()),
                        )
                    }

                    type != null && type.hasGeneratedPresentationImplementation() -> {
                        listOf(
                            "com.typewritermc.presentation.NestedPresentationSlot.Fields to " +
                                nestedPresentationDescriptor(template, type),
                        )
                    }

                    else -> {
                        emptyList()
                    }
                }
            }

            is TypeTemplate.Parameter, is TypeTemplate.Scalar -> {
                emptyList()
            }
        }
    return entries.joinToString(prefix = "mapOf(", postfix = ")")
}

private fun nestedPresentationDescriptor(
    template: TypeTemplate,
    type: KSType?,
): String {
    if (template is TypeTemplate.Named && type != null && type.hasGeneratedPresentationImplementation()) {
        val scope = type.generatedPresentationScope()
        val scopeClass = scope.substringBefore('<')
        return "com.typewritermc.presentation.NestedPresentationScope(" +
            "$scopeClass::class as kotlin.reflect.KClass<$scope>, " +
            "{ nested -> ${type.generatedPresentationScopeImplementation()}(nested) })"
    }
    val scope = presentationNestedScope(template, type)
    val scopeClass = presentationScopeClass(template, type)
    val nested = presentationNestedScopes(template, type)
    return "com.typewritermc.presentation.NestedPresentationScope(" +
        "$scopeClass::class as kotlin.reflect.KClass<$scope>, nested = $nested)"
}

private fun representationKind(
    template: TypeTemplate,
    type: KSType? = null,
): RepresentationKind =
    when (template) {
        is TypeTemplate.Nullable -> {
            representationKind(template.value, type)
        }

        is TypeTemplate.Parameter -> {
            RepresentationKind.Record
        }

        is TypeTemplate.Named -> {
            val scalar = (type?.declaration as? KSClassDeclaration)?.valueClassScalarKind()
            when {
                type?.declaration?.annotation(TYPEWRITER_STRING_ANNOTATION) != null -> RepresentationKind.Text
                scalar != null -> representationKind(TypeTemplate.Scalar(scalar), null)
                type?.declaration?.qualifiedName?.asString() == REFERENCE_TYPE -> RepresentationKind.Link
                type?.declaration?.qualifiedName?.asString() in LIST_TYPES -> RepresentationKind.List
                type?.declaration?.qualifiedName?.asString() in SET_TYPES -> RepresentationKind.Set
                type?.declaration?.qualifiedName?.asString() in MAP_TYPES -> RepresentationKind.Map
                else -> RepresentationKind.Record
            }
        }

        is TypeTemplate.Scalar -> {
            when (template.kind) {
                ScalarKind.Unit -> RepresentationKind.Unit
                ScalarKind.Boolean -> RepresentationKind.Boolean
                ScalarKind.Text -> RepresentationKind.Text
                ScalarKind.Bytes -> RepresentationKind.Bytes
                is ScalarKind.Integer -> RepresentationKind.Integer
                is ScalarKind.Float -> RepresentationKind.Float
                ScalarKind.Decimal -> RepresentationKind.Decimal
                ScalarKind.Timestamp -> RepresentationKind.Timestamp
                ScalarKind.Duration -> RepresentationKind.Duration
            }
        }
    }

private fun draftProjectionDeclaration(
    name: String,
    definition: TypeDefinition,
    draftParameters: String,
    draftProjectionArguments: String,
): String {
    if (definition.representation !is RepresentationTemplate.Record) return ""
    if (definition.parameters.isEmpty()) {
        return """object ${name}DraftProjection : com.typewritermc.authoring.ReadProjection<${name}Draft> by
    com.typewritermc.authoring.draftViewProjection(${name}Definition.use, ::${name}Draft)"""
    }
    val arguments =
        definition.parameters.indices.joinToString { index ->
            "argument$index: com.typewritermc.authoring.ReadProjection<D$index>"
        }
    val uses = definition.parameters.indices.joinToString { index -> "argument$index.expected" }
    return """fun $draftParameters ${name}DraftProjection(
    $arguments,
): com.typewritermc.authoring.ReadProjection<${name}Draft$draftParameters> =
    com.typewritermc.authoring.draftViewProjection(
        ${name}Definition.applied(listOf($uses)),
    ) { binding -> ${name}Draft(binding, $draftProjectionArguments) }"""
}

private fun draftProjectionCode(
    template: TypeTemplate,
    type: KSType?,
    owner: TypeDefinitionId,
    nativeOwner: KSClassDeclaration,
    parameters: List<String>,
): String =
    when (template) {
        is TypeTemplate.Parameter -> {
            require(template.key.owner == owner)
            "argument${template.key.index}"
        }

        is TypeTemplate.Nullable -> {
            "com.typewritermc.authoring.nullableReadProjection(${draftProjectionCode(
                template.value,
                type?.makeNotNullable(),
                owner,
                nativeOwner,
                parameters,
            )})"
        }

        is TypeTemplate.Scalar -> {
            "com.typewritermc.authoring.nativeReadProjection<${configurationValueType(template, type)}>(" +
                "${template.generatedAppliedCode(owner, parameters)})"
        }

        is TypeTemplate.Named -> {
            val declaration = type?.declaration as? KSClassDeclaration
            val qualified = declaration?.qualifiedName?.asString()
            val expected = template.generatedAppliedCode(owner, parameters)
            val scalar = declaration?.valueClassScalarKind()
            when {
                declaration?.annotation(TYPEWRITER_STRING_ANNOTATION) != null -> {
                    "com.typewritermc.authoring.representationReadProjection<kotlin.String>(" +
                        "$expected, com.typewritermc.types.TypeUse.Scalar(com.typewritermc.types.ScalarKind.Text))"
                }

                scalar != null -> {
                    val native = declaration.valueClassRepresentationType()?.sourceType() ?: "kotlin.Any"
                    "com.typewritermc.authoring.representationReadProjection<$native>(" +
                        "$expected, com.typewritermc.types.TypeUse.Scalar(${scalar.kotlinCode()}))"
                }

                qualified in LIST_TYPES -> {
                    val itemType =
                        type!!
                            .arguments
                            .single()
                            .type
                            ?.resolve()
                    val item = draftProjectionCode(template.arguments.single(), itemType, owner, nativeOwner, parameters)
                    "com.typewritermc.authoring.listDraftProjection($expected, $item)"
                }

                qualified in SET_TYPES -> {
                    val itemType =
                        type!!
                            .arguments
                            .single()
                            .type
                            ?.resolve()
                    val item = draftProjectionCode(template.arguments.single(), itemType, owner, nativeOwner, parameters)
                    "com.typewritermc.authoring.setDraftProjection($expected, $item)"
                }

                qualified in MAP_TYPES -> {
                    val key =
                        draftProjectionCode(
                            template.arguments[0],
                            type!!.arguments[0].type?.resolve(),
                            owner,
                            nativeOwner,
                            parameters,
                        )
                    val value =
                        draftProjectionCode(
                            template.arguments[1],
                            type.arguments[1].type?.resolve(),
                            owner,
                            nativeOwner,
                            parameters,
                        )
                    "com.typewritermc.authoring.mapDraftProjection($expected, $key, $value)"
                }

                qualified == REFERENCE_TYPE || declaration?.classKind == ClassKind.ENUM_CLASS -> {
                    val native = type?.nativeType(nativeOwner) ?: "kotlin.Any"
                    "com.typewritermc.authoring.nativeReadProjection<$native>($expected)"
                }

                declaration != null -> {
                    val packageName = qualified?.substringBeforeLast('.', "").orEmpty()
                    val projection = declaration.simpleName.asString() + "DraftProjection"
                    val reference = if (packageName.isEmpty()) projection else "$packageName.$projection"
                    val arguments =
                        template.arguments.mapIndexed { index, argument ->
                            draftProjectionCode(
                                argument,
                                type.arguments[index].type?.resolve(),
                                owner,
                                nativeOwner,
                                parameters,
                            )
                        }
                    if (arguments.isEmpty()) reference else "$reference(${arguments.joinToString()})"
                }

                else -> {
                    "com.typewritermc.authoring.nativeReadProjection<kotlin.Any>($expected)"
                }
            }
        }
    }

private fun draftType(
    type: KSType,
    owner: KSClassDeclaration,
    explicitParameterNullable: Boolean = false,
): String {
    val declaration = type.declaration
    val qualified = declaration.qualifiedName?.asString()
    val result =
        when {
            declaration is com.google.devtools.ksp.symbol.KSTypeParameter -> {
                "D${owner.typeParameters.indexOf(declaration).coerceAtLeast(0)}"
            }

            declaration.annotation(TYPEWRITER_STRING_ANNOTATION) != null -> {
                "kotlin.String"
            }

            (declaration as? KSClassDeclaration)?.valueClassScalarKind() != null -> {
                (declaration as KSClassDeclaration).valueClassRepresentationType()?.sourceType() ?: "kotlin.Any"
            }

            qualified in PRIMITIVE_TYPES -> {
                type.toTypeName().copy(nullable = false).toString()
            }

            qualified in LIST_TYPES -> {
                val item = type.arguments.single().type!!
                "com.typewritermc.authoring.DraftList<${draftType(item.resolve(), owner, item.explicitNullable)}>"
            }

            qualified in SET_TYPES -> {
                val item = type.arguments.single().type!!
                "com.typewritermc.authoring.DraftSet<${draftType(item.resolve(), owner, item.explicitNullable)}>"
            }

            qualified in MAP_TYPES -> {
                val key = type.arguments[0].type!!
                val value = type.arguments[1].type!!
                "com.typewritermc.authoring.MapDraft<${draftType(
                    key.resolve(),
                    owner,
                    key.explicitNullable,
                )}, ${draftType(value.resolve(), owner, value.explicitNullable)}>"
            }

            qualified == REFERENCE_TYPE -> {
                type.makeNotNullable().nativeType(owner)
            }

            else -> {
                "${declaration.qualifiedName?.asString()}Draft${type.arguments.joinToString(
                    prefix = if (type.arguments.isEmpty()) "" else "<",
                    postfix = if (type.arguments.isEmpty()) "" else ">",
                ) { argument ->
                    val reference = argument.type!!
                    draftType(reference.resolve(), owner, reference.explicitNullable)
                }}"
            }
        }
    val nullable =
        if (declaration is com.google.devtools.ksp.symbol.KSTypeParameter) {
            explicitParameterNullable
        } else {
            type.nullability.name ==
                "NULLABLE"
        }
    return result + if (nullable) "?" else ""
}

private fun EndpointBindingTemplate.code(): String =
    "com.typewritermc.types.EndpointBindingTemplate(" +
        "endpoint = com.typewritermc.types.EndpointId(${endpoint.value.kotlinLiteral()}), " +
        "containingResource = ${containingResource.kotlinCode()}, " +
        "valueOwner = ${valueOwner.kotlinCode()}, " +
        "relativePath = ${relativePath.code()}, " +
        "target = ${target.kotlinCode()}, " +
        "containsCollection = $containsCollection)"

private fun RelativeFieldPattern.code(): String =
    "com.typewritermc.configuration.RelativeFieldPattern(listOf(${segments.joinToString { it.code() }}))"

private fun FieldPatternSegment.code(): String =
    when (this) {
        is FieldPatternSegment.Field -> {
            "com.typewritermc.configuration.FieldPatternSegment.Field(${name.kotlinLiteral()})"
        }

        FieldPatternSegment.Items -> {
            "com.typewritermc.configuration.FieldPatternSegment.Items"
        }

        FieldPatternSegment.Keys -> {
            "com.typewritermc.configuration.FieldPatternSegment.Keys"
        }

        FieldPatternSegment.Values -> {
            "com.typewritermc.configuration.FieldPatternSegment.Values"
        }
    }

private fun TypeTemplate.generatedAppliedCode(
    owner: TypeDefinitionId,
    parameters: List<String>,
): CodeBlock {
    val bindings =
        TypeParameterBindings.from(
            parameters.indices.associate { index ->
                ParameterKey(owner, index) to CodeBlock.of("argument%L.expected", index)
            },
        )
    return with(bindings) { appliedUseCode() }
}

private fun TypeTemplate.generatedNativeAppliedCode(owner: TypeDefinitionId): CodeBlock {
    val bindings =
        TypeParameterBindings.from(
            parameterKeys().associateWith { key ->
                require(key.owner == owner)
                CodeBlock.of("arguments.portable[%L]", key.index)
            },
        )
    return with(bindings) { appliedUseCode() }
}

private fun TypeTemplate.containsParameter(): Boolean =
    when (this) {
        is TypeTemplate.Parameter -> true
        is TypeTemplate.Named -> arguments.any(TypeTemplate::containsParameter)
        is TypeTemplate.Nullable -> value.containsParameter()
        is TypeTemplate.Scalar -> false
    }

private fun fieldPath(name: String): String =
    "com.typewritermc.authoring.ValuePath(listOf(com.typewritermc.authoring.PathSegment.Field(${name.kotlinLiteral()})))"

private fun draftEditMethods(
    field: OwnedFieldDeclaration,
    property: KSPropertyDeclaration?,
    owner: TypeDefinitionId,
    parameters: List<String>,
): String {
    val valueType =
        property
            ?.type
            ?.let { reference -> reference.resolve().sourceType(reference.explicitNullable) }
            ?: "com.typewritermc.authoring.PortableValue"
    val expected = field.template.generatedAppliedCode(owner, parameters)
    val suffix = field.sourceName.replaceFirstChar(Char::uppercaseChar)
    return """
    @OptIn(com.typewritermc.authoring.GeneratedEditApi::class)
    context(edits: com.typewritermc.authoring.EditContext)
    suspend fun set$suffix(value: $valueType) {
        edits.set(
            binding.exactEditablePath(${fieldPath(field.name)}, $expected),
            value,
        )
    }

    @OptIn(com.typewritermc.authoring.GeneratedEditApi::class)
    context(edits: com.typewritermc.authoring.EditContext)
    suspend fun clear$suffix() {
        edits.clear<$valueType>(
            binding.exactEditablePath(${fieldPath(field.name)}, $expected),
        )
    }
""".trimEnd()
}

private fun fieldPattern(name: String): String =
    "com.typewritermc.configuration.RelativeFieldPattern(listOf(com.typewritermc.configuration.FieldPatternSegment.Field(\"$name\")))"

private fun KSClassDeclaration.isTypeGraphReady(): Boolean {
    val references =
        sequence {
            yieldAll(superTypes)
            typeParameters.forEach { parameter -> yieldAll(parameter.bounds) }
            primaryConstructor?.parameters?.forEach { parameter -> yield(parameter.type) }
            declarations.filterIsInstance<KSPropertyDeclaration>().forEach { property -> yield(property.type) }
        }
    return references.all { reference -> runCatching { reference.resolve().isResolvedTypeGraph() }.getOrDefault(false) }
}

private fun KSType.isResolvedTypeGraph(): Boolean =
    !isError && arguments.all { argument -> argument.type?.resolve()?.isResolvedTypeGraph() == true }

private const val TYPEWRITER_TYPE_ANNOTATION = "com.typewritermc.types.TypewriterType"
private const val TYPEWRITER_DISPLAY_ANNOTATION = "com.typewritermc.types.TypewriterDisplay"
private const val TYPEWRITER_TYPE_IMPORTS_ANNOTATION = "com.typewritermc.types.TypewriterTypeImports"
private const val TYPEWRITER_STRING_ANNOTATION = "com.typewritermc.types.TypewriterString"
private const val JVM_INLINE_ANNOTATION = "kotlin.jvm.JvmInline"
private const val COLOR_TYPE = "com.typewritermc.types.Color"
private const val REFERENCE_CONTRACT_ANNOTATION = "com.typewritermc.types.ReferenceContract"
private const val RESOURCE_DEFINITION_ANNOTATION = "com.typewritermc.authoring.TypewriterResourceDefinition"
private const val DELETION_POLICY_ANNOTATION = "com.typewritermc.types.DeletionPolicy"
private const val RELATION_FAMILY_ANNOTATION = "com.typewritermc.types.TypewriterRelationFamily"
private const val ONE_ENDPOINT = "com.typewritermc.types.One"
private const val MANY_ENDPOINT = "com.typewritermc.types.Many"
private const val RESOURCE_TYPE = "com.typewritermc.types.Resource"
private const val REFERENCE_TYPE = "com.typewritermc.types.Ref"
private const val ARTIFACT_OPTION = "typewriter.artifactId"
private const val SOURCE_PART_OPTION = "typewriter.sourcePart"
private const val CLAIM_DEPENDENCY_CLOSURE_OPTION = "typewriter.claimDependencyClosure"
private const val PROVIDER_INDEX = "META-INF/typewriter/generated-providers"

private val PRIMITIVE_TYPES =
    setOf(
        "kotlin.Unit",
        "kotlin.Boolean",
        "kotlin.String",
        "kotlin.Byte",
        "kotlin.Short",
        "kotlin.Int",
        "kotlin.Long",
        "kotlin.UByte",
        "kotlin.UShort",
        "kotlin.UInt",
        "kotlin.ULong",
        "kotlin.Float",
        "kotlin.Double",
        "java.math.BigInteger",
        "java.math.BigDecimal",
        "kotlin.time.Instant",
        "java.time.Instant",
        "kotlin.time.Duration",
        "java.time.Duration",
        "kotlin.ByteArray",
    )
private val LIST_TYPES = setOf("kotlin.collections.List", "kotlin.collections.MutableList", "kotlin.collections.ArrayList")
private val SET_TYPES =
    setOf("kotlin.collections.Set", "kotlin.collections.MutableSet", "kotlin.collections.HashSet", "kotlin.collections.LinkedHashSet")
private val MAP_TYPES =
    setOf("kotlin.collections.Map", "kotlin.collections.MutableMap", "kotlin.collections.HashMap", "kotlin.collections.LinkedHashMap")
