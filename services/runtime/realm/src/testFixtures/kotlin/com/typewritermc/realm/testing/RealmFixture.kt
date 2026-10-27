package com.typewritermc.realm.testing

import com.surrealdb.Surreal
import com.typewritermc.authoring.EditContext
import com.typewritermc.operations.OperationInvocation
import com.typewritermc.operations.OperationOrigin
import com.typewritermc.operations.PreparationChoices
import com.typewritermc.realm.authoring.AuthoringLease
import com.typewritermc.realm.authoring.AuthoringSeed
import com.typewritermc.realm.authoring.InMemoryAuthoringViewStore
import com.typewritermc.realm.edit.AuthoringMutationPlanner
import com.typewritermc.realm.edit.AuthoringPlanRejected
import com.typewritermc.realm.edit.AuthoringStorage
import com.typewritermc.realm.edit.MemoryAuthoringStorage
import com.typewritermc.realm.edit.MutationPlanningResult
import com.typewritermc.realm.edit.RealmAuthoringOwner
import com.typewritermc.realm.edit.RealmStructureProvisioning
import com.typewritermc.realm.edit.SurrealAuthoringStorage
import com.typewritermc.realm.edit.WorkingViewEditContext
import com.typewritermc.realm.edit.requiredExpectations
import com.typewritermc.realm.operation.RuntimeOperationPreparation
import com.typewritermc.realm.search.SurrealAuthoringSearchRepository
import com.typewritermc.realm.storage.MigrationResources
import com.typewritermc.realm.storage.openTestDatabase
import com.typewritermc.setup.Setup
import com.typewritermc.testkit.CatalogEncoder
import com.typewritermc.testkit.setup.SetupApplier
import com.typewritermc.types.toResourceIds
import skirout.editor.v1.authoring.CommitPreparedEditResponse
import skirout.editor.v1.authoring.EditIntent
import skirout.editor.v1.authoring.PreparedEdit
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.NamedTypeUse
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.kernel.v1.resource_id.ResourceId

/** Where a [RealmFixture] saves authoring: in memory, or in an embedded SurrealDB with the Realm schema. */
enum class RealmStorage { Memory, Surreal }

/** An embedded SurrealDB named [name], with the Realm schema loaded. */
internal fun realmDatabase(name: String = "realm"): Surreal =
    Surreal().apply {
        openTestDatabase(name)
        MigrationResources().loadRealmSchema().forEach { query(it.script).take(0) }
    }

/**
 * The operation preparation over [subjects] that writes into this edit, as an operation's prepare callback receives it.
 * [origin] is the operation's origin when it has one, and [name] labels the invocation.
 */
internal fun WorkingViewEditContext.operationPreparation(
    subjects: List<ResourceId>,
    origin: OperationOrigin? = null,
    name: String = "operation",
): RuntimeOperationPreparation {
    val targets = subjects.toResourceIds()
    val invocation = origin?.let { OperationInvocation(name, targets, it) } ?: OperationInvocation(name, targets)
    return RuntimeOperationPreparation(invocation, PreparationChoices(), this)
}

/**
 * A started Realm without the network: the catalog it activates, the root and sections Realm start provisions, and
 * the commit path an author's edits go through. Content of real types comes from setups, committed the way an author
 * commits; content only a [DefinitionCatalog] declares is committed with [commit] or seeded by hand.
 */
