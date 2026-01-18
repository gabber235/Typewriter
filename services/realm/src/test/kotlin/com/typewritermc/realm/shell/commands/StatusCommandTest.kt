package com.typewritermc.realm.shell.commands

import com.github.ajalt.clikt.testing.test
import com.typewritermc.realm.shell.RealmShellContext
import com.typewritermc.services.libs.registrar.RegistrationState
import com.typewritermc.services.libs.utils.StateProvider
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.string.shouldContain
import java.time.Instant

class StatusCommandTest : FunSpec({

    context("Registration State Display") {

        test("displays Initializing state correctly") {
            val context = createContext(RegistrationState.Initializing)
            val result = StatusCommand(context).test()

            result.output shouldContain "Status: Initializing"
        }

        test("displays Pending state with registration token") {
            val context = createContext(RegistrationState.Pending("REG-TOKEN-ABC123"))
            val result = StatusCommand(context).test()

            result.output shouldContain "Status: Awaiting Registration"
            result.output shouldContain "Token:  REG-TOKEN-ABC123"
        }

        test("displays Bound state with organization info") {
            val context = createContext(
                RegistrationState.Bound(
                    organizationId = "org-12345",
                    organizationName = "My Test Organization"
                )
            )
            val result = StatusCommand(context).test()

            result.output shouldContain "Status: Bound"
            result.output shouldContain "Org ID: org-12345"
            result.output shouldContain "Org:    My Test Organization"
        }

        test("displays Failed state with error message") {
            val context = createContext(RegistrationState.Failed("Connection refused to backend"))
            val result = StatusCommand(context).test()

            result.output shouldContain "Status: Failed"
            result.output shouldContain "Error:  Connection refused to backend"
        }
    }
})

private fun createContext(state: RegistrationState): RealmShellContext {
    val stateProvider = StateProvider<RegistrationState>(state)
    return RealmShellContext(
        startTime = Instant.now(),
        registrationStateProvider = stateProvider
    )
}
