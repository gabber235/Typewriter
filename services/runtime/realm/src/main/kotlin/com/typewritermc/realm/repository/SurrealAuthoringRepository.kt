package com.typewritermc.realm.repository

import com.surrealdb.RecordId
import com.surrealdb.Surreal
import com.surrealdb.Transaction
import com.typewritermc.authoring.AuthoringRecord
import com.typewritermc.authoring.AuthoringResourceDefinition
import com.typewritermc.authoring.BatchId
import com.typewritermc.authoring.CommitResult
import com.typewritermc.authoring.CounterpartChoice
import com.typewritermc.authoring.EditIntent
import com.typewritermc.authoring.InputConflict
import com.typewritermc.authoring.ItemId
import com.typewritermc.authoring.PathSegment
import com.typewritermc.authoring.PreparedEdit
import com.typewritermc.authoring.RelationProjectionDelta
import com.typewritermc.authoring.TypeSelection
import com.typewritermc.authoring.ValueLocation
import com.typewritermc.authoring.ValuePath
import com.typewritermc.authoring.ValueProblem
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.checking.InputIdentity
import com.typewritermc.checking.InputObservation
import com.typewritermc.checking.InputToken
import com.typewritermc.checking.SnapshotId
import com.typewritermc.realm.authoring.AuthoringSnapshotDelta
import com.typewritermc.realm.authoring.AuthoringSnapshotStore
import com.typewritermc.realm.authoring.SnapshotCatalogLease
import com.typewritermc.realm.authoring.SnapshotCommit
import com.typewritermc.realm.authoring.absentInputToken
import com.typewritermc.realm.authoring.authoringStorageJson
import com.typewritermc.realm.repository.utils.StorageRetryPolicy
import com.typewritermc.realm.repository.utils.inTransaction
import com.typewritermc.realm.repository.utils.unifiedSurrealId
import com.typewritermc.realm.search.AuthoringSearchIndexer
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.TypeUse
import com.typewritermc.types.catalog.Resolution
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.serialization.KSerializer
import kotlinx.serialization.Serializable
import kotlinx.serialization.decodeFromString
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import java.lang.ref.WeakReference
import java.security.MessageDigest

