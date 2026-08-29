package com.typewritermc.realm.repository.utils

import com.surrealdb.Transaction

internal fun Transaction.advanceCollaborationRevision(): Long =
    query("UPDATE ONLY collaboration_head:current SET revision += 1 RETURN VALUE revision;")
        .take(0)
        .getLong()
