@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.realm.authoring

import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.authoring.fieldMap
import com.typewritermc.authoring.of
import com.typewritermc.checking.InputIdentity
import com.typewritermc.realm.testing.DefinitionCatalog
import com.typewritermc.realm.testing.RealmFixture
import com.typewritermc.types.fields
import com.typewritermc.types.named
import com.typewritermc.types.namedUse
import com.typewritermc.types.qualified
import com.typewritermc.types.use
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.kernel.v1.resource_id.ResourceId

internal val REPRESENTATION_TYPE = TypeDefinitionId.qualified("test", "text_representation")
internal val REPRESENTATION_DEFINITION =
    TypeDefinition.partial(id = REPRESENTATION_TYPE, representation = RepresentationTemplate.createScalar(kind = ScalarKind.TEXT))

internal val PROJECTION = ResourceId(value = "projection")
internal val NULL_VALUE = location(PROJECTION, "nullValue")
internal val MISSING_VALUE = location(PROJECTION, "missingValue")
internal val REPRESENTATION_VALUE = location(PROJECTION, "representation")

/** Runs [block] on fresh reads of one resource with an authored null, an unfilled value and a representation. */
internal suspend fun <T> projection(block: (CapturedAuthoringReads) -> T): T {
    val authored =
        AuthoringRecord.of(
            configuration = TypeSelection.of(TEST_TYPE),
            fields =
                record(count = 7, numbers = listOf("item" to 7)).fieldMap +
                    ("nullValue" to DataValue.NULL) +
                    ("missingValue" to DataValue.UNFILLED) +
                    ("representation" to DataValue.named(REPRESENTATION_TYPE.namedUse(), DataValue.StringValueWrapper("value"))),
        )
    return captured(mapOf(PROJECTION to authored), DefinitionCatalog(TEST_DEFINITIONS + REPRESENTATION_DEFINITION)) { lease ->
        block(CapturedAuthoringReads(lease.originalView()))
    }
}

/**
 * Runs [block] on a capture of the saved view of a Realm on [catalog] that starts with [resources] saved, then closes
 * the capture and the Realm.
 */
internal suspend fun <T> captured(
    resources: Map<ResourceId, AuthoringRecord>,
    catalog: DefinitionCatalog = DefinitionCatalog(TEST_DEFINITIONS),
    block: (AuthoringLease) -> T,
): T = RealmFixture.of(catalog, resources).use { realm -> realm.views.capture().use(block) }

/**
 * The record facts the reads [read] makes on a projection depend on, as each read observed them. Every read also reads
 * the catalog, which is the same for every read of one generation.
 */
internal suspend fun dependenciesOf(read: (CapturedAuthoringReads) -> Unit): Set<InputIdentity> =
    projection { reads ->
        read(reads)
        reads.observedInputs().filterNotTo(linkedSetOf()) { it is InputIdentity.Catalog }
    }