class RealmFixture private constructor(
    private val database: Surreal?,
    private var catalog: FixtureCatalog,
    private val storage: AuthoringStorage,
) : AutoCloseable {
    private val authors = mutableListOf<RealmAuthor>()
    private var activation: AutoCloseable? = null
    private var generations = 0
    private var edits = 0

    lateinit var views: InMemoryAuthoringViewStore
        private set
    internal lateinit var owner: RealmAuthoringOwner
        private set

    /** Saved resources by id, as the Realm reads them now. */
    val resources: Map<ResourceId, AuthoringRecord> get() = views.read { it.resources }

    /** The generation of the catalog the Realm runs now, which every prepared edit names. */
    val generation: CatalogGeneration get() = views.read { it.catalog.generation }

    /** The single saved resource of [type], such as the root or a section the Realm provisioned. */
    fun singleOf(type: TypeDefinitionId): ResourceId = resources.typesOf(type).single()

    /** Encodes native values with the current catalog. */
    val encoder: CatalogEncoder get() = views.read { CatalogEncoder(it.catalog.checked, it.catalog.nativeBindings) }

    /**
     * Starts the Realm again on saved authoring, as a new activation does: the catalog is activated anew, from
     * [catalog] when given, and missing sections are provisioned.
     */
    suspend fun restart(catalog: FixtureCatalog = this.catalog) {
        this.catalog = catalog
        closeViews()
        val active = catalog.activate("realm-${++generations}")
        activation = active.owner
        views = InMemoryAuthoringViewStore(active.lease, storage.readCoherent())
        owner = RealmAuthoringOwner(storage, views)
        provision()
    }

    /** Ensures the root and one instance of every section type, as Realm start does; a catalog without a root has none. */
    suspend fun provision() = RealmStructureProvisioning(owner).ensure(views)

    /**
     * Commits [setup] as one author edit and returns its handles; a refused setup throws its problems. Several setups
     * compose with `+` into one, whose handles pair theirs and whose shared parts are created once.
     */
    suspend fun <H> withSetup(setup: Setup<H>): H {
        SetupApplier(FixtureSetupEditor(this)).apply(setup)
        return setup.handles
    }

    /** Commits [edit] through the Realm's admission, as the commit route does. */
    suspend fun commit(edit: PreparedEdit): CommitPreparedEditResponse = owner.commit(edit)

    /**
     * Commits [intents] as an editor sends them: one edit on the current state, guarded by exactly the expectations
     * admission requires for it. An edit the planner refuses goes out unguarded, so admission reports its problems.
     */
    suspend fun commit(vararg intents: EditIntent): CommitPreparedEditResponse = commit(prepare(intents.toList()))

    /**
     * Commits what [block] writes through the Realm's edit context, as an operation does. A write the context refuses
     * while it is made comes back as the same rejection admission gives.
     */
    internal suspend fun commit(block: suspend WorkingViewEditContext.() -> Unit): CommitPreparedEditResponse {
        val edit =
            try {
                views.capture().use { lease ->
                    WorkingViewEditContext(lease.root, "edit:${++edits}").run {
                        block()
                        finish()
                    }
                }
            } catch (refused: AuthoringPlanRejected) {
                return CommitPreparedEditResponse.RejectedErrorWrapper(refused.problems)
            }
        return commit(edit)
    }

    /**
     * Runs one operation over [subjects] inside a commit, as an operation's prepare callback does, and commits what it
     * writes. [origin] is the operation's origin when it has one.
     */
    internal suspend fun operate(
        subjects: List<ResourceId>,
        origin: OperationOrigin? = null,
        block: suspend RuntimeOperationPreparation.() -> Unit,
    ): CommitPreparedEditResponse = commit { operationPreparation(subjects, origin).block() }

    /** [intents] as one prepared edit on the current state, with the expectations admission requires. */
    fun prepare(intents: List<EditIntent>): PreparedEdit =
        views.read { view ->
            val edit = PreparedEdit(catalog = view.catalog.generation, expectations = emptyList(), intents = intents)
            when (val planned = AuthoringMutationPlanner(view.catalog.checked, view.catalog.relations).plan(view.resources, edit)) {
                is MutationPlanningResult.Rejected -> {
                    edit
                }

                is MutationPlanningResult.Accepted -> {
                    val relations = view.catalog.relations.mapTo(linkedSetOf()) { it.id }
                    edit.copy(expectations = view.values.requiredExpectations(edit, view.resources, relations, planned.plan))
                }
            }
        }

    /**
     * The resources a search finds in saved authoring, as the search route runs it under the current view. Only a
     * fixture that saves into SurrealDB has the search index.
     */
    internal fun search(
        query: String = "",
        contexts: Set<ResourceId> = emptySet(),
        roots: Set<TypeDefinitionId> = emptySet(),
        target: NamedTypeUse? = null,
        limit: Int = 10,
    ): List<ResourceId> {
        val repository = SurrealAuthoringSearchRepository(checkNotNull(database) { "Search needs a Realm that saves into SurrealDB." })
        return views.read { view -> repository.search(view, query, contexts, roots, target, limit).map { it.resource } }
    }

    /**
     * A second author who loaded the saved state now. Edits they prepare later still start from that state, as an
     * open editor's do, so a change another author committed in between surfaces as a conflict.
     */
    fun asUser(name: String): RealmAuthor = RealmAuthor(name, views.capture()).also(authors::add)

    override fun close() {
        closeViews()
        database?.close()
    }

    private fun closeViews() {
        authors.forEach(RealmAuthor::close)
        authors.clear()
        if (::views.isInitialized) views.close()
        activation?.close()
        activation = null
    }

    /** One author's editor: it prepares edits from the saved state it loaded and commits them as that author. */
    inner class RealmAuthor internal constructor(
        val name: String,
        private val lease: AuthoringLease,
    ) : AutoCloseable {
        private var edits = 0

        /** The prepared edit [block] writes, with the expectations admission checks against the loaded state. */
        suspend fun edit(block: suspend EditContext.() -> Unit): PreparedEdit =
            WorkingViewEditContext(lease.root, "$name:${++edits}").run {
                block()
                finish()
            }

        suspend fun commit(block: suspend EditContext.() -> Unit): CommitPreparedEditResponse = this@RealmFixture.commit(edit(block))

        override fun close() = lease.close()
    }

    companion object {
        /** A provisioned Realm on [catalog], saving into [storage]. */
        suspend fun core(
            storage: RealmStorage = RealmStorage.Memory,
            catalog: RealmCatalog = RealmCatalog(),
        ): RealmFixture {
            val database =
                when (storage) {
                    RealmStorage.Memory -> null
                    RealmStorage.Surreal -> realmDatabase()
                }
            return start(RealmFixture(database, catalog, database?.let(::SurrealAuthoringStorage) ?: MemoryAuthoringStorage()))
        }

        /**
         * A Realm on [catalog] that starts with [seed] already saved, for rules only types no extension declares
         * reach, or content no author could commit. [storage] holds the seed and can fail on purpose.
         */
        internal suspend fun of(
            catalog: DefinitionCatalog,
            seed: Map<ResourceId, AuthoringRecord> = emptyMap(),
            storage: MemoryAuthoringStorage = MemoryAuthoringStorage(AuthoringSeed(seed)),
        ): RealmFixture = start(RealmFixture(null, catalog, storage))

        /** A Realm on [catalog] whose authoring is saved in an embedded SurrealDB with the Realm schema. */
        suspend fun surreal(catalog: DefinitionCatalog): RealmFixture {
            val database = realmDatabase()
            return start(RealmFixture(database, catalog, SurrealAuthoringStorage(database)))
        }

        private suspend fun start(fixture: RealmFixture): RealmFixture =
            fixture.also {
                try {
                    it.restart()
                } catch (failure: Throwable) {
                    it.close()
                    throw failure
                }
            }
    }
}
