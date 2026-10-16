package com.typewritermc.operations

import com.typewritermc.capability.CapabilityId
import com.typewritermc.capability.RealmCapabilityDescriptor
import com.typewritermc.expression.literal
import com.typewritermc.expression.orElse
import com.typewritermc.library.Book
import com.typewritermc.library.Page
import com.typewritermc.presentation.SearchCapability
import com.typewritermc.presentation.resource
import com.typewritermc.types.ResourceId
import com.typewritermc.types.ScalarKind
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.TypeId
import com.typewritermc.types.TypeUse
import com.typewritermc.types.text

@com.typewritermc.types.TypewriterType(id = "4e720b9034124ae2a4a63eedfb19218b")
data class OperationResourceOption(
    val id: ResourceId,
    val label: String,
)

/** Search callbacks share the invocation's validated operation working context. */
object OperationSearch {
    val compatibleBooks: SearchCapability<String, OperationResourceOption> = source("books")
    val compatiblePages: SearchCapability<String, OperationResourceOption> = source("pages")
    val linkTargets: SearchCapability<String, OperationResourceOption> = source("links")

    val descriptors: List<RealmCapabilityDescriptor.Search> =
        listOf(compatibleBooks, compatiblePages, linkTargets).map {
            RealmCapabilityDescriptor.Search(
                it.id,
                TypeUse.Scalar(ScalarKind.Text),
                OperationResourceOptionDefinition.use,
            )
        }

    fun descriptorsFor(operations: List<BoundResourceOperation>): List<RealmCapabilityDescriptor.Search> {
        val required =
            operations
                .mapNotNull { operation ->
                    when (operation.builtin) {
                        BuiltinResourceOperation.MoveToBook -> compatibleBooks.id
                        BuiltinResourceOperation.MoveToPage -> compatiblePages.id
                        BuiltinResourceOperation.LinkWith -> linkTargets.id
                        else -> null
                    }
                }.toSet()
        return descriptors.filter { it.id in required }
    }

    private fun source(name: String): SearchCapability<String, OperationResourceOption> =
        object : SearchCapability<String, OperationResourceOption> {
            override val id = CapabilityId("typewriter:operation.search.$name")
        }
}

object MoveToBookForm : MoveToBookInputPresentation {
    override fun MoveToBookInputPresentationScope.present() {
        destination {
            searchInput<OperationResourceOption> {
                provider(sources.realmCallback(OperationSearch.compatibleBooks, literal("")))
                result {
                    val option = OperationResourceOptionExpressionsFactory.create(row)
                    key(option.id.text)
                    selectedValue(option.id.text)
                    label(option.label.orElse(literal("Unnamed resource")))
                    presentation { text(option.label.orElse(literal("Unnamed resource"))) }
                }
            }
        }
    }
}

object MoveToPageForm : MoveToPageInputPresentation {
    override fun MoveToPageInputPresentationScope.present() {
        destination {
            searchInput<OperationResourceOption> {
                provider(sources.realmCallback(OperationSearch.compatiblePages, literal("")))
                result {
                    val option = OperationResourceOptionExpressionsFactory.create(row)
                    key(option.id.text)
                    selectedValue(option.id.text)
                    label(option.label.orElse(literal("Unnamed resource")))
                    presentation { text(option.label.orElse(literal("Unnamed resource"))) }
                }
            }
        }
    }
}

object LinkWithForm : LinkWithInputPresentation {
    override fun LinkWithInputPresentationScope.present() {
        target {
            searchInput<OperationResourceOption> {
                provider(sources.realmCallback(OperationSearch.linkTargets, literal("")))
                result {
                    val option = OperationResourceOptionExpressionsFactory.create(row)
                    key(option.id.text)
                    selectedValue(option.id.text)
                    label(option.label.orElse(literal("Unnamed resource")))
                    presentation { text(option.label.orElse(literal("Unnamed resource"))) }
                }
            }
        }
    }
}
