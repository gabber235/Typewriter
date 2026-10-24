package com.typewritermc.realm.repository

import com.surrealdb.Surreal
import com.typewritermc.authoring.AuthoringRecord
import com.typewritermc.authoring.CommitResult
import com.typewritermc.authoring.EditExpectation
import com.typewritermc.authoring.PreparedEdit
import com.typewritermc.authoring.ValueLocation
import com.typewritermc.authoring.ValuePath
import com.typewritermc.authoring.ValueProblem
import com.typewritermc.realm.authoring.AuthoringCatalogLease
import com.typewritermc.realm.authoring.AuthoringViewDelta
import com.typewritermc.realm.authoring.AuthoringViewStore
import com.typewritermc.realm.authoring.authoredDatabaseValues
import com.typewritermc.realm.repository.utils.inTransaction
import com.typewritermc.realm.repository.utils.surrealRecordId
import com.typewritermc.realm.search.authoredSearchText
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock

/**
 * Owns admission of prepared edits into the saved authoring state for one Realm.
 *
 * Admission serializes catalog checks, expected fact comparison, intent replay, mandatory guard validation,
 * storage persistence, and replacement view installation. Missing guards are rejected even when the supplied
 * expectations match. Storage failure invalidates the view for a coherent reload before further reads.
 * A committed edit updates saved authoring only; checking and publication have separate owners.
 */
internal class RealmAuthoringOwner(
    private val storage: AuthoringStorage,
    private val views: AuthoringViewStore,
) : AuthoringRepository {
    private val admission = Mutex()

    suspend fun activateCatalog(
        next: AuthoringCatalogLease,
        install: () -> Unit,
        publish: () -> Unit,
    ) = admission.withLock {
        views.read { current ->
            if (current.catalog.generation != next.generation) {
                val replacement = views.prepare(AuthoringViewDelta(catalog = next))
                try {
                    install()
                } catch (failure: Throwable) {
                    replacement.catalog.close()
                    throw failure
                }
                views.install(replacement)
                publish()
            }
        }
    }

    override suspend fun commit(edit: PreparedEdit): CommitResult =
        admission.withLock {
            views.read { current ->
                if (edit.catalog != current.catalog.generation) return@read CommitResult.CatalogChanged(current.catalog.generation)
                val projections =
                    ResourceValueMapper.project(
                        current.links.values,
                        current.resources,
                        current.catalog.relations,
                        current.catalog.checked,
                    )
                val values = CapturedAuthoringValues(current.resources, projections.projections)
                val conflicts = values.conflicts(edit.expectations)
                if (conflicts.isNotEmpty()) return@read CommitResult.Conflict(conflicts)
                val planner = AuthoringMutationPlanner(current.catalog.checked, current.catalog.relations, current.catalog.endpointBindings)
                val plan =
                    when (val planned = planner.plan(current.resources, edit)) {
                        is MutationPlanningResult.Rejected -> return@read CommitResult.Rejected(planned.problems)
                        is MutationPlanningResult.Accepted -> planned.plan
                    }
                val required =
                    values.requiredExpectations(
                        edit,
                        current.resources,
                        current.catalog.relations.mapTo(linkedSetOf()) { it.id },
                        plan,
                    )
                val missing = required.filter { fact -> edit.expectations.none { it.sameFact(fact) } }
                if (missing.isNotEmpty()) {
                    return@read CommitResult.Rejected(
                        missing.map { ValueProblem(it.location(), "missing_expectation") },
                    )
                }
                val next = views.prepare(AuthoringViewDelta(plan.resources, plan.removedResources))
                try {
                    storage.persistAtomic(plan)
                } catch (failure: Throwable) {
                    views.invalidate(storage::readCoherent)
                    runCatching { next.catalog.close() }.exceptionOrNull()?.let(failure::addSuppressed)
                    throw failure
                }
                views.install(next)
                CommitResult.Committed
            }
        }
}

/** Writes authored objects, declared links, and derived text in one database transaction. */
internal class SurrealAuthoringStorage(
    private val database: Surreal,
    private val relationStore: DeclaredRelationStore = SurrealDeclaredRelationStore(),
) : AuthoringStorage {
    override fun readCoherent() = SurrealAuthoringSeedLoader(database).load()

    override fun persistAtomic(plan: AuthoringMutationPlan) {
        database.inTransaction { transaction ->
            val relations = relationStore.prepare(plan.relations, transaction)
            plan.resources.forEach { (id, record) ->
                transaction
                    .query(
                        "UPSERT ONLY \$resource SET content = \$content, search = \$search;",
                        mapOf(
                            "resource" to id.surrealRecordId(),
                            "content" to authoredDatabaseValues.encode(AuthoringRecord.serializer(), record),
                            "search" to mapOf("text" to authoredSearchText(id, record)),
                        ),
                    ).take(0)
            }
            relationStore.apply(relations, transaction)
            plan.removedResources.forEach { id ->
                transaction.query("DELETE ONLY \$resource;", mapOf("resource" to id.surrealRecordId())).take(0)
            }
        }
    }
}

/**
 * Locates a required expectation for a missing-guard problem. Required expectations are always
 * resource scoped; the realm-wide resource id set is only observed by reads and never required.
 */
internal fun EditExpectation.location(): ValueLocation =
    when (this) {
        is EditExpectation.Value -> at
        is EditExpectation.Configuration -> at
        is EditExpectation.Resource -> ValueLocation(id, ValuePath())
        is EditExpectation.ResourceExists -> ValueLocation(id, ValuePath())
        is EditExpectation.Links -> ValueLocation(resource, ValuePath())
        is EditExpectation.ResourceIds -> error("Resource id set expectations are never required for commit admission.")
    }
