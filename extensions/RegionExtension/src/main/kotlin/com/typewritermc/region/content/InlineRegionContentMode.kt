package com.typewritermc.region.content

import com.typewritermc.core.entries.Entry
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.utils.failure
import com.typewritermc.engine.paper.content.ContentComponent
import com.typewritermc.engine.paper.content.ContentContext
import com.typewritermc.engine.paper.content.ContentMode
import com.typewritermc.engine.paper.content.entryId
import com.typewritermc.engine.paper.content.fieldPath
import com.typewritermc.engine.paper.entry.stagedEntry
import com.typewritermc.region.data.buildShapeOrNull
import org.bukkit.entity.Player
import java.time.Duration

/**
 * The editor of an inline region definition.
 *
 * A definition entry carries its shape in its type, so the panel knows which editor to ask
 * for. An inline definition carries it in its data, so the editor can only be picked once
 * the entry is read. This mode is that indirection: it resolves the shape the user chose and
 * runs the very editor the matching definition entry would have opened, writing through the
 * paths the inline definition lives behind.
 */
class InlineRegionContentMode(context: ContentContext, player: Player) : ContentMode(context, player) {
    private var editor: RegionContentMode? = null

    override val components: MutableList<ContentComponent>
        get() = editor?.components ?: mutableListOf()

    override suspend fun setup(): Result<Unit> {
        val entryId = context.entryId
            ?: return failure("No entryId found for ${this::class.simpleName}. This is a bug. Please report it.")
        val fieldPath = context.fieldPath
            ?: return failure("No fieldPath found for ${this::class.simpleName}. This is a bug. Please report it.")

        val ref = Ref(entryId, Entry::class)
        val entry = ref.stagedEntry() ?: ref.get()
            ?: return failure("Could not find the entry $entryId to edit.")
        val target = regionEditTarget(entry, fieldPath)
            ?: return failure("$fieldPath on $entryId holds no region to edit. This is a bug. Please report it.")
        val definition = target.definitionOf(entry)
            ?: return failure("This region points at a definition entry. Open the editor on that entry instead.")

        val shape = definition.buildShapeOrNull()
            ?: return failure("This region's shape fields do not describe a shape. Fix them on the web panel first.")
        val editor = regionEditorMode(shape, context, player)
            ?: return failure("The inline region's shape has no in-game editor.")
        this.editor = editor
        return editor.setup()
    }

    override suspend fun initialize() {
        editor?.initialize()
    }

    override suspend fun tick(deltaTime: Duration) {
        editor?.tick(deltaTime)
    }

    override suspend fun dispose() {
        editor?.dispose()
    }
}