/** Commits resources, projections, tokens, receipts, search rows, and outbox rows in one transaction. */
internal class SurrealAuthoringRepository(
    private val database: Surreal,
    private val snapshots: AuthoringSnapshotStore,
    private val catalog: () -> SnapshotCatalogLease,
    private val searchIndexer: AuthoringSearchIndexer,
    private val relationStore: DeclaredRelationStore = SurrealDeclaredRelationStore(),
    private val retryPolicy: StorageRetryPolicy = StorageRetryPolicy(),
) : AuthoringRepository,
    AuthoringEventOutbox {
    private val admission = Mutex()

    init {
        bootstrap()
    }

    suspend fun activateCatalog(
        next: SnapshotCatalogLease,
        install: () -> Unit,
        publish: () -> Unit,
    ) {
        admission.withLock {
            var changed = false
            snapshots.commitAndInstall {
                val activation = database.inTransaction { transaction -> transaction.prepareCatalogActivation(next.generation) }
                if (activation == CatalogActivation.AlreadyActive) {
                    val coherent = snapshots.capture().use { it.root.catalog.generation == next.generation }
                    if (coherent) {
                        database.clearLocalCatalogTransition(next.generation)
                        return@commitAndInstall SnapshotCommit(Unit, null)
                    }
                    database.markLocalCatalogTransition(next.generation)
                    install()
                    changed = true
                    return@commitAndInstall SnapshotCommit(Unit, catalogReconciliationDelta(next))
                }
                database.markLocalCatalogTransition(next.generation)
                try {
                    install()
                } catch (failure: Throwable) {
                    runCatching {
                        database.inTransaction { transaction -> transaction.cancelCatalogActivation(next.generation) }
                    }.onSuccess {
                        database.clearLocalCatalogTransition(next.generation)
                    }.exceptionOrNull()
                        ?.let(failure::addSuppressed)
                    throw failure
                }
                val revision =
                    retryPolicy.retryWriteConflicts {
                        database.inTransaction { transaction -> transaction.finalizeCatalogActivation(next.generation) }
                    }
                val identity = InputIdentity.Catalog(next.generation)
                changed = true
                SnapshotCommit(
                    Unit,
                    AuthoringSnapshotDelta(
                        snapshot = SnapshotId("realm:$revision"),
                        inputTokens = mapOf(identity to catalogInputToken(next.generation)),
                        catalog = next.retain(),
                    ),
                )
            }
            database.clearLocalCatalogTransition(next.generation)
            if (changed) publish()
        }
    }

    override suspend fun commit(edit: PreparedEdit): CommitResult =
        admission.withLock {
            val active = catalog()
            try {
                val digest = canonicalPreparedIntentDigest(edit)
                val transactionResult =
                    try {
                        retryPolicy.retryWriteConflicts {
                            snapshots.commitAndInstall {
                                val accepted = database.inTransaction { transaction -> accept(transaction, active, edit, digest) }
                                SnapshotCommit(
                                    accepted,
                                    reconciledSnapshotDelta(),
                                )
                            }
                        }
                    } catch (rejected: LogicalRejection) {
                        return@withLock rejected.result
                    }
                when (transactionResult) {
                    is AcceptedCommit.Replayed -> {
                        transactionResult.result
                    }

                    is AcceptedCommit.Fresh -> {
                        CommitResult.Committed(
                            transactionResult.delta.snapshot,
                            transactionResult.delta.inputTokens.keys,
                        )
                    }
                }
            } finally {
                active.close()
            }
        }

    override suspend fun replay(edit: PreparedEdit): CommitResult? =
        admission.withLock {
            val digest = canonicalPreparedIntentDigest(edit)
            try {
                database.inTransaction { transaction -> transaction.replay(edit, digest) }
            } catch (rejected: LogicalRejection) {
                rejected.result
            }
        }

    override suspend fun pending(): List<AuthoringCommittedEvent> =
        database
            .query(
                "SELECT batch, payload, sequence FROM authoring_event_outbox " +
                    "WHERE acknowledged = false ORDER BY sequence, batch;",
            ).take(0)
            .getArray()
            .map { row ->
                val value = row.getObject()
                val stored = authoringStorageJson.decodeFromString<StoredCommitDelta>(value.get("payload").getString())
                AuthoringCommittedEvent(BatchId(value.get("batch").getString()), stored.toDomain())
            }

    override suspend fun acknowledge(batch: BatchId) {
        database
            .query(
                "UPDATE ONLY \$event SET acknowledged = true;",
                mapOf("event" to RecordId("authoring_event_outbox", batch.value)),
            ).take(0)
    }

    private fun accept(
        transaction: Transaction,
        active: SnapshotCatalogLease,
        edit: PreparedEdit,
        digest: String,
    ): AcceptedCommit {
        transaction.replay(edit, digest)?.let { return AcceptedCommit.Replayed(it) }
        if (database.localCatalogTransition() != null) {
            throw LogicalRejection(catalogTransitionRejection(edit))
        }
        if (active.generation != edit.catalog) {
            throw LogicalRejection(CommitResult.CatalogChanged(active.generation))
        }
        val fence = transaction.catalogFenceState()
        if (fence.pending != null) {
            throw LogicalRejection(catalogTransitionRejection(edit))
        }
        val durableGeneration = fence.active
        if (durableGeneration != edit.catalog) {
            throw LogicalRejection(CommitResult.CatalogChanged(durableGeneration))
        }
        val revision = transaction.touchAcceptanceFence()
        val latest = transaction.loadResources()
        val planner = AuthoringMutationPlanner(active.checked, active.relations, active.endpointBindings)
        val plan =
            when (val planned = planner.plan(latest.records, edit)) {
                is MutationPlanningResult.Accepted -> planned.plan
                is MutationPlanningResult.Rejected -> throw LogicalRejection(CommitResult.Rejected(planned.problems))
            }
        requireWriteEvidence(edit, latest.records, mutationPlanWriteInputs(plan, latest.records))
        transaction.requireInputs(edit.observations)
        val snapshot = SnapshotId("realm:$revision")
        val inputTokens = plan.changedInputs.associateWith { identity -> authoredInputToken(revision, identity) }
        val storedRelations = relationStore.prepare(plan.relations, transaction)
        val changedDefinitions =
            plan.resources.mapValues { (_, record) -> record.resourceDefinition(active.resources, active.checked).id }
        val resourceDefinitions = latest.definitions + changedDefinitions - plan.removedResources
        transaction.upsertResources(plan.resources, changedDefinitions, revision)
        relationStore.apply(storedRelations, revision, transaction)
        transaction.removeResources(plan.removedResources)
        searchIndexer.apply(
            transaction = transaction,
            plan = plan,
            resources = latest.records + plan.resources - plan.removedResources,
            definitions = resourceDefinitions,
            catalog = active.checked,
            contracts = active.relations,
            endpointBindings = active.endpointBindings,
            snapshot = revision,
        )
        transaction.storeInputTokens(inputTokens, revision)
        val delta =
            CommitDelta(
                previousSnapshot = SnapshotId("realm:${revision - 1}"),
                snapshot = snapshot,
                catalog = active.generation,
                resources = plan.resources,
                resourceDefinitions = changedDefinitions,
                removedResources = plan.removedResources,
                relations = plan.relations,
                inputTokens = inputTokens,
            )
        val result = CommitResult.Committed(snapshot, inputTokens.keys)
        transaction.storeReceipt(edit, digest, result)
        transaction.enqueue(edit.id, revision, delta)
        return AcceptedCommit.Fresh(delta)
    }

    private fun bootstrap() {
        val lease = snapshots.capture()
        val active = catalog()
        try {
            database.inTransaction { transaction ->
                transaction.initializeCatalogGeneration(active.generation)
                val hasInputs =
                    transaction
                        .query("SELECT VALUE id FROM authoring_input LIMIT 1;")
                        .take(0)
                        .getArray()
                        .len() > 0
                if (hasInputs) return@inTransaction
                val hasResources =
                    transaction
                        .query("SELECT VALUE id FROM resource LIMIT 1;")
                        .take(0)
                        .getArray()
                        .len() > 0
                check(!hasResources) { "Persistent authoring resources exist without input tokens." }
                val resources = lease.root.resources
                transaction.upsertResources(resources, lease.root.resourceDefinitions, 0)
                val projected =
                    ResourceValueMapper.project(
                        lease.root.links.values,
                        resources,
                        active.relations,
                        active.checked,
                    )
                check(projected.problems.isEmpty()) { "Initial authored graph is structurally invalid: ${projected.problems}" }
                val relations = RelationProjectionDelta(emptyList(), projected.projections, emptyList())
                relationStore.apply(relationStore.prepare(relations, transaction), 0, transaction)
                transaction.storeInputTokens(lease.root.inputs, 0)
                val plan = AuthoringMutationPlan(resources, emptySet(), relations, lease.root.inputs.keys)
                searchIndexer.apply(
                    transaction,
                    plan,
                    resources,
                    lease.root.resourceDefinitions,
                    active.checked,
                    active.relations,
                    active.endpointBindings,
                    0,
                )
            }
        } finally {
            active.close()
            lease.close()
        }
    }

    private fun reconciledSnapshotDelta(): AuthoringSnapshotDelta? {
        val persisted = requireNotNull(SurrealAuthoringSeedLoader(database).load())
        val local = snapshots.capture()
        try {
            if (persisted.snapshot == local.root.id) return null
            val changed =
                persisted.resources.keys.filterTo(linkedSetOf()) { id ->
                    local.root.resources[id] != persisted.resources[id] ||
                        local.root.resourceDefinitions[id] != persisted.resourceDefinitions[id]
                }
            val resources = persisted.resources.filterKeys { it in changed }
            val definitions = persisted.resourceDefinitions.filterKeys { it in changed }
            val removed = local.root.resources.keys - persisted.resources.keys
            val tokens = persisted.inputTokens.filter { (identity, token) -> local.root.inputs[identity] != token }
            return AuthoringSnapshotDelta(
                snapshot = persisted.snapshot,
                upsertedResources = resources,
                resourceDefinitions = definitions,
                removedResources = removed,
                inputTokens = tokens,
            )
        } finally {
            local.close()
        }
    }

    private fun catalogReconciliationDelta(next: SnapshotCatalogLease): AuthoringSnapshotDelta {
        val persisted = SurrealAuthoringSeedLoader(database).loadFor(next)
        val local = snapshots.capture()
        try {
            val changed =
                persisted.resources.keys.filterTo(linkedSetOf()) { id ->
                    local.root.resources[id] != persisted.resources[id] ||
                        local.root.resourceDefinitions[id] != persisted.resourceDefinitions[id]
                }
            val resources = persisted.resources.filterKeys { it in changed }
            val definitions = persisted.resourceDefinitions.filterKeys { it in changed }
            val removed = local.root.resources.keys - persisted.resources.keys
            val tokens = persisted.inputTokens.filter { (identity, token) -> local.root.inputs[identity] != token }
            return AuthoringSnapshotDelta(
                snapshot = persisted.snapshot,
                upsertedResources = resources,
                resourceDefinitions = definitions,
                removedResources = removed,
                inputTokens = tokens,
                catalog = next.retain(),
            )
        } finally {
            local.close()
        }
    }
}

