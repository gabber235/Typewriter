package com.typewritermc.engine.runtime

import com.typewritermc.loader.api.HostedDeploymentContext
import com.typewritermc.loader.api.HostedExtensionArtifact
import com.typewritermc.loader.api.RuntimePlacement
import com.typewritermc.loader.api.SourcePartDisposition
import java.net.URL
import java.util.Collections
import java.util.Enumeration

/**
 * The class loader this deployment's extension code loads under: [engine] first, then the class loader of each Paper
 * plugin a part loaded here uses, found through the host's plugins. Extension code thereby reaches the plugins it
 * compiled against while Typewriter's own plugin declares none. Without such parts it is [engine] itself.
 *
 * A loaded part whose plugin the host no longer enables refuses the deployment: the Realm projected it while the
 * plugin was enabled, and the next projection drops the part.
 */
internal fun HostedDeploymentContext.extensionClassLoader(engine: ClassLoader): ClassLoader {
    val plugins = linkedMapOf<String, ClassLoader>()
    artifacts.extensions.forEach { extension ->
        val loaded = extension.eligibleParts(identity.placement)
        extension.manifest.sourceParts
            .filter { it.name in loaded }
            .forEach { part ->
                part.plugins.forEach { plugin ->
                    plugins.getOrPut(plugin.name) {
                        host.plugins.classLoader(plugin.name)
                            ?: error(
                                "Source part ${part.name} of ${extension.id} needs the ${plugin.name} plugin, which this host has not enabled.",
                            )
                    }
                }
            }
    }
    return if (plugins.isEmpty()) engine else PluginBridgeClassLoader(engine, plugins.values.toList())
}

/** The names of this extension's source parts the Realm made eligible on [placement]. */
internal fun HostedExtensionArtifact.eligibleParts(placement: RuntimePlacement): Set<String> =
    sourceParts.mapNotNullTo(linkedSetOf()) { part ->
        val eligible = part.disposition as? SourcePartDisposition.Eligible
        part.name.takeIf { eligible != null && placement in eligible.placements }
    }

/** Resolves classes and resources from its parent first, then from each of [plugins] in order. */
private class PluginBridgeClassLoader(
    parent: ClassLoader,
    private val plugins: List<ClassLoader>,
) : ClassLoader(parent) {
    override fun findClass(name: String): Class<*> {
        val missing = ClassNotFoundException(name)
        plugins.forEach { plugin ->
            try {
                return plugin.loadClass(name)
            } catch (miss: ClassNotFoundException) {
                missing.addSuppressed(miss)
            }
        }
        throw missing
    }

    override fun findResource(name: String): URL? = plugins.firstNotNullOfOrNull { it.getResource(name) }

    override fun findResources(name: String): Enumeration<URL> =
        Collections.enumeration(plugins.flatMap { Collections.list(it.getResources(name)) })
}
