package com.typewritermc.discovery

import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.CapabilityExtensionSourcePart
import com.typewritermc.imprint.CommonExtensionSourcePart
import com.typewritermc.imprint.EngineExtensionSourcePart
import com.typewritermc.imprint.EngineManifest
import com.typewritermc.imprint.ExtensionManifest
import com.typewritermc.imprint.ExtensionSourcePart

data class DeploymentSelection(
    val engine: EngineManifest,
    val extensions: Set<ArtifactId>,
)

object SourcePartEligibilityResolver {
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
            return Eligibility.Ineligible(listOf("Extension ${manifest.id} is not selected."))
        }
        val ownEligibility =
            when (sourcePart) {
                CommonExtensionSourcePart -> {
                    Eligibility.Eligible
                }

                is EngineExtensionSourcePart -> {
                    if (sourcePart.resolved.id == selection.engine.id) {
                        Eligibility.Eligible
                    } else {
                        Eligibility.Ineligible(listOf("Engine ${selection.engine.id} does not match ${sourcePart.resolved.id}."))
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
                        Eligibility.Ineligible(listOf("Engine ${selection.engine.id} lacks capabilities ${missing.joinToString()}."))
                    }
                }
            }
        if (ownEligibility is Eligibility.Ineligible) return ownEligibility

        val parts = manifest.sourceParts.associateBy(ExtensionSourcePart::name)
        val failedIncludes =
            sourcePart.includes.mapNotNull { included ->
                val includedEligibility = eligibility(selection, manifest, parts.getValue(included))
                included.takeIf { includedEligibility is Eligibility.Ineligible }
            }
        return if (failedIncludes.isEmpty()) {
            Eligibility.Eligible
        } else {
            Eligibility.Ineligible(listOf("Included source parts are ineligible: ${failedIncludes.joinToString()}."))
        }
    }
}
