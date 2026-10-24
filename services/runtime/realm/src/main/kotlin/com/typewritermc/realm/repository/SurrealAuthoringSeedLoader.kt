package com.typewritermc.realm.repository

import com.surrealdb.Surreal
import com.typewritermc.authoring.AuthoringRecord
import com.typewritermc.realm.authoring.AuthoringSeed
import com.typewritermc.realm.authoring.authoredDatabaseValues
import com.typewritermc.realm.repository.utils.inTransaction
import com.typewritermc.realm.repository.utils.toResourceId
import com.typewritermc.types.ResourceId

/** Loads a coherent authored graph without operation history or revision counters. */
internal class SurrealAuthoringSeedLoader(
    private val database: Surreal,
) {
    fun load(): AuthoringSeed =
        database.inTransaction { transaction ->
            val resources = linkedMapOf<ResourceId, AuthoringRecord>()
            transaction.query("SELECT id, content FROM resource ORDER BY id;").take(0).getArray().forEach { rowValue ->
                val row = rowValue.getObject()
                val id = row.get("id").getRecordId().toResourceId()
                resources[id] = authoredDatabaseValues.decode(AuthoringRecord.serializer(), row.get("content"))
            }
            AuthoringSeed(resources)
        }
}
