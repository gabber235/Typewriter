package com.typewritermc.realm.shell.commands

import com.github.ajalt.clikt.testing.test
import com.typewritermc.realm.shell.RealmShellContext
import com.typewritermc.services.libs.registrar.RegistrarSnapshot
import com.typewritermc.services.libs.registrar.RegistrarState
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldContain
import kotlinx.coroutines.flow.MutableStateFlow
import kotlin.time.TestTimeSource

val RealmRootCommandTest by testSuite {
    test("help displays the command catalog") {
        val context =
            RealmShellContext(
                registrarStates = MutableStateFlow(RegistrarSnapshot(12, 3, RegistrarState.Idle)),
                timeSource = TestTimeSource(),
            )

        val result = RealmRootCommand(context).test("help")

        result.output shouldContain "Commands:"
        result.output shouldContain "help"
        result.output shouldContain "status"
        result.output shouldContain "stop"
    }

    test("stop requests only local shell termination") {
        val context =
            RealmShellContext(
                registrarStates = MutableStateFlow(RegistrarSnapshot(12, 3, RegistrarState.Idle)),
                timeSource = TestTimeSource(),
            )

        val result = RealmRootCommand(context).test("stop")

        result.output shouldContain "Exiting Realm shell"
        context.isStopRequested() shouldBe true
    }
}
