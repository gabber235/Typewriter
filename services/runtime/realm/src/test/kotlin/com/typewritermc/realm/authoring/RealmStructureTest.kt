@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.realm.authoring

import com.surrealdb.Surreal
import com.typewritermc.authoring.AuthoringRecord
import com.typewritermc.authoring.CommitResult
import com.typewritermc.authoring.EditIntent
import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.authoring.PathSegment
import com.typewritermc.authoring.PreparedEdit
import com.typewritermc.authoring.RealmRootDefinition
import com.typewritermc.authoring.RealmRootFields
import com.typewritermc.authoring.RealmSectionDefinition
import com.typewritermc.authoring.ValueLocation
import com.typewritermc.authoring.ValuePath
import com.typewritermc.authoring.boundCollectionPath
import com.typewritermc.authoring.definition
import com.typewritermc.discovery.CatalogContributions
import com.typewritermc.discovery.OwnedTypeDeclaration
import com.typewritermc.library.LibraryDefinition
import com.typewritermc.library.TagDefinition
import com.typewritermc.library.TaxonomyDefinition
import com.typewritermc.library.TaxonomyFields
import com.typewritermc.library.TaxonomyTags
import com.typewritermc.realm.catalog.RealmCatalogIncarnation
import com.typewritermc.realm.catalog.RealmCatalogStore
import com.typewritermc.realm.coreRealmCatalog
import com.typewritermc.realm.record
import com.typewritermc.realm.repository.AuthoringMutationPlanner
import com.typewritermc.realm.repository.MutationPlanningResult
import com.typewritermc.realm.repository.RealmAuthoringOwner
import com.typewritermc.realm.repository.SurrealAuthoringStorage
import com.typewritermc.realm.repository.valueAt
import com.typewritermc.realm.schema.MigrationResources
import com.typewritermc.realm.schema.openTestDatabase
import com.typewritermc.realm.testTag
import com.typewritermc.types.DataValue
import com.typewritermc.types.Ref
import com.typewritermc.types.RepresentationTemplate
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeDefinition
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.TypeId
import com.typewritermc.types.TypeTemplate
import com.typewritermc.types.TypeUse
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.encodeGeneratedDefault
import com.typewritermc.types.unwrapNamed
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContain
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf

val RealmStructureTest by testSuite {
    test("a fresh realm gets its root and one instance of every section in display name order") {
        RealmStructureFixture("fresh_realm").use { fixture ->
            fixture.provision()

            val resources = fixture.resources()
            resources.typesOf(RealmRootDefinition.id).size shouldBe 1
            val library = resources.typesOf(LibraryDefinition.id).single()
            val taxonomy = resources.typesOf(TaxonomyDefinition.id).single()
            resources.sectionsOfRoot() shouldBe listOf(library, taxonomy)
        }
    }

    test("provisioning an already structured realm changes nothing") {
        RealmStructureFixture("idempotent_realm").use { fixture ->
            fixture.provision()
            val before = fixture.views.read { it.observationId to it.resources }

            fixture.provision()

            fixture.views.read { it.observationId to it.resources } shouldBe before
        }
    }

    test("a section type added by a new extension is created on the next start") {
        RealmStructureFixture("added_section").use { fixture ->
            fixture.provision()
            val before = fixture.resources()

            fixture.restart(withExtraSection = true)
            fixture.provision()

            val after = fixture.resources()
            val added = after.typesOf(EXTRA_SECTION).single()
            after.sectionsOfRoot() shouldBe before.sectionsOfRoot() + added
            val root = before.typesOf(RealmRootDefinition.id).single()
            after.keys shouldBe before.keys + added
            after.filterKeys { it != root && it != added } shouldBe before - root
        }
    }

    test("a tag created into the taxonomy commits and survives reload") {
        RealmStructureFixture("owned_tag").use { fixture ->
            fixture.provision()
            val taxonomy = fixture.resources().typesOf(TaxonomyDefinition.id).single()
            val tag = ResourceId("tag")
            val edit =
                fixture.views.capture().use { lease ->
                    val context = WorkingViewEditContext(lease.root, "owned-tag")
                    context.create(tag, fixture.unownedTag())
                    context.insert(
                        boundCollectionPath(ValueLocation(taxonomy, TaxonomyFields.tags.path)),
                        null,
                        fixture.taxonomyLink(tag),
                    )
                    context.finish()
                }

            fixture.owner.commit(edit) shouldBe CommitResult.Committed

            fixture.restart()
            val saved = fixture.resources().getValue(tag)
            (saved.valueAt(ValuePath(listOf(PathSegment.Field("taxonomy"))))?.unwrapNamed() as DataValue.Link).target.resource shouldBe
                taxonomy
        }
    }

    test("a resource without an owner is rejected") {
        RealmStructureFixture("owner_required").use { fixture ->
            fixture.provision()

            val problems = fixture.reject(EditIntent.CreateResource(ResourceId("loose"), fixture.unownedTag()))

            problems shouldContain ("loose" to "owner_required")
        }
    }

    test("unlinking a section from the root leaves it without an owner and is rejected") {
        RealmStructureFixture("section_unlinked").use { fixture ->
            fixture.provision()
            val resources = fixture.resources()
            val root = resources.typesOf(RealmRootDefinition.id).single()
            val library = resources.typesOf(LibraryDefinition.id).single()
            val sections = resources.getValue(root).valueAt(RealmRootFields.sections.path)?.unwrapNamed() as DataValue.ListValue
            val item = sections.items.single { (it.value.unwrapNamed() as DataValue.Link).target.resource == library }.id

            val problems = fixture.reject(EditIntent.Remove(ValueLocation(root, RealmRootFields.sections.path), item))

            problems shouldContain (library.value to "owner_required")
        }
    }

    test("a second root or a second instance of a section type is rejected") {
        RealmStructureFixture("singleton_exists").use { fixture ->
            fixture.provision()
            val resources = fixture.resources()
            val root = resources.getValue(resources.typesOf(RealmRootDefinition.id).single())
            val library = resources.getValue(resources.typesOf(LibraryDefinition.id).single())

            fixture.reject(EditIntent.CreateResource(ResourceId("second_root"), root)) shouldContain ("second_root" to "singleton_exists")
            fixture.reject(EditIntent.CreateResource(ResourceId("second_library"), library)) shouldContain
                ("second_library" to "singleton_exists")
        }
    }

    test("removing the root or a section is rejected") {
        RealmStructureFixture("singleton_required").use { fixture ->
            fixture.provision()
            val resources = fixture.resources()
            val root = resources.typesOf(RealmRootDefinition.id).single()
            val library = resources.typesOf(LibraryDefinition.id).single()

            fixture.reject(EditIntent.DeleteResource(library)) shouldContain (library.value to "singleton_required")
            fixture.reject(EditIntent.DeleteResource(root)) shouldContain (root.value to "singleton_required")
        }
    }
}

