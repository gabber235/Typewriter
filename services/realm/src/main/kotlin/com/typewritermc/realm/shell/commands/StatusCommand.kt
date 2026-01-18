package com.typewritermc.realm.shell.commands

import com.github.ajalt.clikt.core.CliktCommand
import com.github.ajalt.clikt.core.Context
import com.typewritermc.realm.shell.RealmShellContext
import com.typewritermc.services.libs.registrar.RegistrationState
import java.time.Duration
import java.time.Instant

class StatusCommand(
    private val context: RealmShellContext,
) : CliktCommand(name = "status") {
    override fun help(context: Context) = "Show the current status of the Realm service"
    override fun run() {
        val uptime = Duration.between(context.startTime, Instant.now())
        val uptimeFormatted = formatDuration(uptime)

        echo("Realm Service Status")
        echo("--------------------")
        echo("Version: ${context.version}")
        echo("Uptime:  $uptimeFormatted")

        displayRegistrationStatus()
    }

    private fun displayRegistrationStatus() {
        echo("")
        echo("Registration Status")
        echo("-------------------")

        when (val state = context.registrationStateProvider.get()) {
            RegistrationState.Initializing -> {
                echo("Status: Initializing...")
            }
            is RegistrationState.Pending -> {
                echo("Status: Awaiting Registration")
                echo("Token:  ${state.token}")
            }
            is RegistrationState.Bound -> {
                echo("Status: Bound")
                echo("Org ID: ${state.organizationId}")
                echo("Org:    ${state.organizationName}")
            }
            is RegistrationState.Failed -> {
                echo("Status: Failed")
                echo("Error:  ${state.message}")
            }
        }
    }

    private fun formatDuration(duration: Duration): String {
        val hours = duration.toHours()
        val minutes = duration.toMinutesPart()
        val seconds = duration.toSecondsPart()
        return "%02d:%02d:%02d".format(hours, minutes, seconds)
    }
}