private fun requireWriteEvidence(
    edit: PreparedEdit,
    latest: Map<ResourceId, AuthoringRecord>,
    plannedInputs: Set<InputIdentity>,
) {
    val required = mandatoryWriteInputs(edit, latest) + plannedInputs
    val observed = edit.observations.mapTo(hashSetOf(), InputObservation::identity)
    val missing = required - observed
    if (missing.isEmpty()) return
    val problems =
        missing.sortedBy(InputIdentity::toString).map { identity ->
            com.typewritermc.authoring.ValueProblem(identity.location(), "missing_input_observation")
        }
    throw LogicalRejection(CommitResult.Rejected(problems))
}

internal fun relationWriteInputs(
    delta: RelationProjectionDelta,
    existingResources: Map<ResourceId, AuthoringRecord>,
): Set<InputIdentity> =
    buildSet {
        (delta.removed + delta.created + delta.metadataChanged).forEach { projection ->
            add(InputIdentity.Incoming(projection.first, projection.contract))
            add(InputIdentity.Incoming(projection.first, null))
            add(InputIdentity.Incoming(projection.second, projection.contract))
            add(InputIdentity.Incoming(projection.second, null))
            projection.firstLocation?.let {
                addAll(ValueLocation(projection.first, it).relationPathEvidence(existingResources))
            }
            projection.secondLocation?.let {
                addAll(ValueLocation(projection.second, it).relationPathEvidence(existingResources))
            }
        }
    }

