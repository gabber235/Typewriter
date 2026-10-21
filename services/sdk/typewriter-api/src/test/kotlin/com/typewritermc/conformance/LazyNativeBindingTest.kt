@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.conformance

import com.typewritermc.authoring.AppliedNativeArguments
import com.typewritermc.authoring.CompletenessResult
import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.authoring.bind
import com.typewritermc.authoring.complete
import com.typewritermc.authoring.map
import com.typewritermc.types.FactoryNativeBindingRegistry
import com.typewritermc.types.GeneratedRecordNativeBinding
import com.typewritermc.types.NativeBinding
import com.typewritermc.types.NativeBindingFactory
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.catalog.CheckedType
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.catalog.resolve
import com.typewritermc.types.nullable
import com.typewritermc.types.qualified
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.NativeBindingId
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import java.util.concurrent.atomic.AtomicInteger

val LazyNativeBindingTest by testSuite {
    test("null and empty containers do not bind unused native children on encode or decode") {
        val childId = TypeDefinitionId.qualified("lazy", "Child")
        val child =
            TypeDefinition.partial(
                id = childId,
                representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = false),
            )
        val calls = AtomicInteger()
        val factory =
            object : NativeBindingFactory {
                override val definition = childId
                override val provider = NativeBindingId(value = "test.lazyChild")

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
        val catalog = DefaultCheckedCatalog(CatalogGeneration(value = "lazy"), StandardTypes.definitions + child)
        val registry = FactoryNativeBindingRegistry(catalog, listOf(factory))
        val childUse = childId.use()
        val cases =
            listOf(
                childUse.nullable() to null,
                StandardTypes.list.use(listOf(childUse)) to emptyList<Any>(),
                StandardTypes.set.use(listOf(childUse)) to emptySet<Any>(),
                StandardTypes.map.use(listOf(childUse, childUse)) to emptyMap<Any, Any>(),
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
