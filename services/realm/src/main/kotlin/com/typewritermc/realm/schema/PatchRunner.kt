package com.typewritermc.realm.schema

import com.surrealdb.Surreal
import io.github.oshai.kotlinlogging.KotlinLogging

private val logger = KotlinLogging.logger {}

class PatchRunner(private val db: Surreal) {

    fun runPendingPatches() {
        val allPatches = loadPatches()
        if (allPatches.isEmpty()) {
            logger.debug { "No patches found" }
            return
        }

        val appliedIds = getAppliedPatchIds()
        val pending = allPatches.filter { it.id !in appliedIds }

        if (pending.isEmpty()) {
            logger.debug { "All ${allPatches.size} patches already applied" }
            return
        }

        logger.info { "Running ${pending.size} pending patches..." }
        pending.forEach { applyPatch(it) }
        logger.info { "All patches applied successfully" }
    }

    private fun applyPatch(patch: Patch) {
        logger.info { "Applying patch: ${patch.id}" }

        try {
            db.query(patch.content)
            db.query("CREATE _patches SET id = '${patch.id}'")
            logger.info { "Patch ${patch.id} applied successfully" }
        } catch (e: Exception) {
            logger.error(e) { "Failed to apply patch ${patch.id}" }
            throw PatchFailedException(patch.id, e)
        }
    }

    private fun getAppliedPatchIds(): Set<String> {
        return try {
            val records = db.query("SELECT id FROM _patches")
                .take(0)
                .get(Array<PatchRecord>::class.java)
            records.mapNotNull { it.id }.toSet()
        } catch (e: Exception) {
            logger.debug { "Could not query _patches table (may not exist yet): ${e.message}" }
            emptySet()
        }
    }

    private fun loadPatches(): List<Patch> {
        val index = loadResourceOrNull("schema/patches/_index.txt")
            ?.lines()
            ?.filter { it.isNotBlank() }
            ?: return emptyList()

        return index.mapNotNull { filename ->
            val content = loadResourceOrNull("schema/patches/$filename")
            if (content == null) {
                logger.warn { "Patch file not found: $filename" }
                return@mapNotNull null
            }
            Patch(
                id = filename.removeSuffix(".surql"),
                content = content
            )
        }
    }

    private fun loadResourceOrNull(path: String): String? {
        return this::class.java.classLoader
            .getResourceAsStream(path)
            ?.bufferedReader()
            ?.readText()
    }
}

data class PatchRecord(
    val id: String? = null
)

data class Patch(
    val id: String,
    val content: String
)

class PatchFailedException(patchId: String, cause: Exception) :
    RuntimeException("Failed to apply patch: $patchId", cause)
