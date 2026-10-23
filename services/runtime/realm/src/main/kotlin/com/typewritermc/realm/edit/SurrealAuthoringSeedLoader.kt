package com.typewritermc.realm.edit

import com.surrealdb.Surreal
import com.typewritermc.realm.authoring.AuthoringSeed
import com.typewritermc.realm.storage.decodeSkir
import com.typewritermc.realm.storage.inTransaction
import com.typewritermc.realm.storage.toResourceId
import com.typewritermc.types.requireValid
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.ResourceId

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
                resources[id] = decodeSkir(AuthoringRecord.serializer, row.get("content")).requireValid()
            }
            AuthoringSeed(resources)
        }
}
