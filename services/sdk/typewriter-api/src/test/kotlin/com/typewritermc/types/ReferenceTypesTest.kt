package com.typewritermc.types

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe

val ReferenceTypesTest by testSuite {
    test("reference family follows nominal ancestry without serialized kind metadata") {
        val referenceable = qualified("com.typewritermc.types", "Referenceable")
        val element = qualified("com.typewritermc.elements", "Element")
        val concrete = qualified("example", "SpeakerEntry")
        val catalog =
            TypeCatalog(
                listOf(
                    TypeDefinition(referenceable, NominalTypeKind.OPEN_ABSTRACT),
                    TypeDefinition(element, NominalTypeKind.OPEN_ABSTRACT, parents = listOf(referenceable)),
                    TypeDefinition(concrete, NominalTypeKind.CONCRETE, parents = listOf(element)),
                ),
            )

        catalog.referenceFamily(concrete) shouldBe ReferenceFamily.ELEMENT
        catalog.acceptsReferenceCandidate(element, listOf(concrete)) shouldBe true
    }

    test("ambiguous resource ancestry is rejected") {
        val referenceable = qualified("com.typewritermc.types", "Referenceable")
        val book = qualified("com.typewritermc.library", "Book")
        val tag = qualified("com.typewritermc.library", "Tag")
        val ambiguous = qualified("example", "Ambiguous")
        val catalog =
            TypeCatalog(
                listOf(
                    TypeDefinition(referenceable, NominalTypeKind.OPEN_ABSTRACT),
                    TypeDefinition(book, NominalTypeKind.CONCRETE, parents = listOf(referenceable)),
                    TypeDefinition(tag, NominalTypeKind.CONCRETE, parents = listOf(referenceable)),
                    TypeDefinition(ambiguous, NominalTypeKind.CONCRETE, parents = listOf(book, tag)),
                ),
            )

        shouldThrow<IllegalArgumentException> { catalog.referenceFamily(ambiguous) }
    }
}

private fun qualified(
    namespace: String,
    name: String,
): ResolvedTypeRef = ResolvedTypeRef(TypeId.Qualified(namespace, name), revision = 1)
