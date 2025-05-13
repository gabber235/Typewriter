package com.typewritermc.engine.paper.ui

import com.corundumstudio.socketio.AckRequest
import com.corundumstudio.socketio.SocketIOClient
import com.google.gson.Gson
import com.google.gson.JsonArray
import com.google.gson.JsonElement
import com.google.gson.JsonObject
import com.google.gson.annotations.SerializedName
import com.typewritermc.engine.paper.content.ContentContext
import com.typewritermc.engine.paper.content.ContentMode
import com.typewritermc.engine.paper.content.ContentModeTrigger
import com.typewritermc.engine.paper.entry.StagingManager
import com.typewritermc.engine.paper.entry.triggerFor
import com.typewritermc.core.interaction.context
import com.typewritermc.engine.paper.logger
import com.typewritermc.engine.paper.utils.ThreadType.SYNC
import com.typewritermc.loader.ExtensionLoader
import com.typewritermc.core.utils.server
import org.bukkit.entity.Player
import org.koin.core.component.KoinComponent
import org.koin.core.component.inject
import org.koin.core.qualifier.named

class ClientSynchronizer : KoinComponent {
    private val stagingManager: StagingManager by inject()
    private val communicationHandler: CommunicationHandler by inject()
    private val writers: Writers by inject()
    private val extensionLoader: ExtensionLoader by inject()
    private val extensionJson by extensionLoader::extensionJson
    private val gson: Gson by inject(named("bukkitDataParser"))

    fun handleFetchRequest(client: SocketIOClient, data: String, ack: AckRequest) {
        if (data == "pages") {
            val array = JsonArray()
            stagingManager.pages.forEach { (_, page) ->
                array.add(page)
            }
            ack.sendAckData(array.toString())
        } else if (data == "extensions") {
            ack.sendAckData(extensionJson.toString())
        }

        ack.sendAckData("No data found")
    }

    fun handleCreatePage(client: SocketIOClient, data: String, ack: AckRequest) {
        val json = gson.fromJson(data, JsonObject::class.java)
        val result = stagingManager.createPage(json)

        ack.sendResult(result) {
            communicationHandler.server?.broadcastOperations?.sendEvent("createPage", client, data)
        }
    }

    fun handleRenamePage(client: SocketIOClient, data: String, ackRequest: AckRequest) {
        val json = gson.fromJson(data, PageRename::class.java)
        val result = stagingManager.renamePage(json.pageId, json.new)

        ackRequest.sendResult(result) {
            communicationHandler.server?.broadcastOperations?.sendEvent("renamePage", client, data)
        }
    }

    fun handleChangePageValue(client: SocketIOClient, data: String, ackRequest: AckRequest) {
        val json = gson.fromJson(data, PageValueUpdate::class.java)
        val result = stagingManager.changePageValue(json.pageId, json.path, json.value)

        ackRequest.sendResult(result) {
            communicationHandler.server?.broadcastOperations?.sendEvent("changePageValue", client, data)
        }
    }

    fun handleDeletePage(client: SocketIOClient, pageId: String, ack: AckRequest) {
        val result = stagingManager.deletePage(pageId)
        ack.sendResult(result) {
            communicationHandler.server?.broadcastOperations?.sendEvent("deletePage", client, pageId)
        }
    }

    fun handleMoveEntry(client: SocketIOClient, data: String, ack: AckRequest) {
        val (entryId, fromPageId, toPageId) = gson.fromJson(data, MoveEntry::class.java)
        val result = stagingManager.moveEntry(entryId, fromPageId, toPageId)
        ack.sendResult(result) {
            communicationHandler.server?.broadcastOperations?.sendEvent("moveEntry", client, data)
        }
    }

    fun handleCreateEntry(client: SocketIOClient, data: String, ack: AckRequest) {
        val json = gson.fromJson(data, EntryCreate::class.java)
        val result = stagingManager.createEntry(json.pageId, json.entry)
        ack.sendResult(result) {
            communicationHandler.server?.broadcastOperations?.sendEvent("createEntry", client, data)
        }
    }

    fun handleEntryFieldUpdate(client: SocketIOClient, data: String, ack: AckRequest) {
        val update = gson.fromJson(data, EntryUpdate::class.java)
        val result = stagingManager.updateEntryField(update.pageId, update.entryId, update.path, update.value)
        ack.sendResult(result) {
            communicationHandler.server?.broadcastOperations?.sendEvent("updateEntry", client, data)
        }
    }

    fun handleEntryUpdate(client: SocketIOClient, data: String, ack: AckRequest) {
        val update = gson.fromJson(data, CompleteEntryUpdate::class.java)
        val result = stagingManager.updateEntry(update.pageId, update.entry)
        ack.sendResult(result) {
            communicationHandler.server?.broadcastOperations?.sendEvent("updateCompleteEntry", client, data)
        }
    }

