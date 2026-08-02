package com.typewritermc.realm.schema

import com.surrealdb.Surreal
import com.typewritermc.services.libs.telemetry.ErrorSlug
import com.typewritermc.services.libs.telemetry.MainSpanScope
import com.typewritermc.services.libs.telemetry.childSpanBlocking
import com.typewritermc.services.libs.telemetry.withErrorSlug

private const val PATCH_TABLE = "_patch"
private val CHECKSUM_PATTERN = Regex("^[a-f0-9]{64}$")
private val PATCH_RUN_FAILURE = ErrorSlug.of("realm-patch-run-failed")

internal class PatchRunner(
    private val db: Surreal,
) {

    context(_: MainSpanScope)
    fun run(patches: List<DatabasePatch>) = childSpanBlocking("realm.patch.run") { child ->
        withErrorSlug(PATCH_RUN_FAILURE) {
            val appliedPatches = loadAppliedPatches()
            validateHistory(patches, appliedPatches)

            val pendingPatches = patches.filter { it.id !in appliedPatches }
            child.annotate {
                attribute("patch.total_count", patches.size.toLong())
                attribute("patch.pending_count", pendingPatches.size.toLong())
            }

            pendingPatches.forEach { patch -> applyPatch(patch) }
        }
    }

    private fun loadAppliedPatches(): Map<String, String> {
        val result = db.query("SELECT id, checksum FROM $PATCH_TABLE ORDER BY id").take(0)
        check(result.isArray) { "Expected patch history query to return an array" }

        val entries = result.array.map { value ->
            check(value.isObject) { "Expected every patch history entry to be an object" }
            val row = value.getObject()
            val id = row.get("id")
            check(id.isRecordId) { "Expected patch history id to be a record id" }
            val storedChecksum = row.get("checksum")
            check(storedChecksum.isString) { "Expected patch checksum to be a string" }
            val patchId = id.recordId.id
            check(patchId.isString) { "Expected patch history id to use a string key" }
            patchId.string to storedChecksum.string
        }

        check(entries.map { it.first }.distinct().size == entries.size) {
            "Patch history contains duplicate ids"
        }
        return entries.toMap()
    }

    private fun validateHistory(
        patches: List<DatabasePatch>,
        appliedPatches: Map<String, String>,
    ) {
        val patchesById = patches.associateBy(DatabasePatch::id)
        val unknownIds = appliedPatches.keys.minus(patchesById.keys)
        check(unknownIds.isEmpty()) {
            "Patch history contains patches missing from the catalog: ${unknownIds.sorted().joinToString()}"
        }

        appliedPatches.forEach { (id, storedChecksum) ->
            check(CHECKSUM_PATTERN.matches(storedChecksum)) {
                "Patch history contains an invalid checksum for $id"
            }
            val expectedChecksum = patchesById.getValue(id).checksum
            check(storedChecksum == expectedChecksum) {
                "Applied patch was modified: $id"
            }
        }
    }

    context(_: MainSpanScope)
    private fun applyPatch(patch: DatabasePatch) = childSpanBlocking("realm.patch.apply") { child ->
        child.annotate { attribute("patch.id", patch.id) }
        val transaction = buildString {
            appendLine("BEGIN TRANSACTION;")
            appendLine(patch.script.trim())
            appendLine(
                "CREATE ONLY type::record(\"$PATCH_TABLE\", \"${patch.id}\") " +
                    "SET checksum = \"${patch.checksum}\", applied_at = time::now();",
            )
            append("COMMIT TRANSACTION;")
        }

        try {
            db.execute(transaction)
        } catch (cause: Exception) {
            throw PatchFailedException(patch.id, cause)
        }
    }
}

internal class PatchFailedException(patchId: String, cause: Exception) :
    RuntimeException("Failed to apply patch: $patchId", cause)
