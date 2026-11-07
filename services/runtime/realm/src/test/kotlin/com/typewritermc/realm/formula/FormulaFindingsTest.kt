package com.typewritermc.realm.formula

import com.typewritermc.authoring.field
import com.typewritermc.authoring.of
import com.typewritermc.authoring.root
import com.typewritermc.authoring.with
import com.typewritermc.formula.eval.Evaluation
import com.typewritermc.realm.edit.PAIR_FIRST
import com.typewritermc.realm.edit.PAIR_SECOND
import com.typewritermc.realm.edit.link
import com.typewritermc.realm.edit.linkType
import com.typewritermc.realm.edit.node
import com.typewritermc.realm.edit.nodeCatalog
import com.typewritermc.realm.edit.pairRelation
import com.typewritermc.realm.edit.path
import com.typewritermc.realm.routeFixtureCatalog
import com.typewritermc.realm.testing.RealmFixture
import com.typewritermc.realm.testing.commitDefinition
import com.typewritermc.realm.testing.commitPreparedTypeChange
import com.typewritermc.realm.testing.commitRecordUser
import com.typewritermc.realm.testing.commitSilverPurseUser
import com.typewritermc.realm.testing.commitTypeDefinition
import com.typewritermc.realm.testing.computedVar
import com.typewritermc.realm.testing.contentJudged
import com.typewritermc.realm.testing.contentSet
import com.typewritermc.realm.testing.declares
import com.typewritermc.realm.testing.delete
import com.typewritermc.realm.testing.entryRef
import com.typewritermc.realm.testing.errorCodesOn
import com.typewritermc.realm.testing.errorsOn
import com.typewritermc.realm.testing.fieldKey
import com.typewritermc.realm.testing.formulaChecksSince
import com.typewritermc.realm.testing.formulaPage
import com.typewritermc.realm.testing.formulas
import com.typewritermc.realm.testing.hookCatalog
import com.typewritermc.realm.testing.intUse
import com.typewritermc.realm.testing.mapType
import com.typewritermc.realm.testing.mapValue
import com.typewritermc.realm.testing.plainType
import com.typewritermc.realm.testing.plainVar
import com.typewritermc.realm.testing.publicationBlockers
import com.typewritermc.realm.testing.publicationBlockersByResource
import com.typewritermc.realm.testing.record
import com.typewritermc.realm.testing.recordValue
import com.typewritermc.realm.testing.restore
import com.typewritermc.realm.testing.setDefinitionValue
import com.typewritermc.realm.testing.setType
import com.typewritermc.realm.testing.setTypes
import com.typewritermc.realm.testing.setValue
import com.typewritermc.realm.testing.settle
import com.typewritermc.realm.testing.settledFormulaChecks
import com.typewritermc.realm.testing.shouldBeCommitted
import com.typewritermc.realm.testing.shouldBeRejected
import com.typewritermc.realm.testing.shouldContainLocation
import com.typewritermc.realm.testing.staticPage
import com.typewritermc.realm.testing.textUse
import com.typewritermc.realm.testing.typeUse
import com.typewritermc.realm.testing.withSetup
import com.typewritermc.setup.setup
import com.typewritermc.types.integer
import com.typewritermc.types.template
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldBeEmpty
import io.kotest.matchers.collections.shouldContain
import io.kotest.matchers.collections.shouldNotContain
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldContain
import skirout.editor.v1.authoring_facts.EditExpectation
import skirout.editor.v1.checking.FindingStatus
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.type_catalog.ValuePath
import skirout.kernel.v1.resource_id.ResourceId

