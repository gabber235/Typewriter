package com.typewritermc.realm.edit

import com.typewritermc.authoring.GraphPlacement
import com.typewritermc.authoring.field
import com.typewritermc.authoring.of
import com.typewritermc.authoring.root
import com.typewritermc.engine.pages.Definition
import com.typewritermc.realm.routeFixtureCatalog
import com.typewritermc.realm.testing.column
import com.typewritermc.realm.testing.commit
import com.typewritermc.realm.testing.commitBoard
import com.typewritermc.realm.testing.commitBound
import com.typewritermc.realm.testing.commitDefinition
import com.typewritermc.realm.testing.computedVar
import com.typewritermc.realm.testing.conflictingFacts
import com.typewritermc.realm.testing.errorCodesOn
import com.typewritermc.realm.testing.errorsOn
import com.typewritermc.realm.testing.fitRuns
import com.typewritermc.realm.testing.formulas
import com.typewritermc.realm.testing.intUse
import com.typewritermc.realm.testing.plainType
import com.typewritermc.realm.testing.plainVar
import com.typewritermc.realm.testing.publicationBlockersByResource
import com.typewritermc.realm.testing.publishToEngine
import com.typewritermc.realm.testing.recordValue
import com.typewritermc.realm.testing.rename
import com.typewritermc.realm.testing.renameAfterReadingTypeOf
import com.typewritermc.realm.testing.rowFields
import com.typewritermc.realm.testing.rowsOf
import com.typewritermc.realm.testing.schemaOf
import com.typewritermc.realm.testing.setColumns
import com.typewritermc.realm.testing.setDefinitionValue
import com.typewritermc.realm.testing.settle
import com.typewritermc.realm.testing.shouldBeCommitted
import com.typewritermc.realm.testing.shouldBeReady
import com.typewritermc.realm.testing.shouldBeRejected
import com.typewritermc.realm.testing.staticPage
import com.typewritermc.realm.testing.textUse
import com.typewritermc.realm.testing.withSetup
import com.typewritermc.realm.testing.writtenFor
import com.typewritermc.testing.routes.FAILING_COLUMN
import com.typewritermc.testing.routes.FixtureContested
import com.typewritermc.testing.routes.FixtureContestedDefinition
import com.typewritermc.testing.routes.FixtureLedger
import com.typewritermc.testing.routes.FixtureLedgerDefinition
import com.typewritermc.testing.routes.FixtureMirror
import com.typewritermc.testing.routes.FixtureMirrorDefinition
import com.typewritermc.types.catalog.derived
import com.typewritermc.types.integer
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldBeEmpty
import io.kotest.matchers.collections.shouldContain
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldContain
import io.kotest.matchers.types.shouldBeInstanceOf
import skirout.editor.v1.authoring.EditIntent
import skirout.editor.v1.authoring_facts.EditExpectation
import skirout.editor.v1.type_catalog.ChosenArgument
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.type_catalog.ValuePath

