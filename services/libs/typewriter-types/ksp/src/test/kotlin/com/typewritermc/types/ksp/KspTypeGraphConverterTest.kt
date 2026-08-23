package com.typewritermc.types.ksp

import com.google.devtools.ksp.symbol.ClassKind
import com.google.devtools.ksp.symbol.KSClassDeclaration
import com.google.devtools.ksp.symbol.KSDeclaration
import com.google.devtools.ksp.symbol.KSName
import com.google.devtools.ksp.symbol.KSPropertyDeclaration
import com.google.devtools.ksp.symbol.KSType
import com.google.devtools.ksp.symbol.KSTypeArgument
import com.google.devtools.ksp.symbol.KSTypeParameter
import com.google.devtools.ksp.symbol.KSTypeReference
import com.google.devtools.ksp.symbol.Modifier
import com.google.devtools.ksp.symbol.Nullability
import com.google.devtools.ksp.symbol.Variance
import com.typewritermc.types.IntegerWidth
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.TypeExpression
import com.typewritermc.types.TypeField
import com.typewritermc.types.TypeId
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContainAll
import io.kotest.matchers.shouldBe
import io.mockk.every
import io.mockk.mockk

val KspTypeGraphConverterTest by testSuite {
    test("nullable collections become Option expressions") {
        val string = classType("kotlin.String")
        val list = classType("kotlin.collections.List", nullability = Nullability.NULLABLE, arguments = listOf(argument(string)))

        val result = KspTypeGraphConverter().convert(list) as KspTypeConversionResult.Success

        result.graph.root shouldBe
            TypeExpression.Named(
                StandardTypes.optionOf(TypeExpression.ListType(TypeExpression.StringType())),
            )
        result.graph.definitions.map { it.id } shouldContainAll StandardTypes.definitions.take(3).map { it.id }
    }

    test("recursive classes produce one nominal definition and a reference") {
        val declaration = classDeclaration("example.Node")
        val node = type(declaration)
        val nullableNode = type(declaration, Nullability.NULLABLE)
        every { declaration.getAllProperties() } returns
            sequenceOf(
                property("name", classType("kotlin.String")),
                property("next", nullableNode),
            )

        val result = KspTypeGraphConverter().convert(node) as KspTypeConversionResult.Success
        val nodeDefinition = result.graph.definitions.single { it.id.id == TypeId.Qualified("example", "Node") }

        result.graph.root shouldBe TypeExpression.Named(nodeDefinition.id)
        (nodeDefinition.representation as TypeExpression.Record).fields.map { it.name } shouldBe listOf("name", "next")
    }

    test("generic classes retain parameter expressions while usages carry arguments") {
        val parameter = typeParameter("T")
        val declaration = classDeclaration("example.Box")
        every { declaration.typeParameters } returns listOf(parameter)
        every { declaration.getAllProperties() } returns sequenceOf(property("value", type(parameter)))
        val box = type(declaration, arguments = listOf(argument(classType("kotlin.String"))))

        val result = KspTypeGraphConverter().convert(box) as KspTypeConversionResult.Success
        val definition = result.graph.definitions.single()

        result.graph.root shouldBe TypeExpression.Named(definition.id.withArguments(listOf(TypeExpression.StringType())))
        (definition.representation as TypeExpression.Record).fields.single().type shouldBe TypeExpression.Parameter("T")
    }

    test("records include private inherited fields and exclude properties without storage") {
        val declaration = classDeclaration("example.SerializableRecord")
        every { declaration.getAllProperties() } returns
            sequenceOf(
                property("privateValue", classType("kotlin.String"), modifiers = setOf(Modifier.PRIVATE)),
                property("inheritedValue", classType("kotlin.Int")),
                property("computedValue", classType("kotlin.String"), hasBackingField = false),
                property("delegatedValue", classType("kotlin.String"), delegated = true),
            )

        val result = KspTypeGraphConverter().convert(type(declaration)) as KspTypeConversionResult.Success
        val definition = result.graph.definitions.single()

        (definition.representation as TypeExpression.Record).fields.map(TypeField::name) shouldBe
            listOf("inheritedValue", "privateValue")
    }

    test("function types return a diagnostic instead of throwing") {
        val function = classType("kotlin.Function1")
        every { function.isFunctionType } returns true

        val result = KspTypeGraphConverter().convert(function) as KspTypeConversionResult.Failure

        result.diagnostics.single().message shouldBe "Function types do not have a Typewriter data representation."
    }

    test("BigInteger uses the logical integer representation") {
        val result = KspTypeGraphConverter().convert(classType("java.math.BigInteger")) as KspTypeConversionResult.Success

        result.graph.root shouldBe TypeExpression.Integer(IntegerWidth.SIGNED_64)
        result.graph.definitions shouldBe emptyList()
    }

    test("extension API converts KSP types and extracts successful graphs") {
        val result = classType("kotlin.String").toTypewriterGraph()

        result.getOrThrow().root shouldBe TypeExpression.StringType()
    }
}

private fun classType(
    qualifiedName: String,
    nullability: Nullability = Nullability.NOT_NULL,
    arguments: List<KSTypeArgument> = emptyList(),
): KSType = type(classDeclaration(qualifiedName), nullability, arguments)

private fun type(
    declaration: KSDeclaration,
    nullability: Nullability = Nullability.NOT_NULL,
    arguments: List<KSTypeArgument> = emptyList(),
): KSType =
    mockk {
        every { this@mockk.declaration } returns declaration
        every { this@mockk.nullability } returns nullability
        every { this@mockk.arguments } returns arguments
        every { isError } returns false
        every { isFunctionType } returns false
        every { isSuspendFunctionType } returns false
    }

private fun classDeclaration(qualifiedName: String): KSClassDeclaration {
    val packageName = qualifiedName.substringBeforeLast('.', "example")
    val simpleName = qualifiedName.substringAfterLast('.')
    return mockk {
        every { this@mockk.qualifiedName } returns name(qualifiedName)
        every { this@mockk.packageName } returns name(packageName)
        every { this@mockk.simpleName } returns name(simpleName)
        every { typeParameters } returns emptyList()
        every { superTypes } returns emptySequence()
        every { declarations } returns emptySequence()
        every { getAllProperties() } returns emptySequence()
        every { annotations } returns emptySequence()
        every { modifiers } returns emptySet()
        every { classKind } returns ClassKind.CLASS
    }
}

private fun property(
    propertyName: String,
    propertyType: KSType,
    modifiers: Set<Modifier> = emptySet(),
    hasBackingField: Boolean = true,
    delegated: Boolean = false,
): KSPropertyDeclaration {
    val reference = mockk<KSTypeReference> { every { resolve() } returns propertyType }
    return mockk {
        every { simpleName } returns name(propertyName)
        every { type } returns reference
        every { extensionReceiver } returns null
        every { this@mockk.hasBackingField } returns hasBackingField
        every { isDelegated() } returns delegated
        every { this@mockk.modifiers } returns modifiers
        every { annotations } returns emptySequence()
    }
}

private fun argument(type: KSType): KSTypeArgument {
    val reference = mockk<KSTypeReference> { every { resolve() } returns type }
    return mockk { every { this@mockk.type } returns reference }
}

private fun name(value: String): KSName = mockk { every { asString() } returns value }

private fun typeParameter(parameterName: String): KSTypeParameter =
    mockk {
        every { name } returns name(parameterName)
        every { bounds } returns emptySequence()
        every { variance } returns Variance.INVARIANT
    }