internal fun mutationPlanWriteInputs(
    plan: AuthoringMutationPlan,
    existingResources: Map<ResourceId, AuthoringRecord>,
): Set<InputIdentity> =
    buildSet {
        addAll(relationWriteInputs(plan.relations, existingResources))
        plan.removedResources.forEach { resource ->
            add(InputIdentity.Existence(resource))
            add(InputIdentity.Form(ValueLocation(resource, ValuePath())))
        }
    }

private fun ValueLocation.relationPathEvidence(existingResources: Map<ResourceId, AuthoringRecord>): Set<InputIdentity> =
    buildSet {
        addAll(pathEvidence())
        add(InputIdentity.Value(this@relationPathEvidence))
        val item = path.segments.lastOrNull() as? PathSegment.Item
        if (item != null) {
            val parent = copy(path = ValuePath(path.segments.dropLast(1)))
            add(InputIdentity.Form(parent))
            add(InputIdentity.Membership(parent))
            add(InputIdentity.Order(parent))
        }
    }.filterTo(linkedSetOf()) { identity -> identity.existedIn(existingResources) }

private fun InputIdentity.existedIn(resources: Map<ResourceId, AuthoringRecord>): Boolean =
    when (this) {
        is InputIdentity.Value -> resources[at.resource]?.valueAt(at.path) != null

        is InputIdentity.Form -> resources[at.resource]?.valueAt(at.path) != null

        is InputIdentity.Membership -> resources[at.resource]?.valueAt(at.path) != null

        is InputIdentity.Order -> resources[at.resource]?.valueAt(at.path) != null

        is InputIdentity.Existence,
        is InputIdentity.Selection,
        is InputIdentity.Incoming,
        is InputIdentity.Catalog,
        -> true
    }

internal fun mandatoryWriteInputs(
    edit: PreparedEdit,
    latest: Map<ResourceId, AuthoringRecord>,
): Set<InputIdentity> {
    val occurrences = ResourceValueMapper.discover(latest).associateBy { it.id }
    return buildSet {
        edit.intents.forEach { intent ->
            when (intent) {
                is EditIntent.CreateResource -> {
                    add(InputIdentity.Existence(intent.id))
                    add(com.typewritermc.realm.authoring.RESOURCE_SELECTION_INPUT)
                }

                is EditIntent.DeleteResource -> {
                    add(InputIdentity.Existence(intent.id))
                    add(InputIdentity.Form(ValueLocation(intent.id, ValuePath())))
                    add(InputIdentity.Incoming(intent.id, null))
                    add(com.typewritermc.realm.authoring.RESOURCE_SELECTION_INPUT)
                }

                is EditIntent.SetValue -> {
                    addAll(intent.at.pathEvidence())
                    add(InputIdentity.Value(intent.at))
                }

                is EditIntent.Insert -> {
                    addAll(intent.at.pathEvidence())
                    add(InputIdentity.Form(intent.at))
                    add(InputIdentity.Membership(intent.at))
                    add(InputIdentity.Order(intent.at))
                }

                is EditIntent.Remove -> {
                    addAll(intent.at.pathEvidence())
                    add(InputIdentity.Form(intent.at))
                    add(InputIdentity.Membership(intent.at))
                    add(InputIdentity.Order(intent.at))
                    add(InputIdentity.Value(intent.at.item(intent.item)))
                }

                is EditIntent.Move -> {
                    addAll(intent.at.pathEvidence())
                    add(InputIdentity.Form(intent.at))
                    add(InputIdentity.Membership(intent.at))
                    add(InputIdentity.Order(intent.at))
                    add(InputIdentity.Value(intent.at.item(intent.item)))
                }

                is EditIntent.ConnectRelation -> {
                    val source = intent.intent.source
                    addAll(source.id.location.pathEvidence())
                    add(InputIdentity.Value(source.id.location))
                    add(InputIdentity.Existence(intent.intent.target))
                    add(InputIdentity.Form(ValueLocation(intent.intent.target, ValuePath())))
                    add(InputIdentity.Incoming(source.source, null))
                    add(InputIdentity.Incoming(intent.intent.target, null))
                    when (val counterpart = intent.intent.counterpart) {
                        null -> {}

                        is CounterpartChoice.Existing -> {
                            addAll(
                                counterpart.occurrence.id.location
                                    .pathEvidence(),
                            )
                            add(InputIdentity.Value(counterpart.occurrence.id.location))
                        }

                        is CounterpartChoice.New -> {
                            addAll(counterpart.containing.pathEvidence())
                            add(InputIdentity.Form(counterpart.containing))
                            add(InputIdentity.Value(counterpart.containing))
                            add(InputIdentity.Membership(counterpart.containing))
                            add(InputIdentity.Order(counterpart.containing))
                        }
                    }
                }

                is EditIntent.DisconnectRelation -> {
                    addAll(intent.occurrence.location.pathEvidence())
                    add(InputIdentity.Value(intent.occurrence.location))
                    occurrences[intent.occurrence]?.let { occurrence ->
                        add(InputIdentity.Incoming(occurrence.source, null))
                        add(InputIdentity.Incoming(occurrence.target.resource, null))
                    }
                }

                is EditIntent.Retag -> {
                    addAll(intent.at.pathEvidence())
                    add(InputIdentity.Form(intent.at))
                    add(InputIdentity.Incoming(intent.at.resource, null))
                }

                is EditIntent.ConfigureResource -> {
                    val root = ValueLocation(intent.resource, ValuePath())
                    add(InputIdentity.Existence(intent.resource))
                    add(InputIdentity.Form(root))
                    add(InputIdentity.Incoming(intent.resource, null))
                }
            }
        }
    }
}

