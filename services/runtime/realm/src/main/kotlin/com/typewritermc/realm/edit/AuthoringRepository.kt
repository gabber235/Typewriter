package com.typewritermc.realm.edit

import com.typewritermc.realm.authoring.AuthoringSeed
import skirout.editor.v1.authoring.CommitPreparedEditResponse
import skirout.editor.v1.authoring.PreparedEdit
import skirout.editor.v1.authoring.RelationProjectionDelta
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.kernel.v1.resource_id.ResourceId

/** Accepts edits when their original expected facts still hold. */
interface AuthoringRepository {
    suspend fun commit(edit: PreparedEdit): CommitPreparedEditResponse
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
