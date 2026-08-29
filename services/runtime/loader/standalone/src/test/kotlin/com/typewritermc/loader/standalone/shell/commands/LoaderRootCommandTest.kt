package com.typewritermc.loader.standalone.shell.commands

import com.github.ajalt.clikt.testing.test
import com.typewritermc.loader.standalone.shell.LoaderShellContext
import com.typewritermc.services.libs.registrar.RegistrarSnapshot
import com.typewritermc.services.libs.registrar.RegistrarState
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldContain
import kotlinx.coroutines.flow.MutableStateFlow
import kotlin.time.TestTimeSource

val LoaderRootCommandTest by testSuite {
    test("help displays the command catalog") {
        val context =
            LoaderShellContext(
                registrarStates = MutableStateFlow(RegistrarSnapshot(12, 3, RegistrarState.Idle)),
                timeSource = TestTimeSource(),
            )

        val result = LoaderRootCommand(context).test("help")

        result.output shouldContain "Commands:"
        result.output shouldContain "help"
        result.output shouldContain "status"
        result.output shouldContain "stop"
    }

    test("stop requests only local shell termination") {
        val context =
            LoaderShellContext(
                registrarStates = MutableStateFlow(RegistrarSnapshot(12, 3, RegistrarState.Idle)),
                timeSource = TestTimeSource(),
            )

        val result = LoaderRootCommand(context).test("stop")

        result.output shouldContain "Stopping the loader"
        context.isStopRequested() shouldBe true
    }
}
