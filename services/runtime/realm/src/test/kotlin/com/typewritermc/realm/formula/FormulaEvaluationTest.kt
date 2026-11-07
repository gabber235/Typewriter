package com.typewritermc.realm.formula

import com.typewritermc.authoring.field
import com.typewritermc.formula.Formula
import com.typewritermc.formula.FormulaFailure
import com.typewritermc.formula.Var
import com.typewritermc.formula.eval.Evaluation
import com.typewritermc.formula.eval.FunctionValue
import com.typewritermc.realm.authoring.valueAt
import com.typewritermc.realm.routeFixtureCatalog
import com.typewritermc.realm.testing.TypeDefinitionBuilder
import com.typewritermc.realm.testing.booleanUse
import com.typewritermc.realm.testing.boxOf
import com.typewritermc.realm.testing.changingCodeCatalog
import com.typewritermc.realm.testing.changingCodeUse
import com.typewritermc.realm.testing.commit
import com.typewritermc.realm.testing.commitDefinition
import com.typewritermc.realm.testing.commitSilverPurseUser
import com.typewritermc.realm.testing.commitTypeDefinition
import com.typewritermc.realm.testing.computedVar
import com.typewritermc.realm.testing.contentLink
import com.typewritermc.realm.testing.contentSet
import com.typewritermc.realm.testing.createEntry
import com.typewritermc.realm.testing.declares
import com.typewritermc.realm.testing.definitionValueUse
import com.typewritermc.realm.testing.delete
import com.typewritermc.realm.testing.demoOneDefinitions
import com.typewritermc.realm.testing.demoTwoDefinitions
import com.typewritermc.realm.testing.entryRef
import com.typewritermc.realm.testing.errorCodesOn
import com.typewritermc.realm.testing.errorSet
import com.typewritermc.realm.testing.evaluationsSince
import com.typewritermc.realm.testing.fieldKey
import com.typewritermc.realm.testing.formulaPage
import com.typewritermc.realm.testing.formulas
import com.typewritermc.realm.testing.intUse
import com.typewritermc.realm.testing.lootUse
import com.typewritermc.realm.testing.plain
import com.typewritermc.realm.testing.plainType
import com.typewritermc.realm.testing.plainValueLocation
import com.typewritermc.realm.testing.plainVar
import com.typewritermc.realm.testing.prizeExtensionCatalog
import com.typewritermc.realm.testing.prizeUse
import com.typewritermc.realm.testing.publicationBlockers
import com.typewritermc.realm.testing.record
import com.typewritermc.realm.testing.recordValue
import com.typewritermc.realm.testing.rename
import com.typewritermc.realm.testing.rerunSince
import com.typewritermc.realm.testing.resources
import com.typewritermc.realm.testing.setFormula
import com.typewritermc.realm.testing.setGiver
import com.typewritermc.realm.testing.setTypes
import com.typewritermc.realm.testing.setVar
import com.typewritermc.realm.testing.settle
import com.typewritermc.realm.testing.settledEvaluations
import com.typewritermc.realm.testing.settledRuns
import com.typewritermc.realm.testing.shouldBeCommitted
import com.typewritermc.realm.testing.shouldContainLocation
import com.typewritermc.realm.testing.signalUse
import com.typewritermc.realm.testing.staticPage
import com.typewritermc.realm.testing.stockRef
import com.typewritermc.realm.testing.textUse
import com.typewritermc.realm.testing.withSetup
import com.typewritermc.setup.setup
import com.typewritermc.testing.routes.FixtureBox
import com.typewritermc.testing.routes.FixtureCoinPrize
import com.typewritermc.testing.routes.FixtureLoot
import com.typewritermc.testing.routes.FixtureSignal
import com.typewritermc.types.FORMULA_USE
import com.typewritermc.types.functionUse
import com.typewritermc.types.integer
import com.typewritermc.types.nullable
import com.typewritermc.types.record
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldBeEmpty
import io.kotest.matchers.collections.shouldContainExactlyInAnyOrder
import io.kotest.matchers.collections.shouldNotBeEmpty
import io.kotest.matchers.collections.shouldNotContain
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import skirout.editor.v1.authoring.EditIntent
import skirout.editor.v1.authoring_facts.EditExpectation
import skirout.editor.v1.checking.FindingStatus
import skirout.editor.v1.diagnostic.Diagnostic
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.PathSegment
import skirout.editor.v1.typed_value.PortableValue

