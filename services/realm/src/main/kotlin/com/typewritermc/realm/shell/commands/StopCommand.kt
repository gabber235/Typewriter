package com.typewritermc.realm.shell.commands

import com.github.ajalt.clikt.core.CliktCommand
import com.github.ajalt.clikt.core.Context
import com.typewritermc.realm.shell.RealmShellContext

class StopCommand(
    private val context: RealmShellContext,
) : CliktCommand(name = "stop") {
    override fun help(context: Context) = "Exit the Realm shell"
    override fun run() {
        echo("Exiting Realm shell")
        context.requestStop()
    }
}
