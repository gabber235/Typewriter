package com.typewritermc.engine.runtime

import com.typewritermc.extensions.ExtensionActivator
import com.typewritermc.imprint.TypewriterExtensionManifest
import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.cbor.Cbor
import kotlinx.serialization.decodeFromByteArray
import kotlin.reflect.full.createInstance
import kotlin.reflect.full.isSubclassOf

/**
 * Instantiates extension activators recorded by compile time discovery in extension manifests.
 *
 * Resources and activators are sorted deterministically. Duplicate class references across manifests are activated once.
 * Every activator must be a Kotlin class implementing [ExtensionActivator] with a constructor supported by
 * `createInstance`, otherwise loading fails before the deployment becomes active.
 */
@OptIn(ExperimentalSerializationApi::class)
class GeneratedActivatorLoader {
    fun load(
        classLoader: ClassLoader,
        targets: List<String>,
    ): List<ExtensionActivator> = targets.flatMap { target -> loadTarget(classLoader, target) }

    private fun loadTarget(
        classLoader: ClassLoader,
        target: String,
    ): List<ExtensionActivator> {
        val resourceName = "META-INF/typewriter/extension.cbor"
        return classLoader
            .getResources(resourceName)
            .asSequence()
            .sortedBy { it.toExternalForm() }
            .flatMap { resource ->
                resource.openStream().use { input ->
                    Cbor.Default.decodeFromByteArray<TypewriterExtensionManifest>(input.readBytes()).activators
                }
            }.filter { it.sourceSet == target }
            .distinctBy { it.className }
            .sortedBy { it.className }
            .map { activator ->
                val type = classLoader.loadClass(activator.className).kotlin
                require(type.isSubclassOf(ExtensionActivator::class)) {
                    "Generated activator does not implement ExtensionActivator: ${activator.className}"
                }
                type.createInstance() as ExtensionActivator
            }.toList()
    }
}
