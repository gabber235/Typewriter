package com.typewritermc.realm.repository

import com.typewritermc.elements.ElementInstanceId
import com.typewritermc.elements.ElementPlacement
import com.typewritermc.elements.ElementSearchDefinition
import com.typewritermc.elements.ElementSearchMode
import com.typewritermc.elements.ElementSearchPolicy
import com.typewritermc.elements.ElementSearchPropertyOverride
import com.typewritermc.elements.ElementTypeId
import com.typewritermc.elements.ElementValueMutation
import com.typewritermc.elements.ElementValuePath
import com.typewritermc.elements.ElementValuePathSegment
import com.typewritermc.library.ChapterPath
import com.typewritermc.library.GridPlacement
import com.typewritermc.library.PageId
import com.typewritermc.library.TagId
import com.typewritermc.library.ref
import com.typewritermc.realm.TestPageKinds
import com.typewritermc.realm.repository.search.AuthoringSearchFilter
import com.typewritermc.realm.repository.search.AuthoringSearchHit
import com.typewritermc.realm.repository.search.AuthoringSearchRequest
import com.typewritermc.realm.repository.search.AuthoringSelectorKind
import com.typewritermc.realm.repository.search.AuthoringSelectorSuggestionRequest
import com.typewritermc.realm.repository.search.SearchFilterExpression
import com.typewritermc.realm.routes.toLibrary
import com.typewritermc.types.Color
import com.typewritermc.types.DataValue
import com.typewritermc.types.DeclaredTypeId
import com.typewritermc.types.Icon
import com.typewritermc.types.NominalTypeKind
import com.typewritermc.types.ResolvedTypeRef
import com.typewritermc.types.TypeDefinition
import com.typewritermc.types.TypeExpression
import com.typewritermc.types.TypeField
import com.typewritermc.types.TypeGraph
import com.typewritermc.types.TypeId
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.test.runTest

