package com.typewritermc.expression

import com.typewritermc.authoring.root
import com.typewritermc.configuration.PortableExpressionChecker
import com.typewritermc.configuration.ruleProfileViolations
import com.typewritermc.expression.operations.CheckFailure
import com.typewritermc.expression.operations.RoundingMode
import com.typewritermc.expression.operations.toDataValue
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import com.typewritermc.types.catalog.resolve
import com.typewritermc.types.floatScalar
import com.typewritermc.types.integer
import com.typewritermc.types.integerScalar
import com.typewritermc.types.qualified
import com.typewritermc.types.template
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import skirout.editor.v1.expression.ExpressionNode
import skirout.editor.v1.expression.OperationId
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.ExpressionBindingId
import skirout.editor.v1.type_catalog.FieldDeclaration
import skirout.editor.v1.type_catalog.FieldOwner
import skirout.editor.v1.type_catalog.FloatWidth
import skirout.editor.v1.type_catalog.IntegerWidth
import skirout.editor.v1.type_catalog.ParameterKey
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeTemplate
import skirout.editor.v1.type_catalog.ValuePath

val PortableExpressionCheckingTest by testSuite {
    val profileId = TypeDefinitionId.qualified("test", "Profile")
    val profile =
        TypeDefinition.partial(
            id = profileId,
            representation =
                RepresentationTemplate.createRecord(
                    fields =
                        listOf(
                            FieldDeclaration.partial(
                                owner = FieldOwner(definition = profileId, name = "title"),
                                type = ScalarKind.TEXT.template,
                            ),
                        ),
                    abstract_ = false,
                ),
        )
    val catalog = DefaultCheckedCatalog(CatalogGeneration(value = "expression calls"), listOf(profile))
    val checker = PortableExpressionChecker(catalog::resolve)
    val candidate = ExpressionBindingId(value = "candidate")
    val parent = ExpressionBindingId(value = "parent")
    val text = ScalarKind.TEXT.use
    val decimal = ScalarKind.DECIMAL.use
    val floating = floatScalar(FloatWidth.THIRTY_TWO).use
    val int32 = integerScalar(IntegerWidth.SIGNED_THIRTY_TWO).use
    val mode = checkLiteral(RoundingMode.Floor.toDataValue())

    fun read(id: ExpressionBindingId) = checkInput(id)

    test("an unused generic ambient binding does not postpone checking a concrete candidate") {
        val generic = ParameterKey(owner = TypeDefinitionId.qualified("test", "GenericAmbient"), index = 0).template
        val concrete = integerScalar(IntegerWidth.SIGNED_THIRTY_TWO).template
        val bindings = mapOf(parent to generic, candidate to concrete)
        com.typewritermc.presentation.checkPresentationExpression(
            read(candidate),
            bindings,
            concrete,
            setOf(candidate),
            catalog::resolve,
        ) shouldBe emptyList()
        val trimmed = checkCall("text.trim_start", read(candidate))
        com.typewritermc.presentation
            .checkPresentationExpression(trimmed, bindings, concrete, setOf(candidate), catalog::resolve)
            .isNotEmpty() shouldBe true
    }

    test("rounding keeps the declared unsigned width and the missing increment") {
        val unsigned = integerScalar(IntegerWidth.UNSIGNED_SIXTY_FOUR).use
        val expression = checkCall("number.round", read(candidate), read(parent), mode)
        val inputs = mapOf(candidate to nominalExpressionType(unsigned), parent to nominalExpressionType(unsigned, true))
        checker.checkExpressionCodes(expression, inputs, nominalExpressionType(unsigned, true)) shouldBe emptyList()
        checker.checkExpressionCodes(expression, inputs, nominalExpressionType(unsigned)) shouldBe
            listOf(CheckFailure.ExpressionResultMayBeMissing)
    }

    test("a literal increment adopts the decimal family of the candidate") {
        checker.checkExpressionCodes(
            checkCall("number.round", read(candidate), checkLiteral(DataValue.DecimalWrapper("0.01")), mode),
            mapOf(candidate to nominalExpressionType(decimal)),
            nominalExpressionType(decimal),
        ) shouldBe emptyList()
    }

    test("a literal increment adopts the narrow float width of the candidate") {
        checker.checkExpressionCodes(
            checkCall("number.round", read(candidate), checkLiteral(DataValue.FloatWrapper(0.5)), mode),
            mapOf(candidate to nominalExpressionType(floating)),
            nominalExpressionType(floating),
        ) shouldBe emptyList()
    }

    test("numbers of different families do not mix") {
        checker.checkExpressionCodes(
            checkCall("number.round", read(candidate), checkLiteral(DataValue.DecimalWrapper("0.5")), mode),
            mapOf(candidate to nominalExpressionType(floating)),
            nominalExpressionType(floating),
        ) shouldBe listOf(CheckFailure.NumericFamilyMismatch)
    }

    test("the widest operand decides the width of a numeric result") {
        val narrow = integerScalar(IntegerWidth.SIGNED_EIGHT).use
        val bindings = mapOf(candidate to nominalExpressionType(narrow), parent to nominalExpressionType(int32))
        val sum = checkCall("number.add", read(candidate), read(parent))
        checker.checkExpressionCodes(sum, bindings, nominalExpressionType(int32)) shouldBe emptyList()
        checker.checkExpressionCodes(sum, bindings, nominalExpressionType(narrow)) shouldBe
            listOf(CheckFailure.IncompatibleExpressionResultType)
    }

    test("a wider declared source does not narrow implicitly") {
        checker.checkExpressionCodes(
            read(parent),
            mapOf(parent to nominalExpressionType(floatScalar(FloatWidth.SIXTY_FOUR).use)),
            nominalExpressionType(floating),
        ) shouldBe listOf(CheckFailure.IncompatibleExpressionResultType)
    }

    test("a fallback handles a missing parent explicitly") {
        val bindings = mapOf(candidate to nominalExpressionType(text), parent to nominalExpressionType(text, true))
        checker.checkExpressionCodes(read(parent), bindings, nominalExpressionType(text)) shouldBe
            listOf(CheckFailure.ExpressionResultMayBeMissing)
        checker.checkExpressionCodes(
            ExpressionNode.createOrElse(value = read(parent), fallback = read(candidate)),
            bindings,
            nominalExpressionType(text),
        ) shouldBe emptyList()
    }

    test("an unknown binding is reported") {
        checker.checkExpressionCodes(read(candidate), emptyMap(), nominalExpressionType(text)) shouldBe
            listOf(CheckFailure.UnknownExpressionBinding)
    }

    test("an argument must fit its declared parameter") {
        checker.checkExpressionCodes(
            checkCall("boolean.not", checkLiteral(DataValue.StringValueWrapper("yes"))),
            emptyMap(),
            nominalExpressionType(ScalarKind.BOOLEAN.use),
        ) shouldBe listOf(CheckFailure.InvalidOperandType)
    }

    test("a call names a declared operation with its declared arity") {
        val one = checkLiteral(DataValue.integer(java.math.BigInteger.ONE))
        checker.checkExpressionStructure(checkCall("integer.lcm", one, one), emptySet()) shouldBe listOf(CheckFailure.UnknownOperation)
        checker.checkExpressionStructure(checkCall("integer.gcd", one), emptySet()) shouldBe listOf(CheckFailure.InvalidArgumentCount)
        checker.checkExpressionStructure(checkCall("number.add", one, one, one, one), emptySet()) shouldBe emptyList()
    }

    test("lambdas appear exactly at lambda parameters with the declared arity") {
        val source = checkInput(candidate)
        val bindings = setOf(candidate)
        val accept = checkLiteral(DataValue.BooleanWrapper(true))
        val predicate = checkLambda(1, accept)
        checker.checkExpressionStructure(checkCall("collection.filter", source, predicate), bindings) shouldBe emptyList()
        checker.checkExpressionStructure(checkCall("collection.filter", source, checkLambda(2, accept)), bindings) shouldBe
            listOf(CheckFailure.InvalidLambda)
        checker.checkExpressionStructure(checkCall("collection.filter", source, accept), bindings) shouldBe
            listOf(CheckFailure.InvalidLambda)
        checker.checkExpressionStructure(checkCall("boolean.not", predicate), bindings) shouldBe listOf(CheckFailure.InvalidLambda)
        checker.checkExpressionStructure(predicate, bindings) shouldBe listOf(CheckFailure.InvalidLambda)
    }

    test("explicit type arguments are closed resolvable types of the declared count") {
        fun convert(arguments: List<TypeTemplate>) = checkCall("number.convert", read(candidate), typeArguments = arguments)
        val narrow = integerScalar(IntegerWidth.SIGNED_EIGHT)
        val bindings = mapOf(candidate to nominalExpressionType(int32))
        checker.checkExpressionCodes(convert(listOf(narrow.template)), bindings, nominalExpressionType(narrow.use)) shouldBe emptyList()
        checker.checkExpressionCodes(convert(emptyList()), bindings, nominalExpressionType(narrow.use)) shouldBe
            listOf(CheckFailure.InvalidTypeArgument)
        checker.checkExpressionCodes(convert(listOf(ScalarKind.TEXT.template)), bindings, nominalExpressionType(text)) shouldBe
            listOf(CheckFailure.InvalidTypeArgument)
        val open = ParameterKey(owner = profileId, index = 0).template
        checker.checkExpressionCodes(convert(listOf(open)), bindings, nominalExpressionType(narrow.use)) shouldBe
            listOf(CheckFailure.InvalidTypeArgument)
    }

    test("a record field replacement names a literal field and gives it a value of the field type") {
        val bindings = mapOf(candidate to nominalExpressionType(profileId.use()), parent to nominalExpressionType(text))
        val title = checkLiteral(DataValue.StringValueWrapper("title"))
        checker.checkExpressionCodes(
            checkCall("record.with_field", read(candidate), title, read(parent)),
            bindings,
            nominalExpressionType(profileId.use()),
        ) shouldBe emptyList()
        checker.checkExpressionCodes(
            checkCall("record.with_field", read(candidate), read(parent), read(parent)),
            bindings,
            nominalExpressionType(profileId.use()),
        ) shouldBe listOf(CheckFailure.LiteralRequired)
        checker.checkExpressionCodes(
            checkCall("record.with_field", read(candidate), title, checkLiteral(DataValue.BooleanWrapper(true))),
            bindings,
            nominalExpressionType(profileId.use()),
        ) shouldBe listOf(CheckFailure.InvalidOperandType)
    }

    test("panel profile operations are outside the rule profile") {
        val formatted =
            checkCall(
                "number.format",
                read(candidate),
                checkLiteral(DataValue.integer(java.math.BigInteger.TWO)),
                checkLiteral(DataValue.StringValueWrapper("en")),
            )
        ExpressionNode.createAnd(left = checkCall("boolean.not", read(parent)), right = formatted).ruleProfileViolations() shouldBe
            listOf(CheckFailure.OutsideRuleProfile)
        checkCall("text.trim_end", read(candidate)).ruleProfileViolations() shouldBe emptyList()
    }
}

internal fun checkInput(
    binding: ExpressionBindingId,
    path: ValuePath = ValuePath.root,
): ExpressionNode = ExpressionNode.createInput(binding = binding, path = path)

internal fun checkLiteral(value: DataValue): ExpressionNode = ExpressionNode.LiteralWrapper(value)

internal fun checkCall(
    operation: String,
    vararg arguments: ExpressionNode,
    typeArguments: List<TypeTemplate> = emptyList(),
): ExpressionNode =
    ExpressionNode.createCall(operation = OperationId(value = operation), typeArguments = typeArguments, arguments = arguments.toList())

internal fun checkLambda(
    arity: Int,
    body: ExpressionNode,
): ExpressionNode = ExpressionNode.createLambda(arity = arity, body = body)

internal fun checkLocal(
    slot: Int,
    depth: Int = 0,
): ExpressionNode = ExpressionNode.createLocal(depth = depth, slot = slot, path = ValuePath.root)