val BoundTypesTest by testSuite {
    test("a board's row type is computed from its own columns, and the board stores no choice for it") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val board = commitBoard("scores", column("gold", number = true), column("title")).created()

            schemaOf(board) shouldBeReady true
            rowFields(board) shouldBe listOf("gold" to intUse, "title" to textUse)
            writtenFor(board).shouldBeEmpty()
        }
    }

    test("editing a board's columns changes the row type behind the same id, and nothing is written back") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val board = commitBoard("scores", column("gold", number = true)).created()

            commit(setColumns(board, column("gold"), column("note"))).shouldBeCommitted()

            rowFields(board) shouldBe listOf("gold" to textUse, "note" to textUse)
            writtenFor(board).shouldBeEmpty()
        }
    }

    test("a value of a board's row type that no longer fits its columns gets a finding on its holder") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val board = commitBoard("scores", column("gold", number = true)).created()
            val row = rowsOf(board)
            val holder =
                commitDefinition("best", plainType(row)) { plainVar(row, recordValue(row, "gold" to DataValue.integer(1))) }.created()
            errorCodesOn(holder).shouldBeEmpty()

            commit(setColumns(board, column("gold"))).shouldBeCommitted()

            errorCodesOn(holder) shouldBe listOf("value_mismatch")
        }
    }

    test("a board whose bind fails is still saved, shows why on itself, and blocks publish") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val board = commitBoard("broken", column(FAILING_COLUMN)).created()

            errorCodesOn(board) shouldBe listOf("derived_type_failed")
            errorsOn(board).single().message shouldContain "The fixture bind fails on this column."
            publicationBlockersByResource()[board] shouldBe 1
        }
    }

    test("a value of a board's row type gets a finding once the board's bind starts failing") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val board = commitBoard("scores", column("gold", number = true)).created()
            val row = rowsOf(board)
            val holder =
                commitDefinition("best", plainType(row)) { plainVar(row, recordValue(row, "gold" to DataValue.integer(1))) }.created()

            commit(setColumns(board, column(FAILING_COLUMN))).shouldBeCommitted()

            errorCodesOn(holder) shouldBe listOf("derived_type_failed")
        }
    }

    test("a new use of a board's row type while its bind fails is refused, as a new use of any missing type is") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val board = commitBoard("broken", column(FAILING_COLUMN)).created()

            commitDefinition("late", plainType(rowsOf(board))).reply.shouldBeRejected("derived_type_failed")
        }
    }

    test("a resource whose own bind fails still cannot start using another resource's failing computed type") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val board = commitBoard("broken", column(FAILING_COLUMN)).created()

            commitBound(
                FixtureLedgerDefinition.id,
                parameters = 2,
                chosen = listOf(ChosenArgument(parameter = 0, type = rowsOf(board))),
            ) { page ->
                FixtureLedger<Nothing, Nothing>(page, GraphPlacement(), "ledger", failing = true)
            }.reply.shouldBeRejected("derived_type_failed")
        }
    }

    test("a resource that already uses a failing computed type can still save its own bind failing") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val board = commitBoard("scores", column("gold")).created()
            val ledger =
                commitBound(
                    FixtureLedgerDefinition.id,
                    parameters = 2,
                    chosen = listOf(ChosenArgument(parameter = 0, type = rowsOf(board))),
                ) { page ->
                    FixtureLedger<Nothing, Nothing>(page, GraphPlacement(), "ledger")
                }.created()
            commit(setColumns(board, column(FAILING_COLUMN))).shouldBeCommitted()

            commit(
                EditIntent.createSetValue(
                    at = ValueLocation.of(ledger, ValuePath.root.field("failing")),
                    value = DataValue.BooleanWrapper(true),
                ),
            ).shouldBeCommitted()
        }
    }

    test("a board that holds rows is still saved when its own bind starts failing") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val board =
                commitBoard(
                    "scores",
                    column("gold", number = true),
                ) { row -> listOf(recordValue(row, "gold" to DataValue.integer(1))) }.created()

            commit(setColumns(board, column(FAILING_COLUMN))).shouldBeCommitted()

            errorCodesOn(board) shouldBe listOf("derived_type_failed")
        }
    }

    test("a bind that needs its own computed type is saved with a loop finding, and a new use of that type is refused") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val mirror =
                commitBound(
                    FixtureMirrorDefinition.id,
                ) { page -> FixtureMirror<Nothing>(page, GraphPlacement(), "first") }.created()

            errorCodesOn(mirror) shouldBe listOf("derived_type_loop")
            commitDefinition("late", plainType(rowsOf(mirror))).reply.shouldBeRejected("derived_type_loop")
        }
    }

    test("binds that need each other's computed types each get a loop finding, and a new use of either is refused") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val first =
                commitBound(
                    FixtureMirrorDefinition.id,
                ) { page -> FixtureMirror<Nothing>(page, GraphPlacement(), "first") }.created()
            val second =
                commitBound(
                    FixtureMirrorDefinition.id,
                ) { page -> FixtureMirror<Nothing>(page, GraphPlacement(), "second") }.created()

            errorCodesOn(first) shouldBe listOf("derived_type_loop")
            errorCodesOn(second) shouldBe listOf("derived_type_loop")
            commitDefinition("late", plainType(rowsOf(first))).reply.shouldBeRejected("derived_type_loop")
            commitDefinition("later", plainType(rowsOf(second))).reply.shouldBeRejected("derived_type_loop")
        }
    }

    test("a parameter two providers bind is decided by neither, and its resource shows the conflict") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val contested =
                commitBound(
                    FixtureContestedDefinition.id,
                ) { page -> FixtureContested<Nothing>(page, GraphPlacement(), "both") }.created()

            errorCodesOn(contested) shouldBe listOf("derived_type_conflict")
        }
    }

    test("a use of a computed type no bind provides is refused") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val board = commitBoard("scores", column("gold")).created()

            commitDefinition("late", plainType(TypeDefinitionId.derived(board, "W").use())).reply.shouldBeRejected("derived_type_missing")
        }
    }

    test("a creator cannot choose a parameter a bind computes") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            commitBoard("chosen", column("gold"), chosen = listOf(ChosenArgument(parameter = 0, type = intUse))).reply.shouldBeRejected()
        }
    }

    test("a value of a board's row type is judged again only when an edit changes that row type") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val board = commitBoard("scores", column("gold", number = true)).created()
            val row = rowsOf(board)
            val holder =
                commitDefinition(
                    "best",
                    plainType(row),
                ) { plainVar(row, recordValue(row, "gold" to DataValue.integer(1))) }.created()
            settle()
            val judged = fitRuns(holder)

            commit(rename(board, "renamed")).shouldBeCommitted()
            settle()
            fitRuns(holder) shouldBe judged

            commit(setColumns(board, column("gold"))).shouldBeCommitted()
            settle()
            fitRuns(holder) shouldBe judged + 1
        }
    }

    test("a board's own hooks still read its fields while its row type is computed") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            commitBoard("scores", column("gold", number = true)).created()

            val first = commitDefinition("first", plainType(textUse)) { computedVar(textUse, "scores.get(0)?.name ?: \"none\"") }.created()

            formulas.value(first) shouldBe "gold"
        }
    }

    test("one commit that changes a board's columns and a value of its row type judges the value by the new columns") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val board = commitBoard("scores", column("gold", number = true)).created()
            val row = rowsOf(board)
            val holder =
                commitDefinition(
                    "best",
                    plainType(row),
                ) { plainVar(row, recordValue(row, "gold" to DataValue.integer(1))) }.created()

            commit(
                setColumns(board, column("gold", number = true), column("note")),
                setDefinitionValue(
                    holder,
                    plainVar(
                        row,
                        recordValue(
                            row,
                            "gold" to DataValue.integer(2),
                            "note" to DataValue.StringValueWrapper("kept"),
                        ),
                    ),
                ),
            ).shouldBeCommitted()
            errorCodesOn(holder).shouldBeEmpty()

            commit(
                setColumns(board, column("gold", number = true)),
                setDefinitionValue(
                    holder,
                    plainVar(
                        row,
                        recordValue(
                            row,
                            "gold" to DataValue.integer(3),
                            "note" to DataValue.StringValueWrapper("gone"),
                        ),
                    ),
                ),
            ).shouldBeCommitted()
            errorCodesOn(holder) shouldContain "value_mismatch"
        }
    }

    test("an operation that read what a board's row type means goes stale when the board's columns change") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val board = commitBoard("scores", column("gold", number = true)).created()
            val row = rowsOf(board)
            val holder =
                commitDefinition(
                    "best",
                    plainType(row),
                ) { plainVar(row, recordValue(row, "gold" to DataValue.integer(1))) }.created()
            val stale = renameAfterReadingTypeOf(holder, "renamed")

            commit(setColumns(board, column("gold"))).shouldBeCommitted()

            commit(stale).conflictingFacts().mapNotNull { (it as? EditExpectation.ValueWrapper)?.value?.at?.resource } shouldContain board
        }
    }

    test("an operation that takes a row type another reader computed first still conflicts when the board's columns change") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val board = commitBoard("scores", column("gold", number = true)).created()
            val row = rowsOf(board)
            val holder =
                commitDefinition(
                    "best",
                    plainType(row),
                ) { plainVar(row, recordValue(row, "gold" to DataValue.integer(1))) }.created()
            val stale = renameAfterReadingTypeOf(holder, "renamed", readElsewhereFirst = true)

            commit(setColumns(board, column("gold"))).shouldBeCommitted()

            commit(stale).conflictingFacts().mapNotNull { (it as? EditExpectation.ValueWrapper)?.value?.at?.resource } shouldContain board
        }
    }

    test("a published board and a value of its row type reach the engine, which computes no row type itself") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val board = commitBoard("scores", column("gold", number = true)).created()
            val row = rowsOf(board)
            val holder =
                commitDefinition(
                    "best",
                    plainType(row),
                ) { plainVar(row, recordValue(row, "gold" to DataValue.integer(7))) }.created()

            val published = publishToEngine()

            published.keys shouldContain board
            published
                .getValue(holder)
                .shouldBeInstanceOf<Definition<*>>()
                .value
                .toString() shouldContain "7"
        }
    }
}
