package com.typewritermc.realm.formula

import com.typewritermc.authoring.with
import com.typewritermc.realm.testing.BrokenDynamics
import com.typewritermc.realm.testing.UnlinkableDynamics
import com.typewritermc.realm.testing.allFindingCodes
import com.typewritermc.realm.testing.commit
import com.typewritermc.realm.testing.contentEvidence
import com.typewritermc.realm.testing.contentJudged
import com.typewritermc.realm.testing.createEntry
import com.typewritermc.realm.testing.entryRef
import com.typewritermc.realm.testing.errorCodesOn
import com.typewritermc.realm.testing.formulaChecksSince
import com.typewritermc.realm.testing.formulaLibrary
import com.typewritermc.realm.testing.formulaPage
import com.typewritermc.realm.testing.hookCatalog
import com.typewritermc.realm.testing.intUse
import com.typewritermc.realm.testing.listType
import com.typewritermc.realm.testing.meaningOf
import com.typewritermc.realm.testing.namingType
import com.typewritermc.realm.testing.record
import com.typewritermc.realm.testing.relinked
import com.typewritermc.realm.testing.rename
import com.typewritermc.realm.testing.rerunSince
import com.typewritermc.realm.testing.resources
import com.typewritermc.realm.testing.retitle
import com.typewritermc.realm.testing.settledFormulaChecks
import com.typewritermc.realm.testing.settledRuns
import com.typewritermc.realm.testing.shouldBeCommitted
import com.typewritermc.realm.testing.staticPage
import com.typewritermc.realm.testing.textUse
import com.typewritermc.realm.testing.withSetup
import com.typewritermc.setup.setup
import com.typewritermc.types.functionUse
import com.typewritermc.types.integer
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldBeEmpty
import io.kotest.matchers.collections.shouldContain
import io.kotest.matchers.collections.shouldNotContain
import io.kotest.matchers.shouldBe
import skirout.editor.v1.type_catalog.DataValue

