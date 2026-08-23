package com.typewritermc.engine.runtime

import com.typewritermc.discovery.DeploymentFacts
import com.typewritermc.discovery.DiscoveryDomains
import com.typewritermc.discovery.runtime.DiscoveryDeployment
import com.typewritermc.discovery.runtime.RuntimeRegistrar
import com.typewritermc.discovery.runtime.RuntimeScope
import com.typewritermc.types.TypePrototypeRegistry
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runTest
import org.koin.dsl.koinApplication
import java.net.URLClassLoader
import java.time.Instant

val DiscoveryEngineRuntimeTest by testSuite {
    test("registers discovered behavior and closes owned resources in reverse order") {
        runTest {
            val events = mutableListOf<String>()
            val fixture = runtime(listOf(RecordingRegistrar("first", events), RecordingRegistrar("second", events)))

            fixture.runtime.activate()
            fixture.runtime.quiesce(Instant.now())

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

    test("content revisions remain monotonic") {
        runTest {
            val revisions = mutableListOf<Long>()
            val fixture = runtime(emptyList(), revisions)
            fixture.runtime.activate()

            fixture.runtime.applyContent(ContentRevision(1, byteArrayOf(1))) shouldBe ContentApplicationResult.Applied(1)
            fixture.runtime.applyContent(ContentRevision(1, byteArrayOf(2))) shouldBe ContentApplicationResult.Ignored(1)
            fixture.runtime.applyContent(ContentRevision(2, byteArrayOf(3))) shouldBe ContentApplicationResult.Applied(2)
            revisions shouldContainExactly listOf(1L, 2L)
            fixture.runtime.stop()
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
            contentGateway = revisions?.let { values -> EngineContentGateway { values += it.revision } },
        ),
        classLoader,
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
