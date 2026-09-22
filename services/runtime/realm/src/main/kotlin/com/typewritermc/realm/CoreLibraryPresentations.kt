package com.typewritermc.realm

import com.typewritermc.authoring.AuthoringSearchContext
import com.typewritermc.authoring.AuthoringSearchMatch
import com.typewritermc.authoring.ResourceIdentity
import com.typewritermc.authoring.ResourceTypeDescriptor
import com.typewritermc.elements.Element
import com.typewritermc.elements.Entry
import com.typewritermc.library.Book
import com.typewritermc.library.Page
import com.typewritermc.library.PageKind
import com.typewritermc.library.TAG_COLLECTION_SOURCE_ID
import com.typewritermc.library.TAG_INHERITS_RELATION_ID
import com.typewritermc.library.Tag
import com.typewritermc.library.TagCollectionRow
import com.typewritermc.presentation.PresentationBuildContext
import com.typewritermc.presentation.PresentationBuilder
import com.typewritermc.presentation.PresentationProvider
import com.typewritermc.presentation.PresentationSpec
import com.typewritermc.presentation.PresentationTextRun
import com.typewritermc.presentation.PresentationValue
import com.typewritermc.presentation.asStringExpression
import com.typewritermc.presentation.collectionGraph
import com.typewritermc.presentation.collectionRelation
import com.typewritermc.presentation.presentationCollection
import com.typewritermc.presentation.presentationExpression
import com.typewritermc.presentation.rolePresentation
import com.typewritermc.presentation.substring
import com.typewritermc.presentation.surface
import com.typewritermc.realm.routes.toWirePath
import com.typewritermc.types.Color
import com.typewritermc.types.DataPath
import com.typewritermc.types.DataValue
import com.typewritermc.types.Icon
import com.typewritermc.types.PresentationRole
import com.typewritermc.types.ResolvedTypeRef
import com.typewritermc.types.TypeExpression
import com.typewritermc.types.TypePrototypeRegistry
import com.typewritermc.types.skir.SkirDataValueCodec
import com.typewritermc.types.skir.SkirTypeCodec
import com.typewritermc.types.skir.getOrThrow
import skirout.editor.v1.authoring.CollectionProjectionDefinition
import skirout.editor.v1.authoring.CollectionProjectionField
import skirout.editor.v1.authoring.CollectionProjectionSource
import skirout.editor.v1.authoring.ResourceDefinitionId
import skirout.editor.v1.authoring.ResourceFilter
import kotlin.reflect.KProperty1