private fun ValueLocation.pathEvidence(): Set<InputIdentity> =
    buildSet {
        add(InputIdentity.Existence(resource))
        var current = ValueLocation(resource, ValuePath())
        add(InputIdentity.Form(current))
        path.segments.forEach { segment ->
            if (segment is PathSegment.Item) add(InputIdentity.Membership(current))
            current = current.append(segment)
        }
    }

private fun ValueLocation.append(segment: PathSegment): ValueLocation = copy(path = ValuePath(path.segments + segment))

private fun ValueLocation.item(item: com.typewritermc.authoring.ItemId): ValueLocation = append(PathSegment.Item(item))

private fun InputIdentity.location(): ValueLocation =
    when (this) {
        is InputIdentity.Value -> at
        is InputIdentity.Existence -> ValueLocation(resource, ValuePath())
        is InputIdentity.Form -> at
        is InputIdentity.Membership -> at
        is InputIdentity.Order -> at
        is InputIdentity.Selection -> ValueLocation(ResourceId("realm"), ValuePath())
        is InputIdentity.Incoming -> ValueLocation(resource, ValuePath())
        is InputIdentity.Catalog -> ValueLocation(ResourceId("realm"), ValuePath())
    }

private sealed interface AcceptedCommit {
    data class Replayed(
        val result: CommitResult.Committed,
    ) : AcceptedCommit

    data class Fresh(
        val delta: CommitDelta,
    ) : AcceptedCommit
}

private class LogicalRejection(
    val result: CommitResult,
) : RuntimeException(null, null, false, false)

private fun Transaction.replay(
    edit: PreparedEdit,
    digest: String,
): CommitResult.Committed? {
    val value =
        query(
            "SELECT intent_digest, result FROM ONLY \$batch;",
            mapOf("batch" to RecordId("authoring_batch", edit.id.value)),
        ).take(0)
    if (value.isNone || value.isNull) return null
    val stored = value.getObject()
    if (stored.get("intent_digest").getString() != digest) {
        throw LogicalRejection(
            CommitResult.Rejected(
                listOf(ValueProblem(ValueLocation(ResourceId(edit.id.value), ValuePath()), "batch_id_reused")),
            ),
        )
    }
    return authoringStorageJson.decodeFromString<StoredCommitResult>(stored.get("result").getString()).toDomain()
}

private fun Transaction.touchAcceptanceFence(): Long =
    query(
        "UPDATE ONLY authoring_acceptance_fence:current SET revision += 1 RETURN VALUE revision;",
    ).take(0).getLong()

private enum class CatalogActivation {
    AlreadyActive,
    Prepared,
    Recovering,
}

private data class CatalogFenceState(
    val active: CatalogGeneration,
    val pending: CatalogGeneration?,
)

private data class LocalCatalogTransition(
    val database: WeakReference<Surreal>,
    val generation: CatalogGeneration,
)

private val localCatalogTransitions = mutableListOf<LocalCatalogTransition>()

private fun Surreal.markLocalCatalogTransition(generation: CatalogGeneration) =
    synchronized(localCatalogTransitions) {
        localCatalogTransitions.removeAll { it.database.get() == null || it.database.get() === this }
        localCatalogTransitions += LocalCatalogTransition(WeakReference(this), generation)
    }

private fun Surreal.clearLocalCatalogTransition(generation: CatalogGeneration) =
    synchronized(localCatalogTransitions) {
        localCatalogTransitions.removeAll { transition ->
            transition.database.get() == null ||
                (transition.database.get() === this && transition.generation == generation)
        }
    }

private fun Surreal.localCatalogTransition(): CatalogGeneration? =
    synchronized(localCatalogTransitions) {
        localCatalogTransitions.removeAll { it.database.get() == null }
        localCatalogTransitions.firstOrNull { it.database.get() === this }?.generation
    }

private fun catalogTransitionRejection(edit: PreparedEdit): CommitResult.Rejected =
    CommitResult.Rejected(
        listOf(ValueProblem(ValueLocation(ResourceId(edit.id.value), ValuePath()), "catalog_transition")),
    )

