package com.typewritermc.realm.checking

import com.typewritermc.realm.authoring.AuthoringSeed
import com.typewritermc.realm.authoring.GRAPH_CATALOG
import com.typewritermc.realm.authoring.GRAPH_NODES
import com.typewritermc.realm.authoring.ProjectionAt
import com.typewritermc.realm.authoring.Reach
import com.typewritermc.realm.authoring.apply
import com.typewritermc.realm.authoring.evidenceNow
import com.typewritermc.realm.authoring.freshNow
import com.typewritermc.realm.authoring.graphEdits
import com.typewritermc.realm.authoring.graphRecord
import com.typewritermc.realm.authoring.liveNow
import com.typewritermc.realm.authoring.location
import com.typewritermc.realm.authoring.readNow
import com.typewritermc.realm.authoring.record
import com.typewritermc.realm.authoring.relink
import com.typewritermc.realm.edit.MemoryAuthoringStorage
import com.typewritermc.realm.routeFixtureCatalog
import com.typewritermc.realm.testing.NOT_ONE
import com.typewritermc.realm.testing.RealmFixture
import com.typewritermc.realm.testing.checksOf
import com.typewritermc.realm.testing.commit
import com.typewritermc.realm.testing.commitDefinition
import com.typewritermc.realm.testing.commitRecordUser
import com.typewritermc.realm.testing.commitTypeDefinition
import com.typewritermc.realm.testing.computedVar
import com.typewritermc.realm.testing.createEntry
import com.typewritermc.realm.testing.declares
import com.typewritermc.realm.testing.entryRef
import com.typewritermc.realm.testing.errorCodesOn
import com.typewritermc.realm.testing.fieldKey
import com.typewritermc.realm.testing.formulaPage
import com.typewritermc.realm.testing.graphLinkRuns
import com.typewritermc.realm.testing.graphLinksOf
import com.typewritermc.realm.testing.grewFrom
import com.typewritermc.realm.testing.hookCatalog
import com.typewritermc.realm.testing.intUse
import com.typewritermc.realm.testing.notOneRule
import com.typewritermc.realm.testing.openCatalogLeases
import com.typewritermc.realm.testing.plain
import com.typewritermc.realm.testing.plainType
import com.typewritermc.realm.testing.plainVar
import com.typewritermc.realm.testing.rerunSince
import com.typewritermc.realm.testing.resources
import com.typewritermc.realm.testing.setDefinitionValue
import com.typewritermc.realm.testing.setTypes
import com.typewritermc.realm.testing.setVar
import com.typewritermc.realm.testing.settle
import com.typewritermc.realm.testing.settledRuns
import com.typewritermc.realm.testing.shouldBeCommitted
import com.typewritermc.realm.testing.staticPage
import com.typewritermc.realm.testing.textUse
import com.typewritermc.realm.testing.typeUse
import com.typewritermc.realm.testing.usagesOf
import com.typewritermc.realm.testing.withSetup
import com.typewritermc.setup.setup
import com.typewritermc.types.integer
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.nondeterministic.eventually
import io.kotest.matchers.collections.shouldContain
import io.kotest.matchers.collections.shouldNotBeEmpty
import io.kotest.matchers.collections.shouldNotContain
import io.kotest.matchers.shouldBe
import io.kotest.property.Arb
import io.kotest.property.PropTestConfig
import io.kotest.property.arbitrary.list
import io.kotest.property.checkAll
import skirout.editor.v1.authoring.EditIntent
import skirout.editor.v1.checking.FindingStatus
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.DataValue
import skirout.kernel.v1.resource_id.ResourceId
import java.lang.ref.WeakReference
import kotlin.time.Duration.Companion.seconds

