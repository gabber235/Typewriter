package com.typewritermc.realm.compiler

import com.typewritermc.elements.ElementPlacement
import com.typewritermc.elements.ref
import com.typewritermc.engine.CompilationContext
import com.typewritermc.engine.CompileDiagnostic
import com.typewritermc.engine.CompileDiagnosticSeverity
import com.typewritermc.engine.CompiledElement
import com.typewritermc.engine.CompiledElementKey
import com.typewritermc.engine.CompiledPageShard
import com.typewritermc.engine.CompiledPlacement
import com.typewritermc.engine.ContentDigest
import com.typewritermc.engine.PageCompileResult
import com.typewritermc.engine.SourceElementKey
import com.typewritermc.library.PageDocument
import com.typewritermc.library.PageDocumentElement
import com.typewritermc.library.PageReference
import com.typewritermc.library.ResourceSummary
import com.typewritermc.library.ref
import com.typewritermc.types.DataMapEntry
import com.typewritermc.types.DataValue
import java.security.MessageDigest
import java.util.Base64

class PageCompiler(
    private val formatRevision: Int = CURRENT_COMPILER_FORMAT,
) {
    fun compile(
        document: PageDocument,
        catalogRevision: String,
    ): PageCompileResult {
        val fingerprint = inputFingerprint(document, catalogRevision)
        val diagnostics =
            document.diagnostics.map { diagnostic ->
                CompileDiagnostic(
                    code = diagnostic.code,
                    message = diagnostic.message,
                    severity = CompileDiagnosticSeverity.ERROR,
                    source = diagnostic.element,
                    target = diagnostic.target,
                )
            }
        if (diagnostics.any { it.severity == CompileDiagnosticSeverity.ERROR }) {
            return PageCompileResult.Blocked(fingerprint, diagnostics)
        }
        val elements =
            document.elements.sortedBy { it.id.value.toHexString() }.map { element ->
                CompiledElement(
                    key = CompiledElementKey(SourceElementKey(element.id.ref()), CompilationContext.Root),
                    sourceId = element.id,
                    elementType = element.elementType,
                    schemaRevision = element.schemaRevision,
                    name = element.name,
                    value = element.value,
                    placement = element.placement.compiled(),
                )
            }
        val page = document.page.id.ref()
        val digest = digest(shardFacts(page.id.referenceString(), fingerprint, elements))
        return PageCompileResult.Success(
            CompiledPageShard(formatRevision, digest, fingerprint, page, elements),
        )
    }

    private fun inputFingerprint(
        document: PageDocument,
        catalogRevision: String,
    ): ContentDigest =
        digest(
            buildString {
                append("format:").append(formatRevision)
                append("|catalog:").append(catalogRevision)
                append("|page:").append(
                    document.page.id
                        .ref()
                        .id
                        .referenceString(),
                )
                append("|book:").append(
                    document.page.book.id
                        .referenceString(),
                )
                append("|kind:").append(document.page.kind.id).append(':').append(document.page.kind.revision)
                append("|chapter:").append(document.page.chapter)
                append("|priority:").append(document.page.priority)
                document.elements.sortedBy { it.id.value.toHexString() }.forEach { appendElement(it) }
                document.references.sortedBy(PageReference::stableKey).forEach { appendReference(it) }
                document.crossPageTargets.sortedBy { it.id.referenceString() }.forEach { appendSummary(it) }
            },
        )
}

private fun StringBuilder.appendElement(element: PageDocumentElement) {
    append("|element:").append(element.id.value.toHexString())
    append(':').append(element.revision.value)
    append(':').append(element.elementType.value)
    append(':').append(element.schemaRevision)
    append(':').append(element.name.length).append(':').append(element.name)
    append(':').append(element.value.canonical())
    append(':').append(element.placement.executionFacts())
}

private fun StringBuilder.appendReference(reference: PageReference) {
    append("|reference:").append(reference.stableKey())
    append(':').append(reference.target.referenceString())
    append(':').append(reference.expectedType)
}

private fun StringBuilder.appendSummary(summary: ResourceSummary) {
    append("|target:").append(summary.id.referenceString())
    append(':').append(summary.exists)
    append(':').append(summary.elementType?.value)
}

private fun shardFacts(
    page: String,
    fingerprint: ContentDigest,
    elements: List<CompiledElement>,
): String =
    buildString {
        append("page:").append(page).append("|input:").append(fingerprint.value)
        elements.forEach { element ->
            append("|compiled:").append(element.sourceId.value.toHexString())
            append(':').append(element.elementType.value)
            append(':').append(element.schemaRevision)
            append(':').append(element.name)
            append(':').append(element.value.canonical())
            append(':').append(element.placement)
        }
    }

private fun PageReference.stableKey(): String = "${source.value.toHexString()}:${slot.value}"

private fun ElementPlacement.executionFacts(): String =
    when (this) {
        is ElementPlacement.Graph -> "graph_v1"
        is ElementPlacement.TimelineEntry -> "timeline_entry_v1:$trackIndex"
        is ElementPlacement.TimelineSegment -> "timeline_segment_v1:$startFrame:$endFrame"
        is ElementPlacement.TimelineKeyframe -> "timeline_keyframe_v1:$frame"
    }

private fun ElementPlacement.compiled(): CompiledPlacement =
    when (this) {
        is ElementPlacement.Graph -> CompiledPlacement.Graph
        is ElementPlacement.TimelineEntry -> CompiledPlacement.TimelineEntry(trackIndex)
        is ElementPlacement.TimelineSegment -> CompiledPlacement.TimelineSegment(startFrame, endFrame)
        is ElementPlacement.TimelineKeyframe -> CompiledPlacement.TimelineKeyframe(frame)
    }

private fun DataValue.canonical(): String =
    when (this) {
        DataValue.Unit -> {
            "u"
        }

        is DataValue.Boolean -> {
            "b:$value"
        }

        is DataValue.Integer -> {
            "i:$value"
        }

        is DataValue.Float -> {
            "f:${value.toBits()}"
        }

        is DataValue.Decimal -> {
            "d:$value"
        }

        is DataValue.StringValue -> {
            "s:${value.length}:$value"
        }

        is DataValue.Bytes -> {
            "y:${Base64.getEncoder().encodeToString(toByteArray())}"
        }

        is DataValue.Timestamp -> {
            "t:$value"
        }

        is DataValue.Duration -> {
            "r:$value"
        }

        is DataValue.ListValue -> {
            values.joinToString(prefix = "l:[", postfix = "]") { it.canonical() }
        }

        is DataValue.MapValue -> {
            entries.map(DataMapEntry::canonical).sorted().joinToString(prefix = "m:{", postfix = "}")
        }

        is DataValue.Record -> {
            fields.entries.sortedBy(Map.Entry<String, DataValue>::key).joinToString(prefix = "o:{", postfix = "}") {
                "${it.key.length}:${it.key}=${it.value.canonical()}"
            }
        }

        is DataValue.Polymorphic -> {
            "p:$concreteType:${value.canonical()}"
        }
    }

private fun DataMapEntry.canonical(): String = "${key.canonical()}=${value.canonical()}"

private fun digest(value: String): ContentDigest =
    ContentDigest(
        MessageDigest.getInstance("SHA-256").digest(value.toByteArray()).joinToString("") {
            "%02x".format(it.toInt() and 0xff)
        },
    )

const val CURRENT_COMPILER_FORMAT = 1
