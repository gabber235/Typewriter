@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.realm.testing

import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.authoring.GraphPlacement
import com.typewritermc.authoring.boundCollectionPath
import com.typewritermc.authoring.field
import com.typewritermc.authoring.of
import com.typewritermc.authoring.root
import com.typewritermc.authoring.with
import com.typewritermc.engine.pages.StaticEntryDefinition
import com.typewritermc.engine.pages.StaticPage
import com.typewritermc.engine.pages.StaticPageDefinition
import com.typewritermc.engine.pages.staticPage
import com.typewritermc.library.PageElements
import com.typewritermc.library.book
import com.typewritermc.library.library
import com.typewritermc.realm.edit.WorkingViewEditContext
import com.typewritermc.setup.Setup
import com.typewritermc.setup.SetupHandle
import com.typewritermc.setup.setup
import com.typewritermc.testing.routes.FixtureStaticEntry
import com.typewritermc.testing.routes.FixtureStaticEntryDefinition
import com.typewritermc.types.Ref
import com.typewritermc.types.namedUse
import com.typewritermc.types.use
import skirout.editor.v1.authoring.CommitPreparedEditResponse
import skirout.editor.v1.authoring.PreparedEdit
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.type_catalog.ValuePath
import skirout.kernel.v1.resource_id.ResourceId
import java.util.UUID
import com.typewritermc.types.ResourceId as AuthorResourceId

/** One book holding one empty core static page. */
val staticPage: Setup<SetupHandle<StaticPage>> =
    setup("static-page") { library { books.book("static") { pages.staticPage("start") { handle } } } }

/** A prepared edit that creates the entry [id]. */
class EntryCreation(
    val id: ResourceId,
    val edit: PreparedEdit,
)

/**
 * An edit creating a FixtureStaticEntry named [name] on the realm's single static page, the way an author adds one: the
 * entry is created with its page link unfilled, then listed in the page's elements, which writes both sides.
 */
suspend fun RealmFixture.createEntry(name: String): EntryCreation {
    val page = resources.typesOf(StaticPageDefinition.id).single()
    val record =
        encoder.record(FixtureStaticEntryDefinition.id.use(), FixtureStaticEntry(Ref(AuthorResourceId(page.value)), GraphPlacement(), name))
    return createElement("create-entry:$name") { record }
}

/**
 * An edit creating the record [record] builds for its new id as a new element of the realm's single static page, the
 * way an author adds one: the element is created with its page link unfilled, then listed in the page's elements, which
 * writes both sides.
 */
internal suspend fun RealmFixture.createElement(
    name: String,
    record: (ResourceId) -> AuthoringRecord,
): EntryCreation {
    val (id, writes) = elementWrites(record)
    val edit =
        views.capture().use { lease ->
            WorkingViewEditContext(lease.root, name).run {
                writes()
                finish()
            }
        }
    return EntryCreation(id, edit)
}

/** Commits the element [createElement] would create, and its id; a write refused while it is made is the reply. */
internal suspend fun RealmFixture.commitElement(record: (ResourceId) -> AuthoringRecord): Pair<ResourceId, CommitPreparedEditResponse> {
    val (id, writes) = elementWrites(record)
    return id to commit { writes() }
}

/** The id of the element [record] builds on the static page, and the writes that create it and place it there. */
internal fun RealmFixture.elementWrites(
    record: (ResourceId) -> AuthoringRecord,
): Pair<ResourceId, suspend WorkingViewEditContext.() -> Unit> {
    val page = resources.typesOf(StaticPageDefinition.id).single()
    val entry = AuthorResourceId("entry-${UUID.randomUUID()}")
    val created = record(ResourceId(value = entry.value))
    val pageField = ValuePath.root.field("page")
    val item =
        encoder.encode(
            PageElements.Page.Definition.id
                .namedUse(listOf(StaticEntryDefinition.id.use()))
                .use,
            Ref<Nothing, Nothing>(entry, pageField),
        )
    return ResourceId(value = entry.value) to {
        create(entry, created.with("page", DataValue.UNFILLED))
        insert(boundCollectionPath(ValueLocation.of(page, ValuePath.root.field("elements"))), null, item)
    }
}

/** Commits [creation] through the Realm's admission. */
suspend fun RealmFixture.commit(creation: EntryCreation): CommitPreparedEditResponse = commit(creation.edit)
