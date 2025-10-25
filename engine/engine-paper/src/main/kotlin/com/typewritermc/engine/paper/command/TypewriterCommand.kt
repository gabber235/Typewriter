@file:Suppress("UnstableApiUsage")

package com.typewritermc.engine.paper.command

import com.typewritermc.core.books.pages.PageType
import com.typewritermc.core.entries.Query
import com.typewritermc.core.entries.formattedName
import com.typewritermc.core.interaction.context
import com.typewritermc.core.utils.UntickedAsync
import com.typewritermc.core.utils.launch
import com.typewritermc.engine.paper.command.dsl.*
import com.typewritermc.engine.paper.entry.TriggerableEntry
import com.typewritermc.engine.paper.entry.audienceState
import com.typewritermc.engine.paper.entry.entries.*
import com.typewritermc.engine.paper.entry.inAudience
import com.typewritermc.engine.paper.entry.temporal.temporalCommand
import com.typewritermc.engine.paper.entry.triggerFor
import com.typewritermc.engine.paper.interaction.chatHistory
import com.typewritermc.engine.paper.logger
import com.typewritermc.engine.paper.plugin
import com.typewritermc.engine.paper.ui.CommunicationHandler
import com.typewritermc.engine.paper.utils.asMini
import com.typewritermc.engine.paper.utils.msg
import com.typewritermc.engine.paper.utils.sendMini
import com.typewritermc.loader.Extension
import com.typewritermc.loader.ExtensionFlag
import com.typewritermc.loader.ExtensionInfo
import com.typewritermc.loader.ExtensionLoader
import kotlinx.coroutines.Dispatchers
import net.kyori.adventure.inventory.Book
import org.bukkit.command.CommandSender
import org.bukkit.entity.Player
import org.koin.java.KoinJavaComponent.get
import java.time.format.DateTimeFormatter

fun typewriterCommand() = command("typewriter", "tw") {
    versionCommand()
    reloadCommand()
    extensionsCommand()
    factsCommand()
    clearChatCommand()
    connectCommand()
    triggerCommand()
    manifestCommand()
    temporalCommand()

    registerDynamicCommands()
}


fun CommandTree.registerDynamicCommands() {
    val extensionLoader = get<ExtensionLoader>(ExtensionLoader::class.java)
    extensionLoader.loadedExtensions.flatMap { it.typewriterCommands }
        .map {
            val clazz = extensionLoader.loadClass(it.className)
            clazz.getMethod(it.methodName, CommandTree::class.java)
        }
        .forEach {
            try {
                it.invoke(null, this)
            } catch (t: Throwable) {
                logger.severe("Exception thrown while registering command '${it.declaringClass.simpleName}'.")
                t.printStackTrace()
            }
        }
}

private fun CommandTree.versionCommand() = literal("version") {
    withPermission("typewriter.version")
    executes {
        sender.msg("You are running typewriter version: <b>${plugin.pluginMeta.version}</b>")
    }
}

private fun CommandTree.reloadCommand() = literal("reload") {
    withPermission("typewriter.reload")
    executes {
        sender.msg("Reloading configuration...")
        Dispatchers.UntickedAsync.launch {
            plugin.reload()
            sender.msg("Configuration reloaded!")
        }
    }
}

private fun CommandTree.extensionsCommand() = literal("extensions") {
    withPermission("typewriter.extensions")

    literal("info") {
        withPermission("typewriter.extensions.info")
        extension<Extension>("extension") { extension ->
            executes {
                when (val extension = extension()) {
                    is Extension.LoadedExtension -> sender.displayLoadedExtension(extension)
                    is Extension.FailedExtension -> sender.displayFailedExtension(extension)
                }
            }
        }
    }

    executes {
        val extensionLoader = get<ExtensionLoader>(ExtensionLoader::class.java)
        val loaded = extensionLoader.loadedExtensions
        val failed = extensionLoader.failedExtensions

        if (loaded.isEmpty() && failed.isEmpty()) {
            sender.msg("No extensions found.")
            return@executes
        }

        sender.displayExtensionsList(loaded, failed)
    }
}

