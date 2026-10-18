package com.typewritermc.operations

import com.typewritermc.authoring.ResourceDraft
import com.typewritermc.presentation.ButtonVariant
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypewriterType

enum class BuiltinResourceOperation(
    val local: String,
    val label: String,
    val icon: String,
    val variant: ButtonVariant = ButtonVariant.Outlined,
    val showInInspector: Boolean = true,
) {
    Open("open", "Open", "mdi:open-in-new", ButtonVariant.Text),
    Edit("edit", "Edit", "mdi:pencil", showInInspector = false),
    MoveToPage("moveToPage", "Move to page", "mdi:file-move-outline"),
    MoveToBook("moveToBook", "Move to book", "mdi:book-arrow-right-outline"),
    LinkWith("linkWith", "Link with", "mdi:link-variant"),
    Duplicate("duplicate", "Duplicate", "mdi:content-copy"),
    LinkWithDuplicate("linkWithDuplicate", "Link with duplicate", "mdi:link-variant-plus"),
    Delete("delete", "Delete", "mdi:delete-outline", ButtonVariant.Filled),
    ;

    val id: ResourceOperationId
        get() = ResourceOperationId("typewriter", "main", "com.typewritermc.library.CoreResourceOperations", local)
}

@TypewriterType(id = "fc34fcfe2cfe4f2ebf52947afc054de1")
data class MoveToPageInput(
    val destination: ResourceId,
    val anchorX: Double? = null,
    val anchorY: Double? = null,
)

@TypewriterType(id = "4a3d713ca8304a17b19a1faf4a075f49")
data class MoveToBookInput(
    val destination: ResourceId,
)

@TypewriterType(id = "e719cd67b7bb4cc096e17149ec4f0a91")
data class LinkWithInput(
    val target: ResourceId,
)

fun ResourceOperationsScope<*>.open(): OperationHandle = builtin(BuiltinResourceOperation.Open)

fun ResourceOperationsScope<*>.edit(): OperationHandle = builtin(BuiltinResourceOperation.Edit)

fun ResourceOperationsScope<*>.moveToPage(): OperationHandle = builtin(BuiltinResourceOperation.MoveToPage)

fun ResourceOperationsScope<*>.moveToBook(): OperationHandle = builtin(BuiltinResourceOperation.MoveToBook)

fun ResourceOperationsScope<*>.linkWith(): OperationHandle = builtin(BuiltinResourceOperation.LinkWith)

fun ResourceOperationsScope<*>.duplicate(): OperationHandle = builtin(BuiltinResourceOperation.Duplicate)

fun ResourceOperationsScope<*>.linkWithDuplicate(): OperationHandle = builtin(BuiltinResourceOperation.LinkWithDuplicate)

fun ResourceOperationsScope<*>.delete(): OperationHandle = builtin(BuiltinResourceOperation.Delete)

context(session: OperationPreparation)
internal suspend fun BuiltinResourceOperation.prepare(
    targets: List<ResourceId>,
    input: Any?,
) {
    when (this) {
        BuiltinResourceOperation.Delete -> {
            session.deleteSelection(targets)
        }

        BuiltinResourceOperation.Duplicate -> {
            session.selectAfterStaging(session.cloner.duplicateOwned(targets).selectedCopies)
        }

        BuiltinResourceOperation.LinkWithDuplicate -> {
            require(targets.size == 1) { "Link with duplicate requires one resource." }
            val copied =
                session.cloner
                    .duplicateOwned(targets)
                    .selectedCopies
                    .single()
            session.relations.linkWithDuplicate(targets.single(), copied, session.choices)
            session.selectAfterStaging(listOf(copied))
        }

        BuiltinResourceOperation.LinkWith -> {
            session.relations.linkWith(targets, (input as LinkWithInput).target, session.choices)
        }

        BuiltinResourceOperation.MoveToPage -> {
            val move = input as MoveToPageInput
            require((move.anchorX == null) == (move.anchorY == null)) { "A placement anchor requires both coordinates." }
            val selected =
                with(session as com.typewritermc.authoring.AuthoredReads) {
                    targets.map {
                        requireAuthored(
                            com.typewritermc.elements.ElementDraftProjection.read(
                                com.typewritermc.authoring.ValueLocation(it, com.typewritermc.authoring.ValuePath()),
                            ),
                        )
                    }
                }
            val assignment = session.relations.requireMove(selected, move.destination, session.invocation.origin, session.choices)
            val anchor = move.anchorX?.let { PlacementAnchor(it, requireNotNull(move.anchorY)) }
            assignment.apply()
            val placement = session.layouts.prepareMove(selected, move.destination, anchor)
            placement.apply()
        }

        BuiltinResourceOperation.MoveToBook -> {
            val move = input as MoveToBookInput
            movePagesToBook(targets, move.destination)
        }

        BuiltinResourceOperation.Open, BuiltinResourceOperation.Edit -> {
            error("Navigation is a client action.")
        }
    }
}
