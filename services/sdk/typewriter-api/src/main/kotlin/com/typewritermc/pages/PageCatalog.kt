package com.typewritermc.pages

import com.typewritermc.library.Page
import com.typewritermc.types.Color
import com.typewritermc.types.Icon
import com.typewritermc.types.ResolvedTypeRef
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
    ) : ResolvedPageEditorDefinition

    @Serializable
    data object Timeline : ResolvedPageEditorDefinition
}

/**
 * Publishes a page kind revision with validated visual values and resolved editor roles.
 *
 * The descriptor is catalog metadata; it contains no authored page instances or runtime resources.
 */
@Serializable
data class PageDescriptor(
    val type: ResolvedTypeRef,
    val name: String,
    val description: String?,
    val icon: Icon,
    val color: Color,
    val editor: ResolvedPageEditorDefinition,
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
    val type: ResolvedTypeRef
    val namespace: String
    val sourcePart: String
    val declarationName: String
    val marker: KClass<out Page>

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
    val type: ResolvedTypeRef? = null,
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
) {
    init {
        require(entries.map { it.descriptor.type }.distinct().size == entries.size) {
            "Page catalog type references must be unique."
        }
    }

    val definitions: List<PageDescriptor>
        get() = entries.map(PageCatalogEntry::descriptor)

    /**
     * Finds the descriptor for one exact page kind revision.
     *
     * Returns null for an absent identity or revision. It never substitutes another revision.
     */
    fun definition(type: ResolvedTypeRef): PageDescriptor? = entries.singleOrNull { it.descriptor.type == type }?.descriptor

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
    val presentationTarget: ResolvedTypeRef = descriptor.type,
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
        val duplicates = compiled.groupBy { it.descriptor.type.id }.filterValues { it.size > 1 }
        duplicates.forEach { (id, entries) ->
            entries.forEach { entry ->
                diagnostics +=
                    PageDiagnostic(
                        "duplicate_id",
                        "Page type id $id is declared more than once.",
                        type = entry.descriptor.type,
                    )
            }
        }
        val accepted = compiled.filterNot { it.descriptor.type.id in duplicates }
        return PageCatalog(
            entries = accepted.sortedBy { it.descriptor.name },
            diagnostics = diagnostics,
        )
    }

    private fun compile(
        provider: PageProvider,
        prototypes: TypePrototypeRegistry,
        diagnostics: MutableList<PageDiagnostic>,
    ): PageCatalogEntry? =
        runCatching {
            val specification = provider.specification()
            require(prototypes.require(provider.marker).type == provider.type) {
                "Page provider type must match its concrete Page marker."
            }
            PageCatalogEntry(
                        originArtifactId = provider.namespace,
                        sourcePart = provider.sourcePart,
                        presentationTarget = provider.type,
                        descriptor =
                            PageDescriptor(
                                type = provider.type,
                                name = specification.name ?: provider.declarationName.derivedPageName(),
                                description = specification.description,
                                icon = Icon.parse(specification.icon),
                                color = Color.parseRgb(specification.color),
                                editor = specification.editor.resolve(),
                            ),
                    )
        }.getOrElse { failure ->
            diagnostics +=
                PageDiagnostic(
                    code = "invalid_page",
                    message = failure.message ?: "Page compilation failed.",
                    namespace = provider.namespace,
                    sourcePart = provider.sourcePart,
                    declarationName = provider.declarationName,
                    type = provider.type,
                )
            null
        }
}

private fun PageEditorDefinition.resolve(): ResolvedPageEditorDefinition =
    when (this) {
        is PageEditorDefinition.Graph -> {
            ResolvedPageEditorDefinition.Graph(direction)
        }

        is PageEditorDefinition.Timeline -> {
            ResolvedPageEditorDefinition.Timeline
        }
    }

private fun String.derivedPageName(): String {
    val base = removeSuffix("Page").ifEmpty { this }
    return base
        .replace(Regex("([a-z0-9])([A-Z])"), "$1 $2")
        .replaceFirstChar(Char::uppercase)
}
