package com.typewritermc.realm.shell.commands

import com.github.ajalt.clikt.core.CliktCommand
import com.github.ajalt.clikt.core.Context
import com.typewritermc.realm.shell.RealmShellContext
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
    }

    private fun formatDuration(duration: Duration): String {
        val hours = duration.toHours()
        val minutes = duration.toMinutesPart()
        val seconds = duration.toSecondsPart()
        return "%02d:%02d:%02d".format(hours, minutes, seconds)
    }
}
