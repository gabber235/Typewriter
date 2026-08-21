package com.typewritermc.loader.standalone.shell.commands

import com.github.ajalt.clikt.core.CliktCommand
import com.github.ajalt.clikt.core.Context
import com.typewritermc.loader.standalone.shell.LoaderShellContext

class StopCommand(
    private val context: LoaderShellContext,
) : CliktCommand(name = "stop") {
    override fun help(context: Context) = "Stop the standalone loader"

    override fun run() {
        echo("Stopping the loader")
        context.requestStop()
    }
}
