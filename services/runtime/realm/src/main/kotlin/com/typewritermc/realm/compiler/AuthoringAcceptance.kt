package com.typewritermc.realm.compiler

import com.typewritermc.authoring.CompletenessResult
import com.typewritermc.authoring.DiagnosticId
import com.typewritermc.authoring.NativeBindingId
import com.typewritermc.authoring.PathSegment
import com.typewritermc.authoring.PublicationId
import com.typewritermc.authoring.TypeSelection
import com.typewritermc.authoring.ValueLocation
import com.typewritermc.authoring.ValuePath
import com.typewritermc.authoring.complete
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.checking.CheckOutcome
import com.typewritermc.checking.Diagnostic
import com.typewritermc.checking.DiagnosticSeverity
import com.typewritermc.checking.InputObservation
import com.typewritermc.checking.InputToken
import com.typewritermc.checking.SnapshotId
import com.typewritermc.configuration.RuleOrigin
import com.typewritermc.realm.authoring.AuthoringSnapshotStore
import com.typewritermc.realm.authoring.SnapshotLease
import com.typewritermc.realm.checking.CheckAdmissionTarget
import com.typewritermc.realm.checking.CheckInstanceId
import com.typewritermc.realm.checking.RealmCheckRuntime
import com.typewritermc.scripting.RuntimeMemberSignature
import com.typewritermc.types.DataValue
import com.typewritermc.types.NativeBindingException
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.TypeId
import com.typewritermc.types.TypeUse
import com.typewritermc.types.canonicalValueKey
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.serialization.Serializable
import java.util.concurrent.CancellationException

data class CheckCoverage(
    val required: Set<CheckInstanceId>,
    val completed: Set<CheckInstanceId>,
) {
    val complete: Boolean get() = required == completed
}

data class NativeBindingRequirement(
    val actual: TypeUse.Named,
    val provider: NativeBindingId,
    val signature: String,
)

@Serializable
data class EngineImplementationInputs(
    val signatures: Set<RuntimeMemberSignature>,
    val token: InputToken,
)

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

data class AcceptedSnapshot(
    val snapshot: SnapshotId,
    val catalog: CatalogGeneration,
    val coverage: CheckCoverage,
    val evidence: List<InputObservation>,
    val bindingRequirements: List<NativeBindingRequirement>,
)

sealed interface AcceptanceResult {
    data class Accepted(
        val proof: AcceptedSnapshot,
    ) : AcceptanceResult

    data class Blocked(
        val findings: List<Diagnostic>,
    ) : AcceptanceResult
}

internal interface PublicationAcceptance {
    fun retain(
        expectedSnapshot: SnapshotId,
        expectedCatalog: CatalogGeneration,
    ): SnapshotLease

    suspend fun evaluate(capture: SnapshotLease): AcceptanceResult
}

