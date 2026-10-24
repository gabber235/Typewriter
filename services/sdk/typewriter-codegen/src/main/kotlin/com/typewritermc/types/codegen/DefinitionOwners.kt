package com.typewritermc.types.codegen

import com.google.devtools.ksp.getClassDeclarationByName
import com.google.devtools.ksp.processing.KSPLogger
import com.google.devtools.ksp.processing.Resolver
import com.google.devtools.ksp.symbol.KSClassDeclaration
import com.google.devtools.ksp.symbol.KSNode
import com.squareup.kotlinpoet.ClassName
import com.squareup.kotlinpoet.asClassName
import com.squareup.kotlinpoet.ksp.toClassName
import com.typewritermc.codegen.DefinitionReferences
import com.typewritermc.codegen.referencedIds
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.TypeDefinition
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.TypeId
import com.typewritermc.types.TypeTemplate
import com.typewritermc.types.TypeUse
import com.typewritermc.types.codegen.emit.SdkRelation
import com.typewritermc.types.ksp.KspTypeConversionResult
import com.typewritermc.types.ksp.RELATION_LINK_NAMESPACE

/**
 * Finds the generated object that owns each type definition id, so generated code references ids instead of
 * restating them.
 *
 * Owners are the generated definitions of declarations this compilation emits ([emittedHere]) or a dependency
 * already generated, the builtin collection objects of [StandardTypes], and the link definitions nested in relation
 * endpoints. An id without an owner is a declaration problem: the deployed catalog would miss its definition too.
 */
internal class DefinitionOwners(
    private val logger: KSPLogger,
    private val emittedHere: (KSClassDeclaration) -> Boolean,
) {
    /** References for code emitted from [conversion], or null after reporting unowned ids at [origin]. */
    context(_: Resolver)
    fun references(
        conversion: KspTypeConversionResult.Success,
        origin: KSNode,
        extra: Set<TypeDefinitionId> = emptySet(),
    ): DefinitionReferences? =
        references(conversion.declarations, conversion.definitions.flatMap(TypeDefinition::referencedIds).toSet() + extra, origin)

    /** References for code that mentions [referenced] ids, whose declarations are [declarations]. */
    context(resolver: Resolver)
    fun references(
        declarations: Map<TypeDefinitionId, KSClassDeclaration>,
        referenced: Set<TypeDefinitionId>,
        origin: KSNode,
    ): DefinitionReferences? {
        val owners = mutableMapOf<TypeDefinitionId, ClassName>()
        declarations.forEach { (id, declaration) ->
            val definition = SdkNames.of(declaration).definition
            if (emittedHere(declaration) || resolver.getClassDeclarationByName(definition.canonicalName) != null) owners[id] = definition
        }
        owners[StandardTypes.list] = StandardTypes.List::class.asClassName()
        owners[StandardTypes.set] = StandardTypes.Set::class.asClassName()
        owners[StandardTypes.map] = StandardTypes.Map::class.asClassName()
        referenced
            .filterNot(owners::containsKey)
            .forEach { id ->
                val link = (id.type as? TypeId.Qualified)?.takeIf { it.namespace == RELATION_LINK_NAMESPACE } ?: return@forEach
                resolver.getClassDeclarationByName(link.name)?.let { endpoint ->
                    owners[id] = endpoint.toClassName().nestedClass(SdkRelation.LINK_DEFINITION)
                }
            }
        val missing = referenced.filterNot(owners::containsKey)
        missing.forEach { id ->
            logger.error(
                "Type ${id.describe()} has no generated definition; declare it with @TypewriterType or import it with @TypewriterTypeImports.",
                origin,
            )
        }
        return DefinitionReferences(owners).takeIf { missing.isEmpty() }
    }
}

/** Every definition id a template mentions. */
internal fun TypeTemplate.referencedIds(): Set<TypeDefinitionId> =
    when (this) {
        is TypeTemplate.Named -> setOf(definition) + arguments.flatMap { it.referencedIds() }
        is TypeTemplate.Nullable -> value.referencedIds()
        is TypeTemplate.Parameter -> setOf(key.owner)
        is TypeTemplate.Scalar -> emptySet()
    }

/** Every definition id a type use mentions. */
internal fun TypeUse.referencedIds(): Set<TypeDefinitionId> =
    when (this) {
        is TypeUse.Named -> setOf(definition) + arguments.flatMap { it.referencedIds() }
        is TypeUse.Nullable -> value.referencedIds()
        is TypeUse.Scalar -> emptySet()
    }

/** `namespace/qualified.Name` or the declared UUID, as authors write and read type identities. */
internal fun TypeDefinitionId.describe(): String =
    when (val identity = type) {
        is TypeId.Declared -> identity.id.toString()
        is TypeId.Qualified -> "${identity.namespace}/${identity.name}"
    }
