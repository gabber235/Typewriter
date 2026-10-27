package com.typewritermc.realm.edit

import com.typewritermc.authoring.field
import com.typewritermc.authoring.of
import com.typewritermc.authoring.root
import com.typewritermc.realm.testing.DefinitionCatalog
import com.typewritermc.realm.testing.RealmFixture
import com.typewritermc.realm.testing.completeRecord
import com.typewritermc.realm.testing.expectRefused
import com.typewritermc.realm.testing.link
import com.typewritermc.realm.testing.linkAt
import com.typewritermc.realm.testing.linkValue
import com.typewritermc.realm.testing.oneToOneRelation
import com.typewritermc.realm.testing.shouldBeCommitted
import com.typewritermc.testkit.definitions
import com.typewritermc.types.integerScalar
import com.typewritermc.types.named
import com.typewritermc.types.namedTemplate
import com.typewritermc.types.namedUse
import com.typewritermc.types.nullable
import com.typewritermc.types.qualified
import com.typewritermc.types.record
import com.typewritermc.types.template
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContain
import io.kotest.matchers.shouldBe
import skirout.editor.v1.authoring.EditIntent
import skirout.editor.v1.type_catalog.ArgumentSelection
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.EndpointId
import skirout.editor.v1.type_catalog.IntegerWidth
import skirout.editor.v1.type_catalog.LinkTarget
import skirout.editor.v1.type_catalog.ParameterKey
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeParameter
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.type_catalog.ValuePath
import skirout.kernel.v1.resource_id.ResourceId

