package com.typewritermc.realm.edit

import com.typewritermc.realm.routeFixtureCatalog
import com.typewritermc.realm.testing.column
import com.typewritermc.realm.testing.commit
import com.typewritermc.realm.testing.commitBoard
import com.typewritermc.realm.testing.commitContested
import com.typewritermc.realm.testing.commitDefinition
import com.typewritermc.realm.testing.commitLedger
import com.typewritermc.realm.testing.commitMirror
import com.typewritermc.realm.testing.errorCodesOn
import com.typewritermc.realm.testing.errorsOn
import com.typewritermc.realm.testing.intUse
import com.typewritermc.realm.testing.plainType
import com.typewritermc.realm.testing.plainVar
import com.typewritermc.realm.testing.publicationBlockersByResource
import com.typewritermc.realm.testing.recordValue
import com.typewritermc.realm.testing.rowFields
import com.typewritermc.realm.testing.rowsOf
import com.typewritermc.realm.testing.schemaOf
import com.typewritermc.realm.testing.setColumns
import com.typewritermc.realm.testing.shouldBeCommitted
import com.typewritermc.realm.testing.shouldBeReady
import com.typewritermc.realm.testing.shouldBeRejected
import com.typewritermc.realm.testing.staticPage
import com.typewritermc.realm.testing.textUse
import com.typewritermc.realm.testing.withSetup
import com.typewritermc.realm.testing.writtenFor
import com.typewritermc.testing.routes.FAILING_COLUMN
import com.typewritermc.types.catalog.derived
import com.typewritermc.types.integer
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldBeEmpty
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldContain
import skirout.editor.v1.type_catalog.ChosenArgument
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.TypeDefinitionId

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

            commitLedger("ledger", about = rowsOf(board), failing = true).reply.shouldBeRejected("derived_type_failed")
        }
    }

    test("a bind that needs its own computed type is saved with a loop finding, and a new use of that type is refused") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val mirror = commitMirror("first").created()

            errorCodesOn(mirror) shouldBe listOf("derived_type_loop")
            commitDefinition("late", plainType(rowsOf(mirror))).reply.shouldBeRejected("derived_type_loop")
        }
    }

    test("a parameter two providers bind is decided by neither, and its resource shows the conflict") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val contested = commitContested("both").created()

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
}
