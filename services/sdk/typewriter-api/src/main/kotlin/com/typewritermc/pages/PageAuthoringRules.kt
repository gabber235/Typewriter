package com.typewritermc.pages

import com.typewritermc.elements.ElementInstanceId
import com.typewritermc.library.PageDocument
import com.typewritermc.library.PageId
import com.typewritermc.types.DataValue
import com.typewritermc.types.RecordIdKey
import com.typewritermc.types.ResolvedTypeRef
import com.typewritermc.types.ResourceId
import kotlinx.serialization.Serializable

/** Identifies one executable page authoring rule across discovery and editor transport. */
@JvmInline
@Serializable
value class PageAuthoringRuleId(
    val value: String,
) {
    init {
        require(value.isNotBlank()) { "Page authoring rule ids must not be blank." }
        require(':' in value) { "Page authoring rule ids must be namespaced." }
    }
}

/** Publishes a rule identity and opaque typed configuration without closing the rule vocabulary. */
@Serializable
data class PageAuthoringRuleRef(
    val id: PageAuthoringRuleId,
    val revision: Int,
    val configuration: PageAuthoringRuleConfiguration? = null,
) {
    init {
        require(revision > 0) { "Page authoring rule revisions must be positive." }
    }
}

/** Carries extension defined rule configuration with its exact portable type. */
@Serializable
data class PageAuthoringRuleConfiguration(
    val type: ResolvedTypeRef,
    val value: DataValue,
)

/** Gives a rule the transaction consistent documents before and after a proposed mutation. */
data class PageAuthoringRuleContext(
    val before: PageDocument?,
    val after: PageDocument,
    val documentsBefore: Map<PageId, PageDocument>,
    val documentsAfter: Map<PageId, PageDocument>,
)

/** Reports a deterministic page rule rejection at document or element scope. */
data class PageAuthoringRuleViolation(
    val code: String,
    val message: String,
    val element: ElementInstanceId? = null,
) {
    init {
        require(code.isNotBlank()) { "Page authoring rule violation codes must not be blank." }
        require(message.isNotBlank()) { "Page authoring rule violation messages must not be blank." }
    }
}

/** Executes one extension supplied authoring invariant inside Realm. */
interface PageAuthoringRule {
    val reference: PageAuthoringRuleRef

    fun validate(context: PageAuthoringRuleContext): List<PageAuthoringRuleViolation>
}

/** Reusable page authoring rules supplied by the core engine. */
object CommonPageAuthoringRules {
    val noSelfReferences: PageAuthoringRule = NoSelfReferences
    val acyclicElementReferences: PageAuthoringRule = AcyclicElementReferences

    private object NoSelfReferences : PageAuthoringRule {
        override val reference =
            PageAuthoringRuleRef(PageAuthoringRuleId("typewriter:page-rule/no-self-references"), revision = 1)

        override fun validate(context: PageAuthoringRuleContext): List<PageAuthoringRuleViolation> =
            context.after.references.mapNotNull { reference ->
                if (reference.target != reference.source.resourceId()) return@mapNotNull null
                PageAuthoringRuleViolation(
                    code = "page-rule-self-reference",
                    message = "Element ${reference.source.value} cannot reference itself.",
                    element = reference.source,
                )
            }
    }

    private object AcyclicElementReferences : PageAuthoringRule {
        override val reference =
            PageAuthoringRuleRef(PageAuthoringRuleId("typewriter:page-rule/acyclic-element-references"), revision = 1)

        override fun validate(context: PageAuthoringRuleContext): List<PageAuthoringRuleViolation> {
            val localElements = context.after.elements.mapTo(linkedSetOf()) { it.id }
            val outgoing =
                context.after.references
                    .mapNotNull { reference ->
                        val target = reference.target.elementInstanceId() ?: return@mapNotNull null
                        if (reference.source !in localElements || target !in localElements) return@mapNotNull null
                        reference.source to target
                    }.groupBy({ it.first }, { it.second })
            val visited = mutableSetOf<ElementInstanceId>()
            val active = linkedSetOf<ElementInstanceId>()

            fun visit(element: ElementInstanceId): ElementInstanceId? {
                if (element in active) return element
                if (!visited.add(element)) return null
                active += element
                outgoing[element].orEmpty().forEach { target ->
                    visit(target)?.let { return it }
                }
                active -= element
                return null
            }

            val cycle = localElements.firstNotNullOfOrNull(::visit) ?: return emptyList()
            return listOf(
                PageAuthoringRuleViolation(
                    code = "page-rule-reference-cycle",
                    message = "Element references must form an acyclic graph.",
                    element = cycle,
                ),
            )
        }
    }
}

private fun ElementInstanceId.resourceId(): ResourceId = ResourceId("element", value)

private fun ResourceId.elementInstanceId(): ElementInstanceId? {
    if (table != "element") return null
    val stringKey = key as? RecordIdKey.String ?: return null
    return ElementInstanceId(stringKey.value)
}
