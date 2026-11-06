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
    val entry = AuthorResourceId("entry-${UUID.randomUUID()}")
    val pageField = ValuePath.root.field("page")
    val record =
        encoder
            .record(FixtureStaticEntryDefinition.id.use(), FixtureStaticEntry(Ref(AuthorResourceId(page.value)), GraphPlacement(), name))
            .with("page", DataValue.UNFILLED)
    val item =
        encoder.encode(
            PageElements.Page.Definition.id
                .namedUse(listOf(StaticEntryDefinition.id.use()))
                .use,
            Ref<Nothing, Nothing>(entry, pageField),
        )
    val edit =
        views.capture().use { lease ->
            WorkingViewEditContext(lease.root, "create-entry:$name").run {
                create(entry, record)
                insert(boundCollectionPath(ValueLocation.of(page, ValuePath.root.field("elements"))), null, item)
                finish()
            }
        }
    return EntryCreation(ResourceId(value = entry.value), edit)
}

/** Commits [creation] through the Realm's admission. */
suspend fun RealmFixture.commit(creation: EntryCreation): CommitPreparedEditResponse = commit(creation.edit)
