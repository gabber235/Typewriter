package com.typewritermc.realm.repository.utils

import com.surrealdb.Transaction

/**
 * Advances editor collaboration sequence inside the caller transaction and returns the new value.
 *
 * Compiler source revision is separate and advances only when the batch affects compilation.
 */
internal fun Transaction.advanceCollaborationRevision(): Long =
    query("UPDATE ONLY collaboration_head:current SET revision += 1 RETURN VALUE revision;")
        .take(0)
        .getLong()
