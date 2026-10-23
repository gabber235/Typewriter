package com.typewritermc.realm.publication

import com.typewritermc.authoring.CompleteValue
import com.typewritermc.authoring.CompletenessResult
import com.typewritermc.authoring.append
import com.typewritermc.authoring.complete
import com.typewritermc.authoring.of
import com.typewritermc.authoring.payload
import com.typewritermc.authoring.root
import com.typewritermc.authoring.use
import com.typewritermc.checking.diagnostics
import com.typewritermc.checking.locations
import com.typewritermc.checking.reason
import com.typewritermc.realm.authoring.AuthoringLease
import com.typewritermc.realm.authoring.AuthoringView
import com.typewritermc.realm.authoring.AuthoringViewStore
import com.typewritermc.realm.checking.CapturedCheckReport
import com.typewritermc.realm.checking.CheckAdmissionTarget
import com.typewritermc.realm.checking.RealmCheckRuntime
import com.typewritermc.services.libs.utils.rethrowExceptional
import com.typewritermc.services.libs.utils.sha256Hex
import com.typewritermc.types.NativeBindingException
import com.typewritermc.types.canonicalValueKey
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.fields
import com.typewritermc.types.items
import com.typewritermc.types.named
import com.typewritermc.types.payload
import com.typewritermc.types.qualified
import com.typewritermc.types.record
import com.typewritermc.types.rows
import com.typewritermc.types.toResourceId
import com.typewritermc.types.toSkir
import com.typewritermc.types.unknownVariant
import com.typewritermc.types.use
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import skirout.editor.v1.authoring_facts.EditExpectation
import skirout.editor.v1.checking.CheckOutcome
import skirout.editor.v1.diagnostic.Diagnostic
import skirout.editor.v1.diagnostic.DiagnosticSeverity
import skirout.editor.v1.publication.DiagnosticEvidence
import skirout.editor.v1.publication.EngineImplementationInputs
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.DiagnosticId
import skirout.editor.v1.type_catalog.NamedTypeUse
import skirout.editor.v1.type_catalog.NativeBindingId
import skirout.editor.v1.type_catalog.PathSegment
import skirout.editor.v1.type_catalog.ResourceId
import skirout.editor.v1.type_catalog.RuleOrigin
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.ValueLocation

data class NativeBindingRequirement(
    val actual: NamedTypeUse,
    val provider: NativeBindingId,
    val signature: String,
)

/**
 * Supplies the engine inputs that fence compilation and publication selection.
 *
 * [activate] checks the captured implementation before invoking the publication callback. It does not load
 * or apply content to an engine; concrete sources own coordination of implementation changes with this check.
 */
interface EngineImplementationSource {
    fun capture(): EngineImplementationInputs

    fun compatible(captured: EngineImplementationInputs): Boolean = capture() == captured

    suspend fun activate(
        captured: EngineImplementationInputs,
        publish: suspend () -> Boolean,
    ): Boolean = compatible(captured) && publish()
}

class StagedEngineImplementationSource(
    private val inputs: EngineImplementationInputs,
) : EngineImplementationSource {
    private val activation = Mutex()

    override fun capture(): EngineImplementationInputs = inputs

    override suspend fun activate(
        captured: EngineImplementationInputs,
        publish: suspend () -> Boolean,
    ): Boolean =
        activation.withLock {
            if (captured != inputs) return@withLock false
            publish()
        }
}

internal sealed interface ResourceReadiness {
    data class Ready(
        val value: CompleteValue,
        val binding: NativeBindingRequirement,
    ) : ResourceReadiness

    data class Blocked(
        val findings: List<Diagnostic>,
    ) : ResourceReadiness {
        init {
            require(findings.isNotEmpty())
        }
    }
}

internal data class CapturedAssessment(
    val resources: Map<ResourceId, ResourceReadiness>,
    val checks: CapturedCheckReport,
    val findings: List<Diagnostic>,
    val evidence: Map<DiagnosticId, DiagnosticEvidence>,
)

internal interface PublicationAcceptance {
    fun capture(): AuthoringLease

    fun <T> withCurrent(block: (AuthoringView) -> T): T

    suspend fun evaluate(capture: AuthoringLease): CapturedAssessment
}