val AuthoringSearchRepositoryTest by testSuite {
    test("returns default pages for an empty query") {
        runTest {
            RepositoryFixture().use { fixture ->
                val book = fixture.createBook("harbor", "harbor")
                val page = fixture.createPage("arrival", book.id, TestPageKinds.STATIC.toLibrary(), "arrival")

                val result = fixture.search.search(request(""))

                result.hits.any { it.resource == AuthoringResourceRef.Page(page.id) } shouldBe true
            }
        }
    }

    test("projects typed content and preserves its concrete value path") {
        runTest {
            RepositoryFixture().use { fixture ->
                fixture.registerElementType(SEARCH_ELEMENT_TYPE, SEARCH_GRAPH, SEARCH_DEFINITION, "Dialogue")
                val book = fixture.createBook("harbor", "harbor")
                val page = fixture.createPage("arrival", book.id, TestPageKinds.STATIC.toLibrary(), "arrival")
                fixture.createSearchElement(page.id, SEARCH_ELEMENT, "Greeting", "Bring the lantern to Rowan")

                val result = fixture.search.search(request("lantern"))

                (result.hits.single() as AuthoringSearchHit.Element).apply {
                    resource shouldBe AuthoringResourceRef.Element(SEARCH_ELEMENT)
                    title shouldBe "Greeting"
                    bookTitle shouldBe "harbor"
                    pageTitle shouldBe "arrival"
                    elementType shouldBe SEARCH_ELEMENT_TYPE
                    kind shouldBe TestPageKinds.STATIC.toLibrary()
                    placement shouldBe ElementPlacement.Graph(0, 0, 2, 1)
                    match?.text shouldBe "Bring the lantern to Rowan"
                }
                fixture.search
                    .search(request("Rowan lantern"))
                    .hits
                    .single()
                    .resource shouldBe
                    AuthoringResourceRef.Element(SEARCH_ELEMENT)
                fixture.search
                    .search(request("lantrn"))
                    .hits
                    .single { it.resource == AuthoringResourceRef.Element(SEARCH_ELEMENT) }
                    .match
                    ?.text shouldBe "Bring the lantern to Rowan"
                fixture.search
                    .search(request("harbor lantern"))
                    .hits
                    .any { it.resource == AuthoringResourceRef.Element(SEARCH_ELEMENT) } shouldBe true
                fixture.search
                    .search(request("search_element"))
                    .hits
                    .first()
                    .resource shouldBe
                    AuthoringResourceRef.Element(SEARCH_ELEMENT)
                fixture.search
                    .search(request("Greetng"))
                    .hits
                    .single()
                    .resource shouldBe
                    AuthoringResourceRef.Element(SEARCH_ELEMENT)
            }
        }
    }

    test("returns partial name matches") {
        runTest {
            RepositoryFixture().use { fixture ->
                val book = fixture.createBook("main_quest", "main_quest")

                val result = fixture.search.search(request("mai"))

                result.hits.map(AuthoringSearchHit::resource) shouldContainExactly
                    listOf(AuthoringResourceRef.Book(book.id))
                fixture.search
                    .search(request("m"))
                    .hits
                    .map(AuthoringSearchHit::resource) shouldContainExactly listOf(AuthoringResourceRef.Book(book.id))
            }
        }
    }

    test("returns prefix and approximate matches beside stronger matches") {
        runTest {
            RepositoryFixture().use { fixture ->
                val exact = fixture.createBook("main", "main")
                val prefix = fixture.createBook("maintenance", "maintenance")
                val approximate = fixture.createBook("greeting", "greeting")
                val typo = fixture.createBook("greetng", "greetng")

                val mainResults =
                    fixture.search
                        .search(request("main"))
                        .hits
                        .map(AuthoringSearchHit::resource)
                val greetingResults =
                    fixture.search
                        .search(request("greetng"))
                        .hits
                        .map(AuthoringSearchHit::resource)

                mainResults.take(2) shouldContainExactly
                    listOf(
                        AuthoringResourceRef.Book(exact.id),
                        AuthoringResourceRef.Book(prefix.id),
                    )
                greetingResults.take(2) shouldContainExactly
                    listOf(
                        AuthoringResourceRef.Book(typo.id),
                        AuthoringResourceRef.Book(approximate.id),
                    )
            }
        }
    }

    test("replaces and deletes payload documents in the authoring transaction") {
        runTest {
            RepositoryFixture().use { fixture ->
                fixture.registerElementType(SEARCH_ELEMENT_TYPE, SEARCH_GRAPH, SEARCH_DEFINITION, "Dialogue")
                val book = fixture.createBook("harbor", "harbor")
                val page = fixture.createPage("arrival", book.id, TestPageKinds.STATIC.toLibrary(), "arrival")
                fixture.createSearchElement(page.id, SEARCH_ELEMENT, "Greeting", "Bring the lantern")

                fixture.authoring.apply(
                    AuthoringBatch(
                        BatchId("replace-search-content"),
                        listOf(
                            AuthoringOperation.PatchElement(
                                SEARCH_ELEMENT,
                                valueMutations =
                                    listOf(
                                        ExpectedElementValueMutation(
                                            DataValue.StringValue("Bring the lantern"),
                                            ElementValueMutation.SetValue(
                                                DIALOGUE_PATH,
                                                DataValue.StringValue("Follow the compass"),
                                            ),
                                        ),
                                    ),
                            ),
                        ),
                    ),
                )

                fixture.search.search(request("lantern")).hits shouldBe emptyList()
                fixture.search
                    .search(request("compass"))
                    .hits
                    .single()
                    .match
                    ?.text shouldBe "Follow the compass"

                fixture.authoring.apply(
                    AuthoringBatch(
                        BatchId("delete-search-content"),
                        listOf(AuthoringOperation.DeleteElement(SEARCH_ELEMENT)),
                    ),
                )
                fixture.search.search(request("compass")).hits shouldBe emptyList()
            }
        }
    }

    test("keeps canonical names searchable when content projection is unavailable") {
        runTest {
            RepositoryFixture().use { fixture ->
                val book = fixture.createBook("harbor", "harbor")
                val page = fixture.createPage("arrival", book.id, TestPageKinds.STATIC.toLibrary(), "arrival")
                fixture.createUnavailableElement(page.id)

                val result = fixture.search.search(request("Fallback"))

                result.hits.any { it.resource == AuthoringResourceRef.Element(UNAVAILABLE_ELEMENT) } shouldBe true
            }
        }
    }

    test("boosts nearby authoring results without filtering other books") {
        runTest {
            RepositoryFixture().use { fixture ->
                fixture.registerElementType(SEARCH_ELEMENT_TYPE, SEARCH_GRAPH, SEARCH_DEFINITION, "Dialogue")
                val harbor = fixture.createBook("harbor", "harbor")
                val forest = fixture.createBook("forest", "forest")
                val current =
                    fixture.createPage(
                        "current",
                        harbor.id,
                        TestPageKinds.STATIC.toLibrary(),
                        chapter = ChapterPath.parse("quest.intro.dialogue"),
                    )
                val sameChapter =
                    fixture.createPage(
                        "same_chapter",
                        harbor.id,
                        TestPageKinds.STATIC.toLibrary(),
                        chapter = ChapterPath.parse("quest.intro.dialogue"),
                    )
                val parent =
                    fixture.createPage(
                        "parent",
                        harbor.id,
                        TestPageKinds.STATIC.toLibrary(),
                        chapter = ChapterPath.parse("quest.intro"),
                    )
                val sibling =
                    fixture.createPage(
                        "sibling",
                        harbor.id,
                        TestPageKinds.STATIC.toLibrary(),
                        chapter = ChapterPath.parse("quest.intro.other"),
                    )
                val root =
                    fixture.createPage(
                        "root",
                        harbor.id,
                        TestPageKinds.STATIC.toLibrary(),
                        chapter = ChapterPath.Root,
                    )
                val otherBook =
                    fixture.createPage(
                        "other_book",
                        forest.id,
                        TestPageKinds.STATIC.toLibrary(),
                        chapter = ChapterPath.parse("quest.intro.dialogue"),
                    )
                val ids =
                    listOf(
                        ElementInstanceId("current_result"),
                        ElementInstanceId("same_chapter_result"),
                        ElementInstanceId("parent_result"),
                        ElementInstanceId("sibling_result"),
                        ElementInstanceId("root_result"),
                        ElementInstanceId("other_book_result"),
                    )
                listOf(current, sameChapter, parent, sibling, root, otherBook)
                    .zip(ids)
                    .forEach { (page, id) -> fixture.createSearchElement(page.id, id, "Nearby", "shared") }

                val result =
                    fixture.search
                        .search(request("Nearby", contextPage = current.id))
                        .hits
                        .mapNotNull { (it.resource as? AuthoringResourceRef.Element)?.id }

                result shouldContainExactly ids
                result.last() shouldBe ElementInstanceId("other_book_result")
            }
        }
    }

    test("preserves boolean selector semantics for authoring resources") {
        runTest {
            RepositoryFixture().use { fixture ->
                fixture.registerElementType(SEARCH_ELEMENT_TYPE, SEARCH_GRAPH, SEARCH_DEFINITION, "Dialogue")
                val harbor = fixture.createBook("harbor", "harbor")
                val forest = fixture.createBook("forest", "forest")
                val harborPage = fixture.createPage("harbor_arrival", harbor.id, TestPageKinds.STATIC.toLibrary(), "arrival")
                val forestPage = fixture.createPage("forest_arrival", forest.id, TestPageKinds.STATIC.toLibrary(), "arrival")
                fixture.createSearchElement(harborPage.id, HARBOR_ELEMENT, "Greeting", "Harbor dialogue")
                fixture.createSearchElement(forestPage.id, FOREST_ELEMENT, "Greeting", "Forest dialogue")

                fixture.elementIds(
                    SearchFilterExpression.And(filter("book", "harbor"), filter("page", "harbor_arrival")),
                ) shouldBe setOf(HARBOR_ELEMENT)
                fixture.elementIds(
                    SearchFilterExpression.Or(filter("book", "harbor"), filter("page", "forest_arrival")),
                ) shouldBe setOf(HARBOR_ELEMENT, FOREST_ELEMENT)
                fixture.elementIds(SearchFilterExpression.Not(filter("book", "harbor"))) shouldBe setOf(FOREST_ELEMENT)
                fixture.elementIds(
                    SearchFilterExpression.Or(filter("book", "harbor"), filter("book", "forest")),
                ) shouldBe setOf(HARBOR_ELEMENT, FOREST_ELEMENT)
                fixture.elementIds(null) shouldBe setOf(HARBOR_ELEMENT, FOREST_ELEMENT)
                fixture.search
                    .search(request("harbor", filter = filter("page", "forest_arrival")))
                    .hits
                    .any { it.resource == AuthoringResourceRef.Book(harbor.id) } shouldBe false
            }
        }
    }

    test("type selectors include elements whose type inherits the selected type") {
        runTest {
            RepositoryFixture().use { fixture ->
                fixture.registerElementType(INHERITED_PARENT_TYPE, INHERITED_PARENT_GRAPH, SEARCH_DEFINITION, "Parent")
                fixture.registerElementType(INHERITED_CHILD_TYPE, INHERITED_CHILD_GRAPH, SEARCH_DEFINITION, "Child")
                val book = fixture.createBook("harbor", "harbor")
                val page = fixture.createPage("arrival", book.id, TestPageKinds.STATIC.toLibrary(), "arrival")
                fixture.createSearchElement(
                    page.id,
                    INHERITED_ELEMENT,
                    "Inherited",
                    "Inherited dialogue",
                    INHERITED_CHILD_TYPE,
                )

                val result = fixture.search.search(request("Inherited", filter = filter("type", "Parent")))

                result.hits.map(AuthoringSearchHit::resource) shouldContainExactly
                    listOf(AuthoringResourceRef.Element(INHERITED_ELEMENT))
                result.selectorValidations.single().accepted shouldBe true
            }
        }
    }

    test("tag selectors include books bearing descendant tags") {
        runTest {
            RepositoryFixture().use { fixture ->
                fixture.registerElementType(SEARCH_ELEMENT_TYPE, SEARCH_GRAPH, SEARCH_DEFINITION, "Dialogue")
                fixture.authoring.apply(
                    AuthoringBatch(
                        BatchId("create-search-tags"),
                        listOf(
                            AuthoringOperation.CreateTag(
                                TagId("quests"),
                                com.typewritermc.library.LibraryName("quests"),
                                Color(0u),
                                emptyList(),
                                GridPlacement(0, 0, 3, 1),
                            ),
                            AuthoringOperation.CreateTag(
                                TagId("side_quests"),
                                com.typewritermc.library.LibraryName("side_quests"),
                                Color(0u),
                                listOf(TagId("quests").ref()),
                                GridPlacement(0, 1, 3, 1),
                            ),
                            AuthoringOperation.CreateBook(
                                com.typewritermc.library.BookId("harbor"),
                                com.typewritermc.library.LibraryName("harbor"),
                                Icon.parse("mdi:book"),
                                Color(0u),
                                listOf(TagId("side_quests").ref()),
                            ),
                            AuthoringOperation.CreateBook(
                                com.typewritermc.library.BookId("forest"),
                                com.typewritermc.library.LibraryName("forest"),
                                Icon.parse("mdi:book"),
                                Color(0u),
                                emptyList(),
                            ),
                        ),
                    ),
                )
                val harborPage =
                    fixture.createPage(
                        "harbor_arrival",
                        com.typewritermc.library.BookId("harbor"),
                        TestPageKinds.STATIC.toLibrary(),
                        "arrival",
                    )
                val forestPage =
                    fixture.createPage(
                        "forest_arrival",
                        com.typewritermc.library.BookId("forest"),
                        TestPageKinds.STATIC.toLibrary(),
                        "arrival",
                    )
                fixture.createSearchElement(harborPage.id, HARBOR_ELEMENT, "Greeting", "Harbor dialogue")
                fixture.createSearchElement(forestPage.id, FOREST_ELEMENT, "Greeting", "Forest dialogue")

                fixture.elementIds(filter("tag", "quests")) shouldBe setOf(HARBOR_ELEMENT)
                fixture.search
                    .search(request("quests", filter = filter("book", "forest")))
                    .hits
                    .any { it.resource == AuthoringResourceRef.Tag(TagId("quests")) } shouldBe false
            }
        }
    }

    test("validates completed selector values exactly") {
        runTest {
            RepositoryFixture().use { fixture ->
                fixture.createBook("harbor", "harbor")

                val accepted = fixture.search.search(request("", filter = filter("book", "harbor")))
                val rejected = fixture.search.search(request("", filter = filter("book", "Missing")))

                accepted.selectorValidations.single().accepted shouldBe true
                rejected.selectorValidations.single().accepted shouldBe false
            }
        }
    }

    test("suggestions apply the projected boolean scope") {
        runTest {
            RepositoryFixture().use { fixture ->
                val harbor = fixture.createBook("harbor", "harbor")
                val forest = fixture.createBook("forest", "forest")
                fixture.createPage("harbor_arrival", harbor.id, TestPageKinds.STATIC.toLibrary(), "arrival")
                fixture.createPage("forest_clearing", forest.id, TestPageKinds.STATIC.toLibrary(), "clearing")

                val suggestions =
                    fixture.search.suggest(
                        AuthoringSelectorSuggestionRequest(
                            kind = AuthoringSelectorKind.PAGE,
                            partial = "",
                            filter = SearchFilterExpression.Not(filter("book", "harbor")),
                        ),
                    )

                suggestions.values shouldContainExactly listOf("clearing")
                suggestions.exhaustive shouldBe true
            }
        }
    }
}

