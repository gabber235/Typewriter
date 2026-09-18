package com.typewritermc.realm.repository.search

import com.typewritermc.elements.ElementSearchDefinition
import com.typewritermc.elements.ElementSearchMode
import com.typewritermc.elements.ElementSearchPolicy
import com.typewritermc.elements.ElementSearchPropertyOverride
import com.typewritermc.elements.ElementValuePath
import com.typewritermc.elements.ElementValuePathSegment
import com.typewritermc.elements.StoredElement
import com.typewritermc.elements.elementName
import com.typewritermc.types.BuiltinTypeId
import com.typewritermc.types.DataValue
import com.typewritermc.types.NominalTypeKind
import com.typewritermc.types.ResolvedTypeRef
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.TypeDefinition
import com.typewritermc.types.TypeExpression
import com.typewritermc.types.TypeGraph
import com.typewritermc.types.TypeId
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import java.security.MessageDigest

internal data class ElementSearchCatalogEntry(
    val graph: TypeGraph,
    val definition: ElementSearchDefinition?,
    val displayName: String,
)

internal data class ElementSearchProjection(
    val element: StoredElement,
    val name: String,
    val policyRevision: String,
    val summary: List<SearchFragment>,
    val body: List<SearchFragment>,
    val keyword: List<SearchFragment>,
)

internal data class SearchFragment(
    val text: String,
    val path: ElementValuePath,
)

internal sealed interface ElementSearchProjectionResult {
    data class Projected(
        val projection: ElementSearchProjection,
    ) : ElementSearchProjectionResult

    data class Unavailable(
        val reason: String,
    ) : ElementSearchProjectionResult
}

/**
 * Projects typed element values without stringifying structural identities or unrelated primitive values.
 *
 * The graph and value are walked together. Any catalog or shape mismatch rejects the payload projection so stale
 * content cannot appear under an incorrect path. The element name remains searchable through its canonical index.
 */
internal class ElementSearchProjector {
    fun project(
        element: StoredElement,
        catalog: ElementSearchCatalogEntry?,
    ): ElementSearchProjectionResult {
        val definition =
            catalog?.definition
                ?: return ElementSearchProjectionResult.Unavailable("element-search-definition-unavailable")
        val root =
            catalog.graph.root as? TypeExpression.Named
                ?: return ElementSearchProjectionResult.Unavailable("element-search-root-invalid")
        if (root.reference.id != TypeId.Declared(element.elementType.value)) {
            return ElementSearchProjectionResult.Unavailable("element-search-type-mismatch")
        }
        if (root.reference.revision != element.schemaRevision) {
            return ElementSearchProjectionResult.Unavailable("element-search-schema-revision-mismatch")
        }
        if (definition.policy != ElementSearchPolicy.ORDINARY_TEXT) {
            return ElementSearchProjectionResult.Unavailable("element-search-policy-unsupported")
        }

        val fragments = mutableListOf<ModeFragment>()
        val traversal = ProjectionTraversal(catalog.graph, definition)
        val failure =
            runCatching {
                traversal.visit(catalog.graph.root, element.value.valueWithSlots, ElementValuePath(), null, fragments)
            }.exceptionOrNull()
        if (failure != null) {
            return ElementSearchProjectionResult.Unavailable("element-search-value-shape-mismatch")
        }
        return ElementSearchProjectionResult.Projected(
            ElementSearchProjection(
                element = element,
                name = element.value.valueWithSlots.elementName(),
                policyRevision = elementSearchPolicyRevision(definition),
                summary = fragments.filterMode(ElementSearchMode.SUMMARY),
                body = fragments.filterMode(ElementSearchMode.BODY),
                keyword = fragments.filterMode(ElementSearchMode.KEYWORD),
            ),
        )
    }
}