val ScopeLookupTest by testSuite {
    val library =
        setup("scope-lookup") {
            formulaLibrary {
                book("main") {
                    page("first") {
                        smith("smith")
                        smith("own_smith")
                        smith("bystander")
                        definition("base_reward", intUse, 50)
                        formula("user", entryRef, "smith")
                        formula("pair_user", entryRef, "twin")
                        formula("with_own_scope", entryRef, "smith")
                        bound("bound_user", entryRef, "smith", mapOf("smith" to named("smith")))
                    }
                    page("second") {
                        smith("farmer")
                        smith("smith", key = "second_smith")
                        smith("twin", key = "twin_a")
                        smith("twin", key = "twin_b")
                    }
                }
                book("other") { page("elsewhere") { smith("stranger") } }
            }
        }
    val onePage =
        setup("scope-one-page") {
            formulaPage {
                smith("smith")
                definition("base_reward", intUse, 50)
                formula("naming", entryRef, "new_name")
                formula("other", intUse, "base_reward + 1")
                bound("bound_user", entryRef, "smith", mapOf("smith" to named("smith")))
            }
        }
    val catalog = hookCatalog()

    test("an element on the same page is in scope") {
        withSetup(library, catalog = catalog) { lib -> meaningOf(lib.named("user"), "bystander") shouldBe listOf(lib.named("bystander")) }
    }

    test("an element on another page of the book is in scope") {
        withSetup(library, catalog = catalog) { lib -> meaningOf(lib.named("user"), "farmer") shouldBe listOf(lib.named("farmer")) }
    }

    test("an element in another book is not in scope") {
        withSetup(library, catalog = catalog) { lib -> meaningOf(lib.named("user"), "stranger").shouldBeEmpty() }
    }

    test("the same page wins over another page") {
        withSetup(library, catalog = catalog) { lib -> meaningOf(lib.named("user"), "smith") shouldBe listOf(lib.named("smith")) }
    }

    test("two elements with one name on another page are ambiguous at the use site") {
        withSetup(library, catalog = catalog) { lib -> errorCodesOn(lib.named("pair_user")) shouldBe listOf("formula_ambiguous_name") }
    }

    test("two elements with one name stop being ambiguous when one is renamed") {
        withSetup(library, catalog = catalog) { lib ->
            commit(rename(lib.named("twin_b"), "single")).shouldBeCommitted()

            meaningOf(lib.named("pair_user"), "twin") shouldBe listOf(lib.named("twin_a"))
            errorCodesOn(lib.named("pair_user")) shouldNotContain "formula_ambiguous_name"
        }
    }

    test("an element's name is not a uniqueness rule, so both commit") {
        withSetup(staticPage, catalog = catalog) {
            commit(createEntry("smith")).shouldBeCommitted()
            commit(createEntry("smith")).shouldBeCommitted()
        }
    }

    test("a lambda parameter hides an element of that name") {
        val shadowed =
            setup("scope-lambda") {
                formulaPage {
                    smith("smith")
                    formula("doubled", listType(intUse), "[1, 2].map { smith -> smith * 2 }")
                }
            }
        withSetup(shadowed, catalog = catalog) { page -> errorCodesOn(page.named("doubled")).shouldBeEmpty() }
    }

    test("a function parameter hides an element of that name") {
        val shadowed =
            setup("scope-parameter") {
                formulaPage {
                    smith("smith")
                    formula("twice", functionUse(parameters = listOf("smith" to intUse), result = intUse), "smith * 2")
                }
            }
        withSetup(shadowed, catalog = catalog) { page -> errorCodesOn(page.named("twice")).shouldBeEmpty() }
    }

    test("a broken field on one element only drops that element from scope") {
        withSetup(library, catalog = catalog) { lib ->
            val broken = lib.named("bystander")
            saveByHand(mapOf(broken to record(broken).with("name", DataValue.integer(3))))

            meaningOf(lib.named("user"), "bystander").shouldBeEmpty()
            meaningOf(lib.named("user"), "smith") shouldBe listOf(lib.named("smith"))
            meaningOf(lib.named("user"), "farmer") shouldBe listOf(lib.named("farmer"))
        }
    }

    test("a name with exports gives the exported field's type") {
        withSetup(library, catalog = catalog) { lib -> namingType(lib.named("base_reward")) shouldBe intUse }
    }

    test("a hook on a parent contract runs for a subtype defined in another artifact") {
        // The library hooks register on Page, from the typewriter artifact; the page here is engine core's StaticPage.
        withSetup(library, catalog = catalog) { lib -> meaningOf(lib.named("user"), "own_smith") shouldBe listOf(lib.named("own_smith")) }
    }

    test("a field's own scope wins over its page") {
        withSetup(library, catalog = catalog) { lib ->
            meaningOf(lib.named("with_own_scope"), "smith") shouldBe listOf(lib.named("own_smith"))
        }
    }

    test("a resource without exports gives a Ref to its type") {
        withSetup(library, catalog = catalog) { lib -> namingType(lib.named("smith")) shouldBe entryRef }
    }

    test("renaming a book does not rerun checks that do not read its contents") {
        withSetup(library, catalog = catalog) { lib ->
            val formulas = settledFormulaChecks()
            val runs = settledRuns()
            commit(retitle(lib.named("main"), "Renamed")).shouldBeCommitted()

            formulaChecksSince(formulas).shouldBeEmpty()
            rerunSince(runs).resources() shouldNotContain lib.named("user")
        }
    }

    test("adding an unrelated field to a page reruns no formula check") {
        withSetup(onePage, catalog = catalog) { page ->
            val before = settledFormulaChecks()
            commit(rename(page.pageId, "renamed")).shouldBeCommitted()

            formulaChecksSince(before).shouldBeEmpty()
        }
    }

    test("adding a page element reruns only the formulas that name it") {
        withSetup(onePage, catalog = catalog) { page ->
            val before = settledFormulaChecks()
            commit(createEntry("new_name")).shouldBeCommitted()

            formulaChecksSince(before) shouldBe setOf(page.named("naming"))
        }
    }

    test("a formula with a stored reference does not rerun when an element of that name appears elsewhere") {
        withSetup(onePage, catalog = catalog) { page ->
            val before = settledFormulaChecks()
            commit(createEntry("smith")).shouldBeCommitted()

            formulaChecksSince(before) shouldNotContain page.named("bound_user")
        }
    }

    test("a hook that throws gives one finding on its resource, and other scopes keep working") {
        val hooked =
            setup("scope-throw") {
                formulaPage {
                    smith("throw")
                    smith("smith")
                    formula("user", entryRef, "smith")
                }
            }
        withSetup(hooked, catalog = catalog) { page ->
            errorCodesOn(page.named("throw")) shouldBe listOf("dynamic_failed")
            meaningOf(page.named("user"), "smith") shouldBe listOf(page.named("smith"))
        }
    }

    test("a provider whose register throws gives one finding, and other providers keep working") {
        withSetup(library, catalog = hookCatalog(BrokenDynamics)) { lib ->
            allFindingCodes().count { it == "dynamic_registration_failed" } shouldBe 1
            meaningOf(lib.named("user"), "smith") shouldBe listOf(lib.named("smith"))
            namingType(lib.named("base_reward")) shouldBe intUse
        }
    }

    test("a hook that throws a wrapped cancellation is not reported as a hook failure") {
        val hooked = setup("scope-cancel") { formulaPage { smith("cancel") } }
        withSetup(hooked, catalog = catalog) { page -> errorCodesOn(page.named("cancel")) shouldNotContain "dynamic_failed" }
    }

    test("a hook that recurses forever gives one hook failure finding, and other scopes keep working") {
        val hooked =
            setup("scope-recurse") {
                formulaPage {
                    smith("recurse")
                    smith("smith")
                    formula("user", entryRef, "smith")
                }
            }
        withSetup(hooked, catalog = catalog) { page ->
            errorCodesOn(page.named("recurse")) shouldBe listOf("dynamic_failed")
            meaningOf(page.named("user"), "smith") shouldBe listOf(page.named("smith"))
        }
    }

    test("a hook that throws NoClassDefFoundError gives one hook failure finding") {
        val hooked = setup("scope-linkage") { formulaPage { smith("linkage") } }
        withSetup(hooked, catalog = catalog) { page -> errorCodesOn(page.named("linkage")) shouldBe listOf("dynamic_failed") }
    }

    test("a dynamic provider whose register throws NoClassDefFoundError gives one registration finding") {
        withSetup(library, catalog = hookCatalog(UnlinkableDynamics)) { lib ->
            allFindingCodes().count { it == "dynamic_registration_failed" } shouldBe 1
            meaningOf(lib.named("user"), "smith") shouldBe listOf(lib.named("smith"))
        }
    }

    test("renaming a sibling element does not change a bound formula's evidence") {
        withSetup(library, catalog = catalog) { lib ->
            val before = contentEvidence(lib.named("bound_user"))
            commit(rename(lib.named("bystander"), "passerby")).shouldBeCommitted()

            contentEvidence(lib.named("bound_user")) shouldBe before
        }
    }

    test("a hook registered by definition id runs for every type argument of that resource") {
        val definitions =
            setup("scope-definitions") {
                formulaPage {
                    definition("count", intUse, 1)
                    definition("title", textUse, "hello")
                }
            }
        withSetup(definitions, catalog = catalog) { page ->
            namingType(page.named("count")) shouldBe intUse
            namingType(page.named("title")) shouldBe textUse
        }
    }

    test("a hook that selects with a predicate gives one scope in a pass and in a commit's binding") {
        // The commit's binding half arrives with the commit binder; a pass gives the selected resource alone its scope.
        withSetup(library, catalog = catalog) { lib ->
            meaningOf(lib.named("with_own_scope"), "smith") shouldBe listOf(lib.named("own_smith"))
            meaningOf(lib.named("user"), "smith") shouldBe listOf(lib.named("smith"))
        }
    }

    test("a resource with no formula, hook or misfit gets no finding set") {
        withSetup(onePage, catalog = catalog) { page ->
            val judged = contentJudged()
            judged shouldContain page.named("naming")
            judged shouldNotContain page.named("smith")
            judged shouldNotContain page.named("base_reward")
            judged shouldNotContain page.pageId
        }
    }

    test("a hand seeded ownership loop gives a finding and does not hang") {
        withSetup(onePage, catalog = catalog) { page ->
            val element = page.named("smith")
            saveByHand(mapOf(page.pageId to relinked(page.pageId, "book", element)))

            errorCodesOn(element) shouldContain "scope_loop"
        }
    }
}
