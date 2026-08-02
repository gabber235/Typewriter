package com.typewritermc.realm.schema

import com.surrealdb.Surreal
import com.typewritermc.services.libs.telemetry.ErrorSlug
import com.typewritermc.services.libs.telemetry.MainSpanScope
import com.typewritermc.services.libs.telemetry.childSpanBlocking
import com.typewritermc.services.libs.telemetry.withErrorSlug

private val SCHEMA_MIGRATION_FAILURE = ErrorSlug.of("realm-schema-migration-failed")

internal class SchemaMigrator(
    private val db: Surreal,
    private val resources: MigrationResources = MigrationResources(),
) {

    context(_: MainSpanScope)
    fun migrate() = childSpanBlocking("realm.schema.migrate") {
        withErrorSlug(SCHEMA_MIGRATION_FAILURE) {
            applySchema(resources.loadMigrationSchema(), "migration.surql")
            PatchRunner(db).run(resources.loadPatches())
            resources.loadRealmSchema().forEach { resource ->
                applySchema(resource.script, resource.path)
            }
        }
    }

    context(_: MainSpanScope)
    private fun applySchema(schema: String, schemaName: String) =
        childSpanBlocking("realm.schema.apply") { child ->
            child.annotate { attribute("schema.name", schemaName) }
            db.execute(schema)
        }
}
