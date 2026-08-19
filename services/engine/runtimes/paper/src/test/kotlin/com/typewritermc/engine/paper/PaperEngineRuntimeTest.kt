package com.typewritermc.engine.paper

import com.typewritermc.engine.runtime.EngineActivationPlan
import com.typewritermc.engine.runtime.EngineGatewayRegistry
import com.typewritermc.engine.runtime.ReloadableEngineRuntime
import com.typewritermc.extensions.ExtensionActivation
import com.typewritermc.extensions.ExtensionActivationContext
import com.typewritermc.extensions.ExtensionActivator
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContainExactly
import kotlinx.coroutines.test.runTest
import java.net.URLClassLoader

val PaperEngineRuntimeTest by testSuite {
    test("typed Paper registrations are owned by the deployment scope") {
        runTest {
            val events = mutableListOf<String>()
            val gateway = RecordingPaperGateway(events)
            val runtime =
                ReloadableEngineRuntime(
                    URLClassLoader(emptyArray()),
                    EngineActivationPlan(listOf(PaperRegistrationActivator), EngineGatewayRegistry(listOf(gateway))),
                    this,
                )

            runtime.activate()
            runtime.stop()

            events shouldContainExactly listOf("listener:add", "command:add", "command:remove", "listener:remove")
        }
    }
}

private object PaperRegistrationActivator : ExtensionActivator {
    override fun activate(context: ExtensionActivationContext): ExtensionActivation {
        val gateway = context.gateway(PaperEngineGateway::class)
        context.scope.own(gateway.registerListener("fixture") {})
        context.scope.own(gateway.registerCommand("fixture") {})
        return ExtensionActivation {}
    }
}

private class RecordingPaperGateway(
    private val events: MutableList<String>,
) : PaperEngineGateway {
    override fun registerListener(
        id: String,
        listener: suspend (Any) -> Unit,
    ): AutoCloseable {
        events += "listener:add"
        return AutoCloseable { events += "listener:remove" }
    }

    override fun registerCommand(
        name: String,
        command: suspend (List<String>) -> Unit,
    ): AutoCloseable {
        events += "command:add"
        return AutoCloseable { events += "command:remove" }
    }
}
