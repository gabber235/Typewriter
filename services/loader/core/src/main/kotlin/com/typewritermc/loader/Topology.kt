package com.typewritermc.loader

import kotlinx.coroutines.flow.Flow

enum class HostEntrypoint {
    STANDALONE,
    PAPER,
}

enum class ChildKind {
    REALM,
    ENGINE,
}

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

enum class ReconciliationStatus {
    ACTIVE,
    FAILED,
    ROLLED_BACK,
}

data class HostExecutionReport(
    val topologyRevision: Long,
    val status: ReconciliationStatus,
    val message: String? = null,
)

data class HostRegistration(
    val hostId: String,
    val entrypoint: HostEntrypoint,
)

interface HostControlPlane {
    suspend fun register(entrypoint: HostEntrypoint): HostRegistration

    fun watchExecution(hostId: String): Flow<DesiredTopology>

    suspend fun report(
        hostId: String,
        report: HostExecutionReport,
    )
}