private fun filter(
    selectorId: String,
    value: String,
): SearchFilterExpression<AuthoringSearchFilter> =
    SearchFilterExpression.Value(
        AuthoringSearchFilter(
            kind =
                when (selectorId) {
                    "book" -> AuthoringSelectorKind.BOOK
                    "page" -> AuthoringSelectorKind.PAGE
                    "tag" -> AuthoringSelectorKind.TAG
                    "type" -> AuthoringSelectorKind.ELEMENT_TYPE
                    else -> error("Unknown authoring selector $selectorId")
                },
            value = value,
        ),
    )

private fun request(
    query: String,
    filter: SearchFilterExpression<AuthoringSearchFilter>? = null,
    contextPage: PageId? = null,
): AuthoringSearchRequest =
    AuthoringSearchRequest(
        query = query,
        terms = query.lowercase().split(' ').filter(String::isNotBlank),
        filter = filter,
        contextPage = contextPage,
    )

private fun RepositoryFixture.elementIds(filter: SearchFilterExpression<AuthoringSearchFilter>?): Set<ElementInstanceId> =
    search
        .search(request("Greeting", filter = filter))
        .hits
        .mapNotNull { (it.resource as? AuthoringResourceRef.Element)?.id }
        .toSet()

private suspend fun RepositoryFixture.createSearchElement(
    page: PageId,
    id: ElementInstanceId,
    name: String,
    dialogue: String,
    elementType: ElementTypeId = SEARCH_ELEMENT_TYPE,
) {
    authoring.apply(
        AuthoringBatch(
            BatchId("create-search-${id.value}"),
            listOf(
                AuthoringOperation.CreateElement(
                    AuthoringElement(
                        id = id,
                        page = page.ref(),
                        elementType = elementType,
                        schemaRevision = 1,
                        value =
                            DataValue.Record(
                                mapOf(
                                    "id" to DataValue.StringValue(id.value),
                                    "name" to DataValue.StringValue(name),
                                    "dialogue" to DataValue.StringValue(dialogue),
                                ),
                            ),
                        placement = ElementPlacement.Graph(0, 0, 2, 1),
                    ),
                ),
            ),
        ),
    )
}