private fun CommandSender.displayExtensionsList(
    loaded: List<Extension.LoadedExtension>,
    failed: List<Extension.FailedExtension>
) {
    val message = buildString {
        append(createSection("Extensions"))

        if (loaded.isNotEmpty()) {
            append("<#7ed957><b>Loaded</b> (${loaded.size}):</#7ed957>\n")

            loaded
                .sortedBy { it.info.name }
                .forEach { ext ->
                    val info = ext.info
                    val flags = info.flags.joinToString(" ") { it.warning }
                        .takeIf { it.isNotBlank() }?.let { " $it" } ?: ""

                    append(
                        "  <hover:show_text:'<gray>Click for details</gray>'>" +
                                "<click:run_command:'/tw extensions info ${info.namespace}:${info.name}'>" +
                                "<#7ed957>•</#7ed957> <white>${info.name}Extension</white> <#a0a0a0>(${info.version})</#a0a0a0>$flags" +
                                "</click></hover>\n"
                    )
                }

            val unsupportedCount = loaded.count { it.info.flags.contains(ExtensionFlag.Unsupported) }
            if (unsupportedCount > 0) {
                val plural = if (unsupportedCount > 1) "s" else ""
                append("\n  <yellow>⚠️  $unsupportedCount unsupported extension$plural detected</yellow>\n")
            }
        }

        if (failed.isNotEmpty()) {
            if (loaded.isNotEmpty()) append("\n")
            append("<#ff5555><b>Failed</b> (${failed.size}):</#ff5555>\n")

            failed.sortedBy { it.info?.name ?: it.jarName }.forEach { failure ->
                val displayName = failure.info?.name?.let { "${it}Extension" }
                    ?: failure.jarName.removeSuffix(".jar")
                val reason = failure.reason.message

                val content = "<#ff5555>•</#ff5555> <red>$displayName</red> <italic><#ff8888>($reason)</#ff8888>"

                failure.info?.let { info ->
                    append(
                        "  <hover:show_text:'<gray>Click for details</gray>'>" +
                                "<click:run_command:'/tw extensions info ${info.namespace}:${info.name}'>$content</click></hover>\n"
                    )
                } ?: append("  $content\n")
            }
        }

        append(createFooter())
    }

    sendMini(message)
}

private fun CommandSender.displayLoadedExtension(extension: Extension.LoadedExtension) {
    val info = extension.info

    val message = buildString {
        append(createExtensionHeader(info, isLoaded = true))
        append(createExtensionBasicInfo(info))

        append("\n<gradient:#ff69b4:#ff1493><bold>Components:</bold></gradient>\n")
        mapOf(
            "Entries" to extension.entries.size,
            "Listeners" to extension.entryListeners.size,
            "Injections" to extension.dependencyInjections.size,
            "Commands" to extension.typewriterCommands.size
        ).forEach { (label, count) ->
            append("  <#ff69b4>▸</#ff69b4> <#b8b8b8>$label:</#b8b8b8> <white>$count</white>\n")
        }

        if (info.dependencies.isNotEmpty()) {
            append("\n<#00d4ff>Extension Dependencies:</#00d4ff>\n")
            info.dependencies.forEach { dep ->
                append("  <#00d4ff>▸</#00d4ff> <white>${dep.name}</white> <dark_gray>·</dark_gray> <#a0a0a0>${dep.namespace}</#a0a0a0>\n")
            }
        }

        info.paper?.dependencies?.takeIf { it.isNotEmpty() }?.let { deps ->
            append("\n<#00d4ff>External Dependencies:</#00d4ff>\n")
            deps.forEach { append("  <#00d4ff>▸</#00d4ff> <white>$it</white>\n") }
        }

        if (info.flags.isNotEmpty()) {
            append("\n<gradient:#a855f7:#9333ea><bold>Flags:</bold></gradient>\n")
            info.flags.forEach { append("  ${it.warning}\n") }
        }

        append(createFooter())
    }

    sendMini(message)
}

private fun CommandSender.displayFailedExtension(failure: Extension.FailedExtension) {
    val message = buildString {
        failure.info?.let { info ->
            append(createExtensionHeader(info, isLoaded = false))
            append(createExtensionBasicInfo(info))
        } ?: run {
            append(createSection("Extension Details"))
            append("<red><b>${failure.jarName}</b> (Not Loaded)</red>\n")
            append("<gray>JAR file:</gray> ${failure.jarName}\n")
        }

        append("\n<red><b>Failure Reason:</b></red>\n")
        append("  ${failure.reason.message}\n")
        append(createFooter())
    }

    sendMini(message)
}

private fun createSection(title: String): String {
    val (leftPadding, rightPadding) = calculatePadding(title)
    return "\n<gradient:#00d4ff:#0099ff><b><st>$leftPadding</st> $title <st>$rightPadding</st></b></gradient>\n\n"
}

private fun createFooter(): String =
    "\n<gradient:#00d4ff:#0099ff><b><st>${" ".repeat(53)}</st></b></gradient>\n"

