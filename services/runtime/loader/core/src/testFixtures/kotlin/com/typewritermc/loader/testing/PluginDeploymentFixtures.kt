package com.typewritermc.loader.testing

import com.typewritermc.imprint.ArtifactKind
import com.typewritermc.imprint.ArtifactRequirement
import com.typewritermc.imprint.CommonExtensionSourcePart
import com.typewritermc.imprint.EnabledPlugin
import com.typewritermc.imprint.EngineExtensionSourcePart
import com.typewritermc.imprint.ExtensionManifest
import com.typewritermc.imprint.PluginRequirement
import com.typewritermc.imprint.ResolvedArtifact
import com.typewritermc.imprint.VersionConstraint
import com.typewritermc.loader.api.EngineCoverage
import com.typewritermc.loader.api.RuntimePlacement
import com.typewritermc.loader.deployment.DeploymentContent
import com.typewritermc.loader.deployment.DeploymentContentCodec
import com.typewritermc.loader.deployment.DeploymentGeneration
import com.typewritermc.loader.deployment.DeploymentSnapshot
import com.typewritermc.loader.deployment.HostDeploymentProjection
import com.typewritermc.loader.deployment.engineCoverage
import com.typewritermc.loader.deployment.projectFor
import com.typewritermc.loader.rollout.deploymentSelectionOrNull
import com.typewritermc.loader.rollout.testing.presence
import com.typewritermc.services.libs.registrar.ServiceId

private val panel = deploymentArtifact("typewritermc:panel", ArtifactKind.ENGINE, "panel")
private val primary = deploymentArtifact("typewritermc:paper", ArtifactKind.ENGINE, "paper")
private val extension = deploymentArtifact("typewritermc:extension", ArtifactKind.EXTENSION, "extension")
private val realm = deploymentArtifact("typewritermc:realm", ArtifactKind.REALM, "realm")
private val content = DeploymentContent(realm = realm, primaryEngine = primary, panelEngine = panel, extensions = listOf(extension))
private val snapshot = DeploymentSnapshot(DeploymentGeneration(1), DeploymentContentCodec.digest(content), content)
private val vaultPart =
    EngineExtensionSourcePart(
        name = "vault",
        requirement = ArtifactRequirement(primary.coordinate.id, VersionConstraint("^1")),
        resolved = ResolvedArtifact(primary.coordinate.id, primary.coordinate.version, ArtifactKind.ENGINE),
        plugins = listOf(PluginRequirement("Vault")),
    )
private val extensionManifest =
    ExtensionManifest(
        id = extension.coordinate.id,
        version = extension.coordinate.version,
        sourceParts = listOf(CommonExtensionSourcePart(), vaultPart),
        buildProvenance = emptyList(),
        contributions = emptyList(),
    )
private val manifests =
    listOf(realmManifest(), engineManifest(panel), engineManifest(primary), extensionManifest).associateBy { it.id }

/**
 * The projection for Paper host `engine`, beside Realm host `realm`, when its presence reports [plugins]. The deployment
 * holds one extension, whose part `vault` uses the `Vault` plugin.
 */
fun engineProjectionReporting(vararg plugins: EnabledPlugin): HostDeploymentProjection {
    val engineHost = ServiceId("engine")
    val selection =
        listOf(
            presence(ServiceId("realm"), setOf(RuntimePlacement.REALM)),
            presence(engineHost, setOf(RuntimePlacement.PRIMARY_ENGINE), plugins = plugins.toList()),
        ).deploymentSelectionOrNull()
    return snapshot.projectFor("realm", requireNotNull(selection), engineHost, manifests)
}

/**
 * What the engines of the Realm run in the deployment of [engineProjectionReporting] when the Realm host `realm`
 * reports [realmPlugins] and one Paper host `engine-<n>` reports each of [enginePlugins], in order.
 */
fun realmCoverageReporting(
    realmPlugins: List<EnabledPlugin> = emptyList(),
    vararg enginePlugins: List<EnabledPlugin>,
): EngineCoverage {
    val selection =
        (
            listOf(presence(ServiceId("realm"), setOf(RuntimePlacement.REALM), plugins = realmPlugins)) +
                enginePlugins.mapIndexed { index, plugins ->
                    presence(ServiceId("engine-${index + 1}"), setOf(RuntimePlacement.PRIMARY_ENGINE), plugins = plugins)
                }
        ).deploymentSelectionOrNull()
    return snapshot.engineCoverage(requireNotNull(selection), manifests)
}
