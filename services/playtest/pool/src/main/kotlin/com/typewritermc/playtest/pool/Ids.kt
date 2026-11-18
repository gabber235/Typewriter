package com.typewritermc.playtest.pool

/** A session's submission, unique within that session; the wire carries its [value]. */
@JvmInline
internal value class SubmissionId(
    val value: Long,
) {
    override fun toString() = value.toString()
}

/** One attempt the pool started, unique within the pool; Paper and the wire know it by its [value]. */
@JvmInline
internal value class AttemptId(
    val value: Long,
) {
    override fun toString() = value.toString()
}
