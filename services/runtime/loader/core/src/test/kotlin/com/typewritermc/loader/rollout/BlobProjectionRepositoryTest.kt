package com.typewritermc.loader.rollout

import com.typewritermc.loader.artifact.toApi
import com.typewritermc.loader.rollout.testing.projection
import com.typewritermc.services.libs.filetransfer.blob.InMemoryBlobEndpoint
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.test.runTest
import skirout.service.v1.rollout.ProjectionReference

val BlobProjectionRepositoryTest by testSuite {
    test("a published projection is fetched back unchanged through its reference") {
        runTest {
            val repository = BlobProjectionRepository(InMemoryBlobEndpoint())
            val projection = projection()

            repository.fetch(repository.publish(projection)) shouldBe projection
        }
    }

    listOf<Pair<String, (ProjectionReference) -> ProjectionReference>>(
        "another Realm" to { it.copy(realmId = "another-realm") },
        "another generation" to { it.copy(generation = it.generation + 1) },
        "another service" to { it.copy(serviceId = "another-service") },
    ).forEach { (owner, retarget) ->
        test("a projection fetched for $owner is refused") {
            runTest {
                val repository = BlobProjectionRepository(InMemoryBlobEndpoint())
                val reference = repository.publish(projection())

                shouldThrow<IllegalArgumentException> { repository.fetch(retarget(reference)) }
            }
        }
    }

    test("a projection whose stored bytes changed is refused by its digest") {
        runTest {
            val blobs = InMemoryBlobEndpoint()
            val repository = BlobProjectionRepository(blobs)
            val reference = repository.publish(projection())
            val digest = reference.blob.toApi()
            blobs.replace(digest, blobs.content(digest).also { it[0] = (it[0] + 1).toByte() })

            shouldThrow<IllegalArgumentException> { repository.fetch(reference) }.message shouldBe
                "Deployment projection digest does not match."
        }
    }

    test("a projection above the projection size limit is refused before it is read") {
        runTest {
            val blobs = InMemoryBlobEndpoint()
            val repository = BlobProjectionRepository(blobs)
            val reference = repository.publish(projection())
            blobs.replace(reference.blob.toApi(), ByteArray(4 * 1024 * 1024 + 1))

            shouldThrow<IllegalArgumentException> { repository.fetch(reference) }.message shouldBe
                "Deployment projection exceeds its maximum size."
        }
    }
}
