package com.typewritermc.realm.edit

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

    override fun persistAtomic(plan: AuthoringMutationPlan) {
        check(!failBeforeWrite) { "write unavailable" }
        seed =
            AuthoringSeed(seed.resources + plan.resources - plan.removedResources)
        check(!failAfterWrite) { "commit result unavailable" }
    }
}
