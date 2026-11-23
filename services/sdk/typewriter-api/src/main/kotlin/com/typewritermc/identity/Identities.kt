package com.typewritermc.identity

import com.typewritermc.types.TypewriterType

/**
 * Something Typewriter tracks across engines by a stable id: values keyed by an identity end when it ends.
 */
@TypewriterType(id = IDENTITY_TYPE_ID)
sealed interface Identity

/**
 * Who an identity acts for: a Minecraft player is `PrincipalId("minecraft", <uuid>)`, a panel user
 * `PrincipalId("user", <user id>)`.
 */
@TypewriterType(id = PRINCIPAL_ID_TYPE_ID)
data class PrincipalId(
    val kind: String,
    val id: String,
) {
    init {
        require(kind.isNotBlank()) { "A principal kind is not blank." }
        require(id.isNotBlank()) { "A principal id is not blank." }
    }

    override fun toString(): String = "$kind:$id"

    companion object {
        /** The kind of a Minecraft player, whose id is the player's UUID. */
        const val MINECRAFT: String = "minecraft"

        /** The kind of a panel user, whose id is the Typewriter user id. */
        const val USER: String = "user"
    }
}

/** The one actor a protagonist is, across every engine and connection it has. */
@TypewriterType(id = PROTAGONIST_TYPE_ID)
data class Protagonist(
    val principal: PrincipalId,
) : Identity

/**
 * One engine of a Realm, named by one subject token that starts with its kind: `primary-<topology engine instance id>`,
 * `panel-<realm id>` for the Realm's panel engine, or `local-<realm id>` for the engine of a host running without
 * topology. It names the engine's event inbox, survives restarts and ends when the engine leaves the topology.
 */
@TypewriterType(id = ENGINE_ID_TYPE_ID)
@JvmInline
value class EngineId(
    val value: String,
) {
    init {
        require(value.isNotBlank()) { "An engine id is not blank." }
    }

    override fun toString(): String = value
}

/** One engine as an identity. */
@TypewriterType(id = ENGINE_TYPE_ID)
data class Engine(
    val id: EngineId,
) : Identity

/**
 * One connection of a protagonist, chosen by its engine kind: the player UUID for Minecraft, which survives server
 * moves, or a per tab id for the panel, which survives reloads.
 */
@TypewriterType(id = SESSION_ID_TYPE_ID)
@JvmInline
value class SessionId(
    val value: String,
) {
    init {
        require(value.isNotBlank()) { "A session id is not blank." }
    }

    override fun toString(): String = value
}

/** One connection of a protagonist as an identity. A protagonist is online while it has at least one. */
@TypewriterType(id = SESSION_TYPE_ID)
data class Session(
    val protagonist: Protagonist,
    val id: SessionId,
) : Identity

const val IDENTITY_TYPE_ID = "99b0ffad447d402f92548db846b1d189"
const val PRINCIPAL_ID_TYPE_ID = "60a703e94ff44e5caf8fadef597476a1"
const val PROTAGONIST_TYPE_ID = "81f43d035dbf4f93b6f01d2e7148b692"
const val ENGINE_ID_TYPE_ID = "1964edcd729c4036a064eb4c6694b16e"
const val ENGINE_TYPE_ID = "179cbcba5fa841c4b5e87930c86da314"
const val SESSION_ID_TYPE_ID = "2e7e1e1e39a5446da1b54971bd5c8d12"
const val SESSION_TYPE_ID = "201965904cb9466a86f62273c1113abe"
