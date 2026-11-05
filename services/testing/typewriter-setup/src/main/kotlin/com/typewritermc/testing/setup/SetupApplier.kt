@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.testing.setup

import com.typewritermc.authoring.EditContext
import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.authoring.boundCollectionPath
import com.typewritermc.authoring.field
import com.typewritermc.authoring.of
import com.typewritermc.authoring.root
import com.typewritermc.authoring.text
import com.typewritermc.authoring.with
import com.typewritermc.setup.Setup
import com.typewritermc.setup.SetupName
import com.typewritermc.setup.SetupOwner
import com.typewritermc.setup.SetupPart
import com.typewritermc.types.NativeBindingRegistry
import com.typewritermc.types.Ref
import com.typewritermc.types.ResourceId
import com.typewritermc.types.actualType
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.catalog.CheckedType
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.encodeGeneratedDefault
import com.typewritermc.types.fieldMap
import com.typewritermc.types.payload
import com.typewritermc.types.toResourceId
import com.typewritermc.types.use
import skirout.editor.v1.authoring.CommitPreparedEditResponse
import skirout.editor.v1.authoring.PreparedEdit
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.TypeUse
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.type_catalog.ValuePath

/** The realm operations a setup needs; in process for Realm tests, over NATS for a running Realm. */
interface SetupEditor {
    /** Runs [block] in a fresh edit context over the current authored state and catalog. */
    suspend fun <T> edit(
        name: String,
        block: suspend SetupEdit.() -> T,
    ): T

    /** Commits [edit] through the commit route as a member. */
    suspend fun commit(edit: PreparedEdit): CommitPreparedEditResponse
}

/** An [EditContext] plus what a setup must read: the catalog that encodes its records and the realm's section ids. */
interface SetupEdit : EditContext {
    val checked: CheckedCatalog
    val nativeBindings: NativeBindingRegistry

    /** The realm's single instance of the section type [definition], or null when the realm has none. */
    fun sectionId(definition: TypeDefinitionId): ResourceId?

    /** The prepared edit, with the expectations admission requires. */
    fun finish(): PreparedEdit
}

/** The realm refused a setup; [problems] name setup paths, for example `library / books greeting / title: code`. */
class SetupRejected(
    val setup: SetupName,
    val problems: List<String>,
) : IllegalStateException("Setup ${setup.value} was rejected:\n${problems.joinToString("\n") { "  $it" }}")

/**
 * Applies setups the way an author creates content: each part is created with its owner link unfilled, then a link to
 * it is inserted into its owner's list, which writes both sides. Every part goes into one edit and one commit.
 */
class SetupApplier(
    private val editor: SetupEditor,
) {
    suspend fun apply(setup: Setup<*>) {
        val edit =
            editor.edit("setup:${setup.name.value}") {
                // Keeps the siblings of one owner list in builder order.
                val lastItem = mutableMapOf<Pair<ResourceId, ValuePath>, ItemId>()
                for (part in setup.parts) {
                    val owner =
                        when (val owner = part.owner) {
                            is SetupOwner.Part -> {
                                owner.id
                            }

                            is SetupOwner.Section -> {
                                sectionId(owner.definition)
                                    ?: error("The realm has no ${owner.type.simpleName}; is its extension loaded?")
                            }
                        }
                    create(part.id, record(part))
                    val slot = owner to part.list
                    lastItem[slot] = insert(boundCollectionPath(ValueLocation.of(owner, part.list)), lastItem[slot], ownerLink(part))
                }
                finish()
            }
        val response = editor.commit(edit)
        if (response != CommitPreparedEditResponse.COMMITTED) throw SetupRejected(setup.name, setup.describe(response))
    }
}

/** The record an author's create would carry for [part], with its owner link left for the insert to fill. */
private fun SetupEdit.record(part: SetupPart): AuthoringRecord {
    val encoded = nativeBindings.bind(checkedType(part.definition.use())).encodeGeneratedDefault(part.construct()) as DataValue.NamedWrapper
    val fields = (encoded.payload as DataValue.RecordWrapper).value.fieldMap
    val record = AuthoringRecord.of(TypeSelection.CompleteWrapper(encoded.actualType), fields)
    return part.ownerField?.let { record.with(it.serialized, DataValue.UNFILLED) } ?: record
}

/** The owner list item for [part], pointing back at the part's owner field when it has one. */
private fun SetupEdit.ownerLink(part: SetupPart): DataValue =
    nativeBindings
        .bind(checkedType(part.item))
        .encodeGeneratedDefault(Ref<Nothing, Nothing>(part.id, part.ownerField?.let { ValuePath.root.field(it.serialized) }))

private fun SetupEdit.checkedType(use: TypeUse): CheckedType =
    when (val resolution = checked.resolve(use)) {
        is Resolution.Ready -> resolution.value
        is Resolution.Invalid -> error("The realm catalog cannot resolve $use: ${resolution.diagnostics}")
    }

/** Rejection problems as setup paths; other responses as they are. */
private fun Setup<*>.describe(response: CommitPreparedEditResponse): List<String> =
    when (response) {
        is CommitPreparedEditResponse.RejectedErrorWrapper -> {
            response.value.map { problem ->
                "${pathOf(problem.location.resource.toResourceId())} ${problem.location.path.text}: ${problem.code}"
            }
        }

        else -> {
            listOf(response.toString())
        }
    }
