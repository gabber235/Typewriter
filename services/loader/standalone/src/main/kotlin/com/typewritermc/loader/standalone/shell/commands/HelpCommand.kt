package com.typewritermc.loader.standalone.shell.commands

import com.github.ajalt.clikt.core.CliktCommand
import com.github.ajalt.clikt.core.Context

class HelpCommand : CliktCommand(name = "help") {
    override fun help(context: Context) = "Show the available loader shell commands"

    override fun run() {
        val root = checkNotNull(currentContext.parent) { "Help command requires a parent command" }
        echo(root.command.getFormattedHelp())
    }
}
