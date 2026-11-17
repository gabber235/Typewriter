package com.typewritermc.playtest

/** One attempt this session submitted to the pool, unique within the session; the wire carries its [value]. */
@JvmInline
internal value class SubmissionId(
    val value: Long,
) {
    override fun toString() = value.toString()
}
