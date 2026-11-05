package com.typewritermc.services.libs.telemetry.testing

/** A fatal error, which the span boundaries must let escape unchanged without recording it as a failure. */
class TestVirtualMachineError : VirtualMachineError("test fatal")
