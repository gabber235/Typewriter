package com.typewritermc.conformance

import com.typewritermc.authoring.AppliedNativeArguments
import com.typewritermc.authoring.CompletenessResult
import com.typewritermc.authoring.NativeBindingId
import com.typewritermc.authoring.bind
import com.typewritermc.authoring.complete
import com.typewritermc.authoring.map
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.types.FactoryNativeBindingRegistry
import com.typewritermc.types.GeneratedRecordNativeBinding
import com.typewritermc.types.NativeBinding
import com.typewritermc.types.NativeBindingFactory
import com.typewritermc.types.RepresentationTemplate
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.TypeDefinition
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.TypeId
import com.typewritermc.types.TypeUse
import com.typewritermc.types.catalog.CheckedType
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.catalog.resolve
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import java.util.concurrent.atomic.AtomicInteger

val LazyNativeBindingTest by testSuite {
    test("null and empty containers do not bind unused native children on encode or decode") {
        val childId = TypeDefinitionId(TypeId.Qualified("lazy", "Child"), 1)
        val child = TypeDefinition(childId, representation = RepresentationTemplate.Record(emptyList()))
        val calls = AtomicInteger()
        val factory =
            object : NativeBindingFactory {
                override val definition = childId
                override val provider = NativeBindingId("test.lazyChild")

                override fun bind(
                    actual: CheckedType,
                    arguments: AppliedNativeArguments,
                ): NativeBinding<*> {
                    calls.incrementAndGet()
                    return GeneratedRecordNativeBinding<Any>(
                        actual,
                        provider,
                        "test.lazyChild",
                        fields = emptyList(),
                        construct = { Any() },
                    )
                }
            }
        val catalog = DefaultCheckedCatalog(CatalogGeneration("lazy"), StandardTypes.definitions + child)
        val registry = FactoryNativeBindingRegistry(catalog, listOf(factory))
        val childUse = TypeUse.Named(childId)
        val cases =
            listOf(
                TypeUse.Nullable(childUse) to null,
                TypeUse.Named(StandardTypes.list, listOf(childUse)) to emptyList<Any>(),
                TypeUse.Named(StandardTypes.set, listOf(childUse)) to emptySet<Any>(),
                TypeUse.Named(StandardTypes.map, listOf(childUse, childUse)) to emptyMap<Any, Any>(),
            )
        cases.forEach { (use, original) ->
            val checked = (catalog.resolve(use) as Resolution.Ready).value

            @Suppress("UNCHECKED_CAST")
            val binding = registry.bind(checked) as NativeBinding<Any?>
            val encoded = binding.encode(original)
            val complete = (checked.complete(encoded) as CompletenessResult.Complete).value
            binding.decode(complete) shouldBe original
            calls.get() shouldBe 0
        }
    }
}