val CheckRerunsTest by testSuite {
    val first = ResourceId(value = "first")
    val second = ResourceId(value = "second")
    val seed = mapOf(first to record(name = "bad"))

    test("start runs every check once") {
        reruns(seed) {
            runsByLabel() shouldBe mapOf("name@first" to 1L, "count@first" to 1L, "ghost" to 1L, "selection" to 1L)
        }
    }

    test("a commit reruns the check that read the changed field") {
        reruns(seed) {
            val before = graphRuns.checkRuns()
            commitChecked(rename(first, "valid"))

            rerunLabelsSince(before) shouldContain "name@first"
            reportedByLabel().map { it.first } shouldNotContain "name@first"
        }
    }

    test("a commit reruns no check that read other fields of that resource") {
        reruns(seed) {
            val before = graphRuns.checkRuns()
            commitChecked(rename(first, "valid"))

            rerunLabelsSince(before) shouldBe setOf("name@first")
        }
    }

    test("a commit that changes nothing anyone read reruns nothing") {
        reruns(seed) {
            val before = graphRuns.checkRuns()
            commitChecked(renumber(first))

            rerunLabelsSince(before) shouldBe emptySet()
        }
    }

    test("a rerun with an equal result gives an equal set and sends no hint") {
        reruns(seed) {
            views.capture().use { earlier ->
                val sent = hints
                commitChecked(renumber(first))

                capturedByLabel(earlier.root) shouldBe liveByLabel()
                hints shouldBe sent
            }
        }
    }

    test("creating an unrelated resource keeps a finding current, and its evidence holds no resource ids fact") {
        reruns(seed) {
            val before = findingsOf("name@first")
            commitChecked(create(second))

            findingsOf("name@first") shouldBe before
            findingsOf("name@first").status shouldBe FindingStatus.CURRENT
            findingsOf("name@first").expectations.holdsResourceIds shouldBe false
        }
    }

    test("a check that selected resources has the resource ids fact in its evidence") {
        reruns(seed) {
            findingsOf("selection").expectations.holdsResourceIds shouldBe true
        }
    }

    test("a check that read a missing resource reruns when it appears") {
        reruns(seed) {
            val before = graphRuns.checkRuns()
            commitChecked(create(GHOST))

            rerunLabelsSince(before) shouldContain "ghost"
            reportedByLabel() shouldNotContain ("ghost" to "Ghost is missing.")
        }
    }

    test("a check that read a selection reruns when a resource joins it") {
        reruns(seed) {
            val before = graphRuns.checkRuns()
            commitChecked(create(second))

            rerunLabelsSince(before) shouldContain "selection"
            reportedByLabel() shouldNotContain ("selection" to "Fewer than two resources.")
        }
    }

    test("creating a resource reruns no check of another resource") {
        reruns(seed) {
            val before = graphRuns.checkRuns()
            commitChecked(create(second))

            rerunLabelsSince(before) shouldBe setOf("count@second", "name@second", "selection")
        }
    }

    test("a resource created by a commit gets its checks scheduled, and a removed one loses them") {
        reruns(seed) {
            commitChecked(create(second, name = "bad"))
            settle()
            reportedByLabel() shouldContain ("name@second" to "Name is invalid.")

            commitChecked(EditIntent.createDeleteResource(id = second))
            settle()
            checks.findings().map { it.ticket.instance.label }.filter { it.endsWith("@second") } shouldBe emptyList()
        }
    }

    test("removing and restoring a resource gives it findings again") {
        reruns(seed) {
            commitChecked(EditIntent.createDeleteResource(id = first))
            commitChecked(EditIntent.createCreateResource(id = first, record = record(name = "bad")))
            settle()

            reportedByLabel() shouldContain ("name@first" to "Name is invalid.")
            findingsOf("name@first").status shouldBe FindingStatus.CURRENT
        }
    }

    test("a check's evidence lists every fact it read, also through a memo") {
        reruns(seed) {
            val before = findingsOf("name@first").expectations
            commitChecked(renumber(first))

            findingsOf("name@first").expectations shouldBe before
            before.valueLocations() shouldContain location(first, "name")
        }
    }

    test("findings stay current while nothing they read changed") {
        reruns(seed) {
            val before = checks.findings()
            commitChecked(renumber(first))
            commitChecked(recount(first, 1))
            settle()

            checks.findings() shouldBe before
            checks.findings().map { it.status }.toSet() shouldBe setOf(FindingStatus.CURRENT)
        }
    }

    test("two quick commits settle on the findings of the last one") {
        reruns(seed) {
            commit(rename(first, "other")).shouldBeCommitted()
            commit(rename(first, "valid")).shouldBeCommitted()
            settle()

            reportedByLabel().map { it.first } shouldNotContain "name@first"
            checks.findings().map { it.status }.toSet() shouldBe setOf(FindingStatus.CURRENT)
        }
    }

    test("a check that throws keeps its failure finding, and later commits still rerun checks") {
        reruns(mapOf(first to record(name = "throw"))) {
            findingsOf("name@first").failureCodes shouldBe listOf("check_callback_failed")

            commitChecked(recount(first, -1))
            settle()
            findingsOf("name@first").failureCodes shouldBe listOf("check_callback_failed")
            reportedByLabel() shouldContain ("count@first" to "Count is negative.")

            commitChecked(rename(first, "valid"))
            settle()
            findingsOf("name@first").failureCodes shouldBe emptyList()
        }
    }

    test("a check whose own code recurses forever gets its failure finding, and the other checks stay current") {
        reruns(mapOf(first to record(name = "recurse"))) {
            findingsOf("name@first").failureCodes shouldBe listOf("check_callback_failed")
            findingsOf("count@first").status shouldBe FindingStatus.CURRENT
            findingsOf("count@first").failureCodes shouldBe emptyList()
        }
    }

    test("a check that throws NoClassDefFoundError gets its failure finding, and later passes still run") {
        reruns(mapOf(first to record(name = "linkage"))) {
            findingsOf("name@first").failureCodes shouldBe listOf("check_callback_failed")

            commitChecked(rename(first, "valid"))
            settle()
            findingsOf("name@first").failureCodes shouldBe emptyList()
        }
    }

    test("a check provider whose register throws NoClassDefFoundError gives one registration finding") {
        reruns(seed, rerunCatalog(checksOf(31, UnlinkableChecks))) {
            checks.findings().flatMap { it.failureCodes } shouldBe listOf("check_registration_failed")
        }
    }

    test("a new generation reruns every check") {
        reruns(seed) {
            val before = graphRuns.checkRuns()
            owner.activateCatalog(rerunCatalog().lease(CatalogGeneration(value = "next")), {}, {})

            rerunLabelsSince(before) shouldBe setOf("count@first", "ghost", "name@first", "selection")
        }
    }

    test("a changed finding sends a hint") {
        reruns(seed) {
            val sent = hints
            commitChecked(rename(first, "valid"))
            settle()

            hints shouldBe sent + 1
        }
    }

    test("a removed instance sends a hint") {
        reruns(seed + (second to record(name = "valid"))) {
            val sent = hints
            commitChecked(EditIntent.createDeleteResource(id = second))
            settle()

            (hints > sent) shouldBe true
        }
    }

    test("a pass of memo hits sends no hint") {
        reruns(seed) {
            val sent = hints
            commitChecked(renumber(first))
            settle()

            hints shouldBe sent
        }
    }

    test("a view replaced by later commits becomes collectable") {
        reruns(seed) {
            val old = WeakReference(currentView)
            repeat(3) { commitChecked(recount(first, it + 2)) }
            settle()

            eventually(10.seconds) {
                System.gc()
                old.get() shouldBe null
            }
        }
    }

    test("publication judges the captured view even when a commit landed after the capture") {
        reruns(mapOf(first to record(name = "valid"))) {
            views.capture().use { capture ->
                commitChecked(rename(first, "bad"))

                capturedByLabel(capture.root).getValue("name@first").first shouldBe emptyList()
                reportedByLabel() shouldContain ("name@first" to "Name is invalid.")
            }
        }
    }

    test("a failed persist reruns nothing, and the view and the graph stay as they were") {
        val storage = MemoryAuthoringStorage(AuthoringSeed(seed))
        reruns(seed, storage = storage) {
            val saved = resources
            val findings = checks.findings()
            val before = graphRuns.checkRuns()
            storage.failBeforeWrite = true
            runCatching { commit(rename(first, "valid")) }.isSuccess shouldBe false
            storage.failBeforeWrite = false

            rerunLabelsSince(before) shouldBe emptySet()
            resources shouldBe saved
            checks.findings() shouldBe findings
        }
    }

    test("a reload from storage with equal content reruns nothing") {
        reruns(seed) {
            val before = graphRuns.checkRuns()
            reloadFromStorage()

            rerunLabelsSince(before) shouldBe emptySet()
        }
    }

    test("a reload from storage that fails once leaves later commits rerunning checks") {
        val storage = MemoryAuthoringStorage(AuthoringSeed(seed))
        reruns(seed, storage = storage) {
            storage.failReads = true
            reloadFromStorage()
            settle()
            storage.failReads = false

            commitChecked(rename(first, "valid"))
            reportedByLabel().map { it.first } shouldNotContain "name@first"
            checks.findings().map { it.status }.toSet() shouldBe setOf(FindingStatus.CURRENT)
        }
    }

    test("a new generation installed during a pass ends on the new catalog's findings, with no pass mixing the two") {
        reruns(mapOf(first to record(name = "valid"))) {
            commit(rename(first, "gated")).shouldBeCommitted()
            RerunGate.awaitEntered()
            owner.activateCatalog(rerunCatalog().lease(CatalogGeneration(value = "next")), {}, {})
            RerunGate.release()
            settle()

            findingGenerations() shouldBe setOf("next")
            reportedByLabel() shouldContain ("name@first" to "Name is invalid.")
        }
    }

    test("publication reuses check results for what did not change") {
        reruns(seed + (second to record(name = "bad"))) {
            views.capture().use { earlier ->
                commitChecked(rename(first, "valid"))
                val runs = NameCheckRuns.snapshot()

                capturedByLabel(earlier.root).keys shouldContain "name@second"
                NameCheckRuns.since(runs) shouldBe mapOf(first to 1)
            }
        }
    }

    test("publication while a new generation installs does not mix catalogs") {
        reruns(seed) {
            val generation = generation
            views.capture().use { earlier ->
                owner.activateCatalog(rerunCatalog().lease(CatalogGeneration(value = "next")), {}, {})

                checks.evaluateCapture(earlier.root).results.mapTo(hashSetOf()) { it.ticket.catalog } shouldBe setOf(generation)
            }
        }
    }

    test("closing the realm during a run leaves no job running") {
        reruns(mapOf(first to record(name = "valid"))) {
            val leases = openCatalogLeases()
            commit(rename(first, "gated")).shouldBeCommitted()
            RerunGate.awaitEntered()

            val closed = waitingOn { close() }
            leases() shouldBe 1
            RerunGate.release()
            closed()
            leases() shouldBe 0
        }
    }

    test("after any value edit, every graph read equals a fresh computation, answer and evidence") {
        checkAll(PropTestConfig(seed = 5_310_227_101L, iterations = 40), Arb.list(graphEdits, 1..6)) { edits ->
            val start =
                mapOf(
                    GRAPH_NODES[0] to graphRecord(GRAPH_NODES[0], listOf(GRAPH_NODES[1])),
                    GRAPH_NODES[1] to graphRecord(GRAPH_NODES[1], emptyList()),
                )
            RealmFixture.of(GRAPH_CATALOG, start).use { realm ->
                realm.resources.keys.forEach { realm.liveNow(Reach(it)) }
                edits.forEach { edit ->
                    realm.apply(edit)
                    realm.resources.keys.forEach { node -> realm.liveNow(Reach(node)) shouldBe realm.freshNow(Reach(node)) }
                }
            }
        }
    }

    // Graph reads, through a query that reads as a check does.
    val x = ResourceId(value = "x")
    val y = ResourceId(value = "y")
    val z = ResourceId(value = "z")
    val w = ResourceId(value = "w")
    val chain =
        mapOf(
            x to graphRecord(x, listOf(y)),
            y to graphRecord(y, listOf(z)),
            z to graphRecord(z, emptyList()),
            w to graphRecord(w, emptyList()),
        )

    test("a commit that changes one link reruns LinksAt only at its two ends") {
        RealmFixture.of(GRAPH_CATALOG, chain).use { realm ->
            realm.readNow(Reach(x)) shouldBe setOf(x, y, z)
            val before = realm.graphRuns.linkReads()
            realm.commit(relink(y, listOf(w))).shouldBeCommitted()

            realm.readNow(Reach(x)) shouldBe setOf(x, y, w)
            realm.graphRuns.linkReads().grewFrom(before) shouldBe setOf(y, w)
        }
    }

    test("creating an unrelated resource keeps a graph read's result, and its evidence holds no resource ids fact") {
        RealmFixture.of(GRAPH_CATALOG, chain).use { realm ->
            realm.readNow(Reach(x))
            val before = realm.graphRuns.linkReads()
            realm
                .commit(
                    EditIntent.createCreateResource(
                        id = ResourceId(value = "v"),
                        record = graphRecord(ResourceId(value = "v"), emptyList()),
                    ),
                ).shouldBeCommitted()

            realm.readNow(Reach(x)) shouldBe setOf(x, y, z)
            realm.graphRuns.linkReads().grewFrom(before) shouldBe emptySet()
            realm.evidenceNow(Reach(x)).holdsResourceIds shouldBe false
        }
    }

    // Content: hooks, formulas and values of content types, on a real Realm.
    val gold = declares { record { field("gold", intUse) } }
    val silver = declares { record("k1") { field("silver", intUse) } }

    test("a hook that throws during verification leaves later commits rerunning checks") {
        withSetup(setup("reruns-hook") { formulaPage { smith("throw") } }, catalog = hookCatalog()) { page ->
            errorCodesOn(page.named("throw")) shouldBe listOf("dynamic_failed")

            commit(rename(page.named("throw"), "mended")).shouldBeCommitted()
            errorCodesOn(page.named("throw")) shouldBe emptyList()
        }
    }

    test("a check that read a value of a content type reruns when the declaration on another resource changes") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val reward = commitTypeDefinition("Reward", gold).created()
            val user = commitRecordUser("first", reward, "gold" to DataValue.integer(1))
            val before = settledRuns()
            commit(setTypes(reward, silver)).shouldBeCommitted()
            settle()

            rerunSince(before).resources() shouldContain user
        }
    }

    test("a graph read over a content typed value reruns when a declaration changes") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val reward = commitTypeDefinition("Reward", gold).created()
            val user = commitRecordUser("first", reward, "gold" to DataValue.integer(1))
            readNow(ProjectionAt(user))
            val before = graphRuns.judgements()
            commit(setTypes(reward, silver)).shouldBeCommitted()
            readNow(ProjectionAt(user))

            graphRuns.judgements().grewFrom(before) shouldContain user
        }
    }

    test("a value edit that keeps a resource's links rejudges no other resource's links") {
        val page = setup("reruns-kept-links") { formulaPage { repeat(3) { definition("n$it", intUse, it) } } }
        withSetup(page, catalog = hookCatalog()) { seeded ->
            val edited = seeded.named("n0")
            val linked = resources.keys.filter { readNow(ProjectionAt(it)).projections.isNotEmpty() }
            val before = graphRuns.judgements()
            commit(setVar(edited, intUse, plain(5))).shouldBeCommitted()
            linked.forEach { readNow(ProjectionAt(it)) }

            linked.shouldNotBeEmpty()
            graphRuns.judgements().grewFrom(before) - edited shouldBe emptySet()
        }
    }

    test("a declaration edit reruns no graph read that never reached a user of it") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val reward = commitTypeDefinition("Reward", gold).created()
            commitRecordUser("first", reward, "gold" to DataValue.integer(1))
            val bystander = createEntry("bystander").also { commit(it).shouldBeCommitted() }.id
            readNow(ProjectionAt(bystander))
            val before = graphRuns.judgements()
            commit(setTypes(reward, silver)).shouldBeCommitted()
            readNow(ProjectionAt(bystander))

            graphRuns.judgements().grewFrom(before) shouldNotContain bystander
        }
    }

    test("changing an alias reruns a graph read over its users") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val amount = commitTypeDefinition("Amount", plainType(intUse)).created()
            val user = commitDefinition("user", plainType(fieldKey(amount))) { plainVar(it.use, DataValue.integer(1)) }.created()
            readNow(ProjectionAt(user))
            val before = graphRuns.judgements()
            commit(setDefinitionValue(amount, plainVar(typeUse, DataValue.TypeUseWrapper(textUse)))).shouldBeCommitted()
            readNow(ProjectionAt(user))

            graphRuns.judgements().grewFrom(before) shouldContain user
        }
    }

    test("a formula naming an entry does not rerun a check over that entry's graph links") {
        withSetup(setup("reruns-formula-names") { formulaPage { smith("smith") } }, catalog = routeFixtureCatalog) { page ->
            val smith = page.named("smith")
            graphLinksOf(smith)
            val runs = graphLinkRuns(smith)
            val giver = commitDefinition("giver", plainType(entryRef)) { computedVar(it.use, "smith", mapOf("smith" to smith)) }.created()

            usagesOf(smith) shouldContain giver
            graphLinksOf(smith) shouldNotContain giver
            graphLinkRuns(smith) shouldBe runs
        }
    }

    test("a portable rule over a content typed value reruns when the declaration changes") {
        withSetup(staticPage, catalog = routeFixtureCatalog.copy(configurations = { listOf(notOneRule(it)) })) {
            val amount = commitTypeDefinition("Amount", plainType(intUse)).created()
            val user = commitDefinition("user", plainType(fieldKey(amount))) { plainVar(it.use, DataValue.integer(1)) }.created()
            errorCodesOn(user) shouldContain NOT_ONE

            commit(setDefinitionValue(amount, plainVar(typeUse, DataValue.TypeUseWrapper(textUse)))).shouldBeCommitted()
            errorCodesOn(user) shouldNotContain NOT_ONE
        }
    }
}
