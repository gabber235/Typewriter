package com.typewritermc.realm.repository

import com.typewritermc.authoring.AuthoringRecord
import com.typewritermc.authoring.BatchId
import com.typewritermc.authoring.CommitResult
import com.typewritermc.authoring.PreparedEdit
import com.typewritermc.authoring.RelationProjectionDelta
import com.typewritermc.authoring.ResourceDefinitionId
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.checking.InputIdentity
import com.typewritermc.checking.InputToken
import com.typewritermc.checking.SnapshotId
import com.typewritermc.types.ResourceId

/** Owns acceptance of prepared authoring intent and its durable receipt. */
interface AuthoringRepository {
    suspend fun replay(edit: PreparedEdit): CommitResult? = null

    suspend fun commit(edit: PreparedEdit): CommitResult
}

data class AuthoringMutationPlan(
    val resources: Map<ResourceId, AuthoringRecord>,
    val removedResources: Set<ResourceId>,
    val relations: RelationProjectionDelta,
    val changedInputs: Set<InputIdentity>,
)

data class CommitDelta(
    val previousSnapshot: SnapshotId,
    val snapshot: SnapshotId,
    val catalog: CatalogGeneration,
    val resources: Map<ResourceId, AuthoringRecord>,
    val resourceDefinitions: Map<ResourceId, ResourceDefinitionId>,
    val removedResources: Set<ResourceId>,
    val relations: RelationProjectionDelta,
    val inputTokens: Map<InputIdentity, InputToken>,
)

data class AuthoringReceipt(
    val batch: BatchId,
    val digest: String,
    val result: CommitResult.Committed,
)

data class AuthoringCommittedEvent(
    val batch: BatchId,
    val delta: CommitDelta,
)

interface AuthoringEventOutbox {
    suspend fun pending(): List<AuthoringCommittedEvent>

    suspend fun acknowledge(batch: BatchId)
}