val LinkAuthorizationTest by testSuite {
    val source = ResourceId(value = "source")

    val target = ResourceId(value = "target")

    val firstEndpoint = EndpointId(value = "typed:first")

    val secondEndpoint = EndpointId(value = "typed:second")

    /*
     * A generic base<T> holds a link to a T; derived<T> inherits it. A source still pending as derived<target> may link a
     * target, but not a sibling type both share a common parent with.
     */
    val genericBase = TypeDefinitionId.qualified("test", "generic_base")

    val genericDerived = TypeDefinitionId.qualified("test", "generic_derived")

    val genericLink = TypeDefinitionId.qualified("test", "generic_link")

    val anyTarget = TypeDefinitionId.qualified("test", "any_target")

    val targetType = TypeDefinitionId.qualified("test", "generic_target")

    val siblingType = TypeDefinitionId.qualified("test", "generic_sibling")

    val genericInheritance =
        run {
            val base = ParameterKey(owner = genericBase, index = 0)
            val derived = ParameterKey(owner = genericDerived, index = 0)
            val link = ParameterKey(owner = genericLink, index = 0)
            DefinitionCatalog(
                definitions {
                    record(genericBase, parameters = listOf(TypeParameter.partial(key = base, name = "T"))) {
                        field("link", genericLink.template(listOf(base.template)))
                    }
                    record(
                        genericDerived,
                        parameters = listOf(TypeParameter.partial(key = derived, name = "T")),
                        parents = listOf(genericBase.namedTemplate(listOf(derived.template))),
                    )
                    record(anyTarget, abstract = true)
                    record(targetType, parents = listOf(anyTarget.namedTemplate()))
                    record(siblingType, parents = listOf(anyTarget.namedTemplate()))
                    link(genericLink, firstEndpoint, link.template, parameters = listOf(TypeParameter.partial(key = link, name = "T")))
                },
                listOf(
                    oneToOneRelation(
                        "typed",
                        firstEndpoint,
                        secondEndpoint,
                        genericBase.namedTemplate(listOf(targetType.template())),
                        anyTarget.namedTemplate(),
                    ),
                ),
            )
        }

    /** A source still pending as `derived<target>`, whose `link` points at [target]. */
    val pendingDerived =
        AuthoringRecord.of(
            TypeSelection.createPending(definition = genericDerived, arguments = listOf(ArgumentSelection.ChosenWrapper(targetType.use()))),
            mapOf("link" to linkValue(genericLink.namedUse(listOf(targetType.use())), firstEndpoint, target)),
        )

    test("a source whose generic type is still pending may link a target of its chosen argument") {
        RealmFixture.of(genericInheritance, mapOf(target to completeRecord(targetType))).use { realm ->
            realm.commit(EditIntent.createCreateResource(id = source, record = pendingDerived)).shouldBeCommitted()

            realm.resources
                .getValue(source)
                .linkAt(ValuePath.root.field("link"))
                ?.resource shouldBe target
        }
    }

    test("a source whose generic type is still pending may not link a target outside its chosen argument") {
        RealmFixture.of(genericInheritance, mapOf(target to completeRecord(siblingType))).use { realm ->
            realm
                .expectRefused(
                    EditIntent.createCreateResource(id = source, record = pendingDerived),
                ).map { it.location to it.code } shouldContain
                (ValueLocation.of(source, ValuePath.root.field("link")) to "binding_target_type_mismatch")
        }
    }

    test("a pending target whose chosen arguments cannot prove the expected type is refused") {
        val config = TypeDefinitionId.qualified("test", "partial_config")
        val sourceType = TypeDefinitionId.qualified("test", "partial_source")
        val linkType = TypeDefinitionId.qualified("test", "partial_link")
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
                    genericLink(linkType, firstEndpoint)
                },
                listOf(
                    oneToOneRelation(
                        "typed",
                        firstEndpoint,
                        secondEndpoint,
                        sourceType.namedTemplate(),
                        config.namedTemplate(listOf(ScalarKind.TEXT.template, integerScalar(IntegerWidth.SIGNED_THIRTY_TWO).template)),
                    ),
                ),
            )
        val link = linkValue(linkType.namedUse(listOf(config.use(listOf(text, integer)))), firstEndpoint, target)

        listOf(integer, text).forEach { chosen ->
            val pending =
                TypeSelection.createPending(
                    definition = config,
                    arguments = listOf(ArgumentSelection.ChosenWrapper(chosen), ArgumentSelection.UNFILLED),
                )
            RealmFixture.of(catalog, mapOf(target to AuthoringRecord.of(pending, emptyMap()))).use { realm ->
                realm
                    .expectRefused(EditIntent.createCreateResource(id = source, record = completeRecord(sourceType, "target" to link)))
                    .map { it.location to it.code } shouldContain
                    (ValueLocation.of(source, ValuePath.root.field("target")) to "target_resource_type_mismatch")
            }
        }
    }

    test("a pending target proves an ancestor that does not use every one of its arguments") {
        val view = TypeDefinitionId.qualified("test", "partial_view")
        val derived = TypeDefinitionId.qualified("test", "partial_derived")
        val sourceType = TypeDefinitionId.qualified("test", "partial_ancestor_source")
        val linkType = TypeDefinitionId.qualified("test", "partial_ancestor_link")
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
                    genericLink(linkType, firstEndpoint)
                },
                listOf(
                    oneToOneRelation(
                        "typed",
                        firstEndpoint,
                        secondEndpoint,
                        sourceType.namedTemplate(),
                        view.namedTemplate(listOf(ScalarKind.TEXT.template)),
                    ),
                ),
            )
        val pending =
            TypeSelection.createPending(
                definition = derived,
                arguments = listOf(ArgumentSelection.ChosenWrapper(ScalarKind.TEXT.use), ArgumentSelection.UNFILLED),
            )
        RealmFixture.of(catalog, mapOf(target to AuthoringRecord.of(pending, emptyMap()))).use { realm ->
            val link = linkValue(linkType.namedUse(listOf(view.use(listOf(ScalarKind.TEXT.use)))), firstEndpoint, target)

            realm
                .commit(EditIntent.createCreateResource(id = source, record = completeRecord(sourceType, "target" to link)))
                .shouldBeCommitted()

            realm.resources.getValue(source).link("target") shouldBe target
        }
    }

    test("a link inside a field's concrete subtype is authorized by that subtype's schema") {
        val host = TypeDefinitionId.qualified("test", "polymorphic_host")
        val message = TypeDefinitionId.qualified("test", "polymorphic_message")
        val linkedMessage = TypeDefinitionId.qualified("test", "linked_message")
        val linkType = TypeDefinitionId.qualified("test", "polymorphic_link")
        val catalog =
            DefinitionCatalog(
                definitions {
                    record(host) { field("message", message.template()) }
                    record(message)
                    record(linkedMessage, parents = listOf(message.namedTemplate())) { field("target", linkType.template()) }
                    link(linkType, firstEndpoint, host.template())
                },
                listOf(oneToOneRelation("typed", firstEndpoint, secondEndpoint, host.namedTemplate())),
            )
        val linked =
            DataValue.named(
                linkedMessage.namedUse(),
                DataValue.record(mapOf("target" to linkValue(linkType.namedUse(), firstEndpoint, target))),
            )
        RealmFixture.of(catalog, mapOf(target to completeRecord(host, "message" to DataValue.UNFILLED))).use { realm ->
            realm
                .commit(EditIntent.createCreateResource(id = source, record = completeRecord(host, "message" to linked)))
                .shouldBeCommitted()

            realm.resources
                .getValue(source)
                .linkAt(ValuePath.root.field("message").field("target"))
                ?.resource shouldBe target
        }
    }

    test("a link inside a recursive record is authorized at the depth it was authored") {
        val host = TypeDefinitionId.qualified("test", "recursive_host")
        val node = TypeDefinitionId.qualified("test", "recursive_node")
        val linkType = TypeDefinitionId.qualified("test", "recursive_link")
        val catalog =
            DefinitionCatalog(
                definitions {
                    record(host) { field("tree", node.template()) }
                    record(node) {
                        field("next", node.template().nullable())
                        field("target", linkType.template())
                    }
                    link(linkType, firstEndpoint, host.template())
                },
                listOf(oneToOneRelation("typed", firstEndpoint, secondEndpoint, host.namedTemplate())),
            )
        val innermost = linkValue(linkType.namedUse(), firstEndpoint, target)
        val inner = DataValue.named(node.namedUse(), DataValue.record(mapOf("next" to DataValue.NULL, "target" to innermost)))
        val tree = DataValue.named(node.namedUse(), DataValue.record(mapOf("next" to inner, "target" to DataValue.UNFILLED)))
        RealmFixture.of(catalog, mapOf(target to completeRecord(host, "tree" to DataValue.UNFILLED))).use { realm ->
            realm.commit(EditIntent.createCreateResource(id = source, record = completeRecord(host, "tree" to tree))).shouldBeCommitted()

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
        val bound = TypeDefinitionId.qualified("test", "bounded_resource")
        val sourceType = TypeDefinitionId.qualified("test", "bounded_source")
        val allowed = TypeDefinitionId.qualified("test", "bounded_allowed")
        val disallowed = TypeDefinitionId.qualified("test", "bounded_disallowed")
        val linkType = TypeDefinitionId.qualified("test", "bounded_link")
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
                        firstEndpoint,
                        parameter.template,
                        parameters = listOf(TypeParameter(key = parameter, name = "T", bounds = listOf(bound.template()))),
                    )
                },
                listOf(oneToOneRelation("typed", firstEndpoint, secondEndpoint, bound.namedTemplate())),
            )
        RealmFixture.of(catalog, mapOf(target to completeRecord(disallowed))).use { realm ->
            val link = linkValue(linkType.namedUse(listOf(allowed.use())), firstEndpoint, target)

            realm
                .expectRefused(EditIntent.createCreateResource(id = source, record = completeRecord(sourceType, "target" to link)))
                .map { it.location to it.code } shouldContain
                (ValueLocation.of(source, ValuePath.root.field("target")) to "binding_target_type_mismatch")
        }
    }

    test("a source whose type the catalog cannot resolve may not author a link") {
        val available = TypeDefinitionId.qualified("test", "unavailable_resource")
        val unavailable = TypeDefinitionId.qualified("test", "unavailable_source")
        val catalog =
            DefinitionCatalog(
                definitions {
                    record(available)
                    record(unavailable, parents = listOf(TypeDefinitionId.qualified("test", "missing_parent").namedTemplate()))
                },
                listOf(oneToOneRelation("typed", firstEndpoint, secondEndpoint, available.namedTemplate())),
            )
        val link = DataValue.createLink(endpoint = firstEndpoint, target = LinkTarget(resource = target, opposite = null))
        RealmFixture.of(catalog, mapOf(target to completeRecord(available))).use { realm ->
            realm
                .expectRefused(EditIntent.createCreateResource(id = source, record = completeRecord(unavailable, "target" to link)))
                .map { it.location to it.code } shouldContain
                (ValueLocation.of(source, ValuePath.root.field("target")) to "source_resource_type_mismatch")
        }
    }
}
