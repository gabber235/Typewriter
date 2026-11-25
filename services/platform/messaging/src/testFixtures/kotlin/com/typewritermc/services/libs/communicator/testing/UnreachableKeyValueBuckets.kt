package com.typewritermc.services.libs.communicator.testing

import com.typewritermc.services.libs.communicator.kv.KeyValueBucketDeclaration
import com.typewritermc.services.libs.communicator.kv.KeyValueBuckets
import com.typewritermc.services.libs.communicator.kv.KeyValueOpen

/**
 * Buckets of a connection that reaches no key value store, for tests whose messaging never opens a bucket. Every open
 * fails, so a test that does reach a bucket sees why; tests of bucket behavior use [MemoryKeyValueBuckets], which
 * the bucket contract test holds to a real broker.
 */
object UnreachableKeyValueBuckets : KeyValueBuckets {
    override suspend fun open(name: String): KeyValueOpen =
        KeyValueOpen.Failed(UnsupportedOperationException("This test messaging reaches no bucket: $name"))

    override suspend fun ensure(bucket: KeyValueBucketDeclaration): KeyValueOpen = open(bucket.name)
}
