package com.typewritermc.discovery.runtime

import com.typewritermc.discovery.AssembledTypeDiscovery
import com.typewritermc.discovery.DiscoveryDomainId
import com.typewritermc.types.CatalogAbstractTypePrototype
import com.typewritermc.types.CatalogMetadataTypePrototype
import com.typewritermc.types.NominalTypeKind
import com.typewritermc.types.ResolvedTypeRef
import com.typewritermc.types.TypeExpression
import com.typewritermc.types.TypeId
import com.typewritermc.types.TypePrototype
import com.typewritermc.types.TypePrototypeProvider
import com.typewritermc.types.TypePrototypeRegistry
import kotlin.reflect.KClass

/**
 * Builds runtime codecs from assembled discovery using the deployment class loader.
 *
 * Concrete providers are filtered by domain and checked against the advertised type reference. Abstract
 * definitions use catalog backed prototypes and qualified runtime names. Missing classes, invalid providers, or
 * conflicting registry entries fail loading; this loader does not own the supplied class loader.
 */
class PrototypeRegistryLoader {
    /**
     * Resolves concrete providers and catalog backed abstract prototypes for one deployment domain.
     *
     * The supplied class loader remains owned by the caller. Every advertised concrete provider must resolve to
     * the exact type it advertises; abstract runtime classes are loaded from their qualified type identities.
     */
    fun load(
        discovery: AssembledTypeDiscovery,
        domain: DiscoveryDomainId,
        classLoader: ClassLoader,
    ): TypePrototypeRegistry {
        val concrete =
            discovery.prototypeBindings
                .filter { domain in it.domains }
                .map { binding ->
                    val providerClass = Class.forName(binding.prototypeProviderClass, true, classLoader)
                    require(TypePrototypeProvider::class.java.isAssignableFrom(providerClass)) {
                        "Prototype provider ${binding.prototypeProviderClass} does not implement TypePrototypeProvider."
                    }
                    val provider = providerClass.getDeclaredConstructor().newInstance() as TypePrototypeProvider
                    provider.prototype().also { prototype ->
                        require(prototype.type == binding.type) {
                            "Prototype provider ${binding.prototypeProviderClass} returned ${prototype.type} instead of ${binding.type}."
                        }
                    }
                }
        val abstracts =
            discovery.catalog.definitions
                .filter { definition ->
                    definition.kind != NominalTypeKind.CONCRETE &&
                        definition.id.id is TypeId.Qualified &&
                        concrete.any { prototype ->
                            discovery.catalog.isDescendant(prototype.definition, definition.id.id)
                        }
                }.map { definition ->
                    val identity = definition.id.id as TypeId.Qualified
                    val runtimeClass = Class.forName(identity.jvmName(), false, classLoader).kotlin
                    @Suppress("UNCHECKED_CAST")
                    CatalogAbstractTypePrototype<Any>(
                        runtimeType = runtimeClass as KClass<Any>,
                        type = definition.id,
                        definition = definition,
                        serializedFieldNames =
                            discovery.catalog
                                .fieldNames(definition)
                                .filter { field -> runtimeClass.java.hasPropertyGetter(field) }
                                .associateWith { it },
                    ) as TypePrototype<*>
                }
        val boundTypes = concrete.mapTo(mutableSetOf()) { it.type }
        val concreteRuntimeTypes = concrete.mapTo(mutableSetOf()) { it.runtimeType }
        val metadata =
            discovery.catalog.definitions
                .filter { definition ->
                    definition.kind == NominalTypeKind.CONCRETE &&
                        definition.id.id is TypeId.Qualified &&
                        definition.id !in boundTypes
                }.mapNotNull { definition ->
                    val identity = definition.id.id as TypeId.Qualified
                    val runtimeClass =
                        runCatching { Class.forName(identity.jvmName(), false, classLoader).kotlin }.getOrNull()
                            ?: return@mapNotNull null
                    if (runtimeClass in concreteRuntimeTypes) return@mapNotNull null

                    @Suppress("UNCHECKED_CAST")
                    CatalogMetadataTypePrototype<Any>(
                        runtimeType = runtimeClass as KClass<Any>,
                        type = definition.id,
                        definition = definition,
                        serializedFieldNames =
                            discovery.catalog
                                .fieldNames(definition)
                                .filter { field -> runtimeClass.java.hasPropertyGetter(field) }
                                .associateWith { it },
                    ) as TypePrototype<*>
                }
        return TypePrototypeRegistry(concrete + abstracts + metadata, discovery.catalog.definitions)
    }
}

private fun Class<*>.hasPropertyGetter(field: String): Boolean {
    val suffix = field.replaceFirstChar { character -> character.titlecase() }
    return methods.any { method -> method.parameterCount == 0 && method.name in setOf("get$suffix", "is$suffix") }
}

private fun com.typewritermc.types.TypeCatalog.fieldNames(
    definition: com.typewritermc.types.TypeDefinition,
    visited: Set<ResolvedTypeRef> = emptySet(),
): Set<String> {
    if (definition.id in visited) return emptySet()
    val own = (definition.representation as? TypeExpression.Record)?.fields?.mapTo(mutableSetOf()) { it.name }.orEmpty()
    val next = visited + definition.id
    return definition.parents.fold(own) { fields, parent ->
        val inherited = definitions.singleOrNull { it.id == parent }?.let { fieldNames(it, next) }.orEmpty()
        fields + inherited
    }
}

private fun com.typewritermc.types.TypeCatalog.isDescendant(
    candidate: com.typewritermc.types.TypeDefinition,
    target: TypeId,
    visited: Set<TypeId> = emptySet(),
): Boolean {
    if (candidate.id.id in visited) return false
    if (candidate.parents.any { it.id == target }) return true
    val next = visited + candidate.id.id
    return candidate.parents.any { parent ->
        definitions.singleOrNull { it.id.id == parent.id }?.let { isDescendant(it, target, next) } == true
    }
}

private fun TypeId.Qualified.jvmName(): String = "$namespace.$name"
