package com.typewritermc.discovery

import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.CapabilityExtensionSourcePart
import com.typewritermc.imprint.CommonExtensionSourcePart
import com.typewritermc.imprint.EnabledPlugin
import com.typewritermc.imprint.EngineExtensionSourcePart
import com.typewritermc.imprint.EngineManifest
import com.typewritermc.imprint.ExtensionManifest
import com.typewritermc.imprint.ExtensionSourcePart
import com.typewritermc.imprint.PluginRequirement
import com.typewritermc.imprint.VersionConstraint

/**
 * Supplies the selected engine, extension identities and engine plugins for source part eligibility.
 *
 * Engine capability resolution has already happened in the manifest; the resolver compares those resolved
 * identities.
 */
data class DeploymentSelection(
    val engine: EngineManifest,
    val extensions: Set<ArtifactId>,
    val plugins: EnginePlugins,
)

/** Whether one source part can load with a selected engine, and when not, every reason why. */
sealed interface Eligibility {
    data object Eligible : Eligibility

    data class Ineligible(
        val reasons: List<IneligibleReason>,
    ) : Eligibility
}

/** One source part's eligibility with a selected engine. */
data class SourcePartCatalogEntry(
    val artifact: ArtifactId,
    val sourcePart: String,
    val eligibility: Eligibility,
)

/**
 * Why a source part cannot load with a selected engine. [message] states it as the resolver reports it, as projections
 * and logs show it; [need] says what the part needs, phrased to follow "it", as a creator reads it.
 */
sealed interface IneligibleReason {
    val message: String
    val need: String

    /** The part's extension is not part of the deployment. */
    data class ExtensionNotSelected(
        val extension: ArtifactId,
    ) : IneligibleReason {
        override val message get() = "Extension $extension is not selected."
        override val need get() = "needs its extension $extension in the deployment"
    }

    /** The part runs on another kind of engine: [required], where this one is [engine]. */
    data class EngineMismatch(
        val engine: ArtifactId,
        val required: ArtifactId,
    ) : IneligibleReason {
        override val message get() = "Engine $engine does not match $required."
        override val need get() = "needs a $required engine"
    }

    /** The engine lacks capabilities the part needs. */
    data class MissingCapabilities(
        val engine: ArtifactId,
        val missing: List<ArtifactId>,
    ) : IneligibleReason {
        override val message get() = "Engine $engine lacks capabilities ${missing.joinToString()}."
        override val need get() = "needs an engine with ${missing.joinToString()}"
    }

    /** The engine has no plugin named [plugin] enabled. */
    data class MissingPlugin(
        val plugin: String,
    ) : IneligibleReason {
        override val message get() = "needs the $plugin plugin"
        override val need get() = message
    }

    /** The engine's [plugin] is at [version], outside the declared [range]. */
    data class PluginVersionOutOfRange(
        val plugin: String,
        val range: VersionConstraint,
        val version: String,
    ) : IneligibleReason {
        override val message get() = "needs $plugin $range, the engine has $version"
        override val need get() = message
    }

    /** The engine's [plugin] reports [version], which starts with no number, so it meets no [range]. */
    data class UnparseableVersion(
        val plugin: String,
        val range: VersionConstraint,
        val version: String,
    ) : IneligibleReason {
        override val message get() = "needs $plugin $range, the engine has $version, which has no version number"
        override val need get() = message
    }

    /** Parts this part includes cannot load. */
    data class IncludedPartsIneligible(
        val parts: List<String>,
    ) : IneligibleReason {
        override val message get() = "Included source parts are ineligible: ${parts.joinToString()}."
        override val need get() = "needs its included parts ${parts.joinToString()}"
    }
}

/** The Paper plugins source part eligibility checks a selection against. */
sealed interface EnginePlugins {
    /**
     * Plugins are not checked: the selection stands for every engine of its kind, whatever each one has enabled, as
     * the publication target does.
     */
    data object Unchecked : EnginePlugins

    /** The plugins one engine host reports enabled; a host outside Paper reports none. */
    data class Reported(
        val enabled: List<EnabledPlugin>,
    ) : EnginePlugins
}

