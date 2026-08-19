package com.typewritermc.engine.runtime

import com.typewritermc.extensions.ExtensionActivator
import java.io.BufferedReader
import java.io.InputStreamReader

class GeneratedActivatorLoader {
    fun load(
        classLoader: ClassLoader,
        targets: List<String>,
    ): List<ExtensionActivator> = targets.flatMap { target -> loadTarget(classLoader, target) }

    private fun loadTarget(
        classLoader: ClassLoader,
        target: String,
    ): List<ExtensionActivator> {
        val resourceName = "META-INF/typewriter/activators/$target.index"
        return classLoader
            .getResources(resourceName)
            .toList()
            .sortedBy { it.toExternalForm() }
            .flatMap { resource ->
                resource.openStream().use { input ->
                    BufferedReader(InputStreamReader(input)).readLines()
                }
            }.filter(String::isNotBlank)
            .distinct()
            .sorted()
            .map { className ->
                val type = classLoader.loadClass(className)
                require(ExtensionActivator::class.java.isAssignableFrom(type)) {
                    "Generated activator does not implement ExtensionActivator: $className"
                }
                type.getDeclaredConstructor().newInstance() as ExtensionActivator
            }
    }
}
