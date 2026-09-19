package com.typewritermc.pages

import com.typewritermc.library.PageKind
import com.typewritermc.library.PageKindRef
import com.typewritermc.types.Color
import com.typewritermc.types.Icon
import com.typewritermc.types.ResolvedTypeRef
import com.typewritermc.types.TypeId
import com.typewritermc.types.TypePrototypeRegistry
import kotlinx.serialization.Serializable
import kotlin.reflect.KClass

/**
 * Describes editor roles using structural type references that can cross the process boundary.
 *
 * This is the catalog form of [PageEditorDefinition]; consumers need no Kotlin class loading to render the editor
 * choices.
 */
@Serializable
sealed interface ResolvedPageEditorDefinition {
    @Serializable
    data class Graph(
        val direction: GraphDirection,
        val nodes: List<ResolvedTypeRef>,
    ) : ResolvedPageEditorDefinition

    @Serializable
    data class Timeline(
        val tracks: List<ResolvedTypeRef>,
        val segments: List<ResolvedTypeRef>,
        val keyframes: List<ResolvedTypeRef>,
    ) : ResolvedPageEditorDefinition
}

/**
 * Publishes a page kind revision with validated visual values and resolved editor roles.
 *
 * The descriptor is catalog metadata; it contains no authored page instances or runtime resources.
 */
@Serializable
data class PageDescriptor(
    val kind: PageKindRef,
    val name: String,
    val description: String?,
    val icon: Icon,
    val color: Color,
    val editor: ResolvedPageEditorDefinition,
    val authoringRules: List<PageAuthoringRuleRef> = emptyList(),
) {
    init {
        require(name.isNotBlank()) { "Page names must not be blank." }
    }
}

/**
 * Generated bridge from a page declaration to runtime catalog assembly.
 *
 * Provenance locates invalid specifications. [specification] executes authored code, so assembly catches its
 * failures and excludes invalid pages with diagnostics.
 */
interface PageProvider {
    val kind: PageKindRef
    val namespace: String
    val sourcePart: String
    val declarationName: String
    val marker: KClass<out PageKind>

    fun specification(): PageSpec
}

/**
 * Explains why a page declaration was omitted from the catalog.
 *
 * Provenance fields are populated when the failure is tied to a provider. A duplicate diagnostic retains the
 * conflicting kind so callers can explain why all declarations for that identity were excluded.
 */
data class PageDiagnostic(
    val code: String,
    val message: String,
    val namespace: String? = null,
    val sourcePart: String? = null,
    val declarationName: String? = null,
    val kind: PageKindRef? = null,
)

/**
 * Stores accepted page definitions alongside diagnostics for rejected declarations.
 *
 * Exact kind references must be unique. [definition] returns null for absent revisions rather than selecting a
 * newer or older schema.
 */
data class PageCatalog(
    val entries: List<PageCatalogEntry>,
    val diagnostics: List<PageDiagnostic>,
    private val authoringRules: Map<PageKindRef, List<PageAuthoringRule>> = emptyMap(),
) {
    init {
        require(entries.map { it.descriptor.kind }.distinct().size == entries.size) {
            "Page catalog kind references must be unique."
        }
    }

    val definitions: List<PageDescriptor>
        get() = entries.map(PageCatalogEntry::descriptor)

    /**
     * Finds the descriptor for one exact page kind revision.
     *
     * Returns null for an absent identity or revision. It never substitutes another revision.
     */
    fun definition(kind: PageKindRef): PageDescriptor? = entries.singleOrNull { it.descriptor.kind == kind }?.descriptor

    /** Returns executable rules for one exact page kind revision. */
    fun authoringRules(kind: PageKindRef): List<PageAuthoringRule> = authoringRules[kind].orEmpty()
}

/**
 * Associates an accepted page descriptor with the artifact and source part that declared it.
 *
 * Provenance is retained for catalog consumers even though descriptors are sorted independently of origin.
 */
@Serializable
data class PageCatalogEntry(
    val originArtifactId: String,
    val sourcePart: String,
    val descriptor: PageDescriptor,
)

/**
 * Compiles page providers into deterministic editor metadata.
 *
 * Invalid specifications become diagnostics. All declarations sharing a duplicate kind identity are excluded,
 * including different revisions. Successful entries are sorted by display name; unresolved role classes fall back
 * to qualified type identities at revision one.
 */
