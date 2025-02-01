@file:Suppress("UnstableApiUsage")

package com.typewritermc.engine.paper.command

import com.typewritermc.core.books.pages.PageType
import com.typewritermc.core.entries.Query
import com.typewritermc.core.entries.formattedName
import com.typewritermc.core.interaction.context
import com.typewritermc.engine.paper.command.dsl.*
import com.typewritermc.engine.paper.entry.TriggerableEntry
import com.typewritermc.engine.paper.entry.audienceState
import com.typewritermc.engine.paper.entry.entries.*
import com.typewritermc.engine.paper.entry.inAudience
import com.typewritermc.engine.paper.entry.temporal.temporalCommand
import com.typewritermc.engine.paper.entry.triggerFor
import com.typewritermc.engine.paper.interaction.chatHistory
import com.typewritermc.engine.paper.plugin
import com.typewritermc.engine.paper.ui.CommunicationHandler
import com.typewritermc.engine.paper.utils.ThreadType
import com.typewritermc.engine.paper.utils.asMini
import com.typewritermc.engine.paper.utils.msg
import com.typewritermc.engine.paper.utils.sendMini
import com.typewritermc.loader.ExtensionLoader
import io.papermc.paper.command.brigadier.CommandSourceStack
import net.kyori.adventure.inventory.Book
import org.bukkit.entity.Player
import org.koin.java.KoinJavaComponent.get
import java.time.format.DateTimeFormatter

fun typewriterCommand() = command<CommandSourceStack>("typewriter", "tw") {
    reloadCommand()
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
    extensionLoader.extensions.flatMap { it.typewriterCommands }
        .map {
            val clazz = extensionLoader.loadClass(it.className)
            clazz.getMethod(it.methodName, CommandTree::class.java)
        }
        .forEach {
            it.invoke(null, this)
        }
}

private fun CommandTree.reloadCommand() = literal("reload") {
    withPermission("typewriter.reload")
    executes {
        sender.msg("Reloading configuration...")
        ThreadType.DISPATCHERS_ASYNC.launch {
            plugin.reload()
            sender.msg("Configuration reloaded!")
        }
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