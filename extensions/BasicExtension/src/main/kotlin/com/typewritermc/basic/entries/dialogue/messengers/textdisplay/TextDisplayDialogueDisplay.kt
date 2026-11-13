package com.typewritermc.basic.entries.dialogue.messengers.textdisplay

import com.github.retrooper.packetevents.protocol.entity.type.EntityTypes
import com.github.retrooper.packetevents.util.Vector3f
import com.typewritermc.core.interaction.InteractionContext
import com.typewritermc.core.utils.point.Position
import com.typewritermc.core.utils.point.isInRange
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.extensions.packetevents.meta
import com.typewritermc.engine.paper.snippets.snippet
import com.typewritermc.engine.paper.utils.lineCount
import com.typewritermc.engine.paper.utils.minimalLines
import com.typewritermc.engine.paper.utils.plainText
import com.typewritermc.engine.paper.utils.toPacketLocation
import com.typewritermc.engine.paper.utils.toTicks
import me.tofaa.entitylib.meta.display.AbstractDisplayMeta.BillboardConstraints
import me.tofaa.entitylib.meta.display.TextDisplayMeta
import me.tofaa.entitylib.wrapper.WrapperEntity
import net.kyori.adventure.text.Component
import org.bukkit.entity.Player
import java.time.Duration

private val textDisplayAlignment: String by snippet("dialogue.textDisplay.style.alignment", "LEFT")
private val textDisplayScale: Double by snippet("dialogue.textDisplay.style.scale", 0.58)
private val textDisplayInstructionLineWidth: Int by snippet(
    "dialogue.textDisplay.style.instructionLineWidth",
    200,
)
private val textDisplayInstructionScale: Double by snippet("dialogue.textDisplay.style.instructionScale", 0.50)
private val textDisplayInstructionGap: Double by snippet("dialogue.textDisplay.style.instructionGap", 0.20)
private val textDisplayBackground: Int by snippet("dialogue.textDisplay.style.backgroundColor", 1476395008)
private val textDisplayOpacity: Int by snippet("dialogue.textDisplay.style.opacity", -1)
private const val HIDDEN_OPACITY = 4
private val textDisplayShadow: Boolean by snippet("dialogue.textDisplay.style.shadow", true)
private val textDisplaySeeThrough: Boolean by snippet("dialogue.textDisplay.style.seeThrough", false)
private val textDisplayInterpolationTicks: Int by snippet("dialogue.textDisplay.placement.interpolationTicks", 3)
private val textDisplayPositionUpdateIntervalTicks: Int by snippet(
    "dialogue.textDisplay.placement.updateIntervalTicks",
    3,
)
private val textDisplayPositionUpdateThreshold: Double by snippet(
    "dialogue.textDisplay.placement.updateThreshold",
    0.04,
)
private val textDisplayEnterTicks: Int by snippet("dialogue.textDisplay.animation.enterTicks", 5)
private val textDisplayExitTicks: Int by snippet("dialogue.textDisplay.animation.exitTicks", 4)
private val textDisplayEnterScale: Double by snippet("dialogue.textDisplay.animation.enterScale", 0.78)
private val textDisplayExitScale: Double by snippet("dialogue.textDisplay.animation.exitScale", 0.8)
private val textDisplayEnterOffset: Double by snippet("dialogue.textDisplay.animation.enterOffset", 0.0)
private val textDisplayExitOffset: Double by snippet("dialogue.textDisplay.animation.exitOffset", 0.0)
private val textDisplayOptionGap: Double by snippet("dialogue.textDisplay.option.gap", 0.08)
private val textDisplayOptionInstructionGap: Double by snippet("dialogue.textDisplay.option.instructionGap", 0.25)
private val textDisplayOptionSelectedBackground: Int by snippet(
    "dialogue.textDisplay.option.background.selected", -1207959552,
)
private val textDisplayOptionBackground: Int by snippet(
    "dialogue.textDisplay.option.background.unselected", 1073741824,
)

/** Controls whether the dialogue faces its viewer or follows the origin's rotation. */
enum class TextDisplayOrientation {
    BILLBOARD,
    FIXED,
}

