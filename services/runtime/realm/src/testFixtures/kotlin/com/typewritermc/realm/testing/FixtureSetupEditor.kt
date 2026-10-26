package com.typewritermc.realm.testing

import com.typewritermc.authoring.EditContext
import com.typewritermc.authoring.definition
import com.typewritermc.realm.authoring.AuthoringView
import com.typewritermc.realm.edit.AuthoringPlanRejected
import com.typewritermc.realm.edit.WorkingViewEditContext
import com.typewritermc.setup.Setup
import com.typewritermc.testkit.setup.EditRefused
import com.typewritermc.testkit.setup.SetupEdit
import com.typewritermc.testkit.setup.SetupEditor
import com.typewritermc.types.ResourceId
import com.typewritermc.types.toResourceId
import skirout.editor.v1.authoring.CommitPreparedEditResponse
import skirout.editor.v1.authoring.PreparedEdit
import skirout.editor.v1.type_catalog.TypeDefinitionId

/**
 * Runs [test] on a fresh provisioned Realm that holds [setup], committed the way an author commits, and passes it the
 * setup's handles.
 */
suspend fun <H> withSetup(
    setup: Setup<H>,
    storage: RealmStorage = RealmStorage.Memory,
    catalog: RealmCatalog = RealmCatalog(),
    test: suspend RealmFixture.(H) -> Unit,
) {
    RealmFixture.core(storage, catalog).use { realm -> realm.test(realm.withSetup(setup)) }
}

/** Edits through the Realm's own edit context and commits through its admission. */
internal class FixtureSetupEditor(
    private val realm: RealmFixture,
) : SetupEditor {
    override suspend fun <T> edit(
        name: String,
        block: suspend SetupEdit.() -> T,
    ): T =
        realm.views.capture().use { lease ->
            try {
                WorkingViewSetupEdit(WorkingViewEditContext(lease.root, name), lease.root).block()
            } catch (rejected: AuthoringPlanRejected) {
                throw EditRefused(rejected.problems)
            }
        }

    override suspend fun commit(edit: PreparedEdit): CommitPreparedEditResponse = realm.commit(edit)
}

/** The setup's view of an edit: the Realm's edit context plus its catalog and section ids. */
private class WorkingViewSetupEdit(
    private val context: WorkingViewEditContext,
    private val view: AuthoringView,
) : SetupEdit,
    EditContext by context {
    override val checked get() = view.catalog.checked
    override val nativeBindings get() = view.catalog.nativeBindings

    override fun sectionId(definition: TypeDefinitionId): ResourceId? =
        view.resources.entries
            .singleOrNull { (_, record) -> record.configuration.definition == definition }
            ?.key
            ?.toResourceId()

    override fun finish(): PreparedEdit = context.finish()
}
