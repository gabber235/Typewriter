package com.typewritermc.playtest.plugin

import org.bukkit.Bukkit
import org.bukkit.entity.Player
import org.bukkit.event.EventHandler
import org.bukkit.event.Listener
import org.bukkit.metadata.FixedMetadataValue
import org.bukkit.permissions.PermissionAttachment
import org.bukkit.plugin.Plugin
import org.bukkit.scheduler.BukkitTask
import skirout.harness.v1.wire.StateKind
import java.io.IOException
import java.io.UncheckedIOException
import java.nio.charset.StandardCharsets
import java.nio.file.Files
import java.nio.file.Path
import java.nio.file.StandardOpenOption
import java.util.Properties
import java.util.UUID

private const val MARK = "playtest-mark"
private const val PERMISSION = "playtest.mark"

/** A hold outlives its end by a minute, so an attempt that starts within it would adopt it. */
private const val HOLD_GRACE_TICKS = 20L * 60

/**
 * State this plugin keeps per player in each of the ways plugins keep it: a stored value and a stored
 * permission in a file, a permission attachment, metadata, a session with its history, queued mail, and
 * a hold that lives on for a grace after it ends. Only the framework's own test kit marks it, to prove
 * that a plugin which resets what it owns on the [PlayerWipeEvent] leaks nothing into the next
 * attempt. Main thread only.
 */
internal class Owned(
    private val plugin: Plugin,
) : Listener {
    private val stored: Path = plugin.dataFolder.toPath().resolve("stored")
    private val mail: Path = plugin.dataFolder.toPath().resolve("mail")
    private val attachments = HashMap<UUID, PermissionAttachment>()
    private val sessions = HashMap<UUID, MutableList<String>>()
    private val holds = HashMap<UUID, BukkitTask>()

    /** Leaves a mark of [kind] on the player, as an earlier attempt could. */
    @Suppress("DEPRECATION") // Paper deprecates metadata, which plugins still set and this kind stands for.
    fun mark(
        player: Player,
        kind: StateKind,
    ) {
        val id = player.uniqueId
        when (kind.kind) {
            StateKind.Kind.STORED_VALUE_CONST -> {
                store(id, "value", MARK)
            }

            StateKind.Kind.STORED_PERMISSION_CONST -> {
                store(id, "permission", PERMISSION)
            }

            StateKind.Kind.ATTACHED_PERMISSION_CONST -> {
                attachments.getOrPut(id) { player.addAttachment(plugin) }.setPermission(PERMISSION, true)
            }

            StateKind.Kind.METADATA_CONST -> {
                player.setMetadata(MARK, FixedMetadataValue(plugin, MARK))
            }

            StateKind.Kind.SESSION_CONST -> {
                sessions.getOrPut(id) { ArrayList() }.add(MARK)
            }

            StateKind.Kind.MAIL_CONST -> {
                append(mail.resolve("$id.txt"), MARK)
            }

            StateKind.Kind.HOLD_CONST -> {
                val old = holds.put(id, Bukkit.getScheduler().runTaskLater(plugin, Runnable { holds.remove(id) }, HOLD_GRACE_TICKS))
                old?.cancel()
            }

            else -> {
                throw IllegalArgumentException("$kind is a kind Paper keeps, not a plugin")
            }
        }
    }

    /** Whether the player carries any mark of [kind] this plugin keeps. */
    fun marked(
        player: Player,
        kind: StateKind,
    ): Boolean {
        val id = player.uniqueId
        return when (kind.kind) {
            StateKind.Kind.STORED_VALUE_CONST -> load(id).containsKey("value")
            StateKind.Kind.STORED_PERMISSION_CONST -> load(id).containsKey("permission")
            StateKind.Kind.ATTACHED_PERMISSION_CONST -> player.hasPermission(PERMISSION)
            StateKind.Kind.METADATA_CONST -> player.hasMetadata(MARK)
            StateKind.Kind.SESSION_CONST -> sessions.containsKey(id)
            StateKind.Kind.MAIL_CONST -> Files.exists(mail.resolve("$id.txt"))
            StateKind.Kind.HOLD_CONST -> holds.containsKey(id)
            else -> throw IllegalArgumentException("$kind is a kind Paper keeps, not a plugin")
        }
    }

    /** Paper wiped the player: everything this plugin keeps for it goes, as for a player who never played. */
    @EventHandler
    fun onWipe(event: PlayerWipeEvent) {
        val player = event.player
        val id = player.uniqueId
        delete(stored.resolve("$id.properties"))
        attachments.remove(id)?.remove()
        player.removeMetadata(MARK, plugin)
        sessions.remove(id)
        delete(mail.resolve("$id.txt"))
        holds.remove(id)?.cancel()
    }

    private fun load(id: UUID): Properties {
        val properties = Properties()
        val file = stored.resolve("$id.properties")
        if (!Files.exists(file)) return properties
        try {
            Files.newBufferedReader(file, StandardCharsets.UTF_8).use { properties.load(it) }
        } catch (unreadable: IOException) {
            throw UncheckedIOException(unreadable)
        }
        return properties
    }

    private fun store(
        id: UUID,
        key: String,
        value: String,
    ) {
        val properties = load(id)
        properties.setProperty(key, value)
        try {
            Files.createDirectories(stored)
            Files.newBufferedWriter(stored.resolve("$id.properties"), StandardCharsets.UTF_8).use { properties.store(it, null) }
        } catch (unwritable: IOException) {
            throw UncheckedIOException(unwritable)
        }
    }

    companion object {
        /** The kinds this plugin keeps, which it resets when Paper wipes a player. */
        val KINDS: Set<StateKind> =
            setOf(
                StateKind.STORED_VALUE,
                StateKind.STORED_PERMISSION,
                StateKind.ATTACHED_PERMISSION,
                StateKind.METADATA,
                StateKind.SESSION,
                StateKind.MAIL,
                StateKind.HOLD,
            )
    }
}

private fun append(
    file: Path,
    line: String,
) {
    try {
        Files.createDirectories(file.parent)
        Files.writeString(file, line + "\n", StandardCharsets.UTF_8, StandardOpenOption.CREATE, StandardOpenOption.APPEND)
    } catch (unwritable: IOException) {
        throw UncheckedIOException(unwritable)
    }
}

private fun delete(file: Path) {
    try {
        Files.deleteIfExists(file)
    } catch (undeletable: IOException) {
        throw UncheckedIOException(undeletable)
    }
}
