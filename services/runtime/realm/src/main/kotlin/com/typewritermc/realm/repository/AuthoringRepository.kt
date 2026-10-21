package com.typewritermc.realm.repository

import com.typewritermc.authoring.CommitResult
import com.typewritermc.authoring.PreparedEdit
import com.typewritermc.authoring.RelationProjectionDelta
import com.typewritermc.realm.authoring.AuthoringSeed
import com.typewritermc.types.ResourceId
import skirout.editor.v1.type_catalog.AuthoringRecord

/** Accepts edits when their original expected facts still hold. */
interface AuthoringRepository {
    suspend fun commit(edit: PreparedEdit): CommitResult
}

data class AuthoringMutationPlan(
    val resources: Map<ResourceId, AuthoringRecord>,
    val removedResources: Set<ResourceId>,
    val relations: RelationProjectionDelta,
)

internal interface AuthoringStorage {
    fun readCoherent(): AuthoringSeed

    fun persistAtomic(plan: AuthoringMutationPlan)
}
