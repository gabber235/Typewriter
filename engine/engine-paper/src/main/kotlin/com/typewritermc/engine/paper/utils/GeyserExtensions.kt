package com.typewritermc.engine.paper.utils

import com.typewritermc.core.utils.point.Position
import com.typewritermc.engine.paper.TypewriterPaperPlugin
import org.bukkit.entity.Player
import org.cloudburstmc.math.vector.Vector3f
import org.geysermc.floodgate.api.FloodgateApi
import org.geysermc.geyser.api.GeyserApi
import org.geysermc.geyser.api.bedrock.camera.CameraEaseType
import org.geysermc.geyser.api.bedrock.camera.CameraPerspective
import org.geysermc.geyser.api.bedrock.camera.CameraPosition
import org.geysermc.geyser.api.bedrock.camera.GuiElement
import org.geysermc.geyser.api.connection.GeyserConnection
import org.koin.java.KoinJavaComponent
import java.util.*


val Player.isFloodgate: Boolean
    get() {
        if (!KoinJavaComponent.get<TypewriterPaperPlugin>(TypewriterPaperPlugin::class.java).isFloodgateInstalled) return false
        return FloodgateApi.getInstance().isFloodgatePlayer(this.uniqueId)
    }

val Player.geyserConnection: GeyserConnection?
    get() {
        if (!KoinJavaComponent.get<TypewriterPaperPlugin>(TypewriterPaperPlugin::class.java).isGeyserInstalled) return null
        return GeyserApi.api().connectionByUuid(this.uniqueId)
    }

fun GeyserConnection.setupCamera(cameraLockId: UUID) = camera().apply {
    this.lockCamera(true, cameraLockId)
    this.forceCameraPerspective(CameraPerspective.FIRST_PERSON)
    this.hideElement(
        GuiElement.PAPER_DOLL,
        GuiElement.ARMOR,
        GuiElement.TOOL_TIPS,
        GuiElement.TOUCH_CONTROLS,
        GuiElement.CROSSHAIR,
        GuiElement.HOTBAR,
        GuiElement.HEALTH,
        GuiElement.PROGRESS_BAR,
        GuiElement.FOOD_BAR,
        GuiElement.AIR_BUBBLES_BAR,
        GuiElement.VEHICLE_HEALTH,
        GuiElement.EFFECTS_BAR,
        GuiElement.ITEM_TEXT_POPUP,
    )
}

fun GeyserConnection.forceCameraPosition(position: Position) = camera().apply {
    this.sendCameraPosition(
        CameraPosition.builder()
            .position(Vector3f.from(position.x, position.y, position.z))
            .renderPlayerEffects(true)
            .rotationX(position.pitch.toInt().coerceIn(-90..90))
            .rotationY(position.yaw.toInt())
            .playerPositionForAudio(false)
            .build()
    )
}

fun GeyserConnection.interpolateCameraPosition(position: Position) = camera().apply {
    this.sendCameraPosition(
        CameraPosition.builder()
            .position(Vector3f.from(position.x, position.y, position.z))
            .easeSeconds(0.5f)
            .easeType(CameraEaseType.LINEAR)
            .renderPlayerEffects(true)
            .rotationX(position.pitch.toInt().coerceIn(-90..90))
            .rotationY(position.yaw.toInt())
            .playerPositionForAudio(false)
            .build()
    )
}

fun GeyserConnection.resetCamera(cameraLockId: UUID) = camera().apply {
    this.lockCamera(false, cameraLockId)
    this.clearCameraInstructions()
    this.resetElement(
        GuiElement.PAPER_DOLL,
        GuiElement.ARMOR,
        GuiElement.TOOL_TIPS,
        GuiElement.TOUCH_CONTROLS,
        GuiElement.CROSSHAIR,
        GuiElement.HOTBAR,
        GuiElement.HEALTH,
        GuiElement.PROGRESS_BAR,
        GuiElement.FOOD_BAR,
        GuiElement.AIR_BUBBLES_BAR,
        GuiElement.VEHICLE_HEALTH,
        GuiElement.EFFECTS_BAR,
        GuiElement.ITEM_TEXT_POPUP,
    )
}