private fun calculatePadding(title: String): Pair<String, String> {
    val remainingSpace = (50 - title.length - 2).coerceAtLeast(2)
    val leftPadding = remainingSpace / 2
    val rightPadding = remainingSpace - leftPadding  // Takes the extra space if odd
    return " ".repeat(leftPadding) to " ".repeat(rightPadding)
}

private fun createExtensionHeader(info: ExtensionInfo, isLoaded: Boolean): String {
    val (color, status) = if (isLoaded) "gradient:#7ed957:#00d4ff" to "" else "red" to " (Not Loaded)"
    return buildString {
        append(createSection("Extension Details"))
        append("<$color><b>${info.name}Extension</b>$status</$color>\n")
    }
}

private fun createExtensionBasicInfo(info: ExtensionInfo): String = buildString {
    append("<#5ba3d0>Version:</#5ba3d0> ${info.version}\n")
    append("<#5ba3d0>Namespace:</#5ba3d0> ${info.namespace}\n")
    append("<#5ba3d0>Engine Version:</#5ba3d0> ${info.engineVersion}\n")

    if (info.shortDescription.isNotBlank()) {
        append("\n<gradient:#ffd700:#ffaa00><bold>Description:</bold></gradient>\n")
        append("<#e0e0e0>${info.shortDescription}</#e0e0e0>\n")
    }
}

private fun CommandTree.factsCommand() = literal("facts") {
    withPermission("typewriter.facts")


    literal("set") {
        withPermission("typewriter.facts.set")
        entry<WritableFactEntry>("fact") { fact ->
            int("value") { value ->
                executePlayerOrTarget { target ->
                    fact().write(target, value())
                    sender.msg("Fact <blue>${fact().formattedName}</blue> set to ${value()} for ${target.name}.")
                }
            }
        }
    }

    literal("add") {
        withPermission("typewriter.facts.add")
        entry<WritableFactEntry>("fact") { fact ->
            int("value") { value ->
                executePlayerOrTarget { target ->
                    val fact = fact()
                    if (fact !is ReadableFactEntry) {
                        sender.msg("This fact is not readable. Therefore we cannot add to it.")
                        return@executePlayerOrTarget
                    }

                    val current = fact.readForPlayersGroup(target)
                    val newValue = current.value + value()
                    fact().write(target, newValue)
                    sender.msg("Fact <blue>${fact().formattedName}</blue> set to $newValue for ${target.name}.")
                }
            }
        }
    }

    literal("reset") {
        withPermission("typewriter.facts.reset")
        executePlayerOrTarget { target ->
            val entries = Query.find<WritableFactEntry>().toList()
            if (entries.isEmpty()) {
                sender.msg("There are no facts available.")
                return@executePlayerOrTarget
            }

            for (entry in entries) {
                entry.write(target, 0)
            }
            sender.msg("All facts for <green>${target.name}</green> have been reset.")
        }
    }

    literal("query") {
        entry<ReadableFactEntry>("fact") { fact ->
            executePlayerOrTarget { target ->
                sender.sendMini("Fact for <green>${target.name}</green>:")
                sender.sendMini(fact().format(target))
            }
        }
    }

    literal("inspect") {
        page("page", PageType.STATIC) { page ->
            executePlayerOrTarget { target ->
                val facts = page().entries.filterIsInstance<ReadableFactEntry>().sortedBy { it.name }
                sender.sendMini("Facts on page <blue>${page().name}</blue> for <green>${target.name}</green>:")

                if (facts.isEmpty()) {
                    sender.msg("There are no facts on this page.")
                    return@executePlayerOrTarget
                }

                for (fact in facts) {
                    sender.sendMini(fact.format(target))
                }
            }
        }
    }

    executePlayerOrTarget { target ->
        val factEntries = Query.find<ReadableFactEntry>().toList()
        if (factEntries.isEmpty()) {
            sender.msg("There are no facts available.")
            return@executePlayerOrTarget
        }

        sender.sendMini("\n\n")
        sender.msg("<green>${target.name}</green> has the following facts:\n")

        for (entry in factEntries.take(10)) {
            sender.sendMini(entry.format(target))
        }

        val remaining = factEntries.size - 10
        if (remaining > 0) {
            sender.sendMini(
                """
                    |<gray><i>and $remaining more...
                    |
                    |<gray>Use <white>/tw facts query [fact_id] </white>to query a specific fact.
                    |<gray>Use <white>/tw facts inspect [page_name] </white>to inspect all facts on a page.
                    """.trimMargin()
            )
        }
    }
}

