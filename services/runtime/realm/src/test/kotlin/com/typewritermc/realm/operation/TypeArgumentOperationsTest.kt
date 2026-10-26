package com.typewritermc.realm.operation

import com.typewritermc.authoring.of
import com.typewritermc.authoring.with
import com.typewritermc.realm.testing.DefinitionCatalog
import com.typewritermc.realm.testing.RealmFixture
import com.typewritermc.realm.testing.codes
import com.typewritermc.realm.testing.linkOrNull
import com.typewritermc.realm.testing.shouldBeCommitted
import com.typewritermc.realm.testing.value
import com.typewritermc.types.listValue
import com.typewritermc.types.named
import com.typewritermc.types.namedTemplate
import com.typewritermc.types.namedUse
import com.typewritermc.types.of
import com.typewritermc.types.qualified
import com.typewritermc.types.record
import com.typewritermc.types.template
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
import skirout.editor.v1.authoring.PrepareTypeArgumentChangeResponse
import skirout.editor.v1.authoring.PreparedEdit
import skirout.editor.v1.authoring.PreviewTypeArgumentChangeResponse
import skirout.editor.v1.authoring.TypeArgumentChangePreview
import skirout.editor.v1.catalog.EndpointCardinality
import skirout.editor.v1.catalog.EndpointDefinition
import skirout.editor.v1.catalog.EndpointSlot
import skirout.editor.v1.catalog.RelationContract
import skirout.editor.v1.catalog.RelationDeletePolicy
import skirout.editor.v1.type_catalog.ArgumentSelection
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.CollectionKind
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.EndpointId
import skirout.editor.v1.type_catalog.FieldDeclaration
import skirout.editor.v1.type_catalog.FieldOwner
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.LinkTarget
import skirout.editor.v1.type_catalog.ListItem
import skirout.editor.v1.type_catalog.NamedTypeUse
import skirout.editor.v1.type_catalog.ParameterKey
import skirout.editor.v1.type_catalog.PathSegment
import skirout.editor.v1.type_catalog.RelationId
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeParameter
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.type_catalog.ValuePath
import skirout.kernel.v1.resource_id.ResourceId

private val REWARD = definition("reward")
private val COIN = definition("coin")
private val GEM = definition("gem")
private val BUNDLE = definition("bundle")
private val LIST = definition("list")
private val CONTAINER = definition("container")
private val DUAL = definition("dual")
private val LINK = definition("link")
private val BUNDLE_PARAMETER = ParameterKey(owner = BUNDLE, index = 0)
private val LIST_PARAMETER = ParameterKey(owner = LIST, index = 0)
private val CONTAINER_PARAMETER = ParameterKey(owner = CONTAINER, index = 0)
private val DUAL_FIRST_PARAMETER = ParameterKey(owner = DUAL, index = 0)
private val DUAL_SECOND_PARAMETER = ParameterKey(owner = DUAL, index = 1)
private val LINK_PARAMETER = ParameterKey(owner = LINK, index = 0)
private val REWARD_USE = REWARD.use()
private val COIN_USE = COIN.namedUse()
private val GEM_USE = GEM.namedUse()
private val BUNDLE_REWARD = BUNDLE.namedUse(listOf(REWARD_USE))
private val BUNDLE_COIN = BUNDLE.namedUse(listOf(COIN_USE.use))
private val LIST_BUNDLE_REWARD = LIST.namedUse(listOf(BUNDLE_REWARD.use))
private val LIST_BUNDLE_COIN = LIST.namedUse(listOf(BUNDLE_COIN.use))
private val CONTAINER_REWARD = CONTAINER.namedUse(listOf(REWARD_USE))
private val CONTAINER_COIN = CONTAINER.namedUse(listOf(COIN_USE.use))
private val DUAL_COIN_GEM = DUAL.namedUse(listOf(COIN_USE.use, GEM_USE.use))
private val DUAL_COIN_COIN = DUAL.namedUse(listOf(COIN_USE.use, COIN_USE.use))
private val LINK_GEM = LINK.namedUse(listOf(GEM_USE.use))
private val SOURCE_ENDPOINT = EndpointId(value = "dual:source")
private val TARGET_ENDPOINT = EndpointId(value = "dual:target")
private val RELATION = RelationId(value = "dual:relation")
private val DUAL_RELATION =
    RelationContract.of(
        RELATION,
        EndpointDefinition(
            id = SOURCE_ENDPOINT,
            slot = EndpointSlot.FIRST,
            resource = DUAL.namedTemplate(listOf(DUAL_FIRST_PARAMETER.template, DUAL_SECOND_PARAMETER.template)),
            cardinality = EndpointCardinality.ONE,
            onDelete = RelationDeletePolicy.CLEAR,
        ),
        EndpointDefinition(
            id = TARGET_ENDPOINT,
            slot = EndpointSlot.SECOND,
            resource = REWARD.namedTemplate(),
            cardinality = EndpointCardinality.ONE,
            onDelete = RelationDeletePolicy.CLEAR,
        ),
    )

