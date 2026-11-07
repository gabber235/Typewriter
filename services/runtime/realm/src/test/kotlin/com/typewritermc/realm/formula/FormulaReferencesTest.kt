package com.typewritermc.realm.formula

import com.typewritermc.authoring.SubmissionKey
import com.typewritermc.authoring.field
import com.typewritermc.authoring.of
import com.typewritermc.authoring.root
import com.typewritermc.formula.Formula
import com.typewritermc.formula.TextSpan
import com.typewritermc.realm.testing.CountedHook
import com.typewritermc.realm.testing.HookGate
import com.typewritermc.realm.testing.commit
import com.typewritermc.realm.testing.commitDefinition
import com.typewritermc.realm.testing.commitRecordUser
import com.typewritermc.realm.testing.commitTypeDefinition
import com.typewritermc.realm.testing.computedVar
import com.typewritermc.realm.testing.createEntry
import com.typewritermc.realm.testing.declares
import com.typewritermc.realm.testing.delete
import com.typewritermc.realm.testing.demoOneDefinitions
import com.typewritermc.realm.testing.demoTwoDefinitions
import com.typewritermc.realm.testing.displayOf
import com.typewritermc.realm.testing.duplicate
import com.typewritermc.realm.testing.elementNamed
import com.typewritermc.realm.testing.entryRef
import com.typewritermc.realm.testing.errorCodesOn
import com.typewritermc.realm.testing.errorsOn
import com.typewritermc.realm.testing.formulaLibrary
import com.typewritermc.realm.testing.formulaPage
import com.typewritermc.realm.testing.hookCatalog
import com.typewritermc.realm.testing.intUse
import com.typewritermc.realm.testing.listType
import com.typewritermc.realm.testing.openCatalogLeases
import com.typewritermc.realm.testing.plainType
import com.typewritermc.realm.testing.publicationBlockers
import com.typewritermc.realm.testing.record
import com.typewritermc.realm.testing.referenceTargets
import com.typewritermc.realm.testing.references
import com.typewritermc.realm.testing.rename
import com.typewritermc.realm.testing.retitle
import com.typewritermc.realm.testing.sendDefinition
import com.typewritermc.realm.testing.setFormula
import com.typewritermc.realm.testing.setTypes
import com.typewritermc.realm.testing.settle
import com.typewritermc.realm.testing.shouldBeCommitted
import com.typewritermc.realm.testing.shouldBeRejected
import com.typewritermc.realm.testing.shouldContainLocation
import com.typewritermc.realm.testing.spannedComputedVar
import com.typewritermc.realm.testing.storedSource
import com.typewritermc.realm.testing.textUse
import com.typewritermc.realm.testing.usagesOf
import com.typewritermc.realm.testing.withSetup
import com.typewritermc.setup.setup
import com.typewritermc.types.FORMULA_USE
import com.typewritermc.types.functionUse
import com.typewritermc.types.integer
import com.typewritermc.types.toResourceId
import com.typewritermc.types.toSkir
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.nondeterministic.eventually
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.collections.shouldBeEmpty
import io.kotest.matchers.collections.shouldContain
import io.kotest.matchers.collections.shouldNotContain
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldContain
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import skirout.editor.v1.authoring.CommitPreparedEditResponse
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.type_catalog.ValuePath
import skirout.kernel.v1.resource_id.ResourceId
import kotlin.time.Duration.Companion.seconds