/**
 * Establishes publication readiness for one retained saved view.
 *
 * Captured checks run against that view, independently of editor finding freshness. Every resource must have
 * complete structure and a concrete native binding that can construct it; intrinsic set and map uniqueness
 * is also checked. Findings carry the original expectations needed to relate them to later working values.
 * Assessment itself neither stores compiled blobs nor selects a publication.
 */
internal class AuthoringAcceptance(
    private val views: AuthoringViewStore,
    private val checks: RealmCheckRuntime,
) : PublicationAcceptance {
    override fun capture(): AuthoringLease = views.capture()

    override fun <T> withCurrent(block: (AuthoringView) -> T): T = views.read(block)

    override suspend fun evaluate(capture: AuthoringLease): CapturedAssessment {
        val snapshot = capture
        return run {
            val target = CheckAdmissionTarget.CapturedAcceptance(snapshot.root)
            val report = checks.evaluateCapture(target)
            val evidence = linkedMapOf<DiagnosticId, DiagnosticEvidence>()
            val findings =
                report.results
                    .flatMap { result ->
                        val emitted =
                            when (val outcome = result.outcome) {
                                CheckOutcome.FINISHED -> {
                                    result.findings
                                }

                                is CheckOutcome.NeedsInputWrapper -> {
                                    result.findings +
                                        outcome.locations.ifEmpty { listOf(result.ticket.instance.location) }.map { location ->
                                            publicationDiagnostic("check_needs_input", "A required check input is unavailable.", location)
                                        }
                                }

                                is CheckOutcome.FailedWrapper -> {
                                    result.findings + outcome.diagnostics
                                }

                                is CheckOutcome.IncompleteWrapper -> {
                                    result.findings +
                                        publicationDiagnostic("check_incomplete", outcome.reason, result.ticket.instance.location)
                                }

                                else -> {
                                    unknownVariant(outcome)
                                }
                            }
                        emitted.forEach { finding ->
                            evidence[finding.id] =
                                DiagnosticEvidence(
                                    catalog = snapshot.root.catalog.generation,
                                    expectations = (evidence[finding.id]?.expectations.orEmpty() + result.expectations).distinct(),
                                )
                        }
                        emitted
                    }.toMutableList()
            val resources = linkedMapOf<ResourceId, ResourceReadiness>()
            snapshot.root.resources.forEach { (id, record) ->
                val firstFinding = findings.size

                fun blocked() {
                    val own = findings.drop(firstFinding)
                    resources[id] = ResourceReadiness.Blocked(own)
                    val witness =
                        DiagnosticEvidence(
                            catalog = snapshot.root.catalog.generation,
                            expectations = listOf(EditExpectation.createResource(id = id, expected = record)),
                        )
                    own.forEach { evidence[it.id] = witness }
                }
                val actual = (record.configuration as? TypeSelection.CompleteWrapper)?.use
                if (actual == null) {
                    findings +=
                        publicationDiagnostic(
                            "pending_type",
                            "Resource ${id.value} has incomplete type arguments.",
                            ValueLocation.of(id),
                        )
                    blocked()
                    return@forEach
                }
                val resolved =
                    snapshot.root.catalog.checked
                        .resolve(actual.use)
                val checked = (resolved as? Resolution.Ready)?.value
                if (checked == null) {
                    findings +=
                        publicationDiagnostic(
                            "unresolved_type",
                            "Resource ${id.value} uses an unavailable type.",
                            ValueLocation.of(id),
                        )
                    blocked()
                    return@forEach
                }
                val value = DataValue.named(actual, DataValue.RecordWrapper(record.payload))
                intrinsicCollectionProblems(value, ValueLocation.of(id)).forEach { problem ->
                    findings += publicationDiagnostic(problem.code, problem.message, problem.location)
                }
                when (val complete = checked.complete(value)) {
                    is CompletenessResult.Unfinished -> {
                        complete.locations.forEach { location ->
                            findings +=
                                publicationDiagnostic(
                                    "unfinished_value",
                                    "A required value is unfinished.",
                                    location.copy(resource = id),
                                )
                        }
                    }

                    is CompletenessResult.Invalid -> {
                        complete.problems.forEach { problem ->
                            findings +=
                                publicationDiagnostic(
                                    problem.code,
                                    "The authored value is structurally invalid.",
                                    problem.location.copy(resource = id),
                                )
                        }
                    }

                    is CompletenessResult.Complete -> {
                        if (findings.size > firstFinding) {
                            blocked()
                            return@forEach
                        }
                        try {
                            val binding =
                                snapshot.root.catalog.nativeBindings
                                    .bind(checked)
                            require(!binding.opaque) { "Engine resources require a concrete native binding." }
                            requireNotNull(binding.decode(complete.value)) { "Native construction returned null." }
                            resources[id] =
                                ResourceReadiness.Ready(
                                    complete.value,
                                    NativeBindingRequirement(actual, binding.provider, binding.signature),
                                )
                        } catch (failure: Exception) {
                            failure.rethrowExceptional()
                            val code = (failure as? NativeBindingException)?.code ?: "native_construction_failed"
                            findings +=
                                publicationDiagnostic(
                                    code,
                                    failure.message ?: "Native construction failed.",
                                    ValueLocation.of(id),
                                )
                        }
                    }
                }
                if (findings.size > firstFinding) blocked()
            }
            if (!report.complete) {
                findings += publicationDiagnostic("check_coverage_incomplete", "Required captured checks did not complete.", null)
            }
            CapturedAssessment(resources, report, findings.distinctBy { it.id }, evidence)
        }
    }
}

