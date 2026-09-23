package com.typewritermc.realm.compiler

import com.typewritermc.engine.CompilationContext
import com.typewritermc.engine.CompileDiagnostic
import com.typewritermc.engine.CompileDiagnosticSeverity
import com.typewritermc.engine.CompiledEdge
import com.typewritermc.engine.CompiledEdgeOrigin
import com.typewritermc.engine.CompiledPageShard
import com.typewritermc.engine.CompiledResource
import com.typewritermc.engine.CompiledResourceKey
import com.typewritermc.engine.ContentDigest
import com.typewritermc.engine.PageCompileResult
import com.typewritermc.realm.repository.AuthoringWorkingGraph
import com.typewritermc.realm.repository.ResourceRelationOrigin
import com.typewritermc.realm.repository.StoredResourceRelation
import com.typewritermc.realm.repository.StoredTypedResource
import com.typewritermc.types.DataMapEntry
import com.typewritermc.types.DataValue
import com.typewritermc.types.RelationId
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeId
import com.typewritermc.authoring.GRAPH_PLACEMENT_TYPE_ID
import java.security.MessageDigest
import java.util.Base64

/** Compiles one bounded Page graph without a second Page content model. */
internal class PageCompiler(
    private val ownershipRelations: Set<RelationId>,
    private val formatRevision: Int = CURRENT_COMPILER_FORMAT,
) {
    fun compile(
        root: ResourceId,
        graph: AuthoringWorkingGraph,
        catalogRevision: String,
    ): PageCompileResult {
        val resources = graph.resources.values.sortedBy { it.id.value }
        val edges = graph.relations.values.sortedWith(compareBy({ it.source.value }, { it.target.value }, { it.id }))
        val fingerprint = digest(buildString {
            append("format:").append(formatRevision)
            append("|catalog:").append(catalogRevision)
            append("|root:").append(root.value)
            resources.forEach { resource ->
                append("|resource:").append(resource.id.value)
                append(':').append(resource.definition.value)
                append(':').append(resource.root)
                append(':').append(resource.valueWithSlots.executionCanonical())
            }
            edges.forEach { edge -> append("|edge:").append(edge.canonical()) }
        })
        val diagnostics = edges.mapNotNull { edge ->
            val origin = edge.origin as? ResourceRelationOrigin.Declared ?: return@mapNotNull null
            if (origin.relationId !in ownershipRelations || edge.source !in graph.resources || edge.target in graph.resources) {
                return@mapNotNull null
            }
            CompileDiagnostic(
                code = "missing-owned-resource",
                message = "Owned resource ${edge.target.value} is missing from the Page graph.",
                severity = CompileDiagnosticSeverity.ERROR,
                source = edge.source,
                target = edge.target,
            )
        }
        if (diagnostics.isNotEmpty()) return PageCompileResult.Blocked(fingerprint, diagnostics)
        val compiledResources = resources.map(StoredTypedResource::compile)
        val compiledEdges = edges.map(StoredResourceRelation::compile)
        val semantic = digest("root:${root.value}|input:${fingerprint.value}")
        return PageCompileResult.Success(
            CompiledPageShard(
                formatRevision = formatRevision,
                digest = semantic,
                inputFingerprint = fingerprint,
                root = CompiledResourceKey(root, CompilationContext.Root),
                resources = compiledResources,
                edges = compiledEdges,
            ),
        )
    }
}

private fun StoredTypedResource.compile(): CompiledResource =
    CompiledResource(
        key = CompiledResourceKey(id, CompilationContext.Root),
        definition = definition,
        rootType = root,
        valueWithSlots = valueWithSlots,
    )

private fun StoredResourceRelation.compile(): CompiledEdge =
    CompiledEdge(
        source = CompiledResourceKey(source, CompilationContext.Root),
        target = CompiledResourceKey(target, CompilationContext.Root),
        origin = when (val value = origin) {
            is ResourceRelationOrigin.Declared -> CompiledEdgeOrigin.Declared(
                relation = value.relationId,
                sourceIndex = value.sourceIndex,
                targetIndex = value.targetIndex,
            )
            is ResourceRelationOrigin.Reference -> CompiledEdgeOrigin.Reference(
                slot = value.slot,
                path = value.sourcePath,
                expectedType = value.expectedTarget,
            )
        },
    )

private fun StoredResourceRelation.canonical(): String = buildString {
    append(source.value).append(':').append(target.value)
    when (val value = origin) {
        is ResourceRelationOrigin.Declared -> {
            append(":declared:").append(value.relationId.value)
            append(':').append(value.sourceIndex).append(':').append(value.targetIndex)
        }
        is ResourceRelationOrigin.Reference -> {
            append(":reference:").append(value.slot.value)
            append(':').append(value.sourcePath)
            append(':').append(value.expectedTarget)
        }
    }
}

private fun DataValue.executionCanonical(): String =
    when (this) {
        is DataValue.Polymorphic -> {
            val id = concreteType.id as? TypeId.Declared
            if (id?.id?.toString() == GRAPH_PLACEMENT_TYPE_ID) "graph"
            else "p:$concreteType:${value.executionCanonical()}"
        }
        is DataValue.Record -> fields.entries.sortedBy { it.key }.joinToString(prefix = "o:{", postfix = "}") {
            "${it.key.length}:${it.key}=${it.value.executionCanonical()}"
        }
        is DataValue.ListValue -> values.joinToString(prefix = "l:[", postfix = "]") { it.executionCanonical() }
        else -> canonical()
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

        is DataValue.Reference -> {
            "x:${id.value}"
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

const val CURRENT_COMPILER_FORMAT = 2
