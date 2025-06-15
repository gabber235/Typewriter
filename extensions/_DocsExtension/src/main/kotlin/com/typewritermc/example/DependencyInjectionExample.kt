package com.typewritermc.example

import com.google.gson.Gson
import com.google.gson.GsonBuilder
import com.typewritermc.core.extension.annotations.*
import org.bukkit.entity.Player
import org.koin.core.component.KoinComponent
import org.koin.core.component.inject
import org.koin.core.parameter.parametersOf
import org.koin.core.qualifier.named
import org.koin.java.KoinJavaComponent

//<code-block:di_singleton_class>
// highlight-next-line
@Singleton
class ExampleService {
    fun greet(player: Player) {
        player.sendMessage("Hello ${player.name}")
    }
}
//</code-block:di_singleton_class>

//<code-block:di_singleton_object>
// highlight-next-line
@Singleton
object ExampleObject {
    const val prefix: String = "[Typewriter]"
}
//</code-block:di_singleton_object>

//<code-block:di_singleton_function>
// highlight-next-line
@Singleton
fun providePrefix(): String = "[Typewriter]"
//</code-block:di_singleton_function>

//<code-block:di_singleton_inject>
class ExampleSingletonUsage : KoinComponent {
    // highlight-next-line
    private val service: ExampleService by inject()

    fun welcome(player: Player) {
        service.greet(player)
        // highlight-start
        // Or if you want to directly get the prefix inline you can do:
        val prefix: String = KoinJavaComponent.get(String::class.java)
        // highlight-end
        player.sendMessage(prefix)
    }
}
//</code-block:di_singleton_inject>

//<code-block:di_factory_class>
// highlight-next-line
@Factory
class ExampleRunner(
    // Parameters are automatically injected by Koin,
    // make sure to register these types with @Singleton or @Factory
    private val service: ExampleService,
) {
    fun start(player: Player) {
        service.greet(player)
    }
}
//</code-block:di_factory_class>

//<code-block:di_factory_function>
// highlight-next-line
@Factory
fun createGson(): Gson = GsonBuilder().setPrettyPrinting().create()
//</code-block:di_factory_function>

//<code-block:di_factory_inject>
class TrackerManager : KoinComponent {
    // highlight-start
    // You can inject a factory like this,
    // it will create a new instance every time you get the field
    val exampleRunner: ExampleRunner by inject()
    // highlight-end

    fun create(): ExampleRunner =
    // highlight-start
        // Or you can get it from the Koin scope directly
        KoinJavaComponent.get(ExampleObject::class.java)
    // highlight-end
}
//</code-block:di_factory_inject>

//<code-block:di_named_function>
@Factory
// highlight-next-line
@Named("exampleParser")
fun provideParser(): Gson = GsonBuilder().create()
//</code-block:di_named_function>

//<code-block:di_named_inject>
@Factory
class ParserUser(
    // highlight-next-line
    @Inject("exampleParser") val parser: Gson,
)
//</code-block:di_named_inject>

//<code-block:di_named_usage>
class NamedUsage : KoinComponent {
    // highlight-next-line
    private val parser: Gson by inject(named("exampleParser"))
}
//</code-block:di_named_usage>

//<code-block:di_named_usage_java>
class NamedUsageJava {
    private val parser: Gson =
        // highlight-next-line
        KoinJavaComponent.get(Gson::class.java, named("exampleParser"))
}
//</code-block:di_named_usage_java>

//<code-block:di_parameter_factory>
@Factory
class GreetingTracker(
    // highlight-next-line
    @Parameter val player: Player,
    private val service: ExampleService,
) {
    fun greet() {
        service.greet(player)
    }
}
//</code-block:di_parameter_factory>

//<code-block:di_parameter_usage>
class ParameterManager : KoinComponent {
    fun trackerFor(player: Player): GreetingTracker =
        // highlight-next-line
        getKoin().get(parameters = { parametersOf(player) })
}
//</code-block:di_parameter_usage>

//<code-block:di_get_all>
class GetAllExample : KoinComponent {
    fun services(): List<ExampleService> =
        // highlight-next-line
        getKoin().getAll()
}
//</code-block:di_get_all>