internal fun coreLibraryPresentationProviders(): List<PresentationProvider> =
    listOf(
        coreProvider("color.default", default = true, specification = ::colorDefault),
        coreProvider("icon.iconify.default", default = true, specification = ::iconifyDefault),
        coreProvider("icon.svg.default", default = true, specification = ::svgDefault),
        coreProvider(
            "element.reference",
            roles = setOf(PresentationRole.REFERENCE_SUMMARY, PresentationRole.REFERENCE_OPTION),
            specification = { elementSubjectRole(it, "element.reference") },
        ),
        coreProvider(
            "element.catalog",
            roles = setOf(PresentationRole.CATALOG_OPTION),
            specification = { elementCatalogRole(it, "element.catalog") },
        ),
        coreProvider(
            "element.authoring",
            roles = setOf(PresentationRole.AUTHORING_RESULT),
            specification = { elementAuthoringRole(it, "element.authoring") },
        ),
        coreProvider(
            "element.inspector",
            roles = setOf(PresentationRole.INSPECTOR_HEADER),
            specification = { elementSubjectRole(it, "element.inspector") },
        ),
        coreProvider(
            "entry.graph",
            roles = setOf(PresentationRole.GRAPH_NODE),
            specification = { entryGraphRole(it, "entry.graph") },
        ),
        coreProvider("book.default", default = true, specification = ::bookDefault),
        coreProvider(
            "book.reference.summary",
            roles = setOf(PresentationRole.REFERENCE_SUMMARY),
            specification = { bookSubjectRole(it, "book.reference.summary") },
        ),
        coreProvider(
            "book.reference.option",
            roles = setOf(PresentationRole.REFERENCE_OPTION),
            specification = { bookSubjectRole(it, "book.reference.option") },
        ),
        coreProvider(
            "book.authoring.result",
            roles = setOf(PresentationRole.AUTHORING_RESULT),
            specification = { bookAuthoringRole(it, "book.authoring.result") },
        ),
        coreProvider(
            "book.inspector.header",
            roles = setOf(PresentationRole.INSPECTOR_HEADER),
            specification = { bookSubjectRole(it, "book.inspector.header") },
        ),
        coreProvider("tag.default", default = true, specification = ::tagDefault),
        coreProvider(
            "tag.reference.summary",
            roles = setOf(PresentationRole.REFERENCE_SUMMARY),
            specification = { tagSubjectRole(it, "tag.reference.summary") },
        ),
        coreProvider(
            "tag.reference.option",
            roles = setOf(PresentationRole.REFERENCE_OPTION),
            specification = { tagSubjectRole(it, "tag.reference.option") },
        ),
        coreProvider(
            "tag.authoring.result",
            roles = setOf(PresentationRole.AUTHORING_RESULT),
            specification = { tagAuthoringRole(it, "tag.authoring.result") },
        ),
        coreProvider(
            "tag.graph.node",
            roles = setOf(PresentationRole.GRAPH_NODE),
            specification = { tagSubjectRole(it, "tag.graph.node") },
        ),
        coreProvider(
            "tag.inspector.header",
            roles = setOf(PresentationRole.INSPECTOR_HEADER),
            specification = { tagSubjectRole(it, "tag.inspector.header") },
        ),
        coreProvider("page.default", default = true, specification = ::pageDefault),
        coreProvider(
            "page.reference.summary",
            roles = setOf(PresentationRole.REFERENCE_SUMMARY),
            specification = { pageSubjectRole(it, "page.reference.summary") },
        ),
        coreProvider(
            "page.reference.option",
            roles = setOf(PresentationRole.REFERENCE_OPTION),
            specification = { pageSubjectRole(it, "page.reference.option") },
        ),
        coreProvider(
            "page.catalog.option",
            roles = setOf(PresentationRole.CATALOG_OPTION),
            specification = { pageCatalogRole(it, "page.catalog.option") },
        ),
        coreProvider(
            "page.authoring.result",
            roles = setOf(PresentationRole.AUTHORING_RESULT),
            specification = { pageAuthoringRole(it, "page.authoring.result") },
        ),
        coreProvider(
            "page.tile",
            roles = setOf(PresentationRole.PAGE_TILE),
            specification = { pageSubjectRole(it, "page.tile") },
        ),
        coreProvider(
            "page.inspector.header",
            roles = setOf(PresentationRole.INSPECTOR_HEADER),
            specification = { pageSubjectRole(it, "page.inspector.header") },
        ),
    )

internal fun coreLibraryCollectionProjections(prototypes: TypePrototypeRegistry): List<CollectionProjectionDefinition> {
    val tag = prototypes.require(Tag::class)
    val row = prototypes.require(TagCollectionRow::class)

    fun serializedPath(
        prototype: com.typewritermc.types.TypePrototype<*>,
        property: KProperty1<*, *>,
    ): DataPath =
        DataPath.field(
            requireNotNull(prototype.serializedFieldNames[property.name]) {
                "Serialized field metadata is unavailable for ${prototype.type}.${property.name}."
            },
        )

    fun field(
        target: KProperty1<TagCollectionRow, *>,
        source: CollectionProjectionSource,
    ) = CollectionProjectionField(
        target = serializedPath(row, target).toWirePath(),
        source = source,
    )

    fun content(
        target: KProperty1<TagCollectionRow, *>,
        source: KProperty1<Tag, *>,
    ) = field(
        target,
        CollectionProjectionSource.ContentWrapper(serializedPath(tag, source).toWirePath()),
    )

    return listOf(
        CollectionProjectionDefinition(
            sourceId = TAG_COLLECTION_SOURCE_ID,
            resources =
                ResourceFilter(
                    definitions = listOf(ResourceDefinitionId(value = CoreResourceDefinitionIds.TAG.value)),
                    assignableTo = SkirTypeCodec.encode(TypeExpression.Named(tag.type)).getOrThrow(),
                ),
            rowType = SkirTypeCodec.encode(row.type).getOrThrow(),
            fields =
                listOf(
                    field(TagCollectionRow::key, CollectionProjectionSource.RESOURCE_ID),
                    content(TagCollectionRow::name, Tag::name),
                    content(TagCollectionRow::color, Tag::color),
                    content(TagCollectionRow::parents, Tag::parents),
                    field(
                        TagCollectionRow::selectable,
                        CollectionProjectionSource.LiteralWrapper(
                            SkirDataValueCodec.encode(DataValue.Boolean(true)).getOrThrow(),
                        ),
                    ),
                ),
        ),
    )
}

