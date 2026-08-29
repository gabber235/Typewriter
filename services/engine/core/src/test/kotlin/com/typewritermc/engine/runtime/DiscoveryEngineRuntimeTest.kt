package com.typewritermc.engine.runtime

import com.typewritermc.discovery.DeploymentFacts
import com.typewritermc.discovery.DiscoveryDomains
import com.typewritermc.discovery.RuntimeRegistrar
import com.typewritermc.discovery.RuntimeScope
import com.typewritermc.discovery.runtime.DiscoveryDeployment
import com.typewritermc.elements.ElementCatalog
import com.typewritermc.engine.ActivatedCompiledContent
import com.typewritermc.engine.CompiledContentBundle
import com.typewritermc.engine.CompiledManifest
import com.typewritermc.engine.ContentDigest
import com.typewritermc.types.TypePrototypeRegistry
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runTest
import org.koin.dsl.koinApplication
import java.net.URLClassLoader

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
                    EngineContentAssembler(ElementCatalog(emptyList()), TypePrototypeRegistry(emptyList())),
                )
            val active = content(1, '4')
            gateway.apply(active)

            shouldThrow<IllegalArgumentException> {
                gateway.apply(
                    active.copy(
                        activationRevision = 2,
                        content = active.content.copy(manifest = active.content.manifest.copy(formatRevision = 2)),
                    ),
                )
            }

            gateway.snapshot.value?.manifest shouldBe active.content.manifest
        }
    }

    test("stopping closes the isolated discovery deployment") {
        runTest {
            val fixture = runtime(emptyList())
            fixture.runtime.activate()

            fixture.runtime.stop()

            fixture.runtime.ownsDeployment() shouldBe false
            fixture.classLoader.closed shouldBe true
        }
    }
}

private fun TestScope.runtime(
    registrars: List<RuntimeRegistrar>,
    revisions: MutableList<Long>? = null,
): RuntimeFixture {
    val classLoader = TrackingClassLoader()
    val deployment =
        DiscoveryDeployment(
            domain = DiscoveryDomains.Execution,
            application = koinApplication {},
            prototypes = TypePrototypeRegistry(emptyList()),
            facts = DeploymentFacts(emptyMap()),
            classLoader = classLoader,
        )
    return RuntimeFixture(
        ReloadableEngineRuntime(
            deployment = deployment,
            registrars = registrars,
            parentScope = this,
            contentGateway = revisions?.let { values -> EngineContentGateway { values += it.activationRevision } },
        ),
        classLoader,
    )
}

private fun content(
    revision: Long,
    digestCharacter: Char,
): ActivatedCompiledContent {
    val digest = ContentDigest(digestCharacter.toString().repeat(64))
    return ActivatedCompiledContent(
        revision,
        CompiledContentBundle(
            CompiledManifest(1, digest, "realm:$revision", "catalog:1", emptyList()),
            emptyList(),
        ),
    )
}

private data class RuntimeFixture(
    val runtime: ReloadableEngineRuntime,
    val classLoader: TrackingClassLoader,
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

private class TrackingClassLoader : URLClassLoader(emptyArray()) {
    var closed = false

    override fun close() {
        closed = true
        super.close()
    }
}
