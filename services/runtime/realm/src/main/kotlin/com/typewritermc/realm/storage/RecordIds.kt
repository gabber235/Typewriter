package com.typewritermc.realm.storage

import com.surrealdb.RecordId
import com.typewritermc.types.requireValid
import skirout.editor.v1.type_catalog.ResourceId

/** Maps the opaque authored identity onto the single canonical resource table. */
internal fun ResourceId.surrealRecordId(): RecordId = RecordId("resource", value)

/** Recovers only the opaque authored identity. Database table identity never crosses this boundary. */
internal fun RecordId.toResourceId(): ResourceId {
    require(table == "resource" && id.isString) { "Resource record ids must use string keys in the resource table." }
    return ResourceId(value = id.string).requireValid()
}
