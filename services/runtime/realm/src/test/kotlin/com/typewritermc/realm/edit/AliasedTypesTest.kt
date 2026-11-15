package com.typewritermc.realm.edit

import com.typewritermc.authoring.GraphPlacement
import com.typewritermc.authoring.of
import com.typewritermc.realm.routeFixtureCatalog
import com.typewritermc.realm.testing.bindRuns
import com.typewritermc.realm.testing.column
import com.typewritermc.realm.testing.commit
import com.typewritermc.realm.testing.commitAlias
import com.typewritermc.realm.testing.commitBoard
import com.typewritermc.realm.testing.commitBound
import com.typewritermc.realm.testing.commitEchoes
import com.typewritermc.realm.testing.errorCodesOn
import com.typewritermc.realm.testing.errorsOn
import com.typewritermc.realm.testing.intUse
import com.typewritermc.realm.testing.publicationBlockersByResource
import com.typewritermc.realm.testing.publishToEngine
import com.typewritermc.realm.testing.recordValue
import com.typewritermc.realm.testing.rowFields
import com.typewritermc.realm.testing.setColumns
import com.typewritermc.realm.testing.shouldBeCommitted
import com.typewritermc.realm.testing.staticPage
import com.typewritermc.realm.testing.textUse
import com.typewritermc.realm.testing.withSetup
import com.typewritermc.testing.routes.FAILING_COLUMN
import com.typewritermc.testing.routes.FixtureBoardAlias
import com.typewritermc.testing.routes.FixtureMisanswer
import com.typewritermc.testing.routes.FixtureMisanswerDefinition
import com.typewritermc.types.integer
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldBeEmpty
import io.kotest.matchers.collections.shouldContain
import io.kotest.matchers.longs.shouldBeGreaterThan
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldContain
import io.kotest.matchers.types.shouldBeInstanceOf
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.ValueLocation

val AliasedTypesTest by testSuite {
    test("an alias has the row type of the board it names, and follows the board's column edits without running its own bind") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val board = commitBoard("scores", column("gold", number = true)).created()
            val alias = commitAlias("alias", board).created()

            rowFields(alias) shouldBe listOf("gold" to intUse)
            errorCodesOn(alias).shouldBeEmpty()
            val runs = bindRuns(alias)
            runs shouldBeGreaterThan 0

            commit(setColumns(board, column("gold"), column("note"))).shouldBeCommitted()

            rowFields(alias) shouldBe listOf("gold" to textUse, "note" to textUse)
            errorCodesOn(alias).shouldBeEmpty()
            bindRuns(alias) shouldBe runs
        }
    }

    test("a bind that answers a type and also declares a field fails, and says why") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val entry =
                commitBound(FixtureMisanswerDefinition.id) { page ->
                    FixtureMisanswer<Nothing>(page, GraphPlacement(), "both")
                }.created()

            errorCodesOn(entry) shouldBe listOf("derived_type_failed")
            errorsOn(entry).single().message shouldContain "answers a type declares no fields"
        }
    }

    test("a bind that answers twice fails, and says why") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val entry =
                commitBound(FixtureMisanswerDefinition.id) { page ->
                    FixtureMisanswer<Nothing>(page, GraphPlacement(), "twice", twice = true)
                }.created()

            errorCodesOn(entry) shouldBe listOf("derived_type_failed")
            errorsOn(entry).single().message shouldContain "answered twice"
        }
    }

    test("two resources whose binds answer each other's row type are saved, and each shows the alias loop") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val (first, second) = commitEchoes()

            errorCodesOn(first) shouldBe listOf("content_alias_loop")
            errorCodesOn(second) shouldBe listOf("content_alias_loop")
        }
    }

    test("a new alias of a board whose bind fails is saved, shows a finding naming that board, and blocks publish") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val board = commitBoard("broken", column(FAILING_COLUMN)).created()

            val alias = commitAlias("alias", board).created()

            errorCodesOn(alias) shouldBe listOf("derived_type_failed")
            val finding = errorsOn(alias).single()
            finding.message shouldContain "The fixture bind fails on this column."
            finding.related shouldContain ValueLocation.of(board)
            publicationBlockersByResource()[alias] shouldBe 1
        }
    }

    test("a published alias carries the board's row type, so the engine admits its rows without running a bind") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val board = commitBoard("scores", column("gold", number = true)).created()
            val alias = commitAlias("alias", board) { row -> listOf(recordValue(row, "gold" to DataValue.integer(7))) }.created()

            val published = publishToEngine()

            published
                .getValue(alias)
                .shouldBeInstanceOf<FixtureBoardAlias<*>>()
                .rows
                .single()
                .toString() shouldContain "7"
        }
    }
}
