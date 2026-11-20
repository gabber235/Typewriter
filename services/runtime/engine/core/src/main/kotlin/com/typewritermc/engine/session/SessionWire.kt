package com.typewritermc.engine.session

import com.typewritermc.identity.EngineId
import com.typewritermc.identity.PrincipalId
import com.typewritermc.identity.Protagonist
import com.typewritermc.identity.SessionId
import com.typewritermc.services.libs.communicator.kv.KeyValueBucket
import com.typewritermc.services.libs.communicator.kv.KeyValueRead
import okio.ByteString.Companion.toByteString
import java.time.Instant
import skirout.service.v1.session.EngineId as WireEngineId
import skirout.service.v1.session.PrincipalId as WirePrincipalId
import skirout.service.v1.session.Protagonist as WireProtagonist
import skirout.service.v1.session.SessionEntry as WireSessionEntry

/** One session's entry in the Realm's sessions bucket: who it belongs to, which engine holds it, and since when. */
data class SessionEntry(
    val protagonist: Protagonist,
    val holder: EngineId,
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

internal fun SessionEntry.encode(): ByteArray =
    WireSessionEntry.serializer
        .toBytes(
            WireSessionEntry(
                protagonist =
                    WireProtagonist(
                        principal = WirePrincipalId(kind = protagonist.principal.kind, id = protagonist.principal.id),
                    ),
                holder = WireEngineId(value = holder.value),
                since = since,
            ),
        ).toByteArray()

internal fun decodeSessionEntry(bytes: ByteArray): SessionEntry {
    val wire = WireSessionEntry.serializer.fromBytes(bytes.toByteString())
    return SessionEntry(
        protagonist = Protagonist(PrincipalId(wire.protagonist.principal.kind, wire.protagonist.principal.id)),
        holder = EngineId(wire.holder.value),
        since = wire.since,
    )
}

/** The live entry of [protagonist]'s session [id] in this sessions bucket, or null when there is none or it cannot be read. */
suspend fun KeyValueBucket.readSessionEntry(
    protagonist: Protagonist,
    id: SessionId,
): SessionEntry? =
    when (val read = get(sessionKey(protagonist, id))) {
        is KeyValueRead.Found -> decodeSessionEntry(read.entry.value)
        else -> null
    }
