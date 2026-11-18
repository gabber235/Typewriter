package com.typewritermc.realm.formula

import com.typewritermc.formula.Var
import com.typewritermc.realm.routeFixtureCatalog
import com.typewritermc.realm.testing.booleanUse
import com.typewritermc.realm.testing.errorCodesOn
import com.typewritermc.realm.testing.errorsOn
import com.typewritermc.realm.testing.formulaPage
import com.typewritermc.realm.testing.formulas
import com.typewritermc.realm.testing.intUse
import com.typewritermc.realm.testing.lootUse
import com.typewritermc.realm.testing.sameSourceNameCatalog
import com.typewritermc.realm.testing.settle
import com.typewritermc.realm.testing.withSetup
import com.typewritermc.setup.setup
import com.typewritermc.testing.routes.FixtureLoot
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldBeEmpty
import io.kotest.matchers.shouldBe

val TypeQualificationTest by testSuite {
    test("a plain name two extensions declare is ambiguous, and the finding lists the shortest qualified form of each") {
        val page = setup("qualify-ambiguous") { formulaPage { formula("built", booleanUse, "FixtureLoot() == FixtureLoot()") } }
        withSetup(page, catalog = sameSourceNameCatalog("quests:loot-tables")) { demo ->
            settle()
            val finding = errorsOn(demo.named("built")).first()
            finding.code shouldBe "formula_ambiguous_type"
            finding.message shouldBe "Several types are named `FixtureLoot` (lootTables.FixtureLoot, realmRouteFixtures.FixtureLoot)"
        }
    }

    test("an extension qualifier picks its type in expressions, by its short or its full form, and in type positions") {
        val page =
            setup("qualify-picks") {
                formulaPage {
                    definition("loot", lootUse, FixtureLoot(gold = Var.Value(3)))
                    formula("short", booleanUse, "loot == realmRouteFixtures.FixtureLoot(gold = 3)")
                    formula("full", booleanUse, "loot == typewritermc.realmRouteFixtures.FixtureLoot(gold = 3)")
                    formula("typed", intUse, "let kept: realmRouteFixtures.FixtureLoot = loot\nkept.gold")
                    formula("other", booleanUse, "lootTables.FixtureLoot() == quests.lootTables.FixtureLoot()")
                }
            }
        withSetup(page, catalog = sameSourceNameCatalog("quests:loot-tables")) { demo ->
            listOf("short", "full", "typed", "other").forEach { errorCodesOn(demo.named(it)).shouldBeEmpty() }
            formulas.value(demo.named("short")) shouldBe true
            formulas.value(demo.named("full")) shouldBe true
            formulas.value(demo.named("typed")) shouldBe 3
            formulas.value(demo.named("other")) shouldBe true
        }
    }

    test("a short qualifier two extensions share is ambiguous where it is written, and the finding offers the full forms") {
        val page =
            setup("qualify-short-clash") {
                formulaPage {
                    definition("loot", lootUse, FixtureLoot(gold = Var.Value(3)))
                    formula("short", booleanUse, "realmRouteFixtures.FixtureLoot() == realmRouteFixtures.FixtureLoot()")
                    formula("full", booleanUse, "loot == typewritermc.realmRouteFixtures.FixtureLoot(gold = 3)")
                }
            }
        withSetup(page, catalog = sameSourceNameCatalog("quests:realm-route-fixtures")) { demo ->
            settle()
            val finding = errorsOn(demo.named("short")).first()
            finding.code shouldBe "formula_ambiguous_extension"
            finding.message shouldBe
                "Several extensions are called `realmRouteFixtures`; write " +
                "`quests.realmRouteFixtures.FixtureLoot` or `typewritermc.realmRouteFixtures.FixtureLoot`"
            errorCodesOn(demo.named("full")).shouldBeEmpty()
            formulas.value(demo.named("full")) shouldBe true
        }
    }

    test("an unknown qualifier, and a type its extension does not declare, each give their own finding") {
        val page =
            setup("qualify-unknown") {
                formulaPage {
                    formula("unknown_extension", booleanUse, "nowhere.FixtureLoot() == nowhere.FixtureLoot()")
                    formula("unknown_typed", intUse, "let kept: nowhere.FixtureLoot? = null\n1")
                    formula("not_declared", booleanUse, "engineCore.FixtureLoot() == engineCore.FixtureLoot()")
                }
            }
        withSetup(page, catalog = routeFixtureCatalog) { demo ->
            settle()
            errorsOn(demo.named("unknown_extension")).first().message shouldBe "There is no extension `nowhere`"
            errorCodesOn(demo.named("unknown_extension")).distinct() shouldBe listOf("formula_unknown_extension")
            errorCodesOn(demo.named("unknown_typed")) shouldBe listOf("formula_unknown_extension")
            val missing = errorsOn(demo.named("not_declared")).first()
            missing.code shouldBe "formula_unknown_type"
            missing.message shouldBe "There is no type `FixtureLoot` in `engineCore`"
        }
    }

    test("a name in scope hides an extension qualifier of that name") {
        val page =
            setup("qualify-hidden") {
                formulaPage {
                    definition("realmRouteFixtures", intUse, 1)
                    formula("by_resource", intUse, "realmRouteFixtures.FixtureLoot")
                    formula("by_let", intUse, "let engineCore = 1\nengineCore.FixtureLoot")
                }
            }
        withSetup(page, catalog = routeFixtureCatalog) { demo ->
            errorCodesOn(demo.named("by_resource")) shouldBe listOf("formula_unknown_member")
            errorCodesOn(demo.named("by_let")) shouldBe listOf("formula_unknown_member")
        }
    }
}