internal class AuthoringAcceptance(
    private val snapshots: AuthoringSnapshotStore,
    private val checks: RealmCheckRuntime,
) : PublicationAcceptance {
    override fun retain(
        expectedSnapshot: SnapshotId,
        expectedCatalog: CatalogGeneration,
    ): SnapshotLease {
        val snapshot = snapshots.retain(expectedSnapshot)
        try {
            require(snapshot.root.catalog.generation == expectedCatalog) {
                "Publication capture uses a different catalog generation."
            }
            return snapshot
        } catch (failure: Throwable) {
            snapshot.close()
            throw failure
        }
    }

    override suspend fun evaluate(capture: SnapshotLease): AcceptanceResult {
        val snapshot = capture
        return run {
            val target = CheckAdmissionTarget.CapturedAcceptance(snapshot.root.id, snapshot.root.catalog.generation)
            val report = checks.evaluateCapture(target)
            val required = report.required
            val completed =
                report.results
                    .filter { result -> result.outcome !is CheckOutcome.Incomplete }
                    .mapTo(linkedSetOf()) { result -> result.ticket.instance }
            val findings =
                report.results
                    .flatMap { result ->
                        when (val outcome = result.outcome) {
                            CheckOutcome.Finished -> {
                                result.findings
                            }

                            is CheckOutcome.NeedsInput -> {
                                result.findings +
                                    outcome.locations.ifEmpty { listOf(result.ticket.instance.location) }.map { location ->
                                        diagnostic(
                                            "check_needs_input",
                                            "A required check input is unavailable.",
                                            location,
                                        )
                                    }
                            }

                            is CheckOutcome.Failed -> {
                                result.findings + outcome.diagnostics
                            }

                            is CheckOutcome.Incomplete -> {
                                result.findings + diagnostic("check_incomplete", outcome.reason, result.ticket.instance.location)
                            }
                        }
                    }.toMutableList()
            val requirements = mutableListOf<NativeBindingRequirement>()
            snapshot.root.resources.forEach { (id, record) ->
                val actual = (record.configuration as? TypeSelection.Complete)?.use
                if (actual == null) {
                    findings +=
                        diagnostic("pending_type", "Resource ${id.value} has incomplete type arguments.", ValueLocation(id, ValuePath()))
                    return@forEach
                }
                val resolved =
                    snapshot.root.catalog.checked
                        .resolve(actual)
                val checked = (resolved as? com.typewritermc.types.catalog.Resolution.Ready)?.value
                if (checked == null) {
                    findings +=
                        diagnostic("unresolved_type", "Resource ${id.value} uses an unavailable type.", ValueLocation(id, ValuePath()))
                    return@forEach
                }
                val value = DataValue.Named(actual, DataValue.Record(record.fields))
                intrinsicCollectionProblems(value, ValueLocation(id, ValuePath())).forEach { problem ->
                    findings += diagnostic(problem.code, problem.message, problem.location)
                }
                when (val complete = checked.complete(value)) {
                    is CompletenessResult.Unfinished -> {
                        complete.locations.forEach { location ->
                            findings += diagnostic("unfinished_value", "A required value is unfinished.", location.copy(resource = id))
                        }
                    }

                    is CompletenessResult.Invalid -> {
                        complete.problems.forEach { problem ->
                            findings +=
                                diagnostic(
                                    problem.code,
                                    "The authored value is structurally invalid.",
                                    problem.location.copy(resource = id),
                                )
                        }
                    }

                    is CompletenessResult.Complete -> {
                        try {
                            val binding =
                                snapshot.root.catalog.nativeBindings
                                    .bind(checked)
                            require(!binding.opaque) { "Engine resources require a concrete native binding." }
                            requireNotNull(binding.decode(complete.value)) { "Native construction returned null." }
                            requirements += NativeBindingRequirement(actual, binding.provider, binding.signature)
                        } catch (cancelled: CancellationException) {
                            throw cancelled
                        } catch (fatal: VirtualMachineError) {
                            throw fatal
                        } catch (failure: Exception) {
                            val code = (failure as? NativeBindingException)?.code ?: "native_construction_failed"
                            findings += diagnostic(code, failure.message ?: "Native construction failed.", ValueLocation(id, ValuePath()))
                        }
                    }
                }
            }
            val coverage = CheckCoverage(required, completed)
            if (!coverage.complete) {
                findings += diagnostic("check_coverage_incomplete", "Required captured checks did not complete.", null)
            }
            if (findings.any { it.severity == DiagnosticSeverity.Error }) {
                AcceptanceResult.Blocked(findings.distinctBy { it.id })
            } else {
                AcceptanceResult.Accepted(
                    AcceptedSnapshot(
                        snapshot = snapshot.root.id,
                        catalog = snapshot.root.catalog.generation,
                        coverage = coverage,
                        evidence = report.results.flatMap { it.observations }.distinct(),
                        bindingRequirements = requirements.distinct(),
                    ),
                )
            }
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

private fun ValueLocation.append(vararg segments: PathSegment): ValueLocation = copy(path = ValuePath(path.segments + segments))

private fun diagnostic(
    code: String,
    message: String,
    location: ValueLocation?,
): Diagnostic {
    val identity = "${location?.resource?.value.orEmpty()}:${location?.path}:$code"
    return Diagnostic(
        id = DiagnosticId("publication:${identity.hashCode().toUInt().toString(16)}"),
        origin = RuleOrigin(PUBLICATION_DIAGNOSTIC_TYPE, 0),
        code = code,
        message = message,
        severity = DiagnosticSeverity.Error,
        primary = location,
        related = emptyList(),
    )
}

private val PUBLICATION_DIAGNOSTIC_TYPE =
    TypeDefinitionId(TypeId.Qualified("typewriter", "publication"), 1)
