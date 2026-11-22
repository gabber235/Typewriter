package com.typewritermc.engine.runtime.testing

import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ArtifactKind
import com.typewritermc.imprint.ArtifactRequirement
import com.typewritermc.imprint.ArtifactVersion
import com.typewritermc.imprint.CommonExtensionSourcePart
import com.typewritermc.imprint.EnabledPlugin
import com.typewritermc.imprint.EngineExtensionSourcePart
import com.typewritermc.imprint.ExtensionManifest
import com.typewritermc.imprint.PluginRequirement
import com.typewritermc.imprint.ResolvedArtifact
import com.typewritermc.imprint.VersionConstraint
import com.typewritermc.loader.api.HostPlugins
import com.typewritermc.loader.api.HostedDeploymentContext
import com.typewritermc.loader.api.HostedExtensionArtifact
import com.typewritermc.loader.api.HostedRuntimeHost
import com.typewritermc.loader.api.HostedSourcePart
import com.typewritermc.loader.api.RuntimePlacement
import com.typewritermc.loader.api.SourcePartDisposition
import java.net.URLClassLoader
import java.nio.file.Files
import java.nio.file.Path

/** Stands in for a class of a plugin's API: [pluginClassLoader] holds it apart from the test class path. */
class PluginApiStandIn

/** A class loader of a plugin whose only class is [PluginApiStandIn], seen by no other class loader of the test. */
fun pluginClassLoader(): ClassLoader {
    val path = PluginApiStandIn::class.java.name.replace('.', '/') + ".class"
    val root = Files.createTempDirectory("plugin-classes")
    val target = root.resolve(path)
    Files.createDirectories(target.parent)
    requireNotNull(PluginApiStandIn::class.java.getResourceAsStream("/$path")).use { Files.copy(it, target) }
    return URLClassLoader(arrayOf(root.toUri().toURL()), ClassLoader.getPlatformClassLoader())
}

/**
 * A primary engine deployment of extension `fixture:integrations`, whose part `vault` uses the `Vault` plugin and
 * part `paper` uses none. Only the parts in [loadedParts] are eligible on this engine, and the host has [enabled]
 * the plugins it maps to their class loaders.
 */
fun pluginDeploymentContext(
    loadedParts: Set<String>,
    enabled: Map<String, ClassLoader>,
): HostedDeploymentContext {
    val base = deploymentContext(RuntimePlacement.PRIMARY_ENGINE, RuntimePlacement.PRIMARY_ENGINE)
    val engine = base.artifacts.runtimeArtifact.manifest
    val paper = ResolvedArtifact(engine.id, engine.version, ArtifactKind.ENGINE)
    val requirement = ArtifactRequirement(engine.id, VersionConstraint("^1"))
    val manifest =
        ExtensionManifest(
            id = ArtifactId("fixture:integrations"),
            version = ArtifactVersion("1.0.0"),
            sourceParts =
                listOf(
                    CommonExtensionSourcePart(),
                    EngineExtensionSourcePart("paper", requirement, paper),
                    EngineExtensionSourcePart("vault", requirement, paper, plugins = listOf(PluginRequirement("Vault"))),
                ),
            buildProvenance = emptyList(),
            contributions = emptyList(),
        )
    val extension =
        HostedExtensionArtifact(
            id = manifest.id,
            path = Path.of("integrations.jar"),
            manifest = manifest,
            sourceParts =
                listOf("paper", "vault").map { part ->
                    HostedSourcePart(
                        part,
                        if (part in loadedParts) {
                            SourcePartDisposition.Eligible(setOf(RuntimePlacement.PRIMARY_ENGINE))
                        } else {
                            SourcePartDisposition.Ineligible(listOf("not loaded"))
                        },
                    )
                },
        )
    return base.copy(
        artifacts = base.artifacts.copy(extensions = listOf(extension)),
        host = PluginHost(base.host, EnabledHostPlugins(enabled)),
    )
}

private class PluginHost(
    host: HostedRuntimeHost,
    override val plugins: HostPlugins,
) : HostedRuntimeHost by host

private class EnabledHostPlugins(
    private val loaders: Map<String, ClassLoader>,
) : HostPlugins {
    override fun enabled() = loaders.keys.map { EnabledPlugin(it, "1.0.0") }

    override fun classLoader(name: String) = loaders[name]
}
