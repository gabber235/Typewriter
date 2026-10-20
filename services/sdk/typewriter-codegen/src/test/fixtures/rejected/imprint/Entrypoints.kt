package fixture

import com.typewritermc.imprint.ImprintRuntimeEntrypoint
import com.typewritermc.loader.api.HostedRuntimeEntrypoint

@ImprintRuntimeEntrypoint
abstract class AbstractEntrypoint : HostedRuntimeEntrypoint // error: Imprint runtime entrypoints must be concrete classes.

object Outer {
    @ImprintRuntimeEntrypoint
    class NestedEntrypoint : HostedRuntimeEntrypoint // error: Imprint runtime entrypoints must be visible qualified declarations.
}

@ImprintRuntimeEntrypoint
class PlainEntrypoint // error: Imprint runtime entrypoints must implement HostedRuntimeEntrypoint.

@ImprintRuntimeEntrypoint
class ConfiguredEntrypoint(val name: String) : HostedRuntimeEntrypoint // error: Imprint runtime entrypoints must have a public zero argument constructor.