internal class TextDisplayDialogueDisplay(
    private val player: Player,
    private val context: InteractionContext,
    private val origin: Var<Position>,
    private val orientation: TextDisplayOrientation = TextDisplayOrientation.BILLBOARD,
) {
    private val bodyScale = textDisplayScale.coerceIn(0.1, 4.0)
    private val instructionScale = textDisplayInstructionScale.coerceIn(0.1, 4.0)
    private val instructionGap = textDisplayInstructionGap.coerceAtLeast(0.0)
    private val optionInstructionGap = textDisplayOptionInstructionGap.coerceAtLeast(0.0)
    private val optionGap = textDisplayOptionGap.coerceAtLeast(0.0)
    private val bodyWidth = (textDisplayMaxLineLength + 8) * 8
    private val contentEntity = createEntity(bodyScale, bodyWidth)
    private val instructionEntity = createEntity(instructionScale, textDisplayInstructionLineWidth)
    private val fixedPosition = (origin as? ConstVar)?.value
    private var body: Component = Component.empty()
    private var instruction: Component? = null
    private var options: List<Component> = emptyList()
    private val optionEntities = mutableListOf<WrapperEntity>()
    private var selectedOption = -1
    private var optionLines = 1
    private var optionsDirty = false
    private var spawned = false
    private var lastContent: Component? = null
    private var lastInstruction: Component? = null
    private var contentLines = 1
    private var contentDirty = true
    private var layoutDirty = true
    private var instructionDirty = true
    private var lastPosition: Position? = null
    private var positionUpdateTicks = 0
    private var entrance = Entrance.PREPARING
    private var elapsed = Duration.ZERO
    private var closeTime: Duration? = null
    private var instantlyClosed = false

    val ready: Boolean
        get() = entrance == Entrance.PLAYING && elapsed.toTicks() >= enterTicks()

    val isClosing: Boolean
        get() = closeTime != null || instantlyClosed

    val finished: Boolean
        get() = instantlyClosed || closeTime?.toTicks()?.let { it >= exitTicks() } == true

    var invalid = false
        private set

    fun spawn(text: Component) {
        body = text
        val position = position()
        if (position.world.identifier != player.world.uid.toString()) {
            invalid = true
            return
        }
        lastPosition = position
        val content = body
        contentLines = content.plainText().lineCount
        contentEntity.meta<TextDisplayMeta> {
            this.text = content
            textOpacity = HIDDEN_OPACITY.toByte()
            translation = translation(contentOffset(textDisplayEnterScale) + textDisplayEnterOffset)
        }
        instructionEntity.meta<TextDisplayMeta> {
            this.text = instruction ?: Component.empty()
            textOpacity = HIDDEN_OPACITY.toByte()
            translation = instructionTranslation(textDisplayEnterScale, textDisplayEnterOffset)
        }
        lastContent = content
        lastInstruction = instruction
        contentDirty = false
        layoutDirty = optionEntities.isNotEmpty()
        instructionDirty = false
        spawn(contentEntity, position)
        spawn(instructionEntity, position)
        optionEntities.forEach { spawn(it, position) }
        spawned = true
    }

    fun tick(deltaTime: Duration, text: Component? = null) {
        if (invalid || deltaTime.isZero || finished) return
        if (lastPosition?.world?.identifier != player.world.uid.toString()) {
            invalid = true
            return
        }
        elapsed += deltaTime
        closeTime = closeTime?.plus(deltaTime)
        if (!isClosing && fixedPosition == null) updatePosition()
        if (invalid) return
        if (text != null) {
            body = text
            contentDirty = true
        }
        if (!isClosing) {
            updateContent()
            updateOptions()
            updateInstruction()
            animateEntrance()
        }
    }

    fun setInstruction(text: Component?) {
        if (instruction == text) return
        instruction = text
        instructionDirty = true
    }

    fun setOptions(lines: List<Component>, slots: Int, selected: Int, rowLines: Int) {
        val options = lines.take(slots)
        if (optionEntities.size == slots && this.options == options &&
            selectedOption == selected && optionLines == rowLines
        ) return
        layoutDirty = layoutDirty || optionEntities.size != slots || optionLines != rowLines.coerceAtLeast(1)
        while (optionEntities.size > slots) dispose(optionEntities.removeAt(optionEntities.lastIndex))
        while (optionEntities.size < slots) {
            val entity = createEntity(bodyScale, bodyWidth)
            optionEntities.add(entity)
            if (spawned) spawn(entity, lastPosition!!)
        }
        selectedOption = selected
        optionLines = rowLines.coerceAtLeast(1)
        this.options = options
        optionsDirty = true
    }

    fun close() {
        if (!spawned || invalid || isClosing) return
        if (exitTicks() <= 0) {
            instantlyClosed = true
            return
        }

        closeTime = Duration.ZERO
        optionEntities.forEachIndexed { index, entity ->
            entity.meta<TextDisplayMeta> {
                animate(
                    bodyScale,
                    textDisplayExitScale,
                    optionOffset(index, textDisplayExitScale) + textDisplayExitOffset,
                    exitTicks(),
                    HIDDEN_OPACITY,
                )
            }
        }
        contentEntity.meta<TextDisplayMeta> {
            animate(
                bodyScale,
                textDisplayExitScale,
                contentOffset(textDisplayExitScale) + textDisplayExitOffset,
                exitTicks(),
                HIDDEN_OPACITY,
            )
        }
        instructionEntity.meta<TextDisplayMeta> {
            animate(
                instructionScale,
                textDisplayExitScale,
                instructionOffset(textDisplayExitScale) + textDisplayExitOffset,
                exitTicks(),
                HIDDEN_OPACITY,
            )
        }
    }

    fun dispose() {
        dispose(contentEntity)
        dispose(instructionEntity)
        optionEntities.forEach { dispose(it) }
    }

    private fun updateContent() {
        if (!contentDirty) return
        val text = body
        if (text != lastContent) {
            contentEntity.meta<TextDisplayMeta> { this.text = text }
            lastContent = text
        }
        contentDirty = false
    }

    private fun updateOptions() {
        if (!optionsDirty) return
        if (layoutDirty && entrance == Entrance.PLAYING && !ready) return
        optionEntities.forEachIndexed { index, entity ->
            entity.meta<TextDisplayMeta> {
                val optionText = options.getOrNull(index)?.minimalLines(optionLines) ?: Component.empty()
                val background = if (index >= options.size) 0 else if (index == selectedOption) {
                    textDisplayOptionSelectedBackground
                } else textDisplayOptionBackground
                if (text != optionText) text = optionText
                if (backgroundColor != background) backgroundColor = background
                if (!layoutDirty) return@meta
                if (entrance == Entrance.PLAYING) {
                    scale = scale(bodyScale, 1.0)
                    translation = translation(optionOffset(index))
                    textOpacity = configuredOpacity().toByte()
                } else {
                    translation = translation(optionOffset(index, textDisplayEnterScale))
                }
            }
        }
        if (layoutDirty) {
            instructionEntity.meta<TextDisplayMeta> {
                translation = if (entrance == Entrance.PLAYING) instructionTranslation() else {
                    instructionTranslation(textDisplayEnterScale, textDisplayEnterOffset)
                }
            }
        }
        layoutDirty = false
        optionsDirty = false
    }

    private fun updateInstruction() {
        if (!instructionDirty) return
        val text = instruction ?: Component.empty()
        if (text != lastInstruction) {
            instructionEntity.meta<TextDisplayMeta> { this.text = text }
            lastInstruction = text
        }
        instructionDirty = false
    }

    private fun animateEntrance() {
        when (entrance) {
            Entrance.PREPARING -> {
                prepareAnimation(contentEntity)
                prepareAnimation(instructionEntity)
                optionEntities.forEach { prepareAnimation(it) }
                entrance = Entrance.PREPARED
            }
            Entrance.PREPARED -> {
                contentEntity.meta<TextDisplayMeta> {
                    backgroundColor = textDisplayBackground
                    animate(bodyScale, 1.0, contentOffset(), enterTicks())
                }
                instructionEntity.meta<TextDisplayMeta> {
                    animate(instructionScale, 1.0, instructionOffset(), enterTicks())
                }
                optionEntities.forEachIndexed { index, entity ->
                    entity.meta<TextDisplayMeta> {
                        animate(bodyScale, 1.0, optionOffset(index), enterTicks())
                    }
                }
                elapsed = Duration.ZERO
                entrance = Entrance.PLAYING
            }
            Entrance.PLAYING -> Unit
        }
    }

    private fun updatePosition() {
        positionUpdateTicks++
        if (positionUpdateTicks < textDisplayPositionUpdateIntervalTicks.coerceAtLeast(1)) return
        positionUpdateTicks = 0

        val position = position()
        if (position.world.identifier != player.world.uid.toString()) {
            invalid = true
            return
        }
        val previous = lastPosition
        if (previous?.isInRange(position, textDisplayPositionUpdateThreshold.coerceAtLeast(0.0)) == true &&
            previous.yaw == position.yaw && previous.pitch == position.pitch
        ) return

        val location = position.toPacketLocation()
        contentEntity.teleport(location)
        instructionEntity.teleport(location)
        optionEntities.forEach { it.teleport(location) }
        lastPosition = position
    }

    private fun position(): Position {
        val position = fixedPosition ?: origin.get(player, context)
        return if (orientation == TextDisplayOrientation.FIXED) position else position.resetRotation()
    }

    private fun createEntity(displayScale: Double, displayLineWidth: Int): WrapperEntity {
        return WrapperEntity(EntityTypes.TEXT_DISPLAY).meta<TextDisplayMeta> {
            billboardConstraints = if (orientation == TextDisplayOrientation.FIXED) {
                BillboardConstraints.FIXED
            } else {
                BillboardConstraints.VERTICAL
            }
            backgroundColor = 0
            isUseDefaultBackground = false
            textOpacity = HIDDEN_OPACITY.toByte()
            isShadow = textDisplayShadow
            isSeeThrough = textDisplaySeeThrough
            isAlignLeft = textDisplayAlignment.equals("LEFT", true)
            isAlignRight = textDisplayAlignment.equals("RIGHT", true)
            lineWidth = displayLineWidth.coerceIn(20, 1024)
            scale = scale(displayScale, textDisplayEnterScale)
            interpolationDelay = 0
            transformationInterpolationDuration = 0
            positionRotationInterpolationDuration = textDisplayInterpolationTicks.coerceIn(0, 59)
        }
    }

    private fun TextDisplayMeta.animate(
        displayScale: Double,
        scaleMultiplier: Double,
        height: Double,
        duration: Int,
        opacity: Int = configuredOpacity(),
    ) {
        // Send a different delay for exit so the client restarts interpolation.
        interpolationDelay = if (isClosing && entrance == Entrance.PLAYING) 0 else -1
        transformationInterpolationDuration = duration
        scale = scale(displayScale, scaleMultiplier)
        translation = translation(height)
        textOpacity = opacity.coerceIn(0, 255).toByte()
    }

    private fun instructionTranslation(scaleMultiplier: Double = 1.0, offset: Double = 0.0): Vector3f {
        return translation(instructionOffset(scaleMultiplier) + offset)
    }

    private fun contentOffset(scaleMultiplier: Double = 1.0): Double {
        return contentHeight() * (1.0 - scaleMultiplier) / 2.0
    }

    private fun instructionOffset(scaleMultiplier: Double = 1.0): Double {
        val contentHeight = contentHeight()
        val instructionHeight = TEXT_LINE_HEIGHT * instructionScale
        val gap = if (optionEntities.isEmpty()) instructionGap else optionInstructionGap
        val optionsHeight = optionEntities.size * (optionHeight() + optionGap)
        return contentHeight / 2.0 -
            scaleMultiplier * (contentHeight / 2.0 + optionsHeight + instructionHeight + gap)
    }

    private fun optionHeight(): Double = optionLines * TEXT_LINE_HEIGHT * bodyScale

    private fun optionOffset(index: Int, scaleMultiplier: Double = 1.0): Double {
        val halfBodyHeight = contentHeight() / 2.0
        return halfBodyHeight - scaleMultiplier * (halfBodyHeight + (index + 1) * (optionHeight() + optionGap))
    }

    private fun contentHeight(): Double = contentLines * TEXT_LINE_HEIGHT * bodyScale

    private fun spawn(entity: WrapperEntity, position: Position) {
        entity.spawn(position.toPacketLocation())
        entity.addViewer(player.uniqueId)
    }

    private fun dispose(entity: WrapperEntity) {
        entity.despawn()
        entity.remove()
    }

    private fun prepareAnimation(entity: WrapperEntity) {
        entity.meta<TextDisplayMeta> {
            interpolationDelay = 0
            transformationInterpolationDuration = enterTicks()
        }
    }

    private enum class Entrance { PREPARING, PREPARED, PLAYING }

    private companion object {
        const val TEXT_LINE_HEIGHT = 10.0 / 40.0
    }
}

private fun configuredOpacity(): Int {
    return if (textDisplayOpacity < 0) 255 else textDisplayOpacity.coerceIn(HIDDEN_OPACITY, 255)
}

private fun enterTicks(): Int = animationTicks(textDisplayEnterTicks)

private fun exitTicks(): Int = animationTicks(textDisplayExitTicks)

private fun animationTicks(ticks: Int): Int = ticks.coerceIn(0, 59)

private fun scale(displayScale: Double, multiplier: Double): Vector3f {
    val scale = (displayScale * multiplier).toFloat()
    return Vector3f(scale, scale, scale)
}

private fun translation(height: Double): Vector3f {
    return Vector3f(0f, height.toFloat(), 0f)
}