private fun colorDefault(context: PresentationBuildContext): PresentationSpec<Color> =
    context(context) {
        rolePresentation<Color>("color.default") {
            colorInput(editableInput<Color>("value").value())
        }
    }

private fun iconifyDefault(context: PresentationBuildContext): PresentationSpec<Icon.Iconify> =
    context(context) {
        rolePresentation<Icon.Iconify>("icon.iconify.default") {
            val value = editableInput<Icon.Iconify>("value")
            textInput(value.field(Icon.Iconify::value))
        }
    }

private fun svgDefault(context: PresentationBuildContext): PresentationSpec<Icon.Svg> =
    context(context) {
        rolePresentation<Icon.Svg>("icon.svg.default") {
            val value = editableInput<Icon.Svg>("value")
            textInput(value.field(Icon.Svg::source), multiline = true)
        }
    }

private val tagInheritanceRelation =
    collectionRelation(TAG_INHERITS_RELATION_ID, TagCollectionRow::parents)

private val tagCollection =
    presentationCollection(
        sourceId = TAG_COLLECTION_SOURCE_ID,
        key = TagCollectionRow::key,
        selectability = TagCollectionRow::selectable,
        tagInheritanceRelation,
    )

private fun elementSubjectRole(
    context: PresentationBuildContext,
    name: String,
): PresentationSpec<Element> =
    context(context) {
        rolePresentation<Element>(name) {
            val content = input<Element>("content")
            val descriptor = input<ResourceTypeDescriptor>("descriptor")
            input<ResourceIdentity>("identity")
            subjectLayout(descriptor.field(ResourceTypeDescriptor::icon), content.field(Element::name).expression())
        }
    }

private fun elementCatalogRole(
    context: PresentationBuildContext,
    name: String,
): PresentationSpec<Element> =
    context(context) {
        rolePresentation<Element>(name) {
            val descriptor = input<ResourceTypeDescriptor>("descriptor")
            input<ResolvedTypeRef>("identity")
            subjectLayout(descriptor.field(ResourceTypeDescriptor::icon), descriptor.field(ResourceTypeDescriptor::name).expression())
        }
    }

private fun elementAuthoringRole(
    context: PresentationBuildContext,
    name: String,
): PresentationSpec<Element> =
    context(context) {
        rolePresentation<Element>(name) {
            val content = input<Element>("content")
            val descriptor = input<ResourceTypeDescriptor>("descriptor")
            input<ResourceIdentity>("identity")
            val searchContext = input<AuthoringSearchContext>("context")
            authoringSubjectLayout(descriptor.field(ResourceTypeDescriptor::icon), content.field(Element::name).expression(), searchContext)
        }
    }

private fun entryGraphRole(
    context: PresentationBuildContext,
    name: String,
): PresentationSpec<Entry> =
    context(context) {
        rolePresentation<Entry>(name) {
            val content = input<Entry>("content")
            val descriptor = input<ResourceTypeDescriptor>("descriptor")
            input<ResourceIdentity>("identity")
            adaptiveLeading(
                leading = { icon(descriptor.field(ResourceTypeDescriptor::icon)) },
                center = { text(content.field(Entry::name).expression()) },
            )
        }
    }

