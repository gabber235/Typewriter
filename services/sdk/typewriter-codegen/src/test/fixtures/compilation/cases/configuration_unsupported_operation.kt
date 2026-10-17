package fixture

import com.typewritermc.types.TypewriterType

@TypewriterType(id = "a00000000000000000000000000000a1")
data class TypedConfiguration(val title: String)

object Configuration : TypedConfigurationConfiguration {
    override fun TypedConfigurationConfigurationScope.configure() {
        title { positive() }
    }
}
