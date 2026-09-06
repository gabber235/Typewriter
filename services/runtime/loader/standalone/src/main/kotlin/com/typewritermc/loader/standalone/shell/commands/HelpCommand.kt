package com.typewritermc.loader.standalone.shell.commands

import com.github.ajalt.clikt.core.CliktCommand
import com.github.ajalt.clikt.core.Context

/**
 * Prints the enclosing root command help using its registered command definitions. Requires a parent command
 * context, as supplied by [LoaderRootCommand], rather than maintaining a separate help listing.
 */
class HelpCommand : CliktCommand(name = "help") {
    override fun help(context: Context) = "Show the available loader shell commands"

    override fun run() {
        val root = checkNotNull(currentContext.parent) { "Help command requires a parent command" }
        echo(root.command.getFormattedHelp())
    }
}