private suspend fun RepositoryFixture.createUnavailableElement(page: PageId) {
    registerElementType(
        UNAVAILABLE_ELEMENT_TYPE,
        TypeGraph(
            TypeExpression.Record(
                listOf(
                    TypeField("id", TypeExpression.StringType()),
                    TypeField("name", TypeExpression.StringType()),
                    TypeField("payload", TypeExpression.StringType()),
                ),
            ),
            emptyList(),
        ),
    )
    authoring.apply(
        AuthoringBatch(
            BatchId("create-unavailable-search"),
            listOf(
                AuthoringOperation.CreateElement(
                    AuthoringElement(
                        id = UNAVAILABLE_ELEMENT,
                        page = page.ref(),
                        elementType = UNAVAILABLE_ELEMENT_TYPE,
                        schemaRevision = 1,
                        value =
                            DataValue.Record(
                                mapOf(
                                    "id" to DataValue.StringValue(UNAVAILABLE_ELEMENT.value),
                                    "name" to DataValue.StringValue("Fallback name"),
                                    "payload" to DataValue.StringValue("Invisible payload"),
                                ),
                            ),
                        placement = ElementPlacement.Graph(0, 0, 2, 1),
                    ),
                ),
            ),
        ),
    )
}

private val SEARCH_ELEMENT_TYPE = ElementTypeId(DeclaredTypeId.parse("50000000000000000000000000000001"))
private val SEARCH_ELEMENT = ElementInstanceId("search_element")
private val HARBOR_ELEMENT = ElementInstanceId("harbor_element")
private val FOREST_ELEMENT = ElementInstanceId("forest_element")
private val UNAVAILABLE_ELEMENT_TYPE = ElementTypeId(DeclaredTypeId.parse("50000000000000000000000000000002"))
private val UNAVAILABLE_ELEMENT = ElementInstanceId("unavailable_element")
private val INHERITED_PARENT_TYPE = ElementTypeId(DeclaredTypeId.parse("50000000000000000000000000000003"))
private val INHERITED_CHILD_TYPE = ElementTypeId(DeclaredTypeId.parse("50000000000000000000000000000004"))
private val INHERITED_ELEMENT = ElementInstanceId("inherited_element")
private val SEARCH_TYPE_REF = ResolvedTypeRef(TypeId.Declared(SEARCH_ELEMENT_TYPE.value), 1)
private val INHERITED_PARENT_TYPE_REF = ResolvedTypeRef(TypeId.Declared(INHERITED_PARENT_TYPE.value), 1)
private val INHERITED_CHILD_TYPE_REF = ResolvedTypeRef(TypeId.Declared(INHERITED_CHILD_TYPE.value), 1)
private val SEARCH_GRAPH =
    TypeGraph(
        root = TypeExpression.Named(SEARCH_TYPE_REF),
        definitions =
            listOf(
                TypeDefinition(
                    id = SEARCH_TYPE_REF,
                    kind = NominalTypeKind.CONCRETE,
                    representation =
                        TypeExpression.Record(
                            listOf(
                                TypeField("id", TypeExpression.StringType()),
                                TypeField("name", TypeExpression.StringType()),
                                TypeField("dialogue", TypeExpression.StringType()),
                            ),
                        ),
                ),
            ),
    )
