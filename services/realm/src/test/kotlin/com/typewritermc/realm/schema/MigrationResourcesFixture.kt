package com.typewritermc.realm.schema

internal fun migrationResources(vararg entries: Pair<String, String>): MigrationResources {
    val content =
        mapOf(
            "schema/migration.surql" to "RETURN true;",
            "schema/realm/_index.txt" to "domain.surql",
            "schema/realm/domain.surql" to "RETURN true;",
            *entries,
        )
    return MigrationResources(content::get)
}
