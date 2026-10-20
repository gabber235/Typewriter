package fixture

import com.typewritermc.discovery.RuntimeRegistrar
import com.typewritermc.discovery.RuntimeScope
import com.typewritermc.discovery.TypewriterRegistrar

@TypewriterRegistrar("fixture.abstract")
abstract class AbstractRegistrar : RuntimeRegistrar // error: Typewriter registrars must be concrete classes.

@TypewriterRegistrar("fixture.private")
private class PrivateRegistrar : RuntimeRegistrar { // error: Typewriter registrars must be visible qualified declarations.
    context(scope: RuntimeScope)
    override suspend fun register() {}
}

@TypewriterRegistrar("fixture.plain")
class PlainRegistrar // error: Typewriter registrars must implement RuntimeRegistrar.

@TypewriterRegistrar("-bad id")
class BadIdRegistrar : RuntimeRegistrar { // error: Runtime registrar ids must be safe path segments.
    context(scope: RuntimeScope)
    override suspend fun register() {}
}

@TypewriterRegistrar("fixture.nowhere", realm = false, execution = false)
class NowhereRegistrar : RuntimeRegistrar { // error: Runtime registrars must select at least one runtime domain.
    context(scope: RuntimeScope)
    override suspend fun register() {}
}
