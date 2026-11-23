package com.typewritermc.realm.checking

import com.typewritermc.engine.pages.StaticPageDefinition
import com.typewritermc.loader.api.RuntimePlacement
import com.typewritermc.loader.api.SourcePartDisposition
import com.typewritermc.realm.routeFixtureCatalog
import com.typewritermc.realm.testing.EnginePart
import com.typewritermc.realm.testing.engines
import com.typewritermc.realm.testing.formulaPage
import com.typewritermc.realm.testing.intUse
import com.typewritermc.realm.testing.publicationBlockers
import com.typewritermc.realm.testing.rerunSince
import com.typewritermc.realm.testing.resources
import com.typewritermc.realm.testing.settledRuns
import com.typewritermc.realm.testing.warningsOn
import com.typewritermc.realm.testing.withSetup
import com.typewritermc.setup.setup
import com.typewritermc.testing.routes.FixtureStaticEntryDefinition
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldBeEmpty
import io.kotest.matchers.collections.shouldNotBeEmpty
import io.kotest.matchers.shouldBe

val EngineCoverageTest by testSuite {
    val page = setup("engine-coverage") { formulaPage { smith() } }
    val entry = FixtureStaticEntryDefinition.id
    val noVault = SourcePartDisposition.Ineligible(listOf("needs the Vault plugin"))
    val runs = SourcePartDisposition.Eligible(setOf(RuntimePlacement.PRIMARY_ENGINE))

    test("an entry whose handling part runs on no engine has a warning saying what it needs") {
        withSetup(page, catalog = routeFixtureCatalog) { demo ->
            engines(EnginePart("vault", listOf(entry), noVault))

            warningsOn(demo.smith) shouldBe listOf("No engine runs Fixture static entry: it needs the Vault plugin.")
        }
    }

    test("an entry whose handling parts all run on no engine has a warning with every need") {
        withSetup(page, catalog = routeFixtureCatalog) { demo ->
            engines(
                EnginePart("vault", listOf(entry), noVault),
                EnginePart("economy", listOf(entry), SourcePartDisposition.Ineligible(listOf("needs the Economy plugin"))),
            )

            warningsOn(demo.smith) shouldBe
                listOf("No engine runs Fixture static entry: it needs the Vault plugin; needs the Economy plugin.")
        }
    }

    test("an entry no engine runs does not block publication") {
        withSetup(page, catalog = routeFixtureCatalog) { demo ->
            engines(EnginePart("vault", listOf(entry), noVault))

            publicationBlockers().filter { it.primary?.resource == demo.smith }.shouldBeEmpty()
        }
    }

    test("an entry one engine runs has no warning") {
        withSetup(page, catalog = routeFixtureCatalog) { demo ->
            engines(EnginePart("vault", listOf(entry), noVault), EnginePart("economy", listOf(entry), runs))

            warningsOn(demo.smith).shouldBeEmpty()
        }
    }

    test("an entry no part handles has no warning") {
        withSetup(page, catalog = routeFixtureCatalog) { demo ->
            engines(EnginePart("vault", listOf(StaticPageDefinition.id), noVault))

            warningsOn(demo.smith).shouldBeEmpty()
        }
    }

    test("the warning clears once an engine runs the entry") {
        withSetup(page, catalog = routeFixtureCatalog) { demo ->
            engines(EnginePart("vault", listOf(entry), noVault))
            warningsOn(demo.smith).shouldNotBeEmpty()
            engines(EnginePart("vault", listOf(entry), runs))

            warningsOn(demo.smith).shouldBeEmpty()
        }
    }

    test("a change in what the engines run reruns only the checks of entries it is about") {
        val withFormula =
            setup("engine-coverage-reruns") {
                formulaPage {
                    smith()
                    formula("total", intUse, "1 + 1")
                }
            }
        withSetup(withFormula, catalog = routeFixtureCatalog) { demo ->
            val before = settledRuns()
            engines(EnginePart("vault", listOf(entry), noVault))

            rerunSince(before).resources() shouldBe setOf(demo.smith)
        }
    }
}
