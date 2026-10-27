package com.typewritermc.capability

import com.typewritermc.types.FactoryNativeBindingRegistry
import com.typewritermc.types.NativeBindingException
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import com.typewritermc.types.named
import com.typewritermc.types.namedUse
import com.typewritermc.types.qualified
import com.typewritermc.types.record
import com.typewritermc.types.template
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import skirout.editor.v1.capability.ComputationCapabilityDefinition
import skirout.editor.v1.capability.SearchCapabilityDefinition
import skirout.editor.v1.type_catalog.CapabilityId
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.FieldDeclaration
import skirout.editor.v1.type_catalog.FieldOwner
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId

internal class ComputationProvider(
    id: CapabilityId,
) : RealmComputationCapabilityProvider {
    override val descriptor =
        ComputationCapabilityDefinition(capabilityId = id, requestType = ScalarKind.TEXT.use, resultType = ScalarKind.TEXT.use)

    override suspend fun invoke(
        context: RealmComputationContext,
        runtime: RealmCapabilityRuntime,
        payload: DataValue,
    ): DataValue = payload
}
