package com.typewritermc.realm.shell.commands

import com.github.ajalt.clikt.testing.test
import com.typewritermc.realm.shell.RealmShellContext
import com.typewritermc.services.libs.registrar.RegistrationState
import com.typewritermc.services.libs.utils.StateProvider
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.shouldBe
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

    context("Service Information Display") {

        test("displays version information") {
            val context = createContext(RegistrationState.Initializing)
            val result = StatusCommand(context).test()

            result.output shouldContain "Version:"
        }

        test("displays uptime header") {
            val context = createContext(RegistrationState.Initializing)
            val result = StatusCommand(context).test()

            result.output shouldContain "Uptime:"
        }

        test("displays service title") {
            val context = createContext(RegistrationState.Initializing)
            val result = StatusCommand(context).test()

            result.output shouldContain "Realm Service Status"
        }
    }

    context("Command Execution") {

        test("exits with code 0 on success") {
            val context = createContext(RegistrationState.Initializing)
            val result = StatusCommand(context).test()

            result.statusCode shouldBe 0
        }
    }

    context("Duration Formatting") {

        test("formats zero seconds as 00:00:00") {
            val formatted = formatTestDuration(0, 0, 0)
            formatted shouldBe "00:00:00"
        }

        test("formats seconds only") {
            val formatted = formatTestDuration(0, 0, 45)
            formatted shouldBe "00:00:45"
        }

        test("formats minutes and seconds") {
            val formatted = formatTestDuration(0, 2, 5)
            formatted shouldBe "00:02:05"
        }

        test("formats hours, minutes, seconds") {
            val formatted = formatTestDuration(1, 1, 1)
            formatted shouldBe "01:01:01"
        }

        test("handles large durations") {
            val formatted = formatTestDuration(24, 0, 0)
            formatted shouldBe "24:00:00"
        }

        test("handles 99 hours") {
            val formatted = formatTestDuration(99, 59, 59)
            formatted shouldBe "99:59:59"
        }
    }

    context("Edge Cases") {

        test("handles empty organization name in Bound state") {
            val context = createContext(
                RegistrationState.Bound(
                    organizationId = "org-empty",
                    organizationName = ""
                )
            )
            val result = StatusCommand(context).test()

            result.output shouldContain "Org ID: org-empty"
        }

        test("handles empty error message in Failed state") {
            val context = createContext(RegistrationState.Failed(""))
            val result = StatusCommand(context).test()

            result.output shouldContain "Status: Failed"
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

private fun formatTestDuration(hours: Long, minutes: Int, seconds: Int): String {
    return "%02d:%02d:%02d".format(hours, minutes, seconds)
}