private class ProjectionTraversal(
    graph: TypeGraph,
    definition: ElementSearchDefinition,
) {
    private val definitions = (StandardTypes.definitions + graph.definitions).associateBy { it.id.withoutArguments() }
    private val overrides = definition.propertyOverrides.associateBy { it.ownerType.withoutArguments() to it.field }

    fun visit(
        expression: TypeExpression,
        value: DataValue,
        path: ElementValuePath,
        explicitMode: ElementSearchMode?,
        fragments: MutableList<ModeFragment>,
        parameters: Map<String, TypeExpression> = emptyMap(),
    ) {
        if (explicitMode == ElementSearchMode.NONE) return
        when (expression) {
            TypeExpression.Any,
            TypeExpression.Unit,
            TypeExpression.Boolean,
            is TypeExpression.Bytes,
            is TypeExpression.Decimal,
            is TypeExpression.Duration,
            is TypeExpression.Float,
            is TypeExpression.Integer,
            is TypeExpression.Reference,
            is TypeExpression.Timestamp,
            -> {
                return
            }

            is TypeExpression.StringType -> {
                val text = (value as DataValue.StringValue).value.trim()
                if (text.isEmpty()) return
                val mode = explicitMode ?: if (expression.allowedValues.isEmpty()) ElementSearchMode.BODY else ElementSearchMode.KEYWORD
                fragments += ModeFragment(mode, SearchFragment(text, path))
            }

            is TypeExpression.Enumeration -> {
                val mode = explicitMode ?: ElementSearchMode.KEYWORD
                visit(expression.valueType, value, path, mode, fragments, parameters)
            }

            is TypeExpression.ListType -> {
                val values = (value as DataValue.ListValue).values
                values.forEachIndexed { index, item ->
                    visit(
                        expression.element,
                        item,
                        path.append(ElementValuePathSegment.Index(index)),
                        explicitMode,
                        fragments,
                        parameters,
                    )
                }
            }

            is TypeExpression.MapType -> {
                val entries = (value as DataValue.MapValue).entries
                entries.forEach { entry ->
                    visit(
                        expression.value,
                        entry.value,
                        path.append(ElementValuePathSegment.MapKey(entry.key)),
                        explicitMode,
                        fragments,
                        parameters,
                    )
                }
            }

            is TypeExpression.Record -> {
                visitRecord(expression, value as DataValue.Record, path, explicitMode, fragments, parameters, null)
            }

            is TypeExpression.Parameter -> {
                visit(parameters[expression.name] ?: TypeExpression.Any, value, path, explicitMode, fragments, parameters)
            }

            is TypeExpression.Named -> {
                visitNamed(expression.reference, value, path, explicitMode, fragments, parameters)
            }
        }
    }

    private fun visitNamed(
        reference: ResolvedTypeRef,
        value: DataValue,
        path: ElementValuePath,
        explicitMode: ElementSearchMode?,
        fragments: MutableList<ModeFragment>,
        parameters: Map<String, TypeExpression>,
    ) {
        val arguments = reference.arguments.map { materialize(it, parameters) }
        val resolved = reference.withArguments(arguments)
        val definition = definitions[resolved.withoutArguments()] ?: error("Missing type definition")
        if (definition.kind != NominalTypeKind.CONCRETE) {
            val polymorphic = value as DataValue.Polymorphic
            visitNamed(polymorphic.concreteType, polymorphic.value, path, explicitMode, fragments, parameters)
            return
        }
        val bindings =
            definition.parameters
                .mapIndexed { index, parameter ->
                    parameter.name to arguments.getOrElse(index) { TypeExpression.Any }
                }.toMap()
        val representation = materialize(definition.representation, bindings)
        val isLogicalString = representation is TypeExpression.StringType
        if (isLogicalString && explicitMode == null) return
        if (representation is TypeExpression.Record) {
            visitRecord(representation, value as DataValue.Record, path, explicitMode, fragments, bindings, definition)
            return
        }
        visit(representation, value, path, explicitMode, fragments, bindings)
    }

    private fun visitRecord(
        expression: TypeExpression.Record,
        value: DataValue.Record,
        path: ElementValuePath,
        explicitMode: ElementSearchMode?,
        fragments: MutableList<ModeFragment>,
        parameters: Map<String, TypeExpression>,
        owner: TypeDefinition?,
    ) {
        expression.fields.forEach { field ->
            val fieldValue = value.fields[field.name] ?: return@forEach
            val mode = owner?.let { overrides[it.id.withoutArguments() to field.name]?.mode } ?: explicitMode
            visit(
                field.type,
                fieldValue,
                path.append(ElementValuePathSegment.Field(field.name)),
                mode,
                fragments,
                parameters,
            )
        }
    }

    private fun materialize(
        expression: TypeExpression,
        parameters: Map<String, TypeExpression>,
    ): TypeExpression =
        when (expression) {
            is TypeExpression.Parameter -> {
                parameters[expression.name]?.let { materialize(it, parameters) } ?: expression
            }

            is TypeExpression.ListType -> {
                expression.copy(element = materialize(expression.element, parameters))
            }

            is TypeExpression.MapType -> {
                expression.copy(
                    key = materialize(expression.key, parameters),
                    value = materialize(expression.value, parameters),
                )
            }

            is TypeExpression.Record -> {
                expression.copy(
                    fields = expression.fields.map { it.copy(type = materialize(it.type, parameters)) },
                )
            }

            is TypeExpression.Named -> {
                expression.copy(
                    reference = expression.reference.withArguments(expression.reference.arguments.map { materialize(it, parameters) }),
                )
            }

            is TypeExpression.Reference -> {
                expression.copy(
                    target = expression.target.withArguments(expression.target.arguments.map { materialize(it, parameters) }),
                )
            }

            else -> {
                expression
            }
        }
}

private data class ModeFragment(
    val mode: ElementSearchMode,
    val fragment: SearchFragment,
)

private fun List<ModeFragment>.filterMode(mode: ElementSearchMode): List<SearchFragment> =
    filter { it.mode == mode }.map(ModeFragment::fragment)

private fun ElementValuePath.append(segment: ElementValuePathSegment): ElementValuePath = copy(segments = segments + segment)

private fun ResolvedTypeRef.withoutArguments(): ResolvedTypeRef = withArguments(emptyList())

internal fun elementSearchPolicyRevision(definition: ElementSearchDefinition): String =
    canonicalJson.encodeToString(ElementSearchDefinition.serializer(), definition).sha256()

private fun String.sha256(): String =
    MessageDigest.getInstance("SHA-256").digest(toByteArray()).joinToString("") {
        "%02x".format(it.toInt() and 0xff)
    }

private val canonicalJson = Json { encodeDefaults = true }
