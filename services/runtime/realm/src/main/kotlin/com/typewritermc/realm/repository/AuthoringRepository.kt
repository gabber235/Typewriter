package com.typewritermc.realm.repository

import com.typewritermc.authoring.AuthoringRecord
import com.typewritermc.authoring.CommitResult
import com.typewritermc.authoring.PreparedEdit
import com.typewritermc.authoring.RelationProjectionDelta
import com.typewritermc.authoring.ResourceDefinitionId
import com.typewritermc.realm.authoring.AuthoringSeed
import com.typewritermc.types.ResourceId

/** Accepts edits when their original expected facts still hold. */
interface AuthoringRepository {
    suspend fun commit(edit: PreparedEdit): CommitResult
}

data class AuthoringMutationPlan(
    val resources: Map<ResourceId, AuthoringRecord>,
    val removedResources: Set<ResourceId>,
    val relations: RelationProjectionDelta,
    val definitions: Map<ResourceId, ResourceDefinitionId> = emptyMap(),
)

internal interface AuthoringStorage {
    fun readCoherent(): AuthoringSeed

    fun persistAtomic(plan: AuthoringMutationPlan)
}
