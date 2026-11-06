package com.typewritermc.realm.edit

import com.typewritermc.authoring.Availability
import com.typewritermc.authoring.with
import com.typewritermc.engine.pages.Definition
import com.typewritermc.engine.pages.DefinitionDefinition
import com.typewritermc.engine.pages.StaticPageDefinition
import com.typewritermc.realm.authoring.valueAt
import com.typewritermc.realm.routeFixtureCatalog
import com.typewritermc.realm.testing.ContentTypes
import com.typewritermc.realm.testing.DeclaredTypes
import com.typewritermc.realm.testing.RealmFixture
import com.typewritermc.realm.testing.RealmStorage
import com.typewritermc.realm.testing.caseValue
import com.typewritermc.realm.testing.catalogOver
import com.typewritermc.realm.testing.codeCatalog
import com.typewritermc.realm.testing.codes
import com.typewritermc.realm.testing.commit
import com.typewritermc.realm.testing.commitCreateThenSet
import com.typewritermc.realm.testing.commitDefinition
import com.typewritermc.realm.testing.commitRecordUser
import com.typewritermc.realm.testing.commitTypeDefinition
import com.typewritermc.realm.testing.conflictingFacts
import com.typewritermc.realm.testing.createEntry
import com.typewritermc.realm.testing.declaredTypes
import com.typewritermc.realm.testing.declares
import com.typewritermc.realm.testing.definitionOf
import com.typewritermc.realm.testing.delete
import com.typewritermc.realm.testing.expectRefused
import com.typewritermc.realm.testing.fieldKey
import com.typewritermc.realm.testing.intUse
import com.typewritermc.realm.testing.listType
import com.typewritermc.realm.testing.overDraft
import com.typewritermc.realm.testing.plain
import com.typewritermc.realm.testing.plainType
import com.typewritermc.realm.testing.plainVar
import com.typewritermc.realm.testing.publicationBlockers
import com.typewritermc.realm.testing.publishToEngine
import com.typewritermc.realm.testing.readJustCreated
import com.typewritermc.realm.testing.record
import com.typewritermc.realm.testing.recordDefinition
import com.typewritermc.realm.testing.recordValue
import com.typewritermc.realm.testing.rename
import com.typewritermc.realm.testing.resolvedSchema
import com.typewritermc.realm.testing.schemaOf
import com.typewritermc.realm.testing.setDefinitionValue
import com.typewritermc.realm.testing.setTypes
import com.typewritermc.realm.testing.shouldBeCommitted
import com.typewritermc.realm.testing.shouldBeReady
import com.typewritermc.realm.testing.shouldBeRejected
import com.typewritermc.realm.testing.staticPage
import com.typewritermc.realm.testing.statusOf
import com.typewritermc.realm.testing.textUse
import com.typewritermc.realm.testing.typeArgumentOf
import com.typewritermc.realm.testing.typeUse
import com.typewritermc.realm.testing.unavailableCodeOf
import com.typewritermc.realm.testing.value
import com.typewritermc.realm.testing.viewCatalog
import com.typewritermc.realm.testing.withSetup
import com.typewritermc.types.catalog.content
import com.typewritermc.types.catalog.contentField
import com.typewritermc.types.catalog.contentOwner
import com.typewritermc.types.catalog.unavailableCode
import com.typewritermc.types.functionUse
import com.typewritermc.types.integer
import com.typewritermc.types.member
import com.typewritermc.types.named
import com.typewritermc.types.namedTemplate
import com.typewritermc.types.namedUse
import com.typewritermc.types.nullable
import com.typewritermc.types.record
import com.typewritermc.types.template
import com.typewritermc.types.toResourceId
import com.typewritermc.types.toSkir
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.collections.shouldBeEmpty
import io.kotest.matchers.collections.shouldContain
import io.kotest.matchers.collections.shouldContainAll
import io.kotest.matchers.collections.shouldNotContain
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe
import io.kotest.matchers.string.shouldContain
import io.kotest.matchers.types.shouldBeInstanceOf
import skirout.editor.v1.authoring.EditIntent
import skirout.editor.v1.authoring_facts.EditExpectation
import skirout.editor.v1.catalog.DeclarationStatus
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.RecordForm
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.typed_value.PortableValue
import skirout.kernel.v1.resource_id.ResourceId

