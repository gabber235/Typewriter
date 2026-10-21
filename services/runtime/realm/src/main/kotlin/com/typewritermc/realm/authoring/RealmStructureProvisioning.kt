@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.realm.authoring

import com.typewritermc.authoring.CommitResult
import com.typewritermc.authoring.DefaultInitializationRuntime
import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.authoring.InitializationRequest
import com.typewritermc.authoring.PreparationTarget
import com.typewritermc.authoring.PreparedEdit
import com.typewritermc.authoring.RealmRoot
import com.typewritermc.authoring.RealmRootDefinition
import com.typewritermc.authoring.RealmRootFields
import com.typewritermc.authoring.RealmSection
import com.typewritermc.authoring.RealmSectionDefinition
import com.typewritermc.authoring.RealmSections
import com.typewritermc.authoring.boundCollectionPath
import com.typewritermc.authoring.definition
import com.typewritermc.authoring.of
import com.typewritermc.authoring.record
import com.typewritermc.realm.repository.AuthoringRepository
import com.typewritermc.realm.repository.valueAt
import com.typewritermc.types.NativeBinding
import com.typewritermc.types.Ref
import com.typewritermc.types.ResourceId
import com.typewritermc.types.actualType
import com.typewritermc.types.canonicalText
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.catalog.CheckedType
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.items
import com.typewritermc.types.payload
import com.typewritermc.types.unwrapNamed
import com.typewritermc.types.use
import skirout.editor.v1.catalog.PreparedContent
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.NamedTypeUse
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.TypeUse
import skirout.editor.v1.type_catalog.ValueLocation
import java.util.UUID

/**
 * Creates the realm root and one instance of every concrete realm section type that is missing.
 *
 * Runs once on Realm start, after routed authoring is wired and outside catalog admission, so it commits like any
 * other edit and cannot deadlock with a commit. A section type added by a new extension is created on the next start.
 * Missing sections are appended to the root in display name order; a fresh realm gets the root and every section in
 * one edit. A realm that already has its root and sections is left untouched.
 */
internal class RealmStructureProvisioning(
    private val authoring: AuthoringRepository,
) {
    suspend fun ensure(views: AuthoringViewStore) {
        val edit = views.capture().use { lease -> prepare(lease.root) } ?: return
        val result = authoring.commit(edit)
        check(result == CommitResult.Committed) { "The realm root and sections could not be created: $result" }
    }

    /**
     * The edit that creates the missing root and sections of [view], or null when nothing is missing. A catalog that
     * declares no usable realm root has no structure to provision.
     */
    internal suspend fun prepare(view: AuthoringView): PreparedEdit? {
        val catalog = view.catalog
        if (catalog.checked.readyOrNull(RealmRootDefinition.id.use()) == null) return null
        val present = view.resources.values.mapTo(hashSetOf()) { it.configuration.definition }
        val displayName = { type: NamedTypeUse ->
            catalog.displays
                .publishedType(type.definition)
                ?.display
                ?.name
        }
        val missing =
            catalog.checked
                .readyOrNull(RealmSectionDefinition.id.use())
                ?.let(catalog.checked::concreteForms)
                .orEmpty()
                .map { (it.use as TypeUse.NamedWrapper).value }
                .filter { it.definition !in present }
                .sortedWith(compareBy(displayName).thenBy { it.definition.canonicalText })
        val existingRoot =
            view.resources.entries
                .singleOrNull { (_, record) ->
                    record.configuration.definition == RealmRootDefinition.id
                }?.key
        if (existingRoot != null && missing.isEmpty()) return null
        val edit = WorkingViewEditContext(view, "realm-structure:${view.observationId}")
        val root = existingRoot ?: newResource().also { edit.create(it, rootRecord(view)) }
        val links = boundCollectionPath(ValueLocation.of(root, RealmRootFields.sections.path))
        val linkBinding = catalog.binding<Ref<RealmSections.Root, RealmSection>>(sectionLink)
        missing.forEach { type ->
            val section = newResource()
            edit.create(section, sectionRecord(view, type))
            val after =
                edit.session.resources
                    .getValue(root)
                    .sectionItems()
                    .lastOrNull()
            edit.insert(links, after, linkBinding.encode(Ref(section)))
        }
        return edit.finish()
    }

    private fun rootRecord(view: AuthoringView): AuthoringRecord {
        val encoded = view.catalog.binding<RealmRoot>(RealmRootDefinition.id.use()).encode(RealmRoot()) as DataValue.NamedWrapper
        return AuthoringRecord.of(
            TypeSelection.CompleteWrapper(encoded.actualType),
            (encoded.payload as DataValue.RecordWrapper).value,
        )
    }

    private suspend fun sectionRecord(
        view: AuthoringView,
        type: NamedTypeUse,
    ): AuthoringRecord {
        val catalog = view.catalog
        val prepared =
            DefaultInitializationRuntime(catalog.checked, catalog.nativeBindings).prepare(
                InitializationRequest(catalog.generation, PreparationTarget.Record(TypeSelection.CompleteWrapper(type)), null),
            )
        val content = prepared.content
        check(content is PreparedContent.RecordWrapper) { "Realm section $type must be creatable as a record without input." }
        return content.record
    }

    private fun AuthoringRecord.sectionItems() =
        (valueAt(RealmRootFields.sections.path)?.unwrapNamed() as? DataValue.ListValueWrapper)?.items.orEmpty().map {
            it.id
        }

    private fun newResource() = ResourceId(UUID.randomUUID().toString())

    private companion object {
        val sectionLink =
            RealmSections.Root.Definition.id
                .use(listOf(RealmSectionDefinition.id.use()))
    }
}

private fun CheckedCatalog.readyOrNull(use: TypeUse): CheckedType? = (resolve(use) as? Resolution.Ready)?.value

private fun CheckedCatalog.ready(use: TypeUse): CheckedType = requireNotNull(readyOrNull(use)) { "The catalog has no usable $use." }

@Suppress("UNCHECKED_CAST")
private fun <T> AuthoringCatalogLease.binding(use: TypeUse): NativeBinding<T> = nativeBindings.bind(checked.ready(use)) as NativeBinding<T>