val FormulaReferencesTest by testSuite {
    val page =
        setup("references") {
            formulaPage {
                smith()
                smith("counted")
                demoOneDefinitions()
                definition("other_value", intUse, 7)
                formula("broken", entryRef, "missing_name")
                formula("pair_user", entryRef, "twin")
                smith("twin", key = "twin_a")
                smith("twin", key = "twin_b")
                formula("counted_user", textUse, "counted.name")
            }
        }
    val catalog = hookCatalog()

    test("saving formula text fills a reference for each content name, at its span") {
        withSetup(page, catalog = catalog) { demo ->
            references(demo.total) shouldBe listOf(TextSpan(0, 11) to demo.baseReward, TextSpan(14, 19) to demo.bonus)
        }
    }

    test("local names, provider functions and catalog types get no reference") {
        withSetup(page, catalog = catalog) { demo ->
            val local = commitDefinition("local", plainType(intUse)) { computedVar(it.use, "let n: Int = 2\nn + base_reward") }.created()
            val provided = commitDefinition("provided", plainType(listType(intUse))) { computedVar(it.use, "emptyList()") }.created()

            references(local) shouldBe listOf(TextSpan(19, 30) to demo.baseReward)
            references(provided).shouldBeEmpty()
        }
    }

    test("a lambda parameter with an element's name gets no reference") {
        withSetup(page, catalog = catalog) {
            val doubled =
                commitDefinition("doubled", plainType(listType(intUse))) {
                    computedVar(it.use, "[1, 2].map { smith -> smith * 2 }")
                }.created()

            references(doubled).shouldBeEmpty()
            errorCodesOn(doubled).shouldBeEmpty()
        }
    }

    test("a function parameter with an element's name gets no reference and reads the parameter") {
        val shadowed =
            setup("references-parameter") {
                formulaPage {
                    smith()
                    formula("twice", functionUse(parameters = listOf("smith" to intUse), result = intUse), "smith * 2")
                }
            }
        withSetup(shadowed, catalog = catalog) { demo ->
            references(demo.named("twice")).shouldBeEmpty()
            errorCodesOn(demo.named("twice")).shouldBeEmpty()
        }
    }

    test("a case name against its expected union gets no reference, even with an element of that name") {
        val cases =
            setup("references-cases") {
                formulaPage {
                    smith()
                    smith("Open")
                    demoOneDefinitions()
                    demoTwoDefinitions()
                    formula("door_number", intUse, "when (door) { is Open -> 1\n is Closed -> 2 }")
                }
            }
        withSetup(cases, catalog = catalog) { demo ->
            referenceTargets(demo.named("door_number")) shouldBe listOf(demo.door)
            errorCodesOn(demo.named("door_number")).shouldBeEmpty()
        }
    }

    test("renaming a target writes nothing to the formula") {
        withSetup(page, catalog = catalog) { demo ->
            val before = record(demo.total)
            commit(rename(demo.baseReward, "starting_reward")).shouldBeCommitted()

            record(demo.total) shouldBe before
        }
    }

    test("after a rename the display text shows the new name") {
        withSetup(page, catalog = catalog) { demo ->
            commit(rename(demo.baseReward, "starting_reward")).shouldBeCommitted()

            displayOf(demo.total) shouldBe "starting_reward + bonus(10)"
        }
    }

    test("display text keeps spans right when a name changes length") {
        withSetup(page, catalog = catalog) { demo ->
            commit(rename(demo.bonus, "b"), rename(demo.baseReward, "the starting reward")).shouldBeCommitted()

            displayOf(demo.total) shouldBe "`the starting reward` + b(10)"
        }
    }

    test("deleting a target empties the reference and keeps the old name in the text") {
        withSetup(page, catalog = catalog) { demo ->
            commit(delete(demo.baseReward)).shouldBeCommitted()

            references(demo.total) shouldBe listOf(TextSpan(0, 11) to null, TextSpan(14, 19) to demo.bonus)
            displayOf(demo.total) shouldBe "base_reward + bonus(10)"
        }
    }

    test("a rename and then a delete shows and reports the last name") {
        withSetup(page, catalog = catalog) { demo ->
            commit(rename(demo.baseReward, "starting_reward")).shouldBeCommitted()
            commit(delete(demo.baseReward)).shouldBeCommitted()

            displayOf(demo.total) shouldBe "starting_reward + bonus(10)"
            settle()
            errorsOn(demo.total).single().message shouldContain "starting_reward"
        }
    }

    test("creating the last name after a rename and a delete binds it") {
        withSetup(page, catalog = catalog) { demo ->
            commit(rename(demo.baseReward, "starting_reward")).shouldBeCommitted()
            commit(delete(demo.baseReward)).shouldBeCommitted()
            val replacement = commitDefinition("starting_reward", plainType(intUse)).created()

            references(demo.total) shouldBe listOf(TextSpan(0, 15) to replacement, TextSpan(18, 23) to demo.bonus)
        }
    }

    test("a rename writes nothing, and only the delete that empties a reference seals the text") {
        withSetup(page, catalog = catalog) { demo ->
            commit(rename(demo.baseReward, "starting_reward")).shouldBeCommitted()
            storedSource(demo.total) shouldBe "base_reward + bonus(10)"

            commit(delete(demo.baseReward)).shouldBeCommitted()
            storedSource(demo.total) shouldBe "starting_reward + bonus(10)"
        }
    }

    test("a commit that rewrites a formula and deletes a target of its old text keeps the new text") {
        withSetup(page, catalog = catalog) { demo ->
            commit(setFormula(demo.total, "bonus(3)"), delete(demo.baseReward)).shouldBeCommitted()

            storedSource(demo.total) shouldBe "bonus(3)"
            references(demo.total) shouldBe listOf(TextSpan(0, 5) to demo.bonus)
        }
    }

    test("a reference a client sends in the same commit as a delete of another target is ignored") {
        withSetup(page, catalog = catalog) { demo ->
            val forged = listOf(TextSpan(0, 11) to demo.smith, TextSpan(14, 19) to demo.bonus)
            commit(setFormula(demo.total, "base_reward + bonus(10)", forged), delete(demo.bonus)).shouldBeCommitted()

            references(demo.total) shouldBe listOf(TextSpan(0, 11) to demo.baseReward, TextSpan(14, 19) to null)
        }
    }

    test("duplicating a page with a formula commits, and the copy reads the copied element") {
        withSetup(page, catalog = catalog) { demo ->
            val copy = duplicate(demo.pageId)

            referenceTargets(elementNamed(copy, "total")) shouldBe listOf(elementNamed(copy, "base_reward"), elementNamed(copy, "bonus"))
        }
    }

    test("duplicating after a rename of the target keeps the formula working") {
        withSetup(page, catalog = catalog) { demo ->
            commit(rename(demo.baseReward, "starting_reward")).shouldBeCommitted()
            val copy = duplicate(demo.total)

            errorCodesOn(copy).shouldBeEmpty()
            displayOf(copy) shouldBe "starting_reward + bonus(10)"
        }
    }

    test("a rename and a duplicate in one operation keep the formula working") {
        withSetup(page, catalog = catalog) { demo ->
            lateinit var copy: ResourceId
            operate(listOf(demo.total)) {
                checkedSet(ValueLocation.of(demo.baseReward, ValuePath.root.field("name")), DataValue.StringValueWrapper("starting_reward"))
                copy = duplicate(listOf(demo.total.toResourceId())).single().toSkir()
            }.shouldBeCommitted()

            errorCodesOn(copy).shouldBeEmpty()
            displayOf(copy) shouldBe "starting_reward + bonus(10)"
        }
    }

    test("duplicating an element whose target stays behind keeps reading that target") {
        withSetup(page, catalog = catalog) { demo ->
            referenceTargets(duplicate(demo.total)) shouldBe listOf(demo.baseReward, demo.bonus)
        }
    }

    test("references on a new record keep only spans inside its text and targets that exist") {
        withSetup(page, catalog = catalog) { demo ->
            val sent =
                listOf(
                    TextSpan(0, 11) to demo.baseReward,
                    TextSpan(14, 15) to ResourceId(value = "no-such-resource"),
                    TextSpan(20, 25) to demo.bonus,
                )
            val created = sendDefinition("sent", plainType(intUse)) { spannedComputedVar(it.use, "base_reward + 1", sent) }.created()

            references(created) shouldBe listOf(TextSpan(0, 11) to demo.baseReward)
        }
    }

    test("a new record with text and no references binds fresh") {
        withSetup(page, catalog = catalog) { demo ->
            val created = commitDefinition("fresh", plainType(intUse)) { computedVar(it.use, "base_reward * 2") }.created()

            references(created) shouldBe listOf(TextSpan(0, 11) to demo.baseReward)
        }
    }

    test("a name from an extension hook is the name display shows") {
        val hooked =
            setup("references-hooked") {
                formulaPage {
                    smith("own_smith")
                    formula("with_own_scope", entryRef, "smith")
                }
            }
        withSetup(hooked, catalog = catalog) { demo ->
            referenceTargets(demo.named("with_own_scope")) shouldBe listOf(demo.named("own_smith"))
            displayOf(demo.named("with_own_scope")) shouldBe "smith"
        }
    }

    test("a target moved out of scope keeps its reference and the text it covers") {
        val library =
            setup("references-library") {
                formulaLibrary {
                    book("main") { page("first") { demoOneDefinitions() } }
                    book("other") { page("elsewhere") { smith("stranger") } }
                }
            }
        withSetup(library, catalog = catalog) { lib ->
            operate(listOf(lib.baseReward)) { move(listOf(lib.baseReward.toResourceId()), lib.named("elsewhere").toResourceId(), null) }
                .shouldBeCommitted()
            commit(rename(lib.baseReward, "far_away")).shouldBeCommitted()

            referenceTargets(lib.total) shouldContain lib.baseReward
            displayOf(lib.total) shouldBe "base_reward + bonus(10)"
        }
    }

    test("deleting a target gives one finding naming it, and blocks publish") {
        withSetup(page, catalog = catalog) { demo ->
            commit(delete(demo.baseReward)).shouldBeCommitted()
            settle()

            errorsOn(demo.total).single().message shouldContain "base_reward"
            publicationBlockers() shouldContainLocation demo.total
        }
    }

    test("a name used twice and deleted gives one finding, and its emptied references stay stored") {
        withSetup(page, catalog = catalog) { demo ->
            val twice = commitDefinition("twice", plainType(intUse)) { computedVar(it.use, "base_reward + base_reward") }.created()
            commit(delete(demo.baseReward)).shouldBeCommitted()

            errorCodesOn(twice) shouldBe listOf("formula_deleted_reference")
            references(twice) shouldBe listOf(TextSpan(0, 11) to null, TextSpan(14, 25) to null)
        }
    }

    test("a later commit that resolves nothing writes nothing to a formula with an emptied reference") {
        withSetup(page, catalog = catalog) { demo ->
            commit(delete(demo.baseReward)).shouldBeCommitted()
            val before = record(demo.total)
            commit(createEntry("unrelated")).shouldBeCommitted()

            record(demo.total) shouldBe before
        }
    }

    test("the target lists the formula's holder as a usage") {
        withSetup(page, catalog = catalog) { demo -> usagesOf(demo.baseReward) shouldContain demo.total }
    }

    test("a name that resolves to nothing gets no link and an unknown name error") {
        withSetup(page, catalog = catalog) { demo ->
            references(demo.named("broken")).shouldBeEmpty()
            errorCodesOn(demo.named("broken")) shouldBe listOf("formula_unknown_name")
        }
    }

    test("creating the missing target binds the broken formula by itself") {
        withSetup(page, catalog = catalog) { demo ->
            val created = createEntry("missing_name")
            commit(created).shouldBeCommitted()

            referenceTargets(demo.named("broken")) shouldBe listOf(created.id)
            errorCodesOn(demo.named("broken")).shouldBeEmpty()
        }
    }

    test("renaming something to the missing name binds the broken formula") {
        withSetup(page, catalog = catalog) { demo ->
            commit(rename(demo.smith, "missing_name")).shouldBeCommitted()

            referenceTargets(demo.named("broken")) shouldBe listOf(demo.smith)
        }
    }

    test("a new target with a deleted name binds the emptied reference") {
        withSetup(page, catalog = catalog) { demo ->
            val user = commitDefinition("user", plainType(entryRef)) { computedVar(it.use, "smith") }.created()
            commit(delete(demo.smith)).shouldBeCommitted()
            val replacement = createEntry("smith")
            commit(replacement).shouldBeCommitted()

            references(user) shouldBe listOf(TextSpan(0, 5) to replacement.id)
            errorCodesOn(user).shouldBeEmpty()
        }
    }

    test("a name with two matches gets no link and stays an ambiguity error") {
        withSetup(page, catalog = catalog) { demo ->
            references(demo.named("pair_user")).shouldBeEmpty()
            errorCodesOn(demo.named("pair_user")) shouldBe listOf("formula_ambiguous_name")
        }
    }

    test("renaming one of the two matches binds the name") {
        withSetup(page, catalog = catalog) { demo ->
            commit(rename(demo.named("twin_b"), "single")).shouldBeCommitted()

            referenceTargets(demo.named("pair_user")) shouldBe listOf(demo.named("twin_a"))
        }
    }

    test("a commit that makes no name resolve writes nothing to other formulas") {
        withSetup(page, catalog = catalog) { demo ->
            val before = record(demo.named("broken"))
            commit(createEntry("unrelated")).shouldBeCommitted()

            record(demo.named("broken")) shouldBe before
        }
    }

    test("a working formula is never written, even if a new element would shadow its name") {
        withSetup(page, catalog = catalog) { demo ->
            val before = record(demo.total)
            commit(createEntry("base_reward")).shouldBeCommitted()

            record(demo.total) shouldBe before
        }
    }

    test("a new element named like a provider function writes nothing into a working formula") {
        withSetup(page, catalog = catalog) {
            val provided = commitDefinition("provided", plainType(listType(intUse))) { computedVar(it.use, "emptyList()") }.created()
            val before = record(provided)
            commit(createEntry("emptyList")).shouldBeCommitted()

            record(provided) shouldBe before
        }
    }

    test("a function typed body's names bind the same way") {
        val bodies =
            setup("references-body") {
                formulaPage {
                    definition("base_reward", intUse, 50)
                    formula("scaled", functionUse(parameters = listOf("level" to intUse), result = intUse), "level * base_reward")
                }
            }
        withSetup(bodies, catalog = catalog) { demo ->
            references(demo.named("scaled")) shouldBe listOf(TextSpan(8, 19) to demo.baseReward)
        }
    }

    test("editing the text replaces the references for that formula, keeping a span but changing the name too") {
        withSetup(page, catalog = catalog) { demo ->
            commit(setFormula(demo.total, "other_value + bonus(10)")).shouldBeCommitted()

            references(demo.total) shouldBe listOf(TextSpan(0, 11) to demo.named("other_value"), TextSpan(14, 19) to demo.bonus)
        }
    }

    test("references a client sends are ignored, with text unchanged and with text changed") {
        withSetup(page, catalog = catalog) { demo ->
            val forged = listOf(TextSpan(0, 11) to demo.smith)
            commit(setFormula(demo.total, "base_reward + bonus(10)", forged)).shouldBeCommitted()
            references(demo.total) shouldBe listOf(TextSpan(0, 11) to demo.baseReward, TextSpan(14, 19) to demo.bonus)

            commit(setFormula(demo.total, "base_reward + 1", forged)).shouldBeCommitted()
            references(demo.total) shouldBe listOf(TextSpan(0, 11) to demo.baseReward)
        }
    }

    test("a binding and the edit that caused it are one atomic commit") {
        withSetup(page, catalog = catalog) { demo ->
            val created = createEntry("missing_name")
            val reply = commit(created).shouldBeCommitted()

            val broken = demo.named("broken")
            reply.resources.single { it.id == broken }.content shouldBe record(broken)
            reply.resources.map { it.id } shouldContain created.id
            referenceTargets(broken) shouldBe listOf(created.id)
        }
    }

    test("a resent commit binds once") {
        withSetup(page, catalog = catalog) { demo ->
            val created = createEntry("missing_name")
            val key = SubmissionKey("resent")
            commit(created.edit, key).shouldBeCommitted()
            val first = record(demo.named("broken"))
            commit(created.edit, key).shouldBeCommitted()

            record(demo.named("broken")) shouldBe first
            referenceTargets(demo.named("broken")) shouldBe listOf(created.id)
        }
    }

    test("a rejected edit binds nothing") {
        withSetup(page, catalog = catalog) { demo ->
            val before = record(demo.named("broken"))
            val created = createEntry("missing_name")
            commit(prepare(created.edit.intents + delete(ResourceId(value = "absent")))).shouldBeRejected("resource_missing")

            record(demo.named("broken")) shouldBe before
        }
    }

    test("a commit with no broken formula and no formula edit runs no binding") {
        val working =
            setup("references-working") {
                formulaPage {
                    smith("counted")
                    formula("counted_user", textUse, "counted.name")
                }
            }
        withSetup(working, catalog = catalog) { demo ->
            settle()
            val runs = CountedHook.runs.get()
            commit(rename(demo.pageId, "renamed")).shouldBeCommitted()
            settle()

            CountedHook.runs.get() shouldBe runs
        }
    }

    test("a commit on an unrelated resource with a broken formula saved forks nothing and runs no hook") {
        withSetup(page, catalog = catalog) { demo ->
            val reader = commitDefinition("reader", plainType(textUse)) { computedVar(it.use, "counted.name + missing_name") }.created()
            settle()
            referenceTargets(reader) shouldBe listOf(demo.named("counted"))
            val runs = CountedHook.runs.get()
            commit(rename(demo.pageId, "renamed")).shouldBeCommitted()
            settle()

            CountedHook.runs.get() shouldBe runs
        }
    }

    test("a broken formula on a resource whose type is missing does not refuse someone else's edit") {
        withSetup(page, catalog = catalog) {
            val holder = commitTypeDefinition("Holder", declares { record { field("count", functionUse(result = intUse)) } }).created()
            commitRecordUser("holder", holder, "count" to encoder.encode(FORMULA_USE.use, Formula("missing_name")))
            commit(delete(holder)).shouldBeCommitted()

            commit(createEntry("missing_name")).shouldBeCommitted()
        }
    }

    test("a holder whose plain value no longer fits does not refuse someone else's edit that binds its formula") {
        withSetup(page, catalog = catalog) {
            val holderType =
                commitTypeDefinition(
                    "Holder",
                    declares {
                        record {
                            field("gold", intUse)
                            field("count", functionUse(result = entryRef))
                        }
                    },
                ).created()
            val holder =
                commitRecordUser(
                    "holder",
                    holderType,
                    "gold" to DataValue.integer(1),
                    "count" to encoder.encode(FORMULA_USE.use, Formula("missing_name")),
                )
            val asText =
                declares {
                    record("k1") {
                        field("gold", textUse)
                        field("count", functionUse(result = entryRef))
                    }
                }
            commit(setTypes(holderType, asText)).shouldBeCommitted()
            errorCodesOn(holder) shouldContain "value_mismatch"
            val created = createEntry("missing_name")
            commit(created).shouldBeCommitted()

            referenceTargets(holder) shouldBe listOf(created.id)
        }
    }

    test("a binder failure commits the edit, keeps no client reference, and releases its lease") {
        withSetup(page, catalog = catalog) { demo ->
            val openLeases = openCatalogLeases()
            val before = openLeases()
            failNextRepair(IllegalStateException("The binder broke."))
            commit(setFormula(demo.total, "base_reward + 1", listOf(TextSpan(0, 11) to demo.baseReward))).shouldBeCommitted()

            storedSource(demo.total) shouldBe "base_reward + 1"
            references(demo.total).shouldBeEmpty()
            openLeases() shouldBe before
        }
    }

    test("a commit whose follow up writes fail still saves the edit, and later commits work") {
        withSetup(page, catalog = catalog) { demo ->
            failNextRepair(IllegalStateException("The follow up writes broke."), afterBinding = true)
            val created = createEntry("missing_name")
            commit(created).shouldBeCommitted()
            resources.keys shouldContain created.id

            commit(rename(demo.smith, "blacksmith")).shouldBeCommitted()
            referenceTargets(demo.named("broken")) shouldBe listOf(created.id)
        }
    }

    test("a hook that recurses forever during a commit commits the edit, gives its finding, and leaves no lease open") {
        withSetup(page, catalog = catalog) { demo ->
            val openLeases = openCatalogLeases()
            val before = openLeases()
            val recurse = createEntry("recurse")
            commit(prepare(recurse.edit.intents + setFormula(demo.named("broken"), "recurse"))).shouldBeCommitted()

            referenceTargets(demo.named("broken")) shouldBe listOf(recurse.id)
            errorCodesOn(recurse.id) shouldBe listOf("dynamic_failed")
            openLeases() shouldBe before
        }
    }

    test("after a binder failure, the next unrelated commit binds the name") {
        withSetup(page, catalog = catalog) { demo ->
            failNextRepair(IllegalStateException("The binder broke."))
            val created = createEntry("missing_name")
            commit(created).shouldBeCommitted()
            references(demo.named("broken")).shouldBeEmpty()

            commit(rename(demo.pageId, "renamed")).shouldBeCommitted()
            referenceTargets(demo.named("broken")) shouldBe listOf(created.id)
        }
    }

    test("a rejected repair leaves a log line naming its problems, and the edit commits") {
        withSetup(page, catalog = catalog) {
            val ghostly = commitDefinition("ghost_scope", plainType(entryRef)) { computedVar(it.use, "ghost") }.created()

            references(ghostly).shouldBeEmpty()
            logLines().single { "Repairs rejected" in it } shouldContain "target_resource_missing"
        }
    }

    test("a cancellation during binding is not treated as a binder failure, and releases its lease") {
        withSetup(page, catalog = catalog) { demo ->
            val openLeases = openCatalogLeases()
            val before = openLeases()
            val saved = record(demo.named("broken"))
            val gated = createEntry("gated")
            val gate = HookGate.arm()
            withContext(Dispatchers.Default) {
                val committing =
                    async(Dispatchers.Default) { commit(prepare(gated.edit.intents + setFormula(demo.named("broken"), "gated"))) }
                gate.awaitHeld()
                committing.cancel()
                gate.release()
                shouldThrow<CancellationException> { committing.await() }
            }

            record(demo.named("broken")) shouldBe saved
            resources.keys shouldNotContain gated.id
            logLines().filter { "Repairs skipped" in it }.shouldBeEmpty()
            openLeases() shouldBe before
        }
    }

    test("a reader is not blocked while a commit runs a slow hook") {
        withSetup(page, catalog = catalog) { demo ->
            val gated = createEntry("gated")
            val gate = HookGate.arm()
            withContext(Dispatchers.Default) {
                val committing =
                    async(Dispatchers.Default) { commit(prepare(gated.edit.intents + setFormula(demo.named("broken"), "gated"))) }
                gate.awaitHeld()

                resources.keys shouldContain demo.total
                gate.release()
                committing.await().shouldBeCommitted()
            }
        }
    }

    test("a hook slower than a second leaves a log line naming the commit and its edited resources, and the commit completes") {
        withSetup(page, catalog = catalog) { demo ->
            val gated = createEntry("gated")
            val gate = HookGate.arm()
            withContext(Dispatchers.Default) {
                val committing =
                    async(Dispatchers.Default) {
                        commit(prepare(gated.edit.intents + setFormula(demo.named("broken"), "gated")), SubmissionKey("slow-commit"))
                    }
                gate.awaitHeld()
                val line = eventually(5.seconds) { logLines().single { "slow-commit" in it } }
                gate.release()

                committing.await().shouldBeCommitted()
                line shouldContain gated.id.value
                line shouldContain demo.named("broken").value
            }
        }
    }

    test("a hook that never returns still gets its log line") {
        withSetup(page, catalog = catalog) { demo ->
            val gated = createEntry("gated")
            val gate = HookGate.arm()
            withContext(Dispatchers.Default) {
                val committing =
                    launch(Dispatchers.Default) { commit(prepare(gated.edit.intents + setFormula(demo.named("broken"), "gated"))) }
                gate.awaitHeld()

                eventually(5.seconds) { logLines().single { "Still running" in it } }
                gate.release()
                committing.join()
            }
        }
    }
}
