package com.typewritermc.realm.edit

import com.typewritermc.authoring.field
import com.typewritermc.authoring.of
import com.typewritermc.authoring.root
import com.typewritermc.realm.testing.DefinitionCatalog
import com.typewritermc.realm.testing.RealmFixture
import com.typewritermc.realm.testing.expectRefused
import com.typewritermc.realm.testing.link
import com.typewritermc.realm.testing.linkAt
import com.typewritermc.realm.testing.shouldBeCommitted
import com.typewritermc.testkit.definitions
import com.typewritermc.types.integerScalar
import com.typewritermc.types.named
import com.typewritermc.types.namedTemplate
import com.typewritermc.types.namedUse
import com.typewritermc.types.nullable
import com.typewritermc.types.of
import com.typewritermc.types.qualified
import com.typewritermc.types.record
import com.typewritermc.types.template
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContain
import io.kotest.matchers.shouldBe
import skirout.editor.v1.authoring.EditIntent
import skirout.editor.v1.catalog.EndpointCardinality
import skirout.editor.v1.catalog.EndpointDefinition
import skirout.editor.v1.catalog.EndpointSlot
import skirout.editor.v1.catalog.RelationContract
import skirout.editor.v1.catalog.RelationDeletePolicy
import skirout.editor.v1.type_catalog.ArgumentSelection
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.EndpointId
import skirout.editor.v1.type_catalog.IntegerWidth
import skirout.editor.v1.type_catalog.LinkTarget
import skirout.editor.v1.type_catalog.NamedTypeTemplate
import skirout.editor.v1.type_catalog.NamedTypeUse
import skirout.editor.v1.type_catalog.ParameterKey
import skirout.editor.v1.type_catalog.RelationId
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeParameter
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.type_catalog.ValuePath
import skirout.kernel.v1.resource_id.ResourceId

private val source = ResourceId(value = "source")
private val target = ResourceId(value = "target")
private val FIRST = EndpointId(value = "typed:first")
private val SECOND = EndpointId(value = "typed:second")

private fun id(name: String) = TypeDefinitionId.qualified("test", name)

/** A one to one relation from resources of [first] through [FIRST] to resources of [second]. */
private fun relation(
    first: NamedTypeTemplate,
    second: NamedTypeTemplate = first,
) = RelationContract.of(
    RelationId(value = "typed"),
    EndpointDefinition(
        id = FIRST,
        slot = EndpointSlot.FIRST,
        resource = first,
        cardinality = EndpointCardinality.ONE,
        onDelete = RelationDeletePolicy.CLEAR,
    ),
    EndpointDefinition(
        id = SECOND,
        slot = EndpointSlot.SECOND,
        resource = second,
        cardinality = EndpointCardinality.ONE,
        onDelete = RelationDeletePolicy.CLEAR,
    ),
)

/** A one sided link value of [type] through [FIRST] to [target]. */
private fun linkTo(
    type: NamedTypeUse,
    target: ResourceId,
) = DataValue.named(type, DataValue.createLink(endpoint = FIRST, target = LinkTarget(resource = target, opposite = null)))

/** A resource of the complete type [type] with [fields]. */
private fun resource(
    type: TypeDefinitionId,
    vararg fields: Pair<String, DataValue>,
) = AuthoringRecord.of(TypeSelection.CompleteWrapper(type.namedUse()), fields.toMap())

private fun create(record: AuthoringRecord) = EditIntent.createCreateResource(id = source, record = record)

/*
 * A generic base<T> holds a link to a T; derived<T> inherits it. A source still pending as derived<target> may link a
 * target, but not a sibling type both share a common parent with.
 */
private val GENERIC_BASE = id("generic_base")
private val GENERIC_DERIVED = id("generic_derived")
private val GENERIC_LINK = id("generic_link")
private val ANY_TARGET = id("any_target")
private val TARGET = id("generic_target")
private val SIBLING = id("generic_sibling")
private val genericInheritance =
    run {
        val base = ParameterKey(owner = GENERIC_BASE, index = 0)
        val derived = ParameterKey(owner = GENERIC_DERIVED, index = 0)
        val link = ParameterKey(owner = GENERIC_LINK, index = 0)
        DefinitionCatalog(
            definitions {
                record(GENERIC_BASE, parameters = listOf(TypeParameter.partial(key = base, name = "T"))) {
                    field("link", GENERIC_LINK.template(listOf(base.template)))
                }
                record(
                    GENERIC_DERIVED,
                    parameters = listOf(TypeParameter.partial(key = derived, name = "T")),
                    parents = listOf(GENERIC_BASE.namedTemplate(listOf(derived.template))),
                )
                record(ANY_TARGET, abstract = true)
                record(TARGET, parents = listOf(ANY_TARGET.namedTemplate()))
                record(SIBLING, parents = listOf(ANY_TARGET.namedTemplate()))
                link(GENERIC_LINK, FIRST, link.template, parameters = listOf(TypeParameter.partial(key = link, name = "T")))
            },
            listOf(relation(GENERIC_BASE.namedTemplate(listOf(TARGET.template())), ANY_TARGET.namedTemplate())),
        )
    }

