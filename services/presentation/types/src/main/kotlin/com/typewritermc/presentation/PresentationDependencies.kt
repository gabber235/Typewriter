package com.typewritermc.presentation

import build.skir.reflection.ArrayDescriptor
import build.skir.reflection.EnumDescriptor
import build.skir.reflection.OptionalDescriptor
import build.skir.reflection.ReflectiveTransformer
import build.skir.reflection.ReflectiveTypeVisitor
import build.skir.reflection.StructDescriptor
import build.skir.reflection.TypeDescriptor
import build.skir.reflection.TypeEquivalence
import com.typewritermc.capability.CapabilityId
import com.typewritermc.types.ConversionId
import com.typewritermc.types.PresentationId
import com.typewritermc.types.ResolvedTypeRef
import com.typewritermc.types.skir.SkirTypeCodec
import com.typewritermc.types.skir.getOrThrow
import skirout.editor.v1.presentation.PresentationNode
import skirout.editor.v1.type_catalog.CapabilityId as SkirCapabilityId
import skirout.editor.v1.type_catalog.ConversionId as SkirConversionId
import skirout.editor.v1.type_catalog.PresentationId as SkirPresentationId
import skirout.editor.v1.type_catalog.ResolvedTypeRef as SkirResolvedTypeRef

data class PresentationDependencies(
    val types: Set<ResolvedTypeRef> = emptySet(),
    val presentations: Set<PresentationId> = emptySet(),
    val conversions: Set<ConversionId> = emptySet(),
    val capabilities: Set<CapabilityId> = emptySet(),
)

internal fun collectPresentationDependencies(
    root: PresentationNode,
    target: ResolvedTypeRef,
): PresentationDependencies {
    val collector = PresentationDependencyCollector()
    collector.transform(root, PresentationNode.serializer.typeDescriptor)
    val dependencies = collector.dependencies()
    return dependencies.copy(types = dependencies.types + target)
}

internal fun PresentationDependencies.toWire(): skirout.editor.v1.presentation.PresentationDependencies =
    skirout.editor.v1.presentation.PresentationDependencies(
        types = types.sortedBy(ResolvedTypeRef::toString).map { SkirTypeCodec.encode(it).getOrThrow() },
        presentations =
            presentations.sortedBy { "${it.namespace}/${it.name}" }.map {
                SkirPresentationId(namespace = it.namespace, name = it.name)
            },
        conversions =
            conversions.sortedBy { "${it.namespace}/${it.name}" }.map {
                SkirConversionId(namespace = it.namespace, name = it.name)
            },
        capabilities = capabilities.sortedBy(CapabilityId::value).map { SkirCapabilityId(value = it.value) },
    )

private class PresentationDependencyCollector : ReflectiveTransformer {
    private val types = linkedSetOf<ResolvedTypeRef>()
    private val presentations = linkedSetOf<PresentationId>()
    private val conversions = linkedSetOf<ConversionId>()
    private val capabilities = linkedSetOf<CapabilityId>()

    fun dependencies(): PresentationDependencies =
        PresentationDependencies(
            types = types.toSet(),
            presentations = presentations.toSet(),
            conversions = conversions.toSet(),
            capabilities = capabilities.toSet(),
        )

    override fun <T> transform(
        input: T,
        descriptor: TypeDescriptor.Reflective<T>,
    ): T {
        descriptor.accept(
            object : ReflectiveTypeVisitor.Noop<T>() {
                override fun <Mutable> visitStruct(descriptor: StructDescriptor.Reflective<T, Mutable>) {
                    collectRecord(descriptor.modulePath, descriptor.qualifiedName, input)
                    descriptor.mapFields(input, this@PresentationDependencyCollector)
                }

                override fun visitEnum(descriptor: EnumDescriptor.Reflective<T>) {
                    descriptor.mapValue(input, this@PresentationDependencyCollector)
                }

                override fun <NotNull : Any> visitOptional(
                    descriptor: OptionalDescriptor.Reflective<NotNull>,
                    equivalence: TypeEquivalence<T, NotNull?>,
                ) {
                    descriptor.map(equivalence.fromT(input), this@PresentationDependencyCollector)
                }

                override fun <Other : Any> visitJavaOptional(
                    descriptor: OptionalDescriptor.JavaReflective<Other>,
                    equivalence: TypeEquivalence<T, java.util.Optional<Other>>,
                ) {
                    descriptor.map(equivalence.fromT(input), this@PresentationDependencyCollector)
                }

                override fun <Element, ListType : List<Element>> visitArray(
                    descriptor: ArrayDescriptor.Reflective<Element, ListType>,
                    equivalence: TypeEquivalence<T, ListType>,
                ) {
                    descriptor.map(equivalence.fromT(input), this@PresentationDependencyCollector)
                }
            },
        )
        return input
    }

    private fun collectRecord(
        modulePath: String,
        qualifiedName: String,
        input: Any?,
    ) {
        if (modulePath != TYPE_CATALOG_MODULE) return
        when (qualifiedName) {
            "ResolvedTypeRef" -> {
                types += SkirTypeCodec.decode(input as SkirResolvedTypeRef).getOrThrow()
            }

            "PresentationId" -> {
                val id = input as SkirPresentationId
                presentations += PresentationId(id.namespace, id.name)
            }

            "ConversionId" -> {
                val id = input as SkirConversionId
                conversions += ConversionId(id.namespace, id.name)
            }

            "CapabilityId" -> {
                capabilities += CapabilityId((input as SkirCapabilityId).value)
            }
        }
    }
}

private const val TYPE_CATALOG_MODULE = "editor/v1/type_catalog.skir"
