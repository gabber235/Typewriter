package com.typewritermc.engine

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf

val EngineLayerResolverTest by testSuite {
    test("resolves direct engine layers") {
        val minecraft = layer("minecraft", "1.0.0")
        val result = EngineLayerResolver(listOf(minecraft)).resolve(engine(requires("minecraft", "1.0.0")))

        result.shouldBeInstanceOf<EngineLayerResolution.Success>().layers shouldContainExactly listOf(minecraft)
    }

    test("resolves transitive layers before their dependents") {
        val base = layer("base", "1.1.0")
        val composite = layer("composite", "1.0.0", requires("base", "1.0.0"))
        val result = EngineLayerResolver(listOf(composite, base)).resolve(engine(requires("composite", "1.0.0")))

        result.shouldBeInstanceOf<EngineLayerResolution.Success>().layers shouldContainExactly listOf(base, composite)
    }

    test("merges compatible requirements to their highest minimum") {
        val shared = layer("shared", "1.4.0")
        val first = layer("first", "1.0.0", requires("shared", "1.1.0"))
        val second = layer("second", "1.0.0", requires("shared", "1.3.0"))
        val result =
            EngineLayerResolver(listOf(shared, first, second)).resolve(
                engine(requires("first", "1.0.0"), requires("second", "1.0.0")),
            )

        result.shouldBeInstanceOf<EngineLayerResolution.Success>().layers shouldContainExactly
            listOf(shared, first, second)
    }

    test("rejects conflicting major requirements") {
        val shared = layer("shared", "1.4.0")
        val first = layer("first", "1.0.0", requires("shared", "1.0.0"))
        val second = layer("second", "1.0.0", requires("shared", "2.0.0"))
        val result =
            EngineLayerResolver(listOf(shared, first, second)).resolve(
                engine(requires("first", "1.0.0"), requires("second", "1.0.0")),
            )

        result.shouldBeInstanceOf<EngineLayerResolution.IncompatibleRequirements>().id shouldBe layerId("shared")
    }

    test("rejects an incomplete layer graph") {
        val composite = layer("composite", "1.0.0", requires("missing", "1.0.0"))
        val result = EngineLayerResolver(listOf(composite)).resolve(engine(requires("composite", "1.0.0")))

        result shouldBe EngineLayerResolution.MissingLayer(layerId("missing"))
    }

    test("rejects unavailable compatible versions") {
        val shared = layer("shared", "1.1.0")
        val result = EngineLayerResolver(listOf(shared)).resolve(engine(requires("shared", "1.2.0")))

        result.shouldBeInstanceOf<EngineLayerResolution.UnsupportedVersion>().available shouldBe version("1.1.0")
    }

    test("rejects cyclic layer graphs with the complete cycle") {
        val first = layer("first", "1.0.0", requires("second", "1.0.0"))
        val second = layer("second", "1.0.0", requires("first", "1.0.0"))
        val result = EngineLayerResolver(listOf(first, second)).resolve(engine(requires("first", "1.0.0")))

        result.shouldBeInstanceOf<EngineLayerResolution.Cycle>().path shouldContainExactly
            listOf(layerId("first"), layerId("second"), layerId("first"))
    }
}

private fun engine(vararg layers: EngineLayerRequirement) = EngineDescriptor(EngineId.of("test"), version("1.0.0"), layers.toList())

private fun layer(
    id: String,
    version: String,
    vararg requires: EngineLayerRequirement,
) = EngineLayerDescriptor(layerId(id), version(version), requires.toList())

private fun requires(
    id: String,
    version: String,
) = EngineLayerRequirement(layerId(id), VersionRequirement(version(version)))

private fun layerId(value: String) = EngineLayerId.of("test:$value")

private fun version(value: String) = SemanticVersion.parse(value)
