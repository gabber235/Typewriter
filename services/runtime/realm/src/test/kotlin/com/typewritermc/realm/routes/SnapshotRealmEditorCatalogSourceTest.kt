package com.typewritermc.realm.routes

import com.typewritermc.realm.catalog.RealmCatalogStore
import com.typewritermc.realm.catalog.installTestCatalog
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.test.runTest
import skirout.editor.v1.catalog.CatalogFetchRequest
import skirout.editor.v1.catalog.CatalogFetchResult
import skirout.editor.v1.catalog.CatalogUnavailableReason
import skirout.editor.v1.catalog.EditorCatalogWireSnapshot
import skirout.editor.v1.catalog.WatchEditorCatalogRequest
import skirout.editor.v1.type_catalog.CatalogGeneration
import java.security.MessageDigest

val SnapshotRealmEditorCatalogSourceTest by testSuite {
    test("fetch returns one coherent full catalog snapshot") {
        runTest {
            val catalogs = RealmCatalogStore()
            catalogs.installTestCatalog("catalog_a")
            try {
                val transfer =
                    SnapshotRealmEditorCatalogSource(
                        catalogs,
                        chunkSize = 32,
                    ).fetch(CatalogFetchRequest(expectedGeneration = null, transferId = "catalog_a"))

                val chunks = listOf(transfer.initial) + transfer.updates
                val first = chunks.first() as CatalogFetchResult.ChunkWrapper
                chunks.size shouldBe first.value.transfer.chunkCount
                chunks.forEachIndexed { index, result ->
                    val value = (result as CatalogFetchResult.ChunkWrapper).value
                    val chunk = value.transfer
                    chunk.transferId shouldBe first.value.transfer.transferId
                    value.generation shouldBe first.value.generation
                    chunk.index shouldBe index
                    chunk.chunkCount shouldBe first.value.transfer.chunkCount
                    chunk.encodedSize shouldBe first.value.transfer.encodedSize
                    chunk.sha256 shouldBe first.value.transfer.sha256
                }
                val encoded =
                    chunks
                        .map {
                            (it as CatalogFetchResult.ChunkWrapper)
                                .value.transfer.payload
                                .toByteArray()
                        }.fold(byteArrayOf()) { combined, bytes -> combined + bytes }
                encoded.size.toLong() shouldBe first.value.transfer.encodedSize
                MessageDigest.getInstance("SHA-256").digest(encoded).toHex() shouldBe first.value.transfer.sha256
                val snapshot = EditorCatalogWireSnapshot.serializer.fromBytes(encoded)
                snapshot.generation.value shouldBe "catalog_a"
                snapshot.types.isNotEmpty() shouldBe true
            } finally {
                catalogs.close()
            }
        }
    }

    test("fetch rejects a stale expected generation without mixing snapshots") {
        runTest {
            val catalogs = RealmCatalogStore()
            catalogs.installTestCatalog("catalog_b")
            try {
                val transfer =
                    SnapshotRealmEditorCatalogSource(catalogs).fetch(
                        CatalogFetchRequest(
                            expectedGeneration = CatalogGeneration(value = "catalog_a"),
                            transferId = "catalog_b",
                        ),
                    )

                val result = transfer.initial as CatalogFetchResult.GenerationChangedWrapper
                result.value.value shouldBe "catalog_b"
                transfer.updates shouldBe emptyList()
            } finally {
                catalogs.close()
            }
        }
    }

    test("overlapping fetches use distinct transfer identities") {
        runTest {
            val catalogs = RealmCatalogStore()
            catalogs.installTestCatalog("catalog_overlap")
            try {
                val source = SnapshotRealmEditorCatalogSource(catalogs, chunkSize = 32)

                val first = source.fetch(CatalogFetchRequest(expectedGeneration = null, transferId = "first"))
                val second = source.fetch(CatalogFetchRequest(expectedGeneration = null, transferId = "second"))

                val firstId = (first.initial as CatalogFetchResult.ChunkWrapper).value.transfer.transferId
                val secondId = (second.initial as CatalogFetchResult.ChunkWrapper).value.transfer.transferId
                (firstId == secondId) shouldBe false
                first.updates.all { (it as CatalogFetchResult.ChunkWrapper).value.transfer.transferId == firstId } shouldBe true
                second.updates.all { (it as CatalogFetchResult.ChunkWrapper).value.transfer.transferId == secondId } shouldBe true
            } finally {
                catalogs.close()
            }
        }
    }

    test("fetch reports capacity before emitting any catalog chunk") {
        runTest {
            val catalogs = RealmCatalogStore()
            catalogs.installTestCatalog("catalog_too_large")
            try {
                val transfer =
                    SnapshotRealmEditorCatalogSource(catalogs, chunkSize = 1, maxChunks = 1)
                        .fetch(CatalogFetchRequest(expectedGeneration = null, transferId = "too_large"))

                val unavailable = (transfer.initial as CatalogFetchResult.UnavailableWrapper).value
                unavailable.generation.value shouldBe "catalog_too_large"
                unavailable.reason shouldBe CatalogUnavailableReason.ENCODED_SIZE_LIMIT
                (unavailable.encodedSize > unavailable.maxEncodedSize) shouldBe true
                unavailable.maxEncodedSize shouldBe 1
                transfer.updates shouldBe emptyList()
            } finally {
                catalogs.close()
            }
        }
    }

    test("catalog watch begins at the captured current generation") {
        runTest {
            val catalogs = RealmCatalogStore()
            catalogs.installTestCatalog("catalog_watch")
            try {
                val result =
                    SnapshotRealmEditorCatalogSource(catalogs)
                        .initialGeneration(WatchEditorCatalogRequest())

                result.generation.value shouldBe "catalog_watch"
            } finally {
                catalogs.close()
            }
        }
    }
}

private fun ByteArray.toHex(): String = joinToString("") { byte -> "%02x".format(byte) }