private fun Transaction.prepareCatalogActivation(generation: CatalogGeneration): CatalogActivation {
    val state = catalogFenceState()
    if (state.pending == generation) return CatalogActivation.Recovering
    check(state.pending == null) { "Catalog activation ${state.pending?.value} is already in progress." }
    if (state.active == generation) return CatalogActivation.AlreadyActive
    query(
        "UPDATE ONLY authoring_acceptance_fence:current " +
            "SET gate += 1, pending_catalog_generation = \$generation RETURN VALUE gate;",
        mapOf("generation" to generation.value),
    ).take(0).getLong()
    return CatalogActivation.Prepared
}

private fun Transaction.cancelCatalogActivation(generation: CatalogGeneration) {
    val state = catalogFenceState()
    if (state.pending != generation) return
    query(
        "UPDATE ONLY authoring_acceptance_fence:current SET pending_catalog_generation = NONE RETURN VALUE gate;",
    ).take(0).getLong()
}

private fun Transaction.finalizeCatalogActivation(generation: CatalogGeneration): Long {
    val state = catalogFenceState()
    if (state.active == generation && state.pending == null) {
        return query("SELECT VALUE revision FROM ONLY authoring_acceptance_fence:current;").take(0).getLong()
    }
    check(state.pending == generation) { "Catalog activation ${generation.value} is not prepared." }
    val revision =
        query(
            "UPDATE ONLY authoring_acceptance_fence:current " +
                "SET revision += 1, catalog_generation = \$generation, pending_catalog_generation = NONE " +
                "RETURN VALUE revision;",
            mapOf("generation" to generation.value),
        ).take(0).getLong()
    val identity = InputIdentity.Catalog(generation)
    storeInputTokens(mapOf(identity to catalogInputToken(generation)), revision)
    return revision
}

private fun Transaction.initializeCatalogGeneration(generation: CatalogGeneration) {
    val current = catalogGenerationOrNull()
    if (current == null) {
        query(
            "UPDATE ONLY authoring_acceptance_fence:current SET catalog_generation = \$generation RETURN VALUE catalog_generation;",
            mapOf("generation" to generation.value),
        ).take(0).getString()
    }
}

private fun Transaction.catalogGeneration(): CatalogGeneration =
    CatalogGeneration(requireNotNull(catalogGenerationOrNull()) { "The authoring catalog generation is not initialized." })

private fun Transaction.catalogFenceState(): CatalogFenceState {
    val value =
        query(
            "SELECT catalog_generation, pending_catalog_generation FROM ONLY authoring_acceptance_fence:current;",
        ).take(0).getObject()
    val active = CatalogGeneration(value.get("catalog_generation").getString())
    val pendingValue = value.get("pending_catalog_generation")
    val pending = if (pendingValue.isNone || pendingValue.isNull) null else CatalogGeneration(pendingValue.getString())
    return CatalogFenceState(active, pending)
}

private fun Transaction.catalogGenerationOrNull(): String? {
    val value = query("SELECT VALUE catalog_generation FROM ONLY authoring_acceptance_fence:current;").take(0)
    if (value.isNone || value.isNull) return null
    return value.getString().takeIf(String::isNotBlank)
}

private fun Transaction.requireInputs(observations: List<InputObservation>) {
    val conflicts =
        observations.distinctBy(InputObservation::identity).mapNotNull { observation ->
            val stored =
                query(
                    "SELECT VALUE token FROM ONLY \$input;",
                    mapOf("input" to observation.identity.inputRecordId()),
                ).take(0)
            val actual = if (stored.isNone || stored.isNull) absentInputToken() else InputToken(stored.getString())
            InputConflict(observation.identity, observation.token, actual).takeIf { actual != observation.token }
        }
    if (conflicts.isNotEmpty()) throw LogicalRejection(CommitResult.Conflict(conflicts))
}

private data class LoadedResources(
    val records: Map<ResourceId, AuthoringRecord>,
    val definitions: Map<ResourceId, com.typewritermc.authoring.ResourceDefinitionId>,
)

private fun Transaction.loadResources(): LoadedResources {
    val rows = query("SELECT id, definition, content FROM resource ORDER BY id;").take(0).getArray()
    val records = linkedMapOf<ResourceId, AuthoringRecord>()
    val definitions = linkedMapOf<ResourceId, com.typewritermc.authoring.ResourceDefinitionId>()
    rows.forEach { row ->
        val stored = row.getObject()
        val id = stored.get("id").getRecordId()
        require(id.table == "resource" && id.id.isString)
        val resource = ResourceId(id.id.string)
        records[resource] = authoringStorageJson.decodeFromString(AuthoringRecord.serializer(), stored.get("content").getString())
        definitions[resource] = com.typewritermc.authoring.ResourceDefinitionId(stored.get("definition").getString())
    }
    return LoadedResources(records, definitions)
}

