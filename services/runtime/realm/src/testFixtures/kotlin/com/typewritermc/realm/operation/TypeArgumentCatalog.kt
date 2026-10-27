package com.typewritermc.realm.operation

import com.typewritermc.authoring.of
import com.typewritermc.authoring.with
import com.typewritermc.realm.testing.DefinitionCatalog
import com.typewritermc.realm.testing.RealmFixture
import com.typewritermc.realm.testing.codes
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
import io.kotest.matchers.types.shouldBeInstanceOf
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

internal val REWARD = definition("reward")
internal val COIN = definition("coin")
internal val GEM = definition("gem")
internal val BUNDLE = definition("bundle")
internal val LIST = definition("list")
internal val CONTAINER = definition("container")
internal val DUAL = definition("dual")
internal val LINK = definition("link")
internal val BUNDLE_PARAMETER = ParameterKey(owner = BUNDLE, index = 0)
internal val LIST_PARAMETER = ParameterKey(owner = LIST, index = 0)
internal val CONTAINER_PARAMETER = ParameterKey(owner = CONTAINER, index = 0)
internal val DUAL_FIRST_PARAMETER = ParameterKey(owner = DUAL, index = 0)
internal val DUAL_SECOND_PARAMETER = ParameterKey(owner = DUAL, index = 1)
internal val LINK_PARAMETER = ParameterKey(owner = LINK, index = 0)
internal val REWARD_USE = REWARD.use()
internal val COIN_USE = COIN.namedUse()
internal val GEM_USE = GEM.namedUse()
internal val BUNDLE_REWARD = BUNDLE.namedUse(listOf(REWARD_USE))
internal val BUNDLE_COIN = BUNDLE.namedUse(listOf(COIN_USE.use))
internal val LIST_BUNDLE_REWARD = LIST.namedUse(listOf(BUNDLE_REWARD.use))
internal val LIST_BUNDLE_COIN = LIST.namedUse(listOf(BUNDLE_COIN.use))
internal val CONTAINER_REWARD = CONTAINER.namedUse(listOf(REWARD_USE))
internal val CONTAINER_COIN = CONTAINER.namedUse(listOf(COIN_USE.use))
internal val DUAL_COIN_GEM = DUAL.namedUse(listOf(COIN_USE.use, GEM_USE.use))
internal val DUAL_COIN_COIN = DUAL.namedUse(listOf(COIN_USE.use, COIN_USE.use))
internal val LINK_GEM = LINK.namedUse(listOf(GEM_USE.use))
internal val SOURCE_ENDPOINT = EndpointId(value = "dual:source")
internal val TARGET_ENDPOINT = EndpointId(value = "dual:target")
internal val RELATION = RelationId(value = "dual:relation")
internal val DUAL_RELATION =
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

internal val REPAIR_DEFINITIONS =
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

internal fun definition(name: String) = TypeDefinitionId.qualified("repair", name)

internal val container = ResourceId(value = "container")
internal val dual = ResourceId(value = "dual")
internal val gem = ResourceId(value = "gem")
internal val bundleItem = ItemId(value = "bundle")

/** A pending dual selection: the first argument chosen as coin, the second left open. */
internal val pendingCoin =
    TypeSelection.createPending(
        definition = DUAL,
        arguments = listOf(ArgumentSelection.ChosenWrapper(COIN_USE.use), ArgumentSelection.UNFILLED),
    )

/** A container of rewards whose one bundle holds a gem, and whose own reward is a coin. */
internal val rewardContainer =
    mapOf(container to containerRecord(CONTAINER_REWARD, LIST_BUNDLE_REWARD, BUNDLE_REWARD, gemValue()))

/** A dual of coin and gem with a name and both values filled. */
internal val coinGemDual = mapOf(dual to dualRecord(TypeSelection.CompleteWrapper(DUAL_COIN_GEM)))

/** The coin and gem dual linked to a gem resource through its second argument. */
internal val linkedDual =
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

internal val REPAIR_CATALOG = DefinitionCatalog(REPAIR_DEFINITIONS, listOf(DUAL_RELATION))

/** Previews changing [resource] to [requested] on the state the Realm holds now. */
internal fun RealmFixture.preview(
    resource: ResourceId,
    requested: TypeSelection,
): PreviewTypeArgumentChangeResponse =
    views.capture().use { snapshot -> DefaultTypeArgumentOperations(views).preview(resource, requested, snapshot) }

/** Confirms [preview] against the state the Realm holds now. */
internal suspend fun RealmFixture.prepare(preview: TypeArgumentChangePreview): PrepareTypeArgumentChangeResponse =
    DefaultTypeArgumentOperations(views).prepare(preview)

internal fun PreviewTypeArgumentChangeResponse.shouldBeReady(): TypeArgumentChangePreview =
    shouldBeInstanceOf<PreviewTypeArgumentChangeResponse.ReadyWrapper>().value

internal fun PrepareTypeArgumentChangeResponse.shouldBePrepared(): PreparedEdit =
    shouldBeInstanceOf<PrepareTypeArgumentChangeResponse.PreparedWrapper>().value.edit

internal fun PrepareTypeArgumentChangeResponse.refusalCodes(): List<String> =
    shouldBeInstanceOf<PrepareTypeArgumentChangeResponse.RejectedErrorWrapper>().value.codes

/** The value leaf of the container's one bundle. */
internal fun bundleValue() =
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

internal fun gemValue() = DataValue.named(GEM_USE, DataValue.record(emptyMap()))

internal fun containerRecord(
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

internal fun dualRecord(selection: TypeSelection): AuthoringRecord =
    AuthoringRecord.of(
        configuration = selection,
        fields =
            mapOf(
                "name" to DataValue.StringValueWrapper("kept"),
                "first" to DataValue.named(COIN_USE, DataValue.record(emptyMap())),
                "second" to DataValue.named(GEM_USE, DataValue.record(emptyMap())),
            ),
    )
