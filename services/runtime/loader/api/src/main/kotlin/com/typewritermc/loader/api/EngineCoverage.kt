package com.typewritermc.loader.api

import com.typewritermc.imprint.ArtifactId
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

/**
 * Which extension source parts the engines of one Realm run: its panel engine and every connected primary engine.
 *
 * A part some engine runs is [SourcePartDisposition.Eligible] with the placements that run it; a part no engine runs is
 * [SourcePartDisposition.Ineligible] with every distinct thing it needs, each phrased to follow "it", such as
 * "needs the Vault plugin". A part [parts] does not name is unknown, as every part is before the Realm's host first
 * resolves its deployment.
 */
data class EngineCoverage(
    val parts: Map<SourcePartKey, SourcePartDisposition>,
) {
    companion object {
        /** Nothing known yet. */
        val UNKNOWN = EngineCoverage(emptyMap())

        /** The coverage of a host that never learns it: every host but the Realm's. */
        val unknown: StateFlow<EngineCoverage> = MutableStateFlow(UNKNOWN).asStateFlow()
    }
}

/** One source part of one extension. */
data class SourcePartKey(
    val extension: ArtifactId,
    val part: String,
)
