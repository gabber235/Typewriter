package com.typewritermc.imprint.gradle

import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ArtifactKind
import com.typewritermc.imprint.ArtifactVersion
import com.typewritermc.imprint.GeneratedContribution
import com.typewritermc.imprint.gradle.testing.contribution
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.shouldBe

/**
 * Wraps [contributions] and [runtimeEntrypoints] as a manifest content source. The source type is internal to the
 * plugin, so this fixture is internal too.
 */
internal fun manifestContentSource(
    vararg contributions: GeneratedContribution,
    runtimeEntrypoints: List<String> = emptyList(),
): ManifestContentSource =
    ManifestContentSource {
        ManifestContent(
            contributions = contributions.toList(),
            runtimeEntrypoints = runtimeEntrypoints,
        )
    }