private data class IntrinsicCollectionProblem(
    val code: String,
    val message: String,
    val location: ValueLocation,
)

private fun intrinsicCollectionProblems(
    value: DataValue,
    at: ValueLocation,
): List<IntrinsicCollectionProblem> =
    buildList {
        when (value) {
            is DataValue.NamedWrapper -> {
                addAll(intrinsicCollectionProblems(value.payload, at))
            }

            is DataValue.RecordWrapper -> {
                value.fields.forEach { field ->
                    addAll(intrinsicCollectionProblems(field.value, at.append(PathSegment.createField(name = field.name))))
                }
            }

            is DataValue.ListValueWrapper -> {
                value.items.forEach { item ->
                    addAll(intrinsicCollectionProblems(item.value, at.append(PathSegment.createItem(id = item.id))))
                }
            }

            is DataValue.SetValueWrapper -> {
                value.items
                    .groupBy { item -> item.value.canonicalValueKey() }
                    .values
                    .filter { duplicates -> duplicates.size > 1 }
                    .flatMap { duplicates -> duplicates.drop(1) }
                    .forEach { duplicate ->
                        add(
                            IntrinsicCollectionProblem(
                                "duplicate_set_value",
                                "A set contains the same authored value more than once.",
                                at.append(PathSegment.createItem(id = duplicate.id)),
                            ),
                        )
                    }
                value.items.forEach { item ->
                    addAll(intrinsicCollectionProblems(item.value, at.append(PathSegment.createItem(id = item.id))))
                }
            }

            is DataValue.MapValueWrapper -> {
                value.rows
                    .groupBy { row -> row.key.canonicalValueKey() }
                    .values
                    .filter { duplicates -> duplicates.size > 1 }
                    .flatMap { duplicates -> duplicates.drop(1) }
                    .forEach { duplicate ->
                        add(
                            IntrinsicCollectionProblem(
                                "duplicate_map_key",
                                "A map contains the same authored key more than once.",
                                at.append(PathSegment.createItem(id = duplicate.id), PathSegment.MAP_KEY),
                            ),
                        )
                    }
                value.rows.forEach { row ->
                    val rowLocation = at.append(PathSegment.createItem(id = row.id))
                    addAll(intrinsicCollectionProblems(row.key, rowLocation.append(PathSegment.MAP_KEY)))
                    addAll(intrinsicCollectionProblems(row.value, rowLocation.append(PathSegment.MAP_VALUE)))
                }
            }

            else -> {
                Unit
            }
        }
    }

/**
 * Builds a publication finding. The identity digests location, code, and message so distinct findings
 * never share an id while repeated identical findings collapse.
 */
internal fun publicationDiagnostic(
    code: String,
    message: String,
    location: ValueLocation? = null,
): Diagnostic =
    Diagnostic(
        id =
            DiagnosticId(
                value = "publication:${"${location?.let(ValueLocation.serializer::toJsonCode)}\u0000$code\u0000$message".sha256Hex()}",
            ),
        origin = RuleOrigin(owner = PUBLICATION_DIAGNOSTIC_TYPE, ordinal = 0),
        code = code,
        message = message,
        severity = DiagnosticSeverity.ERROR,
        primary = location,
        related = emptyList(),
    )

internal val PUBLICATION_DIAGNOSTIC_TYPE =
    TypeDefinitionId.qualified("typewriter", "publication")