private val REPAIR_DEFINITIONS =
    listOf(
        TypeDefinition.partial(id = REWARD, representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = true)),
        TypeDefinition.partial(
            id = COIN,
            representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = false),
            parents = listOf(REWARD.namedTemplate()),
        ),
        TypeDefinition.partial(
            id = GEM,
            representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = false),
            parents = listOf(REWARD.namedTemplate()),
        ),
        TypeDefinition.partial(
            id = BUNDLE,
            parameters = listOf(TypeParameter.partial(key = BUNDLE_PARAMETER, name = "value")),
            representation =
                RepresentationTemplate.createRecord(
                    fields =
                        listOf(
                            FieldDeclaration.partial(
                                owner = FieldOwner(definition = BUNDLE, name = "title"),
                                type = ScalarKind.TEXT.template,
                            ),
                            FieldDeclaration.partial(
                                owner = FieldOwner(definition = BUNDLE, name = "value"),
                                type = BUNDLE_PARAMETER.template,
                            ),
                        ),
                    abstract_ = false,
                ),
        ),
        TypeDefinition.partial(
            id = LIST,
            parameters = listOf(TypeParameter.partial(key = LIST_PARAMETER, name = "item")),
            representation = RepresentationTemplate.createSequence(item = LIST_PARAMETER.template, kind = CollectionKind.LIST),
        ),
        TypeDefinition.partial(
            id = CONTAINER,
            parameters = listOf(TypeParameter.partial(key = CONTAINER_PARAMETER, name = "reward")),
            representation =
                RepresentationTemplate.createRecord(
                    fields =
                        listOf(
                            FieldDeclaration.partial(
                                owner = FieldOwner(definition = CONTAINER, name = "bundles"),
                                type = LIST.template(listOf(BUNDLE.template(listOf(CONTAINER_PARAMETER.template)))),
                            ),
                            FieldDeclaration.partial(
                                owner = FieldOwner(definition = CONTAINER, name = "reward"),
                                type = CONTAINER_PARAMETER.template,
                            ),
                        ),
                    abstract_ = false,
                ),
        ),
        TypeDefinition.partial(
            id = LINK,
            parameters = listOf(TypeParameter.partial(key = LINK_PARAMETER, name = "target")),
            representation = RepresentationTemplate.createLink(endpoint = SOURCE_ENDPOINT, target = LINK_PARAMETER.template),
        ),
        TypeDefinition.partial(
            id = DUAL,
            parameters =
                listOf(
                    TypeParameter.partial(key = DUAL_FIRST_PARAMETER, name = "first"),
                    TypeParameter.partial(key = DUAL_SECOND_PARAMETER, name = "second"),
                ),
            representation =
                RepresentationTemplate.createRecord(
                    fields =
                        listOf(
                            FieldDeclaration.partial(owner = FieldOwner(definition = DUAL, name = "name"), type = ScalarKind.TEXT.template),
                            FieldDeclaration.partial(
                                owner = FieldOwner(definition = DUAL, name = "first"),
                                type = DUAL_FIRST_PARAMETER.template,
                            ),
                            FieldDeclaration.partial(
                                owner = FieldOwner(definition = DUAL, name = "second"),
                                type = DUAL_SECOND_PARAMETER.template,
                            ),
                            FieldDeclaration.partial(
                                owner = FieldOwner(definition = DUAL, name = "target"),
                                type = LINK.template(listOf(DUAL_SECOND_PARAMETER.template)),
                            ),
                        ),
                    abstract_ = false,
                ),
        ),
    )

