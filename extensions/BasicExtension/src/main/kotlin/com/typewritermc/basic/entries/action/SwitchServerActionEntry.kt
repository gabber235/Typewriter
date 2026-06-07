package com.typewritermc.basic.entries.action

import com.google.common.io.ByteStreams
import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.extension.annotations.LabelKey
import com.typewritermc.engine.paper.entry.Criteria
import com.typewritermc.engine.paper.entry.Modifier
import com.typewritermc.core.entries.Ref
import com.typewritermc.engine.paper.entry.TriggerableEntry
import com.typewritermc.engine.paper.entry.entries.ActionEntry
import com.typewritermc.engine.paper.entry.entries.ActionTrigger
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.plugin
import org.bukkit.entity.Player

@Entry("switch_server_action", "Switches the player to another server", Colors.RED, "fluent:server-link-16-filled")
/**
 * The `Switch Server Action` is an action that switches the player to another server.
 *
 * ## How could this be used?
 *
 * This could be used to switch a player from one server to another when interacting with an entity, maybe clicking a button.
 */
class SwitchServerActionEntry(
    override val id: String = "",
    override val name: String = "",
    override val criteria: List<Criteria> = emptyList(),
    override val modifiers: List<Modifier> = emptyList(),
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),
    @LabelKey("basic.switch_server_action.fields.server.label")
    @Help(key = "basic.switch_server_action.fields.server.help")
    val server: Var<String> = ConstVar(""),
): ActionEntry {
    override fun ActionTrigger.execute() {
        plugin.server.messenger.registerOutgoingPluginChannel(plugin, "BungeeCord")

        val out = ByteStreams.newDataOutput()
        out.writeUTF("Connect")
        out.writeUTF(server.get(player, context))
        player.sendPluginMessage(plugin, "BungeeCord", out.toByteArray())

        plugin.server.messenger.unregisterOutgoingPluginChannel(plugin, "BungeeCord")
    }
}