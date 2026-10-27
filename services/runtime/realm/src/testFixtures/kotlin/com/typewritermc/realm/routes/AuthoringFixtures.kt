package com.typewritermc.realm.routes

import com.typewritermc.authoring.field
import com.typewritermc.authoring.of
import com.typewritermc.authoring.root
import com.typewritermc.library.Book
import com.typewritermc.realm.authoring.valueAt
import com.typewritermc.realm.testing.RealmFixture
import com.typewritermc.setup.SetupHandle
import com.typewritermc.types.qualified
import skirout.editor.v1.authoring.EditIntent
import skirout.editor.v1.authoring.PreparedEdit
import skirout.editor.v1.authoring_facts.EditExpectation
import skirout.editor.v1.checking.CheckInstanceId
import skirout.editor.v1.checking.CheckOutcome
import skirout.editor.v1.checking.CheckTicket
import skirout.editor.v1.checking.FindingSet
import skirout.editor.v1.checking.FindingStatus
import skirout.editor.v1.type_catalog.CheckExecutionId
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.FieldValue
import skirout.editor.v1.type_catalog.RuleId
import skirout.editor.v1.type_catalog.RuleOrigin
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.type_catalog.ValuePath

/** A commit payload that cannot be decoded or validated, built from the setup's book. */
internal class InvalidCommit(
    val name: String,
    val payload: RealmFixture.(SetupHandle<Book>) -> ByteArray,
)

/** The location of the title of [book]. */
internal fun titleOf(book: SetupHandle<Book>) = ValueLocation.of(book.resource, ValuePath.root.field("title"))

/** An edit renaming [book] to [title], with the expectations an editor sends. */
internal fun RealmFixture.rename(
    book: SetupHandle<Book>,
    title: String,
): PreparedEdit = prepare(listOf(EditIntent.createSetValue(at = titleOf(book), value = DataValue.StringValueWrapper(title))))

/** [intent] alone, unguarded, as a client that skips preparation sends it. */
internal fun RealmFixture.edit(intent: EditIntent) =
    PreparedEdit(catalog = generation, expectations = emptyList(), intents = listOf(intent))

/** The wire bytes of [edit], as a client sends a prepared edit. */
internal fun encode(edit: PreparedEdit): ByteArray = PreparedEdit.serializer.toBytes(edit).toByteArray()

/** Two title fields in one record, which admission refuses as duplicated. */
internal fun duplicateTitles() =
    listOf(
        FieldValue(name = "title", value = DataValue.StringValueWrapper("first")),
        FieldValue(name = "title", value = DataValue.StringValueWrapper("second")),
    )

/** A finding of a check that read the saved title of [book] under the current catalog, stored as [status]. */
internal fun RealmFixture.titleFinding(
    book: SetupHandle<Book>,
    status: FindingStatus,
): FindingSet {
    val title = titleOf(book)
    return FindingSet(
        ticket =
            CheckTicket(
                instance =
                    CheckInstanceId(
                        rule = RuleId(origin = RuleOrigin(owner = TypeDefinitionId.qualified("test", "rule"), ordinal = 0), localIndex = 0),
                        location = title,
                    ),
                incarnation = "catalog:1",
                execution = CheckExecutionId(value = "execution"),
                catalog = generation,
            ),
        expectations = listOf(EditExpectation.createValue(at = title, expected = resources.getValue(book.resource).valueAt(title.path))),
        outcome = CheckOutcome.FINISHED,
        findings = emptyList(),
        status = status,
    )
}
