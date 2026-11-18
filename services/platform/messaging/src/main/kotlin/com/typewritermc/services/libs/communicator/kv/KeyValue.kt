package com.typewritermc.services.libs.communicator.kv

import kotlin.time.Duration

/**
 * Opens and creates the key value buckets of one connection. Every bucket access goes through here, so the place a
 * bucket lives (its JetStream domain on a leaf node) is decided once.
 */
interface KeyValueBuckets {
    /** The bucket named [name], or [KeyValueOpen.Missing] until its owner created it. */
    suspend fun open(name: String): KeyValueOpen

    /** Creates [bucket], or opens it unchanged when it exists. Only a bucket's owner may call this. */
    suspend fun ensure(bucket: KeyValueBucketDeclaration): KeyValueOpen
}

/**
 * The shape a bucket is created with. Every key carries its own time to live, and an expired key leaves a marker for
 * [markerTtl], so a watcher sees the expiry.
 */
data class KeyValueBucketDeclaration(
    val name: String,
    val markerTtl: Duration,
)

/** The outcome of opening a bucket. */
sealed interface KeyValueOpen {
    data class Opened(
        val bucket: KeyValueBucket,
    ) : KeyValueOpen

    /** The bucket does not exist yet. */
    data object Missing : KeyValueOpen

    data class Failed(
        val cause: Throwable,
    ) : KeyValueOpen
}

/**
 * One bucket. Writes check the key's revision, so two writers never overwrite each other unnoticed, and each write
 * sets the key's time to live: a key nobody rewrites in time expires.
 */
interface KeyValueBucket {
    /** The current entry of [key], or [KeyValueRead.Absent] when it never existed or expired. */
    suspend fun get(key: String): KeyValueRead

    /** Writes [key] only when it holds no live entry. */
    suspend fun create(
        key: String,
        value: ByteArray,
        ttl: Duration,
    ): KeyValueWrite

    /** Writes [key] only when its live entry is still at [revision]. */
    suspend fun update(
        key: String,
        value: ByteArray,
        ttl: Duration,
        revision: Long,
    ): KeyValueWrite

    /** The keys with a live entry matching [filter], a subject pattern such as `minecraft.<uuid>.*`. */
    suspend fun keys(filter: String): KeyValueKeys
}

/** One live entry of a bucket. */
class KeyValueEntry(
    val key: String,
    val value: ByteArray,
    val revision: Long,
)

/** The outcome of reading one key. */
sealed interface KeyValueRead {
    data class Found(
        val entry: KeyValueEntry,
    ) : KeyValueRead

    data object Absent : KeyValueRead

    data class Failed(
        val cause: Throwable,
    ) : KeyValueRead
}

/** The outcome of a checked write. */
sealed interface KeyValueWrite {
    data class Written(
        val revision: Long,
    ) : KeyValueWrite

    /** Another writer changed the key first: it exists for a create, or moved past the revision for an update. */
    data object Conflict : KeyValueWrite

    data class Failed(
        val cause: Throwable,
    ) : KeyValueWrite
}

/** The outcome of listing keys. */
sealed interface KeyValueKeys {
    data class Listed(
        val keys: List<String>,
    ) : KeyValueKeys

    data class Failed(
        val cause: Throwable,
    ) : KeyValueKeys
}
