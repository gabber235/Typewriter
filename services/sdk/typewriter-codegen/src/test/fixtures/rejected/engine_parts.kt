package fixture

import com.typewritermc.events.EnginePart

class TwoWays(val name: String) : EnginePart { // error: An engine part needs exactly one public constructor, so the engine knows how to build it.
    constructor(number: Int) : this(number.toString())
}

class Hidden private constructor() : EnginePart // error: An engine part needs exactly one public constructor, so the engine knows how to build it.

private class Secret : EnginePart // error: An engine part must be visible, so the engine can build it.
