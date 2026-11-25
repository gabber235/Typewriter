package com.typewritermc.engine.session

import com.typewritermc.identity.EngineId
import com.typewritermc.identity.PrincipalId
import com.typewritermc.identity.Protagonist
import com.typewritermc.identity.SessionId
import com.typewritermc.services.libs.communicator.kv.KeyValueBucket
import com.typewritermc.services.libs.communicator.kv.KeyValueRead
import com.typewritermc.services.libs.communicator.kv.LeaseCodec
import com.typewritermc.services.libs.communicator.kv.LeaseEntry
import okio.ByteString.Companion.toByteString
import java.io.IOException
import java.time.Instant
import java.util.logging.Logger
import skirout.service.v1.session.EngineId as WireEngineId
import skirout.service.v1.session.PrincipalId as WirePrincipalId
import skirout.service.v1.session.Protagonist as WireProtagonist
import skirout.service.v1.session.SessionEntry as WireSessionEntry

/**
 * One session's entry in the Realm's sessions bucket: who it belongs to, which engine holds it, since when the
 * session runs, and when the holder's connection began on the holder's clock.
 */
data class SessionEntry(
    val protagonist: Protagonist,
    val holder: EngineId,
    val since: Instant,
    val connected: Instant,
)

/** What a session's lease keeps besides its holder and claim: whose session it is and since when it runs. */
internal data class SessionValue(
    val protagonist: Protagonist,
    val since: Instant,
)

/**
 * The bucket key of a session, `<principal kind>.<principal id>.<session id>`, so every session of a protagonist
 * shares the prefix [protagonistKeys] matches.
 */
internal fun sessionKey(
    protagonist: Protagonist,
    id: SessionId,
): String = "${protagonist.principal.kind}.${protagonist.principal.id}.${id.value}"

/** The key filter matching every session of [protagonist]. */
internal fun protagonistKeys(protagonist: Protagonist): String = "${protagonist.principal.kind}.${protagonist.principal.id}.*"

/**
 * Session entries as the sessions bucket stores them. A value no engine can read, damaged or cut off, is logged and
 * read as no entry, so a join writes over it and a holder listing skips it.
 */
internal object SessionLeaseCodec : LeaseCodec<SessionValue> {
    private val log: Logger = Logger.getLogger(SessionLeaseCodec::class.java.name)

    override fun encode(entry: LeaseEntry<SessionValue>): ByteArray =
        WireSessionEntry.serializer
            .toBytes(
                WireSessionEntry(
                    protagonist =
                        WireProtagonist(
                            principal =
                                WirePrincipalId(
                                    kind = entry.value.protagonist.principal.kind,
                                    id = entry.value.protagonist.principal.id,
                                ),
                        ),
                    holder = WireEngineId(value = entry.holder),
                    since = entry.value.since,
                    connected = entry.claimed,
                ),
            ).toByteArray()

    override fun decode(bytes: ByteArray): LeaseEntry<SessionValue>? =
        try {
            val wire = WireSessionEntry.serializer.fromBytes(bytes.toByteString())
            LeaseEntry(
                holder = wire.holder.value,
                claimed = wire.connected,
                value = SessionValue(Protagonist(PrincipalId(wire.protagonist.principal.kind, wire.protagonist.principal.id)), wire.since),
            )
        } catch (failure: IllegalArgumentException) {
            unreadable(failure)
        } catch (failure: IOException) {
            // A cut off value ends the decoder's input early.
            unreadable(failure)
        }

    private fun unreadable(failure: Exception): Nothing? {
        log.warning("Skipped a session value no engine can read: $failure")
        return null
    }
}

internal fun LeaseEntry<SessionValue>.toSessionEntry(): SessionEntry =
    SessionEntry(value.protagonist, EngineId(holder), value.since, claimed)

/** The live entry of [protagonist]'s session [id] in this sessions bucket, or null when there is none or no engine can read it; a failed read throws its cause. */
suspend fun KeyValueBucket.readSessionEntry(
    protagonist: Protagonist,
    id: SessionId,
): SessionEntry? =
    when (val read = get(sessionKey(protagonist, id))) {
        is KeyValueRead.Found -> SessionLeaseCodec.decode(read.entry.value)?.toSessionEntry()
        KeyValueRead.Absent -> null
        is KeyValueRead.Failed -> throw read.cause
    }
