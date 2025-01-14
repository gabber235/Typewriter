package com.typewritermc.engine.paper

import com.typewritermc.core.books.pages.PageType
import com.typewritermc.core.entries.Entry
import com.typewritermc.core.entries.Page
import com.typewritermc.core.entries.Query
import com.typewritermc.core.entries.formattedName
import com.typewritermc.core.interaction.context
import com.typewritermc.engine.paper.entry.TriggerableEntry
import com.typewritermc.engine.paper.entry.audienceState
import com.typewritermc.engine.paper.entry.entries.*
import com.typewritermc.engine.paper.entry.inAudience
import com.typewritermc.engine.paper.entry.temporal.temporalCommands
import com.typewritermc.engine.paper.entry.triggerFor
import com.typewritermc.engine.paper.interaction.chatHistory
import com.typewritermc.engine.paper.ui.CommunicationHandler
import com.typewritermc.engine.paper.utils.ThreadType
import com.typewritermc.engine.paper.utils.asMini
import com.typewritermc.engine.paper.utils.msg
import com.typewritermc.engine.paper.utils.sendMini
import com.typewritermc.loader.ExtensionLoader
import dev.jorel.commandapi.CommandTree
import dev.jorel.commandapi.StringTooltip
import dev.jorel.commandapi.arguments.Argument
import dev.jorel.commandapi.arguments.ArgumentSuggestions
import dev.jorel.commandapi.arguments.CustomArgument
import dev.jorel.commandapi.arguments.CustomArgument.CustomArgumentException
import dev.jorel.commandapi.arguments.CustomArgument.MessageBuilder
import dev.jorel.commandapi.arguments.StringArgument
import dev.jorel.commandapi.executors.CommandArguments
import dev.jorel.commandapi.kotlindsl.*
import net.kyori.adventure.inventory.Book
import org.bukkit.command.CommandSender
import org.bukkit.entity.Player
import org.koin.java.KoinJavaComponent.get
import java.time.format.DateTimeFormatter
import kotlin.reflect.KClass

