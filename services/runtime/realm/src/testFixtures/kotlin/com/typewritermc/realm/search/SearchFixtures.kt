package com.typewritermc.realm.search

import com.typewritermc.authoring.RealmRootDefinition
import com.typewritermc.authoring.of
import com.typewritermc.library.LibraryDefinition
import com.typewritermc.library.TaxonomyDefinition
import com.typewritermc.realm.testing.DefinitionCatalog
import com.typewritermc.realm.testing.RealmFixture
import com.typewritermc.realm.testing.RealmStorage
import com.typewritermc.realm.testing.shouldBeCommitted
import com.typewritermc.testkit.definitions
import com.typewritermc.types.listValue
import com.typewritermc.types.mapValue
import com.typewritermc.types.named
import com.typewritermc.types.namedTemplate
import com.typewritermc.types.namedUse
import com.typewritermc.types.qualified
import com.typewritermc.types.record
import com.typewritermc.types.setValue
import com.typewritermc.types.template
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import skirout.editor.v1.authoring.EditIntent
import skirout.editor.v1.type_catalog.ArgumentSelection
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.ListItem
import skirout.editor.v1.type_catalog.MapRow
import skirout.editor.v1.type_catalog.ParameterKey
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeParameter
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.kernel.v1.resource_id.ResourceId

internal fun definition(name: String): TypeDefinitionId = TypeDefinitionId.qualified("test", name)

/** Creates [id] as an empty resource of [type]. */
internal fun create(
    id: String,
    type: skirout.editor.v1.type_catalog.NamedTypeUse,
) = EditIntent.createCreateResource(
    id = ResourceId(value = id),
    record = AuthoringRecord.of(TypeSelection.CompleteWrapper(type), emptyMap()),
)