private fun definition(name: String) = TypeDefinitionId.qualified("repair", name)

private val container = ResourceId(value = "container")
private val dual = ResourceId(value = "dual")
private val gem = ResourceId(value = "gem")
private val bundleItem = ItemId(value = "bundle")

/** A pending dual selection: the first argument chosen as coin, the second left open. */
private val pendingCoin =
    TypeSelection.createPending(
        definition = DUAL,
        arguments = listOf(ArgumentSelection.ChosenWrapper(COIN_USE.use), ArgumentSelection.UNFILLED),
    )

/** A container of rewards whose one bundle holds a gem, and whose own reward is a coin. */
private val rewardContainer =
    mapOf(container to containerRecord(CONTAINER_REWARD, LIST_BUNDLE_REWARD, BUNDLE_REWARD, gemValue()))

/** A dual of coin and gem with a name and both values filled. */
private val coinGemDual = mapOf(dual to dualRecord(TypeSelection.CompleteWrapper(DUAL_COIN_GEM)))

/** The coin and gem dual linked to a gem resource through its second argument. */
private val linkedDual =
    mapOf(
        dual to
            dualRecord(TypeSelection.CompleteWrapper(DUAL_COIN_GEM)).with(
                "target",
                DataValue.named(
                    LINK_GEM,
                    DataValue.createLink(endpoint = SOURCE_ENDPOINT, target = LinkTarget(resource = gem, opposite = null)),
                ),
            ),
        gem to AuthoringRecord.of(TypeSelection.CompleteWrapper(GEM_USE), emptyMap()),
    )

private val REPAIR_CATALOG = DefinitionCatalog(REPAIR_DEFINITIONS, listOf(DUAL_RELATION))

