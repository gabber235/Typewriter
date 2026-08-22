package com.typewritermc.engine.paper.command

import com.mojang.brigadier.CommandDispatcher
import com.mojang.brigadier.builder.LiteralArgumentBuilder
import com.mojang.brigadier.tree.CommandNode
import com.mojang.brigadier.tree.LiteralCommandNode
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.Query
import com.typewritermc.core.utils.launch
import com.typewritermc.engine.paper.command.dsl.DslCommand
import com.typewritermc.engine.paper.entry.matches
import com.typewritermc.engine.paper.entry.entries.CustomCommandEntry
import com.typewritermc.engine.paper.entry.entries.ReadableFactEntry
import com.typewritermc.engine.paper.facts.FactListenerSubscription
import com.typewritermc.engine.paper.facts.listenForFacts
import com.typewritermc.engine.paper.plugin
import com.typewritermc.engine.paper.utils.Sync
import com.typewritermc.engine.paper.utils.server
import io.papermc.paper.command.brigadier.CommandSourceStack
import kotlinx.coroutines.Dispatchers
import org.bukkit.entity.Player
import org.bukkit.event.EventHandler
import org.bukkit.event.EventPriority
import org.bukkit.event.Listener
import org.bukkit.event.player.PlayerJoinEvent
import org.bukkit.event.player.PlayerQuitEvent
import java.lang.invoke.MethodHandles
import java.lang.invoke.MethodType
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap


@Suppress("UnstableApiUsage")
class TypewriterCommandManager : Listener {
    private var dispatcher: CommandDispatcher<CommandSourceStack>? = null
    private var commandsLabels = emptyList<String>()
    private var criteriaFacts = emptyList<Ref<ReadableFactEntry>>()
    private val criteriaSubscriptions = ConcurrentHashMap<UUID, FactListenerSubscription>()

    val labels: List<String>
        get() = commandsLabels

    /** Call once during plugin startup, after player sessions initialize and before custom commands register. */
    fun initialize() {
        plugin.server.pluginManager.registerEvents(this, plugin)
    }

    fun registerDispatcher(dispatcher: CommandDispatcher<CommandSourceStack>) {
        this.dispatcher = dispatcher
    }

    fun registerCommands() {
        val dispatcher = this.dispatcher
        if (dispatcher == null) {
            throw IllegalStateException("TypewriterCommandManager has not been initialized with a dispatcher")
        }

        val customCommands = Query.find<CustomCommandEntry>().toList()
        criteriaFacts = customCommands.flatMap { entry -> entry.criteria.map { it.fact } }.distinct()

        val commands = listOf(
            typewriterCommand(),
        )

        commandsLabels = commands.flatMap {
            dispatcher.register(it, plugin.name.lowercase())
        } + customCommands.flatMap { entry ->
            dispatcher.register(entry.command(), plugin.name.lowercase()) { source ->
                val player = (source.executor as? Player) ?: (source.sender as? Player)
                entry.criteria.isEmpty() || (player != null && entry.criteria.matches(player))
            }
        }

        resetCriteriaSubscriptions()
        server.onlinePlayers.forEach { player ->
            player.watchCommandCriteria()
            player.updateCommands()
        }
    }


    fun unregisterCommands() {
        val dispatcher = this.dispatcher
        if (dispatcher == null) {
            throw IllegalStateException("TypewriterCommandManager has not been initialized with a dispatcher")
        }

        commandsLabels.forEach {
            dispatcher.unregister(it)
        }

        criteriaFacts = emptyList()
        resetCriteriaSubscriptions()
    }

    private fun Player.watchCommandCriteria() {
        if (criteriaFacts.isEmpty()) return

        criteriaSubscriptions[uniqueId] = listenForFacts(criteriaFacts) {
            Dispatchers.Sync.launch {
                player.updateCommands()
            }
        }
    }

    private fun resetCriteriaSubscriptions() {
        criteriaSubscriptions.forEach { (playerId, subscription) ->
            server.getPlayer(playerId)?.let(subscription::cancel)
        }
        criteriaSubscriptions.clear()
    }

    @EventHandler(priority = EventPriority.MONITOR)
    private fun onPlayerJoin(event: PlayerJoinEvent) {
        event.player.watchCommandCriteria()
    }

    @EventHandler
    private fun onPlayerQuit(event: PlayerQuitEvent) {
        criteriaSubscriptions.remove(event.player.uniqueId)?.cancel(event.player)
    }
}

private val removeCommandMethod by lazy {
    MethodHandles.lookup().findVirtual(
        CommandNode::class.java,
        "removeCommand",
        MethodType.methodType(Void.TYPE, String::class.java)
    )
}

fun <S> CommandDispatcher<S>.unregister(literal: String) {
    try {
        removeCommandMethod.invoke(this.root, literal)
    } catch (e: Throwable) {
        e.printStackTrace()
    }
}

fun <S> CommandDispatcher<S>.register(command: DslCommand<S>, identifier: String): List<String> {
    return register(command, identifier) { true }
}

fun <S> CommandDispatcher<S>.register(
    command: DslCommand<S>,
    identifier: String,
    additionalRequirement: (S) -> Boolean,
): List<String> {
    val commandsLabels = mutableListOf<String>()
    val sourceCommand = LiteralArgumentBuilder.literal<S>("$identifier:${command.literal}")
        .executes(command.node.command)
        .requires { source -> command.node.requirement.test(source) && additionalRequirement(source) }
        .build()
        .apply {
            command.node.children.forEach(this::addChild)
        }

    register(sourceCommand)
    commandsLabels.add(sourceCommand.literal)

    registerRedirect(command.literal, sourceCommand)
    commandsLabels.add(command.literal)

    command.aliases.forEach {
        registerRedirect(it, sourceCommand)
        commandsLabels.add(it)

        val alias = "$identifier:$it"
        registerRedirect(alias, sourceCommand)
        commandsLabels.add(alias)
    }

    return commandsLabels
}

fun <S> CommandDispatcher<S>.registerRedirect(aliasLiteral: String, target: LiteralCommandNode<S>) {
    val redirect = LiteralArgumentBuilder.literal<S>(aliasLiteral)
        .executes(target.command)
        .redirect(target)
        .requires(target.requirement)
        .build()

    register(redirect)
}

private fun <S> CommandDispatcher<S>.register(node: LiteralCommandNode<S>) {
    root.getChild(node.literal)?.let {
        unregister(node.literal)
    }
    root.addChild(node)
}