    fun handleReorderEntry(client: SocketIOClient, data: String, ack: AckRequest) {
        val update = gson.fromJson(data, ReorderEntry::class.java)
        val result = stagingManager.reorderEntry(update.pageId, update.entryId, update.newIndex)
        ack.sendResult(result) {
            communicationHandler.server?.broadcastOperations?.sendEvent("reorderEntry", client, data)
        }
    }


    fun handleDeleteEntry(client: SocketIOClient, data: String, ack: AckRequest) {
        val json = gson.fromJson(data, EntryDelete::class.java)
        val result = stagingManager.deleteEntry(json.pageId, json.entryId)
        ack.sendResult(result) {
            communicationHandler.server?.broadcastOperations?.sendEvent("deleteEntry", client, data)
        }
    }

    fun handlePublish(client: SocketIOClient, data: String, ack: AckRequest) {
        SYNC.launch {
            val result = stagingManager.publish()
            ack.sendResult(result)
        }
    }

    fun handleUpdateWriter(client: SocketIOClient, data: String, ack: AckRequest) {
        writers.updateWriter(client.sessionId.toString(), data)
        communicationHandler.server.broadcastWriters(writers)
        ack.sendResult(Result.success("Writer updated"))
    }

    fun handleContentModeRequest(client: SocketIOClient, data: String, ack: AckRequest) {
        val request = gson.fromJson(data, ContentModeRequest::class.java)

        var player = communicationHandler.getPlayer(client)
        if (player == null) {
            // If we have authentication enabled, we don't want to fallback as it could be a security issue.
            if (communicationHandler.authenticationEnabled) {
                ack.sendResult(Result.failure(Exception("Could not determine player")))
                return
            }

            // If we have no authentication, we can assume that it's a local server,
            // and we can fall back to the first player.

            val onlinePlayers = server.onlinePlayers
            if (onlinePlayers.isEmpty()) {
                ack.sendResult(Result.failure(Exception("No players online to start content mode")))
                return
            }

            if (onlinePlayers.size > 1) {
                ack.sendResult(Result.failure(Exception("Could not determine player to record")))
                return
            }

            player = onlinePlayers.first()
            logger.warning("Could not determine player from session, using ${player.name}")
        }

        if (player == null) {
            ack.sendResult(Result.failure(Exception("Could not determine player")))
            return
        }

        val context = ContentContext(request.data)
        try {
            val clazz = extensionLoader.loadClass(request.contentModeClassName)
            // Find the constructor with a context and player parameter
            val constructor = clazz.getConstructor(ContentContext::class.java, Player::class.java)
            val mode = constructor.newInstance(context, player)
            if (mode !is ContentMode) {
                ack.sendResult(Result.failure(Exception("Content mode class ${request.contentModeClassName} does not implement ContentMode")))
                return
            }

            ContentModeTrigger(context, mode).triggerFor(player, context())
        } catch (e: ClassNotFoundException) {
            ack.sendResult(Result.failure(Exception("Could not find content mode class ${request.contentModeClassName}")))
            e.printStackTrace()
            return
        } catch (e: NoSuchMethodException) {
            ack.sendResult(Result.failure(Exception("Could not find constructor (ContentContext, Player) for content mode class ${request.contentModeClassName}")))
            e.printStackTrace()
            return
        }
    }

    fun sendEntryFieldUpdate(pageId: String, entryId: String, fieldPath: String, data: JsonElement) {
        val update = EntryUpdate(pageId, entryId, fieldPath, data)
        val updateData = gson.toJson(update)
        communicationHandler.server?.broadcastOperations?.sendEvent("updateEntry", updateData)
    }
}

fun AckRequest.sendResult(result: Result<String>) {
    val json = JsonObject()
    json.addProperty("success", result.isSuccess)
    json.addProperty("message", result.getOrElse { it.message })

    sendAckData(json.toString())

    if (result.isFailure) {
        logger.severe(result.exceptionOrNull()?.message)
    }
}

inline fun AckRequest.sendResult(result: Result<String>, onSuccess: () -> Unit) {
    sendResult(result)
    if (result.isSuccess) {
        onSuccess()
    }
}

private data class PageRename(val pageId: String, val new: String)

private data class PageValueUpdate(
    val pageId: String,
    val path: String,
    val value: JsonElement
)

private data class MoveEntry(
    val entryId: String,
    val fromPageId: String,
    val toPageId: String,
)


private data class EntryCreate(
    val pageId: String,
    val entry: JsonObject,
)

private data class EntryUpdate(
    val pageId: String,
    val entryId: String,
    val path: String,
    val value: JsonElement
)

private data class CompleteEntryUpdate(
    val pageId: String,
    val entry: JsonObject,
)

private data class ReorderEntry(
    val pageId: String,
    val entryId: String,
    val newIndex: Int,
)

private data class EntryDelete(
    val pageId: String,
    val entryId: String,
)

private data class ContentModeRequest(
    @SerializedName("contentMode")
    val contentModeClassName: String,
    val data: Map<String, Any>,
)