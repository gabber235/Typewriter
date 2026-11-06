package fixture

import com.typewritermc.discovery.DeploymentFacts
import com.typewritermc.discovery.DiscoveryDomains
import com.typewritermc.discovery.GeneratedProviderArtifact
import com.typewritermc.discovery.GeneratedProviderLoader
import com.typewritermc.formula.FormulaCall
import com.typewritermc.formula.NotProvided
import com.typewritermc.formula.TypewriterFormulaName
import com.typewritermc.formula.TypewriterFormulaProvider
import com.typewritermc.imprint.ArtifactId
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.TypewriterType
import com.typewritermc.types.functionTemplate
import com.typewritermc.types.integerScalar
import com.typewritermc.types.qualified
import com.typewritermc.types.template
import io.kotest.matchers.shouldBe
import skirout.editor.v1.type_catalog.FunctionParameterTemplate
import skirout.editor.v1.type_catalog.FunctionTypeTemplate
import skirout.editor.v1.type_catalog.IntegerWidth
import skirout.editor.v1.type_catalog.ParameterKey
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeTemplate
import java.nio.file.Path
import kotlin.time.Duration
import kotlin.time.Duration.Companion.seconds
import kotlin.time.DurationUnit
import kotlin.time.toDuration

@TypewriterType(id = "a0000000000000000000000000000931")
data class Gold(
    val amount: Int,
)

@TypewriterFormulaProvider
object Sample {
    @TypewriterFormulaName("plus")
    fun Int.add(other: Int): Int = this + other

    fun <T> List<T>.count2(f: (T) -> Boolean): Int = count(f)

    fun greeting(
        prefix: String = "hi",
        name: String = "you",
    ): String = "$prefix $name"

    val Int.seconds: Duration get() = this.toDuration(DurationUnit.SECONDS)

    fun Gold.doubled(): Gold = Gold(amount * 2)

    private fun helper(): Int = 0
}

/** Hands values through unchanged: every value in this fixture is already its Kotlin form. */
object KotlinValues : FormulaCall {
    override fun intoKotlin(
        value: Any?,
        type: TypeTemplate,
    ): Any? = value

    override fun fromKotlin(
        value: Any?,
        type: TypeTemplate,
    ): Any? = value

    override fun display(value: Any?): String = value.toString()

    override fun resolve(value: Any?): Any? = value

    override fun force(value: Any?): Any? = value

    override fun fail(message: String): Nothing = error(message)
}

/** Each generated function runs its Kotlin function, and its signature is what the Kotlin code declares. */
fun main(args: Array<String>) {
    val int = integerScalar(IntegerWidth.SIGNED_THIRTY_TWO).template
    GeneratedProviderLoader()
        .load(
            listOf(GeneratedProviderArtifact(ArtifactId("fixture"), Path.of(args.single()))),
            DeploymentFacts(emptyMap()),
            DiscoveryDomains.Realm,
            // The host sees the fixture's classes, so a Gold built here is the Gold the provider receives.
            parentClassLoader = Gold::class.java.classLoader,
        ).use { deployment ->
            val functions = deployment.providers.formula.associate { it.function.name to it.function }
            functions.keys shouldBe setOf("plus", "count2", "greeting", "seconds", "doubled")

            fun call(
                name: String,
                vararg arguments: Any?,
            ): Any? = functions.getValue(name).invoke(KotlinValues, arguments.toList())

            call("plus", 2, 3) shouldBe 5
            functions.getValue("plus").signature shouldBe
                FunctionTypeTemplate(
                    context = listOf(FunctionParameterTemplate(name = "this", type = int)),
                    parameters = listOf(FunctionParameterTemplate(name = "other", type = int)),
                    result = int,
                )

            val counted: (Any?) -> Boolean = { (it as Int) > 1 }
            call("count2", listOf(1, 2, 3), counted) shouldBe 2
            val count2 = functions.getValue("count2")
            val t = ParameterKey(owner = TypeDefinitionId.qualified("formula", "fixture.Sample.count2"), index = 0)
            count2.typeParameters.map { it.key to it.name } shouldBe listOf(t to "T")
            count2.signature shouldBe
                FunctionTypeTemplate(
                    context = listOf(FunctionParameterTemplate(name = "this", type = StandardTypes.list.template(listOf(t.template)))),
                    parameters = listOf(FunctionParameterTemplate(name = "f", type = functionTemplate(listOf(), listOf("it" to t.template), ScalarKind.BOOLEAN.template))),
                    result = int,
                )

            functions.getValue("greeting").defaulted shouldBe setOf("prefix", "name")
            call("greeting", NotProvided, NotProvided) shouldBe "hi you"
            call("greeting", "yo", NotProvided) shouldBe "yo you"
            call("greeting", NotProvided, "Ann") shouldBe "hi Ann"
            call("greeting", "yo", "Ann") shouldBe "yo Ann"

            call("seconds", 5) shouldBe 5.seconds
            functions.getValue("seconds").signature shouldBe
                FunctionTypeTemplate(
                    context = listOf(FunctionParameterTemplate(name = "this", type = int)),
                    parameters = listOf(),
                    result = ScalarKind.DURATION.template,
                )

            call("doubled", Gold(2)) shouldBe Gold(4)
            functions.getValue("doubled").signature.result shouldBe GoldDefinition.id.template()
        }
}