private val EXTRA_SECTION = TypeDefinitionId(TypeId.Qualified("structure", "ExtraSection"), 1)

/** A realm on the core catalog backed by a test database, provisioned like Realm start does. */
private class RealmStructureFixture(
    name: String,
) : AutoCloseable {
    private val database = Surreal()
    private val storage: SurrealAuthoringStorage
    lateinit var views: InMemoryAuthoringViewStore
        private set
    lateinit var owner: RealmAuthoringOwner
        private set

    init {
        database.openTestDatabase(name)
        MigrationResources().loadRealmSchema().forEach { database.query(it.script).take(0) }
        storage = SurrealAuthoringStorage(database)
        restart()
    }

    /** Reloads saved authoring under the core catalog, optionally with one more realm section type. */
    fun restart(withExtraSection: Boolean = false) {
        if (::views.isInitialized) views.close()
        // A restart installs its catalog into a new store, as a new Realm activation does.
        val catalogs = RealmCatalogStore().apply { replace(coreCatalog(withExtraSection)) }
        views = InMemoryAuthoringViewStore(catalogs.captureCurrent(), storage.readCoherent())
        owner = RealmAuthoringOwner(storage, views)
    }

    suspend fun provision() = RealmStructureProvisioning(owner).ensure(views)

    fun resources(): Map<ResourceId, AuthoringRecord> = views.read { it.resources }

    /** A Tag whose owner link is not filled in yet. */
    fun unownedTag(): AuthoringRecord =
        views.read { view ->
            val record = view.catalog.record(testTag(name = "Quest"), TagDefinition.id)
            record.copy(fields = record.fields + ("taxonomy" to DataValue.Unfilled))
        }

    /** The taxonomy's link item for [tag], pointing back at the tag's owner field. */
    fun taxonomyLink(tag: ResourceId): DataValue =
        views.read { view ->
            val use = TypeUse.Named(TaxonomyTags.Taxonomy.Definition.id, listOf(TypeUse.Named(TagDefinition.id)))
            val checked = (view.catalog.checked.resolve(use) as Resolution.Ready).value
            view.catalog.nativeBindings
                .bind(checked)
                .encodeGeneratedDefault(Ref<Nothing, Nothing>(tag, ValuePath(listOf(PathSegment.Field("taxonomy")))))
        }

    /** The planner's problems for [intent] on the saved resources, as resource and code pairs. */
    fun reject(intent: EditIntent): List<Pair<String, String>> =
        views.read { view ->
            val planner = AuthoringMutationPlanner(view.catalog.checked, view.catalog.relations, view.catalog.endpointBindings)
            val result = planner.plan(view.resources, PreparedEdit(view.catalog.generation, emptyList(), listOf(intent)))
            result.shouldBeInstanceOf<MutationPlanningResult.Rejected>().problems.map { it.location.resource.value to it.code }
        }

    override fun close() {
        views.close()
        database.close()
    }

    private fun coreCatalog(withExtraSection: Boolean): RealmCatalogIncarnation =
        coreRealmCatalog("realm-structure-$withExtraSection") { core -> if (withExtraSection) listOf(extraSection(core)) else emptyList() }

    private fun extraSection(core: CatalogContributions) =
        OwnedTypeDeclaration(
            core.declarations.first().origin,
            TypeDefinition(
                EXTRA_SECTION,
                representation = RepresentationTemplate.Record(emptyList()),
                parents = listOf(TypeTemplate.Named(RealmSectionDefinition.id)),
            ),
            searchKey = "extrasection",
        )
}

private fun Map<ResourceId, AuthoringRecord>.typesOf(type: TypeDefinitionId): List<ResourceId> =
    filterValues { it.configuration.definition == type }.keys.toList()

private fun Map<ResourceId, AuthoringRecord>.sectionsOfRoot(): List<ResourceId> {
    val root = getValue(typesOf(RealmRootDefinition.id).single())
    val sections = root.valueAt(RealmRootFields.sections.path)?.unwrapNamed() as DataValue.ListValue
    return sections.items.map { (it.value.unwrapNamed() as DataValue.Link).target.resource }
}
