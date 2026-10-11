package com.typewritermc.realm.compiler

import com.typewritermc.authoring.TypeSelection
import com.typewritermc.authoring.descendants
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
import com.typewritermc.engine.RuntimeCompilationFacts
import com.typewritermc.engine.RuntimeRelationFact
import com.typewritermc.engine.canonicalized
import com.typewritermc.engine.semanticDigest
import com.typewritermc.realm.authoring.AuthoringView
import com.typewritermc.realm.repository.ResourceValueMapper
import com.typewritermc.types.DataValue
import com.typewritermc.types.RESOURCE_OWNERSHIP_FAMILY_ID
import com.typewritermc.types.RelationFamilyId
import com.typewritermc.types.RelationId
import com.typewritermc.types.ResourceId
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.catalog.runtimeDefinitions
import java.security.MessageDigest

internal class PageCompiler(
    private val ownershipRelations: Set<RelationId>,
    private val bindings: Map<com.typewritermc.types.TypeUse.Named, NativeBindingRequirement>,
    private val formatRevision: Int = CURRENT_COMPILER_FORMAT,
) {
    context(snapshot: AuthoringView)
    fun compile(root: ResourceId): PageCompileResult {
        val projected =
            ResourceValueMapper.project(
                snapshot.links.values,
                snapshot.resources,
                snapshot.catalog.relations,
                snapshot.catalog.checked,
            )
        val byFirst = projected.projections.groupBy { it.first }
        val occurrencesByLocation = snapshot.links.values.associateBy { it.id.location }
        val relationByEndpoint =
            snapshot.catalog.relations
                .flatMap { relation ->
                    listOf(relation.first.id to relation.id, relation.second.id to relation.id)
                }.toMap()
        val owned = linkedSetOf(root)
        val pending = ArrayDeque<ResourceId>()
        pending += root
        val diagnostics =
            projected.problems.mapTo(mutableListOf()) { problem ->
                val occurrence = occurrencesByLocation[problem.location]
                val missingOwned =
                    problem.code == "target_resource_missing" &&
                        occurrence != null &&
                        relationByEndpoint[occurrence.id.endpoint] in ownershipRelations
                CompileDiagnostic(
                    code = if (missingOwned) "missing_owned_resource" else problem.code,
                    message =
                        if (missingOwned) {
                            "Owned resource ${occurrence.target.resource.value} is absent from the captured snapshot."
                        } else {
                            "Captured link projection is invalid at ${problem.location}."
                        },
                    severity = CompileDiagnosticSeverity.ERROR,
                    source = occurrence?.source ?: problem.location.resource,
                    target = occurrence?.target?.resource,
                )
            }
        while (pending.isNotEmpty()) {
            val parent = pending.removeFirst()
            byFirst[parent].orEmpty().forEach { projection ->
                if (projection.contract in ownershipRelations) {
                    if (projection.second !in snapshot.resources) {
                        diagnostics +=
                            CompileDiagnostic(
                                code = "missing_owned_resource",
                                message = "Owned resource ${projection.second.value} is absent from the captured snapshot.",
                                severity = CompileDiagnosticSeverity.ERROR,
                                source = parent,
                                target = projection.second,
                            )
                    } else if (owned.add(projection.second)) {
                        pending += projection.second
                    }
                }
            }
        }
        val projectedEdges =
            projected.projections
                .filter { projection -> projection.first in owned || projection.second in owned }
                .map { projection ->
                    CompiledEdge(
                        source = CompiledResourceKey(projection.first, CompilationContext.Root),
                        target = CompiledResourceKey(projection.second, CompilationContext.Root),
                        origin =
                            CompiledEdgeOrigin.Relation(
                                projection.contract,
                                projection.firstLocation,
                                projection.secondLocation,
                            ),
                    )
                }
        val resources = owned.mapNotNull { id -> snapshot.resources[id]?.let { id to it } }.sortedBy { it.first.value }
        resources.forEach { (id, record) ->
            val actual = (record.configuration as? TypeSelection.Complete)?.use
            if (actual == null) {
                diagnostics +=
                    CompileDiagnostic(
                        code = "pending_resource_type",
                        message = "Resource ${id.value} has incomplete type arguments.",
                        severity = CompileDiagnosticSeverity.ERROR,
                        source = id,
                    )
                return@forEach
            }
            if (snapshot.catalog.checked.resolve(actual) !is Resolution.Ready) {
                diagnostics +=
                    CompileDiagnostic(
                        code = "unavailable_resource_type",
                        message = "Resource ${id.value} uses a type that is unavailable in the captured catalog.",
                        severity = CompileDiagnosticSeverity.ERROR,
                        source = id,
                    )
            }
            if (id !in snapshot.resourceDefinitions) {
                diagnostics +=
                    CompileDiagnostic(
                        code = "missing_resource_definition",
                        message = "Resource ${id.value} has no captured resource definition identity.",
                        severity = CompileDiagnosticSeverity.ERROR,
                        source = id,
                    )
            }
            if (actual !in bindings) {
                diagnostics +=
                    CompileDiagnostic(
                        code = "missing_native_binding_evidence",
                        message = "Resource ${id.value} has no accepted native binding evidence.",
                        severity = CompileDiagnosticSeverity.ERROR,
                        source = id,
                    )
            }
        }
        val fingerprint =
            digest(
                buildString {
                    append("format:").append(formatRevision)
                    append("|catalog:").append(snapshot.catalog.generation.value)
                    append("|root:").append(root.value)
                    resources.forEach { (id, record) -> append("|resource:").append(id.value).append(':').append(record) }
                    projectedEdges.sortedWith(compareBy({ it.source.source.value }, { it.target.source.value })).forEach { edge ->
                        append("|edge:").append(edge)
                    }
                },
            )
        if (diagnostics.isNotEmpty()) return PageCompileResult.Blocked(fingerprint, diagnostics)
        val runtimeResources = resources.map { (id, record) -> record.compile(id, bindings) }
        val relationIds =
            projectedEdges.mapTo(linkedSetOf()) { edge ->
                (edge.origin as CompiledEdgeOrigin.Relation).relation
            }
        val facts =
            RuntimeCompilationFacts(
                formatRevision = formatRevision,
                root = CompiledResourceKey(root, CompilationContext.Root),
                resources = runtimeResources,
                edges = projectedEdges,
                types =
                    snapshot.catalog.checked.runtimeDefinitions(
                        runtimeResources.flatMap { resource ->
                            resource.value
                                .descendants()
                                .mapNotNull { located ->
                                    (located.value as? DataValue.Named)?.actualType
                                }.toList()
                        },
                    ),
                relations =
                    snapshot.catalog.relations
                        .filter { relation -> relation.id in relationIds }
                        .map { relation ->
                            RuntimeRelationFact(
                                relation.id,
                                RelationFamilyId(RESOURCE_OWNERSHIP_FAMILY_ID) in relation.families,
                            )
                        },
            )
        val canonical = facts.canonicalized()
        return PageCompileResult.Success(
            shard = CompiledPageShard(canonical.semanticDigest(), canonical),
            inputFingerprint = fingerprint,
        )
    }
}

context(snapshot: AuthoringView)
private fun com.typewritermc.authoring.AuthoringRecord.compile(
    id: ResourceId,
    bindings: Map<com.typewritermc.types.TypeUse.Named, NativeBindingRequirement>,
): CompiledResource {
    val actual = (configuration as TypeSelection.Complete).use
    val definition = requireNotNull(snapshot.resourceDefinitions[id])
    val binding = requireNotNull(bindings[actual]) { "Accepted native binding evidence is missing for ${actual.definition}." }
    return CompiledResource(
        key = CompiledResourceKey(id, CompilationContext.Root),
        definition = definition,
        actualType = actual,
        bindingProvider = binding.provider,
        bindingSignature = binding.signature,
        value = DataValue.Named(actual, DataValue.Record(fields)),
    )
}

private fun digest(value: String): ContentDigest =
    ContentDigest(
        MessageDigest.getInstance("SHA-256").digest(value.encodeToByteArray()).joinToString("") { byte ->
            "%02x".format(byte.toInt() and 0xff)
        },
    )

const val CURRENT_COMPILER_FORMAT = 2