fun typeWriterCommand() = commandTree("typewriter") {
    withAliases("tw")

    reloadCommands()
    factsCommands()
    clearChatCommand()
    connectCommand()
    triggerCommand()
    manifestCommands()
    temporalCommands()

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

private fun CommandTree.reloadCommands() = literalArgument("reload") {
    withPermission("typewriter.reload")
    anyExecutor { sender, _ ->
        sender.msg("Reloading configuration...")
        ThreadType.DISPATCHERS_ASYNC.launch {
            plugin.reload()
            sender.msg("Configuration reloaded!")
        }
    }
}

private fun CommandTree.factsCommands() = literalArgument("facts") {
    withPermission("typewriter.facts")

    literalArgument("set") {
        withPermission("typewriter.facts.set")
        argument(entryArgument<WritableFactEntry>("fact")) {
            integerArgument("value") {
                optionalTarget {
                    anyExecutor { sender, args ->
                        val target = args.targetOrSelfPlayer(sender) ?: return@anyExecutor
                        val fact = args["fact"] as WritableFactEntry
                        val value = args["value"] as Int
                        fact.write(target, value)
                        sender.msg("Fact <blue>${fact.formattedName}</blue> set to $value for ${target.name}.")
                    }
                }
            }
        }
    }

    literalArgument("reset") {
        withPermission("typewriter.facts.reset")
        optionalTarget {
            anyExecutor { sender, args ->
                val target = args.targetOrSelfPlayer(sender) ?: return@anyExecutor
                val entries = Query.find<WritableFactEntry>().toList()
                if (entries.isEmpty()) {
                    sender.msg("There are no facts available.")
                    return@anyExecutor
                }

                for (entry in entries) {
                    entry.write(target, 0)
                }
                sender.msg("All facts for <green>${target.name}</green> have been reset.")
            }
        }
    }

    literalArgument("query") {
        argument(entryArgument<ReadableFactEntry>("fact")) {
            optionalTarget {
                anyExecutor { sender, args ->
                    val target = args.targetOrSelfPlayer(sender) ?: return@anyExecutor
                    val fact = args["fact"] as ReadableFactEntry
                    sender.sendMini("Fact for <green>${target.name}</green>:")
                    sender.sendMini(fact.format(target))
                }
            }
        }
    }

    literalArgument("inspect") {
        argument(pages("page", PageType.STATIC)) {
            optionalTarget {
                anyExecutor { sender, args ->
                    val target = args.targetOrSelfPlayer(sender) ?: return@anyExecutor
                    val page = args["page"] as Page
                    val facts = page.entries.filterIsInstance<ReadableFactEntry>().sortedBy { it.name }
                    sender.sendMini("Facts on page <blue>${page.name}</blue> for <green>${target.name}</green>:")

                    if (facts.isEmpty()) {
                        sender.msg("There are no facts on this page.")
                        return@anyExecutor
                    }

                    for (fact in facts) {
                        sender.sendMini(fact.format(target))
                    }
                }
            }
        }
    }

    optionalTarget {
        anyExecutor { sender, args ->
            val target = args.targetOrSelfPlayer(sender) ?: return@anyExecutor

            val factEntries = Query.find<ReadableFactEntry>().toList()
            if (factEntries.isEmpty()) {
                sender.msg("There are no facts available.")
                return@anyExecutor
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
                    |<gray>Use <white>/tw facts [fact_id/page_name] </white>to query them.
                    """.trimMargin()
                )
            }
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

private fun CommandTree.clearChatCommand() = literalArgument("clearChat") {
    withPermission("typewriter.clearChat")
    playerExecutor { player, _ ->
        player.chatHistory.let {
            it.clear()
            it.allowedMessageThrough()
            it.resendMessages(player)
        }
    }
}

private fun CommandTree.connectCommand() {
    val communicationHandler: CommunicationHandler = get(CommunicationHandler::class.java)
    literalArgument("connect") {
        withPermission("typewriter.connect")
        consoleExecutor { console, _ ->
            if (communicationHandler.server == null) {
                console.msg("The server is not hosting the websocket. Try and enable it in the config.")
                return@consoleExecutor
            }

            val url = communicationHandler.generateUrl(playerId = null)
            console.msg("Connect to<blue> $url </blue>to start the connection.")
        }
        playerExecutor { player, _ ->
            if (communicationHandler.server == null) {
                player.msg("The server is not hosting the websocket. Try and enable it in the config.")
                return@playerExecutor
            }

            val url = communicationHandler.generateUrl(player.uniqueId)

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
}

private fun CommandTree.triggerCommand() = literalArgument("trigger") {
    withPermission("typewriter.trigger")

    argument(entryArgument<TriggerableEntry>("entry")) {
        optionalTarget {
            anyExecutor { sender, args ->
                val target = args.targetOrSelfPlayer(sender) ?: return@anyExecutor
                val entry = args["entry"] as TriggerableEntry
                EntryTrigger(entry).triggerFor(target, context())
            }
        }
    }
}

private fun CommandTree.manifestCommands() = literalArgument("manifest") {
    literalArgument("inspect") {
        withPermission("typewriter.manifest.inspect")

        optionalTarget {
            anyExecutor { sender, args ->
                val target = args.targetOrSelfPlayer(sender) ?: return@anyExecutor
                val inEntries = Query.findWhere<AudienceEntry> { target.inAudience(it) }.sortedBy { it.name }.toList()
                if (inEntries.none()) {
                    sender.msg("You are not in any audience entries.")
                    return@anyExecutor
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
    }

    literalArgument("page") {
        argument(pages("page", PageType.MANIFEST)) {
            optionalTarget {
                anyExecutor { sender, args ->
                    val target = args.targetOrSelfPlayer(sender) ?: return@anyExecutor
                    val page = args["page"] as Page
                    val audienceEntries =
                        page.entries.filterIsInstance<AudienceEntry>().sortedBy { it.name }.toList()

                    if (audienceEntries.isEmpty()) {
                        sender.msg("No audience entries found on page ${page.name}")
                        return@anyExecutor
                    }

                    val entryStates = audienceEntries.groupBy { target.audienceState(it) }

                    sender.sendMini("\n\n")
                    sender.msg("These are the audience entries on page <i>${page.name}</i>:")
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
}

fun CommandArguments.targetOrSelfPlayer(commandSender: CommandSender): Player? {
    val target = this["target"] as? Player
    if (target != null) return target
    val self = commandSender as? Player
    if (self != null) return self
    commandSender.msg("<red>You must specify a target to execute this command on.")
    return null
}

fun Argument<*>.optionalTarget(block: Argument<*>.() -> Unit) = playerArgument("target", optional = true, block)

inline fun <reified E : Entry> entryArgument(name: String): Argument<E> = entryArgument(name, E::class)

fun <E : Entry> entryArgument(name: String, klass: KClass<E>): Argument<E> {
    return CustomArgument(StringArgument(name)) { info ->
        Query.findById(klass, info.input)
            ?: Query.findByName(klass, info.input)
            ?: throw CustomArgumentException.fromMessageBuilder(MessageBuilder("Could not find entry: ").appendArgInput())
    }.replaceSuggestions(ArgumentSuggestions.stringsWithTooltips { _ ->
        Query.find(klass).map {
            StringTooltip.ofString(it.name, it.id)
        }.toList().toTypedArray()
    })
}


fun pages(name: String, type: PageType): Argument<Page> = CustomArgument(StringArgument(name)) { info ->
    val pages = Query.findPagesOfType(type).toList()
    val page = pages.firstOrNull { it.id == info.input || it.name == info.input }
    if (page == null) {
        throw CustomArgumentException.fromMessageBuilder(MessageBuilder("Page does not exist."))
    }
    page
}.replaceSuggestions(ArgumentSuggestions.stringsWithTooltips { _ ->
    val pages = Query.findPagesOfType(type).toList()
    pages.map {
        StringTooltip.ofString(it.name, it.name)
    }.toList().toTypedArray()
})