private fun bookDefault(context: PresentationBuildContext): PresentationSpec<Book> =
    context(context) {
        rolePresentation<Book>("book.default") {
            val content = editableInput<Book>("content")
            section("title", "Title") { defaultEditor(content.field(Book::title)) }
            section("icon", "Icon") { defaultEditor(content.field(Book::icon)) }
            section("color", "Color") { defaultEditor(content.field(Book::color)) }
            section("tags", "Direct Tags") { defaultEditor(content.field(Book::tags)) }
            section("pages", "Pages") { defaultEditor(content.field(Book::pages)) }
            section("effective-tags", "Effective Tags", initiallyExpanded = true) {
                collectionGraph(
                    collection = tagCollection,
                    roots = content.field(Book::tags),
                    relation = tagInheritanceRelation,
                    label = TagCollectionRow::name,
                    color = TagCollectionRow::color,
                )
            }
        }
    }

private fun tagDefault(context: PresentationBuildContext): PresentationSpec<Tag> =
    context(context) {
        rolePresentation<Tag>("tag.default") {
            val content = editableInput<Tag>("content")
            section("name", "Name") { defaultEditor(content.field(Tag::name)) }
            section("color", "Color") { defaultEditor(content.field(Tag::color)) }
            section("parents", "Direct Parents") { defaultEditor(content.field(Tag::parents)) }
            section("inheritance", "Inheritance", initiallyExpanded = true) {
                collectionGraph(
                    collection = tagCollection,
                    roots = content.field(Tag::parents),
                    relation = tagInheritanceRelation,
                    label = TagCollectionRow::name,
                    color = TagCollectionRow::color,
                )
            }
            section("placement", "Placement") { defaultEditor(content.field(Tag::placement)) }
        }
    }

private fun pageDefault(context: PresentationBuildContext): PresentationSpec<Page> =
    context(context) {
        rolePresentation<Page>("page.default") {
            val content = editableInput<Page>("content")
            section("book", "Book") { defaultEditor(content.field(Page::book)) }
            section("name", "Name") { defaultEditor(content.field(Page::name)) }
            section("kind", "Kind") { defaultEditor(content.field(Page::kind)) }
            section("chapter", "Chapter") { defaultEditor(content.field(Page::chapter)) }
            section("priority", "Priority") { defaultEditor(content.field(Page::priority)) }
            section("elements", "Elements") { defaultEditor(content.field(Page::elements)) }
        }
    }

private fun bookSubjectRole(
    context: PresentationBuildContext,
    name: String,
): PresentationSpec<Book> =
    context(context) {
        rolePresentation<Book>(name) {
            val content = input<Book>("content")
            input<ResourceTypeDescriptor>("descriptor")
            input<ResourceIdentity>("identity")
            surface(content.field(Book::color).expression()) {
                subjectLayout(content.field(Book::icon), content.field(Book::title).asStringExpression())
            }
        }
    }

private fun bookAuthoringRole(
    context: PresentationBuildContext,
    name: String,
): PresentationSpec<Book> =
    context(context) {
        rolePresentation<Book>(name) {
            val content = input<Book>("content")
            val descriptor = input<ResourceTypeDescriptor>("descriptor")
            input<ResourceIdentity>("identity")
            val searchContext = input<AuthoringSearchContext>("context")
            authoringSubjectLayout(
                descriptor.field(ResourceTypeDescriptor::icon),
                content.field(Book::title).asStringExpression(),
                searchContext,
            )
        }
    }

private fun tagSubjectRole(
    context: PresentationBuildContext,
    name: String,
): PresentationSpec<Tag> =
    context(context) {
        rolePresentation<Tag>(name) {
            val content = input<Tag>("content")
            val descriptor = input<ResourceTypeDescriptor>("descriptor")
            input<ResourceIdentity>("identity")
            surface(content.field(Tag::color).expression()) {
                subjectLayout(descriptor.field(ResourceTypeDescriptor::icon), content.field(Tag::name).asStringExpression())
            }
        }
    }