object PageCatalogAssembler {
    /**
     * Resolves provider specifications into the catalog consumed by editor clients.
     *
     * Providers are evaluated in stable provenance order. Invalid providers become diagnostics, and duplicate
     * kind identities remove every conflicting entry rather than choosing an arbitrary winner.
     */
    fun assemble(
        providers: Collection<PageProvider>,
        prototypes: TypePrototypeRegistry,
    ): PageCatalog {
        val diagnostics = mutableListOf<PageDiagnostic>()
        val compiled =
            providers
                .sortedWith(compareBy(PageProvider::namespace, PageProvider::sourcePart, PageProvider::declarationName))
                .mapNotNull { provider -> compile(provider, prototypes, diagnostics) }
        val duplicates = compiled.groupBy { it.entry.descriptor.kind.id }.filterValues { it.size > 1 }
        duplicates.forEach { (id, entries) ->
            entries.forEach { entry ->
                diagnostics +=
                    PageDiagnostic(
                        "duplicate_id",
                        "Page kind id $id is declared more than once.",
                        kind = entry.entry.descriptor.kind,
                    )
            }
        }
        val accepted = compiled.filterNot { it.entry.descriptor.kind.id in duplicates }
        return PageCatalog(
            entries = accepted.map(CompiledPage::entry).sortedBy { it.descriptor.name },
            diagnostics = diagnostics,
            authoringRules = accepted.associate { it.entry.descriptor.kind to it.authoringRules },
        )
    }

    private fun compile(
        provider: PageProvider,
        prototypes: TypePrototypeRegistry,
        diagnostics: MutableList<PageDiagnostic>,
    ): CompiledPage? =
        runCatching {
            val specification = provider.specification()
            CompiledPage(
                entry =
                    PageCatalogEntry(
                        originArtifactId = provider.namespace,
                        sourcePart = provider.sourcePart,
                        descriptor =
                            PageDescriptor(
                                kind = provider.kind,
                                name = specification.name ?: provider.declarationName.derivedPageName(),
                                description = specification.description,
                                icon = Icon.parse(specification.icon),
                                color = Color.parseRgb(specification.color),
                                editor = specification.editor.resolve(prototypes),
                                authoringRules = specification.authoringRules.map(PageAuthoringRule::reference),
                            ),
                    ),
                authoringRules = specification.authoringRules,
            )
        }.getOrElse { failure ->
            diagnostics +=
                PageDiagnostic(
                    code = "invalid_page",
                    message = failure.message ?: "Page compilation failed.",
                    namespace = provider.namespace,
                    sourcePart = provider.sourcePart,
                    declarationName = provider.declarationName,
                    kind = provider.kind,
                )
            null
        }
}

private data class CompiledPage(
    val entry: PageCatalogEntry,
    val authoringRules: List<PageAuthoringRule>,
)

private fun PageEditorDefinition.resolve(prototypes: TypePrototypeRegistry): ResolvedPageEditorDefinition =
    when (this) {
        is PageEditorDefinition.Graph -> {
            ResolvedPageEditorDefinition.Graph(direction, nodes.map { it.resolve(prototypes) })
        }

        is PageEditorDefinition.Timeline -> {
            ResolvedPageEditorDefinition.Timeline(
                tracks = tracks.map { it.resolve(prototypes) },
                segments = segments.map { it.resolve(prototypes) },
                keyframes = keyframes.map { it.resolve(prototypes) },
            )
        }
    }

private fun KClass<*>.resolve(prototypes: TypePrototypeRegistry): ResolvedTypeRef {
    val prototype = runCatching { prototypes.require(this) }.getOrNull()
    if (prototype != null) return prototype.type
    val qualifiedName = requireNotNull(qualifiedName) { "Page role types must have a qualified name." }
    val packageName = qualifiedName.substringBeforeLast('.', "")
    val simpleName = qualifiedName.removePrefix("$packageName.")
    return ResolvedTypeRef(TypeId.Qualified(packageName, simpleName), revision = 1)
}

private fun String.derivedPageName(): String {
    val base = removeSuffix("Page").ifEmpty { this }
    return base
        .replace(Regex("([a-z0-9])([A-Z])"), "$1 $2")
        .replaceFirstChar(Char::uppercase)
}