val TypeArgumentOperationsTest by testSuite {
    test("previewing a type of another definition is refused with type_argument_definition_changed") {
        RealmFixture.of(REPAIR_CATALOG, rewardContainer).use { realm ->
            realm
                .preview(container, TypeSelection.CompleteWrapper(BUNDLE_COIN))
                .shouldBeInstanceOf<PreviewTypeArgumentChangeResponse.InvalidArgumentsErrorWrapper>()
                .value
                .map { it.code } shouldBe listOf("type_argument_definition_changed")
        }
    }

    test("previewing a change for a missing resource is refused with resource_missing") {
        RealmFixture.of(REPAIR_CATALOG, rewardContainer).use { realm ->
            realm
                .preview(ResourceId(value = "missing"), TypeSelection.CompleteWrapper(CONTAINER_COIN))
                .shouldBeInstanceOf<PreviewTypeArgumentChangeResponse.InvalidArgumentsErrorWrapper>()
                .value
                .map { it.code } shouldBe listOf("resource_missing")
        }
    }

    test("previewing a change on a record with an undeclared field is refused at that field") {
        val invalid = rewardContainer.mapValues { (_, record) -> record.with("unknown", DataValue.StringValueWrapper("retained")) }
        RealmFixture.of(REPAIR_CATALOG, invalid).use { realm ->
            realm
                .preview(container, TypeSelection.CompleteWrapper(CONTAINER_COIN))
                .shouldBeInstanceOf<PreviewTypeArgumentChangeResponse.RejectedErrorWrapper>()
                .value
                .map { it.location } shouldContain location(container, "unknown")
        }
    }

    test("narrowing a type argument retags its containers, clears incompatible leaves and keeps compatible values") {
        RealmFixture.of(REPAIR_CATALOG, rewardContainer).use { realm ->
            val preview = realm.preview(container, TypeSelection.CompleteWrapper(CONTAINER_COIN)).shouldBeReady()
            preview.clearedLocations shouldBe listOf(bundleValue())

            realm.commit(realm.prepare(preview).shouldBePrepared()).shouldBeCommitted()

            realm.resources.getValue(container) shouldBe
                containerRecord(CONTAINER_COIN, LIST_BUNDLE_COIN, BUNDLE_COIN, DataValue.UNFILLED)
        }
    }

    test("a confirmed change is refused with expectation_conflict when a value it keeps changed after the preview") {
        RealmFixture.of(REPAIR_CATALOG, rewardContainer).use { realm ->
            val preview = realm.preview(container, TypeSelection.CompleteWrapper(CONTAINER_COIN)).shouldBeReady()
            realm.commit(EditIntent.createSetValue(at = location(container, "reward"), value = gemValue())).shouldBeCommitted()

            realm.prepare(preview).refusalCodes() shouldBe listOf("expectation_conflict")
        }
    }

    test("a confirmed change is refused with catalog_changed once the Realm runs another catalog") {
        RealmFixture.of(REPAIR_CATALOG, rewardContainer).use { realm ->
            val preview = realm.preview(container, TypeSelection.CompleteWrapper(CONTAINER_COIN)).shouldBeReady()
            realm.restart()

            realm.prepare(preview).refusalCodes() shouldBe listOf("catalog_changed")
        }
    }

    test("a preview without guards whose resource is gone by confirmation is refused as no longer valid") {
        RealmFixture.of(REPAIR_CATALOG, rewardContainer).use { realm ->
            val preview = realm.preview(container, TypeSelection.CompleteWrapper(CONTAINER_COIN)).shouldBeReady()
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

            val complete = TypeSelection.CompleteWrapper(DUAL_COIN_COIN)
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
                                        configuration = TypeSelection.CompleteWrapper(DUAL_COIN_COIN),
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

/** Previews changing [resource] to [requested] on the state the Realm holds now. */
private fun RealmFixture.preview(
    resource: ResourceId,
    requested: TypeSelection,
): PreviewTypeArgumentChangeResponse =
    views.capture().use { snapshot -> DefaultTypeArgumentOperations(views).preview(resource, requested, snapshot) }

/** Confirms [preview] against the state the Realm holds now. */
private suspend fun RealmFixture.prepare(preview: TypeArgumentChangePreview): PrepareTypeArgumentChangeResponse =
    DefaultTypeArgumentOperations(views).prepare(preview)

private fun PreviewTypeArgumentChangeResponse.shouldBeReady(): TypeArgumentChangePreview =
    shouldBeInstanceOf<PreviewTypeArgumentChangeResponse.ReadyWrapper>().value

private fun PrepareTypeArgumentChangeResponse.shouldBePrepared(): PreparedEdit =
    shouldBeInstanceOf<PrepareTypeArgumentChangeResponse.PreparedWrapper>().value.edit

private fun PrepareTypeArgumentChangeResponse.refusalCodes(): List<String> =
    shouldBeInstanceOf<PrepareTypeArgumentChangeResponse.RejectedErrorWrapper>().value.codes

/** The value leaf of the container's one bundle. */
private fun bundleValue() =
    ValueLocation.of(
        container,
        ValuePath(
            segments =
                listOf(
                    PathSegment.createField(name = "bundles"),
                    PathSegment.createItem(id = bundleItem),
                    PathSegment.createField(name = "value"),
                ),
        ),
    )

private fun gemValue() = DataValue.named(GEM_USE, DataValue.record(emptyMap()))

private fun containerRecord(
    configuration: NamedTypeUse,
    list: NamedTypeUse,
    bundle: NamedTypeUse,
    value: DataValue,
): AuthoringRecord =
    AuthoringRecord.of(
        configuration = TypeSelection.CompleteWrapper(configuration),
        fields =
            mapOf(
                "bundles" to
                    DataValue.named(
                        list,
                        DataValue.listValue(
                            listOf(
                                ListItem(
                                    id = bundleItem,
                                    value =
                                        DataValue.named(
                                            bundle,
                                            DataValue.record(mapOf("title" to DataValue.StringValueWrapper("kept"), "value" to value)),
                                        ),
                                ),
                            ),
                        ),
                    ),
                "reward" to DataValue.named(COIN_USE, DataValue.record(emptyMap())),
            ),
    )

private fun dualRecord(selection: TypeSelection): AuthoringRecord =
    AuthoringRecord.of(
        configuration = selection,
        fields =
            mapOf(
                "name" to DataValue.StringValueWrapper("kept"),
                "first" to DataValue.named(COIN_USE, DataValue.record(emptyMap())),
                "second" to DataValue.named(GEM_USE, DataValue.record(emptyMap())),
            ),
    )

private fun location(
    resource: ResourceId,
    field: String,
) = ValueLocation.of(
    resource,
    ValuePath(
        segments =
            listOf(
                PathSegment.createField(name = field),
            ),
    ),
)
