package com.typewritermc.realm.shell.commands

import com.github.ajalt.clikt.core.NoOpCliktCommand
import com.github.ajalt.clikt.core.subcommands
import com.typewritermc.realm.shell.RealmShellContext

class RealmRootCommand(
    context: RealmShellContext,
) : NoOpCliktCommand(name = "realm") {
    init {
        subcommands(
            StatusCommand(context),
            StopCommand(context),
        )
    }
}
