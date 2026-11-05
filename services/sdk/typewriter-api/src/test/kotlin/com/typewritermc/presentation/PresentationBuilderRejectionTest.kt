@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.presentation

import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.authoring.field
import com.typewritermc.authoring.root
import com.typewritermc.expression.literal
import com.typewritermc.testkit.buildPresentation
import com.typewritermc.testkit.definitions
import com.typewritermc.testkit.ready
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import com.typewritermc.types.integerScalar
import com.typewritermc.types.listValue
import com.typewritermc.types.namedTemplate
import com.typewritermc.types.qualified
import com.typewritermc.types.template
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import skirout.editor.v1.catalog.PresentationRole
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.IntegerWidth
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.ListItem
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.ValuePath

/*
 * Builder rules that refuse a presentation while it is being built: each case is one invalid declaration and the
 * exact reason the author sees.
 */
val PresentationBuilderRejectionTest by testSuite {
    val titleField = CollectionProjectionFieldSpec(ValuePath.root, CollectionProjectionValueSpec.Content(ValuePath.root.field("title")))

    mapOf<String, Pair<() -> Any, String>>(
        "two tabs with one id" to
            (
                {
                    buildPresentation {
                        tabs {
                            tab("details", literal("Details")) {}
                            tab("details", literal("More")) {}
                        }
                    }
                } to "Tab identifiers must be nonempty and unique."
            ),
        "a tab with a blank id" to
            ({ buildPresentation { tabs { tab(" ", literal("Details")) {} } } } to "Tab identifiers must be nonempty and unique."),
        "a minimum width above the maximum" to
            ({ buildPresentation { size(minimumWidth = 20.0, maximumWidth = 10.0) {} } } to "A minimum width cannot exceed its maximum."),
        "a minimum height above the maximum" to
            (
                {
                    buildPresentation {
                        size(
                            minimumHeight = 20.0,
                            maximumHeight = 10.0,
                        ) {}
                    }
                } to "A minimum height cannot exceed its maximum."
            ),
        "a collection source with a blank id" to
            (
                {
                    collectionSource<String, String>(
                        " ",
                        ScalarKind.TEXT.template,
                    ) { key(row) }
                } to "Collection source ids must not be blank."
            ),
        "a collection source without a row key" to
            ({ collectionSource<String, String>("tags", ScalarKind.TEXT.template) {} } to "A collection source must declare its row key."),
        "two collection relations with one id" to
            (
                {
                    collectionSource<String, String>("tags", ScalarKind.TEXT.template) {
                        key(row)
                        relation("parent", row)
                        relation("parent", row)
                    }
                } to "Collection relation ids must be unique within one source."
            ),
    ).forEach { (case, rejection) ->
        test("$case is refused") {
            shouldThrow<IllegalArgumentException> { rejection.first() }.message shouldBe rejection.second
        }
    }

    val subjectId = TypeDefinitionId.qualified("test", "RejectionSubject")
    val subject =
        DefaultCheckedCatalog(
            CatalogGeneration(value = "field rejections"),
            StandardTypes.definitions + com.typewritermc.types.ResourceIdDefinition.definition +
                definitions {
                    record(subjectId) {
                        field("title", ScalarKind.TEXT.template)
                        field("at", ScalarKind.TIMESTAMP.template)
                    }
                }.single(),
        ).let { it.ready(subjectId.use()) }

    val values =
        com.typewritermc.expression.portableLiteral<List<String>>(
            DataValue.listValue(listOf(ListItem(id = ItemId(value = "a"), value = DataValue.StringValueWrapper("a")))),
        )
    val open = navigate(literal(com.typewritermc.types.ResourceId("book:1")))

    mapOf<String, Pair<() -> Any, String>>(
        "two select options with one id" to
            (
                {
                    buildPresentation(subject, PresentationRole.INSPECTOR) {
                        val title: PresentedField<String, TextControl> = field("title", TextControl::class)
                        title {
                            selectInput(
                                listOf(SelectOption("a", literal("A"), literal("a")), SelectOption("a", literal("B"), literal("b"))),
                            )
                        }
                    }
                } to
                    "Select option identifiers must be unique."
            ),
        "a choice appearance for an option the select does not have" to
            (
                {
                    buildPresentation(subject, PresentationRole.INSPECTOR) {
                        val title: PresentedField<String, TextControl> = field("title", TextControl::class)
                        title { selectInput(listOf(SelectOption("a", literal("A"), literal("a")))) { optionEnabled("b", literal(false)) } }
                    }
                } to
                    "Choice appearance targets an unknown option."
            ),
        "a date time input without date or time" to
            (
                {
                    buildPresentation(subject, PresentationRole.INSPECTOR) {
                        val at: PresentedField<kotlin.time.Instant, DateTimeControl> = field("at", DateTimeControl::class)
                        at {
                            dateTimeInput {
                                includeDate(false)
                                includeTime(false)
                            }
                        }
                    }
                } to "Date or time must be included."
            ),
        "two menu items with one id" to
            (
                {
                    buildPresentation {
                        menu {
                            item("open", literal("Open"), open)
                            item("open", literal("Open again"), open)
                        }
                    }
                } to "Menu item identifiers must be nonempty and unique."
            ),
        "two header items with one id" to
            (
                {
                    buildPresentation {
                        section(
                            header = {
                                button(HeaderItemId("open")) {
                                    icon(literal("mdi:open"))
                                    label(literal("Open"))
                                    action(open)
                                }
                                button(HeaderItemId("open")) {
                                    icon(literal("mdi:open"))
                                    label(literal("Again"))
                                    action(open)
                                }
                            },
                        ) {}
                    }
                } to "Header item ids must be unique within one node."
            ),
        "a header button without a label and action" to
            (
                { buildPresentation { section(header = { button(HeaderItemId("open")) { icon(literal("mdi:open")) } }) {} } } to
                    "Header button label is required."
            ),
        "a header button without an action" to (
            {
                buildPresentation {
                    section(header = {
                        button(HeaderItemId("open")) {
                            icon(literal("mdi:open"))
                            label(literal("Open"))
                        }
                    }) {}
                }
            } to "Header button action is required."
        ),
        "two anchors with one id" to
            (
                {
                    buildPresentation {
                        anchors({
                            point("a") {}
                            point("a") {}
                        }) {}
                    }
                } to "Anchor ids must be unique within one layout."
            ),
        "an anchor with a blank id" to ({ buildPresentation { anchors({ point(" ") {} }) {} } } to "Anchor id must not be blank."),
        "an anchor in a blank group" to
            ({ buildPresentation { anchors({ point("a") { groups(" ") } }) {} } } to "Anchor group ids must not be blank."),
        "a connection without a source" to
            ({ buildPresentation { connectionLayer({ connection {} }) {} } } to "Connection source anchor is required."),
        "a connection bundle without a source" to
            ({ buildPresentation { connectionLayer({ bundle {} }) {} } } to "Connection bundle source anchor is required."),
        "a collection projection without a source id" to
            (
                { CollectionProjectionSpec(" ", subjectId.namedTemplate(), ScalarKind.TEXT.template, listOf(titleField)) } to
                    "Collection source id must not be blank."
            ),
        "a collection projection without fields" to
            (
                { CollectionProjectionSpec("rows", subjectId.namedTemplate(), ScalarKind.TEXT.template, emptyList()) } to
                    "Collection projection must declare at least one row field."
            ),
        "a collection projection with one row field twice" to
            (
                { CollectionProjectionSpec("rows", subjectId.namedTemplate(), ScalarKind.TEXT.template, listOf(titleField, titleField)) } to
                    "Collection projection row fields must be unique."
            ),
        "a collection projection reading a path of another type" to
            (
                {
                    collectionProjection<com.typewritermc.library.Book, String, com.typewritermc.library.BookExpressions>(
                        "rows",
                        com.typewritermc.library.TagDefinition.id
                            .namedTemplate(),
                        ScalarKind.TEXT.template,
                        com.typewritermc.library.BookExpressionsFactory,
                    ) { content(com.typewritermc.library.BookFields.title) }
                } to
                    "Collection projection path owner ${com.typewritermc.library.BookDefinition.id} does not match ${com.typewritermc.library.TagDefinition.id}."
            ),
    ).forEach { (case, rejection) ->
        test("$case is refused") {
            shouldThrow<IllegalArgumentException> { rejection.first() }.message shouldBe rejection.second
        }
    }

    buildMap<Pair<String, String>, SearchSources.() -> SearchProviderSpec<String>> {
        put("a search ranking with a weight of zero" to "Search ranking weight must be positive.") {
            staticValues(values).rank { field(row, weight = 0) }
        }
        put("a search ranking without fields" to "Search ranking must declare at least one field.") { staticValues(values).rank {} }
        put("merging no search providers" to "Merged search providers must contain at least one child.") { merge() }
        put("merging search providers of different row types" to "Merged search providers must yield rows of one type.") {
            @Suppress("UNCHECKED_CAST")
            merge(
                staticValues(values),
                httpJson<Int> {
                    uri(literal("https://example.com"))
                    result("items", integerScalar(IntegerWidth.SIGNED_THIRTY_TWO).template)
                } as SearchProviderSpec<String>,
            )
        }
        put("an HTTP search without a URI" to "HTTP search must declare a URI.") { httpJson { result("items", ScalarKind.TEXT.template) } }
        put("an HTTP search without a result" to "HTTP search must declare a result path.") {
            httpJson { uri(literal("https://example.com")) }
        }
        put("an HTTP search with a zero timeout" to "HTTP search timeout must be positive.") {
            httpJson { timeout(kotlin.time.Duration.ZERO) }
        }
        put("an HTTP search parameter with a blank name" to "HTTP search parameter name must not be blank.") {
            httpJson { parameter(" ", query) }
        }
    }.forEach { (case, search) ->
        test("${case.first} is refused") {
            shouldThrow<IllegalArgumentException> {
                buildPresentation(subject, PresentationRole.INSPECTOR) {
                    val title: PresentedField<String, TextControl> = field("title", TextControl::class)
                    title {
                        searchInput<String> {
                            provider(search(sources))
                            result {
                                key(row)
                                selectedValue(row)
                                presentation { text(row) }
                            }
                        }
                    }
                }
            }.message shouldBe case.second
        }
    }
}
