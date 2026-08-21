package com.typewritermc.loader

import kotlinx.coroutines.flow.Flow
import kotlinx.serialization.Serializable

/** Identifies how the stable loader entered its host process and therefore which runtimes it can support. */
@Serializable
enum class HostEntrypoint {
    STANDALONE,
    PAPER,
}

/** Identifies the two independently replaceable child slots owned by an official host. */
@Serializable
enum class ChildKind {
    REALM,
    ENGINE,
}

/**
 * Requests one exact child deployment revision for a host slot.
 *
 * [runtimeId] selects the runtime implementation and [manifestRevision] selects immutable deployment content. Reusing
 * both values is idempotent during reconciliation.
 */
@Serializable
data class DesiredChild(
    val kind: ChildKind,
    val runtimeId: String,
    val manifestRevision: Long,
) {
    init {
        require(runtimeId.isNotBlank()) { "Runtime id must not be blank." }
        require(manifestRevision >= 1) { "Manifest revision must be positive." }
    }
}

/**
 * Captures the complete desired execution state for one host at a monotonic revision.
 *
 * A host owns at most one Realm and one execution engine. Missing slots mean the corresponding child must be removed.
 * Older revisions are ignored after a newer revision has been applied.
 */
@Serializable
data class DesiredTopology(
    val revision: Long,
    val realm: DesiredChild? = null,
    val engine: DesiredChild? = null,
) {
    init {
        require(revision >= 0) { "Topology revision must not be negative." }
        require(realm?.kind != ChildKind.ENGINE) { "Realm slot requires a Realm child." }
        require(engine?.kind != ChildKind.REALM) { "Engine slot requires an Engine child." }
    }

    fun child(kind: ChildKind): DesiredChild? =
        when (kind) {
            ChildKind.REALM -> realm
            ChildKind.ENGINE -> engine
        }
}

/** Summarizes the externally relevant outcome of applying one topology revision. */
enum class ReconciliationStatus {
    ACTIVE,
    FAILED,
    ROLLED_BACK,
}

/**
 * Reports whether a host applied a desired topology or retained an earlier deployment after failure.
 *
 * [message] is diagnostic text for operators and must not be used as a stable machine readable error contract.
 */
data class HostExecutionReport(
    val topologyRevision: Long,
    val status: ReconciliationStatus,
    val message: String? = null,
)

/** Associates a stable host identity with the entrypoint accepted by the control plane. */
data class HostRegistration(
    val hostId: String,
    val entrypoint: HostEntrypoint,
)

/**
 * Connects the stable loader to host registration and desired topology state.
 *
 * [watchExecution] must emit complete snapshots in revision order for the requested host. Reporting may happen after
 * local persistence, so implementations should tolerate retries and duplicate reports.
 */
interface HostControlPlane {
    suspend fun register(entrypoint: HostEntrypoint): HostRegistration

    fun watchExecution(hostId: String): Flow<DesiredTopology>

    suspend fun report(
        hostId: String,
        report: HostExecutionReport,
    )
}

/** Creates an entrypoint aware control plane adapter for one loader application lifetime. */
fun interface HostControlPlaneFactory {
    fun create(entrypoint: HostEntrypoint): HostControlPlane
}
