package com.typewritermc.realm.repository

import com.surrealdb.Surreal
import com.typewritermc.authoring.AuthoringRecord
import com.typewritermc.authoring.AuthoringResourceDefinition
import com.typewritermc.authoring.CommitResult
import com.typewritermc.authoring.EditExpectation
import com.typewritermc.authoring.PathSegment
import com.typewritermc.authoring.PreparedEdit
import com.typewritermc.authoring.ResourceDefinitionId
import com.typewritermc.authoring.TypeSelection
import com.typewritermc.authoring.ValueLocation
import com.typewritermc.authoring.ValuePath
import com.typewritermc.authoring.ValueProblem
import com.typewritermc.realm.authoring.AuthoringCatalogLease
import com.typewritermc.realm.authoring.AuthoringViewDelta
import com.typewritermc.realm.authoring.AuthoringViewStore
import com.typewritermc.realm.authoring.authoredDatabaseValues
import com.typewritermc.realm.repository.utils.inTransaction
import com.typewritermc.realm.repository.utils.unifiedSurrealId
import com.typewritermc.realm.search.authoredSearchText
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.catalog.Resolution
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock

/** Owns validation, persistence, catalog installation, and coherent current reads for one Realm. */
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
                val planned = planner.plan(current.resources, edit)
                if (planned is MutationPlanningResult.Rejected) return@read CommitResult.Rejected(planned.problems)
                val raw = (planned as MutationPlanningResult.Accepted).plan
                val required =
                    values.requiredExpectations(
                        edit,
                        current.resources,
                        current.catalog.relations.mapTo(linkedSetOf()) { it.id },
                        raw,
                    )
                val missing = required.filter { fact -> edit.expectations.none { it.sameFact(fact) } }
                if (missing.isNotEmpty()) {
                    return@read CommitResult.Rejected(
                        missing.map { ValueProblem(it.location(), "missing_expectation") },
                    )
                }
                val plan =
                    raw.copy(
                        definitions =
                            raw.resources.mapValues { (_, record) ->
                                record.resourceDefinition(current.catalog.resources, current.catalog.checked).id
                            },
                    )
                val next = views.prepare(AuthoringViewDelta(plan.resources, plan.removedResources, resourceDefinitions = plan.definitions))
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
                val definition = plan.definitions.getValue(id)
                transaction
                    .query(
                        "UPSERT ONLY \$resource SET definition = \$definition, content = \$content, search = \$search;",
                        mapOf(
                            "resource" to id.unifiedSurrealId(),
                            "definition" to definition.value,
                            "content" to authoredDatabaseValues.encode(AuthoringRecord.serializer(), record),
                            "search" to mapOf("text" to authoredSearchText(id, definition, record)),
                        ),
                    ).take(0)
            }
            relationStore.apply(relations, transaction)
            plan.removedResources.forEach { id ->
                transaction.query("DELETE ONLY \$resource;", mapOf("resource" to id.unifiedSurrealId())).take(0)
            }
        }
    }
}

internal fun EditExpectation.location(): ValueLocation =
    when (this) {
        is EditExpectation.Value -> at
        is EditExpectation.Configuration -> at
        is EditExpectation.Resource -> ValueLocation(id, ValuePath())
        is EditExpectation.ResourceExists -> ValueLocation(id, ValuePath())
        is EditExpectation.Links -> ValueLocation(resource, ValuePath())
        is EditExpectation.ResourceIds -> ValueLocation(ResourceId("realm"), ValuePath())
    }

private fun AuthoringRecord.resourceDefinition(
    definitions: List<AuthoringResourceDefinition>,
    catalog: CheckedCatalog,
): AuthoringResourceDefinition {
    val definition =
        when (val selected = configuration) {
            is TypeSelection.Complete -> selected.use.definition
            is TypeSelection.Pending -> selected.definition
        }
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
    return requireNotNull(candidates.singleOrNull()) { "Authored type $definition must belong to exactly one resource definition." }
}