val ContentTypesTest by testSuite {
    val gold = declares { record { field("gold", intUse) } }

    for ((written, declared) in listOf(
        "record { gold: Int }" to gold,
        "union { Open, Closed }" to
            declares {
                union {
                    case("Open")
                    case("Closed")
                }
            },
        "union { Money(amount: Int), None }" to
            declares {
                union {
                    case("Money") { field("amount", intUse) }
                    case("None")
                }
            },
        "List<record { gold: Int }>" to declares { listType(record { field("gold", intUse) }) },
        "record { gold: Int }?" to declares { record { field("gold", intUse) }.nullable() },
        "(x: Int) -> record { gold: Int }" to
            declares { functionUse(parameters = listOf("x" to intUse), result = record { field("gold", intUse) }) },
        "record { inner: record { a: Int } }" to declares { record { field("inner", record { field("a", intUse) }) } },
    )) {
        test("a resource whose type argument is $written commits and resolves") {
            withSetup(staticPage, catalog = routeFixtureCatalog) {
                val id = commitDefinition(written, declared).created()
                schemaOf(id) shouldBeReady true
            }
        }
    }

    test("a value of an inline type is admitted, and a value of the wrong shape is refused") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val reward =
                commitDefinition(
                    "reward",
                    gold,
                ) { plainVar(it.use, recordValue(it.use, "gold" to DataValue.integer(70))) }.created()
            val type = typeArgumentOf(reward)
            expectRefused(
                setDefinitionValue(reward, plainVar(type, recordValue(type, "gold" to DataValue.StringValueWrapper("seventy")))),
            ).shouldNotBe(emptyList<Any>())
        }
    }

    test("two identical inline records are different types") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val first = commitDefinition("first", gold).created()
            val second = commitDefinition("second", gold).created()
            val firstType = typeArgumentOf(first)
            typeArgumentOf(second) shouldNotBe firstType
            expectRefused(
                setDefinitionValue(second, plainVar(typeArgumentOf(second), recordValue(firstType, "gold" to DataValue.integer(1)))),
            )
        }
    }

    test("a declaration with parameters is refused and nothing changes") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val before = resources
            commitDefinition("generic", declares { record { parameter("T") } }).reply.shouldBeRejected("declaration_has_parameters")
            resources shouldBe before
        }
    }

    test("an unused invalid declaration is dropped at commit") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val id =
                commitDefinition(
                    "reward",
                    declares {
                        record("unused") { parameter("T") }
                        record("reward") { field("gold", intUse) }
                    },
                ).created()
            declaredTypes(id).map { it.id } shouldBe listOf(TypeDefinitionId.content(id, "reward"))
        }
    }

    test("an inline union keeps its cases after commit") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val door =
                commitDefinition(
                    "door",
                    declares {
                        union {
                            case("Open")
                            case("Closed")
                        }
                    },
                ).created()
            val type = typeArgumentOf(door)
            commit(setDefinitionValue(door, plainVar(type, caseValue(type, "Closed")))).shouldBeCommitted()
            val union = TypeDefinitionId.content(door, "k1")
            declaredTypes(door).map { it.id } shouldContainAll listOf(union, union.member("Open"), union.member("Closed"))
        }
    }

    test("a creator record with a field typed by an alias admits that alias's type") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val amount = commitTypeDefinition("Amount", plainType(intUse)).created()
            val holder =
                commitDefinition("holder", declares { record { field("gold", fieldKey(amount)) } }) {
                    plainVar(
                        it.use,
                        recordValue(
                            it.use,
                            "gold" to DataValue.integer(5),
                        ),
                    )
                }.created()
            val type = typeArgumentOf(holder)
            expectRefused(setDefinitionValue(holder, plainVar(type, recordValue(type, "gold" to DataValue.StringValueWrapper("five")))))
        }
    }

    test("a declaration whose id names another resource is refused") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val foreign = TypeDefinitionId.content(singleOf(StaticPageDefinition.id), "k1")
            val declared = ContentTypes { DeclaredTypes(foreign.use(), listOf(recordDefinition(foreign))) }
            val before = resources
            commitDefinition("foreign", declared).reply.shouldBeRejected("declaration_owner_mismatch")
            resources shouldBe before
        }
    }

    test("an unused declaration whose id names another resource is refused") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val foreign = TypeDefinitionId.content(singleOf(StaticPageDefinition.id), "k1")
            val declared = ContentTypes { owner -> gold.on(owner).let { DeclaredTypes(it.use, it.types + recordDefinition(foreign)) } }
            val before = resources
            commitDefinition("foreign", declared).reply.shouldBeRejected("declaration_owner_mismatch")
            resources shouldBe before
        }
    }

    test("setting types that name another resource on an existing resource is refused") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val reward = commitDefinition("reward", gold).created()
            val foreign = TypeDefinitionId.content(singleOf(StaticPageDefinition.id), "k1")
            expectRefused(setTypes(reward, record(reward).types + recordDefinition(foreign))).codes shouldContain
                "declaration_owner_mismatch"
        }
    }

    test("a field declared by another type's owner is refused") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            commitDefinition(
                "stray",
                declares { record { field("gold", intUse, owner = id("other")) } },
            ).reply.shouldBeRejected("invalid_field_owner")
        }
    }

    test("a declaration with a parent outside its own union is refused") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            commitDefinition("child", declares { record { parent(StaticPageDefinition.id) } }).reply.shouldBeRejected("declaration_parent")
        }
    }

    test("a declaration with a parent on its own resource that is not its union is refused") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val declared =
                declares {
                    union("door") { case("Open") }
                    record("stray") { parent(id("door")) }
                }
            commitDefinition("stray", declared).reply.shouldBeRejected("not_a_listed_case")
        }
    }

    test("a client declaration whose parent is a concrete record on its own resource is refused when used") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val declared =
                declares {
                    record("base") { field("a", intUse) }
                    record("child") { parent(id("base")) }
                }
            commitDefinition("child", declared).reply.shouldBeRejected("declaration_parent")
        }
    }

    test("a declaration with an open form is refused") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            commitDefinition("open", declares { record { form = RecordForm.OPEN } }).reply.shouldBeRejected("declaration_open_form")
        }
    }

    test("a declaration nothing points at any more is removed at commit") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val type = commitTypeDefinition("Reward", gold).created()
            commit(setDefinitionValue(type, plainVar(typeUse, DataValue.TypeUseWrapper(intUse)))).shouldBeCommitted()
            declaredTypes(type).shouldBeEmpty()
        }
    }

    test("an unused nested inline record goes in the same commit as its parent") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val type = commitTypeDefinition("Outer", declares { record { field("inner", record { field("a", intUse) }) } }).created()
            declaredTypes(type).size shouldBe 2
            commit(setDefinitionValue(type, plainVar(typeUse, DataValue.TypeUseWrapper(intUse)))).shouldBeCommitted()
            declaredTypes(type).shouldBeEmpty()
        }
    }

    test("an unused recursive declaration is removed") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val type = commitTypeDefinition("Chain", declares { record("chain") { field("next", id("chain").use().nullable()) } }).created()
            declaredTypes(type).size shouldBe 1
            commit(setDefinitionValue(type, plainVar(typeUse, DataValue.TypeUseWrapper(intUse)))).shouldBeCommitted()
            declaredTypes(type).shouldBeEmpty()
        }
    }

    test("a type edit and a value edit commit together or not at all") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val reward =
                commitDefinition(
                    "reward",
                    gold,
                ) { plainVar(it.use, recordValue(it.use, "gold" to DataValue.integer(1))) }.created()
            val type = typeArgumentOf(reward)
            val withSilver =
                declares {
                    record("k1") {
                        field("gold", intUse)
                        field("silver", intUse)
                    }
                }
            val both = recordValue(type, "gold" to DataValue.integer(2), "silver" to DataValue.integer(3))
            commit(setTypes(reward, withSilver), setDefinitionValue(reward, plainVar(type, both))).shouldBeCommitted()
            record(reward).types shouldBe withSilver.on(reward).types

            val before = resources
            commit(
                setTypes(reward, gold),
                setDefinitionValue(reward, plainVar(type, recordValue(type, "copper" to DataValue.integer(1)))),
            ).shouldBeRejected()
            resources shouldBe before
        }
    }

    test("a commit against an older types list reports a conflict") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val reward = commitDefinition("reward", gold).created()
            val stale =
                prepare(
                    listOf(
                        setTypes(
                            reward,
                            declares {
                                record("k1") {
                                    field("gold", intUse)
                                    field("silver", intUse)
                                }
                            },
                        ),
                    ),
                )
            commit(
                setTypes(
                    reward,
                    declares {
                        record("k1") {
                            field("gold", intUse)
                            field("copper", intUse)
                        }
                    },
                ),
            ).shouldBeCommitted()
            commit(stale).conflictingFacts().single().shouldBeInstanceOf<EditExpectation.TypesWrapper>()
        }
    }

    test("types survive a realm restart") {
        withSetup(staticPage, storage = RealmStorage.Surreal, catalog = routeFixtureCatalog) {
            val id = commitDefinition("reward", gold).created()
            restart()
            schemaOf(id) shouldBeReady true
            declaredTypes(id).size shouldBe 1
        }
    }

    test("editing a resource with declared types commits, and they survive a reload") {
        withSetup(staticPage, storage = RealmStorage.Surreal, catalog = routeFixtureCatalog) {
            val id = commitDefinition("reward", gold).created()
            val types = declaredTypes(id)
            commit(rename(id, "renamed")).shouldBeCommitted()
            restart()
            declaredTypes(id) shouldBe types
        }
    }

    test("cloning a resource gives its declarations new ids and keeps its values readable") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val reward =
                commitDefinition(
                    "reward",
                    gold,
                ) { plainVar(it.use, recordValue(it.use, "gold" to DataValue.integer(70))) }.created()
            val before = resources.keys
            operate(listOf(reward)) { duplicate(listOf(reward.toResourceId())) }.shouldBeCommitted()
            val copy = (resources.keys - before).single()
            declaredTypes(copy).map { it.id.contentOwner() } shouldBe listOf(copy)
            typeArgumentOf(copy).named?.definition?.contentOwner() shouldBe copy
            schemaOf(copy) shouldBeReady true
            val copyType = typeArgumentOf(copy)
            commit(setDefinitionValue(copy, plainVar(copyType, recordValue(copyType, "gold" to DataValue.integer(71))))).shouldBeCommitted()
        }
    }

    test("cloning a page with an alias and its user points the cloned user at the cloned alias") {
        withSetup(staticPage, catalog = routeFixtureCatalog) { page ->
            val amount = commitTypeDefinition("Amount", plainType(intUse)).created()
            commitDefinition("user", plainType(fieldKey(amount))).created()
            val before = resources.keys
            operate(listOf(page.id.toSkir())) { duplicate(listOf(page.id)) }.shouldBeCommitted()
            val copies = resources.keys - before
            val copiedAmount = copies.single { record(it).value("name") == DataValue.StringValueWrapper("Amount") }
            val copiedUser = copies.single { record(it).value("name") == DataValue.StringValueWrapper("user") }
            typeArgumentOf(copiedUser) shouldBe fieldKey(copiedAmount)
        }
    }

    test("cloning a page with a custom type and its user points the cloned user at the cloned type") {
        withSetup(staticPage, catalog = routeFixtureCatalog) { page ->
            val reward = commitTypeDefinition("Reward", gold).created()
            commitDefinition("first", plainType(fieldKey(reward))).created()
            val before = resources.keys
            operate(listOf(page.id.toSkir())) { duplicate(listOf(page.id)) }.shouldBeCommitted()
            val copies = resources.keys - before
            val copiedReward = copies.single { record(it).value("name") == DataValue.StringValueWrapper("Reward") }
            val copiedUser = copies.single { record(it).value("name") == DataValue.StringValueWrapper("first") }
            typeArgumentOf(copiedUser) shouldBe fieldKey(copiedReward)
            schemaOf(copiedUser) shouldBeReady true
        }
    }

    test("deleting a custom type in use is allowed") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val reward = commitTypeDefinition("Reward", gold).created()
            val user = commitDefinition("first", plainType(fieldKey(reward))).created()
            commit(delete(reward)).shouldBeCommitted()
            resources.keys shouldContain user
            unavailableCodeOf(fieldKey(reward)) shouldBe "content_type_missing"
        }
    }

    test("a value that fits only the old declaration is refused when set_types comes after it in one edit") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val reward = commitDefinition("reward", gold).created()
            val type = typeArgumentOf(reward)
            expectRefused(
                setDefinitionValue(reward, plainVar(type, recordValue(type, "gold" to DataValue.integer(1)))),
                setTypes(reward, declares { record("k1") { field("silver", intUse) } }),
            )
        }
    }

    test("creating an element is not refused because a resource's type is missing") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val reward = commitTypeDefinition("Reward", gold).created()
            commitDefinition("first", plainType(fieldKey(reward))).created()
            commit(delete(reward)).shouldBeCommitted()
            commit(createEntry("smith")).shouldBeCommitted()
        }
    }

    test("a resource whose type is missing keeps its page link, and deleting the page deletes it") {
        withSetup(staticPage, catalog = routeFixtureCatalog) { page ->
            val reward = commitTypeDefinition("Reward", gold).created()
            val user = commitDefinition("first", plainType(fieldKey(reward))).created()
            commit(delete(reward)).shouldBeCommitted()
            record(user).value("page").shouldBeInstanceOf<DataValue.LinkWrapper>()
            commit(delete(page.id.toSkir())).shouldBeCommitted()
            resources.keys shouldNotContain user
        }
    }

    test("renaming a resource whose type is missing commits") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val reward = commitTypeDefinition("Reward", gold).created()
            val user = commitRecordUser("first", reward, "gold" to DataValue.integer(1))
            commit(delete(reward)).shouldBeCommitted()
            commit(rename(user, "second")).shouldBeCommitted()
        }
    }

    test("an edit that adds a field to a value whose type is missing is refused, and one that removes or changes a field commits") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val reward =
                commitTypeDefinition(
                    "Reward",
                    declares {
                        record {
                            field("gold", intUse)
                            field("silver", intUse)
                        }
                    },
                ).created()
            val user = commitRecordUser("first", reward, "gold" to DataValue.integer(1), "silver" to DataValue.integer(2))
            commit(delete(reward)).shouldBeCommitted()
            val type = fieldKey(reward)
            expectRefused(
                setDefinitionValue(
                    user,
                    plainVar(
                        type,
                        recordValue(
                            type,
                            "gold" to DataValue.integer(1),
                            "silver" to DataValue.integer(2),
                            "copper" to DataValue.integer(3),
                        ),
                    ),
                ),
            )
            commit(
                setDefinitionValue(
                    user,
                    plainVar(
                        type,
                        recordValue(
                            type,
                            "gold" to DataValue.integer(5),
                            "silver" to DataValue.integer(2),
                        ),
                    ),
                ),
            ).shouldBeCommitted()
            commit(setDefinitionValue(user, plainVar(type, recordValue(type, "gold" to DataValue.integer(5))))).shouldBeCommitted()
        }
    }

    test("a new use of a missing custom type is refused") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val reward = commitTypeDefinition("Reward", gold).created()
            commit(delete(reward)).shouldBeCommitted()
            commitDefinition("late", plainType(fieldKey(reward))).reply.shouldBeRejected("content_type_missing")
        }
    }

    test("a commit that makes a holder's own value stop fitting is refused") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val reward =
                commitDefinition(
                    "reward",
                    gold,
                ) { plainVar(it.use, recordValue(it.use, "gold" to DataValue.integer(1))) }.created()
            expectRefused(setTypes(reward, declares { record("k1") { field("silver", intUse) } }))
        }
    }

    test("a declaration added in one intent is usable by the next intent of that edit") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val type = commitTypeDefinition("Late", plainType(intUse)).created()
            val late = gold.on(type)
            expectRefused(setDefinitionValue(type, plainVar(typeUse, DataValue.TypeUseWrapper(late.use))))
            commit(
                setTypes(type, late.types),
                setDefinitionValue(type, plainVar(typeUse, DataValue.TypeUseWrapper(late.use))),
            ).shouldBeCommitted()
            resolvedSchema(fieldKey(type))
        }
    }

    test("a set_value on an alias's field is seen by the next intent of that edit") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val amount = commitTypeDefinition("Amount", plainType(intUse)).created()
            val user = commitDefinition("user", plainType(fieldKey(amount))) { plainVar(it.use, DataValue.integer(1)) }.created()
            commit(
                setDefinitionValue(amount, plainVar(typeUse, DataValue.TypeUseWrapper(textUse))),
                setDefinitionValue(user, plainVar(fieldKey(amount), DataValue.StringValueWrapper("one"))),
            ).shouldBeCommitted()
        }
    }

    test("an invalid declaration followed by an intent that uses it is refused with its declaration code") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val type = commitTypeDefinition("Late", plainType(intUse)).created()
            val invalid = declares { record { parameter("T") } }.on(type)
            commit(setTypes(type, invalid.types), setDefinitionValue(type, plainVar(typeUse, DataValue.TypeUseWrapper(invalid.use))))
                .shouldBeRejected("declaration_has_parameters")
        }
    }

    test("a stored position naming an alias admits a value of the alias's type and refuses another") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val amount = commitTypeDefinition("Amount", plainType(intUse)).created()
            val user = commitDefinition("user", plainType(fieldKey(amount))) { plainVar(it.use, DataValue.integer(1)) }.created()
            expectRefused(setDefinitionValue(user, plainVar(fieldKey(amount), DataValue.StringValueWrapper("one"))))
        }
    }

    test("a new use of an alias commits") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val amount = commitTypeDefinition("Amount", plainType(intUse)).created()
            commitDefinition("first", plainType(fieldKey(amount))).created()
            commitDefinition("second", plainType(listType(fieldKey(amount)))).created()
        }
    }

    test("an alias of an alias resolves through both") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val amount = commitTypeDefinition("Amount", plainType(intUse)).created()
            val price = commitTypeDefinition("Price", plainType(fieldKey(amount))).created()
            val cost = commitDefinition("cost", plainType(fieldKey(price))) { plainVar(it.use, DataValue.integer(3)) }.created()
            expectRefused(setDefinitionValue(cost, plainVar(fieldKey(price), DataValue.StringValueWrapper("three"))))
        }
    }

    test("changing an alias changes what its stored users admit") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val amount = commitTypeDefinition("Amount", plainType(intUse)).created()
            val user = commitDefinition("user", plainType(fieldKey(amount))).created()
            commit(setDefinitionValue(amount, plainVar(typeUse, DataValue.TypeUseWrapper(textUse)))).shouldBeCommitted()
            expectRefused(setDefinitionValue(user, plainVar(fieldKey(amount), DataValue.integer(2))))
            commit(setDefinitionValue(user, plainVar(fieldKey(amount), DataValue.StringValueWrapper("two")))).shouldBeCommitted()
        }
    }

    test("retyping a record as an alias keeps its users, and back again") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val reward = commitTypeDefinition("Reward", gold).created()
            val user = commitRecordUser("first", reward, "gold" to DataValue.integer(1))
            commit(
                setTypes(reward, emptyList()),
                setDefinitionValue(reward, plainVar(typeUse, DataValue.TypeUseWrapper(intUse))),
            ).shouldBeCommitted()
            typeArgumentOf(user) shouldBe fieldKey(reward)
            commit(setDefinitionValue(user, plainVar(fieldKey(reward), DataValue.integer(2)))).shouldBeCommitted()
            val record = gold.on(reward)
            commit(
                setTypes(reward, record.types),
                setDefinitionValue(reward, plainVar(typeUse, DataValue.TypeUseWrapper(record.use))),
            ).shouldBeCommitted()
            typeArgumentOf(user) shouldBe fieldKey(reward)
            commit(
                setDefinitionValue(user, plainVar(fieldKey(reward), recordValue(fieldKey(reward), "gold" to DataValue.integer(3)))),
            ).shouldBeCommitted()
        }
    }

    test("two aliases in a loop resolve as missing and do not hang") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val first = commitTypeDefinition("First", plainType(intUse)).created()
            val second = commitTypeDefinition("Second", plainType(fieldKey(first))).created()
            val looping = DataValue.TypeUseWrapper(fieldKey(second))
            commit(setDefinitionValue(first, plainVar(typeUse, looping))).shouldBeRejected().codes.distinct() shouldBe
                listOf("content_alias_loop")
            val looped = catalogOver(mapOf(first to record(first).with("value", plainVar(typeUse, looping))))
            looped.resolve(fieldKey(second)) shouldBeReady true
            looped.unavailableCode(TypeDefinitionId.contentField(second, "value")) shouldBe "content_alias_loop"
        }
    }

    test("an alias that contains itself reports an alias loop") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val looped = commitTypeDefinition("Looped", plainType(intUse)).created()
            commit(setDefinitionValue(looped, plainVar(typeUse, DataValue.TypeUseWrapper(listType(fieldKey(looped))))))
                .shouldBeRejected()
                .codes
                .distinct() shouldBe listOf("content_alias_loop")
        }
    }

    test("an alias of a list of a deleted alias reports a missing type, not a loop") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val amount = commitTypeDefinition("Amount", plainType(intUse)).created()
            val amounts = commitTypeDefinition("Amounts", plainType(listType(fieldKey(amount)))).created()
            commit(delete(amount)).shouldBeCommitted()
            commitDefinition("user", plainType(fieldKey(amounts)))
                .reply
                .shouldBeRejected()
                .codes
                .distinct() shouldBe
                listOf("content_type_missing")
        }
    }

    test("a client union that lists a case without that union as its parent is refused when used") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val declared =
                declares {
                    declare(recordDefinition(id("door.Open")))
                    declare(recordDefinition(id("door"), RecordForm.createClosed(cases = listOf(id("door.Open").namedTemplate()))))
                }
            commitDefinition("door", declared).reply.shouldBeRejected("case_missing_parent")
        }
    }

    test("a client record with two fields of one name is refused when used") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            commitDefinition(
                "twice",
                declares {
                    record {
                        field("gold", intUse)
                        field("gold", textUse)
                    }
                },
            ).reply.shouldBeRejected("duplicate_field")
        }
    }

    test("two client unions that list each other as case and parent are refused when used") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val declared =
                declares {
                    declare(recordDefinition(id("a"), RecordForm.createClosed(cases = listOf(id("b").namedTemplate())), parent = id("b")))
                    declare(recordDefinition(id("b"), RecordForm.createClosed(cases = listOf(id("a").namedTemplate())), parent = id("a")))
                }
            commitDefinition("cycle", declared).reply.shouldBeRejected("inheritance_cycle")
        }
    }

    test("a code record whose parent is open stays available") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            statusOf(DefinitionDefinition.id) shouldBe DeclarationStatus.READY
        }
    }

    test("a used declaration with a field key is refused") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val declared =
                ContentTypes { owner ->
                    DeclaredTypes(fieldKey(owner), listOf(recordDefinition(TypeDefinitionId.contentField(owner, "value"))))
                }
            val before = resources
            commitDefinition("keyed", declared).reply.shouldBeRejected("declaration_key")
            resources shouldBe before
        }
    }

    test("an unused declaration with a field key is refused") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val declared =
                ContentTypes { owner ->
                    gold.on(owner).let {
                        DeclaredTypes(
                            it.use,
                            it.types + recordDefinition(TypeDefinitionId.contentField(owner, "value")),
                        )
                    }
                }
            val before = resources
            commitDefinition("keyed", declared).reply.shouldBeRejected("declaration_key")
            resources shouldBe before
        }
    }

    test("an operation over a draft holding a declaration filed on another resource is refused") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val reward = commitDefinition("reward", gold).created()
            val foreign = TypeDefinitionId.content(singleOf(StaticPageDefinition.id), "k1")
            val draft = record(reward).copy(types = record(reward).types + recordDefinition(foreign))
            shouldThrow<IllegalArgumentException> { overDraft(mapOf(reward to draft)) { it } }.message shouldContain
                "declaration_owner_mismatch"
        }
    }

    test("a view catalog reads an alias the same through every public entry") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val reward = commitTypeDefinition("Reward", gold).created()
            val alias = commitTypeDefinition("Prize", plainType(fieldKey(reward))).created()
            val declared = record(reward).types.single().id
            val viaAlias = TypeDefinitionId.contentField(alias, "value")
            val catalog = viewCatalog
            catalog.isReadableAs(viaAlias.use(), declared.use()) shouldBe true
            catalog.isNominalSubtype(viaAlias, declared) shouldBe true
            catalog.knownApplications(TypeSelection.CompleteWrapper(viaAlias.namedUse())) shouldContain declared.namedUse()
            catalog.definition(viaAlias) shouldBe DeclarationStatus.READY
        }
    }

    test("a case of a union named through a field resolves to the declared case") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val door =
                commitTypeDefinition(
                    "Door",
                    declares {
                        union {
                            case("Open")
                            case("Closed")
                        }
                    },
                ).created()
            val viaField = TypeDefinitionId.contentField(door, "value").member("Open")
            resolvedSchema(viaField.use()) shouldBe resolvedSchema(TypeDefinitionId.content(door, "k1").member("Open").use())
        }
    }

    test("an operation over an unsaved edit to a holder that no longer fits runs") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val reward = commitTypeDefinition("Reward", gold).created()
            val user = commitRecordUser("first", reward, "gold" to DataValue.integer(1))
            commit(delete(reward)).shouldBeCommitted()
            overDraft(mapOf(user to record(user).with("name", DataValue.StringValueWrapper("renamed")))) {
                it.unavailableCode(TypeDefinitionId.contentField(reward, "value"))
            } shouldBe
                "content_type_missing"
        }
    }

    test("an operation over a draft that adds a new misfit is refused") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val reward = commitDefinition("reward", gold).created()
            val type = typeArgumentOf(reward)
            val misfit =
                record(reward).copy(
                    fields =
                        record(reward).fields.map {
                            if (it.name ==
                                "value"
                            ) {
                                it.copy(value = plainVar(type, recordValue(type, "copper" to DataValue.integer(1))))
                            } else {
                                it
                            }
                        },
                )
            shouldThrow<IllegalArgumentException> { overDraft(mapOf(reward to misfit)) { it } }.message shouldContain "unknown_field"
        }
    }

    test("an operation sees a declaration added in its draft") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val reward = commitDefinition("reward", gold).created()
            val extra = TypeDefinitionId.content(reward, "extra")
            val draft = record(reward).copy(types = record(reward).types + recordDefinition(extra))
            overDraft(mapOf(reward to draft)) { it.definition(extra) } shouldBe DeclarationStatus.READY
        }
    }

    test("an operation over a draft that uses an invalid declaration is refused") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val type = commitTypeDefinition("Late", plainType(intUse)).created()
            val invalid = declares { record { parameter("T") } }.on(type)
            val draft =
                record(type).copy(
                    types = invalid.types,
                    fields =
                        record(type).fields.map {
                            if (it.name ==
                                "value"
                            ) {
                                it.copy(value = plainVar(typeUse, DataValue.TypeUseWrapper(invalid.use)))
                            } else {
                                it
                            }
                        },
                )
            shouldThrow<IllegalArgumentException> { overDraft(mapOf(type to draft)) { it } }.message shouldContain
                "declaration_has_parameters"
        }
    }

    test("the code catalog answers a content id as an unknown definition") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val reward = commitDefinition("reward", gold).created()
            val id = record(reward).types.single().id
            viewCatalog.definition(id) shouldBe DeclarationStatus.READY
            codeCatalog
                .definition(id)
                .shouldBeInstanceOf<DeclarationStatus.UnavailableWrapper>()
                .value
                .map { it.code } shouldBe
                listOf("unknown_definition")
        }
    }

    test("a page with content typed values passes publication") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val reward =
                commitDefinition(
                    "reward",
                    gold,
                ) { plainVar(it.use, recordValue(it.use, "gold" to DataValue.integer(70))) }.created()
            publicationBlockers().mapNotNull { it.primary?.resource } shouldNotContain reward
            publishToEngine().getValue(reward).shouldBeInstanceOf<Definition<*>>()
        }
    }

    test("a declaration edit between two publications uses the new schema") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val reward =
                commitDefinition(
                    "reward",
                    gold,
                ) { plainVar(it.use, recordValue(it.use, "gold" to DataValue.integer(70))) }.created()
            publishToEngine()
            val type = typeArgumentOf(reward)
            commit(
                setTypes(reward, declares { record("k1") { field("silver", intUse) } }),
                setDefinitionValue(reward, plainVar(type, recordValue(type, "silver" to DataValue.integer(3)))),
            ).shouldBeCommitted()
            publicationBlockers().mapNotNull { it.primary?.resource } shouldNotContain reward
            publishToEngine()
                .getValue(reward)
                .shouldBeInstanceOf<Definition<*>>()
                .value
                .toString() shouldContain "3"
        }
    }

    test("a published Definition of an alias names the alias's type, expanded") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val amount = commitTypeDefinition("Amount", plainType(intUse)).created()
            val cost = commitDefinition("cost", plainType(fieldKey(amount))) { plainVar(it.use, DataValue.integer(3)) }.created()
            publicationBlockers().mapNotNull { it.primary?.resource } shouldNotContain cost
            publishToEngine()
                .getValue(cost)
                .shouldBeInstanceOf<Definition<*>>()
                .value
                .toString() shouldContain "3"
        }
    }

    val holder = ResourceId(value = "holder")
    val target = ResourceId(value = "target")
    val unrelated = ResourceId(value = "unrelated")
    val withSpareSlot = nodeCatalog(pairRelation(), extraFields = { field("spare", linkType(PAIR_FIRST).template()) })
    val withoutSpareSlot = nodeCatalog(pairRelation())
    val linkedThroughSpare =
        mapOf(
            holder to node().with("spare", link(PAIR_FIRST, target, path("second"))),
            target to node(second = link(PAIR_SECOND, holder, path("spare"))),
            unrelated to node(),
        )

    test("after a new generation drops a Ref slot from a code type, a delete elsewhere commits") {
        RealmFixture.of(withSpareSlot, linkedThroughSpare).use { realm ->
            realm.restart(withoutSpareSlot)
            realm.commit(delete(unrelated)).shouldBeCommitted()
        }
    }

    test("deleting the target of a link in a slot a new generation dropped clears that link") {
        RealmFixture.of(withSpareSlot, linkedThroughSpare).use { realm ->
            realm.restart(withoutSpareSlot)
            realm.commit(delete(target)).shouldBeCommitted()
            realm.resources.getValue(holder).valueAt(path("spare")) shouldBe DataValue.UNFILLED
        }
    }

    test("a commit to a code record whose slot a new generation removed is refused only for a new misfit") {
        RealmFixture.of(withSpareSlot, linkedThroughSpare).use { realm ->
            realm.restart(withoutSpareSlot)
            realm
                .commit(
                    EditIntent.createSetValue(at = at(holder, "label"), value = DataValue.StringValueWrapper("renamed")),
                ).shouldBeCommitted()
            realm
                .expectRefused(
                    EditIntent.createSetValue(at = at(unrelated, "spare"), value = link(PAIR_FIRST, holder)),
                ).map { it.code } shouldContain
                "unknown_field"
        }
    }

    test("an operation can read a resource it just created with a content type") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val (declared, read) = readJustCreated("reward", gold) { plainVar(it.use, recordValue(it.use, "gold" to DataValue.integer(3))) }
            read shouldBe
                Availability.Available(PortableValue(actualType = declared.use, payload = DataValue.record("gold" to DataValue.integer(3))))
        }
    }

    test("an operation that creates a content type and writes a value of it in the same edit commits") {
        withSetup(staticPage, catalog = routeFixtureCatalog) {
            val door =
                declares {
                    union {
                        case("Open")
                        case("Closed")
                    }
                }
            val id =
                commitCreateThenSet("door", door) {
                    plain(PortableValue(actualType = checkNotNull(it.use.named).definition.member("Open").use(), payload = DataValue.UNIT))
                }.created()
            value(id, "value", "value") shouldBe caseValue(door.on(id).use, "Open")
        }
    }
}
