@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.testkit.setup

import com.typewritermc.authoring.EditContext
import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.authoring.SubmissionKey
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
import com.typewritermc.testkit.CatalogEncoder
import com.typewritermc.types.NativeBindingRegistry
import com.typewritermc.types.Ref
import com.typewritermc.types.ResourceId
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.toResourceId
import com.typewritermc.types.use
import skirout.editor.v1.authoring.CommitPreparedEditResponse
import skirout.editor.v1.authoring.PreparedEdit
import skirout.editor.v1.diagnostic.ValueProblem
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.type_catalog.ValuePath
import java.util.UUID

/** The realm operations a setup needs; in process for Realm tests, over NATS for a running Realm. */
interface SetupEditor {
    /**
     * Runs [block] in a fresh edit context over the current authored state and catalog. A realm that checks each write
     * as it is made throws [EditRefused] for a write it refuses.
     */
    suspend fun <T> edit(
        name: String,
        block: suspend SetupEdit.() -> T,
    ): T

    /** Commits [edit] as the save attempt [submission] through the commit route as a member. */
    suspend fun commit(
        edit: PreparedEdit,
        submission: SubmissionKey,
    ): CommitPreparedEditResponse
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

/** The realm refused a write while the edit was being written, for [problems]. */
class EditRefused(
    val problems: List<ValueProblem>,
) : IllegalStateException(problems.joinToString { "${it.location.resource.value} ${it.location.path.text}: ${it.code}" })

/** The realm refused a setup; [problems] name setup paths, for example `library / books greeting / title: code`. */
class SetupRejected(
    val setup: SetupName,
    val problems: List<String>,
    cause: Throwable? = null,
) : IllegalStateException("Setup ${setup.value} was rejected:\n${problems.joinToString("\n") { "  $it" }}", cause)

/**
 * Applies setups the way an author creates content: each part is created with its owner link unfilled, then a link to
 * it is inserted into its owner's list, which writes both sides. Every part goes into one edit and one commit.
 */
class SetupApplier(
    private val editor: SetupEditor,
) {
    suspend fun apply(setup: Setup<*>) {
        val edit =
            try {
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
            } catch (refused: EditRefused) {
                throw SetupRejected(setup.name, setup.describe(refused.problems), refused)
            }
        val response = editor.commit(edit, SubmissionKey("setup:${UUID.randomUUID()}"))
        if (response !is CommitPreparedEditResponse.CommittedWrapper) throw SetupRejected(setup.name, setup.describe(response))
    }
}

/** The record an author's create would carry for [part], with its owner link left for the insert to fill. */
private fun SetupEdit.record(part: SetupPart): AuthoringRecord {
    val record = CatalogEncoder(checked, nativeBindings).record(part.definition.use(part.arguments), part.construct())
    return part.ownerField?.let { record.with(it.serialized, DataValue.UNFILLED) } ?: record
}

/** The owner list item for [part], pointing back at the part's owner field when it has one. */
private fun SetupEdit.ownerLink(part: SetupPart): DataValue =
    CatalogEncoder(checked, nativeBindings)
        .encode(part.item, Ref<Nothing, Nothing>(part.id, part.ownerField?.let { ValuePath.root.field(it.serialized) }))

/** Rejection problems as setup paths; other responses as they are. */
private fun Setup<*>.describe(response: CommitPreparedEditResponse): List<String> =
    when (response) {
        is CommitPreparedEditResponse.RejectedErrorWrapper -> {
            describe(response.value)
        }

        else -> {
            listOf(response.toString())
        }
    }

private fun Setup<*>.describe(problems: List<ValueProblem>): List<String> =
    problems.map { problem -> "${pathOf(problem.location.resource.toResourceId())} ${problem.location.path.text}: ${problem.code}" }