private val SEARCH_DEFINITION =
    ElementSearchDefinition(
        policy = ElementSearchPolicy.ORDINARY_TEXT,
        propertyOverrides =
            listOf(
                ElementSearchPropertyOverride(SEARCH_TYPE_REF, "id", ElementSearchMode.NONE),
                ElementSearchPropertyOverride(SEARCH_TYPE_REF, "name", ElementSearchMode.NONE),
            ),
        revisionFingerprintInputs = listOf(SEARCH_TYPE_REF),
    )
private val INHERITED_PARENT_DEFINITION =
    TypeDefinition(
        id = INHERITED_PARENT_TYPE_REF,
        kind = NominalTypeKind.CONCRETE,
        representation =
            TypeExpression.Record(
                listOf(
                    TypeField("id", TypeExpression.StringType()),
                    TypeField("name", TypeExpression.StringType()),
                    TypeField("dialogue", TypeExpression.StringType()),
                ),
            ),
    )
private val INHERITED_CHILD_DEFINITION =
    TypeDefinition(
        id = INHERITED_CHILD_TYPE_REF,
        kind = NominalTypeKind.CONCRETE,
        representation =
            TypeExpression.Record(
                listOf(
                    TypeField("id", TypeExpression.StringType()),
                    TypeField("name", TypeExpression.StringType()),
                    TypeField("dialogue", TypeExpression.StringType()),
                ),
            ),
        parents = listOf(INHERITED_PARENT_TYPE_REF),
    )
private val INHERITED_PARENT_GRAPH =
    TypeGraph(
        root = TypeExpression.Named(INHERITED_PARENT_TYPE_REF),
        definitions = listOf(INHERITED_PARENT_DEFINITION, INHERITED_CHILD_DEFINITION),
    )
private val INHERITED_CHILD_GRAPH =
    TypeGraph(
        root = TypeExpression.Named(INHERITED_CHILD_TYPE_REF),
        definitions = listOf(INHERITED_PARENT_DEFINITION, INHERITED_CHILD_DEFINITION),
    )
private val DIALOGUE_PATH =
    ElementValuePath(listOf(ElementValuePathSegment.Field("dialogue")))
