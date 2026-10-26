package com.typewritermc.realm.testing

import com.surrealdb.Surreal
import com.typewritermc.authoring.EditContext
import com.typewritermc.authoring.definition
import com.typewritermc.realm.authoring.AuthoringLease
import com.typewritermc.realm.authoring.InMemoryAuthoringViewStore
import com.typewritermc.realm.catalog.RealmCatalogStore
import com.typewritermc.realm.edit.AuthoringStorage
import com.typewritermc.realm.edit.MemoryAuthoringStorage
import com.typewritermc.realm.edit.RealmAuthoringOwner
import com.typewritermc.realm.edit.RealmStructureProvisioning
import com.typewritermc.realm.edit.SurrealAuthoringStorage
import com.typewritermc.realm.edit.WorkingViewEditContext
import com.typewritermc.realm.storage.MigrationResources
import com.typewritermc.realm.storage.openTestDatabase
import com.typewritermc.setup.Setup
import com.typewritermc.testkit.CatalogEncoder
import com.typewritermc.testkit.setup.SetupApplier
import skirout.editor.v1.authoring.CommitPreparedEditResponse
import skirout.editor.v1.authoring.PreparedEdit
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.kernel.v1.resource_id.ResourceId

/** Where a [RealmFixture] saves authoring: in memory, or in an embedded SurrealDB with the Realm schema. */
enum class RealmStorage { Memory, Surreal }

/**
 * A started Realm without the network: the catalog discovery assembles, the root and sections Realm start provisions,
 * and the commit path an author's edits go through. Content comes from setups, committed the way an author commits.
 */
class RealmFixture private constructor(
    private val database: Surreal?,
    private var catalog: RealmCatalog,
) : AutoCloseable {
    private val storage: AuthoringStorage =
        database?.let(::SurrealAuthoringStorage) ?: MemoryAuthoringStorage()
    private val authors = mutableListOf<RealmAuthor>()
    private var catalogs: RealmCatalogStore? = null
    private var generation = 0

    lateinit var views: InMemoryAuthoringViewStore
        private set
    internal lateinit var owner: RealmAuthoringOwner
        private set

    /** Saved resources by id, as the Realm reads them now. */
    val resources: Map<ResourceId, AuthoringRecord> get() = views.read { it.resources }

    /** The single saved resource of [type], such as the root or a section the Realm provisioned. */
    fun singleOf(type: TypeDefinitionId): ResourceId = resources.filterValues { it.configuration.definition == type }.keys.single()

    /** Encodes native values with the current catalog. */
    val encoder: CatalogEncoder get() = views.read { CatalogEncoder(it.catalog.checked, it.catalog.nativeBindings) }

    /**
     * Starts the Realm again on saved authoring, as a new activation does: the catalog is assembled anew, from
     * [catalog] when given, and missing sections are provisioned.
     */
    suspend fun restart(catalog: RealmCatalog = this.catalog) {
        this.catalog = catalog
        closeViews()
        val store = RealmCatalogStore().apply { replace(catalog.incarnation("realm-${++generation}")) }
        catalogs = store
        views = InMemoryAuthoringViewStore(store.captureCurrent(), storage.readCoherent())
        owner = RealmAuthoringOwner(storage, views)
        provision()
    }

    /** Ensures the root and one instance of every section type, as Realm start does. */
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
        catalogs?.close()
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
                    RealmStorage.Memory -> {
                        null
                    }

                    RealmStorage.Surreal -> {
                        Surreal().apply {
                            openTestDatabase("realm")
                            MigrationResources().loadRealmSchema().forEach { query(it.script).take(0) }
                        }
                    }
                }
            return RealmFixture(database, catalog).also { fixture ->
                try {
                    fixture.restart()
                } catch (failure: Throwable) {
                    fixture.close()
                    throw failure
                }
            }
        }
    }
}