private fun tagAuthoringRole(
    context: PresentationBuildContext,
    name: String,
): PresentationSpec<Tag> =
    context(context) {
        rolePresentation<Tag>(name) {
            val content = input<Tag>("content")
            val descriptor = input<ResourceTypeDescriptor>("descriptor")
            input<ResourceIdentity>("identity")
            val searchContext = input<AuthoringSearchContext>("context")
            authoringSubjectLayout(
                descriptor.field(ResourceTypeDescriptor::icon),
                content.field(Tag::name).asStringExpression(),
                searchContext,
            )
        }
    }

private fun pageSubjectRole(
    context: PresentationBuildContext,
    name: String,
): PresentationSpec<Page> =
    context(context) {
        rolePresentation<Page>(name) {
            val content = input<Page>("content")
            val descriptor = input<ResourceTypeDescriptor>("descriptor")
            input<ResourceIdentity>("identity")
            subjectLayout(descriptor.field(ResourceTypeDescriptor::icon), content.field(Page::name).asStringExpression())
        }
    }

private fun pageCatalogRole(
    context: PresentationBuildContext,
    name: String,
): PresentationSpec<PageKind> =
    context(context) {
        rolePresentation<PageKind>(name) {
            val descriptor = input<ResourceTypeDescriptor>("descriptor")
            input<ResolvedTypeRef>("identity")
            subjectLayout(
                descriptor.field(ResourceTypeDescriptor::icon),
                descriptor.field(ResourceTypeDescriptor::name).expression(),
            )
        }
    }

private fun pageAuthoringRole(
    context: PresentationBuildContext,
    name: String,
): PresentationSpec<Page> =
    context(context) {
        rolePresentation<Page>(name) {
            val content = input<Page>("content")
            val descriptor = input<ResourceTypeDescriptor>("descriptor")
            input<ResourceIdentity>("identity")
            val searchContext = input<AuthoringSearchContext>("context")
            authoringSubjectLayout(
                descriptor.field(ResourceTypeDescriptor::icon),
                content.field(Page::name).asStringExpression(),
                searchContext,
            )
        }
    }

private fun <T : Any> PresentationBuilder<T>.subjectLayout(
    icon: PresentationValue<Icon>,
    title: com.typewritermc.presentation.PresentationExpression<String>,
) {
    adaptiveLeading(
        leading = { icon(icon) },
        center = { text(title) },
    )
}

private fun <T : Any> PresentationBuilder<T>.authoringSubjectLayout(
    icon: PresentationValue<Icon>,
    title: com.typewritermc.presentation.PresentationExpression<String>,
    context: com.typewritermc.presentation.PresentationInputRef<AuthoringSearchContext>,
) {
    val match = context.optionalField(AuthoringSearchContext::match)
    val text = match.field(AuthoringSearchMatch::text).orElse("")
    val start = match.field(AuthoringSearchMatch::start).orElse(0)
    val end = match.field(AuthoringSearchMatch::end).orElse(0)
    adaptiveLeading(
        leading = { icon(icon) },
        center = {
            text(title)
            richText(
                PresentationTextRun(text.substring(0.presentationExpression(), start)),
                PresentationTextRun(text.substring(start, end), fontWeight = 700.0),
                PresentationTextRun(text.substring(end)),
                maxLines = 1,
                ellipsis = true,
                secondary = true,
            )
        },
    )
}

private fun coreProvider(
    name: String,
    default: Boolean = false,
    roles: Set<PresentationRole> = emptySet(),
    specification: (PresentationBuildContext) -> PresentationSpec<*>,
): PresentationProvider =
    object : PresentationProvider {
        override val namespace = "typewriter.core"
        override val sourcePart = "realm"
        override val declarationName = name
        override val default = default
        override val priority = 0
        override val roles = roles

        override fun specification(context: PresentationBuildContext): PresentationSpec<*> = specification(context)
    }
