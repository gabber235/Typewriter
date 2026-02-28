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
        require(patch.id.matches(Regex("^[a-zA-Z0-9_-]+$"))) {
            "Invalid patch id format: ${patch.id}"
        }
        logger.info { "Applying patch: ${patch.id}" }

        try {
            db.query(patch.content)
            db.queryBind($$"CREATE _patch SET id = $id", mapOf("id" to patch.id))
            logger.info { "Patch ${patch.id} applied successfully" }
        } catch (e: Exception) {
            logger.error(e) { "Failed to apply patch ${patch.id}" }
            throw PatchFailedException(patch.id, e)
        }
    }

    private fun getAppliedPatchIds(): Set<String> {
        return try {
            val result = db.query("SELECT id FROM _patch")
                .take(0)
            require(result.isArray) { "Expected array result from query, got: ${result.javaClass.name}" }
            result.array.mapNotNull { it.thing.id.string }.toSet()
        } catch (e: Exception) {
            logger.debug { "Could not query _patch table (may not exist yet): ${e.message}" }
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
            ?.use { it.bufferedReader().readText() }
    }
}

data class Patch(
    val id: String,
    val content: String
)

class PatchFailedException(patchId: String, cause: Exception) :
    RuntimeException("Failed to apply patch: $patchId", cause)
