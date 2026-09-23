package com.typewritermc.realm.repository.utils

import com.typewritermc.types.ResourceId

/** Maps the opaque authored identity onto the single canonical resource table. */
internal fun ResourceId.unifiedSurrealId(): com.surrealdb.RecordId = com.surrealdb.RecordId("resource", value)

/** Recovers only the opaque authored identity. Database table identity never crosses this boundary. */
internal fun com.surrealdb.RecordId.toUnifiedResourceId(): ResourceId {
    require(table == "resource" && id.isString) { "Unified resource ids must use string resource keys." }
    return ResourceId(id.string)
}