private val formatter = DateTimeFormatter.ofPattern("HH:mm:ss dd/MM/yyyy")
private fun ReadableFactEntry.format(player: Player): String {
    val data = readForPlayersGroup(player)
    return "<hover:show_text:'${
        comment.replace(
            Regex(" +"),
            " "
        ).replace("'", "\\'")
    }\n\n<gray><i>Click to modify'><click:suggest_command:'/tw facts set $name ${data.value} ${player.name}'><gray> - </gray><blue>${formattedName}:</blue> ${data.value} <gray><i>(${
        formatter.format(
            data.lastUpdate
        )
    })</i></gray>"
}

private fun CommandTree.clearChatCommand() = literal("clearChat") {
    withPermission("typewriter.clearChat")
    executePlayerOrTarget { player ->
        player.chatHistory.let {
            it.clear()
            it.allowedMessageThrough()
            it.resendMessages(player)
        }
    }
}


private fun CommandTree.connectCommand() = literal("connect") {
    val communicationHandler: CommunicationHandler = get(CommunicationHandler::class.java)
    withPermission("typewriter.connect")
    executes {
        if (communicationHandler.server == null) {
            sender.msg("The server is not hosting the websocket. Try and enable it in the config.")
            return@executes
        }

        val player = (source.executor as? Player) ?: (sender as? Player)
        val url = communicationHandler.generateUrl(player?.uniqueId)

        if (player == null) {
            sender.msg("Connect to<blue> $url </blue>to start the connection.")
            return@executes
        }

        val bookTitle = "<blue>Connect to the server</blue>".asMini()
        val bookAuthor = "<blue>Typewriter</blue>".asMini()

        val bookPage = """
				|<blue><bold>Connect to Panel</bold></blue>
				|
				|<#3e4975>Click on the link below to connect to the panel. Once you are connected, you can start writing.</#3e4975>
				|
				|<hover:show_text:'<gray>Click to open the link'><click:open_url:'$url'><blue>[Link]</blue></click></hover>
				|
				|<gray><i>Because of security reasons, this link will expire in 5 minutes.</i></gray>
			""".trimMargin().asMini()

        val book = Book.book(bookTitle, bookAuthor, bookPage)
        player.openBook(book)
    }
}

private fun CommandTree.triggerCommand() = literal("trigger") {
    withPermission("typewriter.trigger")
    entry<TriggerableEntry>("entry") { entry ->
        executePlayerOrTarget { target ->
            EntryTrigger(entry()).triggerFor(target, context())
        }
    }
}

private fun CommandTree.manifestCommand() = literal("manifest") {
    withPermission("typewriter.manifest")
    literal("inspect") {
        withPermission("typewriter.manifest.inspect")
        executePlayerOrTarget { target ->
            val inEntries = Query.findWhere<AudienceEntry> { target.inAudience(it) }
                .sortedBy { it.name }
                .toList()

            if (inEntries.none()) {
                sender.msg("You are not in any audience entries.")
                return@executePlayerOrTarget
            }

            sender.sendMini("\n\n")
            sender.msg("You are in the following audience entries:")
            for (entry in inEntries) {
                sender.sendMini(
                    "<hover:show_text:'<gray>${entry.id}'><click:copy_to_clipboard:${entry.id}><gray> - </gray><blue>${entry.formattedName}</blue></click></hover>"
                )
            }
        }
    }

    literal("page") {
        withPermission("typewriter.manifest.page")
        page("page", PageType.MANIFEST) { page ->
            executePlayerOrTarget { target ->
                val audienceEntries = page().entries
                    .filterIsInstance<AudienceEntry>()
                    .sortedBy { it.name }
                    .toList()

                if (audienceEntries.isEmpty()) {
                    sender.msg("No audience entries found on page ${page().name}")
                    return@executePlayerOrTarget
                }

                val entryStates = audienceEntries.groupBy { target.audienceState(it) }

                sender.sendMini("\n\n")
                sender.msg("These are the audience entries on page <i>${page().name}</i>:")
                for (state in AudienceDisplayState.entries) {
                    val entries = entryStates[state] ?: continue
                    val color = state.color
                    sender.sendMini("\n<b><$color>${state.displayName}</$color></b>")

                    for (entry in entries) {
                        sender.sendMini(
                            "<hover:show_text:'<gray>${entry.id}'><click:copy_to_clipboard:${entry.id}><gray> - </gray><$color>${entry.formattedName}</$color></click></hover>"
                        )
                    }
                }
            }
        }
    }
}