package com.typewritermc.realm.shell.commands

import com.github.ajalt.clikt.core.NoOpCliktCommand
import com.github.ajalt.clikt.core.context
import com.github.ajalt.clikt.core.subcommands
import com.github.ajalt.clikt.core.terminal
import com.github.ajalt.mordant.terminal.Terminal
import com.typewritermc.realm.shell.RealmShellContext

class RealmRootCommand(
    shellContext: RealmShellContext,
    terminal: Terminal? = null,
) : NoOpCliktCommand(name = "realm") {
    init {
        terminal?.let { output -> context { this.terminal = output } }
        subcommands(
            HelpCommand(),
            StatusCommand(shellContext),
            StopCommand(shellContext),
        )
    }
}
