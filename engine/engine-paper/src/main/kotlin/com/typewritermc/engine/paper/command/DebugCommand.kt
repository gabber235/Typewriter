@file:Suppress("UnstableApiUsage")

package com.typewritermc.engine.paper.command

import com.typewritermc.core.books.pages.PageType
import com.typewritermc.core.entries.Entry
import com.typewritermc.core.entries.Query
import com.typewritermc.engine.paper.command.dsl.CommandTree
import com.typewritermc.engine.paper.command.dsl.sender
import com.typewritermc.engine.paper.command.dsl.withPermission
import com.typewritermc.engine.paper.plugin
import com.typewritermc.engine.paper.ui.CommunicationHandler
import com.typewritermc.engine.paper.ui.PanelHost
import com.typewritermc.engine.paper.utils.sendMiniWithResolvers
import com.typewritermc.engine.paper.utils.server
import com.typewritermc.loader.ExtensionLoader
import net.kyori.adventure.text.minimessage.tag.resolver.Placeholder
import net.kyori.adventure.text.minimessage.tag.resolver.TagResolver
import org.koin.java.KoinJavaComponent.get
import java.lang.management.ManagementFactory

internal fun CommandTree.debugCommand() = literal("debug") {
    withPermission("typewriter.debug")
    executes {
        val message = createDebugMessage()
        sender.sendMiniWithResolvers(message.text, *message.resolvers)
    }
}

private fun createDebugMessage(): DebugMessage {
    val runtime = Runtime.getRuntime()
    val extensionLoader = get<ExtensionLoader>(ExtensionLoader::class.java)
    val communicationHandler = get<CommunicationHandler>(CommunicationHandler::class.java)
    val panelHost = get<PanelHost>(PanelHost::class.java)
    val socketServer = communicationHandler.server
    val pages = PageType.entries.sumOf { Query.findPagesOfType(it).count() }
    val entries = Query.find<Entry>().count()
    val usedMemory = (runtime.totalMemory() - runtime.freeMemory()).toMebibytes()
    val maxMemory = runtime.maxMemory().toMebibytes()
    val resolvers = mutableListOf<TagResolver>()

    val text = buildString {
        append(createSection("Debug Information"))
        append("<#5ba3d0>Version:</#5ba3d0> ")
        appendUnparsed(plugin.pluginMeta.version, resolvers)
        append("\n<#5ba3d0>Server:</#5ba3d0> ")
        appendUnparsed(server.name, resolvers)
        append(" (")
        appendUnparsed(server.minecraftVersion, resolvers)
        append(")\n")
        append("<#5ba3d0>Uptime:</#5ba3d0> ${formatDuration(ManagementFactory.getRuntimeMXBean().uptime)}\n")
        append("<#5ba3d0>Memory:</#5ba3d0> $usedMemory / $maxMemory MiB\n")
        append("<#5ba3d0>Players:</#5ba3d0> ${server.onlinePlayers.size} / ${server.maxPlayers}\n")
        append("<#5ba3d0>Story content:</#5ba3d0> ${pages.withLabel("page")}, ${entries.withLabel("entry")}\n")
        append("<#5ba3d0>Web panel:</#5ba3d0> ${startedState(panelHost.isStarted)}\n")
        append("<#5ba3d0>Panel connection:</#5ba3d0> ${startedState(socketServer != null)}")
        append(" <gray>·</gray> ${(socketServer?.allClients?.size ?: 0).withLabel("user")} connected\n")

        append("\n<gradient:#ff69b4:#ff1493><bold>Extensions:</bold></gradient>\n")
        if (extensionLoader.extensions.isEmpty()) {
            append("  <gray>No extensions found.</gray>\n")
        }

        extensionLoader.loadedExtensions.sortedBy { it.info.name }.forEach {
            append("  <#7ed957>✓</#7ed957> <white>")
            appendUnparsed("${it.info.name} Extension", resolvers)
            append("</white> <gray>")
            appendUnparsed(it.info.version, resolvers)
            append("</gray>\n")
        }
        extensionLoader.failedExtensions.sortedBy { it.info?.name ?: it.jarName }.forEach {
            val name = it.info?.name?.let { name -> "$name Extension" } ?: it.jarName
            append("  <red>✕ ")
            appendUnparsed(name, resolvers)
            append("</red> <#ff8888>(")
            appendUnparsed(it.reason.message, resolvers)
            append(")</#ff8888>\n")
        }

        append(createFooter())
    }

    return DebugMessage(text, resolvers.toTypedArray())
}

private fun startedState(started: Boolean): String =
    if (started) "<green>Started</green>" else "<gray>Not started</gray>"

private fun Int.withLabel(singular: String): String =
    "$this ${if (this == 1) singular else "${singular}s"}"

internal fun formatDuration(milliseconds: Long): String {
    val totalSeconds = milliseconds.coerceAtLeast(0) / 1_000
    val days = totalSeconds / 86_400
    val hours = totalSeconds % 86_400 / 3_600
    val minutes = totalSeconds % 3_600 / 60
    val seconds = totalSeconds % 60

    return buildList {
        if (days > 0) add("${days}d")
        if (hours > 0 || days > 0) add("${hours}h")
        if (minutes > 0 || hours > 0 || days > 0) add("${minutes}m")
        add("${seconds}s")
    }.joinToString(" ")
}

private fun Long.toMebibytes(): Long = this / (1024 * 1024)

private data class DebugMessage(
    val text: String,
    val resolvers: Array<TagResolver>,
)

internal fun StringBuilder.appendUnparsed(value: String, resolvers: MutableList<TagResolver>) {
    val name = "debug_value_${resolvers.size}"
    append("<$name>")
    resolvers += Placeholder.unparsed(name, value)
}
