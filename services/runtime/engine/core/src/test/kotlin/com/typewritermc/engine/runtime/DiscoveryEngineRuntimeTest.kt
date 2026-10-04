package com.typewritermc.engine.runtime

import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.discovery.DeploymentFacts
import com.typewritermc.discovery.GeneratedProviderDeployment
import com.typewritermc.discovery.GeneratedProviderLoader
import com.typewritermc.discovery.RuntimeRegistrar
import com.typewritermc.discovery.RuntimeScope
import com.typewritermc.engine.CompiledArtifactManifest
import com.typewritermc.engine.ContentDigest
import com.typewritermc.engine.LoadedCompiledContent
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

    test("compiled content activation revisions remain monotonic") {
        runTest {
            val revisions = mutableListOf<Long>()
            val fixture = runtime(emptyList(), revisions)
            fixture.runtime.activate()

            fixture.runtime.applyContent(content(1, '1')) shouldBe
                ContentApplicationResult.Applied(1, ContentDigest("1".repeat(64)))
            fixture.runtime.applyContent(content(1, '2')) shouldBe
                ContentApplicationResult.Ignored(1, ContentDigest("1".repeat(64)))
            fixture.runtime.applyContent(content(2, '3')) shouldBe
                ContentApplicationResult.Applied(2, ContentDigest("3".repeat(64)))
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
                        activationRevision = 2,
                        manifest = active.manifest.copy(formatRevision = 3),
                    ),
                )
            }

            gateway.snapshot.value?.manifest shouldBe active.manifest
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
                ContentApplicationResult.Applied(2, ContentDigest("8".repeat(64)))
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
                ContentApplicationResult.Applied(1, ContentDigest("9".repeat(64)))
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
    val deployment = GeneratedProviderLoader().load(emptyList(), DeploymentFacts(emptyMap()))
    return RuntimeFixture(
        ReloadableEngineRuntime(
            deployment = deployment,
            registrars = registrars,
            parentScope = this,
            implementationToken = "implementation",
            enforceImplementationCompatibility = enforceImplementationCompatibility,
            runtimeSignatures = emptySet(),
            contentGateway = revisions?.let { values -> EngineContentGateway { values += it.activationRevision } },
        ),
        deployment,
    )
}

private fun content(
    revision: Long,
    digestCharacter: Char,
    implementationToken: String = "implementation",
): LoadedCompiledContent {
    val digest = ContentDigest(digestCharacter.toString().repeat(64))
    return LoadedCompiledContent(
        activationRevision = revision,
        manifest =
            CompiledArtifactManifest(
                formatRevision = 2,
                digest = digest,
                sourceRevision = "realm:$revision",
                catalogRevision = "catalog:1",
                implementationToken = implementationToken,
                runtimeSignatures = emptySet(),
                artifacts = emptyList(),
            ),
        artifacts = emptyList(),
    )
}

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
