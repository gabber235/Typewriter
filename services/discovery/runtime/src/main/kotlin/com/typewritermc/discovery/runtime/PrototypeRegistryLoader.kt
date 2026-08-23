package com.typewritermc.discovery.runtime

import com.typewritermc.discovery.AssembledTypeDiscovery
import com.typewritermc.discovery.DiscoveryDomainId
import com.typewritermc.types.CatalogAbstractTypePrototype
import com.typewritermc.types.NominalTypeKind
import com.typewritermc.types.TypeId
import com.typewritermc.types.TypePrototype
import com.typewritermc.types.TypePrototypeProvider
import com.typewritermc.types.TypePrototypeRegistry
import kotlin.reflect.KClass

class PrototypeRegistryLoader {
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
                .filter { it.kind != NominalTypeKind.CONCRETE }
                .map { definition ->
                    val identity = definition.id.id
                    require(identity is TypeId.Qualified) { "Abstract type identities must be qualified names." }
                    val runtimeClass = Class.forName(identity.jvmName(), false, classLoader).kotlin
                    @Suppress("UNCHECKED_CAST")
                    CatalogAbstractTypePrototype<Any>(
                        runtimeType = runtimeClass as KClass<Any>,
                        type = definition.id,
                        definition = definition,
                    ) as TypePrototype<*>
                }
        return TypePrototypeRegistry(concrete + abstracts)
    }
}

private fun TypeId.Qualified.jvmName(): String = "$namespace.$name"
