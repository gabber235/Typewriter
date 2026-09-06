package com.typewritermc.region.shape

import io.kotest.assertions.withClue
import io.kotest.matchers.collections.shouldNotBeEmpty
import io.kotest.matchers.doubles.shouldBeLessThan
import io.kotest.matchers.shouldBe
import kotlin.math.abs

internal fun Shape.shouldSampleOnBoundary(density: Double = 0.5, tolerance: Double = 1e-6) {
    val samples = sampleBoundary(density).toList()
    samples.shouldNotBeEmpty()
    val bounds = localBounds
    for (sample in samples) {
        abs(signedDistance(sample)) shouldBeLessThan tolerance
        (sample.x in bounds.minX - tolerance..bounds.maxX + tolerance) shouldBe true
        (sample.y in bounds.minY - tolerance..bounds.maxY + tolerance) shouldBe true
        (sample.z in bounds.minZ - tolerance..bounds.maxZ + tolerance) shouldBe true
    }

    val distinct = samples.mapTo(HashSet()) { Triple(it.x, it.y, it.z) }
    withClue("$this emitted ${samples.size} samples but only ${distinct.size} distinct points") {
        distinct.size shouldBe samples.size
    }
}
