package com.typewritermc.realm.schema

import com.surrealdb.Surreal
import com.typewritermc.services.libs.telemetry.withSpan
import io.opentelemetry.api.trace.Span
import io.opentelemetry.api.trace.StatusCode
import io.opentelemetry.api.trace.Tracer

class PatchRunner(
    private val db: Surreal,
    private val tracer: Tracer,
) {

    fun runPendingPatches(parentSpan: Span? = null) {
        val span = parentSpan ?: tracer.spanBuilder("realm.patch.apply").startSpan()
        span.makeCurrent().use { _ ->
            val allPatches = loadPatches(span)
            if (allPatches.isEmpty()) {
                span.addEvent("No patches found")
                span.end()
                return
            }

            val appliedIds = getAppliedPatchIds(span)
            val pending = allPatches.filter { it.id !in appliedIds }

            if (pending.isEmpty()) {
                span.addEvent("All patches already applied", io.opentelemetry.api.common.Attributes.builder()
                    .put("patch.count", allPatches.size.toLong())
                    .build())
                span.end()
                return
            }

            span.addEvent("Running pending patches", io.opentelemetry.api.common.Attributes.builder()
                .put("patch.pending_count", pending.size.toLong())
                .put("patch.total_count", allPatches.size.toLong())
                .build())
            pending.forEach { applyPatch(it, span) }
            span.addEvent("All patches applied successfully")
            span.end()
        }
    }

    private fun applyPatch(patch: Patch, parentSpan: Span) = tracer.withSpan("realm.patch.apply_single") { s ->
        s.setAttribute("patch.id", patch.id)

        // TODO: Add checksum validation for already-applied patches.
        // Store a SHA-256 hash of each patch file in the _patch table at apply time.
        // On startup, compare stored checksums against current file contents.
        // If a previously-applied patch was modified, fail with a clear error.
        // This prevents silent drift when patch files are edited after deployment.

        require(patch.id.matches(Regex("^[a-zA-Z0-9_-]+$"))) {
            "Invalid patch id format: ${patch.id}"
        }
        s.addEvent("Applying patch")

        try {
            db.query(patch.content)
            db.queryBind($$"CREATE _patch SET id = $id", mapOf("id" to patch.id))
            s.addEvent("Patch applied successfully")
        } catch (e: Exception) {
            s.setStatus(StatusCode.ERROR, "Failed to apply patch: ${patch.id}")
            throw PatchFailedException(patch.id, e)
        }
    }

    private fun getAppliedPatchIds(parentSpan: Span): Set<String> {
        return try {
            val result = db.query("SELECT id FROM _patch")
                .take(0)
            require(result.isArray) { "Expected array result from query, got: ${result.javaClass.name}" }
            result.array.mapNotNull { it.thing.id.string }.toSet()
        } catch (e: Exception) {
            parentSpan.addEvent("Could not query _patch table (may not exist yet)", io.opentelemetry.api.common.Attributes.builder()
                .put("error.message", e.message ?: "Unknown error")
                .build())
            emptySet()
        }
    }

    private fun loadPatches(parentSpan: Span): List<Patch> {
        val index = loadResourceOrNull("schema/patches/_index.txt")
            ?.lines()
            ?.filter { it.isNotBlank() }
            ?: return emptyList()

        return index.mapNotNull { filename ->
            val content = loadResourceOrNull("schema/patches/$filename")
            if (content == null) {
                parentSpan.addEvent("Patch file not found", io.opentelemetry.api.common.Attributes.builder()
                    .put("patch.filename", filename)
                    .build())
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
