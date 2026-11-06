package com.typewritermc.realm.edit

import com.typewritermc.authoring.RealmRootDefinition
import com.typewritermc.authoring.field
import com.typewritermc.authoring.of
import com.typewritermc.authoring.root
import com.typewritermc.realm.testing.DefinitionCatalog
import com.typewritermc.realm.testing.RealmFixture
import com.typewritermc.realm.testing.completeRecord
import com.typewritermc.realm.testing.linkValue
import com.typewritermc.realm.testing.links
import com.typewritermc.realm.testing.operationPreparation
import com.typewritermc.realm.testing.shouldBeCommitted
import com.typewritermc.realm.testing.text
import com.typewritermc.types.RESOURCE_OWNERSHIP_FAMILY_ID
import com.typewritermc.types.listValue
import com.typewritermc.types.named
import com.typewritermc.types.namedTemplate
import com.typewritermc.types.namedUse
import com.typewritermc.types.of
import com.typewritermc.types.qualified
import com.typewritermc.types.template
import com.typewritermc.types.toResourceId
import com.typewritermc.types.toResourceIds
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import skirout.editor.v1.authoring.EditIntent
import skirout.editor.v1.catalog.EndpointCardinality
import skirout.editor.v1.catalog.EndpointDefinition
import skirout.editor.v1.catalog.EndpointSlot
import skirout.editor.v1.catalog.RelationContract
import skirout.editor.v1.catalog.RelationDeletePolicy
import skirout.editor.v1.type_catalog.CollectionKind
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.EndpointId
import skirout.editor.v1.type_catalog.FieldDeclaration
import skirout.editor.v1.type_catalog.FieldOwner
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.ListItem
import skirout.editor.v1.type_catalog.RecordForm
import skirout.editor.v1.type_catalog.RelationFamilyId
import skirout.editor.v1.type_catalog.RelationId
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.type_catalog.ValuePath
import skirout.kernel.v1.resource_id.ResourceId

/**
 * Ownership over a catalog whose members are held only by their owner's collection, like keyframes in a segment. They
 * have no inverse field to relink, so their owner candidates and moves go through the owners' own bindings.
 */