private fun Transaction.upsertResources(
    resources: Map<ResourceId, AuthoringRecord>,
    definitions: Map<ResourceId, com.typewritermc.authoring.ResourceDefinitionId>,
    revision: Long,
) {
    resources.forEach { (id, record) ->
        val definition = requireNotNull(definitions[id]) { "Resource ${id.value} is missing its definition identity." }
        query(
            "UPSERT ONLY \$resource CONTENT { definition: \$definition, content: \$content, snapshot: \$snapshot };",
            mapOf(
                "resource" to id.unifiedSurrealId(),
                "definition" to definition.value,
                "content" to authoringStorageJson.encodeToString(AuthoringRecord.serializer(), record),
                "snapshot" to revision,
            ),
        ).take(0)
    }
}

private fun Transaction.removeResources(resources: Set<ResourceId>) {
    resources.forEach { resource ->
        query("DELETE ONLY \$resource;", mapOf("resource" to resource.unifiedSurrealId())).take(0)
    }
}

private fun Transaction.storeInputTokens(
    tokens: Map<InputIdentity, InputToken>,
    revision: Long,
) {
    tokens.forEach { (identity, token) ->
        query(
            "UPSERT ONLY \$input CONTENT { identity: \$identity, token: \$authored_token, snapshot: \$snapshot };",
            mapOf(
                "input" to identity.inputRecordId(),
                "identity" to authoringStorageJson.encodeToString(InputIdentity.serializer(), identity),
                "authored_token" to token.value,
                "snapshot" to revision,
            ),
        ).take(0)
    }
}

private fun Transaction.storeReceipt(
    edit: PreparedEdit,
    digest: String,
    result: CommitResult.Committed,
) {
    query(
        "CREATE ONLY \$batch CONTENT { intent_digest: \$digest, result: \$result, snapshot: \$snapshot };",
        mapOf(
            "batch" to RecordId("authoring_batch", edit.id.value),
            "digest" to digest,
            "result" to authoringStorageJson.encodeToString(StoredCommitResult.from(result)),
            "snapshot" to result.snapshot.value,
        ),
    ).take(0)
}

private fun Transaction.enqueue(
    batch: BatchId,
    sequence: Long,
    delta: CommitDelta,
) {
    query(
        "CREATE ONLY \$event CONTENT { batch: \$batch, snapshot: \$snapshot, sequence: \$sequence, " +
            "payload: \$payload, acknowledged: false };",
        mapOf(
            "event" to RecordId("authoring_event_outbox", batch.value),
            "batch" to batch.value,
            "snapshot" to delta.snapshot.value,
            "sequence" to sequence,
            "payload" to authoringStorageJson.encodeToString(StoredCommitDelta.from(delta)),
        ),
    ).take(0)
}

private fun AuthoringRecord.resourceDefinition(
    definitions: List<AuthoringResourceDefinition>,
    catalog: com.typewritermc.types.catalog.CheckedCatalog,
): AuthoringResourceDefinition {
    val definition = configuration.definition()
    val candidates =
        definitions.filter { resource ->
            if (resource.root == definition) return@filter true
            val complete =
                (configuration as? TypeSelection.Complete)?.use
                    ?: return@filter catalog.isNominalSubtype(definition, resource.root)
            val resolved = catalog.resolve(complete) as? Resolution.Ready ?: return@filter false
            resolved.value.schema.ancestors
                .any { it.definition == resource.root }
        }
    return requireNotNull(candidates.singleOrNull()) {
        "Authored type $definition must belong to exactly one resource definition."
    }
}

private fun TypeSelection.definition(): TypeDefinitionId =
    when (this) {
        is TypeSelection.Complete -> use.definition
        is TypeSelection.Pending -> definition
    }

internal fun InputIdentity.inputRecordId(): RecordId = RecordId("authoring_input", digest())

private fun InputIdentity.digest(): String = authoringStorageJson.encodeToString(InputIdentity.serializer(), this).sha256()

internal fun catalogInputToken(generation: CatalogGeneration): InputToken = InputToken("catalog:${generation.value.sha256()}")

internal fun authoredInputToken(
    revision: Long,
    identity: InputIdentity,
): InputToken = InputToken("$revision:${identity.digest()}")

private fun String.sha256(): String =
    MessageDigest.getInstance("SHA-256").digest(toByteArray()).joinToString("") { byte -> "%02x".format(byte.toInt() and 0xff) }

internal fun canonicalPreparedIntentDigest(edit: PreparedEdit): String =
    with(edit) {
        val observations =
            observations.map { canonical(InputObservation.serializer(), it) }.sorted()
        val intents = intents.map(EditIntent::canonical)
        return frame(
            "prepared_edit",
            canonical(CatalogGeneration.serializer(), catalog),
            canonical(SnapshotId.serializer(), snapshot),
            frame("observations", *observations.toTypedArray()),
            frame("intents", *intents.toTypedArray()),
        ).sha256()
    }

