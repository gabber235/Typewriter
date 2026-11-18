package com.typewritermc.playtest.wire;

import java.io.IOException;

/** A frame that breaks the framing: the connection cannot be trusted past it. */
public final class WireException extends IOException {
    public WireException(String message) {
        super(message);
    }
}
