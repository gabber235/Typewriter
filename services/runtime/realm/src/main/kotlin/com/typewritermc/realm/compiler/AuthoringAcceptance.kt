package com.typewritermc.realm.compiler

import com.typewritermc.authoring.CompleteValue
import com.typewritermc.authoring.CompletenessResult
import com.typewritermc.authoring.DiagnosticId
import com.typewritermc.authoring.EditExpectation
import com.typewritermc.authoring.NativeBindingId
import com.typewritermc.authoring.PathSegment
import com.typewritermc.authoring.TypeSelection
import com.typewritermc.authoring.ValueLocation
import com.typewritermc.authoring.ValuePath
import com.typewritermc.authoring.append
import com.typewritermc.authoring.complete
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.checking.CheckOutcome
import com.typewritermc.checking.Diagnostic
import com.typewritermc.checking.DiagnosticSeverity
import com.typewritermc.checking.InputToken
import com.typewritermc.realm.authoring.AuthoringLease
import com.typewritermc.realm.authoring.AuthoringView
import com.typewritermc.realm.authoring.AuthoringViewStore
import com.typewritermc.realm.checking.CapturedCheckReport
import com.typewritermc.realm.checking.CheckAdmissionTarget
import com.typewritermc.realm.checking.RealmCheckRuntime
import com.typewritermc.services.libs.utils.rethrowExceptional
import com.typewritermc.services.libs.utils.sha256Hex
import com.typewritermc.types.DataValue
import com.typewritermc.types.NativeBindingException
import com.typewritermc.types.ResourceId
import com.typewritermc.types.canonicalValueKey
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.qualified
import com.typewritermc.types.use
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.serialization.Serializable
import skirout.editor.v1.type_catalog.NamedTypeUse
import skirout.editor.v1.type_catalog.RuleOrigin
import skirout.editor.v1.type_catalog.TypeDefinitionId

data class NativeBindingRequirement(
    val actual: NamedTypeUse,
    val provider: NativeBindingId,
    val signature: String,
)

@Serializable
data class EngineImplementationInputs(
    val token: InputToken,
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

/** Classifies diagnostics once at the saved candidate evaluation boundary. */
sealed interface PublicationNotice {
    val diagnostic: Diagnostic

    @ConsistentCopyVisibility
    data class Information internal constructor(
        override val diagnostic: Diagnostic,
    ) : PublicationNotice {
        init {
            require(diagnostic.severity == DiagnosticSeverity.Info)
        }
    }

    @ConsistentCopyVisibility
    data class Warning internal constructor(
        override val diagnostic: Diagnostic,
    ) : PublicationNotice {
        init {
            require(diagnostic.severity == DiagnosticSeverity.Warning)
        }
    }
}

@ConsistentCopyVisibility
data class PublicationBlocker internal constructor(
    val diagnostic: Diagnostic,
) {
    init {
        require(diagnostic.severity == DiagnosticSeverity.Error)
    }
}

/** A blocking assessment always has at least one reason. */
data class PublicationBlockers(
    val first: PublicationBlocker,
    val additional: List<PublicationBlocker> = emptyList(),
) {
    val all: List<PublicationBlocker> get() = listOf(first) + additional

    companion object {
        fun from(findings: List<Diagnostic>): PublicationBlockers {
            val blockers = findings.map(::PublicationBlocker)
            return PublicationBlockers(blockers.first(), blockers.drop(1))
        }
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

/** Authoring facts required for a saved finding to describe a working value. */
data class DiagnosticEvidence(
    val catalog: CatalogGeneration,
    val expectations: List<EditExpectation>,
)

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
                                CheckOutcome.Finished -> {
                                    result.findings
                                }

                                is CheckOutcome.NeedsInput -> {
                                    result.findings +
                                        outcome.locations.ifEmpty { listOf(result.ticket.instance.location) }.map { location ->
                                            publicationDiagnostic("check_needs_input", "A required check input is unavailable.", location)
                                        }
                                }

                                is CheckOutcome.Failed -> {
                                    result.findings + outcome.diagnostics
                                }

                                is CheckOutcome.Incomplete -> {
                                    result.findings +
                                        publicationDiagnostic("check_incomplete", outcome.reason, result.ticket.instance.location)
                                }
                            }
                        emitted.forEach { finding ->
                            evidence[finding.id] =
                                DiagnosticEvidence(
                                    snapshot.root.catalog.generation,
                                    (evidence[finding.id]?.expectations.orEmpty() + result.expectations).distinct(),
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
                    val witness = DiagnosticEvidence(snapshot.root.catalog.generation, listOf(EditExpectation.Resource(id, record)))
                    own.forEach { evidence[it.id] = witness }
                }
                val actual = (record.configuration as? TypeSelection.Complete)?.use
                if (actual == null) {
                    findings +=
                        publicationDiagnostic(
                            "pending_type",
                            "Resource ${id.value} has incomplete type arguments.",
                            ValueLocation(id, ValuePath()),
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
                            ValueLocation(id, ValuePath()),
                        )
                    blocked()
                    return@forEach
                }
                val value = DataValue.Named(actual, DataValue.Record(record.fields))
                intrinsicCollectionProblems(value, ValueLocation(id, ValuePath())).forEach { problem ->
                    findings += publicationDiagnostic(problem.code, problem.message, problem.location)
                }
                when (val complete = checked.complete(value)) {
                    is CompletenessResult.Unfinished -> {
                        complete.locations.forEach { location ->
                            findings +=
                                publicationDiagnostic("unfinished_value", "A required value is unfinished.", location.copy(resource = id))
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
                                    ValueLocation(id, ValuePath()),
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
            is DataValue.Named -> {
                addAll(intrinsicCollectionProblems(value.payload, at))
            }

            is DataValue.Record -> {
                value.fields.forEach { (name, field) ->
                    addAll(intrinsicCollectionProblems(field, at.append(PathSegment.Field(name))))
                }
            }

            is DataValue.ListValue -> {
                value.items.forEach { item ->
                    addAll(intrinsicCollectionProblems(item.value, at.append(PathSegment.Item(item.id))))
                }
            }

            is DataValue.SetValue -> {
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
                                at.append(PathSegment.Item(duplicate.id)),
                            ),
                        )
                    }
                value.items.forEach { item ->
                    addAll(intrinsicCollectionProblems(item.value, at.append(PathSegment.Item(item.id))))
                }
            }

            is DataValue.MapValue -> {
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
                                at.append(PathSegment.Item(duplicate.id), PathSegment.MapKey),
                            ),
                        )
                    }
                value.rows.forEach { row ->
                    val rowLocation = at.append(PathSegment.Item(row.id))
                    addAll(intrinsicCollectionProblems(row.key, rowLocation.append(PathSegment.MapKey)))
                    addAll(intrinsicCollectionProblems(row.value, rowLocation.append(PathSegment.MapValue)))
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
        id = DiagnosticId("publication:${"$location\u0000$code\u0000$message".sha256Hex()}"),
        origin = RuleOrigin(owner = PUBLICATION_DIAGNOSTIC_TYPE, ordinal = 0),
        code = code,
        message = message,
        severity = DiagnosticSeverity.Error,
        primary = location,
        related = emptyList(),
    )

internal val PUBLICATION_DIAGNOSTIC_TYPE =
    TypeDefinitionId.qualified("typewriter", "publication")
