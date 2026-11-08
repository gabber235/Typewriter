package com.typewritermc.realm.edit

import com.surrealdb.Surreal
import com.typewritermc.authoring.SubmissionKey
import com.typewritermc.authoring.of
import com.typewritermc.authoring.text
import com.typewritermc.realm.authoring.AuthoringLease
import com.typewritermc.realm.authoring.AuthoringView
import com.typewritermc.realm.authoring.AuthoringViewDelta
import com.typewritermc.realm.authoring.AuthoringViewStore
import com.typewritermc.realm.authoring.conflicts
import com.typewritermc.realm.authoring.savedState
import com.typewritermc.realm.catalog.AuthoringCatalogLease
import com.typewritermc.realm.formula.CommitRepairs
import com.typewritermc.realm.formula.commitRepairs
import com.typewritermc.realm.search.authoredSearchText
import com.typewritermc.realm.storage.encodeSkir
import com.typewritermc.realm.storage.inTransaction
import com.typewritermc.realm.storage.surrealRecordId
import com.typewritermc.services.libs.telemetry.ErrorSlug
import com.typewritermc.services.libs.telemetry.EventProjection
import com.typewritermc.services.libs.telemetry.LogSeverity
import com.typewritermc.services.libs.telemetry.MainSpanScope
import com.typewritermc.services.libs.telemetry.ServiceTelemetry
import com.typewritermc.services.libs.telemetry.mainSpan
import com.typewritermc.services.libs.telemetry.serviceTelemetry
import com.typewritermc.services.libs.utils.findExceptional
import com.typewritermc.services.libs.utils.sha256Hex
import com.typewritermc.types.unknownVariant
import io.opentelemetry.api.OpenTelemetry
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import skirout.editor.v1.authoring.CommitPreparedEditResponse
import skirout.editor.v1.authoring.PreparedEdit
import skirout.editor.v1.authoring_facts.EditExpectation
import skirout.editor.v1.checking.FindingSet
import skirout.editor.v1.diagnostic.ValueProblem
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.ValueLocation
import kotlin.time.Duration
import kotlin.time.Duration.Companion.seconds

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
    private val findings: () -> List<FindingSet>,
    private val telemetry: ServiceTelemetry = OpenTelemetry.noop().serviceTelemetry("realm.authoring"),
    private val repairs: CommitRepairs = views.commitRepairs(),
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

    override suspend fun commit(
        edit: PreparedEdit,
        submission: SubmissionKey,
    ): CommitPreparedEditResponse =
        admission.withLock {
            // A resent attempt applies nothing; the lookup runs under admission, so concurrent resends apply once.
            val request =
                PreparedEdit.serializer
                    .toBytes(edit)
                    .toByteArray()
                    .sha256Hex()
            when (storage.submittedRequest(submission)) {
                null -> {}

                request -> {
                    return@withLock views.capture().use { CommitPreparedEditResponse.CommittedWrapper(it.root.savedState(findings())) }
                }

                else -> {
                    return@withLock invalidCommit("submission_reused", "Submission $submission was committed with a different edit.")
                }
            }
            // Admission holds only the admission lock, which every writer takes, so the saved view cannot move while
            // names are bound and readers are not blocked. Findings are read once the view lock is released, since the
            // check runtime takes the view lock under its own.
            val admitted = views.capture().use { lease -> admit(lease.root, edit, submission, request) }
            when (admitted) {
                is Admission.Refused -> admitted.response
                is Admission.Installed -> admitted.saved.use { CommitPreparedEditResponse.CommittedWrapper(it.root.savedState(findings())) }
            }
        }

    /**
     * Checks [edit] on [current], binds the names it makes resolve, then persists and installs the result under the
     * view lock, retaining the installed view. The first plan decides whether the edit is accepted, and it stands
     * whatever the binding does.
     */
    private suspend fun admit(
        current: AuthoringView,
        edit: PreparedEdit,
        submission: SubmissionKey,
        request: String,
    ): Admission {
        if (edit.catalog != current.catalog.generation) {
            return Admission.Refused(CommitPreparedEditResponse.CatalogChangedErrorWrapper(current.catalog.generation))
        }
        val values = current.values
        val conflicts = values.conflicts(edit.expectations)
        if (conflicts.isNotEmpty()) return Admission.Refused(CommitPreparedEditResponse.ConflictErrorWrapper(conflicts))
        val planner = AuthoringMutationPlanner(current)
        val plan =
            when (val planned = planner.plan(edit)) {
                is MutationPlanningResult.Rejected -> {
                    return Admission.Refused(CommitPreparedEditResponse.RejectedErrorWrapper(planned.problems))
                }

                is MutationPlanningResult.Accepted -> {
                    planned.plan
                }
            }
        val required =
            values.requiredExpectations(
                edit,
                current.resources,
                current.catalog.relations.mapTo(linkedSetOf()) { it.id },
                plan,
            )
        val given = edit.expectations.mapTo(hashSetOf()) { it.factKey() }
        val missing = required.filter { it.factKey() !in given }
        if (missing.isNotEmpty()) {
            return Admission.Refused(
                CommitPreparedEditResponse.RejectedErrorWrapper(
                    missing.map { ValueProblem(location = it.location(), code = "missing_expectation") },
                ),
            )
        }
        val candidate = views.prepare(AuthoringViewDelta(plan.resources, plan.removedResources))
        val (final, next) = withRepairs(current, candidate, plan, edit, planner, submission)
        try {
            views.read { latest ->
                check(latest === current) { "The view moved under the admission lock." }
                storage.persistAtomic(final, submission, request)
                views.install(next)
            }
        } catch (failure: Throwable) {
            views.invalidate(storage::readCoherent)
            runCatching { next.catalog.close() }.exceptionOrNull()?.let(failure::addSuppressed)
            throw failure
        }
        return Admission.Installed(views.retain(next.readContext))
    }

    /**
     * The plan and view the commit installs: [plan] with the realm owned writes that follow it, or [plan] alone when
     * there are none, they are rejected, or binding fails, so a broken extension never refuses a creator's edit. Hook
     * failures are already values inside the graph. Only cancellation and fatal errors fail the commit, and every path
     * closes the view it does not return.
     */
    private suspend fun withRepairs(
        current: AuthoringView,
        candidate: AuthoringView,
        plan: AuthoringMutationPlan,
        edit: PreparedEdit,
        planner: AuthoringMutationPlanner,
        submission: SubmissionKey,
    ): Pair<AuthoringMutationPlan, AuthoringView> =
        telemetry.mainSpan("realm.commit.bind", BINDING_FAILED) { scope ->
            val changed = plan.resources.keys + plan.removedResources
            try {
                val intents =
                    logWhenSlow(
                        scope,
                        1.seconds,
                        { "Binding names for commit ${submission.value}, editing ${changed.joinToString { it.value }}" },
                    ) {
                        repairs.intents(current, candidate, plan.resources.keys)
                    }
                when (val repaired = if (intents.isEmpty()) null else planner.plan(edit, intents)) {
                    null -> {
                        plan to candidate
                    }

                    is MutationPlanningResult.Accepted -> {
                        val next = views.prepare(AuthoringViewDelta(repaired.plan.resources, repaired.plan.removedResources))
                        candidate.catalog.close()
                        repaired.plan to next
                    }

                    is MutationPlanningResult.Rejected -> {
                        val problems =
                            repaired.problems.joinToString {
                                "${it.location.resource.value} ${it.location.path.text}: ${it.code}"
                            }
                        scope.event(
                            "realm.commit.bind.rejected",
                            EventProjection.log(LogSeverity.WARN, "Repairs rejected for commit ${submission.value}: $problems"),
                        )
                        plan to candidate
                    }

                    else -> {
                        unknownVariant(repaired)
                    }
                }
            } catch (failure: Throwable) {
                if (failure.findExceptional() != null) {
                    candidate.catalog.close()
                    throw failure
                }
                scope.event(
                    "realm.commit.bind.skipped",
                    EventProjection.log(LogSeverity.WARN, "Repairs skipped for commit ${submission.value}."),
                ) {
                    exception(failure)
                }
                plan to candidate
            }
        }

    /** What admission decided under the view lock: a refusal, or the installed view retained for the reply. */
    private sealed interface Admission {
        class Refused(
            val response: CommitPreparedEditResponse,
        ) : Admission

        class Installed(
            val saved: AuthoringLease,
        ) : Admission
    }
}