private fun pendingDerivedLinking(target: ResourceId) =
    AuthoringRecord.of(
        TypeSelection.createPending(definition = GENERIC_DERIVED, arguments = listOf(ArgumentSelection.ChosenWrapper(TARGET.use()))),
        mapOf("link" to linkTo(GENERIC_LINK.namedUse(listOf(TARGET.use())), target)),
    )

val LinkAuthorizationTest by testSuite {
    test("a source whose generic type is still pending may link a target of its chosen argument") {
        RealmFixture.of(genericInheritance, mapOf(target to resource(TARGET))).use { realm ->
            realm.commit(create(pendingDerivedLinking(target))).shouldBeCommitted()

            realm.resources
                .getValue(source)
                .linkAt(ValuePath.root.field("link"))
                ?.resource shouldBe target
        }
    }

    test("a source whose generic type is still pending may not link a target outside its chosen argument") {
        RealmFixture.of(genericInheritance, mapOf(target to resource(SIBLING))).use { realm ->
            realm.expectRefused(create(pendingDerivedLinking(target))).map { it.location to it.code } shouldContain
                (ValueLocation.of(source, ValuePath.root.field("link")) to "binding_target_type_mismatch")
        }
    }

    test("a pending target whose chosen arguments cannot prove the expected type is refused") {
        val config = id("partial_config")
        val sourceType = id("partial_source")
        val linkType = id("partial_link")
        val text = ScalarKind.TEXT.use
        val integer = integerScalar(IntegerWidth.SIGNED_THIRTY_TWO).use
        val expected = config.template(listOf(ScalarKind.TEXT.template, integerScalar(IntegerWidth.SIGNED_THIRTY_TWO).template))
        val parameter = ParameterKey(owner = linkType, index = 0)
        val catalog =
            DefinitionCatalog(
                definitions {
                    record(sourceType) { field("target", linkType.template(listOf(expected))) }
                    record(
                        config,
                        parameters =
                            listOf(
                                TypeParameter.partial(key = ParameterKey(owner = config, index = 0), name = "T"),
                                TypeParameter.partial(key = ParameterKey(owner = config, index = 1), name = "U"),
                            ),
                    )
                    link(linkType, FIRST, parameter.template, parameters = listOf(TypeParameter.partial(key = parameter, name = "T")))
                },
                listOf(
                    relation(
                        sourceType.namedTemplate(),
                        config.namedTemplate(listOf(ScalarKind.TEXT.template, integerScalar(IntegerWidth.SIGNED_THIRTY_TWO).template)),
                    ),
                ),
            )
        val link = linkTo(linkType.namedUse(listOf(config.use(listOf(text, integer)))), target)

        listOf(integer, text).forEach { chosen ->
            val pending =
                TypeSelection.createPending(
                    definition = config,
                    arguments = listOf(ArgumentSelection.ChosenWrapper(chosen), ArgumentSelection.UNFILLED),
                )
            RealmFixture.of(catalog, mapOf(target to AuthoringRecord.of(pending, emptyMap()))).use { realm ->
                realm.expectRefused(create(resource(sourceType, "target" to link))).map { it.location to it.code } shouldContain
                    (ValueLocation.of(source, ValuePath.root.field("target")) to "target_resource_type_mismatch")
            }
        }
    }

    test("a pending target proves an ancestor that does not use every one of its arguments") {
        val view = id("partial_view")
        val derived = id("partial_derived")
        val sourceType = id("partial_ancestor_source")
        val linkType = id("partial_ancestor_link")
        val first = ParameterKey(owner = derived, index = 0)
        val parameter = ParameterKey(owner = linkType, index = 0)
        val catalog =
            DefinitionCatalog(
                definitions {
                    record(sourceType) { field("target", linkType.template(listOf(view.template(listOf(ScalarKind.TEXT.template))))) }
                    record(view, parameters = listOf(TypeParameter.partial(key = ParameterKey(owner = view, index = 0), name = "T")))
                    record(
                        derived,
                        parameters =
                            listOf(
                                TypeParameter.partial(key = first, name = "T"),
                                TypeParameter.partial(key = ParameterKey(owner = derived, index = 1), name = "Unused"),
                            ),
                        parents = listOf(view.namedTemplate(listOf(first.template))),
                    )
                    link(linkType, FIRST, parameter.template, parameters = listOf(TypeParameter.partial(key = parameter, name = "T")))
                },
                listOf(relation(sourceType.namedTemplate(), view.namedTemplate(listOf(ScalarKind.TEXT.template)))),
            )
        val pending =
            TypeSelection.createPending(
                definition = derived,
                arguments = listOf(ArgumentSelection.ChosenWrapper(ScalarKind.TEXT.use), ArgumentSelection.UNFILLED),
            )
        RealmFixture.of(catalog, mapOf(target to AuthoringRecord.of(pending, emptyMap()))).use { realm ->
            val link = linkTo(linkType.namedUse(listOf(view.use(listOf(ScalarKind.TEXT.use)))), target)

            realm.commit(create(resource(sourceType, "target" to link))).shouldBeCommitted()

            realm.resources.getValue(source).link("target") shouldBe target
        }
    }

    test("a link inside a field's concrete subtype is authorized by that subtype's schema") {
        val host = id("polymorphic_host")
        val message = id("polymorphic_message")
        val linkedMessage = id("linked_message")
        val linkType = id("polymorphic_link")
        val catalog =
            DefinitionCatalog(
                definitions {
                    record(host) { field("message", message.template()) }
                    record(message)
                    record(linkedMessage, parents = listOf(message.namedTemplate())) { field("target", linkType.template()) }
                    link(linkType, FIRST, host.template())
                },
                listOf(relation(host.namedTemplate())),
            )
        val linked = DataValue.named(linkedMessage.namedUse(), DataValue.record(mapOf("target" to linkTo(linkType.namedUse(), target))))
        RealmFixture.of(catalog, mapOf(target to resource(host, "message" to DataValue.UNFILLED))).use { realm ->
            realm.commit(create(resource(host, "message" to linked))).shouldBeCommitted()

            realm.resources
                .getValue(source)
                .linkAt(ValuePath.root.field("message").field("target"))
                ?.resource shouldBe target
        }
    }

    test("a link inside a recursive record is authorized at the depth it was authored") {
        val host = id("recursive_host")
        val node = id("recursive_node")
        val linkType = id("recursive_link")
        val catalog =
            DefinitionCatalog(
                definitions {
                    record(host) { field("tree", node.template()) }
                    record(node) {
                        field("next", node.template().nullable())
                        field("target", linkType.template())
                    }
                    link(linkType, FIRST, host.template())
                },
                listOf(relation(host.namedTemplate())),
            )

        fun level(
            next: DataValue,
            target: DataValue,
        ) = DataValue.named(node.namedUse(), DataValue.record(mapOf("next" to next, "target" to target)))
        val tree = level(next = level(next = DataValue.NULL, target = linkTo(linkType.namedUse(), target)), target = DataValue.UNFILLED)
        RealmFixture.of(catalog, mapOf(target to resource(host, "tree" to DataValue.UNFILLED))).use { realm ->
            realm.commit(create(resource(host, "tree" to tree))).shouldBeCommitted()

            realm.resources
                .getValue(source)
                .linkAt(
                    ValuePath.root
                        .field("tree")
                        .field("next")
                        .field("target"),
                )?.resource shouldBe target
        }
    }

    test("a link whose applied target argument excludes the target's type is refused") {
        val bound = id("bounded_resource")
        val sourceType = id("bounded_source")
        val allowed = id("bounded_allowed")
        val disallowed = id("bounded_disallowed")
        val linkType = id("bounded_link")
        val parameter = ParameterKey(owner = linkType, index = 0)
        val catalog =
            DefinitionCatalog(
                definitions {
                    record(bound)
                    record(
                        sourceType,
                        parents = listOf(bound.namedTemplate()),
                    ) { field("target", linkType.template(listOf(allowed.template()))) }
                    record(allowed, parents = listOf(bound.namedTemplate()))
                    record(disallowed, parents = listOf(bound.namedTemplate()))
                    link(
                        linkType,
                        FIRST,
                        parameter.template,
                        parameters = listOf(TypeParameter(key = parameter, name = "T", bounds = listOf(bound.template()))),
                    )
                },
                listOf(relation(bound.namedTemplate())),
            )
        RealmFixture.of(catalog, mapOf(target to resource(disallowed))).use { realm ->
            val link = linkTo(linkType.namedUse(listOf(allowed.use())), target)

            realm.expectRefused(create(resource(sourceType, "target" to link))).map { it.location to it.code } shouldContain
                (ValueLocation.of(source, ValuePath.root.field("target")) to "binding_target_type_mismatch")
        }
    }

    test("a source whose type the catalog cannot resolve may not author a link") {
        val available = id("unavailable_resource")
        val unavailable = id("unavailable_source")
        val catalog =
            DefinitionCatalog(
                definitions {
                    record(available)
                    record(unavailable, parents = listOf(id("missing_parent").namedTemplate()))
                },
                listOf(relation(available.namedTemplate())),
            )
        val link = DataValue.createLink(endpoint = FIRST, target = LinkTarget(resource = target, opposite = null))
        RealmFixture.of(catalog, mapOf(target to resource(available))).use { realm ->
            realm.expectRefused(create(resource(unavailable, "target" to link))).map { it.location to it.code } shouldContain
                (ValueLocation.of(source, ValuePath.root.field("target")) to "source_resource_type_mismatch")
        }
    }
}
