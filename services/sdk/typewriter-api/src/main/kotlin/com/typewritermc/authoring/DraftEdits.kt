package com.typewritermc.authoring

interface DraftEdits {
    suspend fun DraftView.prepareEdit(
        id: EditPreparationId,
        block: suspend EditContext.() -> Unit,
    ): PreparedEditResult

    suspend fun commit(edit: PreparedEdit): CommitResult
}

@JvmInline
value class EditPreparationId(
    val value: String,
) {
    init {
        require(value.isNotBlank()) { "An edit preparation id must not be blank." }
    }
}
