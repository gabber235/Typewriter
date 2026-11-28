package com.typewritermc.engine.session.testing

import com.typewritermc.loader.api.work.WorkSubject
import com.typewritermc.loader.api.work.WorkSubjects
import com.typewritermc.services.libs.communicator.kv.KeyValueBucket
import com.typewritermc.services.libs.communicator.kv.KeyValueBucketDeclaration
import com.typewritermc.services.libs.communicator.kv.KeyValueBuckets
import com.typewritermc.services.libs.communicator.kv.KeyValueOpen
import kotlinx.coroutines.currentCoroutineContext
import kotlin.time.Duration

/** One write to a bucket: which [key] and the work subjects of the coroutine that wrote it, null for none. */
data class SubjectWrite(
    val key: String,
    val subjects: Set<WorkSubject>?,
)

/** [buckets] whose buckets note each write with the work subjects of the coroutine that makes it. */
class SubjectRecordingBuckets(
    private val buckets: KeyValueBuckets,
) : KeyValueBuckets {
    private val recorded = mutableListOf<SubjectWrite>()

    /** Every create and update so far, in order. */
    val writes: List<SubjectWrite> get() = synchronized(recorded) { recorded.toList() }

    override suspend fun open(name: String): KeyValueOpen = buckets.open(name).recording()

    override suspend fun ensure(bucket: KeyValueBucketDeclaration): KeyValueOpen = buckets.ensure(bucket).recording()

    private fun KeyValueOpen.recording(): KeyValueOpen = if (this is KeyValueOpen.Opened) KeyValueOpen.Opened(Recording(bucket)) else this

    private suspend fun record(key: String) {
        val subjects = currentCoroutineContext()[WorkSubjects]?.subjects
        synchronized(recorded) { recorded += SubjectWrite(key, subjects) }
    }

    private inner class Recording(
        private val bucket: KeyValueBucket,
    ) : KeyValueBucket by bucket {
        override suspend fun create(
            key: String,
            value: ByteArray,
            ttl: Duration,
        ) = bucket.create(key, value, ttl).also { record(key) }

        override suspend fun update(
            key: String,
            value: ByteArray,
            ttl: Duration,
            revision: Long,
        ) = bucket.update(key, value, ttl, revision).also { record(key) }
    }
}