val OwnershipRulesTest by testSuite {
    val first = ResourceId(value = "first")

    val second = ResourceId(value = "second")

    val keyframe = ResourceId(value = "keyframe")

    val other = ResourceId(value = "other")

    val root = ResourceId(value = "root")

    val ownerType = TypeDefinitionId.qualified("owner_side", "segment")

    val memberType = TypeDefinitionId.qualified("owner_side", "keyframe")

    val childLink = TypeDefinitionId.qualified("owner_side", "keyframe_link")

    val childrenType = TypeDefinitionId.qualified("owner_side", "keyframes")

    val childLinkUse = childLink.namedUse()

    val childrenUse = childrenType.namedUse()

    val ownership = RelationId(value = "segment_keyframes")

    val ownerEndpoint = EndpointId(value = "segment_keyframes:first")

    val memberEndpoint = EndpointId(value = "segment_keyframes:second")

    val ownershipContract =
        RelationContract.of(
            ownership,
            EndpointDefinition(
                id = ownerEndpoint,
                slot = EndpointSlot.FIRST,
                resource = ownerType.namedTemplate(),
                cardinality = EndpointCardinality.ONE,
                onDelete = RelationDeletePolicy.CASCADE,
            ),
            EndpointDefinition(
                id = memberEndpoint,
                slot = EndpointSlot.SECOND,
                resource = memberType.namedTemplate(),
                cardinality = EndpointCardinality.MANY,
                onDelete = RelationDeletePolicy.CLEAR,
            ),
            setOf(RelationFamilyId(value = RESOURCE_OWNERSHIP_FAMILY_ID)),
        )

    val definitions =
        listOf(
            TypeDefinition.partial(
                id = ownerType,
                representation =
                    RepresentationTemplate.createRecord(
                        fields =
                            listOf(
                                FieldDeclaration.partial(
                                    owner = FieldOwner(definition = ownerType, name = "children"),
                                    type = childrenType.template(),
                                ),
                            ),
                        form = RecordForm.CONCRETE,
                    ),
            ),
            TypeDefinition.partial(
                id = memberType,
                representation =
                    RepresentationTemplate.createRecord(
                        fields =
                            listOf(
                                FieldDeclaration.partial(
                                    owner = FieldOwner(definition = memberType, name = "frame"),
                                    type = ScalarKind.TEXT.template,
                                ),
                            ),
                        form = RecordForm.CONCRETE,
                    ),
            ),
            TypeDefinition.partial(
                id = RealmRootDefinition.id,
                representation =
                    RepresentationTemplate.createRecord(
                        fields =
                            listOf(
                                FieldDeclaration.partial(
                                    owner = FieldOwner(definition = RealmRootDefinition.id, name = "frame"),
                                    type = ScalarKind.TEXT.template,
                                    overrides = listOf(FieldOwner(definition = memberType, name = "frame")),
                                ),
                            ),
                        form = RecordForm.CONCRETE,
                    ),
                parents = listOf(memberType.namedTemplate()),
            ),
            TypeDefinition.partial(
                id = childLink,
                representation = RepresentationTemplate.createLink(endpoint = ownerEndpoint, target = memberType.template()),
            ),
            TypeDefinition.partial(
                id = childrenType,
                representation = RepresentationTemplate.createSequence(item = childLink.template(), kind = CollectionKind.LIST),
            ),
        )

    val ownerSide = DefinitionCatalog(definitions, listOf(ownershipContract))

    /** Two segments, the first holding both keyframes, and the realm root, whose type is a keyframe's subtype. */
    val seed =
        mapOf(
            root to completeRecord(RealmRootDefinition.id, "frame" to DataValue.StringValueWrapper("0")),
            first to
                completeRecord(
                    ownerType,
                    "children" to
                        DataValue.named(
                            childrenUse,
                            DataValue.listValue(
                                listOf(
                                    ListItem(id = ItemId(value = "child_0"), value = linkValue(childLinkUse, ownerEndpoint, keyframe)),
                                    ListItem(id = ItemId(value = "child_1"), value = linkValue(childLinkUse, ownerEndpoint, other)),
                                ),
                            ),
                        ),
                ),
            second to completeRecord(ownerType, "children" to DataValue.named(childrenUse, DataValue.listValue(emptyList()))),
            keyframe to completeRecord(memberType, "frame" to DataValue.StringValueWrapper("0")),
            other to completeRecord(memberType, "frame" to DataValue.StringValueWrapper("0")),
        )

    test("a member without a back reference lists every owner whose collection accepts it") {
        RealmFixture.of(ownerSide, seed).use { realm ->
            realm
                .commit {
                    operationPreparation(listOf(keyframe, other), name = "owner-side")
                        .ownerCandidatesOf(keyframe.toResourceId())
                        .toList() shouldBe listOf(first, second).toResourceIds()
                }.shouldBeCommitted()
        }
    }

    test("moving members without a back reference releases them from the old owner and reads current owners") {
        RealmFixture.of(ownerSide, seed).use { realm ->
            realm
                .commit {
                    val preparation = operationPreparation(listOf(keyframe, other), name = "owner-side")
                    preparation.move(listOf(keyframe.toResourceId()), second.toResourceId(), null)
                    preparation.ownerOf(keyframe.toResourceId()) shouldBe second.toResourceId()
                    preparation.move(listOf(other.toResourceId()), second.toResourceId(), null)
                    preparation.ownerOf(other.toResourceId()) shouldBe second.toResourceId()
                }.shouldBeCommitted()

            realm.resources.getValue(first).links("children") shouldBe emptyList()
            realm.resources.getValue(second).links("children") shouldBe listOf(keyframe, other)
        }
    }

    test("the realm root needs no owner even when its type could be owned") {
        RealmFixture.of(ownerSide, seed).use { realm ->
            realm
                .commit(
                    EditIntent.createSetValue(
                        at = ValueLocation.of(root, ValuePath.root.field("frame")),
                        value = DataValue.StringValueWrapper("1"),
                    ),
                ).shouldBeCommitted()

            realm.resources.getValue(root).text("frame") shouldBe "1"
        }
    }
}
