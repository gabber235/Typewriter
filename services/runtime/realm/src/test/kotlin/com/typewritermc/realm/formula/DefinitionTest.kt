package com.typewritermc.realm.formula

import com.typewritermc.authoring.Availability
import com.typewritermc.authoring.with
import com.typewritermc.engine.pages.Definition
import com.typewritermc.formula.Formula
import com.typewritermc.realm.authoring.location
import com.typewritermc.realm.operation.prepare
import com.typewritermc.realm.operation.refusalCodes
import com.typewritermc.realm.operation.shouldBeReady
import com.typewritermc.realm.routeFixtureCatalog
import com.typewritermc.realm.testing.RealmStorage
import com.typewritermc.realm.testing.caseValue
import com.typewritermc.realm.testing.commitPreparedTypeChange
import com.typewritermc.realm.testing.computed
import com.typewritermc.realm.testing.declares
import com.typewritermc.realm.testing.definitionDraft
import com.typewritermc.realm.testing.definitionOf
import com.typewritermc.realm.testing.definitionValueUse
import com.typewritermc.realm.testing.expectRefused
import com.typewritermc.realm.testing.fieldKey
import com.typewritermc.realm.testing.formulaPage
import com.typewritermc.realm.testing.intUse
import com.typewritermc.realm.testing.plain
import com.typewritermc.realm.testing.plainValueLocation
import com.typewritermc.realm.testing.previewTypeChange
import com.typewritermc.realm.testing.publicationBlockers
import com.typewritermc.realm.testing.publishToEngine
import com.typewritermc.realm.testing.readDraft
import com.typewritermc.realm.testing.record
import com.typewritermc.realm.testing.resolvedSchema
import com.typewritermc.realm.testing.setVar
import com.typewritermc.realm.testing.shouldBeCommitted
import com.typewritermc.realm.testing.shouldContainLocation
import com.typewritermc.realm.testing.stringUse
import com.typewritermc.realm.testing.typeArgumentOf
import com.typewritermc.realm.testing.value
import com.typewritermc.realm.testing.varValue
import com.typewritermc.realm.testing.withSetup
import com.typewritermc.setup.setup
import com.typewritermc.types.functionUse
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldBeEmpty
import io.kotest.matchers.collections.shouldContain
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import skirout.editor.v1.authoring.EditIntent
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.TypeSelection

val DefinitionTest by testSuite {
    val definitions =
        setup("definitions") {
            formulaPage {
                definition("base_reward", intUse, 50)
                formula("bonus", functionUse(parameters = listOf("level" to intUse), result = intUse), "level * 2")
                formula("total", intUse, "base_reward + bonus(10)")
            }
        }

    test("a Definition of Int with a plain value commits") {
        withSetup(definitions, catalog = routeFixtureCatalog) { page ->
            varValue(page.baseReward) shouldBe plain(50)
        }
    }

    test("a plain value of the wrong type is refused") {
        withSetup(definitions, catalog = routeFixtureCatalog) { page ->
            expectRefused(setVar(page.baseReward, stringUse, plain("fifty"))).map { it.location } shouldContain
                location(page.baseReward, "value")
        }
    }

    test("a Definition of a function type stores its body as a Formula") {
        withSetup(definitions, catalog = routeFixtureCatalog) { page ->
            varValue(page.bonus) shouldBe plain(Formula("level * 2"))
            value(page.bonus, "value", "value", "source") shouldBe DataValue.StringValueWrapper("level * 2")
        }
    }

    test("a Definition with no value blocks publish, like any required field") {
        withSetup(definitions, catalog = routeFixtureCatalog) { page ->
            commit(EditIntent.createSetValue(at = location(page.baseReward, "value"), value = DataValue.UNFILLED)).shouldBeCommitted()
            publicationBlockers() shouldContainLocation page.baseReward
        }
    }

    test("previewing Int to String shows the plain value will clear") {
        withSetup(definitions, catalog = routeFixtureCatalog) { page ->
            previewTypeChange(page.baseReward, to = stringUse).shouldBeReady().clearedLocations shouldContain
                plainValueLocation(page.baseReward)
        }
    }

    test("previewing a type change keeps a formula") {
        withSetup(definitions, catalog = routeFixtureCatalog) { page ->
            previewTypeChange(page.total, to = stringUse).shouldBeReady().clearedLocations.shouldBeEmpty()
            val before = varValue(page.total)
            commitPreparedTypeChange(page.total, to = stringUse).shouldBeCommitted()
            varValue(page.total) shouldBe before
        }
    }

    test("a preview after someone else's commit is refused as stale") {
        withSetup(definitions, catalog = routeFixtureCatalog) { page ->
            val preview = previewTypeChange(page.baseReward, to = stringUse).shouldBeReady()
            commit(setVar(page.baseReward, intUse, computed("60"))).shouldBeCommitted()
            prepare(preview).refusalCodes() shouldBe listOf("expectation_conflict")
        }
    }

    test("a Definition keeps its type argument across a realm restart") {
        withSetup(definitions, storage = RealmStorage.Surreal, catalog = routeFixtureCatalog) { page ->
            restart()
            record(page.baseReward).configuration shouldBe TypeSelection.CompleteWrapper(definitionOf(intUse))
            varValue(page.baseReward) shouldBe plain(50)
        }
    }

    test("publishing a page of Definitions still compiles, and the engine stores it unchanged") {
        withSetup(definitions, catalog = routeFixtureCatalog) { page ->
            val engine = publishToEngine()
            engine.getValue(page.baseReward).shouldBeInstanceOf<Definition<*>>().value shouldBe plain(50)
            engine.getValue(page.total).shouldBeInstanceOf<Definition<*>>().value shouldBe varValue(page.total)
        }
    }

    test("the draft of a Definition reads a Var of the wrong type as Failed and its other fields as written") {
        withSetup(definitions, catalog = routeFixtureCatalog) { page ->
            val broken = record(page.baseReward).with("value", encoder.encode(definitionValueUse(stringUse), plain("fifty")))
            readDraft(page.baseReward, broken, definitionDraft<Int>(intUse)) { draft ->
                draft.value.shouldBeInstanceOf<Availability.Failed>()
                draft.name shouldBe Availability.Available("base_reward")
            }
        }
    }

    val customTypes =
        setup("custom-types") {
            formulaPage {
                customType("Reward") { field("gold", intUse) }
                definition(
                    "door",
                    declares {
                        union {
                            case("Open")
                            case("Closed")
                        }
                    },
                ) { caseValue(it, "Open") }
            }
        }

    test("a formula page seeds a custom type with the fields it declares") {
        withSetup(customTypes, catalog = routeFixtureCatalog) { page ->
            resolvedSchema(fieldKey(page.reward)).schema.fields.map { it.key to it.type } shouldBe listOf("gold" to intUse)
        }
    }

    test("a formula page seeds an inline union value") {
        withSetup(customTypes, catalog = routeFixtureCatalog) { page ->
            val door = typeArgumentOf(page.door)
            resolvedSchema(door)
            value(page.door, "value", "value") shouldBe caseValue(door, "Open")
        }
    }
}