val FormulaEvaluationTest by testSuite {
    val level = functionUse(parameters = listOf("level" to intUse), result = intUse)

    test("a Definition of Int with a formula evaluates it") {
        val page = setup("evaluate-int") { formulaPage { formula("total", intUse, "1 + 2 * 3") } }
        withSetup(page, catalog = routeFixtureCatalog) { demo -> formulas.value(demo.total) shouldBe 7 }
    }

    test("a Definition reads another Definition") {
        val page =
            setup("evaluate-reads") {
                formulaPage {
                    definition("base_reward", intUse, 50)
                    formula("total", intUse, "base_reward * 2")
                }
            }
        withSetup(page, catalog = routeFixtureCatalog) { demo -> formulas.value(demo.total) shouldBe 100 }
    }

    test("a Definition of a function type is callable, and its body does not run until it is called") {
        val page =
            setup("evaluate-function-lazy") {
                formulaPage {
                    formula("bonus", level, "level / 0")
                    formula("total", intUse, "bonus(1)")
                }
            }
        withSetup(page, catalog = routeFixtureCatalog) { demo ->
            formulas
                .evaluation(demo.bonus)
                .shouldBeInstanceOf<Evaluation.Value<*>>()
                .value
                .shouldBeInstanceOf<FunctionValue>()
            errorCodesOn(demo.bonus).shouldBeEmpty()
            formulas.failure(demo.total) shouldBe FormulaFailure.DivisionByZero
        }
    }

    test("calling a function Definition binds its arguments") {
        val page = setup("evaluate-call") { formulaPage { demoOneDefinitions() } }
        withSetup(page, catalog = routeFixtureCatalog) { demo -> formulas.value(demo.total) shouldBe 70 }
    }

    test("a caller of a function Definition reruns with the new value when a Definition read inside its body changes") {
        val page =
            setup("evaluate-body-read") {
                formulaPage {
                    definition("factor", intUse, 2)
                    formula("bonus", level, "level * factor")
                    formula("total", intUse, "bonus(10)")
                }
            }
        withSetup(page, catalog = routeFixtureCatalog) { demo ->
            formulas.value(demo.total) shouldBe 20
            commit(setVar(demo.named("factor"), intUse, plain(3)))
            settle()
            formulas.value(demo.total) shouldBe 30
        }
    }

    test("a function Definition stays callable after an unrelated commit") {
        val page =
            setup("evaluate-function-stays") {
                formulaPage {
                    demoOneDefinitions()
                    definition("other", intUse, 1)
                }
            }
        withSetup(page, catalog = routeFixtureCatalog) { demo ->
            formulas.value(demo.total) shouldBe 70
            commit(setVar(demo.named("other"), intUse, plain(2)))
            settle()
            formulas.value(demo.total) shouldBe 70
        }
    }

    test("a plain Var.Value reads as its value, also through a reference") {
        val page =
            setup("evaluate-plain") {
                formulaPage {
                    definition("base_reward", intUse, 50)
                    contextual("chain", 5)
                    formula("through", intUse, "chain.chained + 1")
                }
            }
        withSetup(page, catalog = routeFixtureCatalog) { demo ->
            formulas.value(demo.baseReward) shouldBe 50
            formulas.value(demo.named("through")) shouldBe 6
        }
    }

    test("a Definition of Type gives a name usable as a type and a constructor, and others read its fields") {
        val page =
            setup("evaluate-custom-type") {
                formulaPage {
                    val reward = customType("Reward") { field("gold", intUse) }
                    formula("first_reward", fieldKey(reward), "Reward(gold = 3)")
                    formula("gold", intUse, "first_reward.gold + 1")
                }
            }
        withSetup(page, catalog = routeFixtureCatalog) { demo ->
            formulas.value(demo.firstReward, "gold") shouldBe 3
            formulas.value(demo.named("gold")) shouldBe 4
        }
    }

    test("a Definition whose formula fails has one error finding that blocks publish") {
        val page = setup("evaluate-fails") { formulaPage { formula("total", intUse, "1 / 0") } }
        withSetup(page, catalog = routeFixtureCatalog) { demo ->
            errorCodesOn(demo.total) shouldBe listOf("formula_failed")
            publicationBlockers() shouldContainLocation demo.total
        }
    }

    test("a reader of a failing Definition has no finding of its own") {
        val page =
            setup("evaluate-fails-reader") {
                formulaPage {
                    formula("broken", intUse, "1 / 0")
                    formula("total", intUse, "broken + 1")
                }
            }
        withSetup(page, catalog = routeFixtureCatalog) { demo ->
            errorCodesOn(demo.total).shouldBeEmpty()
            formulas.failure(demo.total) shouldBe FormulaFailure.Dependency(demo.named("broken"))
        }
    }

    test("two Definitions that read each other both get a cycle finding, and others keep evaluating") {
        val page =
            setup("evaluate-cycle") {
                formulaPage {
                    formula("a", intUse, "b + 1")
                    formula("b", intUse, "a + 1")
                    formula("c", intUse, "2")
                }
            }
        withSetup(page, catalog = routeFixtureCatalog) { demo ->
            val members = listOf(demo.named("a"), demo.named("b")).sortedBy { it.value }
            formulas.failure(demo.named("a")) shouldBe FormulaFailure.Cycle(members)
            formulas.failure(demo.named("b")) shouldBe FormulaFailure.Cycle(members)
            errorCodesOn(demo.named("a")) shouldBe listOf("formula_failed")
            errorCodesOn(demo.named("b")) shouldBe listOf("formula_failed")
            formulas.value(demo.named("c")) shouldBe 2
        }
    }

    test("a cycle through a lambda still recovers on each member") {
        val page =
            setup("evaluate-cycle-lambda") {
                formulaPage {
                    formula("a", intUse, "[1].map { it + b }.sumOf { it }")
                    formula("b", intUse, "a + 1")
                }
            }
        withSetup(page, catalog = routeFixtureCatalog) { demo ->
            val members = listOf(demo.named("a"), demo.named("b")).sortedBy { it.value }
            formulas.failure(demo.named("a")) shouldBe FormulaFailure.Cycle(members)
            formulas.failure(demo.named("b")) shouldBe FormulaFailure.Cycle(members)
        }
    }

    test("fixing one Definition of a cycle clears both findings") {
        val page =
            setup("evaluate-cycle-fix") {
                formulaPage {
                    formula("a", intUse, "b + 1")
                    formula("b", intUse, "a + 1")
                }
            }
        withSetup(page, catalog = routeFixtureCatalog) { demo ->
            errorCodesOn(demo.named("a")) shouldBe listOf("formula_failed")
            commit(setFormula(demo.named("a"), "1"))
            settle()
            errorCodesOn(demo.named("a")).shouldBeEmpty()
            errorCodesOn(demo.named("b")).shouldBeEmpty()
            formulas.value(demo.named("b")) shouldBe 2
        }
    }

    test("a field read on a reference reads the target's current value, also after a rename") {
        val page =
            setup("evaluate-reference") {
                formulaPage {
                    smith()
                    demoOneDefinitions()
                    demoTwoDefinitions()
                }
            }
        withSetup(page, catalog = routeFixtureCatalog) { demo ->
            formulas.value(demo.giverName) shouldBe "smith"
            commit(rename(demo.smith, "blacksmith"))
            settle()
            formulas.value(demo.giverName) shouldBe "blacksmith"
        }
    }

    test("a value read through a deleted reference gives a finding on the source only, not a crash") {
        val page =
            setup("evaluate-deleted") {
                formulaPage {
                    smith()
                    demoOneDefinitions()
                    demoTwoDefinitions()
                }
            }
        withSetup(page, catalog = routeFixtureCatalog) { demo ->
            commit(delete(demo.smith))
            settle()
            errorCodesOn(demo.firstReward) shouldBe listOf("formula_deleted_reference")
            errorCodesOn(demo.giverName).shouldBeEmpty()
        }
    }

    test("a Definition of a function with no parameters gives a function and runs its body only when called") {
        val page =
            setup("evaluate-thunk") {
                formulaPage {
                    formula("later", functionUse(result = intUse), "1 / 0")
                    formula("now", intUse, "later() + 1")
                }
            }
        withSetup(page, catalog = routeFixtureCatalog) { demo ->
            formulas
                .evaluation(demo.named("later"))
                .shouldBeInstanceOf<Evaluation.Value<*>>()
                .value
                .shouldBeInstanceOf<FunctionValue>()
            errorCodesOn(demo.named("later")).shouldBeEmpty()
            formulas.failure(demo.named("now")) shouldBe FormulaFailure.DivisionByZero
        }
    }

    test("a Var.Computed at a function typed field gives one finding and is not evaluated") {
        val page = setup("evaluate-computed-function") { formulaPage { computedFunction("bonus", level, "level * 2") } }
        withSetup(page, catalog = routeFixtureCatalog) { demo ->
            errorCodesOn(demo.bonus) shouldBe listOf("formula_computed_function")
            formulas.evaluation(demo.bonus) shouldBe Evaluation.NotEvaluated
        }
    }

    test("a chain of 2000 Definitions evaluates to the right value, cold and warm") {
        val page =
            setup("evaluate-chain") {
                formulaPage {
                    definition("d0", intUse, 0)
                    (1 until 2000).forEach { formula("d$it", intUse, "d${it - 1} + 1") }
                }
            }
        withSetup(page, catalog = routeFixtureCatalog) { demo ->
            formulas.value(demo.named("d1999")) shouldBe 1999
            formulas.value(demo.named("d1999")) shouldBe 1999
        }
    }

    test("an alias of a content record decodes its value, and a formula reads its field") {
        val page =
            setup("evaluate-alias") {
                formulaPage {
                    val reward = customType("Reward") { field("gold", intUse) }
                    formula("first_reward", fieldKey(reward), "Reward(gold = 5)")
                    formula("same", booleanUse, "first_reward == Reward(gold = 5)")
                }
            }
        withSetup(page, catalog = routeFixtureCatalog) { demo -> formulas.value(demo.named("same")) shouldBe true }
    }

    test("evaluation reruns only when something it read changed") {
        val page =
            setup("evaluate-reruns") {
                formulaPage {
                    demoOneDefinitions()
                    definition("other", intUse, 1)
                    formula("reads_other", intUse, "other + 1")
                }
            }
        withSetup(page, catalog = routeFixtureCatalog) { demo ->
            val before = settledEvaluations()
            commit(setVar(demo.named("other"), intUse, plain(2)))
            settle()
            val rerun = evaluationsSince(before)
            rerun shouldNotContain demo.total
            rerun shouldContainExactlyInAnyOrder listOf(demo.named("other"), demo.named("reads_other"))
        }
    }

    test("a when over a stored value whose type names a union through a field key matches its case") {
        val page =
            setup("evaluate-when-field-key") {
                formulaPage {
                    smith()
                    demoOneDefinitions()
                    demoTwoDefinitions()
                    formula("opened", intUse, "when (door) { is Open -> 1\n is Closed -> 2 }")
                }
            }
        withSetup(page, catalog = routeFixtureCatalog) { demo -> formulas.value(demo.named("opened")) shouldBe 1 }
    }

    test("a value whose type is missing is not evaluated, and its reader has no finding of its own") {
        val page =
            setup("evaluate-missing-type") {
                formulaPage {
                    val reward = customType("Reward") { field("gold", intUse) }
                    formula("first_reward", fieldKey(reward), "Reward(gold = 3)")
                    formula("gold", intUse, "first_reward.gold + 1")
                }
            }
        withSetup(page, catalog = routeFixtureCatalog) { demo ->
            commit(delete(demo.reward))
            settle()
            errorCodesOn(demo.named("gold")).shouldBeEmpty()
            formulas.evaluation(demo.named("gold")).shouldBeInstanceOf<Evaluation.Failed>()
        }
    }

    test("a reader of a value with an unfilled link has no finding, and reruns and evaluates once the link is filled") {
        val page =
            setup("evaluate-unfilled-link") {
                formulaPage {
                    smith()
                    demoOneDefinitions()
                    demoTwoDefinitions()
                    formula("gift_giver", textUse, "gift.giver.name")
                }
            }
        withSetup(page, catalog = routeFixtureCatalog) { demo ->
            commit(delete(demo.smith))
            settle()
            errorCodesOn(demo.named("gift_giver")).shouldBeEmpty()
            formulas.evaluation(demo.named("gift_giver")).shouldBeInstanceOf<Evaluation.Failed>()
            val replacement = createEntry("anvil")
            commit(replacement)
            commit(setGiver(demo.gift, to = replacement.id))
            settle()
            formulas.value(demo.named("gift_giver")) shouldBe "anvil"
        }
    }
    test("two passes that enter a cycle from different members give equal finding sets") {
        val page =
            setup("evaluate-cycle-passes") {
                formulaPage {
                    formula("a", intUse, "b + 1")
                    formula("b", intUse, "a + 1")
                }
            }
        val passes = mutableListOf<Set<Diagnostic>>()
        for (entered in listOf("a", "b")) {
            withSetup(page, catalog = routeFixtureCatalog) { demo ->
                formulas.evaluation(demo.named(entered))
                passes += errorSet(demo.named("a"), demo.named("b"))
            }
        }
        passes[0].shouldNotBeEmpty()
        passes[0] shouldBe passes[1]
    }

    test("a stored code record equals the same record built by a formula constructor") {
        val page =
            setup("evaluate-stored-code-record") {
                formulaPage {
                    definition("loot", lootUse, FixtureLoot(gold = Var.Value(3)))
                    formula("same", booleanUse, "loot == FixtureLoot(gold = 3)")
                }
            }
        withSetup(page, catalog = routeFixtureCatalog) { demo -> formulas.value(demo.named("same")) shouldBe true }
    }

    test(
        "a stored plain case at a union position whose other case holds a Var equals the same case built by a formula, and when matches both",
    ) {
        val page =
            setup("evaluate-plain-case") {
                formulaPage {
                    definition("signal", signalUse, FixtureSignal.Quiet)
                    formula("same", booleanUse, "signal == Quiet()")
                    formula("stored_arm", intUse, "when (signal) { is Quiet -> 1\n is Tuned -> 2 }")
                    formula("built_arm", intUse, "let built: FixtureSignal = Quiet()\nwhen (built) { is Quiet -> 1\n is Tuned -> 2 }")
                }
            }
        withSetup(page, catalog = routeFixtureCatalog) { demo ->
            formulas.value(demo.named("same")) shouldBe true
            formulas.value(demo.named("stored_arm")) shouldBe 1
            formulas.value(demo.named("built_arm")) shouldBe 1
        }
    }

    test("a reader of one field is not stopped by a failing Var in a sibling field") {
        val page =
            setup("evaluate-sibling-var") {
                formulaPage {
                    definition("loot", lootUse, FixtureLoot(gold = Var.Value(3), bonus = Var.Computed(Formula("1 / 0"))))
                    formula("reads_gold", intUse, "loot.gold + 1")
                }
            }
        withSetup(page, catalog = routeFixtureCatalog) { demo ->
            formulas.value(demo.named("reads_gold")) shouldBe 4
            errorCodesOn(demo.named("reads_gold")).shouldBeEmpty()
            errorCodesOn(demo.named("loot")) shouldBe listOf("formula_failed")
        }
    }

    test("a Var inside a list item evaluates at that item's location") {
        val page =
            setup("evaluate-list-var") {
                formulaPage {
                    definition("loot", lootUse, FixtureLoot(extras = listOf(Var.Value(1), Var.Computed(Formula("2 + 3")))))
                }
            }
        withSetup(page, catalog = routeFixtureCatalog) { demo ->
            val site = formulas.site(demo.named("loot"), "2 + 3")
            site.holder.path.segments
                .last()
                .shouldBeInstanceOf<PathSegment.ItemWrapper>()
            formulas.evaluation(demo.named("loot"), "2 + 3") shouldBe Evaluation.Value(5)
        }
    }

    test("a stored nullable function field is callable, and a stored nullable Ref reads through") {
        val page =
            setup("evaluate-nullable-fields") {
                formulaPage {
                    val smith = smith()
                    definition(
                        "kit",
                        declares {
                            record {
                                field("rule", level.nullable())
                                field("helper", entryRef.nullable())
                            }
                        },
                    ) { recordValue(it, "rule" to DataValue.NULL, "helper" to contentLink(smith)) }
                    formula("ruled", intUse, "let rule = kit.rule ?: { level: Int -> 0 }\nrule(4)")
                    formula("helped", textUse, "kit.helper?.name ?: \"nobody\"")
                }
            }
        withSetup(page, catalog = routeFixtureCatalog) { demo ->
            val rule = plainValueLocation(demo.named("kit")).let { it.copy(path = it.path.field("rule")) }
            commit(EditIntent.createSetValue(at = rule, value = encoder.encode(FORMULA_USE.use, Formula("level * 2"))))
            settle()
            formulas.value(demo.named("ruled")) shouldBe 8
            formulas.value(demo.named("helped")) shouldBe "smith"
        }
    }

    test("adding an extension that gives an open type a Var holding subtype leaves a formula passing that type to a provider valid") {
        val page =
            setup("evaluate-open-subtype") {
                formulaPage {
                    definition("prize", prizeUse, FixtureCoinPrize(5))
                    formula("worth", intUse, "prize.worth()")
                }
            }
        withSetup(page, catalog = routeFixtureCatalog) { demo ->
            formulas.value(demo.named("worth")) shouldBe 5
            restart(prizeExtensionCatalog)
            settle()
            errorCodesOn(demo.named("worth")).shouldBeEmpty()
            formulas.value(demo.named("worth")) shouldBe 5
        }
    }

    test("a when over a code union matches a stored value and a built one alike") {
        val page =
            setup("evaluate-code-union") {
                formulaPage {
                    definition("signal", signalUse, FixtureSignal.Tuned(Var.Value(2)))
                    formula("stored_arm", intUse, "when (signal) { is Tuned -> 1\n is Quiet -> 2 }")
                    formula("built_arm", intUse, "let built: FixtureSignal = Quiet()\nwhen (built) { is Tuned -> 1\n is Quiet -> 2 }")
                }
            }
        withSetup(page, catalog = routeFixtureCatalog) { demo ->
            formulas.value(demo.named("stored_arm")) shouldBe 1
            formulas.value(demo.named("built_arm")) shouldBe 2
        }
    }

    test("a Var field read through a reference gives its evaluated value") {
        val page =
            setup("evaluate-var-through-reference") {
                formulaPage {
                    val depot = stock("depot", stock = Var.Computed(Formula("2 * 3")))
                    definition("loot", lootUse, FixtureLoot(givers = listOf(stockRef(depot))))
                    formula("stocked", intUse, "loot.givers.get(0)?.stock ?: 0")
                }
            }
        withSetup(page, catalog = routeFixtureCatalog) { demo -> formulas.value(demo.named("stocked")) shouldBe 6 }
    }

    test("a two hop reference chain reads through both") {
        val page =
            setup("evaluate-two-hops") {
                formulaPage {
                    val far = stock("far")
                    val near = stock("near", loot = FixtureLoot(givers = listOf(stockRef(far))))
                    definition("loot", lootUse, FixtureLoot(givers = listOf(stockRef(near))))
                    formula("far_name", textUse, "let near = loot.givers.get(0)\nnear?.loot?.givers?.get(0)?.name ?: \"none\"")
                }
            }
        withSetup(page, catalog = routeFixtureCatalog) { demo -> formulas.value(demo.named("far_name")) shouldBe "far" }
    }

    test("a code generic over a content type reads its fields") {
        val page =
            setup("evaluate-generic-content") {
                formulaPage {
                    val build: TypeDefinitionBuilder.() -> Unit = { field("gold", intUse) }
                    val declared = customTypeUse("Reward", build)
                    val reward = customType("Reward", build)
                    val held = PortableValue(actualType = declared, payload = DataValue.record("gold" to DataValue.integer(4)))
                    definition("boxed", boxOf(fieldKey(reward)), FixtureBox(held))
                    formula("gold", intUse, "boxed.x.gold + 1")
                }
            }
        withSetup(page, catalog = routeFixtureCatalog) { demo -> formulas.value(demo.named("gold")) shouldBe 5 }
    }

    test(
        "a value read below a check changes with equal findings: the set stays current with no new run, and its evidence holds the new value",
    ) {
        val page =
            setup("evaluate-below-check") {
                formulaPage {
                    definition("base", intUse, 50)
                    formula("total", intUse, "base * 0 + 1")
                }
            }
        withSetup(page, catalog = routeFixtureCatalog) { demo ->
            val base = demo.named("base")
            val total = demo.named("total")
            val before = settledRuns()
            commit(setVar(base, intUse, plain(60)))
            settle()
            rerunSince(before).resources() shouldNotContain total
            val set = contentSet(total)
            set.status shouldBe FindingStatus.CURRENT
            val stored = record(base)
            val held =
                set.expectations.mapNotNull { fact ->
                    when {
                        fact is EditExpectation.ResourceWrapper && fact.value.id == base -> {
                            fact.value.expected to stored
                        }

                        fact is EditExpectation.ValueWrapper && fact.value.at.resource == base -> {
                            fact.value.expected to
                                stored.valueAt(fact.value.at.path)
                        }

                        else -> {
                            null
                        }
                    }
                }
            held.shouldNotBeEmpty()
            held.forEach { (expected, now) -> expected shouldBe now }
        }
    }

    test("an extension entry that exports its own field evaluates through that field") {
        val page =
            setup("evaluate-entry-export") {
                formulaPage {
                    stock("depot", stock = Var.Computed(Formula("3 * 4")))
                    formula("reads_depot", intUse, "depot + 1")
                }
            }
        withSetup(page, catalog = routeFixtureCatalog) { demo ->
            formulas.value(demo.named("depot")) shouldBe 12
            formulas.value(demo.named("reads_depot")) shouldBe 13
        }
    }

    test("an alias of a code record decodes its value, and a formula reads its field") {
        val page =
            setup("evaluate-code-alias") {
                formulaPage {
                    val bag = alias("Bag", lootUse)
                    definition("bag_value", fieldKey(bag), FixtureLoot(gold = Var.Value(4)))
                    formula("gold", intUse, "bag_value.gold + 1")
                }
            }
        withSetup(page, catalog = routeFixtureCatalog) { demo -> formulas.value(demo.named("gold")) shouldBe 5 }
    }

    test(
        "a holder with a missing type gives exactly its FitOf finding, its own formulas no check failure, and a sibling field that fits still evaluates",
    ) {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val reward = commitTypeDefinition("Reward", declares { record { field("gold", intUse) } }).created()
            val bag =
                commitDefinition(
                    "bag",
                    declares {
                        record {
                            field("prize", fieldKey(reward))
                            field("count", definitionValueUse(intUse))
                        }
                    },
                ) {
                    plainVar(
                        it.use,
                        recordValue(
                            it.use,
                            "prize" to recordValue(fieldKey(reward), "gold" to DataValue.integer(1)),
                            "count" to computedVar(intUse, "2 + 2"),
                        ),
                    )
                }.created()
            commit(delete(reward)).shouldBeCommitted()

            errorCodesOn(bag) shouldBe listOf("content_type_missing")
            formulas.evaluation(bag, "2 + 2") shouldBe Evaluation.Value(4)
        }
    }

    test("a content value whose declaration dropped a field, and a code record a new generation changed, give their readers no finding") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val (reward, user) = commitSilverPurseUser()
            val reader =
                commitDefinition(
                    "reader",
                    plainType(intUse),
                ) { computedVar(intUse, "first.gold", mapOf("first" to user)) }.created()
            commit(setTypes(reward, declares { record { field("gold", intUse) } })).shouldBeCommitted()

            errorCodesOn(reader).shouldBeEmpty()
        }
        withSetup(staticPage, catalog = changingCodeCatalog(withSilver = true)) {
            val user =
                commitDefinition("first", plainType(changingCodeUse)) {
                    plainVar(
                        changingCodeUse,
                        recordValue(
                            changingCodeUse,
                            "gold" to DataValue.integer(1),
                            "silver" to DataValue.integer(2),
                        ),
                    )
                }.created()
            val reader =
                commitDefinition(
                    "reader",
                    plainType(intUse),
                ) { computedVar(intUse, "first.gold", mapOf("first" to user)) }.created()
            restart(changingCodeCatalog(withSilver = false))

            errorCodesOn(reader).shouldBeEmpty()
        }
    }

    test("a nested value whose type is missing, read through a reference, gives its reader no finding") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val reward = commitTypeDefinition("Reward", declares { record { field("gold", intUse) } }).created()
            val holder =
                commitDefinition("holder", declares { record { field("prize", fieldKey(reward)) } }) {
                    plainVar(it.use, recordValue(it.use, "prize" to recordValue(fieldKey(reward), "gold" to DataValue.integer(1))))
                }.created()
            val reader =
                commitDefinition(
                    "reader",
                    plainType(intUse),
                ) { computedVar(intUse, "holder.prize.gold", mapOf("holder" to holder)) }.created()
            commit(delete(reward)).shouldBeCommitted()

            errorCodesOn(reader).shouldBeEmpty()
            formulas.evaluation(reader).shouldBeInstanceOf<Evaluation.Failed>()
        }
    }

    test("a Var field inside a code record reads as its evaluated T") {
        val page =
            setup("evaluate-code-var") {
                formulaPage {
                    definition("loot", lootUse, FixtureLoot(gold = Var.Computed(Formula("20 + 1"))))
                    formula("gold", intUse, "loot.gold * 2")
                }
            }
        withSetup(page, catalog = routeFixtureCatalog) { demo -> formulas.value(demo.named("gold")) shouldBe 42 }
    }

    test("a Ref field inside a code record reads through to its target") {
        val page =
            setup("evaluate-code-ref") {
                formulaPage {
                    val depot = stock("depot")
                    definition("loot", lootUse, FixtureLoot(givers = listOf(stockRef(depot))))
                    formula("giver_name", textUse, "loot.givers.get(0)?.name ?: \"none\"")
                }
            }
        withSetup(page, catalog = routeFixtureCatalog) { demo -> formulas.value(demo.named("giver_name")) shouldBe "depot" }
    }

    test("a reader of an unfilled Definition has no finding of its own") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val empty = commitDefinition("empty", plainType(intUse)).created()
            val reader =
                commitDefinition(
                    "reader",
                    plainType(intUse),
                ) { computedVar(intUse, "empty + 1", mapOf("empty" to empty)) }.created()

            errorCodesOn(reader).shouldBeEmpty()
            formulas.failure(reader) shouldBe FormulaFailure.Dependency(empty)
        }
    }
}