/**
 * Explains which extension source parts can load with a selected engine.
 *
 * Unselected extensions remain visible with reasons. Engine, capability and plugin requirements, including recursively
 * included source parts, must all match. Input manifests must already satisfy their include graph invariants; this
 * resolver does not repair malformed graphs.
 */
object SourcePartEligibilityResolver {
    /**
     * Produces one eligibility entry for every source part in deterministic artifact order.
     *
     * Engine projections use these entries to select executable source parts. Realm loads selected extensions'
     * common authoring providers independently of engine placement. Manifests must have valid include references.
     */
    fun resolve(
        selection: DeploymentSelection,
        manifests: Collection<ExtensionManifest>,
    ): List<SourcePartCatalogEntry> =
        manifests
            .sortedBy { it.id.value }
            .flatMap { manifest ->
                manifest.sourceParts.map { sourcePart ->
                    SourcePartCatalogEntry(
                        artifact = manifest.id,
                        sourcePart = sourcePart.name,
                        eligibility = eligibility(selection, manifest, sourcePart),
                    )
                }
            }

    private fun eligibility(
        selection: DeploymentSelection,
        manifest: ExtensionManifest,
        sourcePart: ExtensionSourcePart,
    ): Eligibility {
        if (manifest.id !in selection.extensions) {
            return Eligibility.Ineligible(listOf(IneligibleReason.ExtensionNotSelected(manifest.id)))
        }
        val ownEligibility =
            when (sourcePart) {
                is CommonExtensionSourcePart -> {
                    Eligibility.Eligible
                }

                is EngineExtensionSourcePart -> {
                    if (sourcePart.resolved.id == selection.engine.id) {
                        Eligibility.Eligible
                    } else {
                        Eligibility.Ineligible(listOf(IneligibleReason.EngineMismatch(selection.engine.id, sourcePart.resolved.id)))
                    }
                }

                is CapabilityExtensionSourcePart -> {
                    val available =
                        selection.engine.resolvedCapabilities
                            .map { it.id }
                            .toSet()
                    val missing = sourcePart.resolved.map { it.id }.filterNot(available::contains)
                    if (missing.isEmpty()) {
                        Eligibility.Eligible
                    } else {
                        Eligibility.Ineligible(listOf(IneligibleReason.MissingCapabilities(selection.engine.id, missing)))
                    }
                }
            }
        if (ownEligibility is Eligibility.Ineligible) return ownEligibility
        val unmetPlugins = selection.plugins.unmet(sourcePart.plugins)
        if (unmetPlugins.isNotEmpty()) return Eligibility.Ineligible(unmetPlugins)

        val parts = manifest.sourceParts.associateBy(ExtensionSourcePart::name)
        val failedIncludes =
            sourcePart.includes.mapNotNull { included ->
                val includedEligibility = eligibility(selection, manifest, parts.getValue(included))
                included.takeIf { includedEligibility is Eligibility.Ineligible }
            }
        return if (failedIncludes.isEmpty()) {
            Eligibility.Eligible
        } else {
            Eligibility.Ineligible(listOf(IneligibleReason.IncludedPartsIneligible(failedIncludes)))
        }
    }
}

/**
 * One reason for each of [requirements] these plugins do not meet: the plugin is not enabled, or its version is outside
 * the declared range. A version that starts with no number meets no range but any requirement without one.
 */
private fun EnginePlugins.unmet(requirements: List<PluginRequirement>): List<IneligibleReason> =
    when (this) {
        EnginePlugins.Unchecked -> {
            emptyList()
        }

        is EnginePlugins.Reported -> {
            val byName = enabled.associateBy(EnabledPlugin::name)
            requirements.mapNotNull { requirement ->
                val plugin = byName[requirement.name] ?: return@mapNotNull IneligibleReason.MissingPlugin(requirement.name)
                val range = requirement.version ?: return@mapNotNull null
                val version =
                    plugin.leadingVersion
                        ?: return@mapNotNull IneligibleReason.UnparseableVersion(requirement.name, range, plugin.version)
                IneligibleReason.PluginVersionOutOfRange(requirement.name, range, plugin.version).takeUnless { range.accepts(version) }
            }
        }
    }
