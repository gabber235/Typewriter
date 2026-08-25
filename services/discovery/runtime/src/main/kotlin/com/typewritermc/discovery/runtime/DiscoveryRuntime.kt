package com.typewritermc.discovery.runtime

import com.typewritermc.discovery.AssembledTypeDiscovery
import com.typewritermc.discovery.ContributionKey
import com.typewritermc.discovery.DeploymentFacts
import com.typewritermc.discovery.DiscoveryDomainId
import com.typewritermc.discovery.DiscoveryDomains
import com.typewritermc.discovery.KeyedExecutableBinding
import com.typewritermc.types.TypePrototypeRegistry
import kotlinx.coroutines.CoroutineScope
import org.koin.core.KoinApplication
import org.koin.core.module.Module
import org.koin.dsl.koinApplication
import java.net.URL
import java.net.URLClassLoader

interface GeneratedDiscoveryModule {
    fun module(contribution: ContributionKey): Module
}

interface RuntimeScope {
    val coroutineScope: CoroutineScope
    val prototypes: TypePrototypeRegistry
    val facts: DeploymentFacts

    fun own(cleanup: suspend () -> Unit)

    fun <Resource : AutoCloseable> own(resource: Resource): Resource
}

interface RuntimeRegistrar {
    context(scope: RuntimeScope)
    suspend fun register()
}

@Target(AnnotationTarget.CLASS)
@Retention(AnnotationRetention.BINARY)
annotation class TypewriterRegistrar(
    val id: String,
    val realm: Boolean = false,
    val execution: Boolean = true,
)

data class DiscoveryArtifactPackage(
    val artifacts: List<URL>,
    val selectedEngine: com.typewritermc.imprint.ArtifactId?,
    val selectedExtensions: Set<com.typewritermc.imprint.ArtifactId>,
    val facts: DeploymentFacts,
)

class DiscoveryDeployment(
    val domain: DiscoveryDomainId,
    val application: KoinApplication,
    val prototypes: TypePrototypeRegistry,
    val facts: DeploymentFacts,
    private val classLoader: URLClassLoader,
) : AutoCloseable {
    override fun close() {
        val failures = mutableListOf<Throwable>()
        runCatching { application.close() }.exceptionOrNull()?.let(failures::add)
        runCatching { classLoader.close() }.exceptionOrNull()?.let(failures::add)
        if (failures.isNotEmpty()) {
            val failure = failures.first()
            failures.drop(1).forEach(failure::addSuppressed)
            throw failure
        }
    }
}

class DiscoveryModuleLoader {
    fun load(
        artifactPackage: DiscoveryArtifactPackage,
        domain: DiscoveryDomainId,
        discovery: AssembledTypeDiscovery,
        parentClassLoader: ClassLoader = requireNotNull(javaClass.classLoader),
    ): DiscoveryDeployment {
        require(domain == DiscoveryDomains.Realm || domain == DiscoveryDomains.Execution) {
            "Unsupported discovery domain ${domain.value}."
        }
        val classLoader = URLClassLoader(artifactPackage.artifacts.toTypedArray(), parentClassLoader)
        var application: KoinApplication? = null
        return try {
            val modules =
                discovery.executableBindings
                    .asSequence()
                    .filter { it.binding.domain == domain }
                    .sortedBy { it.binding.localName }
                    .map { loadModule(classLoader, it) }
                    .toList()
            application =
                koinApplication {
                    allowOverride(false)
                    modules(modules)
                }
            val prototypes = PrototypeRegistryLoader().load(discovery, domain, classLoader)
            DiscoveryDeployment(domain, requireNotNull(application), prototypes, artifactPackage.facts, classLoader)
        } catch (failure: Throwable) {
            runCatching { application?.close() }.exceptionOrNull()?.let(failure::addSuppressed)
            runCatching { classLoader.close() }.exceptionOrNull()?.let(failure::addSuppressed)
            throw failure
        }
    }

    private fun loadModule(
        classLoader: ClassLoader,
        keyed: KeyedExecutableBinding,
    ): Module {
        val binding = keyed.binding
        val providerClass = Class.forName(binding.moduleProviderClass, true, classLoader)
        require(GeneratedDiscoveryModule::class.java.isAssignableFrom(providerClass)) {
            "Discovery module provider ${binding.moduleProviderClass} does not implement GeneratedDiscoveryModule."
        }
        val constructor = providerClass.getDeclaredConstructor()
        require(
            java.lang.reflect.Modifier
                .isPublic(constructor.modifiers),
        ) {
            "Discovery module provider ${binding.moduleProviderClass} requires a public zero argument constructor."
        }
        return (constructor.newInstance() as GeneratedDiscoveryModule).module(keyed.key)
    }
}
