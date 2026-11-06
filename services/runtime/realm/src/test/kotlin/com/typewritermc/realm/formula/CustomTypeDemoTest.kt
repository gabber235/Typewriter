package com.typewritermc.realm.formula

import com.typewritermc.realm.routeFixtureCatalog
import com.typewritermc.realm.testing.addField
import com.typewritermc.realm.testing.commit
import com.typewritermc.realm.testing.createEntry
import com.typewritermc.realm.testing.delete
import com.typewritermc.realm.testing.demoOneDefinitions
import com.typewritermc.realm.testing.demoTwoDefinitions
import com.typewritermc.realm.testing.errorsOn
import com.typewritermc.realm.testing.formulaPage
import com.typewritermc.realm.testing.formulas
import com.typewritermc.realm.testing.publicationBlockers
import com.typewritermc.realm.testing.record
import com.typewritermc.realm.testing.records
import com.typewritermc.realm.testing.referenceTargets
import com.typewritermc.realm.testing.rename
import com.typewritermc.realm.testing.rerunSince
import com.typewritermc.realm.testing.resources
import com.typewritermc.realm.testing.setFormula
import com.typewritermc.realm.testing.setGiver
import com.typewritermc.realm.testing.settle
import com.typewritermc.realm.testing.settledRuns
import com.typewritermc.realm.testing.shouldBeRejected
import com.typewritermc.realm.testing.shouldContainLocation
import com.typewritermc.realm.testing.textUse
import com.typewritermc.realm.testing.value
import com.typewritermc.realm.testing.withSetup
import com.typewritermc.setup.setup
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContain
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldContain
import skirout.editor.v1.type_catalog.DataValue

val CustomTypeDemoTest by testSuite {
    val page =
        setup("custom-type-demo") {
            formulaPage {
                smith()
                demoOneDefinitions()
                demoTwoDefinitions()
            }
        }

    test("a custom type's fields and references evaluate") {
        withSetup(page, catalog = routeFixtureCatalog) { demo ->
            formulas.value(demo.firstReward, "gold") shouldBe 70
            formulas.value(demo.giverName) shouldBe "smith"
        }
    }

    test("a reference pointing at the wrong type is refused and nothing changes") {
        withSetup(page, catalog = routeFixtureCatalog) { demo ->
            val before = record(demo.gift)
            commit(setGiver(demo.gift, to = demo.pageId)).shouldBeRejected("binding_target_type_mismatch")
            record(demo.gift) shouldBe before
        }
    }

    test("renaming smith writes nothing to the others and the read follows") {
        withSetup(page, catalog = routeFixtureCatalog) { demo ->
            val before = records(demo.gift, demo.firstReward, demo.giverName)
            commit(rename(demo.smith, "blacksmith"))
            settle()
            records(demo.gift, demo.firstReward, demo.giverName) shouldBe before
            formulas.value(demo.giverName) shouldBe "blacksmith"
        }
    }

    test("deleting smith empties the plain link, blocks publish, and names the deleted target") {
        withSetup(page, catalog = routeFixtureCatalog) { demo ->
            commit(delete(demo.smith))
            settle()
            value(demo.gift, "value", "value", "giver") shouldBe DataValue.UNFILLED
            errorsOn(demo.firstReward).single().message shouldContain "smith"
            publicationBlockers() shouldContainLocation demo.gift
        }
    }

    test("a new smith binds the broken formula by itself, and the plain link stays empty") {
        withSetup(page, catalog = routeFixtureCatalog) { demo ->
            commit(delete(demo.smith))
            val replacement = createEntry("smith")
            commit(replacement)
            settle()
            errorsOn(demo.firstReward) shouldBe emptyList()
            formulas.value(demo.giverName) shouldBe "smith"
            referenceTargets(demo.firstReward) shouldContain replacement.id
            value(demo.gift, "value", "value", "giver") shouldBe DataValue.UNFILLED
        }
    }

    test("a when over an inline union that misses a case is an error in the check list") {
        withSetup(page, catalog = routeFixtureCatalog) { demo ->
            commit(setFormula(demo.total, "when (door) { is Open -> 1 }"))
            settle()
            errorsOn(demo.total).single().code shouldBe "formula_when_not_exhaustive"
        }
    }

    test("adding a field to Reward reruns its readers and flags values that no longer fit") {
        withSetup(page, catalog = routeFixtureCatalog) { demo ->
            val before = settledRuns()
            commit(addField(demo.reward, "note", textUse))
            settle()
            rerunSince(before).resources() shouldContain demo.firstReward
            errorsOn(demo.firstReward).single().code shouldBe "formula_missing_argument"
        }
    }
}
