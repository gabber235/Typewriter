package com.typewritermc.authoring

/**
 * Names one save attempt of a prepared edit. A client mints a new key per attempt and keeps it when it resends the
 * same edit, so the Realm applies a resent attempt at most once. The wire carries it as the commit request's
 * `submission` string; the commit route turns that string into a key.
 */
@JvmInline
value class SubmissionKey(
    val value: String,
) {
    init {
        require(value.length in 1..MAX_LENGTH) { "A commit needs a submission key of 1 to $MAX_LENGTH characters." }
    }

    override fun toString(): String = value

    private companion object {
        const val MAX_LENGTH = 128
    }
}
