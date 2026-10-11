package com.typewritermc.engine.runtime

import com.typewritermc.authoring.PublicationId
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.discovery.DeploymentFacts
import com.typewritermc.discovery.DiscoveryDomains
import com.typewritermc.discovery.GeneratedProviderDeployment
import com.typewritermc.discovery.GeneratedProviderLoader
import com.typewritermc.discovery.RuntimeRegistrar
import com.typewritermc.discovery.RuntimeScope
import com.typewritermc.engine.ContentDigest
import com.typewritermc.engine.LoadedPublishedContent
import com.typewritermc.engine.PublishedContent
import com.typewritermc.types.FactoryNativeBindingRegistry
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runTest

val DiscoveryEngineRuntimeTest by testSuite {
    test("registers discovered behavior and closes owned resources in reverse order") {
        runTest {
            val events = mutableListOf<String>()
            val fixture = runtime(listOf(RecordingRegistrar("first", events), RecordingRegistrar("second", events)))

            fixture.runtime.activate()
            fixture.runtime.quiesce()

            events shouldContainExactly listOf("register:first", "register:second", "close:second", "close:first")
        }
    }

    test("partial registration failure cleans acquired resources") {
        runTest {
            val events = mutableListOf<String>()
            val fixture =
                runtime(
                    listOf(
                        RecordingRegistrar("first", events),
                        RecordingRegistrar("failing", events, fail = true),
                    ),
                )

            runCatching { fixture.runtime.activate() }.isFailure shouldBe true

            events shouldContainExactly listOf("register:first", "register:failing", "close:failing", "close:first")
            fixture.runtime.stop()
        }
    }

    test("applies each fetched publication once without ordering its identity") {
        runTest {
            val revisions = mutableListOf<Long>()
            val fixture = runtime(emptyList(), revisions)
            fixture.runtime.activate()

            fixture.runtime.applyContent(content(1, '1')) shouldBe
                ContentApplicationResult.Applied(PublicationId("publication:1"))
            fixture.runtime.applyContent(content(1, '2')) shouldBe
                ContentApplicationResult.Unchanged(PublicationId("publication:1"))
            fixture.runtime.applyContent(content(2, '3')) shouldBe
                ContentApplicationResult.Applied(PublicationId("publication:2"))
            revisions shouldContainExactly listOf(1L, 2L)
            fixture.runtime.stop()
        }
    }

    test("assembly failure retains the active content snapshot") {
        runTest {
            val gateway =
                AssemblingEngineContentGateway(
                    listOf(
                        PageCompiledArtifactConsumer(
                            catalog = EMPTY_CATALOG,
                            bindings = FactoryNativeBindingRegistry(EMPTY_CATALOG, emptyList()),
                            relations = emptyList(),
                        ),
                    ),
                )
            val active = content(1, '4')
            gateway.apply(active)

            shouldThrow<IllegalArgumentException> {
                gateway.apply(
                    active.copy(
                        descriptor = active.descriptor.copy(formatRevision = 3),
                    ),
                )
            }

            gateway.snapshot.value?.descriptor shouldBe active.descriptor
        }
    }

    test("incompatible implementation leaves the active engine content unchanged") {
        runTest {
            val revisions = mutableListOf<Long>()
            val fixture = runtime(emptyList(), revisions)
            fixture.runtime.activate()
            fixture.runtime.applyContent(content(1, '6'))

            shouldThrow<IllegalArgumentException> {
                fixture.runtime.applyContent(content(2, '7', implementationToken = "replacement"))
            }

            revisions shouldContainExactly listOf(1L)
            fixture.runtime.applyContent(content(2, '8')) shouldBe
                ContentApplicationResult.Applied(PublicationId("publication:2"))
            revisions shouldContainExactly listOf(1L, 2L)
            fixture.runtime.stop()
        }
    }

    test("panel preview accepts primary content without claiming implementation compatibility") {
        runTest {
            val revisions = mutableListOf<Long>()
            val fixture = runtime(emptyList(), revisions, enforceImplementationCompatibility = false)
            fixture.runtime.activate()

            fixture.runtime.applyContent(content(1, '9', implementationToken = "primary implementation")) shouldBe
                ContentApplicationResult.Applied(PublicationId("publication:1"))
            revisions shouldContainExactly listOf(1L)
            fixture.runtime.stop()
        }
    }

    test("stopping closes the generated provider deployment") {
        runTest {
            val fixture = runtime(emptyList())
            fixture.runtime.activate()

            fixture.runtime.stop()

            fixture.runtime.ownsDeployment() shouldBe false
            shouldThrow<IllegalStateException> { fixture.deployment.retain() }
        }
    }
}

private fun TestScope.runtime(
    registrars: List<RuntimeRegistrar>,
    revisions: MutableList<Long>? = null,
    enforceImplementationCompatibility: Boolean = true,
): RuntimeFixture {
    val deployment = GeneratedProviderLoader().load(emptyList(), DeploymentFacts(emptyMap()), DiscoveryDomains.Execution)
    return RuntimeFixture(
        ReloadableEngineRuntime(
            deployment = deployment,
            registrars = registrars,
            parentScope = this,
            implementationToken = "implementation",
            enforceImplementationCompatibility = enforceImplementationCompatibility,
            runtimeSignatures = emptySet(),
            contentGateway =
                revisions?.let { values ->
                    EngineContentGateway {
                        values +=
                            it.descriptor.publication.value
                                .substringAfter(":")
                                .toLong()
                    }
                },
        ),
        deployment,
    )
}

private fun content(
    revision: Long,
    digestCharacter: Char,
    implementationToken: String = "implementation",
): LoadedPublishedContent =
    LoadedPublishedContent(
        PublishedContent(
            PublicationId("publication:$revision"),
            2,
            CatalogGeneration("catalog:1"),
            implementationToken,
            emptySet(),
            emptyList(),
        ),
        emptyList(),
    )

private data class RuntimeFixture(
    val runtime: ReloadableEngineRuntime,
    val deployment: GeneratedProviderDeployment,
)

private class RecordingRegistrar(
    private val name: String,
    private val events: MutableList<String>,
    private val fail: Boolean = false,
) : RuntimeRegistrar {
    context(scope: RuntimeScope)
    override suspend fun register() {
        events += "register:$name"
        scope.own { events += "close:$name" }
        if (fail) error("registration failed")
    }
}

private val EMPTY_CATALOG = DefaultCheckedCatalog(CatalogGeneration("engine runtime test"), emptyList())
