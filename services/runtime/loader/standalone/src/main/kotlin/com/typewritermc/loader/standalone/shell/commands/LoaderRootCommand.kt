package com.typewritermc.loader.standalone.shell.commands

import com.github.ajalt.clikt.core.NoOpCliktCommand
import com.github.ajalt.clikt.core.context
import com.github.ajalt.clikt.core.subcommands
import com.github.ajalt.clikt.core.terminal
import com.github.ajalt.mordant.terminal.Terminal
import com.typewritermc.loader.standalone.shell.LoaderShellContext

/**
 * Local loader command tree sharing one [LoaderShellContext] across help, status, and stop. Constructed for each
 * shell input so Clikt parsing state does not leak between commands.
 */
class LoaderRootCommand(
    shellContext: LoaderShellContext,
    terminal: Terminal? = null,
) : NoOpCliktCommand(name = "loader") {
    init {
        terminal?.let { output -> context { this.terminal = output } }
        subcommands(
            HelpCommand(),
            StatusCommand(shellContext),
            StopCommand(shellContext),
        )
    }
}
