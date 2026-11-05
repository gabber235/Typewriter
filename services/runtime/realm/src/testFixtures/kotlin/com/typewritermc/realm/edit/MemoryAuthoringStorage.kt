package com.typewritermc.realm.edit

import com.typewritermc.authoring.SubmissionKey
import com.typewritermc.realm.authoring.AuthoringSeed

/**
 * Saved authoring kept in memory for tests that need no database. The failure switches stand in for a storage that
 * cannot read, fails before writing, or loses the commit result after writing.
 */
internal class MemoryAuthoringStorage(
    var seed: AuthoringSeed = AuthoringSeed(emptyMap()),
) : AuthoringStorage {
    var failBeforeWrite = false
    var failAfterWrite = false
    var failReads = false

    override fun readCoherent(): AuthoringSeed {
        check(!failReads) { "read unavailable" }
        return seed
    }

    /** Committed submissions, kept across fixture restarts as the Surreal table keeps them. */
    private val submissions = mutableMapOf<SubmissionKey, String>()

    override fun submittedRequest(submission: SubmissionKey): String? = submissions[submission]

    override fun persistAtomic(
        plan: AuthoringMutationPlan,
        submission: SubmissionKey,
        request: String,
    ) {
        check(!failBeforeWrite) { "write unavailable" }
        seed = AuthoringSeed(seed.resources + plan.resources - plan.removedResources)
        submissions[submission] = request
        check(!failAfterWrite) { "commit result unavailable" }
    }
}