private fun EditIntent.canonical(): String =
    when (this) {
        is EditIntent.CreateResource -> {
            frame("create", canonical(ResourceId.serializer(), id), canonical(AuthoringRecord.serializer(), record))
        }

        is EditIntent.DeleteResource -> {
            frame("delete", canonical(ResourceId.serializer(), id))
        }

        is EditIntent.SetValue -> {
            frame(
                "set",
                canonical(ValueLocation.serializer(), at),
                canonical(
                    com.typewritermc.types.DataValue
                        .serializer(),
                    value,
                ),
            )
        }

        is EditIntent.Insert -> {
            frame(
                "insert",
                canonical(ValueLocation.serializer(), at),
                after.canonicalNullable(),
                canonical(
                    com.typewritermc.types.ListItem
                        .serializer(),
                    item,
                ),
            )
        }

        is EditIntent.Remove -> {
            frame("remove", canonical(ValueLocation.serializer(), at), canonical(ItemId.serializer(), item))
        }

        is EditIntent.Move -> {
            frame(
                "move",
                canonical(ValueLocation.serializer(), at),
                canonical(ItemId.serializer(), item),
                after.canonicalNullable(),
            )
        }

        is EditIntent.ConnectRelation -> {
            val value = intent
            val counterpart =
                when (val choice = value.counterpart) {
                    null -> {
                        frame("none")
                    }

                    is CounterpartChoice.Existing -> {
                        frame(
                            "existing",
                            canonical(
                                com.typewritermc.authoring.LinkOccurrence
                                    .serializer(),
                                choice.occurrence,
                            ),
                        )
                    }

                    is CounterpartChoice.New -> {
                        frame(
                            "new",
                            canonical(ValueLocation.serializer(), choice.containing),
                            canonical(
                                com.typewritermc.authoring.PreparedCreation
                                    .serializer(),
                                choice.prepared,
                            ),
                        )
                    }
                }
            frame(
                "connect",
                canonical(
                    com.typewritermc.authoring.LinkOccurrence
                        .serializer(),
                    value.source,
                ),
                canonical(ResourceId.serializer(), value.target),
                counterpart,
            )
        }

        is EditIntent.DisconnectRelation -> {
            frame(
                "disconnect",
                canonical(
                    com.typewritermc.authoring.LinkOccurrenceId
                        .serializer(),
                    occurrence,
                ),
            )
        }

        is EditIntent.Retag -> {
            frame("retag", canonical(ValueLocation.serializer(), at), canonical(TypeUse.Named.serializer(), type))
        }

        is EditIntent.ConfigureResource -> {
            frame(
                "configure_resource",
                canonical(ResourceId.serializer(), resource),
                canonical(
                    com.typewritermc.authoring.TypeSelection
                        .serializer(),
                    configuration,
                ),
            )
        }
    }

private fun ItemId?.canonicalNullable(): String = if (this == null) frame("none") else frame("item", canonical(ItemId.serializer(), this))

private fun frame(
    kind: String,
    vararg values: String,
): String =
    buildString {
        append(kind.length).append(':').append(kind)
        values.forEach { value -> append(value.length).append(':').append(value) }
    }

private fun <T> canonical(
    serializer: KSerializer<T>,
    value: T,
): String = authoringStorageJson.encodeToJsonElement(serializer, value).canonical().toString()

private fun JsonElement.canonical(): JsonElement =
    when (this) {
        is JsonObject -> JsonObject(entries.sortedBy { it.key }.associate { it.key to it.value.canonical() })
        is JsonArray -> JsonArray(map(JsonElement::canonical))
        is JsonPrimitive -> this
    }

@Serializable
private data class StoredCommitResult(
    val snapshot: String,
    val changed: List<InputIdentity>,
) {
    fun toDomain(): CommitResult.Committed = CommitResult.Committed(SnapshotId(snapshot), changed.toSet())

    companion object {
        fun from(value: CommitResult.Committed): StoredCommitResult =
            StoredCommitResult(value.snapshot.value, value.changed.sortedBy { it.toString() })
    }
}

@Serializable
private data class StoredCommitDelta(
    val previousSnapshot: String,
    val snapshot: String,
    val catalog: CatalogGeneration,
    val resources: Map<ResourceId, AuthoringRecord>,
    val resourceDefinitions: Map<ResourceId, com.typewritermc.authoring.ResourceDefinitionId>,
    val removedResources: Set<ResourceId>,
    val relations: RelationProjectionDelta,
    val inputTokens: Map<InputIdentity, InputToken>,
) {
    fun toDomain(): CommitDelta =
        CommitDelta(
            SnapshotId(previousSnapshot),
            SnapshotId(snapshot),
            catalog,
            resources,
            resourceDefinitions,
            removedResources,
            relations,
            inputTokens,
        )

    companion object {
        fun from(value: CommitDelta): StoredCommitDelta =
            StoredCommitDelta(
                value.previousSnapshot.value,
                value.snapshot.value,
                value.catalog,
                value.resources,
                value.resourceDefinitions,
                value.removedResources,
                value.relations,
                value.inputTokens,
            )
    }
}
