package com.typewritermc.basic.entries.dialogue.messengers

import org.bukkit.entity.Player

internal fun Player.sendDialogueForm(
    title: String,
    content: String,
    button: String,
    onClose: () -> Unit,
    onConfirm: () -> Unit,
) {
    org.geysermc.floodgate.api.FloodgateApi.getInstance().sendForm(
        uniqueId,
        org.geysermc.cumulus.form.SimpleForm.builder()
            .title(title)
            .content(content)
            .button(button)
            .closedOrInvalidResultHandler { _, _ -> onClose() }
            .validResultHandler { _, _ -> onConfirm() },
    )
}

internal fun Player.sendDialogueOptions(
    title: String,
    content: String,
    prompt: String,
    options: List<String>,
    onClose: () -> Unit,
    onSelect: (Int) -> Unit,
) {
    org.geysermc.floodgate.api.FloodgateApi.getInstance().sendForm(
        uniqueId,
        org.geysermc.cumulus.form.CustomForm.builder()
            .title(title)
            .label(content)
            .dropdown(prompt, options)
            .label("\n\n\n\n")
            .closedOrInvalidResultHandler { _, _ -> onClose() }
            .validResultHandler { response -> onSelect(response.asDropdown()) },
    )
}
