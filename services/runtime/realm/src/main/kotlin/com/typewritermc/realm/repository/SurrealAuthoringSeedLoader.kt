package com.typewritermc.realm.repository

import com.surrealdb.Surreal
import com.surrealdb.Transaction
import com.typewritermc.authoring.AuthoringRecord
import com.typewritermc.authoring.ResourceDefinitionId
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.checking.InputIdentity
import com.typewritermc.checking.InputToken
import com.typewritermc.checking.SnapshotId
import com.typewritermc.realm.authoring.AuthoredSnapshotSeed
import com.typewritermc.realm.authoring.RESOURCE_SELECTION_INPUT
import com.typewritermc.realm.authoring.SnapshotCatalogLease
import com.typewritermc.realm.authoring.absentInputToken
import com.typewritermc.realm.authoring.authoringStorageJson
import com.typewritermc.realm.authoring.requiredAuthoringInputs
import com.typewritermc.realm.repository.utils.inTransaction
import com.typewritermc.realm.repository.utils.toUnifiedResourceId
import com.typewritermc.types.ResourceId
import kotlinx.serialization.decodeFromString
import kotlinx.serialization.encodeToString

/** Loads the exact durable authored state used to seed snapshot publication after a process restart. */
internal class SurrealAuthoringSeedLoader(
    private val database: Surreal,
) {
    fun loadFor(next: SnapshotCatalogLease): AuthoredSnapshotSeed {
        val loaded = loadState()
        val seed = loaded.seed ?: AuthoredSnapshotSeed(SnapshotId("realm:0"), emptyMap(), emptyMap())
        val retained = seed.inputTokens.filterKeys { it !is InputIdentity.Catalog }
        val catalogIdentity = InputIdentity.Catalog(next.generation)
        val catalogToken =
            if (loaded.catalogGeneration == null || loaded.catalogGeneration == next.generation) {
                catalogInputToken(next.generation)
            } else {
                absentInputToken()
            }
        return seed.copy(
            inputTokens =
                retained +
                    (RESOURCE_SELECTION_INPUT to (retained[RESOURCE_SELECTION_INPUT] ?: absentInputToken())) +
                    (catalogIdentity to catalogToken),
        )
    }

    fun load(): AuthoredSnapshotSeed? = loadState().seed

    private fun loadState(): LoadedAuthoringState = database.inTransaction { transaction -> transaction.loadState() }
}

private fun Transaction.loadState(): LoadedAuthoringState {
    val fence = query("SELECT revision, catalog_generation FROM ONLY authoring_acceptance_fence:current;").take(0)
    val catalogGeneration =
        if (fence.isNone || fence.isNull) {
            null
        } else {
            val value = fence.getObject().get("catalog_generation")
            if (value.isNone || value.isNull) null else value.getString().takeIf(String::isNotBlank)?.let(::CatalogGeneration)
        }
    val resourceRows = query("SELECT id, definition, content, snapshot FROM resource ORDER BY id;").take(0).getArray()
    val inputRows = query("SELECT id, identity, token FROM authoring_input ORDER BY id;").take(0).getArray()
    if (resourceRows.len() == 0 && inputRows.len() == 0) return LoadedAuthoringState(null, catalogGeneration)
    check(inputRows.len() > 0) { "Persistent authoring resources exist without input tokens." }
    check(!fence.isNone && !fence.isNull) { "Persistent authoring state exists without an acceptance fence." }
    val sequence = fence.getObject().get("revision").getLong()
    val resources = linkedMapOf<ResourceId, AuthoringRecord>()
    val definitions = linkedMapOf<ResourceId, ResourceDefinitionId>()
    val resourceRevisions = linkedMapOf<ResourceId, Long>()
    resourceRows.forEach { rowValue ->
        val row = rowValue.getObject()
        val resource = row.get("id").getRecordId().toUnifiedResourceId()
        resources[resource] = authoringStorageJson.decodeFromString(AuthoringRecord.serializer(), row.get("content").getString())
        definitions[resource] = ResourceDefinitionId(row.get("definition").getString())
        val snapshot = row.get("snapshot")
        resourceRevisions[resource] = if (snapshot.isNone || snapshot.isNull) sequence else snapshot.getLong()
    }
    val inputs =
        inputRows.associate { rowValue ->
            val row = rowValue.getObject()
            authoringStorageJson.decodeFromString(InputIdentity.serializer(), row.get("identity").getString()) to
                InputToken(row.get("token").getString())
        }
    val missing = requiredAuthoringInputs(resources) - inputs.keys
    val recovered =
        missing.associateWith { identity ->
            val revision = identity.authoredResource()?.let(resourceRevisions::get) ?: sequence
            authoredInputToken(revision, identity)
        }
    recovered.forEach { (identity, token) ->
        query(
            "CREATE ONLY \$input CONTENT { identity: \$identity, token: \$authored_token, snapshot: \$snapshot };",
            mapOf(
                "input" to identity.inputRecordId(),
                "identity" to authoringStorageJson.encodeToString(InputIdentity.serializer(), identity),
                "authored_token" to token.value,
                "snapshot" to sequence,
            ),
        ).take(0)
    }
    return LoadedAuthoringState(
        AuthoredSnapshotSeed(SnapshotId("realm:$sequence"), resources, inputs + recovered, definitions),
        catalogGeneration,
    )
}

private data class LoadedAuthoringState(
    val seed: AuthoredSnapshotSeed?,
    val catalogGeneration: CatalogGeneration?,
)

private fun InputIdentity.authoredResource(): ResourceId? =
    when (this) {
        is InputIdentity.Value -> at.resource
        is InputIdentity.Existence -> resource
        is InputIdentity.Form -> at.resource
        is InputIdentity.Membership -> at.resource
        is InputIdentity.Order -> at.resource
        is InputIdentity.Incoming -> resource
        is InputIdentity.Selection, is InputIdentity.Catalog -> null
    }