private val BINDING_FAILED = ErrorSlug.of("realm-commit-binding-failed")

/**
 * Logs [message] on [scope] once [after] has passed while [block] still runs. The warning is a child of the caller's
 * scope, so the commit owns it and it ends with [block]; it runs on [Dispatchers.Default], so a [block] that blocks a
 * single threaded dispatcher still gets its line. The one helper for a call that may hang under a lock.
 */
internal suspend fun <T> logWhenSlow(
    scope: MainSpanScope,
    after: Duration,
    message: () -> String,
    block: () -> T,
): T =
    coroutineScope {
        val warning =
            launch(Dispatchers.Default) {
                delay(after)
                scope.event("realm.slow", EventProjection.log(LogSeverity.WARN, "Still running after $after: ${message()}"))
            }
        try {
            block()
        } finally {
            warning.cancel()
        }
    }

/**
 * Committed submission keys a Realm keeps. A row is a key of at most 128 characters, a 64 character digest and a
 * time, so the bound costs a few hundred kilobytes and covers far more unanswered saves than a realm has editors.
 * It bounds storage only: a resent key that aged out conflicts with its own write through the mandatory guards.
 */
internal const val COMMIT_SUBMISSIONS_KEPT = 1024

/** Writes authored objects, declared links, derived text and the commit's submission in one database transaction. */
internal class SurrealAuthoringStorage(
    private val database: Surreal,
    private val relationStore: DeclaredRelationStore = SurrealDeclaredRelationStore(),
) : AuthoringStorage {
    override fun readCoherent() = SurrealAuthoringSeedLoader(database).load()

    override fun submittedRequest(submission: SubmissionKey): String? =
        database
            .query("SELECT VALUE request FROM ONLY \$submission;", mapOf("submission" to submission.surrealRecordId()))
            .take(0)
            .takeUnless { it.isNone || it.isNull }
            ?.getString()

    override fun persistAtomic(
        plan: AuthoringMutationPlan,
        submission: SubmissionKey,
        request: String,
    ) {
        database.inTransaction { transaction ->
            val relations = relationStore.prepare(plan.relations, transaction)
            plan.resources.forEach { (id, record) ->
                transaction
                    .query(
                        "UPSERT ONLY \$resource SET content = \$content, search = \$search;",
                        mapOf(
                            "resource" to id.surrealRecordId(),
                            "content" to encodeSkir(AuthoringRecord.serializer, record),
                            "search" to mapOf("text" to authoredSearchText(id, record)),
                        ),
                    ).take(0)
            }
            relationStore.apply(relations, transaction)
            plan.removedResources.forEach { id ->
                transaction.query("DELETE ONLY \$resource;", mapOf("resource" to id.surrealRecordId())).take(0)
            }
            transaction
                .query(
                    "CREATE ONLY \$submission SET request = \$request;",
                    mapOf("submission" to submission.surrealRecordId(), "request" to request),
                ).take(0)
            transaction
                .query(
                    "DELETE (SELECT VALUE id FROM commit_submission ORDER BY committed_at DESC START \$kept);",
                    mapOf("kept" to COMMIT_SUBMISSIONS_KEPT),
                ).take(0)
        }
    }
}

/**
 * Locates a required expectation for a missing-guard problem. Required expectations are always
 * resource scoped; the realm-wide resource id set is only observed by reads and never required.
 */
internal fun EditExpectation.location(): ValueLocation =
    when (this) {
        is EditExpectation.ValueWrapper -> value.at
        is EditExpectation.ConfigurationWrapper -> value.at
        is EditExpectation.ResourceWrapper -> ValueLocation.of(value.id)
        is EditExpectation.ResourceExistsWrapper -> ValueLocation.of(value.id)
        is EditExpectation.LinksWrapper -> ValueLocation.of(value.resource)
        is EditExpectation.TypesWrapper -> ValueLocation.of(value.resource)
        is EditExpectation.ResourceIdsWrapper -> error("Resource id set expectations are never required for commit admission.")
        is EditExpectation.ScopeWrapper -> error("Scope expectations are never required for commit admission.")
        else -> unknownVariant(this)
    }
