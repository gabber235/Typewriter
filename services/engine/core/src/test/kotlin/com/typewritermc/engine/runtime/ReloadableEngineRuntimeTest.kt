package com.typewritermc.engine.runtime

import com.typewritermc.extensions.ExtensionActivation
import com.typewritermc.extensions.ExtensionActivationContext
import com.typewritermc.extensions.ExtensionActivator
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import kotlinx.coroutines.test.runTest
import java.lang.ref.WeakReference
import java.net.URLClassLoader
import java.time.Instant

val ReloadableEngineRuntimeTest by testSuite {
    test("activates extensions and closes owned resources in reverse order") {
        runTest {
            val events = mutableListOf<String>()
            val runtime = runtime(listOf(RecordingActivator("first", events), RecordingActivator("second", events)))

            runtime.activate()
            runtime.quiesce(Instant.now())

            events shouldContainExactly
                listOf(
                    "activate:first",
                    "activate:second",
                    "close:second",
                    "resource:second",
                    "close:first",
                    "resource:first",
                )
        }
    }

    test("partial activation failure cleans every attached resource") {
        runTest {
            val events = mutableListOf<String>()
            val runtime =
                runtime(
                    listOf(
                        RecordingActivator("first", events),
                        RecordingActivator("failing", events, fail = true),
                    ),
                )

            runCatching { runtime.activate() }.isFailure shouldBe true

            events shouldContainExactly
                listOf(
                    "activate:first",
                    "activate:failing",
                    "resource:failing",
                    "close:first",
                    "resource:first",
                )
        }
    }

    test("content revisions do not replace code and stale revisions are ignored") {
        runTest {
            val events = mutableListOf<String>()
            val content = mutableListOf<Long>()
            val runtime = runtime(listOf(RecordingActivator("extension", events)), content)
            runtime.activate()

            runtime.applyContent(ContentRevision(1, "first".encodeToByteArray())) shouldBe
                ContentApplicationResult.Applied(1)
            runtime.applyContent(ContentRevision(1, "duplicate".encodeToByteArray())) shouldBe
                ContentApplicationResult.Ignored(1)
            runtime.applyContent(ContentRevision(2, "second".encodeToByteArray())) shouldBe
                ContentApplicationResult.Applied(2)

            events shouldContainExactly listOf("activate:extension")
            content shouldContainExactly listOf(1L, 2L)
            runtime.stop()
        }
    }

    test("stopping releases and closes the deployment classloader") {
        runTest {
            val classLoader = TrackingClassLoader()
            val runtime =
                ReloadableEngineRuntime(
                    classLoader,
                    EngineActivationPlan(emptyList(), EngineGatewayRegistry(emptyList())),
                    this,
                )
            runtime.activate()

            runtime.stop()

            runtime.ownsClassLoader() shouldBe false
            classLoader.closed shouldBe true
        }
    }

    test("stopped deployment classloader can be collected") {
        runTest {
            val reference = stoppedClassLoaderReference()

            repeat(20) {
                if (reference.get() == null) return@runTest
                System.gc()
                System.runFinalization()
            }

            reference.get() shouldBe null
        }
    }
}

private suspend fun kotlinx.coroutines.test.TestScope.stoppedClassLoaderReference(): WeakReference<ClassLoader> {
    val classLoader = TrackingClassLoader()
    val reference = WeakReference<ClassLoader>(classLoader)
    val runtime =
        ReloadableEngineRuntime(
            classLoader,
            EngineActivationPlan(emptyList(), EngineGatewayRegistry(emptyList())),
            this,
        )
    runtime.activate()
    runtime.stop()
    return reference
}

private fun kotlinx.coroutines.test.TestScope.runtime(
    activators: List<ExtensionActivator>,
    content: MutableList<Long>? = null,
) = ReloadableEngineRuntime(
    TrackingClassLoader(),
    EngineActivationPlan(
        activators,
        EngineGatewayRegistry(emptyList()),
        content?.let { revisions -> EngineContentGateway { revision -> revisions += revision.revision } },
    ),
    this,
)

private class RecordingActivator(
    private val name: String,
    private val events: MutableList<String>,
    private val fail: Boolean = false,
) : ExtensionActivator {
    override fun activate(context: ExtensionActivationContext): ExtensionActivation {
        events += "activate:$name"
        context.scope.own(AutoCloseable { events += "resource:$name" })
        if (fail) error("activation failed")
        return ExtensionActivation { events += "close:$name" }
    }
}

private class TrackingClassLoader : URLClassLoader(emptyArray()) {
    var closed = false

    override fun close() {
        closed = true
        super.close()
    }
}
