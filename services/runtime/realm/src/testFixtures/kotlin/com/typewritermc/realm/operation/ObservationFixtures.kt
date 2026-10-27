package com.typewritermc.realm.operation

import com.typewritermc.realm.authoring.AuthoringLease
import com.typewritermc.realm.authoring.TEST_DEFINITIONS
import com.typewritermc.realm.testing.DefinitionCatalog
import com.typewritermc.realm.testing.RealmFixture
import io.kotest.assertions.throwables.shouldThrow
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.kernel.v1.resource_id.ResourceId

/**
 * The reason a Realm holding [seed] refuses an operation overlay that upserts [upserts] and removes [removals], as the
 * observation of the saved state reports it.
 */
internal suspend fun refusedOverlay(
    seed: Map<ResourceId, AuthoringRecord>,
    upserts: Map<ResourceId, AuthoringRecord> = emptyMap(),
    removals: Set<ResourceId> = emptySet(),
): String? =
    RealmFixture.of(DefinitionCatalog(TEST_DEFINITIONS), seed).use { realm ->
        realm.views.capture().use { lease: AuthoringLease ->
            shouldThrow<IllegalArgumentException> { lease.operationObservation(lease.root.observationId, upserts, removals) }.message
        }
    }