val FormulaFindingsTest by testSuite {
    val gold = declares { record { field("gold", intUse) } }
    val goldAsText = declares { record("k1") { field("gold", textUse) } }

    test("a formula of the wrong type has an error finding on its field") {
        val page = setup("findings-wrong-type") { formulaPage { formula("total", intUse, "\"seventy\"") } }
        withSetup(page, catalog = routeFixtureCatalog) { demo ->
            settle()
            val finding = errorsOn(demo.named("total")).single()
            finding.code shouldBe "formula_type_mismatch"
            finding.primary shouldBe ValueLocation.of(demo.named("total"), ValuePath.root.field("value").field("formula"))
        }
    }

    test("a formula error blocks publish") {
        val page = setup("findings-blocks") { formulaPage { formula("total", intUse, "\"seventy\"") } }
        withSetup(page, catalog = routeFixtureCatalog) { demo -> publicationBlockers() shouldContainLocation demo.named("total") }
    }

    test("a formula with a context the realm cannot fill gives no finding here and is not evaluated") {
        val page = setup("findings-context") { formulaPage { contextual("chained", "chain + 1") } }
        withSetup(page, catalog = routeFixtureCatalog) { demo ->
            errorCodesOn(demo.named("chained")).shouldBeEmpty()
            formulas.evaluation(demo.named("chained")) shouldBe Evaluation.NotEvaluated
        }
    }

    test("one broken name gives one finding, with no cascade from the error type") {
        val page = setup("findings-broken-name") { formulaPage { formula("total", intUse, "missing * 2 + 1") } }
        withSetup(page, catalog = routeFixtureCatalog) { demo -> errorCodesOn(demo.named("total")) shouldBe listOf("formula_unknown_name") }
    }

    test("deleting an entry a formula names gives that formula one finding naming it") {
        val page =
            setup("findings-deleted") {
                formulaPage {
                    smith("smith")
                    bound("giver", entryRef, "smith", mapOf("smith" to named("smith")))
                }
            }
        withSetup(page, catalog = routeFixtureCatalog) { demo ->
            errorCodesOn(demo.named("giver")).shouldBeEmpty()
            commit(delete(demo.named("smith"))).shouldBeCommitted()

            errorCodesOn(demo.named("giver")) shouldBe listOf("formula_deleted_reference")
            errorsOn(demo.named("giver")).single().message shouldContain "smith"
        }
    }

    test("a formula in a Definition of an alias checks against the alias's type") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val amount = commitTypeDefinition("Amount", plainType(intUse)).created()
            val fits = commitDefinition("fits", plainType(fieldKey(amount))) { computedVar(it.use, "1 + 2") }.created()
            val misfits = commitDefinition("misfits", plainType(fieldKey(amount))) { computedVar(it.use, "\"three\"") }.created()

            errorCodesOn(fits).shouldBeEmpty()
            errorCodesOn(misfits) shouldBe listOf("formula_type_mismatch")
        }
    }

    test("changing an alias reruns its stored users, and a value that no longer fits gets a finding") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val amount = commitTypeDefinition("Amount", plainType(intUse)).created()
            val holder = commitDefinition("holder", plainType(fieldKey(amount))) { plainVar(it.use, DataValue.integer(3)) }.created()
            val computed = commitDefinition("computed", plainType(fieldKey(amount))) { computedVar(it.use, "2") }.created()
            val before = settledFormulaChecks()
            commit(setDefinitionValue(amount, plainVar(typeUse, DataValue.TypeUseWrapper(textUse)))).shouldBeCommitted()

            formulaChecksSince(before) shouldContain computed
            errorCodesOn(holder) shouldBe listOf("value_mismatch")
            errorCodesOn(computed) shouldBe listOf("formula_type_mismatch")
        }
    }

    test("two aliases in a loop give each user one finding and do not hang") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val first = commitTypeDefinition("First", plainType(intUse)).created()
            val second = commitTypeDefinition("Second", plainType(fieldKey(first))).created()
            val firstUser = commitDefinition("first_user", plainType(fieldKey(first))).created()
            val secondUser = commitDefinition("second_user", plainType(fieldKey(second))).created()
            val looping = plainVar(typeUse, DataValue.TypeUseWrapper(fieldKey(second)))
            saveByHand(mapOf(first to record(first).with("value", looping)))

            errorCodesOn(firstUser) shouldBe listOf("content_alias_loop")
            errorCodesOn(secondUser) shouldBe listOf("content_alias_loop")
        }
    }

    test("an alias whose value is a formula gives its users a missing type finding") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val amount = commitTypeDefinition("Amount", plainType(intUse)).created()
            val user = commitDefinition("user", plainType(fieldKey(amount))) { plainVar(it.use, DataValue.integer(1)) }.created()
            commit(setDefinitionValue(amount, computedVar(typeUse, "Int"))).shouldBeCommitted()

            errorCodesOn(user) shouldBe listOf("content_type_missing")
        }
    }

    test("deleting an alias gives its users a missing type finding, and restoring it clears that") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val amount = commitTypeDefinition("Amount", plainType(intUse)).created()
            val user = commitDefinition("user", plainType(fieldKey(amount))) { plainVar(it.use, DataValue.integer(1)) }.created()
            val saved = record(amount)
            commit(delete(amount)).shouldBeCommitted()
            errorCodesOn(user) shouldBe listOf("content_type_missing")

            restore(amount, saved).shouldBeCommitted()
            errorCodesOn(user).shouldBeEmpty()
        }
    }

    test("a formula stored in a field whose type is missing shows no finding of its own") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val amount = commitTypeDefinition("Amount", plainType(intUse)).created()
            val user = commitDefinition("user", plainType(fieldKey(amount))) { computedVar(it.use, "1 + 1") }.created()
            commit(delete(amount)).shouldBeCommitted()

            errorCodesOn(user) shouldBe listOf("content_type_missing")
        }
    }

    test("a custom type that no longer exists gives its users one finding and blocks publish") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val reward = commitTypeDefinition("Reward", gold).created()
            val user = commitRecordUser("first", reward, "gold" to DataValue.integer(1))
            commit(delete(reward)).shouldBeCommitted()

            errorCodesOn(user) shouldBe listOf("content_type_missing")
            publicationBlockersByResource()[user] shouldBe 1
        }
    }

    test("restoring a deleted custom type clears its users' findings") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val reward = commitTypeDefinition("Reward", gold).created()
            val user = commitRecordUser("first", reward, "gold" to DataValue.integer(1))
            val saved = record(reward)
            commit(delete(reward)).shouldBeCommitted()
            errorCodesOn(user) shouldBe listOf("content_type_missing")

            restore(reward, saved).shouldBeCommitted()
            errorCodesOn(user).shouldBeEmpty()
        }
    }

    test("a value that no longer fits its edited declaration gives one finding on its holder, and blocks publish") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val reward = commitTypeDefinition("Reward", gold).created()
            val user = commitRecordUser("first", reward, "gold" to DataValue.integer(1))
            commit(setTypes(reward, goldAsText)).shouldBeCommitted()

            errorCodesOn(user) shouldBe listOf("value_mismatch")
            publicationBlockersByResource()[user] shouldBe 1
        }
    }

    test("restoring the declaration clears that finding") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val reward = commitTypeDefinition("Reward", gold).created()
            val user = commitRecordUser("first", reward, "gold" to DataValue.integer(1))
            commit(setTypes(reward, goldAsText)).shouldBeCommitted()
            errorCodesOn(user) shouldBe listOf("value_mismatch")

            commit(setTypes(reward, gold)).shouldBeCommitted()
            errorCodesOn(user).shouldBeEmpty()
        }
    }

    test("a formula finding whose evidence holds a types fact is judged current") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val reward = commitTypeDefinition("Reward", gold).created()
            val user = commitDefinition("user", plainType(fieldKey(reward))) { computedVar(it.use, "1") }.created()

            errorCodesOn(user) shouldBe listOf("formula_type_mismatch")
            val set = contentSet(user)
            set.expectations.filterIsInstance<EditExpectation.TypesWrapper>().map { it.value.resource } shouldContain reward
            set.status shouldBe FindingStatus.CURRENT
        }
    }

    test("fixing a holder's own misfit clears its finding, and the reply judges it current") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            findings = checks::findings
            val reward = commitTypeDefinition("Reward", gold).created()
            val user = commitRecordUser("first", reward, "gold" to DataValue.integer(1))
            commit(setTypes(reward, goldAsText)).shouldBeCommitted()
            errorCodesOn(user) shouldBe listOf("value_mismatch")

            val fixed = plainVar(fieldKey(reward), recordValue(fieldKey(reward), "gold" to DataValue.StringValueWrapper("one")))
            val reply = commit(setDefinitionValue(user, fixed)).shouldBeCommitted()
            reply.findings
                .filter { set -> set.status == FindingStatus.CURRENT && set.findings.any { it.primary?.resource == user } }
                .shouldBeEmpty()
            errorCodesOn(user).shouldBeEmpty()
            contentJudged() shouldNotContain user
        }
    }

    test("a resource whose type argument changes to a content type gets its findings") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val title = commitTypeDefinition("Title", plainType(textUse)).created()
            val user = commitDefinition("user", plainType(intUse)) { computedVar(it.use, "1") }.created()
            errorCodesOn(user).shouldBeEmpty()

            commitPreparedTypeChange(user, to = fieldKey(title)).shouldBeCommitted()
            errorCodesOn(user) shouldBe listOf("formula_type_mismatch")
        }
    }

    test("a new use of an alias gives its user no finding") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val amount = commitTypeDefinition("Amount", plainType(intUse)).created()
            val user = commitDefinition("user", plainType(fieldKey(amount))) { plainVar(it.use, DataValue.integer(1)) }.created()

            errorCodesOn(user).shouldBeEmpty()
        }
    }

    test("a code record whose Ref slot a new generation removed gets one fit finding") {
        val holder = ResourceId(value = "holder")
        val target = ResourceId(value = "target")
        val withSpareSlot = nodeCatalog(pairRelation(), extraFields = { field("spare", linkType(PAIR_FIRST).template()) })
        val linked =
            mapOf(
                holder to node().with("spare", link(PAIR_FIRST, target, path("second"))),
                target to node(second = link(PAIR_SECOND, holder, path("spare"))),
            )
        RealmFixture.of(withSpareSlot, linked).use { realm ->
            realm.restart(nodeCatalog(pairRelation()))

            realm.errorCodesOn(holder) shouldBe listOf("value_mismatch")
        }
    }

    test("a hook that throws gives that resource a finding set, and a page a hook ran on cleanly gets none") {
        val page = setup("findings-hook") { formulaPage { smith("throw") } }
        withSetup(page, catalog = hookCatalog()) { demo ->
            val judged = contentJudged()
            judged shouldContain demo.named("throw")
            judged shouldNotContain demo.pageId
        }
    }

    test("a value whose type is missing shows only the missing type finding, not one per old field") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val (reward, user) = commitSilverPurseUser()
            commit(delete(reward)).shouldBeCommitted()

            errorCodesOn(user) shouldBe listOf("content_type_missing")
        }
    }

    test("deleting a custom type in use gives exactly one publish blocker per holder") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val reward = commitTypeDefinition("Reward", gold).created()
            val first = commitRecordUser("first", reward, "gold" to DataValue.integer(1))
            val second = commitRecordUser("second", reward, "gold" to DataValue.integer(2))
            commit(delete(reward)).shouldBeCommitted()
            settle()

            val blockers = publicationBlockersByResource()
            blockers[first] shouldBe 1
            blockers[second] shouldBe 1
        }
    }

    test("a set holding one value twice gets one fit finding naming the repeat, and blocks publish once") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val numbers = setType(intUse)
            val held =
                commitDefinition("numbers", plainType(numbers)) {
                    plainVar(numbers, setValue(intUse, DataValue.integer(1), DataValue.integer(2)))
                }.created()
            saveByHand(
                mapOf(held to record(held).with("value", plainVar(numbers, setValue(intUse, DataValue.integer(1), DataValue.integer(1))))),
            )

            errorCodesOn(held) shouldBe listOf("value_mismatch")
            errorsOn(held).single().message shouldContain "duplicate_set_value"
            publicationBlockersByResource()[held] shouldBe 1
        }
    }

    test("a map holding one key twice gets one fit finding naming the repeat, and blocks publish once") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val scores = mapType(textUse, intUse)
            val first = DataValue.StringValueWrapper("first")
            val held =
                commitDefinition("scores", plainType(scores)) {
                    plainVar(
                        scores,
                        mapValue(
                            textUse,
                            intUse,
                            first to DataValue.integer(1),
                            DataValue.StringValueWrapper("second") to DataValue.integer(2),
                        ),
                    )
                }.created()
            saveByHand(
                mapOf(
                    held to
                        record(held).with(
                            "value",
                            plainVar(
                                scores,
                                mapValue(
                                    textUse,
                                    intUse,
                                    first to DataValue.integer(1),
                                    first to DataValue.integer(2),
                                ),
                            ),
                        ),
                ),
            )

            errorCodesOn(held) shouldBe listOf("value_mismatch")
            errorsOn(held).single().message shouldContain "duplicate_map_key"
            publicationBlockersByResource()[held] shouldBe 1
        }
    }

    test("a commit that puts one value twice in a set is refused") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val numbers = setType(intUse)
            commitDefinition(
                "numbers",
                plainType(numbers),
            ) { plainVar(numbers, setValue(intUse, DataValue.integer(1), DataValue.integer(1))) }
                .reply
                .shouldBeRejected("duplicate_set_value")
        }
    }

    test("a commit that puts one key twice in a map is refused") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val scores = mapType(textUse, intUse)
            val first = DataValue.StringValueWrapper("first")
            commitDefinition("scores", plainType(scores)) {
                plainVar(
                    scores,
                    mapValue(
                        textUse,
                        intUse,
                        first to DataValue.integer(1),
                        first to DataValue.integer(2),
                    ),
                )
            }.reply
                .shouldBeRejected("duplicate_map_key")
        }
    }
}
