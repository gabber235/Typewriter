package com.typewritermc.realm.operation

import com.typewritermc.authoring.of
import com.typewritermc.authoring.with
import com.typewritermc.realm.authoring.location
import com.typewritermc.realm.testing.RealmFixture
import com.typewritermc.realm.testing.linkOrNull
import com.typewritermc.realm.testing.shouldBeCommitted
import com.typewritermc.realm.testing.value
import com.typewritermc.types.of
import com.typewritermc.types.record
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContain
import io.kotest.matchers.collections.shouldNotContain
import io.kotest.matchers.nulls.shouldBeNull
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import skirout.editor.v1.authoring.EditIntent
import skirout.editor.v1.authoring.LinkOccurrenceId
import skirout.editor.v1.authoring.LinkRepairIntent
import skirout.editor.v1.authoring.PreviewTypeArgumentChangeResponse
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.kernel.v1.resource_id.ResourceId

val TypeArgumentOperationsTest by testSuite {
    test("previewing a type of another definition is refused with type_argument_definition_changed") {
        RealmFixture.of(REPAIR_CATALOG, rewardContainer).use { realm ->
            realm
                .preview(container, TypeSelection.of(BUNDLE_COIN))
                .shouldBeInstanceOf<PreviewTypeArgumentChangeResponse.InvalidArgumentsErrorWrapper>()
                .value
                .map { it.code } shouldBe listOf("type_argument_definition_changed")
        }
    }

    test("previewing a change for a missing resource is refused with resource_missing") {
        RealmFixture.of(REPAIR_CATALOG, rewardContainer).use { realm ->
            realm
                .preview(ResourceId(value = "missing"), TypeSelection.of(CONTAINER_COIN))
                .shouldBeInstanceOf<PreviewTypeArgumentChangeResponse.InvalidArgumentsErrorWrapper>()
                .value
                .map { it.code } shouldBe listOf("resource_missing")
        }
    }

    test("an undeclared field a record already holds does not block previewing a change, which leaves it in place") {
        val invalid = rewardContainer.mapValues { (_, record) -> record.with("unknown", DataValue.StringValueWrapper("retained")) }
        RealmFixture.of(REPAIR_CATALOG, invalid).use { realm ->
            realm.preview(container, TypeSelection.of(CONTAINER_COIN)).shouldBeReady().clearedLocations shouldNotContain
                location(container, "unknown")
        }
    }

    test("narrowing a type argument retags its containers, clears incompatible leaves and keeps compatible values") {
        RealmFixture.of(REPAIR_CATALOG, rewardContainer).use { realm ->
            val preview = realm.preview(container, TypeSelection.of(CONTAINER_COIN)).shouldBeReady()
            preview.clearedLocations shouldBe listOf(bundleValue())

            realm.commit(realm.prepare(preview).shouldBePrepared()).shouldBeCommitted()

            realm.resources.getValue(container) shouldBe
                containerRecord(CONTAINER_COIN, LIST_BUNDLE_COIN, BUNDLE_COIN, DataValue.UNFILLED)
        }
    }

    test("a confirmed change is refused with expectation_conflict when a value it keeps changed after the preview") {
        RealmFixture.of(REPAIR_CATALOG, rewardContainer).use { realm ->
            val preview = realm.preview(container, TypeSelection.of(CONTAINER_COIN)).shouldBeReady()
            realm.commit(EditIntent.createSetValue(at = location(container, "reward"), value = gemValue())).shouldBeCommitted()

            realm.prepare(preview).refusalCodes() shouldBe listOf("expectation_conflict")
        }
    }

    test("a confirmed change is refused with catalog_changed once the Realm runs another catalog") {
        RealmFixture.of(REPAIR_CATALOG, rewardContainer).use { realm ->
            val preview = realm.preview(container, TypeSelection.of(CONTAINER_COIN)).shouldBeReady()
            realm.restart()

            realm.prepare(preview).refusalCodes() shouldBe listOf("catalog_changed")
        }
    }

    test("a preview without guards whose resource is gone by confirmation is refused as no longer valid") {
        RealmFixture.of(REPAIR_CATALOG, rewardContainer).use { realm ->
            val preview = realm.preview(container, TypeSelection.of(CONTAINER_COIN)).shouldBeReady()
            realm.commit(EditIntent.createDeleteResource(id = container)).shouldBeCommitted()

            realm.prepare(preview.copy(edit = preview.edit.copy(expectations = emptyList()))).refusalCodes() shouldBe
                listOf("type_argument_preview_no_longer_valid")
        }
    }

    test("a pending selection keeps the independent and compatible fields, clears the open one, and can later be completed") {
        RealmFixture.of(REPAIR_CATALOG, coinGemDual).use { realm ->
            val pending = realm.preview(dual, pendingCoin).shouldBeReady()
            realm.commit(realm.prepare(pending).shouldBePrepared()).shouldBeCommitted()

            val partial = realm.resources.getValue(dual)
            partial.configuration shouldBe pendingCoin
            partial.value("name") shouldBe DataValue.StringValueWrapper("kept")
            partial.value("first") shouldBe DataValue.record(emptyMap())
            partial.value("second") shouldBe DataValue.UNFILLED

            val complete = TypeSelection.of(DUAL_COIN_COIN)
            realm.commit(realm.prepare(realm.preview(dual, complete).shouldBeReady()).shouldBePrepared()).shouldBeCommitted()

            val completed = realm.resources.getValue(dual)
            completed.configuration shouldBe complete
            completed.value("name") shouldBe DataValue.StringValueWrapper("kept")
            completed.value("first") shouldBe DataValue.record(emptyMap())
        }
    }

    test("a preview whose intents were altered is refused with type_argument_preview_mismatch") {
        RealmFixture.of(REPAIR_CATALOG, coinGemDual).use { realm ->
            val preview = realm.preview(dual, pendingCoin).shouldBeReady()
            val altered =
                preview.copy(
                    edit =
                        preview.edit.copy(
                            intents =
                                listOf(
                                    EditIntent.createConfigureResource(
                                        resource = dual,
                                        configuration = TypeSelection.of(DUAL_COIN_COIN),
                                    ),
                                ),
                        ),
                )

            realm.prepare(altered).refusalCodes() shouldBe listOf("type_argument_preview_mismatch")
        }
    }

    test("a preview missing one of its guards is refused with type_argument_preview_mismatch") {
        RealmFixture.of(REPAIR_CATALOG, coinGemDual).use { realm ->
            val preview = realm.preview(dual, pendingCoin).shouldBeReady()
            val unguarded = preview.copy(edit = preview.edit.copy(expectations = preview.edit.expectations.dropLast(1)))

            realm.prepare(unguarded).refusalCodes() shouldBe listOf("type_argument_preview_mismatch")
        }
    }

    test("the exact preview is prepared and commits after an altered one was refused") {
        RealmFixture.of(REPAIR_CATALOG, coinGemDual).use { realm ->
            val preview = realm.preview(dual, pendingCoin).shouldBeReady()
            realm.prepare(preview.copy(edit = preview.edit.copy(expectations = preview.edit.expectations.dropLast(1)))).refusalCodes()

            realm.commit(realm.prepare(preview).shouldBePrepared()).shouldBeCommitted()

            realm.resources.getValue(dual).configuration shouldBe pendingCoin
        }
    }

    test("a pending selection clears a link whose target type becomes unknown on both sides") {
        RealmFixture.of(REPAIR_CATALOG, linkedDual).use { realm ->
            val target = location(dual, "target")
            val preview = realm.preview(dual, pendingCoin).shouldBeReady()
            preview.clearedLocations shouldContain target
            preview.linkRepairs shouldBe
                listOf(LinkRepairIntent.ClearWrapper(LinkOccurrenceId(endpoint = SOURCE_ENDPOINT, location = target)))

            realm.commit(realm.prepare(preview).shouldBePrepared()).shouldBeCommitted()

            realm.resources
                .getValue(dual)
                .linkOrNull("target")
                .shouldBeNull()
            realm.views.read { view -> view.links.values.map { it.target.resource } } shouldNotContain gem
        }
    }
}
