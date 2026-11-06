package com.typewritermc.realm.formula

import com.typewritermc.realm.routeFixtureCatalog
import com.typewritermc.realm.testing.commitPreparedTypeChange
import com.typewritermc.realm.testing.demoOneDefinitions
import com.typewritermc.realm.testing.errorsOn
import com.typewritermc.realm.testing.formulaPage
import com.typewritermc.realm.testing.formulas
import com.typewritermc.realm.testing.record
import com.typewritermc.realm.testing.rename
import com.typewritermc.realm.testing.rerunSince
import com.typewritermc.realm.testing.resources
import com.typewritermc.realm.testing.settle
import com.typewritermc.realm.testing.settledRuns
import com.typewritermc.realm.testing.stringUse
import com.typewritermc.realm.testing.withSetup
import com.typewritermc.setup.setup
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContainExactlyInAnyOrder
import io.kotest.matchers.shouldBe

val FormulaDemoTest by testSuite {
    val page = setup("formula-demo") { formulaPage { demoOneDefinitions() } }

    test("the realm evaluates total to 70") {
        withSetup(page, catalog = routeFixtureCatalog) { demo -> formulas.value(demo.total) shouldBe 70 }
    }

    test("a type change on base_reward shows an error on total and reruns only total") {
        withSetup(page, catalog = routeFixtureCatalog) { demo ->
            val before = settledRuns()
            commitPreparedTypeChange(demo.baseReward, to = stringUse)
            settle()
            errorsOn(demo.total).single().code shouldBe "formula_type_mismatch"
            rerunSince(before).resources() shouldContainExactlyInAnyOrder listOf(demo.baseReward, demo.total)
        }
    }

    test("renaming base_reward writes nothing to total, and total shows the new name") {
        withSetup(page, catalog = routeFixtureCatalog) { demo ->
            val before = record(demo.total)
            commit(rename(demo.baseReward, "starting_reward"))
            settle()
            record(demo.total) shouldBe before
            formulas.display(demo.total) shouldBe "starting_reward + bonus(10)"
            formulas.value(demo.total) shouldBe 70
        }
    }
}
