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

val RealmCapabilityRuntimeTest by testSuite {
    val request = TypeDefinitionId.qualified("test", "Request")
    val catalog =
        DefaultCheckedCatalog(
            CatalogGeneration(value = "capabilities"),
            StandardTypes.definitions +
                TypeDefinition.partial(
                    id = request,
                    representation =
                        RepresentationTemplate.createRecord(
                            fields =
                                listOf(
                                    FieldDeclaration.partial(
                                        owner = FieldOwner(definition = request, name = "query"),
                                        type = ScalarKind.TEXT.template,
                                    ),
                                ),
                            abstract_ = false,
                        ),
                ),
        )
    val runtime = RealmCapabilityRuntime(catalog, FactoryNativeBindingRegistry(catalog, emptyList()))

    test("a complete capability payload decodes to its native value") {
        runtime.decode<String>(ScalarKind.TEXT.use, DataValue.StringValueWrapper("books")) shouldBe "books"
    }

    mapOf(
        "an unfinished payload" to
            (
                Triple(
                    request.namedUse().use,
                    DataValue.named(request.namedUse(), DataValue.record(mapOf("query" to DataValue.UNFILLED))),
                    "unfinished_capability_value",
                )
            ),
        "a payload of another type" to (Triple(ScalarKind.TEXT.use, DataValue.BooleanWrapper(true), "invalid_capability_value")),
        "a payload of an undeclared type" to
            (
                Triple(
                    TypeDefinitionId.qualified("test", "Undeclared").namedUse().use,
                    DataValue.record(emptyMap()),
                    "unresolved_capability_type",
                )
            ),
    ).forEach { (case, rejection) ->
        test("decoding $case is refused") {
            shouldThrow<NativeBindingException> { runtime.decode<Any>(rejection.first, rejection.second) }.code shouldBe rejection.third
        }
    }

    val lookup = ComputationProvider(CapabilityId(value = "test.lookup"))

    test("a capability registry refuses two capabilities with one id") {
        shouldThrow<IllegalArgumentException> { RealmCapabilityRegistry(listOf(lookup, lookup)) }.message shouldBe
            "Realm capability ids must be unique."
    }

    test("asking a registry for a capability as the wrong kind fails") {
        val registry = RealmCapabilityRegistry(listOf(lookup))

        registry.requireComputation(lookup.descriptor.capabilityId) shouldBe lookup
        shouldThrow<IllegalArgumentException> { registry.requireSearch(lookup.descriptor.capabilityId) }.message shouldBe
            "Realm search capability is unavailable: test.lookup"
        shouldThrow<IllegalArgumentException> { registry.requireCommand(lookup.descriptor.capabilityId) }.message shouldBe
            "Realm command capability is unavailable: test.lookup"
    }
}

private class ComputationProvider(
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
