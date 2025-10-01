package com.typewritermc.roadnetwork.content.debug

import com.github.retrooper.packetevents.protocol.entity.type.EntityTypes
import com.github.retrooper.packetevents.protocol.item.type.ItemType
import com.github.retrooper.packetevents.protocol.item.type.ItemTypes
import com.github.retrooper.packetevents.protocol.world.Location
import com.github.retrooper.packetevents.util.Vector3f
import com.typewritermc.core.utils.point.Position
import com.typewritermc.engine.paper.extensions.packetevents.sendPacketTo
import de.bsommerfeld.pathetic.api.wrapper.PathPosition
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import me.tofaa.entitylib.meta.display.AbstractDisplayMeta
import me.tofaa.entitylib.meta.display.ItemDisplayMeta
import me.tofaa.entitylib.meta.display.TextDisplayMeta
import me.tofaa.entitylib.wrapper.WrapperEntity
import net.kyori.adventure.text.Component
import net.kyori.adventure.text.format.NamedTextColor
import org.bukkit.entity.Player
import com.github.retrooper.packetevents.protocol.item.ItemStack as PacketItemStack

class PathfindingDebugDisplayManager(
    private val player: Player,
    private val startPosition: Position,
    private val endPosition: Position
) {

    private val stepDisplays = mutableMapOf<PathPosition, StepDisplay>()
    private val rejectionDisplays = mutableMapOf<PathPosition, RejectionDisplay>()
    private val pathDisplays = mutableListOf<PathDisplay>()
    private val failureDisplays = mutableListOf<FailureDisplay>()

    private val updateMutex = Mutex()

    private var lastIsPlayback = false
    private var lastProcessedStepIndex = -1
    private var rejectionTimestamps = mutableMapOf<PathPosition, Long>()
    private var wasInPlayback = false
    private var visiblePositions = setOf<PathPosition>()
    private var emphasizedPositions = setOf<PathPosition>()

    companion object {
        private const val REJECTION_TIMEOUT_MS = 1000L
    }

    suspend fun updateVisualization(
        steps: List<PathfindingDebugStep>,
        currentStepIndex: Int,
        finalPath: List<PathPosition>? = null,
        showVerbose: Boolean = false,
        isPlayback: Boolean = false,
        successful: Boolean = true,
        intermediateNodeCollision: IntermediateNodeCollision? = null,
        timeoutOnly: Boolean = false
    ) {
        updateMutex.withLock {
            if (timeoutOnly) {
                handleRejectionTimeouts()
                return@withLock
            }

            val (newVisiblePositions, newEmphasizedPositions) = calculateVisiblePositions(
                steps,
                currentStepIndex,
                showVerbose
            )
            val visibilityChanged = newVisiblePositions != visiblePositions
            val emphasisChanged = newEmphasizedPositions != emphasizedPositions

            visiblePositions = newVisiblePositions
            emphasizedPositions = newEmphasizedPositions

            val visibleSteps = if (showVerbose) {
                steps.take(currentStepIndex + 1)
            } else {
                steps.filter { !it.isVerbose }.take(currentStepIndex + 1)
            }

            val isShowingFinalPath = finalPath != null && finalPath.isNotEmpty() &&
                    currentStepIndex >= steps.size - 1 && successful

            val isShowingCollisionPath = finalPath != null && finalPath.isNotEmpty() &&
                    currentStepIndex >= steps.size - 1 && !successful &&
                    intermediateNodeCollision != null

            updateStepDisplays(
                visibleSteps, currentStepIndex, isShowingFinalPath, finalPath,
                isShowingCollisionPath, intermediateNodeCollision
            )
            updateRejectionDisplays(visibleSteps, currentStepIndex, isPlayback)
            updatePathDisplays(finalPath, isShowingFinalPath, isShowingCollisionPath, intermediateNodeCollision)
            updateFailureDisplays(steps, currentStepIndex, finalPath, successful, intermediateNodeCollision)

            if (visibilityChanged || emphasisChanged) {
                updateStepVisibility()
            }

            lastIsPlayback = isPlayback
        }
    }

    private fun calculateVisiblePositions(
        steps: List<PathfindingDebugStep>,
        currentStepIndex: Int,
        showVerbose: Boolean
    ): Pair<Set<PathPosition>, Set<PathPosition>> {
        val newVisiblePositions = mutableSetOf<PathPosition>()
        val newEmphasizedPositions = mutableSetOf<PathPosition>()

        val visibleSteps = if (showVerbose) {
            steps.take(currentStepIndex + 1)
        } else {
            steps.filter { !it.isVerbose }.take(currentStepIndex + 1)
        }

        val currentStep = visibleSteps.getOrNull(currentStepIndex)
        if (currentStep != null) {
            newVisiblePositions.add(currentStep.position)
            newEmphasizedPositions.add(currentStep.position)

            currentStep.parentPosition?.let { parentPos ->
                newVisiblePositions.add(parentPos)
                newEmphasizedPositions.add(parentPos)
            }
        }

        return newVisiblePositions to newEmphasizedPositions
    }

    private fun updateStepVisibility() {
        stepDisplays.forEach { (position, display) ->
            val shouldBeVisible = position in visiblePositions
            val shouldBeEmphasized = position in emphasizedPositions
            display.setVisibility(shouldBeVisible)
            if (shouldBeVisible) {
                display.refreshBlockType(shouldBeEmphasized)
            }
        }
    }

    private fun updateStepDisplays(
        visibleSteps: List<PathfindingDebugStep>,
        currentStepIndex: Int,
        isShowingFinalPath: Boolean,
        finalPath: List<PathPosition>?,
        isShowingCollisionPath: Boolean,
        intermediateNodeCollision: IntermediateNodeCollision?
    ) {
        val stepsToShow = mutableSetOf<PathPosition>()
        val stepInfo = mutableMapOf<PathPosition, StepInfo>()

        val exploredPositions = mutableSetOf<PathPosition>()
        visibleSteps.forEach { step ->
            if (step.event is PathfindingDebugEvent.NodeExplored) {
                exploredPositions.add(step.position)
            }
        }

        val finalPathPositions = finalPath?.toSet() ?: emptySet()
        val collisionPathPositions = if (isShowingCollisionPath) {
            finalPath?.take(intermediateNodeCollision!!.collisionPathIndex + 1)?.toSet() ?: emptySet()
        } else emptySet()

        val collidingNodePosition = intermediateNodeCollision?.let { collision ->
            PathPosition(
                collision.collidingNode.position.x,
                collision.collidingNode.position.y,
                collision.collidingNode.position.z
            )
        }

        visibleSteps.forEachIndexed { visibleIndex, step ->
            val position = step.position

            if (isStartOrEndPosition(position)) return@forEachIndexed

            val isCurrent = visibleIndex == currentStepIndex
            val isExplored = step.event is PathfindingDebugEvent.NodeExplored
            val isRejected = step.event is PathfindingDebugEvent.NodeRejected
            val isCollisionEvent = step.event is PathfindingDebugEvent.IntermediateNodeCollision

            if (isCollisionEvent) return@forEachIndexed

            if (isShowingFinalPath && isExplored && position in finalPathPositions) return@forEachIndexed
            if (isShowingCollisionPath && isExplored && position in collisionPathPositions) return@forEachIndexed

            val isCollidingNode = collidingNodePosition != null && isSamePosition(position, collidingNodePosition)

            if (!isExplored && !isRejected) return@forEachIndexed
            if (isRejected && position in exploredPositions) {
                if (isCurrent) {
                    val existingInfo = stepInfo[position]
                    if (existingInfo != null) {
                        stepInfo[position] = existingInfo.copy(isCurrent = true)
                    }
                }
                return@forEachIndexed
            }

            stepsToShow.add(position)

            val existingInfo = stepInfo[position]
            val shouldReplace = existingInfo == null ||
                    (!existingInfo.isExplored && isExplored) ||
                    (existingInfo.isExplored == isExplored && step.stepIndex > existingInfo.stepIndex)

            if (shouldReplace) {
                stepInfo[position] = StepInfo(
                    stepIndex = step.stepIndex,
                    isCurrent = isCurrent,
                    isExplored = isExplored,
                    isRejected = isRejected,
                    isCollidingNode = isCollidingNode
                )
            } else if (isCurrent || isCollidingNode) {
                stepInfo[position] = existingInfo.copy(
                    isCurrent = isCurrent || existingInfo.isCurrent,
                    isCollidingNode = isCollidingNode || existingInfo.isCollidingNode
                )
            }
        }

        val toRemove = stepDisplays.keys - stepsToShow
        toRemove.forEach { position ->
            stepDisplays[position]?.remove()
            stepDisplays.remove(position)
        }

        stepInfo.forEach { (position, info) ->
            val existingDisplay = stepDisplays[position]
            val isEmphasized = position in emphasizedPositions
            if (existingDisplay != null) {
                existingDisplay.update(
                    info.isCurrent,
                    info.isExplored,
                    info.isRejected,
                    info.isCollidingNode,
                    isEmphasized
                )
            } else {
                val newDisplay = createStepDisplay(
                    position, info.isCurrent, info.isExplored, info.isRejected,
                    info.isCollidingNode, isEmphasized
                )
                stepDisplays[position] = newDisplay
            }
        }
    }

    private fun updateRejectionDisplays(
        visibleSteps: List<PathfindingDebugStep>,
        currentStepIndex: Int,
        isPlayback: Boolean
    ) {
        val currentTime = System.currentTimeMillis()

        val currentRejections = if (isPlayback) {
            if (!wasInPlayback) {
                lastProcessedStepIndex = currentStepIndex
                wasInPlayback = true
            }

            if (currentStepIndex > lastProcessedStepIndex) {
                for (stepIndex in (lastProcessedStepIndex + 1)..currentStepIndex) {
                    if (stepIndex < visibleSteps.size) {
                        val step = visibleSteps[stepIndex]
                        if (step.event is PathfindingDebugEvent.NodeRejected) {
                            if (!rejectionTimestamps.containsKey(step.position)) {
                                rejectionTimestamps[step.position] = currentTime
                            }
                        }
                    }
                }
            }

            rejectionTimestamps.entries.removeAll { (position, timestamp) ->
                val isExpired = currentTime - timestamp >= REJECTION_TIMEOUT_MS
                if (isExpired) {
                    rejectionDisplays[position]?.remove()
                    rejectionDisplays.remove(position)
                }
                isExpired
            }

            val activeRejections = mutableMapOf<PathPosition, PathfindingDebugEvent.NodeRejected>()
            visibleSteps.forEach { step ->
                val rejection = step.event as? PathfindingDebugEvent.NodeRejected
                if (rejection != null && rejectionTimestamps.containsKey(step.position)) {
                    activeRejections[step.position] = rejection
                }
            }
            activeRejections
        } else {
            if (wasInPlayback) {
                rejectionTimestamps.clear()
                lastProcessedStepIndex = -1
                wasInPlayback = false
            }

            val currentStep = visibleSteps.getOrNull(currentStepIndex)
            if (currentStep?.event is PathfindingDebugEvent.NodeRejected) {
                mapOf(currentStep.position to currentStep.event)
            } else {
                emptyMap()
            }
        }

        if (isPlayback) {
            lastProcessedStepIndex = currentStepIndex
        }

        val toRemove = rejectionDisplays.keys - currentRejections.keys
        toRemove.forEach { position ->
            rejectionDisplays[position]?.remove()
            rejectionDisplays.remove(position)
        }

        currentRejections.forEach { (position, rejection) ->
            val currentStep = visibleSteps.getOrNull(currentStepIndex)
            val isCurrentStep = currentStep?.position == position

            val existingDisplay = rejectionDisplays[position]
            if (existingDisplay != null) {
                existingDisplay.update(isCurrentStep)
            } else {
                val newDisplay = createRejectionDisplay(position, rejection, isCurrentStep)
                rejectionDisplays[position] = newDisplay
            }
        }
    }

    private fun updatePathDisplays(
        finalPath: List<PathPosition>?,
        isShowingFinalPath: Boolean,
        isShowingCollisionPath: Boolean,
        intermediateNodeCollision: IntermediateNodeCollision?
    ) {
        pathDisplays.forEach { it.remove() }
        pathDisplays.clear()

        if (isShowingFinalPath && finalPath != null && finalPath.isNotEmpty()) {
            finalPath
                .filterNot { isStartOrEndPosition(it) }
                .forEach { pathPos ->
                    val display = createPathDisplay(pathPos, isSuccessPath = true, isCollisionPoint = false)
                    pathDisplays.add(display)
                }
        } else if (isShowingCollisionPath && finalPath != null && finalPath.isNotEmpty() && intermediateNodeCollision != null) {
            val pathToCollision = finalPath.take(intermediateNodeCollision.collisionPathIndex + 1)
            val actualCollisionPosition = intermediateNodeCollision.collisionPosition

            pathToCollision.forEach { pathPos ->
                val isActualCollisionPosition = isSamePosition(pathPos, actualCollisionPosition)
                if (isStartOrEndPosition(pathPos) && !isActualCollisionPosition) {
                    return@forEach
                }

                val display = createPathDisplay(
                    pathPos,
                    isSuccessPath = false,
                    isCollisionPoint = isActualCollisionPosition
                )
                pathDisplays.add(display)
            }
        }
    }

    private fun updateFailureDisplays(
        steps: List<PathfindingDebugStep>,
        currentStepIndex: Int,
        finalPath: List<PathPosition>?,
        successful: Boolean,
        intermediateNodeCollision: IntermediateNodeCollision?
    ) {
        failureDisplays.forEach { it.remove() }
        failureDisplays.clear()

        if (currentStepIndex >= steps.size - 1 && !successful) {
            if (intermediateNodeCollision != null) {
                val failureDisplay = createFailureTextDisplay(
                    intermediateNodeCollision.collisionPosition,
                    "Path blocked by node ${intermediateNodeCollision.collidingNode.id}!"
                )
                failureDisplays.add(failureDisplay)
            } else {
                val pathFailedEvent = steps.lastOrNull {
                    it.event is PathfindingDebugEvent.PathFailed
                }?.event as? PathfindingDebugEvent.PathFailed

                val targetPos = finalPath?.lastOrNull()
                if (targetPos != null) {
                    val failureDisplay = createFailureTextDisplay(
                        targetPos,
                        pathFailedEvent?.reason ?: "Pathfinding failed"
                    )
                    failureDisplays.add(failureDisplay)
                }
            }
        }
    }

    private fun isStartOrEndPosition(pathPos: PathPosition): Boolean {
        return (pathPos.flooredX == kotlin.math.floor(startPosition.x).toInt() &&
                pathPos.flooredY == kotlin.math.floor(startPosition.y).toInt() &&
                pathPos.flooredZ == kotlin.math.floor(startPosition.z).toInt()) ||
                (pathPos.flooredX == kotlin.math.floor(endPosition.x).toInt() &&
                        pathPos.flooredY == kotlin.math.floor(endPosition.y).toInt() &&
                        pathPos.flooredZ == kotlin.math.floor(endPosition.z).toInt())
    }

    private fun isSamePosition(pos1: PathPosition, pos2: PathPosition): Boolean {
        return pos1.flooredX == pos2.flooredX &&
                pos1.flooredY == pos2.flooredY &&
                pos1.flooredZ == pos2.flooredZ
    }

    private fun determineBlockType(isRejected: Boolean, isExplored: Boolean, isEmphasized: Boolean): ItemType {
        return when {
            isRejected && isEmphasized -> ItemTypes.RED_CONCRETE
            isRejected -> ItemTypes.RED_STAINED_GLASS
            isExplored && isEmphasized -> ItemTypes.GREEN_CONCRETE
            isExplored -> ItemTypes.GREEN_STAINED_GLASS
            isEmphasized -> ItemTypes.WHITE_CONCRETE
            else -> ItemTypes.GLASS
        }
    }

    private fun createStepDisplay(
        position: PathPosition,
        isCurrent: Boolean,
        isExplored: Boolean,
        isRejected: Boolean,
        isCollidingNode: Boolean,
        isEmphasized: Boolean
    ): StepDisplay {
        val entity = WrapperEntity(EntityTypes.ITEM_DISPLAY)
        val meta = entity.entityMeta as ItemDisplayMeta

        val itemType = determineBlockType(isRejected, isExplored, isEmphasized)

        meta.item = PacketItemStack.builder().type(itemType).amount(1).build()
        meta.billboardConstraints = AbstractDisplayMeta.BillboardConstraints.FIXED
        meta.scale = if (isCurrent) Vector3f(0.8f, 0.8f, 0.8f) else Vector3f(0.5f, 0.5f, 0.5f)

        if (isCollidingNode) {
            meta.isGlowing = true
        }

        entity.addViewer(player.uniqueId)
        val location = Location(
            position.x + 0.5,
            position.y + 0.8,
            position.z + 0.5,
            0f, 0f
        )
        entity.spawn(location)

        val stepDisplay = StepDisplay(entity, itemType, player, isCurrent, isCollidingNode)
        val shouldBeVisible = position in visiblePositions
        stepDisplay.setVisibility(shouldBeVisible)

        return stepDisplay
    }

    private fun createRejectionDisplay(
        position: PathPosition,
        rejection: PathfindingDebugEvent.NodeRejected,
        isCurrent: Boolean
    ): RejectionDisplay {
        val entity = WrapperEntity(EntityTypes.TEXT_DISPLAY)
        val meta = entity.entityMeta as TextDisplayMeta

        val textComponent = Component.text(rejection.reason)
            .color(NamedTextColor.RED)
            .append(Component.newline())
            .append(Component.text("(${rejection.processorName})").color(NamedTextColor.GRAY))

        meta.text = textComponent
        meta.isShadow = true
        meta.isSeeThrough = false
        meta.backgroundColor = if (isCurrent) 0x60000000 else 0x40000000
        meta.billboardConstraints = AbstractDisplayMeta.BillboardConstraints.CENTER
        meta.scale = if (isCurrent) Vector3f(1.2f, 1.2f, 1.2f) else Vector3f(0.8f, 0.8f, 0.8f)
        meta.isSeeThrough = true

        entity.addViewer(player.uniqueId)
        val location = Location(
            position.x + 0.5,
            position.y + 1.5,
            position.z + 0.5,
            0f, 0f
        )
        entity.spawn(location)

        return RejectionDisplay(entity, player, isCurrent)
    }

    private fun createPathDisplay(
        position: PathPosition,
        isSuccessPath: Boolean,
        isCollisionPoint: Boolean
    ): PathDisplay {
        val entity = WrapperEntity(EntityTypes.ITEM_DISPLAY)
        val meta = entity.entityMeta as ItemDisplayMeta

        if (isSuccessPath) {
            meta.item = PacketItemStack.builder().type(ItemTypes.LIGHT_BLUE_CONCRETE).amount(1).build()
            meta.isGlowing = true
        } else {
            meta.item = PacketItemStack.builder().type(ItemTypes.ORANGE_CONCRETE).amount(1).build()
            meta.isGlowing = isCollisionPoint
            meta.glowColorOverride = NamedTextColor.GOLD.value()
        }

        meta.billboardConstraints = AbstractDisplayMeta.BillboardConstraints.FIXED
        meta.scale = Vector3f(0.6f, 0.6f, 0.6f)

        entity.addViewer(player.uniqueId)
        val location = Location(
            position.x + 0.5,
            position.y + 0.6,
            position.z + 0.5,
            0f, 0f
        )
        entity.spawn(location)

        return PathDisplay(entity)
    }

    private fun createFailureTextDisplay(position: PathPosition, message: String): FailureDisplay {
        val entity = WrapperEntity(EntityTypes.TEXT_DISPLAY)
        val meta = entity.entityMeta as TextDisplayMeta

        val textComponent = Component.text(message)
            .color(NamedTextColor.RED)
            .append(Component.newline())
            .append(Component.text("Pathfinding Failed").color(NamedTextColor.DARK_RED))

        meta.text = textComponent
        meta.isShadow = true
        meta.isSeeThrough = false
        meta.backgroundColor = 0x80FF0000.toInt()
        meta.billboardConstraints = AbstractDisplayMeta.BillboardConstraints.CENTER
        meta.scale = Vector3f(1.5f, 1.5f, 1.5f)
        meta.isSeeThrough = true

        entity.addViewer(player.uniqueId)
        val location = Location(
            position.x + 0.5,
            position.y + 2.0,
            position.z + 0.5,
            0f, 0f
        )
        entity.spawn(location)

        return FailureDisplay(entity)
    }

    private fun handleRejectionTimeouts() {
        val currentTime = System.currentTimeMillis()
        rejectionTimestamps.entries.removeAll { (position, timestamp) ->
            val isExpired = currentTime - timestamp >= REJECTION_TIMEOUT_MS
            if (isExpired) {
                rejectionDisplays[position]?.remove()
                rejectionDisplays.remove(position)
            }
            isExpired
        }
    }

    suspend fun clearAll() {
        updateMutex.withLock {
            stepDisplays.values.forEach { it.remove() }
            stepDisplays.clear()

            rejectionDisplays.values.forEach { it.remove() }
            rejectionDisplays.clear()

            pathDisplays.forEach { it.remove() }
            pathDisplays.clear()

            failureDisplays.forEach { it.remove() }
            failureDisplays.clear()

            rejectionTimestamps.clear()
            lastProcessedStepIndex = -1
        }
    }

    private data class StepInfo(
        val stepIndex: Int,
        val isCurrent: Boolean,
        val isExplored: Boolean,
        val isRejected: Boolean,
        val isCollidingNode: Boolean
    )

    private class StepDisplay(
        private val entity: WrapperEntity,
        private var currentItemType: ItemType,
        private val player: Player,
        private var currentIsCurrent: Boolean,
        private var currentIsCollidingNode: Boolean
    ) {
        private var currentScale = if (currentIsCurrent) Vector3f(0.8f, 0.8f, 0.8f) else Vector3f(0.5f, 0.5f, 0.5f)
        private var isVisible = true

        fun update(
            isCurrent: Boolean,
            isExplored: Boolean,
            isRejected: Boolean,
            isCollidingNode: Boolean,
            isEmphasized: Boolean
        ) {
            val meta = entity.entityMeta as ItemDisplayMeta
            var needsUpdate = false

            val newItemType = when {
                isRejected && isEmphasized -> ItemTypes.RED_CONCRETE
                isRejected -> ItemTypes.RED_STAINED_GLASS
                isExplored && isEmphasized -> ItemTypes.GREEN_CONCRETE
                isExplored -> ItemTypes.GREEN_STAINED_GLASS
                isEmphasized -> ItemTypes.WHITE_CONCRETE
                else -> ItemTypes.GLASS
            }

            if (newItemType != currentItemType) {
                meta.item = PacketItemStack.builder().type(newItemType).amount(1).build()
                currentItemType = newItemType
                needsUpdate = true
            }

            if (isCurrent != currentIsCurrent) {
                val newScale = if (isCurrent) Vector3f(0.8f, 0.8f, 0.8f) else Vector3f(0.5f, 0.5f, 0.5f)
                meta.scale = newScale
                currentScale = Vector3f(newScale.x, newScale.y, newScale.z)
                currentIsCurrent = isCurrent
                needsUpdate = true
            }

            if (isCollidingNode != currentIsCollidingNode) {
                meta.isGlowing = isCollidingNode
                currentIsCollidingNode = isCollidingNode
                needsUpdate = true
            }

            if (needsUpdate) {
                val metaPacket = meta.createPacket()
                metaPacket sendPacketTo player
            }
        }

        fun refreshBlockType(isEmphasized: Boolean) {
            val meta = entity.entityMeta as ItemDisplayMeta

            val newItemType = when (currentItemType) {
                ItemTypes.RED_STAINED_GLASS, ItemTypes.RED_CONCRETE ->
                    if (isEmphasized) ItemTypes.RED_CONCRETE else ItemTypes.RED_STAINED_GLASS

                ItemTypes.GREEN_STAINED_GLASS, ItemTypes.GREEN_CONCRETE ->
                    if (isEmphasized) ItemTypes.GREEN_CONCRETE else ItemTypes.GREEN_STAINED_GLASS

                else ->
                    if (isEmphasized) ItemTypes.WHITE_CONCRETE else ItemTypes.GLASS
            }

            if (newItemType != currentItemType) {
                meta.item = PacketItemStack.builder().type(newItemType).amount(1).build()
                currentItemType = newItemType
                val metaPacket = meta.createPacket()
                metaPacket sendPacketTo player
            }
        }

        fun setVisibility(visible: Boolean) {
            if (visible == isVisible) return

            val meta = entity.entityMeta as ItemDisplayMeta
            meta.isInvisible = !visible
            val metaPacket = meta.createPacket()
            metaPacket sendPacketTo player

            isVisible = visible
        }

        fun remove() {
            entity.remove()
        }
    }

    private class RejectionDisplay(
        private val entity: WrapperEntity,
        private val player: Player,
        private var currentIsCurrent: Boolean
    ) {
        private var currentBackgroundColor = if (currentIsCurrent) 0x60000000 else 0x40000000
        private var currentScale = if (currentIsCurrent) Vector3f(1.2f, 1.2f, 1.2f) else Vector3f(0.8f, 0.8f, 0.8f)

        fun update(isCurrent: Boolean) {
            val meta = entity.entityMeta as TextDisplayMeta
            var needsUpdate = false

            if (isCurrent != currentIsCurrent) {
                val newBackgroundColor = if (isCurrent) 0x60000000 else 0x40000000
                meta.backgroundColor = newBackgroundColor
                currentBackgroundColor = newBackgroundColor

                val newScale = if (isCurrent) Vector3f(1.2f, 1.2f, 1.2f) else Vector3f(0.8f, 0.8f, 0.8f)
                meta.scale = newScale
                currentScale = Vector3f(newScale.x, newScale.y, newScale.z)
                currentIsCurrent = isCurrent
                needsUpdate = true
            }

            if (needsUpdate) {
                val metaPacket = meta.createPacket()
                metaPacket sendPacketTo player
            }
        }

        fun remove() = entity.remove()
    }

    private class PathDisplay(private val entity: WrapperEntity) {
        fun remove() = entity.remove()
    }

    private class FailureDisplay(private val entity: WrapperEntity) {
        fun remove() = entity.remove()
    }
}